--
-- Parkour v2.0
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
	donation = "https://bit.ly/parkour-donate",
	github = "https://bit.ly/tfm-parkour",
	discord = "https://bit.ly/parkour-discord",
	maps = "https://bit.ly/submit-parkour-maps",
	modapps = "https://bit.ly/parkourmod"
}

local starting = string.sub(tfm.get.room.name, 1, 2)

local tribe, module_name, submode
local flags = ""

{% require-package "translations" %}
{% require-package "global" %}

if starting == "*\003" then
	tribe = string.sub(tfm.get.room.name, 3)

	{% require-package "modes/parkour" %}
else
	local pos
	if starting == "*#" then
		module_name = string.match(tfm.get.room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(tfm.get.room.name, "^[a-z][a-z2]%-#([a-z]+)")
		pos = #module_name + 5
	end

	local numbers
	numbers, submode = string.match(tfm.get.room.name, "^(%d+)([a-z_]+)", pos)
	if numbers then
		flags = string.sub(tfm.get.room.name, pos + #numbers + #submode + 1)
	end

	if room.name == "*#parkour4bots" then
		{% require-package "modes/bots" %}
	elseif submode == "freezertag" then
		{% require-package "modes/freezertag" %}
	elseif submode == "rocketlaunch" then
		{% require-package "modes/rocketlaunch" %}
	else
		{% require-package "modes/parkour" %}
	end
end

for player in next, tfm.get.room.playerList do
	eventNewPlayer(player)
end
