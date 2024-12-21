--
-- Parkour v2
-- MIT License

-- Copyright (c) 2020 Iván Gabriel (Tocutoeltuco)

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--


math.randomseed(os.time())
local data_version = 9
local room = tfm.get.room
local links = {
	donation = "https://a801-luadev.github.io/?redirect=parkour",
	github = "https://github.com/a801-luadev/parkour",
	discord = "https://discord.gg/QRCjyVyg7B",
	maps = "https://atelier801.com/topic?f=6&t=887284",
	records = "https://tfmrecords.com/",
	forum = "https://atelier801.com/topic?f=6&t=892086",
	mod_apps = "https://bit.ly/parkourmods",
	mapper_event = "https://atelier801.com/topic?f=6&t=898915&p=1#m2",
}

local starting = string.sub(room.name, 1, 2)

local is_tribe = starting == "*\003"
local tribe, module_name, submode
local flags = ""

if is_tribe then
	tribe = string.sub(room.name, 3)
end

room.lowerName = string.lower(room.name)
room.shortName = string.gsub(room.name, "%-?#parkour", "", 1)

local function enlargeName(name)
	if string.sub(name, 1, 1) == "*" then
		return "*#parkour" .. string.sub(name, 2)
	else
		return string.sub(name, 1, 2) .. "-#parkour" .. string.sub(name, 3)
	end
end

local function generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomString = ""
    
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        randomString = randomString .. string.sub(chars, randomIndex, randomIndex)
    end
    
    return randomString
end

local function table_find(tbl, value)
	for index=1, #tbl do
		if tbl[index] == value then
			return index
		end
	end
end

local function capitalize(str)
	local first = string.sub(str, 1, 1)
	if first == "+" then
		return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
	else
		return string.upper(first) .. string.lower(string.sub(str, 2))
	end
end

do
	local savePlayerData = system.savePlayerData
	system.savePlayerData = function(playerName, ...)
		if not playerName then return end
		if tostring(playerName):sub(1, 1) == '*' then return end
		return savePlayerData(playerName, ...)
	end
end

do
	room.moduleMaxPlayers = 50
	local setRoomMaxPlayers = tfm.exec.setRoomMaxPlayers
	function tfm.exec.setRoomMaxPlayers(maxPlayers)
		local ret = setRoomMaxPlayers(maxPlayers)
		room.moduleMaxPlayers = room.maxPlayers
		return ret
	end
end

{% require-package "translations" %}
{% require-package "global" %}

local function initialize_parkour() -- so it uses less space after building
	{% require-package "modes/parkour" %}
end

if is_tribe then
	initialize_parkour()
else
	local pos
	if starting == "*#" then
		module_name = string.match(room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(room.name, "^[a-z][a-z]%-#([a-z]+)")
		pos = #module_name + 5
	end

	submode = string.match(room.name, "^[^a-zA-Z]-([a-z_]+)", pos)
	if submode then
		flags = string.sub(room.name, pos + #submode + 2)
	end

	local nameLength = string.len(room.name)
	if nameLength > 45 then 
		local password = generateRandomString(10)
		tfm.exec.setRoomPassword(password)
		translatedChatMessage("room_name_length")
		return 
	end

	if room.name == "*#parkour4bots" then
		{% require-package "modes/bots" %}
	elseif submode == "freezertag" then
		{% require-package "modes/freezertag" %}
	elseif submode == "rocketlaunch" then
		{% require-package "modes/rocketlaunch" %}
	elseif submode == "smol" then
		initialize_parkour()
		{% require-package "modes/smol" %}
	else
		initialize_parkour()
	end
end

for player in next, room.playerList do
	eventNewPlayer(player, true)
end

initializingModule = false