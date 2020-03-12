local first_data_load = true
local room = tfm.get.room
local repeated = {_count = 0}
local maps = {_count = 0}
local is_invalid = false
local levels

local function newMap()
	if repeated._count == maps._count then
		repeated = {_count = 0}
	end

	local map
	repeat
		map = maps[math.random(1, maps._count)]
	until map and not repeated[map]
	repeated[map] = true
	repeated._count = repeated._count + 1

	tfm.exec.newGame(map)
end

local function invalidMap(arg)
	levels = nil
	is_invalid = os.time() + 3000
	translatedChatMessage("corrupt_map")
	translatedChatMessage("corrupt_map_" .. arg)
end

local function getTagProperties(tag)
	local properties = {}
	for name, value in string.gmatch(tag, '(%S+)%s*=%s*"([^"]+)"') do
		properties[name] = tonumber(value) or value
	end
	return properties
end

onEvent("GameDataLoaded", function(data)
	if data.maps then
		if #data.maps > 0 then
			maps._count = #data.maps
			for index = 1, maps._count do
				maps[index] = data.maps[index]
			end
		else
			maps = {_count = 1, [1] = 7171137}
		end
		repeated = {_count = 0}
	else
		maps = {_count = 1, [1] = 7171137}
	end

	if first_data_load then
		newMap()
		first_data_load = false
	end
end)

onEvent("NewGame", function()
	levels = {}
	if not room.xmlMapInfo then return invalidMap("vanilla") end
	local xml = room.xmlMapInfo.xml

	local count = 1
	local mouse_start = string.match(xml, '<DS%s+(.-)%s+/>')

	if not mouse_start then
		return invalidMap("mouse_start")
	end

	local properties = getTagProperties(mouse_start)
	levels[count] = {x = properties.X, y = properties.Y}

	for tag in string.gmatch(xml, '<O%s+(.-)%s+/>') do
		properties = getTagProperties(tag)

		if properties.C == 22 then
			count = count + 1
			levels[count] = {x = properties.X, y = properties.Y}
		end
	end

	local chair = false
	for tag in string.gmatch(xml, '<P%s+(.-)%s+/>') do
		properties = getTagProperties(tag)

		if properties.T == 19 and properties.C == "329cd2" then
			chair = true
			count = count + 1
			levels[count] = {x = properties.X, y = properties.Y - 25}
			break
		end
	end

	if not chair or count < 3 then -- start, at least one nail and end chair
		return invalidMap(not chair and "needing_chair" or "missing_checkpoints")
	end

	tfm.exec.setGameTime(1080)
end)

onEvent("Loop", function(elapsed, remaining)
	if (is_invalid and os.time() >= is_invalid) or remaining < 500 then
		newMap()
		is_invalid = false
	end
end)

onEvent("GameStart", function()
	tfm.exec.disableAutoNewGame(true)
	tfm.exec.disableAutoShaman(true)
	tfm.exec.disableAfkDeath(true)
	tfm.exec.disableAutoTimeLeft(true)
end)