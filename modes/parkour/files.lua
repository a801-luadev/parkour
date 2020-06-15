local next_file_load = os.time() + math.random(60500, 90500)
local player_ranks
local no_powers
local unbind
local bindNecessary
local killing = {}
local to_save = {}
local files = {
	--[[
		File values:

		- maps        (1)
		- ranks       (1)
		- modchat     (1)

		- ranking     (2)
		- weekranking (2)

		- lowmaps     (3)
		- banned      (3)
	]]

	[1] = 20, -- maps, ranks, modchat
	[2] = 21, -- ranking, weekranking
	[3] = 22, -- lowmaps, banned
}
local total_files = 3
local file_index = 1
local fetching_player_room = {}
local file_id = files[file_index]
local timed_maps = {
	week = {},
	hour = {}
}
players_file = {}

local data_migrations = {
	["0.0"] = function(player, data)
		data.parkour = data.modules.parkour
		data.drawbattle = data.modules.drawbattle

		data.modules = nil

		data.parkour.v = "0.6" -- version
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
		data.parkour.week_c = 0 -- completed maps this week
		data.parkour.week_r = timed_maps.week.last_reset -- last week reset
		data.parkour.hour_c = 0 -- completed maps this hour
		data.parkour.hour_r = os.time() + 60 * 60 * 1000 -- next hour reset
		data.parkour.help = 0 -- doesn't want help?

		data.parkour.cm = nil
	end,
	["0.1"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.ckpart = 1
		data.parkour.mort = 1
		data.parkour.pcool = 1
		data.parkour.pbut = 1
		data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
		data.parkour.killed = 0
		data.parkour.congrats = 1
		data.parkour.troll = 0
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
		data.parkour.hour_c = 0
		data.parkour.hour_r = os.time() + 60 * 60 * 1000
		data.parkour.help = 0
	end,
	["0.2"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.killed = 0
		data.parkour.hbut = 1
		data.parkour.congrats = 1
		data.parkour.troll = 0
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
		data.parkour.hour_c = 0
		data.parkour.hour_r = os.time() + 60 * 60 * 1000
		data.parkour.help = 0
	end,
	["0.3"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.hbut = 1
		data.parkour.congrats = 1
		data.parkour.troll = 0
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
		data.parkour.hour_c = 0
		data.parkour.hour_r = os.time() + 60 * 60 * 1000
		data.parkour.help = 0
	end,
	["0.4"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.troll = 0
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
		data.parkour.hour_c = 0
		data.parkour.hour_r = os.time() + 60 * 60 * 1000
		data.parkour.help = 0
	end,
	["0.5"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
		data.parkour.hour_c = 0
		data.parkour.hour_r = os.time() + 60 * 60 * 1000
		data.parkour.help = 0
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
			translatedChatMessage("kill_minutes", player, math.ceil((data.parkour.killed - os.time()) / 1000 / 60))
			if os.time() < data.parkour.killed then
				no_powers[player] = true
				unbind(player)
			else
				no_powers[player] = false
				if victory[player] then
					bindNecessary(player)
				end
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
	system.saveFile(filemanagers[id]:dump(data), id)
end)

onEvent("FileLoaded", function(id, data)
	data = filemanagers[id]:load(data)
	eventGameDataLoaded(data)
	if data.ranking or data.weekranking then -- the only file that can get written by rooms
		eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
	end
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
	local ts = os.time()

	next_file_load = ts + math.random(60500, 90500)
	file_index = file_index % total_files + 1
	file_id = files[file_index]

	local now = os.date("*t", ts / 1000) -- os.date is weird in tfm, *t accepts seconds, %d/%m/%Y accepts ms
	now.wday = now.wday - 1
	if now.wday == 0 then
		now.wday = 7
	end
	timed_maps.week.last_reset = os.date("%d/%m/%Y", ts - (now.wday - 1) * 24 * 60 * 60 * 1000)
	timed_maps.week.next_reset = os.date("%d/%m/%Y", ts + (8 - now.wday) * 24 * 60 * 60 * 1000)
end)

onEvent("NewPlayer", function(player)
	players_file[player] = nil -- don't cache lol
	system.loadPlayerData(player)
end)

onEvent("PlayerDataParsed", function(player, data)
	local now = os.time()
	if data.parkour.hour_r <= now then
		data.parkour.hour_c = 0
		data.parkour.hour_r = now + 60 * 60 * 1000
	end

	if data.parkour.week_r ~= timed_maps.week.last_reset then
		data.parkour.week_c = 0
		data.parkour.week_r = timed_maps.week.last_reset
	end
end)