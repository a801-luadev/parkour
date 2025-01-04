local WEEKLY_RESET_INIT = 1722204000000
local last_weekly_reset_ts
local player_ranks
local no_powers
local unbind
local bindNecessary
local NewBadgeInterface
local CompletedQuestsInterface
local QuestsInterface
local getQuestsResetTime

local badges, titles
local default_skins = { [1] = 1, [2] = 1, [7] = 1, [28] = 1, [46] = 1, [57] = 1, [90] = 1 }

local quests
local fillQuests
local power_quest = {}
local dont_parse_data = {}

local files = {
	--[[
		File values:

		- ranks       (1)
		- maps        (1)
		- maps2        (1)
		- maps3        (1)

		- ranking     (2)
		- weekly      (2)

		- sanction    (3)
	]]

	[1] = 40, -- ranks, maps, maps2, maps3
	[2] = 21, -- ranking, weekly
	[3] = 43, -- sanction
}

do
local total_files = 3
local file_index = 1
local settings_length = 9
local file_id = files[file_index]
local next_file_load = os.time() + math.random(60500, 90500)

badges = { -- badge id, small image, big image
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
		-- filePriority = true, -- always takes the value from the file

		{14, "1746ef93af1.png", "1746ef8f813.png"},
	},
	[6] = { -- records
		-- filePriority = true,

		{15, "1755b8540b8.png", "1755b851704.png"}, -- 1
		{16, "1755b858a36.png", "1755b85628e.png"}, -- 5
		{17, "1755b85f345.png", "1755b85cc7e.png"}, -- 10
		{18, "1755b865284.png", "1755b861ef0.png"}, -- 15
		{19, "1755baac7c8.png", "1755baa9e31.png"}, -- 20
		{20, "1755bab889c.png", "1755bab5995.png"}, -- 25
		{21, "1755babf3c0.png", "1755babbd2d.png"}, -- 30
		{22, "1755bac4ab9.png", "1755bac1ed3.png"}, -- 35
		{23, "1755bacbdd6.png", "1755bac996d.png"}, -- 40
	},
}
titles = {
	piglet = {
		code = "T_496",
		requirement = 6000,
		field = "tc" -- map count
	},
	checkpoint = {
		code = "T_497",
		requirement = 3000,
		field = "cc" -- checkpoint count
	},
	press_m = {
		code = "T_498",
		requirement = 1500,
		field = "tc"
	}
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

		data.parkour.congrats = 1 -- congratulations message
	end,

	["0.4"] = function(player, data)


		data.parkour.v = "0.5"
		data.parkour.troll = 0
	end,
	["0.5"] = function(player, data)
		data.parkour.v = "0.6"
		data.parkour.week_c = 0 -- completed maps this week
		data.parkour.week_r = last_weekly_reset_ts -- last week reset
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

		data.parkour.badges = new_badges
	end,
	["0.9"] = function(player, data)
		data.v = 0 -- better

		data.c = data.parkour.c -- completed maps
		data.killed = data.parkour.killed -- sanction end
		data.kill = data.parkour.troll -- last sanction duration
		data.keys = data.parkour.keys -- power keys
		data.week = {data.parkour.week_c, data.parkour.week_r} -- maps this week
		data.hour_r = os.time()
		data.hour = {} -- maps in the last hour
		data.badges = data.parkour.badges -- badges
		data.settings = {
			data.parkour.ckpart, -- particle checkpoints (1) or flags (0)
			data.parkour.mort, -- M (1) or DEL (0) or /mort
			data.parkour.pcool, -- show power cooldowns
			data.parkour.pbut, -- show powers button
			data.parkour.keyboard, -- qwerty (1) or azerty (0)
			data.parkour.hbut, -- show help button
			data.parkour.congrats, -- show congratulations messages
			data.parkour.help -- show no help line
		}
		-- data.commu = "en"
		-- data.room = "en-#parkour1"
		-- data.langue = "en"
		-- data.spec = nil
		-- data.banned = nil
		-- data.private_maps = nil
		-- data.hidden = nil

		data.parkour = nil
		data.drawbattle = nil
	end,
	[0] = function(player, data)
		data.v = 1

		data.report = true
		-- data.namecolor = nil
	end,
	[1] = function(player, data)
		data.v = 2

		for index = 1, 8 do
			if not data.settings[index] then
				if index == 5 then -- keyboard
					data.settings[index] = (room.playerList[player] or room).community == "fr" and 0 or 1
				elseif index >= 1 and index <= 7 then
					data.settings[index] = 1
				else
					data.settings[index] = 0
				end
			end
		end
	end,
	[2] = function(player, data)
		data.v = 3

		data.tc = 0 -- map counter for titles
		data.cc = 0 -- checkpoint counter for titles
	end,
	[3] = function(player, data)
		data.v = 4

		data.settings[2] = (data.settings[2] == 1 and 77 or 46)
	end,
	[4] = function(player, data)
		data.v = 5

		data.bancount = 0
		data.lastsanction = nil
		data.bannedby = nil
		--data.playerid = tfm.get.room.playerList[player].id
	end,
	[5] = function(player, data)
		data.v = 6

		data.coins = math.floor(data.c * 0.10)
		data.skins = { ["1"] = 1, ["2"] = 1, ["7"] = 1, ["28"] = 1, ["46"] = 1 }

		-- small box, big box, trampoline, balloon, choco, cloud, rip
		data.cskins = { 1, 2, 7, 28, 46 }
	end,
	[6] = function(player, data)
		data.v = 7

		local questList = {}
		local dailyQuests = fillQuests(data, questList, false)
		local allQuests = fillQuests(data, dailyQuests, true)

		data.quests = allQuests
		--data.killedby
	end,
	[7] = function(player, data)
		data.v = 8
		data.namecolor = nil
		data.settings[4] = 1
		data.settings[6] = 1

		local skins = {}

		for key in next, data.skins do
			if not default_skins[tonumber(key)] then
				skins[1 + #skins] = tonumber(key)
			end
		end

		data.skins = skins
		--data.gifts = nil
	end,
	[8] = function(player, data)
		data.v = 9
		data.cskins[6] = 57
		data.cskins[7] = 90
	end,
	[9] = function(player, data)
		data.v = 10
		data.cskins[8] = 1
		data.powers = {}
	end,
}

local pdataFunctions = {}
pdataFunctions.__index = pdataFunctions

do
	-- weak keys so it gets deleted when pdata is not referenced anywhere else
	local _cache = {
		powers = setmetatable({}, { __mode = "k" }),
		skins = setmetatable({}, { __mode = "k" }),
		_power_uses = setmetatable({}, { __mode = "k" }),
	}

	function pdataFunctions.refreshCache(file, key)
		local cache = {}
		_cache[key][file] = cache

		local list = file[key]
		for i=1, #list do
			cache[key == "powers" and math.floor(list[i]) or list[i]] = i
		end

		if key == "powers" then
			local uses = {}
			local val
			_cache._power_uses[file] = uses
			for i=1, #list do
				val = (list[i] * 100) % 100
				if val ~= 0 then
					uses[math.floor(list[i])] = math.floor(val + 0.5)
				end
			end
		end

		return cache
	end

	function pdataFunctions.findShopItem(file, id, power)
		if power and id == 1 or not power and default_skins[id] then
			return 0
		end
		local key = power and "powers" or "skins"
		local cache = _cache[key][file]
		if not cache then
			cache = file:refreshCache(key)
		end
		if power then
			id = math.floor(id)
		end
		return cache[id]
	end

	function pdataFunctions.addShopItem(file, id, power)
		if file:findShopItem(id, power) then
			return
		end

		local key = power and "powers" or "skins"
		table.insert(file[key], id)
		_cache[key][file][power and math.floor(id) or id] = #file[key]
		if power then
			local val = (id * 100) % 100
			if val ~= 0 then
				_cache._power_uses[file][math.floor(id)] = math.floor(val + 0.5)
			end
		end
		return true
	end

	function pdataFunctions.removeShopItem(file, id, power)
		local index = file:findShopItem(id, power)
		if not index or index == 0 then
			return
		end

		local key = power and "powers" or "skins"
		table.remove(file[key], index)

		if index == #file[key] + 1 then
			_cache[key][file][power and math.floor(id) or id] = nil
			if power then
				_cache._power_uses[file][math.floor(id)] = nil
			end
		else
			file:refreshCache(key)
		end

		return true
	end

	function pdataFunctions.getPowerUse(file, id)
		local cache = _cache._power_uses[file]
		if not cache then
			cache = file:refreshCache("powers")
		end
		return cache[id]
	end

	function pdataFunctions.updatePower(file, id, useChange)
		local index = file:findShopItem(id, true)
		if not index or index == 0 then
			if useChange > 0 then
				return file:addShopItem(id + useChange / 100, true)
			end
			return
		end

		local uses = file:getPowerUse(id)
		if not uses then
			return
		end

		uses = uses + useChange
		if uses > 99 then
			return
		end

		if uses > 0 then
			file.powers[index] = math.floor(id) + uses / 100
			_cache._power_uses[file][math.floor(id)] = uses
		else
			file.cskins[8] = 1
			table.remove(file.powers, index)
			file:refreshCache("powers")
		end

		return true
	end
end

function getQuestsResetTime()
	local currentTime = os.time() + 60 * 60 * 1000
	local currentDate = os.date("*t", os.time() / 1000)
	local day = 24 * 60 * 60 * 1000

	currentDate.wday = currentDate.wday - 2

	if currentDate.wday == -1 then
		currentDate.wday = 6
	end

	local last_daily_reset = math.floor(currentTime / day) * day
	local next_daily_reset = math.ceil(currentTime / day) * day

	local last_weekly_reset = last_daily_reset - currentDate.wday * day
	local next_weekly_reset = last_weekly_reset + 7 * day

	local reset_times = {last_daily_reset - 60 * 60 * 1000, last_weekly_reset - 60 * 60 * 1000, next_daily_reset, next_weekly_reset}

	return reset_times
end

function savePlayerData(player, delay)
	if not players_file[player] then return end

	if delay then
		queueForSave(player)
		return
	end

	system.savePlayerData(
		player,
		json.encode(players_file[player])
	)
	eventPlayerDataUpdated(player, players_file[player])
end

local function updateData(player, data)
	if not data.v and not data.parkour then
		if data.modules then
			data.parkour = {v = "0.0"}
		else
			data.parkour = {
				v = "0.1", -- version
				c = 0 -- completed maps
			}
		end
	end

	local migration = data_migrations[data.v or data.parkour.v or "0.0"]
	while migration do
		migration(player, data)
		migration = data_migrations[data.v or data.parkour.v]
	end
end

onEvent("PlayerDataLoaded", function(player, data)
	if channels[player] then return end
	if in_room[player] then return end

	if dont_parse_data[player] then
		dont_parse_data[player] = nil
		local isHidden = data:find('"hidden":true')
		local commu = data:match('"commu":"(.-)"') or "xx"

		if isHidden then
			hidden[player] = commu
		else
			online[player] = commu
		end

		return
	end

	if data == "" then
		data = {}
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
		end
	end

	if data.v ~= data_version then
		updateData(player, data)
	end

	local commu = data.commu or "xx"
	if not data.hidden then
		online[player] = commu
	else
		hidden[player] = commu
	end

	data.settings.__len = settings_length
	eventOutPlayerDataParsed(player, data)
end)

onEvent("PlayerDataLoaded", function(player, data)
	if channels[player] then return end
	if not in_room[player] then return end

	if dont_parse_data[player] then
		dont_parse_data[player] = nil
		local isHidden = data:find('"hidden":true')
		local commu = data:match('"commu":"(.-)"') or room.community

		if isHidden then
			hidden[player] = commu
		else
			online[player] = commu
		end

		return
	end

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

	if data.v ~= data_version then
		updateData(player, data)
	end

	if ranks.hidden[player] then
		data.hidden = true
	end

	local commu = data.commu or room.community
	if not data.hidden then
		online[player] = commu
	else
		hidden[player] = commu
	end

	if players_file[player] then
		return
	end

	players_file[player] = data
	players_file[player].room = room.name
	players_file[player].settings.__len = settings_length
	players_file[player].badges.__len = #badges
	setmetatable(players_file[player], pdataFunctions)

	if room.playerList[player] then
		players_file[player].commu = room.playerList[player].community
		players_file[player].playerid = room.playerList[player].id
	end

	if players_file[player].quests then
		local reset_time = getQuestsResetTime() -- reset_time = {last_daily_reset, last_weekly_reset, next_daily_reset, next_weekly_reset}

		local isDailyReset = false
		local isWeeklyReset = false
		local questTable = players_file[player].quests

		for i = 1, #questTable do
			local quest = questTable[i]
		
			if i <= 4 then
				if (quest.ts and quest.ts < reset_time[1]) or (quest.skp and quest.skp > 1 and quest.skp < reset_time[1]) then
					isDailyReset = true
				end
			else
				if (quest.ts and quest.ts < reset_time[2]) or (quest.skp and quest.skp > 1 and quest.skp < reset_time[2]) then
					isWeeklyReset = true
				end
			end
		end

		if isDailyReset or isWeeklyReset then
			if isDailyReset then
				local daily_text = translatedMessage("daily_q", player)
				daily_text = daily_text:lower()
				translatedChatMessage("quest_reset", player, daily_text)

				questTable = fillQuests(players_file[player], questTable, false)
			end
		
			if isWeeklyReset then
				local weekly_text = translatedMessage("weekly_q", player)
				weekly_text = weekly_text:lower()

				translatedChatMessage("quest_reset", player, weekly_text)
				questTable = fillQuests(players_file[player], questTable, true)
			end
		end

		for questID = 1, #questTable do
			if questTable[questID].id == 6 then
				if not power_quest[player] then
					power_quest[player] = {}
				end

				if questID <= 4 then
					power_quest[player].d = questTable[questID].pr
					power_quest[player].di = questID
				else
					power_quest[player].w = questTable[questID].pr
					power_quest[player].wi = questID
				end
			end
		end	

		players_file[player].quests = questTable
	end

	savePlayerData(player, true)
	eventPlayerDataParsed(player, data)
end)

onEvent("SavingFile", function(id, data)
	system.saveFile(filemanagers[id]:dump(data), id)
end)

onEvent("FileLoaded", function(id, data)
	data = filemanagers[id]:load(data)
	eventGameDataLoaded(data, id)
end)

onEvent("Loop", function()
	local now = os.time()
	if now >= next_file_load then
		system.loadFile(file_id)
		next_file_load = now + math.random(10500, 13000)
		file_index = file_index % total_files + 1
		file_id = files[file_index]
	end
end)

onEvent("GameStart", function()
	system.loadFile(file_id)
	local ts = os.time()

	next_file_load = ts + math.random(10500, 15500)
	file_index = file_index % total_files + 1
	file_id = files[file_index]

	-- os.date is weird in tfm, *t accepts seconds, %d/%m/%Y accepts ms
	-- so we just don't use it here
	local a_week = 7 * 24 * 60 * 60 * 1000
	last_weekly_reset_ts = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
end)

onEvent("NewPlayer", function(player)
	players_file[player] = nil -- don't cache lol
	system.loadPlayerData(player)
end)

onEvent("PlayerDataParsed", function(player, data)
	if data.week[2] ~= last_weekly_reset_ts then
		-- TODO can remove this after aug 5 
		if not tonumber(data.week[2]) and last_weekly_reset_ts == WEEKLY_RESET_INIT then
			return
		end

		data.week[1] = 0
		data.week[2] = last_weekly_reset_ts
		savePlayerData(player, true)
	end
end)

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == packets.bots.remote_command then
		local targetPlayer, targetRoom, command, executer = string.match(packet, "([^\000]+)\000([^\000]+)\000([^\000]+)\000([^\000]*)")

		if not in_room[targetPlayer] and targetRoom ~= room.name then
			return
		end

		executer = executer == "" and "Parkour#0568" or executer
		eventChatCommand(executer, command)

	elseif id == packets.bots.update_pdata then
		local player, fields = string.match(packet, "([^\000]+)\000([^\000]+)")
		local pdata = players_file[player]
		if not in_room[player] or not pdata then
			return
		end

		local key, value, done, parsed
		for fieldPair in fields:gmatch('([^\001]+)') do
			key, value = fieldPair:match('([^\002]+)\002([^\002]+)')
			done, parsed = pcall(json.decode, value)
			if not done then
				sendPacket(
					"common", packets.rooms.update_error,
					player .. "\000" .. key .. "\000" .. value
				)
				return
			end

			if key == "badges" then
				local p_badges = pdata.badges
				for index = 1, #parsed do
					if parsed[index] ~= p_badges[index] then
						NewBadgeInterface:show(
							player, index, math.max(parsed[index] or 1, 1)
						)
					end
				end
			end

			pdata[key] = parsed

			if key == "killed" then
				checkKill(player)
			end
		end

		savePlayerData(player)
	end
end)
end