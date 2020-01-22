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
		module_name = string.match(tfm.get.room.name, "^[a-z][a-z]%-#([a-z]+)")
		pos = #module_name + 5
	end

	local numbers
	numbers, submode = string.match(tfm.get.room.name, "^(%d+)([a-z_]+)", pos)
	if numbers then
		flags = string.sub(tfm.get.room.name, pos + #numbers + #submode + 1)
	end

	if submode == "freezertag" then
		{% require-package "modes/freezertag" %}
	elseif submode == "rocketlaunch" then
		{% require-package "modes/rocketlaunch" %}
	else
		{% require-package "modes/parkour" %}
	end
end