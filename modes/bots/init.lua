local files = {
	[1] = 20, -- maps, ranks, chats
	[2] = 22 -- lowmaps, banned
}
local next_file_load = os.time() + 61000
local next_file_check = 0

local bit = bit or bit32
local packets = {
	send_other = bit.lshift(1, 8) + 255,
	send_room = bit.lshift(2, 8) + 255,
	send_webhook = bit.lshift(3, 8) + 255,
	modify_rank = bit.lshift(4, 8) + 255,
	synchronize = bit.lshift(5, 8) + 255,
	heartbeat = bit.lshift(6, 8) + 255,
	change_map = bit.lshift(7, 8) + 255,
	file_loaded = bit.lshift(8, 8) + 255,
	current_chat = bit.lshift(9, 8) + 255,
	new_chat = bit.lshift(10, 8) + 255,
	load_map = bit.lshift(11, 8) + 255,
	weekly_reset = bit.lshift(12, 8) + 255,
	room_password = bit.lshift(13, 8) + 255,
	verify_discord = bit.lshift(14, 8) + 255,
	version_mismatch = bit.lshift(15, 8) + 255,
	record_submission = bit.lshift(16, 8) + 255,
	record_badges = bit.lshift(17, 8) + 255,
	simulate_sus = bit.lshift(18, 8) + 255,
	last_sanction = bit.lshift(19, 8) + 255,
	runtime = bit.lshift(20, 8) + 255,
	player_victory = bit.lshift(21, 8) + 255,
	get_player_info = bit.lshift(22, 8) + 255,

	module_crash = bit.lshift(255, 8) + 255
}

local hidden_bot = "Tocutoeltuco#5522"
local parkour_bot = "Parkour#8558"
local loaded = false
local chats = {loading = true}
local killing = {}
local verifying = {}
local get_sanction = {}
local get_player_info = {}
local to_do = {}
local in_room = {}
local records = {
	all_badges = 9
}

