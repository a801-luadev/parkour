math.randomseed(os.time())
local data_version = 12
local room = tfm.get.room
local links = {
	-- keys here become commands (e.g. !donate)
	-- and textarea callbacks (check chat-ui.lua)
	donate = "https://a801-luadev.github.io/?redirect=parkour",
	github = "https://github.com/a801-luadev/parkour",
	discord = "https://discord.gg/eMmFyptwbs",
	map_submission = "https://atelier801.com/topic?f=6&t=887284",
	records = "https://tfmrecords.com/",
	forum = "https://atelier801.com/topic?f=6&t=892086",
	mod_apps = "https://bit.ly/parkourmods",
	mapper_apps = "https://discord.gg/eMmFyptwbs",
	mapper_event = "https://atelier801.com/topic?f=6&t=898915&p=1#m2",
}
local app_times = {
	mapper_apps = 1756267200000,
	mod_apps = 0,
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

local function printList(list, col, len, player)
	for i=1, len, col do
		tfm.exec.chatMessage(table.concat(list, ' ', i, math.min(i+col-1, len)), player)
	end
end

local function sendChatFmt(msg, player, a, ...)
	local message
	if a == nil then
		message = "<v>[#] <bl>" .. msg
	else
		message = string.format("<v>[#] <bl>" .. msg, a, ...)
	end

	if #message > 1000 then
		-- Potential bug: this ignores empty lines
		for line in message:gmatch("([^\n]+)") do
			tfm.exec.chatMessage(line:sub(1, 1000):gsub('<[^>]+$', ''), player)
		end
	else
		tfm.exec.chatMessage(message:gsub('<[^>]+$', ''), player)
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
{% require-file "global/id.lua" %}
{% require-file "global/event-handler.lua" %}
{% require-file "global/translation-handler.lua" %}
{% require-dir "translations/parkour" %}

local in_room = {}

onEvent("NewPlayer", function(player)
	in_room[player] = true
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)

{% require-dir "modes/parkour/objects" %}
{% require-file "modes/parkour/interfaces/report.lua" %}

onEvent("TextAreaCallback", function(id, player, callback)
	local position = string.find(callback, ":", 1, true)
	local action, args
	if not position then
		if eventRawTextAreaCallback then
			eventRawTextAreaCallback(id, player, callback)
		end
	elseif eventParsedTextAreaCallback then
		eventParsedTextAreaCallback(id, player, string.sub(callback, 1, position - 1), string.sub(callback, position + 1))
	end
end)

for player in next, room.playerList do
	eventNewPlayer(player)
end

local loader = string.match(({ pcall(0) })[2], "^(.-)%.")
-- player_langs[loader] = translations['tr']

ReportInterface:show(loader)
