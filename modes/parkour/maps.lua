--[[
	The map quantity is HUGE (over 300). We need a system that:
	- Picks a random map quickly
	- Does NOT repeat maps unless the whole rotation has played
	- Is able to switch the map list quickly (add/remove maps)

	This system uses sections:
	Every section is a pointer to the index of a map, depending
	on the maps per section quantity. If it is 10, section 0
	points to the maps 1-10, section 1 to the maps 11-20 and so
	on.

	The sections do NOT point to the map, but to the index.
	This way we can update the maps easily.

	We shuffle these sections when they're calculated, and keep
	a pointer to the next section, which we increase every time
	we want to select a map. Every section has an internal
	counter too, and it works the same way.

	When a section is selected, if the maps it contains weren't
	shuffled, they will be shuffled at that moment. When all
	the maps are played, the sections will reshuffle and their
	maps will be flagged as unshuffled.
	This way we can do small shuffles without the need of
	shuffling a big array with a lot of elements. Due to the
	runtime limitations in transformice lua, this is way better
]]

local global_poll = false
local first_data_load = true
local maps_per_section = math.random(10, 20)
local maps = {
	polls = {_count = 0},
}
local current_difficulty = 0
local maplist_index = 0

for i=1,3 do
	maps[i] = {
		sections = {
			_count = 0,
			_pointer = 0,
			_map_pointer = 1,
		},
		list = {7171137},
		count = 1,
		odds = 100,
	}
end

local is_invalid = false
local count_stats = true
local map_change_cd = 0

current_map = nil

local levels
local perms
local review_mode
local records_admins = string.find(room.lowerName, "records", 1, true) and {}
if records_admins and submode == "smol" then
	records_admins = nil
end

if records_admins then
	tfm.exec.playerVictory = function(name)
		tfm.exec.removeCheese(name)
		eventPlayerWon(name)
	end
end

local function selectMap(sections, list, count)
	if sections._map_pointer > maps_per_section then
		-- All maps played, reset sections
		sections._map_pointer = 1
		sections._pointer = 0
		sections._count = 0
	end

	if sections._count == 0 then
		-- No sections, calculate them
		local quantity = math.ceil(count / maps_per_section)

		local section, start, limit
		for i = 1, quantity do
			start = maps_per_section * (i - 1)
			limit = math.min(maps_per_section * i, count)

			section = {}
			for j = 1, limit - start do
				section[j] = j + start
			end

			sections[i] = section
		end

		-- shuffle sections
		local current, swap
		for index = 1, quantity do
			swap = math.random(index, quantity)

			current = sections[index]
			sections[index] = sections[swap]
			sections[swap] = current
		end

		sections._count = quantity
	end

	-- make pointer go through 1 to _count
	-- 0 -> 1, _count -> 1, x -> x + 1
	sections._pointer = sections._pointer % sections._count + 1

	local section = sections[sections._pointer]
	if not section._count then -- the section has not been shuffled!
		section._count = #section

		local current, swap
		for index = 1, section._count do
			swap = math.random(index, section._count)

			current = section[index]
			section[index] = section[swap]
			section[swap] = current
		end

	elseif (section._pointer == sections._count -- is it the las section?
			and section._count < maps_per_section -- does it have less maps than a regular section?
			and sections._map_pointer > section._count) then -- have all the maps from this section been played?
		sections._map_pointer = sections._map_pointer + 1 -- increase map pointer
		return selectMap(sections, list, count) -- and select another map
	end

	local map = section[sections._map_pointer]

	if sections._pointer == sections._count then
		-- if it is the last section, the next map pointer has to be increased
		sections._map_pointer = sections._map_pointer + 1
	end

	maplist_index = map
	return list[map]
end

local function newMap()
	count_stats = not review_mode
	map_change_cd = os.time() + 20000

	-- This might break if we move them to different files
	local map
	local chosen = math.random(maps[3].odds)
	for i=1,3 do
		if chosen <= maps[i].odds then
			current_difficulty = i
			map = selectMap(maps[i].sections, maps[i].list, maps[i].count)
			break
		end
	end

	current_map = map
	tfm.exec.newGame(map, not records_admins and math.random(3000000) <= 1000000)
end

local function invalidMap(arg)
	levels = nil
	is_invalid = os.time() + 3000
	tfm.exec.chatMessage("<r>" .. room.currentMap)
	translatedChatMessage("corrupt_map")
	translatedChatMessage("corrupt_map_" .. arg)
end

local function getTagProperties(tag)
	local properties = {}
	for name, value in string.gmatch(tag, '(%S+)%s*=%s*"([^"]*)"') do
		properties[name] = tonumber(value) or value
	end
	return properties
end

onEvent("GameDataLoaded", function(data)
	if data.maps or data.maps2 or data.maps3 then
		local in_file = { data.maps, data.maps2, data.maps3 }
		local memory, sections

		for i=1, 3 do
			if in_file[i] then
				memory = maps[i]
				memory.list = in_file[i]
				memory.count = #in_file[i]
				memory.odds = memory.count * 1000000 * (i == 2 and 2 or 1) + (maps[i - 1] and maps[i - 1].odds or 0)

				if memory.count == 0 then
					memory.list = {7171137}
					memory.count = 1
				end

				sections = memory.sections
				if sections._count ~= 0 then
					if sections._count ~= math.ceil(memory.count / maps_per_section) then
						sections._map_pointer = maps_per_section + 1 -- reset everything

					elseif sections._count == needed then
						local section = sections[sections._count]
						local modulo = memory.count % maps_per_section

						if modulo == 0 then
							modulo = maps_per_section
						end

						if section._count ~= 0 and section._count ~= modulo then
							sections._map_pointer = maps_per_section + 1
						end
					end
				end
			end
		end

		if first_data_load then
			newMap()
			first_data_load = false
		end
	end

	if data.map_polls then
		maps.polls = data.map_polls

		-- even if we are modifying the file object, internally it's an array
		-- so _count will be ignored
		maps.polls._count = #data.map_polls
	end
end)

