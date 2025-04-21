local addTextArea
do
	local add = ui.addTextArea
	local gsub = string.gsub
	function addTextArea(id, data, target)
		return add(id, gsub(data, "([Hh][Tt])([Tt][Pp])", "%1<%2"), target)
	end
end

local loading_file_time = os.time()
local pdata_requested = {}
local pdata_updates = {}
local file_updates

local bit = bit or bit32
local callbacks = {
	send_room = bit.lshift(2, 8) + 255,
	load_map = bit.lshift(11, 8) + 255,
	load_file = bit.lshift(40, 8) + 255,
	load_pdata = bit.lshift(41, 8) + 255,
	send_update = bit.lshift(42, 8) + 255,
	update_file = bit.lshift(43, 8) + 255,
	update_pdata_bot = bit.lshift(44, 8) + 255,
	show_textarea = bit.lshift(45, 8) + 255,
}
local textareas = {
	heartbeat = 1 + 255,
	file_action_status = 2 + 255,
	pdata_update_status = 3 + 255,
}

local parkour_bot = "Parkour#0568"

local function apply_file_operation(data, operation, file, raw_data)
	local action = operation[2]
	if action == 'fetch' then
		tfm.exec.playMusic('file:' .. tostring(file), tostring(raw_data), 0, false, false, parkour_bot)
		return
	elseif action == 'backup' then
		system.saveFile(raw_data, operation[3])
		return
	elseif action == 'fetch_field' then
		local current = data
		for j=3, #operation do
			if not current[operation[j]] then
				return "field not found"
			end
			current = current[operation[j]]
		end

		tfm.exec.playMusic(
			'field:' .. tostring(file) .. ':' .. table.concat(operation, '.', 3),
			json.encode(current),
			0, false, false, parkour_bot
		)
		return
	elseif action == 'set_field' then
		local done, parsed = pcall(json.decode, operation[3])
		if not done then
			return "invalid value: " .. tostring(operation[3])
		end

		local current = data
		for j=4, #operation-1 do
			if not current[operation[j]] then
				return "field not found: " .. tostring(operation[j])
			end
			current = current[operation[j]]
		end

		current[operation[#operation]] = parsed

		return
	elseif action == 'sanction' then
		if not data.mods then
			return "no mods field"
		end
		if not data.sanction then
			return "no sanction field"
		end

		local playerid, moderator = operation[3], operation[4]
		if not moderator then
			data.sanction[playerid] = nil
			return
		end

		local prev_sanction = data.sanction[playerid]
		local time, level = tonumber(operation[5]), tonumber(operation[6])
		local mod_index = table_find(data.mods, moderator)
		local now = os.time()

		if not mod_index then
			data.mods[1 + #data.mods] = moderator
			mod_index = #data.mods
		end

		local sanctionLevel = data.sanction[playerid] and data.sanction[playerid].level or 0
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

		tfm.exec.playMusic(
			'sanction:' .. tostring(playerid),
			json.encode({
				prev = prev_sanction,
				current = data.sanction[playerid]
			}),
			0, false, false, parkour_bot
		)
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
			addTextArea(
				textareas.file_action_status,
				tostring(data) .. "\000invalid file id",
				parkour_bot
			)
			return
		end

		if os.time() < loading_file_time then
			addTextArea(
				textareas.file_action_status,
				file_id .. "\000too early",
				parkour_bot
			)
			return
		end

		loading_file_time = os.time() + 11000
		system.loadFile(file_id)

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

	elseif id == callbacks.update_pdata_bot then
		local player, fields = string.match(data, "([^\000]+)\000([^\000]+)")
		pdata_updates[player] = fields
		if not pdata_requested[player] then
			pdata_requested[player] = os.time() + 2000
			system.loadPlayerData(player)
		end

	elseif id == callbacks.show_textarea then
		local id, target, text = string.match(data, "([^\000]+)\000([^\000]+)\000([^\000]+)")
		ui.addTextArea(id, text, target, 0, 30, nil, nil, 1, 0, 0.8, true)

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

	local clear = {}
	local now = os.time()
	for name, ts in next, pdata_requested do
		if now > ts then
			clear[1+#clear] = name
		end
	end
	for i=1, #clear do
		pdata_requested[clear[i]] = nil
		pdata_updates[clear[i]] = nil
	end
end)

onEvent("FileLoaded", function(file, raw_data)
	if not file_updates then
		tfm.exec.playMusic('file:' .. tostring(file), tostring(raw_data), 0, false, false, parkour_bot)
		return
	end

	local manager = filemanagers[tostring(file)]
	if not manager then
		file_updates = nil
		addTextArea(
			textareas.file_action_status,
			file .. '\000no manager',
			parkour_bot
		)
		return
	end

	local data = manager:load(raw_data)
	local reason, operation

	for i=1, #file_updates do
		operation = file_updates[i]
		if operation[1] ~= file then
			file_updates = nil
			addTextArea(
				textareas.file_action_status,
				file .. '\000file id mismatch: ' .. tostring(operation[1]) .. ' at ' .. i,
				parkour_bot
			)
			return
		end

		reason = apply_file_operation(data, operation, file, raw_data)
		if reason then
			file_updates = nil
			addTextArea(
				textareas.file_action_status,
				file .. '\000' .. reason,
				parkour_bot
			)
			return
		end
	end

	file_updates = nil
	data = manager:dump(data)
	system.saveFile(data, file)

	addTextArea(
		textareas.file_action_status,
		file .. '\000',
		parkour_bot
	)
end)

onEvent("PlayerDataLoaded", function(player, file)
	if not pdata_requested[player] then return end
	pdata_requested[player] = nil
	tfm.exec.playMusic('pdata:' .. tostring(player), tostring(file), 0, false, false, parkour_bot)

	if not pdata_updates[player] then
		return
	end
	local fields = pdata_updates[player]
	pdata_updates[player] = nil

	local done, data = pcall(json.decode, file)
	if not done then
		addTextArea(
			textareas.pdata_update_status,
			player .. '\000Invalid json',
			parkour_bot
		)
		return
	end

	if data.v ~= data_version then
		addTextArea(
			textareas.pdata_update_status,
			player .. '\000Invalid version',
			parkour_bot
		)
		return
	end

	local key, value, done, parsed
	for fieldPair in fields:gmatch('([^\001]+)') do
		key, value = fieldPair:match('([^\002]+)\002([^\002]+)')
		done, parsed = pcall(json.decode, value)
		if not done then
			addTextArea(
				textareas.pdata_update_status,
				player .. '\000Invalid value ' .. tostring(value) .. ' at ' .. tostring(key),
				parkour_bot
			)
			return
		end

		data[key] = parsed
	end

	system.savePlayerData(
		player,
		json.encode(data)
	)
	addTextArea(
		textareas.pdata_update_status,
		player .. '\000',
		parkour_bot
	)
end)

tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableMortCommand(true)
tfm.exec.newGame(0)
tfm.exec.setRoomMaxPlayers(50)
