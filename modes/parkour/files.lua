local WEEKLY_RESET_INIT = 1722204000000
local last_weekly_reset_ts
local player_ranks
local no_powers
local unbind
local bindNecessary
local NewBadgeInterface
local Quests, Milestones

local badges, titles

local dont_parse_data = {}

local files = {
	init = 17, -- ranks, maps, maps2, maps3, maps4, maps5, map_polls
	leaderboard = 77, -- ranking, weekly
	sanction = 63, -- sanction
	shop = 54, -- shop
	npc = 51, -- npc, xml
}
local scheduleFile

do
local settings_length = 9

local file_queue = { files.init, files.shop, files.leaderboard, files.sanction }
local file_schedule
local total_files = #file_queue
local file_index = 1
local next_file_load

function scheduleFile(name)
	if not files[name] then return end
	if file_schedule then
		file_schedule[name] = true
	else
		file_schedule = {[name] = true}
	end
	return true
end

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
		{14, "img@19fbafba2e9", "img@19fbafb9def"}, -- 60
		{15, "img@19fbafbacec", "img@19fbafba7b4"}, -- 65
		{16, "img@19fbafbbcac", "img@19fbafbb1ce"}, -- 70
	},
	[5] = { -- discord
		-- filePriority = true, -- always takes the value from the file

		{17, "1746ef93af1.png", "1746ef8f813.png"},
	},
	[6] = { -- records
		-- filePriority = true,

		{18, "1755b8540b8.png", "1755b851704.png"}, -- 1
		{19, "1755b858a36.png", "1755b85628e.png"}, -- 5
		{20, "1755b85f345.png", "1755b85cc7e.png"}, -- 10
		{21, "1755b865284.png", "1755b861ef0.png"}, -- 15
		{22, "1755baac7c8.png", "1755baa9e31.png"}, -- 20
		{23, "1755bab889c.png", "1755bab5995.png"}, -- 25
		{24, "1755babf3c0.png", "1755babbd2d.png"}, -- 30
		{25, "1755bac4ab9.png", "1755bac1ed3.png"}, -- 35
		{26, "1755bacbdd6.png", "1755bac996d.png"}, -- 40
		{27, "img@19fbaf8e63a", "img@19fbaf51523"}, -- 45
		{28, "img@19fbaf8d35c", "img@19fbaf51cbd"}, -- 50
		{29, "img@19fbaf8dacf", "img@19fbaf521e0"}, -- 55
		{30, "img@19fbaf8dfab", "img@19fbaf526c6"}, -- 60
	},
	[7] = { -- Lemonade Event
		{31, "img@197eae1e011", "img@197eae1cec8"},
	},
	[8] = { -- Halloween Event
		{32, "img@19a0404cea1", "img@19a04047b46"},
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
		data.quests = {}
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
	[10] = function(player, data)
		data.v = 11
		data.cskins[9] = 34
		--data.ownshop = nil
		--data.claim = nil
	end,
	[11] = function(player, data)
		data.v = 12
		data.cpower = data.cskins[8] -- currently equipped shop power

		-- reset equipped skins
		data.cskins = {}
		data.cslen = {0,0,0,0,0,0,0,0,0}

		local powers = data.powers
		local powuse = {}

		for i=1, #powers do
			powuse[i] = math.floor(((powers[i] * 100) % 100) + 0.5)
			powers[i] = math.floor(powers[i])
		end

		data.powuse = powuse
		data.ec = {data.gifts or 0} -- event coins
		data.ec[1] = data.ec[1] % 30 -- subtract gifts "spent"
		if data.ec[1] == 0 then data.ec[1] = nil end
		data.gifts = nil

		-- migrate skin ids
		local migrate_id
		for i=1, #data.skins do
			migrate_id = shop_migrate_ids[tostring(data.skins[i])]
			if migrate_id then
				data.skins[i] = migrate_id
			end
		end
	end,
	[12] = function(player, data)
		data.v = 13

		local old_quests = data.quests
		local new_quests = {
			0, -- daily skip ts
			0, -- weekly skip ts
			0, -- daily streak ts
			0, -- weekly streak ts
			0, -- daily completions
			0, -- weekly completions
			0, -- daily streak
			0, -- weekly streak
		}
		local quest, offset

		for i=1, 8 do
			quest = old_quests and old_quests[i]
			offset = 8 + 5 * (i - 1)

			if quest then
				new_quests[1 + offset] = quest.id -- quest type/id
				new_quests[2 + offset] = quest.ts or 0 -- completion timestamp
				new_quests[3 + offset] = quest.tg -- target
				new_quests[4 + offset] = quest.pg -- current progress
				new_quests[5 + offset] = quest.pr or 0 -- extra (e.g. power id)

				if quest.skp then
					new_quests[i > 4 and 2 or 1] = quest.skp
				end
			else
				new_quests[1 + offset] = 0
				new_quests[2 + offset] = 0
				new_quests[3 + offset] = 0
				new_quests[4 + offset] = 0
				new_quests[5 + offset] = 0
			end
		end

		data.quests = new_quests
		data.dc = { 0, 0, 0, 0, 0 } -- completions for each diff
	end,
}

