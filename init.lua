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


local room = tfm.get.room
local links = {
	donation = "https://a801-luadev.github.io/?redirect=parkour",
	github = "https://bit.ly/tfm-parkour",
	discord = "https://bit.ly/parkour-discord",
	maps = "https://bit.ly/submit-parkour-maps",
	modapps = "https://bit.ly/parkourmod"
}

local starting = string.sub(room.name, 1, 2)

local tribe, module_name, submode
local flags = ""

{% require-package "translations" %}
{% require-package "global" %}

local function initialide_parkour() -- so it uses less space after building
	{% require-package "modes/parkour" %}
end

if starting == "*\003" then
	tribe = string.sub(room.name, 3)

	initialide_parkour()
else
	local pos
	if starting == "*#" then
		module_name = string.match(room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(room.name, "^[a-z][a-z2]%-#([a-z]+)")
		pos = #module_name + 5
	end

	local numbers
	numbers, submode = string.match(room.name, "^(%d+)([a-z_]+)", pos)
	if numbers then
		flags = string.sub(room.name, pos + #numbers + #submode + 1)
	end

	if room.name == "*#parkour4bots" then
		{% require-package "modes/bots" %}
	elseif submode == "freezertag" then
		{% require-package "modes/freezertag" %}
	elseif submode == "rocketlaunch" then
		{% require-package "modes/rocketlaunch" %}
	else
		initialide_parkour()
	end
end

for player in next, room.playerList do
	eventNewPlayer(player)
end

initializingModule = false