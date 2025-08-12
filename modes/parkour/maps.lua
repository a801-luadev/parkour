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
local next_map
local mapIsAboutToChange
local map_images

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

local chair_pos
local levels
local perms
local review_mode
local records_admins = string.find(room.lowerName, "records", 1, true) and {}
local smol_completions = submode == "smol" and { _max = 0, _maxName = nil }
local isAieMap

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

local function newMap(difficulty)
	count_stats = not review_mode
	map_change_cd = os.time() + 20000

	if next_map then
		current_map = next_map
		tfm.exec.newGame(next_map)
		next_map = nil
		return
	end

	-- This might break if we move them to different files
	local map

	if difficulty then
		difficulty = math.min(3, math.max(1, difficulty))
	else
		local chosen = math.random(maps[3].odds)
		for i=1,3 do
			if chosen <= maps[i].odds then
				difficulty = i
				break
			end
		end
	end

	map = selectMap(maps[difficulty].sections, maps[difficulty].list, maps[difficulty].count)

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

local function renderMapImages(player)
	if not map_images then return end
	for index = 1, map_images._len do
		local image = map_images[index]
		tfm.exec.addImage(image[4], "+" .. image[1], image[2], image[3], player, 1, 1, image[5], 1, 0, 0, false)
	end
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

	map_images = nil
	current_difficulty = 0
	for i=1, 3 do
		if table_find(maps[i].list, map_code_num) then
			current_difficulty = i
			break
		end
	end

	if current_difficulty == 0 and room.xmlMapInfo and room.xmlMapInfo.permCode == 42 then
		current_difficulty = 4
	end

	-- When a map is loaded, this function reads the XML to know where the
	-- checkpoints are

	levels = nil
	if not room.xmlMapInfo or not room.xmlMapInfo.xml or tonumber(room.currentMap) or tonumber(room.xmlMapInfo.mapCode) ~= map_code_num then
		if not room.xmlMapInfo then
			return
		end
		return invalidMap("vanilla")
	end
	local info = room.xmlMapInfo
	local xml = info.xml

	local hole = string.match(xml, '<T%s+.-/>')
	if hole then
		return invalidMap("hole")
	end

	local count = 1
	local mouse_start = string.match(xml, '<DS%s+(.-)%s*/>')

	if not mouse_start then
		return invalidMap("mouse_start")
	end

	isAieMap = xml:find('aie="')
	levels = {}

	local properties = getTagProperties(mouse_start)
	levels[count] = {
		x = properties.X, y = properties.Y,
		size = tonumber(properties.size) or 1,
		cheese = properties.cheese and properties.cheese ~= 0,
		uncheese = properties.cheese == 0,
	}

	for tag in string.gmatch(xml, '<O%s+(.-)%s*/>') do
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

	chair_pos = nil
	for tag in string.gmatch(xml, '<P%s+(.-)%s*/>') do
		properties = getTagProperties(tag)

		if properties.T == 19 and properties.C == "329cd2" then
			chair_pos = { properties.X, properties.Y - 40 }
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

	if info.author ~= "#Module" then
		if not chair_pos or count < 3 then -- start, at least one nail and end chair
			return invalidMap(not chair_pos and "needing_chair" or "missing_checkpoints")
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
		and info.permCode ~= 41
		and info.author ~= "#Module") then
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

	if review_mode or info.permCode == 41 or info.permCode == 42 then
		if not xml:find(' i="', 1, true) or not xml:find(' lua="', 1, true) then
			return
		end

		if info.author == "#Module" then
			return
		end

		local images, count, gcount = {}, 0, 0
		local props, testId, x, y, w, h, rot, image

		for ground in string.gmatch(xml, '<S( .-)/>') do
			props = getTagProperties(ground)
			if props.lua and props.i then
				x, y, image = string.match(props.i, "^(.-),(.-),(.-)$")
				rot = props.P and string.match(props.P, "^.-,.-,.-,.-,(.-),")
				rot = math.rad(tonumber(rot) or 0)
				if x and y and image then
					if image:sub(-4) ~= ".png" then
						image = "img@" .. image
					end
					testId = tfm.exec.addImage(image, "+" .. props.lua, x, y, "Tigrounette")
					if testId then
						w = math.max(10, tonumber(props.L) or 10)
						h = math.max(10, tonumber(props.H) or 10)
						x = tonumber(x) or 0
						y = tonumber(y) or 0
						x = x - w / 2
						y = y - h / 2

						count = count + 1
						images[count] = { props.lua, x, y, image, rot }

						if count == 60 then break	end
					end
				end
			end

			gcount = gcount + 1
			if gcount == 60 then break end
		end

		if count > 0 then
			images._len = count
			map_images = images
			renderMapImages()
		end
	end
end)

onEvent("Loop", function(elapsed, remaining)
	if review_mode or records_admins then return end

	mapIsAboutToChange = remaining < 1500

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
		local smol_cond = smol_completions and smol_completions._maxName == player
		if not records_cond and not tribe_cond and not normal_cond and not smol_cond then return end

		if quantity > 0 then
			if not records_cond and not tribe_cond and not (perms[player] and perms[player].load_custom_map) then
				return tfm.exec.chatMessage("<v>[#] <r>You can't load a custom map.", player)
			end

			if args[1]:sub(1, 1):lower() == 'd' then
				local difficulty = tonumber(args[1]:sub(2))
				newMap(difficulty)
				return
			end

			local map = tonumber(args[1]) or tonumber(string.sub(args[1], 2))
			if not map or map < 1000 then
				translatedChatMessage("invalid_syntax", player)
				return
			end
			count_stats = false
			current_map = map
			tfm.exec.newGame(args[1], args[2] and string.lower(args[2]) == "flipped" and not records_admins)
		elseif os.time() < map_change_cd and not review_mode then
			tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", player)
		else
			newMap()
		end

		inGameLogCommand(player, "map", args)

		if not records_cond and not tribe_cond and normal_cond then
			-- logged when using staff powers
			if review_mode and perms[player].enable_review then
				-- legitimate review mode
				return
			end
			logCommand(player, "map", math.min(quantity, 2), args)
		end
	end
end)

onEvent("NewPlayer", renderMapImages)

onEvent("GameStart", function()
	tfm.exec.disableAutoNewGame(true)
	tfm.exec.disableAutoShaman(true)
	tfm.exec.disableAfkDeath(true)
	tfm.exec.disableAutoTimeLeft(true)
	tfm.exec.setAutoMapFlipMode(false)

	system.disableChatCommandDisplay("map")
end)