local pdataFunctions = {}
pdataFunctions.__index = pdataFunctions

do
	local _cache = {
		powers = newSessionTable(players_file),
		skins = newSessionTable(players_file),
		cskins = newSessionTable(players_file),
	}
	local testskins = newSessionTable(players_file)

	local function refreshCache(file, key, start)
		local cache = start and _cache[key][file]

		if not cache then
			-- requests partial refresh & cache doesn't exist, no need for refresh
			if start then
				return
			end

			cache = {}
			start = 1
			_cache[key][file] = cache
		end

		local list = file[key]
		for i=start, #list do
			cache[list[i]] = i
		end

		return cache
	end

	local function removeCachedIndex(file, key, index)
		local cache = _cache[key][file]
		local list = file[key]

		if cache then
			cache[list[index]] = nil
		end

		table.remove(list, index)
		refreshCache(file, key, index)
	end

	function pdataFunctions.tester(file)
		return testskins[file] and true or false
	end

	function pdataFunctions.setTester(file, state)
		if state then
			if not testskins[file] then
				testskins[file] = {}
			end
		else
			testskins[file] = nil
		end
	end

	-- category can be nil, 8 or 0
	function pdataFunctions.findItem(file, id, category)
		if category == 0 then
			if not file.ec[id] or file.ec[id] <= 0 then
				return nil, "ec"
			end
			return id, "ec"
		end

		local power = category == 8
		local key = power and "powers" or "skins"
		if power and id == 1 or not power and default_skins[id] or file.ownshop or testskins[file] then
			return 0, key
		end

		local cache = _cache[key][file] or refreshCache(file, key)
		if cache[id] or power then
			return cache[id], key
		end

		key = "cskins"
		cache = _cache[key][file] or refreshCache(file, key)
		return cache[id], key
	end

	function pdataFunctions.addItem(file, id, category, amount)
		if file:findItem(id, category) then
			return
		end

		if category == 0 then
			if amount <= 0 then return end
			file.ec[id] = amount
			-- fill the gaps
			for i=1, id do
				if not file.ec[i] then
					file.ec[i] = 0
				end
			end
			return true
		end

		local key = category == 8 and "powers" or "skins"

		table.insert(file[key], id)
		refreshCache(file, key, #file[key])

		if category == 8 then
			table.insert(file.powuse, amount or 0)
		end
		return true
	end

	function pdataFunctions.removeItem(file, id, category)
		if category == 0 then
			return file:updateItem(id, 0, -file:getItemAmount(id, 0))
		end

		local index, key = file:findItem(id, category)
		if not index or index == 0 then
			return
		end

		if key == "cskins" then
			local sum = 0

			for i=1, 9 do
				sum = sum + file.cslen[i]
				if index <= sum then
					-- category doesn't match
					if category ~= i then return end
					break
				end
			end

			-- update cslen
			file.cslen[category] = file.cslen[category] - 1
		end

		removeCachedIndex(file, key, index)

		if category == 8 then
			table.remove(file.powuse, index)
		end

		return true
	end

	function pdataFunctions.getItemAmount(file, id, category)
		if category == 0 then return file.ec[id] or 0 end
		if category ~= 8 then return 0 end

		local cache = _cache.powers[file] or refreshCache(file, "powers")
		local uses = cache[id] and file.powuse[cache[id]]
		return uses or 0
	end

	function pdataFunctions.updateItem(file, id, category, useChange)
		local index = file:findItem(id, category)
		if index == 0 then return end
		if not index then
			return file:addItem(id, category, useChange)
		end

		if not useChange then return end

		local uses = file:getItemAmount(id, category)

		if category == 0 then
			file.ec[id] = math.max(0, uses + useChange)
			if file.ec[id] == 0 and id == #file.ec then
				-- remove fillers
				for i=id, 1, -1 do
					if file.ec[i] ~= 0 then break end
					file.ec[i] = nil
				end
			end
			return true
		end

		-- shop items other than powers has no amount field
		-- powers with 0 amount cant be updated
		if category ~= 8 or uses == 0 then return end

		uses = uses + useChange
		if uses > 1000000 then
			return
		end

		if uses > 0 then
			file.powuse[index] = uses
		else
			removeCachedIndex(file, "powers", index)
			table.remove(file.powuse, index)
			file:equip(8, 1)
		end

		return true
	end

	function pdataFunctions.resetEquipped(file)
		-- add back to skins
		if not file.ownshop then
			local len = #file.cskins
			local skinsOffset = #file.skins + 1
			local skinsIndex = skinsOffset
			local id

			for i=1, len do
				id = file.cskins[i]
				if not default_skins[id] then
					file.skins[skinsIndex] = id
					skinsIndex = skinsIndex + 1
				end
			end

			refreshCache(file, "skins", skinsOffset)
		end

		-- reset current skins
		file.cskins = {}
		_cache.cskins[file] = nil

		for i=1, 9 do
			file.cslen[i] = 0
		end
	end

	function pdataFunctions.reachedSkinLimit(file)
		return #file.skins + #file.cskins >= 100
	end

	function pdataFunctions.isEquipped(file, category, id)
		if testskins[file] and testskins[file][category] then
			return testskins[file][category] == id
		end

		if category == 8 then
			return file.cpower == id
		end

		-- if the category is not in cskins, it means it is equipped with the default skin
		if file.cslen[category] == 0 then
			return default_skins_by_cat[category] == id
		end

		local cache = _cache.cskins[file] or refreshCache(file, "cskins")
		return cache[id]
	end

	function pdataFunctions.getEquipped(file, category)
		if testskins[file] and testskins[file][category] then
			return testskins[file][category]
		end

		if category == 8 then
			return file.cpower
		end

		if file.cslen[category] == 0 then
			return default_skins_by_cat[category]
		end

		local first = 1
		for i=1, category - 1 do
			first = first + file.cslen[i]
		end

		local last = first + file.cslen[category] - 1
		local index = math.random(first, last)

		return file.cskins[index]
	end

	function pdataFunctions.unequip(file, category, id)
		if testskins[file] and testskins[file][category] == id then
			testskins[file][category] = nil
			return true
		end

		if category == 8 then
			file.cpower = default_skins_by_cat[category]
			return true
		end

		if not file:isEquipped(category, id) or file.cslen[category] == 0 then
			return
		end

		-- isEquipped makes sure we have a fresh cache
		local cache = _cache.cskins[file]

		-- remove from cskins
		local index = cache[id]
		removeCachedIndex(file, "cskins", index)

		-- update cslen
		file.cslen[category] = file.cslen[category] - 1

		-- add to skins
		if not default_skins[id] and not file.ownshop then
			file.skins[#file.skins + 1] = id
			refreshCache(file, "skins", #file.skins)
		end

		return true
	end

	function pdataFunctions.equip(file, category, id)
		if file:isEquipped(category, id) then
			return
		end

		if testskins[file] then
			testskins[file][category] = id
			return true
		end

		if category == 8 then
			file.cpower = id
			return true
		end

		if default_skins_by_cat[category] ~= id then
			local cache = _cache.skins[file] or refreshCache(file, "skins")
			local index = cache[id]
			if index then
				-- remove from skins
				removeCachedIndex(file, "skins", index)
			elseif not file.ownshop then
				return -- can't equip a skin that is not owned
			end
		end

		-- add to cskins
		local first = 1
		for i=1, category - 1 do
			first = first + file.cslen[i]
		end

		table.insert(file.cskins, first, id)
		refreshCache(file, "cskins", first)

		-- update cslen
		file.cslen[category] = file.cslen[category] + 1
		return true
	end

	local function quest_fn(field, daily, weekly)
		return function(file, index, new_value, add)
			local offset

			if field then
				offset = 8 + field + 5 * (index - 1)
			else
				offset = index > 4 and weekly or daily
			end

			if new_value then
				if add then
					file.quests[offset] = new_value + file.quests[offset]
				else
					file.quests[offset] = new_value
				end
			end

			return file.quests[offset]
		end
	end

	pdataFunctions.quest_skipped = quest_fn(nil, 1, 2)
	pdataFunctions.quest_streak_ts = quest_fn(nil, 3, 4)
	pdataFunctions.quest_completions = quest_fn(nil, 5, 6)
	pdataFunctions.quest_streak = quest_fn(nil, 7, 8)

	pdataFunctions.quest_id = quest_fn(1)
	pdataFunctions.quest_ts = quest_fn(2)
	pdataFunctions.quest_target = quest_fn(3)
	pdataFunctions.quest_progress = quest_fn(4)
	pdataFunctions.quest_extra = quest_fn(5)
end

function savePlayerData(player, immediate)
	if not players_file[player] then return end
	if not immediate then
		save_queue = save_queue or {}
		save_queue[player] = true
		return
	end

	eventPlayerDataUpdated(player, players_file[player])
	system.savePlayerData(
		player,
		json.encode(players_file[player])
	)
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
	if player:sub(1, 1) == "*" then return end

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
	setmetatable(data, pdataFunctions)
	eventOutPlayerDataParsed(player, data)
end)

onEvent("PlayerDataLoaded", function(player, data)
	if channels[player] then return end
	if not in_room[player] then return end
	if player:sub(1, 1) == "*" then return end

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
			print(data)
			translatedChatMessage("corrupt_data", player)
			return
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
	data.room = room.name
	data.settings.__len = settings_length
	data.badges.__len = #badges
	setmetatable(data, pdataFunctions)

	local playerObj = room.playerList[player]

	if playerObj then
		data.commu = playerObj.community
		data.playerid = playerObj.id
	end

	Quests.trigger_load(player, data)
	savePlayerData(player)
	eventPlayerDataParsed(player, data)
end)

onEvent("SavingFile", function(id, data, name)
	id = id or tostring(files[name])
	local new_data = filemanagers[id]:dump(data)
	if not new_data then return end
	system.saveFile(new_data, id)
end)

onEvent("FileLoaded", function(id, data)
	data = filemanagers[id]:load(data)
	eventGameDataLoaded(data, id)
end)

onEvent("Loop", function()
	local now = os.time()
	if now >= next_file_load then
		local file_id
		if file_schedule then
			for name in next, file_schedule do
				file_id = files[name]
				file_schedule[name] = nil
				break
			end
			if not next(file_schedule) then
				file_schedule = nil
			end
		end
		if not file_id then
			file_id = file_queue[file_index]
			file_index = file_index % total_files + 1
		end
		system.loadFile(file_id)
		next_file_load = now + math.random(10500, 13000)
	end
end)

-- this event is called after every event
-- we save here using 2nd parameter (immediate save)
-- this is to avoid saving same player too many times in a single event
onEvent("After", function()
	if not save_queue then return end
	for player in next, save_queue do
		savePlayerData(player, true)
	end
	save_queue = nil
end)

onEvent("GameStart", function()
	system.loadFile(file_queue[file_index])
	local ts = os.time()

	next_file_load = ts + math.random(10500, 15500)
	file_index = file_index % total_files + 1

	-- os.date is weird in tfm, *t accepts seconds, %d/%m/%Y accepts ms
	-- so we just don't use it here
	local a_week = 7 * 24 * 60 * 60 * 1000
	last_weekly_reset_ts = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
end)

onEvent("NewPlayer", function(player)
	players_file[player] = nil -- don't cache lol

	if player:sub(1, 1) == "*" then
		enableSpecMode(player, true)
	else
		system.loadPlayerData(player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	if data.week[2] ~= last_weekly_reset_ts then
		-- TODO can remove this after aug 5 
		if not tonumber(data.week[2]) and last_weekly_reset_ts == WEEKLY_RESET_INIT then
			return
		end

		data.week[1] = 0
		data.week[2] = last_weekly_reset_ts
		savePlayerData(player)
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