local file_actions = {
	high_map_change = {1, true, function(data, map, add)
		for index = #data.maps, 1, -1 do
			if data.maps[index] == map then
				if add then
					return
				else
					table.remove(data.maps, index)
				end
			end
		end

		if add then
			data.maps[#data.maps + 1] = map
		end
	end},

	low_map_change = {2, true, function(data, map, add)
		for index = 1, #data.lowmaps do
			if data.lowmaps[index] == map then
				if add then
					return
				else
					table.remove(data.lowmaps, index)
				end
			end
		end

		if add then
			data.lowmaps[#data.lowmaps + 1] = map
		end
	end},

	new_chat = {1, true, function(data, name, chat)
		data.chats[name] = chat
		chats[name] = chat
		ui.addTextArea(packets.current_chat, name .. "\000" .. chat, parkour_bot)
	end},

	ban_change = {2, true, function(data, id, value)
		data.banned[tostring(id)] = value
	end},

	modify_rank = {1, true, function(data, player, newrank)
		data.ranks[player] = newrank
	end}
}

local function schedule(action, arg1, arg2)
	to_do[#to_do + 1] = {file_actions[action], arg1, arg2}
	next_file_check = os.time() + 4000
end

local function sendSynchronization()
	local packet
	for rank in next, ranks_id do
		if not packet then
			packet = rank
		else
			packet = packet .. "\001" .. rank
		end
	end

	for player, _ranks in next, player_ranks do
		packet = packet .. "\000" .. player
		for rank in next, _ranks do
			packet = packet .. "\001" .. rank
		end
	end

	ui.addTextArea(packets.synchronize, os.time() .. "\000" .. packet, parkour_bot)
	ui.addTextArea(packets.current_chat, "mod\000" .. chats.mod, parkour_bot)
	ui.addTextArea(packets.current_chat, "mapper\000" .. chats.mapper, parkour_bot)
end

onEvent("SavingFile", function(file, data)
	system.saveFile(filemanagers[tostring(file)]:dump(data), file)
end)

onEvent("FileLoaded", function(file, data)
	ui.addTextArea(packets.file_loaded, file, hidden_bot)

	data = filemanagers[file]:load(data)
	file = tonumber(file)
	local save = false

	local action
	for index = 1, #to_do do
		action = to_do[index][1]
		if files[action[1]] == file then
			if action[2] then
				save = true
			end

			action[3](data, to_do[index][2], to_do[index][3])
			to_do[index] = nil
		end
	end
	for index = #to_do, 1, -1 do
		if not to_do[index] then
			table.remove(to_do, index)
		end
	end

	eventGameDataLoaded(data)
	if data.chats then
		if chats.loading then
			chats = data.chats
		end
	end

	if not loaded and in_room[parkour_bot] then
		sendSynchronization()
	end
	loaded = true

	if save then
		eventSavingFile(file, data)
	end
end)

onEvent("TextAreaCallback", function(id, player, data)
	if player ~= hidden_bot and player ~= parkour_bot then return end

	if id == packets.send_other then
		ui.addTextArea(packets.send_other, data, player == hidden_bot and parkour_bot or hidden_bot)

	elseif id == packets.send_room then
		local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
		packet_id = tonumber(packet_id)
		if not packet_id then return end

		eventSendingPacket(packet_id, packet)

	elseif id == packets.new_chat then
		local name, chat = string.match(data, "^([^\000]+)\000([^\000]+)$")
		schedule("new_chat", name, chat)
		ui.addTextArea(packets.current_chat, name .. "\000" .. chat, parkour_bot)

	elseif id == packets.modify_rank then
		local player, action, rank = string.match(data, "^([^\000]+)\000([01])\000(.*)$")
		if not player_ranks[player] then
			player_ranks[player] = {
				[rank] = action == "1"
			}
		else
			player_ranks[player][rank] = action == "1"
		end

		local id = 0
		for rank, has in next, player_ranks[player] do
			if has then
				id = id + ranks_id[rank]
			end
		end

		if id == 0 then
			player_ranks[player] = nil
			id = nil
		end

		schedule("modify_rank", player, id)

	elseif id == packets.change_map then
		local rotation, map, add = string.match(data, "^([^\000]+)\000(%d+)\000([01])$")

		schedule(rotation .. "_map_change", tonumber(map), add == "1")

	elseif id == packets.load_map then
		tfm.exec.newGame(data)

	elseif id == packets.verify_discord then
		verifying[data] = true
		system.loadPlayerData(data)

	elseif id == packets.record_badges then
		local name, badge = string.match(data, "^([^\000]+)\000([^\000]+)$")
		badge = tonumber(badge)

		if badge > 1 then
			badge = math.ceil(badge / 5) + 1
		end

		if badge <= records.all_badges then
			records[name] = badge
			system.loadPlayerData(name)
		end

	elseif id == packets.simulate_sus then
		eventPacketReceived(1, data)

	elseif id == packets.last_sanction then
		get_sanction[data] = true
		system.loadPlayerData(data)

	elseif id == packets.runtime then
		ui.addTextArea(packets.runtime, usedRuntime .. "\000" .. totalRuntime .. "\000" .. (cycleId - startCycle), player)

	elseif id == packets.get_player_info then
		get_player_info[data] = true
		system.loadPlayerData(data)
	end
end)

onEvent("PlayerDataLoaded", function(player, data)
	if player == recv_channel or player == send_channel or data == "" then return end

	data = json.decode(data)
	if data.v ~= data_version then
		return ui.addTextArea(packets.version_mismatch, player)
	end

	local update = false
	if killing[player] then
		data.killed = os.time() + killing[player] * 60 * 1000
		data.kill = killing[player]

		update = true
		killing[player] = nil
	end

	if verifying[player] then
		data.badges[5] = 1
		ui.addTextArea(packets.verify_discord, player)

		update = true
		verifying[player] = nil
	end

	if records[player] then
		if data.badges[6] < records[player] then
			data.badges[6] = records[player]

			update = true
		end
		records[player] = nil
	end

	if get_player_info[player] then
		ui.addTextArea(packets.get_player_info, player .. "\000" .. data.room .. "\000" .. #data.hour)
		get_player_info[player] = nil
	end

	if get_sanction[player] then
		ui.addTextArea(packets.last_sanction, player .. "\000" .. data.kill)
		get_sanction[player] = nil
	end

	if update then
		system.savePlayerData(player, json.encode(data))
		sendPacket(2, player)
	end
end)

onEvent("SendingPacket", function(id, packet)
	if id == 1 then -- update
		sendPacket(1, tostring(os.time() + 60 * 1000))
		return

	elseif id == 2 then -- !kill
		local player, minutes = string.match(packet, "^([^\000]+)\000([^\000]+)$")
		killing[player] = tonumber(minutes)
		system.loadPlayerData(player)
		return

	elseif id == 3 then -- !ban
		local id, ban_time = string.match(packet, "^[^\000]+\000([^\000]+)\000([^\000]+)$")
		schedule("ban_change", id, tonumber(ban_time))

	elseif id == 4 then -- !announcement
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	end

	sendPacket(id, packet)
end)

onEvent("PacketReceived", function(id, packet, map, time)
	if id == -1 then
		ui.addTextArea(packets.payer_victory, packet, parkour_bot)
		return
	end

	local args, count = {}, 0
	for slice in string.gmatch(packet, "[^\000]+") do
		count = count + 1
		args[count] = slice
	end

	if id == 0 then
		local _room, event, errormsg = table.unpack(args)
		enlargeName(_room)
		ui.addTextArea(
			packets.send_webhook,
			"**`[CRASH]:`** `" .. _room .. "` has crashed. <@212634414021214209>: `" .. event .. "`, `" .. errormsg .. "`",
			parkour_bot
		)

	elseif id == 1 then
		local _room, player, id, map, taken = table.unpack(args)
		_room = enlargeName(_room)
		ui.addTextArea(
			packets.send_webhook,
			"**`[SUS]:`** `" .. player .. "` (`" .. id .. "`) completed the map `" ..
			map .. "` in the room `" .. _room .. "` in `" .. taken .. "` seconds.",
			parkour_bot
		)
		if tonumber(taken) <= 27 then -- autoban!
			schedule("ban_change", id, 1)
			sendPacket(3, player .. "\000" .. id .. "\0001")
			ui.addTextArea(
				packets.send_webhook,
				"**`[BANS]:`** `AntiCheatSystem` has permbanned the player `" .. player .. "` (`" .. id .. "`)",
				parkour_bot
			)
		end

	elseif id == 2 then
		local player, ban = table.unpack(args)
		schedule("ban_change", player, nil)

	elseif id == 3 then
		local _room, id, player, maps = table.unpack(args)
		enlargeName(_room)
		ui.addTextArea(
			packets.send_webhook,
			"**`[SUS2]:`** `" .. player .. "` (`" .. id .. "`) has got `" .. maps .. "` maps in the last hour.",
			parkour_bot
		)

	elseif id == 4 then
		ui.addTextArea(packets.weekly_reset, packet, parkour_bot)

	elseif id == 5 then
		ui.addTextArea(packets.room_password, packet, parkour_bot)

	elseif id == 6 then
		ui.addTextArea(packets.record_submission, packet, parkour_bot)
	end
end)

onEvent("Loop", function()
	ui.addTextArea(packets.heartbeat, "", hidden_bot)

	local now = os.time()
	if #to_do > 0 and now >= next_file_check and now >= next_file_load then
		next_file_load = os.time() + 61000

		system.loadFile(files[to_do[1][1][1]]) -- first action, data, file
	end
end)

onEvent("NewPlayer", function(player)
	in_room[player] = true

	if player == parkour_bot and loaded then -- Start sync process
		sendSynchronization()
	end
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)

system.loadFile(files[1])
tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableMortCommand(true)
tfm.exec.newGame(0)
tfm.exec.setRoomMaxPlayers(50)
