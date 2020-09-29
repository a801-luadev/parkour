local next_file_load = os.time() + math.random(60500, 90500)
local player_ranks
local no_powers
local unbind
local bindNecessary
local NewBadgeInterface
local to_save = {}
local files = {
	--[[
		File values:

		- maps        (1)
		- ranks       (1)
		- chats       (1)

		- ranking     (2)
		- weekranking (2)

		- lowmaps     (3)
		- banned      (3)
	]]

	[1] = 20, -- maps, ranks, chats
	[2] = 21, -- ranking, weekranking
	[3] = 22, -- lowmaps, banned
}
local total_files = 3
local file_index = 1
local file_id = files[file_index]
local timed_maps = {
	week = {},
	hour = {}
}
local badges = {
	[1] = { -- former staff
		{ 1, "1745f43783e.png", "1745f432e33.png"},
	},
	[2] = { -- leaderboard
		{ 2, "17435b0098c.png", "1745a88ffce.png"}, -- 1
		{ 3, "17435b03030.png", "1745a892d25.png"}, -- 2
		{ 4, "17435b06052.png", "1745a89eb17.png"}, -- 3
		{ 5, "17435af7df1.png", "1745a89bc52.png"}, -- 4
		{ 6, "17435afd7c2.png", "1745a899776.png"}, -- 5
	},
	[3] = { -- weekly podium
		{ 7, "1745a660504.png", "1745a6bfa2c.png"},
	},
	[4] = { -- hour records
		{ 8, "1745a5547a9.png", "1745afa8577.png"}, -- 30
		{ 9, "1745a53f4c9.png", "1745afac029.png"}, -- 35
		{10, "1745a5506b3.png", "1745afaf043.png"}, -- 40
		{11, "1745a54a1e3.png", "1745afb4333.png"}, -- 45
		{12, "1745a541bdd.png", "1745afc2c32.png"}, -- 50
		{13, "1745a54869e.png", "1745afc5c2e.png"}, -- 55
	},
	[5] = { -- discord
		filePriority = true, -- always takes the value from the file

		{14, "1746ef93af1.png", "1746ef8f813.png"},
	},
	[6] = { -- records
		filePriority = true,

		{15, "174dc1c8c4b.png", "174dc1c4ae8.png"}, -- 1
		{16, "174dc220359.png", "174dc21e1c8.png"},
		{17, "174dc22969c.png", "174dc22211d.png"},
	},
}
players_file = {}

local data_migrations = {
	["0.0"] = function(player, data)
		data.parkour = data.modules.parkour
		data.drawbattle = data.modules.drawbattle

		data.modules = nil

		data.parkour.v = "0.1" -- version
		data.parkour.c = data.parkour.cm -- completed maps

		data.parkour.cm = nil
	end,
	["0.1"] = function(player, data)
		data.parkour.v = "0.2"
		data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
		data.parkour.mort = 1 -- /mort hotkey
		data.parkour.pcool = 1 -- power cooldowns
		data.parkour.pbut = 1 -- powers button
		data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> azerty
	end,
	["0.2"] = function(player, data)
		data.parkour.v = "0.3"
		data.parkour.killed = 0
	end,
	["0.3"] = function(player, data)
		data.parkour.v = "0.4"
		data.parkour.hbut = 1 -- help button
		data.parkour.congrats = 1 -- contratulations message
	end,
	["0.4"] = function(player, data)
		data.parkour.v = "0.5"
		data.parkour.troll = 0
	end,
	["0.5"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.week_c = 0 -- completed maps this week
		data.parkour.week_r = timed_maps.week.last_reset -- last week reset
		data.parkour.hour_c = 0 -- completed maps this hour
		data.parkour.hour_r = os.time() + 60 * 60 * 1000 -- next hour reset
		data.parkour.help = 0 -- doesn't want help?
	end,
	["0.6"] = function(player, data)
		data.parkour.v = "0.7"
		data.parkour.keys = {}
		data.parkour.badges = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	end,
	["0.7"] = function(player, data)
		data.parkour.v = "0.8"
		data.parkour.badges[13] = 0
		data.parkour.badges[14] = 0
	end,
	["0.8"] = function(player, data)
		data.parkour.v = "0.9"

		local old_badges = data.parkour.badges
		local new_badges = {0, 0, 0, 0, 0, 0}

		local limit
		for i = 1, 5 do
			if i == 2 then
				limit = 5
			elseif i == 4 then
				limit = 6
			else
				limit = 1
			end

			for j = limit, 1, -1 do
				if old_badges[ badges[i][j][1] ] == 1 then
					new_badges[i] = j
					break
				end
			end
		end

		data.parkour.badges = old_badges
	end
}

function savePlayerData(player)
	if not players_file[player] then return end

	if not to_save[player] then
		to_save[player] = true
		system.loadPlayerData(player)
	end
end

local function updateData(player, data)
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
		migration(player, data)
		migration = data_migrations[data.parkour.v]
	end
end

onEvent("PlayerDataLoaded", function(player, data)
	if player == send_channel or player == recv_channel then return end
	if in_room[player] then return end

	if data == "" then
		data = {}
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
		end
	end

	updateData(player, data)

	if not data.hidden then
		if not data.commu then
			online[player] = "xx"
		else
			online[player] = data.commu
		end
	end

	eventOutPlayerDataParsed(player, data)
end)

onEvent("PlayerDataLoaded", function(player, data)
	if player == send_channel or player == recv_channel then return end
	if not in_room[player] then return end

	if data == "" then
		data = {}
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
			translatedChatMessage("corrupt_data", player)
		end
	end

	updateData(player, data)

	if not data.hidden then
		if not data.commu then
			online[player] = room.community
		else
			online[player] = data.commu
		end
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

		local p_badges = data.parkour.badges
		for index = 1, #badges do
			if badges[index].filePriority then
				if old.parkour.badges[index] ~= p_badges[index] then
					old.parkour.badges[index] = p_badges[index]
					NewBadgeInterface:show(player, index, math.max(p_badges[index], 1))
				end
			end
		end

		eventPlayerDataUpdated(player, data)

		if to_save[player] then
			to_save[player] = false
			system.savePlayerData(player, json.encode(old))
		end
		return
	end

	players_file[player] = data
	players_file[player].room = room.name

	if room.playerList[player] then
		players_file[player].commu = room.playerList[player].community
	end

	eventPlayerDataParsed(player, data)

	system.savePlayerData(
		player,
		json.encode(players_file[player])
	)
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

onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 2 then -- update pdata
		if in_room[packet] then
			system.loadPlayerData(packet)
		end
	end
end)