onEvent("NewGame", function()
	local map_code_num = tonumber(tostring(room.currentMap):sub(2))

	-- Makes sure current_difficulty is correct
	local rotation = maps[current_difficulty]
	if not rotation or rotation.list[maplist_index] ~= map_code_num then
		current_difficulty = 0
	end

	-- When a map is loaded, this function reads the XML to know where the
	-- checkpoints are

	levels = {}
	if not room.xmlMapInfo or tonumber(room.currentMap) or tonumber(room.xmlMapInfo.mapCode) ~= map_code_num then
		if not room.xmlMapInfo then
			return
		end
		return invalidMap("vanilla")
	end
	local xml = room.xmlMapInfo.xml

	local hole = string.match(xml, '<T%s+.-/>')
	if hole then
		return invalidMap("hole")
	end

	local count = 1
	local mouse_start = string.match(xml, '<DS%s+(.-)%s+/>')

	if not mouse_start then
		return invalidMap("mouse_start")
	end

	local properties = getTagProperties(mouse_start)
	levels[count] = {
		x = properties.X, y = properties.Y,
		size = tonumber(properties.size) or 1,
		cheese = properties.cheese and properties.cheese ~= 0,
		uncheese = properties.cheese == 0,
	}

	for tag in string.gmatch(xml, '<O%s+(.-)%s+/>') do
		properties = getTagProperties(tag)

		if properties.C == 22 then
			count = count + 1
			levels[count] = {
				x = properties.X, y = properties.Y,
				stop = properties.stop, size = tonumber(properties.size),
				cheese = properties.cheese and properties.cheese ~= 0,
				uncheese = properties.cheese == 0,
			}
		end
	end

	local chair = false
	for tag in string.gmatch(xml, '<P%s+(.-)%s+/>') do
		properties = getTagProperties(tag)

		if properties.T == 19 and properties.C == "329cd2" then
			chair = true
			count = count + 1
			levels[count] = {
				x = properties.X, y = properties.Y - 40,
				size = 1
			}
			break
		end
	end

	if submode == "smol" then
		local level
		for i = 1, count do
			level = levels[i]
			if level.size then
				level.size = level.size / 2
			else
				level.size = levels[i - 1].size
			end
		end
	else
		local level
		for i = 1, count do
			level = levels[i]
			if not level.size then
				level.size = levels[i - 1].size
			end
		end
	end

	if room.xmlMapInfo.author ~= "#Module" then
		if not chair or count < 3 then -- start, at least one nail and end chair
			return invalidMap(not chair and "needing_chair" or "missing_checkpoints")
		end
	end

	if room.mirroredMap then
		for index = 1, count do
			levels[index].x = 1600 - levels[index].x
		end
	end

	tfm.exec.setGameTime(1080)

	if (count_stats
		and not is_tribe
		and not records_admins
		and not review_mode
		and room.xmlMapInfo.permCode ~= 41
		and room.xmlMapInfo.author ~= "#Module") then
		invalidMap("no_perm")
		return
	end
	is_invalid = false

	global_poll = false
	local map = tonumber((string.gsub(room.currentMap, "@", "", 1)))
	for index = 1, maps.polls._count do
		if maps.polls[index] == map then
			global_poll = true
			-- poll starts in modes/parkour/ui.lua
			break
		end
	end
end)

onEvent("Loop", function(elapsed, remaining)
	if review_mode or records_admins then return end

	-- Changes the map when needed
	if (is_invalid and os.time() >= is_invalid) or remaining < 500 then
		newMap()
	end
end)

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if cmd == "map" then
		local records_cond = records_admins and records_admins[player]
		local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
		local normal_cond = perms[player] and perms[player].change_map
		if not records_cond and not tribe_cond and not normal_cond then return end

		if quantity > 0 then
			if not records_cond and not tribe_cond and not perms[player].load_custom_map then
				return tfm.exec.chatMessage("<v>[#] <r>You can't load a custom map.", player)
			end

			count_stats = false
			local map = tonumber(args[1]) or tonumber(string.sub(args[1], 2))
			if not map or map < 1000 then
				translatedChatMessage("invalid_syntax", player)
				return
			end
			current_map = args[1]
			tfm.exec.newGame(args[1], args[2] and string.lower(args[2]) == "flipped" and not records_admins)
		elseif os.time() < map_change_cd and not review_mode then
			tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", player)
		else
			newMap()
		end

		if not records_cond and not tribe_cond and normal_cond then
			-- logged when using staff powers
			if review_mode and perms[player].enable_review then
				-- legitimate review mode
				return
			end
			inGameLogCommand(player, "map", args)
			logCommand(player, "map", math.min(quantity, 2), args)
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disableAutoNewGame(true)
	tfm.exec.disableAutoShaman(true)
	tfm.exec.disableAfkDeath(true)
	tfm.exec.disableAutoTimeLeft(true)
	tfm.exec.setAutoMapFlipMode(false)

	system.disableChatCommandDisplay("map")
end)
