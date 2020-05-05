local next_file_load = os.time() + math.random(60500, 90500)
local player_ranks
local no_powers
local unbind
local killing = {}
local to_save = {}
local files = {
	--[[
		File values:

		- maps     (1)
		- ranks    (1)

		- banned   (2)
		- ranking  (2)

		- lowmaps  (3)
	]]

	[1] = 1, -- maps, ranks
	[2] = 2, -- ranking, banned
	[3] = 10, -- lowmaps
}
local total_files = 3
local file_index = 1
local fetching_player_room = {}
local file_id = files[file_index]
players_file = {}

local data_migrations = {
	["0.0"] = function(player, data)
		data.parkour = data.modules.parkour
		data.drawbattle = data.modules.drawbattle

		data.modules = nil

		data.parkour.v = "0.5" -- version
		data.parkour.c = data.parkour.cm -- completed maps
		data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
		data.parkour.mort = 1 -- /mort hotkey
		data.parkour.pcool = 1 -- power cooldowns
		data.parkour.pbut = 1 -- powers button
		data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
		data.parkour.killed = 0
		data.parkour.hbut = 1 -- help button
		data.parkour.congrats = 1 -- contratulations message
		data.parkour.troll = 0

		data.parkour.cm = nil
	end,
	["0.1"] = function(player, data)
		data.parkour.v = "0.5"
		data.parkour.ckpart = 1
		data.parkour.mort = 1
		data.parkour.pcool = 1
		data.parkour.pbut = 1
		data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
		data.parkour.killed = 0
		data.parkour.congrats = 1
		data.parkour.troll = 0

	end,
	["0.2"] = function(player, data)
		data.parkour.v = "0.5"
		data.parkour.killed = 0
		data.parkour.hbut = 1
		data.parkour.congrats = 1
		data.parkour.troll = 0

	end,
	["0.3"] = function(player, data)
		data.parkour.v = "0.5"
		data.parkour.hbut = 1
		data.parkour.congrats = 1
		data.parkour.troll = 0

	end,
	["0.4"] = function(player, data)
		data.parkour.v = "0.5"
		data.parkour.troll = 0
	end
}

local function savePlayerData(player)
	if not players_file[player] then return end

	if not to_save[player] then
		to_save[player] = true
		system.loadPlayerData(player)
	end
end

onEvent("PlayerDataLoaded", function(player, data)
	if player == send_channel or player == recv_channel then return end
	if in_room[player] then return end
	online[player] = true

	if data == "" then
		data = {}
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
		end
	end

	local fetch = fetching_player_room[player]
	if fetch then
		tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. (data.room or "unknown"), fetch[1])
		fetching_player_room[player] = nil
	end

	if killing[player] and data.parkour then
		data.parkour.killed = os.time() + killing[player] * 60 * 1000
		system.savePlayerData(player, json.encode(data))
	end
end)

onEvent("PlayerDataLoaded", function(player, data)
	if player == send_channel or player == recv_channel then return end
	if not in_room[player] then return end
	online[player] = true

	local corrupt
	if data == "" then
		data = {}
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
			translatedChatMessage("corrupt_data", player)
			corrupt = true
		end
	end

	if not data.parkour then
		if data.modules then
			data.parkour = {v = "0.0"}
		else
			data.parkour = {
				v = "0.1", -- version
				c = 0 -- completed maps
			}
		end
	end

	local migration = data_migrations[data.parkour.v or "0.0"]
	while migration do
		corrupt = true -- just so this process is made only once
		migration(player, data)
		migration = data_migrations[data.parkour.v]
	end

	local fetch = fetching_player_room[player]
	if fetch then
		tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. room.name, fetch[1])
		fetching_player_room[player] = nil
	end

	if players_file[player] then
		local old = players_file[player]
		if old.parkour.killed < data.parkour.killed then
			old.parkour.killed = data.parkour.killed
			if os.time() < data.parkour.killed then
				no_powers[player] = true
				unbind(player)
			end
		end

		if to_save[player] then
			to_save[player] = false
			system.savePlayerData(player, json.encode(old))
		end
		return
	end

	players_file[player] = data

	players_file[player].room = room.name
	system.savePlayerData(
		player,
		json.encode(players_file[player])
	)

	eventPlayerDataParsed(player, data)
end)

onEvent("SavingFile", function(id, data)
	if data.ranking then -- the only file that can get written by rooms
		system.saveFile(json.encode(data), id)
	end
end)

onEvent("FileLoaded", function(id, data)
	data = json.decode(data)
	eventGameDataLoaded(data)
	eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
end)

onEvent("Loop", function()
	local now = os.time()
	if now >= next_file_load then
		system.loadFile(file_id)
		next_file_load = now + math.random(60500, 63000)
		file_index = file_index % total_files + 1
		file_id = files[file_index]
	end

	local to_remove, count = {}, 0
	for player, data in next, fetching_player_room do
		if now >= data[2] then
			count = count + 1
			to_remove[count] = player
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n> is offline.", data[1])
		end
	end

	for idx = 1, count do
		fetching_player_room[to_remove[idx]] = nil
	end
end)

onEvent("GameStart", function()
	system.loadFile(file_id)
	next_file_load = os.time() + math.random(60500, 90500)
	file_index = file_index % total_files + 1
	file_id = files[file_index]
end)

onEvent("NewPlayer", function(player)
	system.loadPlayerData(player)
end)
