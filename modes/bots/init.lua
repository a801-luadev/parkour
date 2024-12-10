local addTextArea
do
	local add = ui.addTextArea
	local gsub = string.gsub
	function addTextArea(id, data, target)
		return add(id, gsub(data, "([Hh][Tt])([Tt][Pp])", "%1<%2"), target)
	end
end

local loading_file_time = os.time() + 11000
local loading_file_id
local pdata_requested = {}
local file_updates

local bit = bit or bit32
local callbacks = {
	send_room = bit.lshift(2, 8) + 255,
	load_map = bit.lshift(11, 8) + 255,
	load_file = bit.lshift(40, 8) + 255,
	load_pdata = bit.lshift(41, 8) + 255,
	send_update = bit.lshift(42, 8) + 255,
	update_file = bit.lshift(43, 8) + 255,
}
local textareas = {
	heartbeat = 1 + 255,
	action_error = 2 + 255,
	file_update_status = 3 + 255,
}

local parkour_bot = "Parkour#0568"

local function apply_file_operation(data, operation)
	local action = operation[2]
	if action == 'fetch' then
		return
	elseif action == 'sanction' then
		if not data.mods then
			return "no mods field"
		end
		if not data.sanction then
			return "no sanction field"
		end

		local playerid, moderator = operation[3], operation[4]
		local time, level = tonumber(operation[5]), tonumber(operation[6])
		local mod_index = table_find(data.mods, moderator)
		local now = os.time()

		if not mod_index then
			data.mods[1 + #data.mods] = moderator
			mod_index = #data.mods
		end

		local sanctionLevel = data.sanction[playerid] or 0
		if level then
			if operation[6]:sub(1,1) == '+' or operation[6]:sub(1,1) == '-' then
				sanctionLevel = math.min(4, math.max(0, sanctionLevel + level))
			else
				sanctionLevel = level
			end
		end

		if not time then
			if sanctionLevel == 1 then
				time = now + 86400000 -- 1 day
			elseif sanctionLevel == 2 then
				time = now + 86400000 * 7
			elseif sanctionLevel == 3 then
				time = now + 86400000 * 30
			elseif sanctionLevel == 4 then
				time = 2 -- permanent ban
			else
				time = 0 -- unban
			end
		end

		data.sanction[playerid] = {
			timestamp = now,
			time = time,
			info = mod_index,
			level = sanctionLevel,
		}
		return
	elseif action == 'addmap' then
		local list = data[operation[3]]
		if not list then
			return "list not found"
		end
		local mapcode
		for i=4, #operation do
			mapcode = tonumber(operation[i])
			if not mapcode then
				return "invalid mapcode " .. operation[i]
			end
			list[1+#list] = mapcode
		end
		return
	elseif action == 'removemap' then
		local list = data[operation[3]]
		if not list then
			return "list not found"
		end
		local mapcode
		local indexList = {}
		local index
		for i=4, #operation do
			mapcode = tonumber(operation[i])
			if not mapcode then
				return "invalid mapcode " .. operation[i]
			end
			index = table_find(list, mapcode)
			if index then
				indexList[#indexList + 1] = index
			end
		end
		table.sort(indexList)
		for i=#indexList, 1, -1 do
			table.remove(list, indexList[i])
		end
		return
	end
	return "invalid action"
end

onEvent("NewPlayer", function(player)
	if player ~= parkour_bot then return end
	file_updates = nil
end)

onEvent("TextAreaCallback", function(id, player, data)
	if player ~= parkour_bot then return end

	if id == callbacks.send_room then
		local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
		packet_id = tonumber(packet_id)
		if not packet_id then return end

		eventSendingPacket(packet_id, packet)

	elseif id == callbacks.send_update then
		local seconds = tonumber(data)
		if not seconds then return end

		eventSendingPacket(packets.bots.game_update, tostring(os.time() + seconds * 1000))

	elseif id == callbacks.load_map then
		tfm.exec.newGame(data)

	elseif id == callbacks.load_file then
		local file_id = tonumber(data)

		if not file_id or file_id < 0 or file_id > 100 then
			addTextArea(textareas.action_error, "invalid file id", parkour_bot)
			return
		end

		if loading_file_id then
			addTextArea(textareas.action_error, "already loading a file", parkour_bot)
			return
		end

		loading_file_id = file_id

	elseif id == callbacks.load_pdata then
		pdata_requested[data] = os.time() + 2000
		system.loadPlayerData(data)

	elseif id == callbacks.update_file then
		if data == "" then
			file_updates = nil
			return
		end

		local params = {}

		for value in data:gmatch('[^\000]+') do
			params[1 + #params] = value
		end

		if not file_updates then
			file_updates = {}
		end

		file_updates[1 + #file_updates] = params
	end
end)

onEvent("SendingPacket", function(id, packet)
	if id == packets.bots.announce then -- !announcement
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	end

	sendPacket("bots", id, packet)
end)

onEvent("PacketReceived", function(channel, id, packet, map, time)
	if channel ~= "common" then return end

	if id <= 255 then -- see textareas
		addTextArea(id, packet, parkour_bot)
	end
end)

onEvent("Loop", function()
	addTextArea(textareas.heartbeat, "", parkour_bot)

	if loading_file_id and os.time() > loading_file_time then
		system.loadFile(loading_file_id)

		loading_file_time = os.time() + 11000
		loading_file_id = nil
	end

	local clear = {}
	local now = os.time()
	for name, ts in next, pdata_requested do
		if now > ts then
			clear[1+#clear] = name
		end
	end
	for i=1, #clear do
		pdata_requested[clear[i]] = nil
	end
end)

onEvent("FileLoaded", function(file, data)
	if not file_updates or file_updates[1][1] == file and file_updates[1][2] == 'fetch' then
		tfm.exec.playMusic('file:' .. tostring(file), tostring(data), 0, false, false, parkour_bot)
	end

	if not file_updates then
		return
	end

	local manager = filemanagers[file]
	if not manager then
		file_updates = nil
		addTextArea(
			textareas.file_update_status,
			file .. '\000\000no manager',
			parkour_bot
		)
		return
	end

	local data = manager:load(data)
	local reason

	for i=1, #file_updates do
		if file_updates[i][1] ~= file then
			file_updates = nil
			addTextArea(
				textareas.file_update_status,
				file .. '\000' .. i .. '\000file id mismatch',
				parkour_bot
			)
			return
		end

		reason = apply_file_operation(data, file_updates[i])
		if reason then
			file_updates = nil
			addTextArea(
				textareas.file_update_status,
				file .. '\000' .. i .. '\000' .. reason,
				parkour_bot
			)
			return
		end
	end

	file_updates = nil
	data = manager:dump(data)
	system.saveFile(data, file)

	addTextArea(
		textareas.file_update_status,
		file .. '\000' .. #update_indices .. '\000',
		parkour_bot
	)
end)

onEvent("PlayerDataLoaded", function(player, file)
	if not pdata_requested[player] then return end
	pdata_requested[player] = nil
	tfm.exec.playMusic('pdata:' .. tostring(player), tostring(file), 0, false, false, parkour_bot)
end)

tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableMortCommand(true)
tfm.exec.newGame(0)
tfm.exec.setRoomMaxPlayers(50)
