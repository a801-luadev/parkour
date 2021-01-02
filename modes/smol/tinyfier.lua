local is_thicc = true
local in_room = {}
local next_xml
local next_load
local map_code, map_author
local chair_x, chair_y
local chair_prop = {
	type = 14,
	width = 32,
	height = 11,
	friction = 0.3,
	restitution = 0.2
}

local function tinyfy(prop, val)
	if prop == "X" or prop == "Y" then
		return prop = '="' .. ((tonumber(val) + 800) / 2 - 800) .. '"'
	end

	return prop .. '="' .. (tonumber(val) / 2) .. '"'
end

local newGame = tfm.exec.newGame
function tfm.exec.newGame(arg)
	is_thicc = false
	return newGame(arg)
end

onEvent("NewPlayer", function(player)
	if chair_x and chair_y then
		tfm.exec.addImage(
			"176c51d7288.png", "_51",
			chair_x - HALF, chair_y - TOTAL,
			player
		)
		tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
	end
	tfm.exec.changePlayerSize(player, 0.5)
	in_room[player] = true
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)

onEvent("NewGame", function()
	if not is_thicc then
		map_author = room.xmlMapInfo.author
		map_core = room.currentMap
		next_load = os.time() + 3000

		next_xml = string.gsub(
			room.xmlMapInfo.xml, '([XYLH])%s*=%s*"(%d+)"', tinyfy
		)

		local chair = string.match(
			next_xml,
			'<P[^>]+T="19"[^>]+C="329cd2"[^>]+/>'
		)
		if not chair then
			chair = string.match(
				next_xml,
				'<P[^>]+C%s*=%s*"329cd2"[^>]+T%s*=%s*"19"[^>]+/>'
			)
		end

		chair_x, chair_y = nil, nil
		if not chair then return end

		-- remove chair
		next_xml = string.gsub(next_xml, chair, "")
		-- replace with nail
		next_xml = string.gsub(
			next_xml,
			"</O>",
			'<O C="22" Y="' .. chair_x .. '" P="0" X="' .. chair_y .. '" /></O>'
		)

		for prop, val in string.gmatch(chair, '([XY])%s*=%s*"(%d+)"') do
			if prop == "X" then
				chair_x = tonumber(val)
			else
				chair_y = tonumber(val)
			end
		end

	elseif chair_x and chair_y then
		tfm.exec.addImage(
			"176c51d7288.png", "_51",
			chair_x - HALF, chair_y - TOTAL
		)
		tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
	end
end)

onEvent("Loop", function()
	if next_load and os.time() >= next_load then
		next_load = nil
		is_thicc = true
		newGame(next_xml)
	end
end)