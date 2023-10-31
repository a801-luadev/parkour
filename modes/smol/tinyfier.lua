local is_smol = true
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
	return prop .. '="' .. (tonumber(val) / 2) .. '"'
end

local function tinyfyPoints(prop, x, y)
	return " " .. prop .. '="' .. (tonumber(x) / 2) .. "," .. (tonumber(y) / 2) .. '"'
end

local newGame = tfm.exec.newGame
function tfm.exec.newGame(arg)
	is_smol = false
	return newGame(arg)
end

onEvent("NewPlayer", function(player)
	if chair_x and chair_y then
		tfm.exec.addImage(
			"176c51d7288.png", "_51",
			chair_x - 18, chair_y - 31,
			player
		)
		tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
	end
	if not string.find(room.name, "test", 1, true) then
		-- has to be disabled, because size is already handled by normal parkour
		tfm.exec.changePlayerSize(player, 0.5)
	end
	in_room[player] = true
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)

onEvent("NewGame", function()
	if not is_smol then
		map_author = room.xmlMapInfo.author
		map_core = room.currentMap
		next_load = os.time() + 3000

		next_xml = string.gsub(
			room.xmlMapInfo.xml, '([XYLH])%s*=%s*"([^"]+)"', tinyfy
		)
		next_xml = next_xml:gsub(' (P%d)%s*=%s*"(.-),(.-)"', tinyfyPoints) -- joints

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

		for prop, val in string.gmatch(chair, '([XY])%s*=%s*"([^"]+)"') do
			if prop == "X" then
				chair_x = tonumber(val)
			else
				chair_y = tonumber(val)
			end
		end

		-- remove chair
		next_xml = string.gsub(next_xml, chair, "")
		-- replace with nail
		next_xml = string.gsub(
			next_xml,
			"</O>",
			'<O C="22" X="' .. chair_x .. '" P="0" Y="' .. (chair_y - 20) .. '" /></O>'
		)

	elseif chair_x and chair_y then
		tfm.exec.addImage(
			"176c51d7288.png", "_51",
			chair_x - 18, chair_y - 31
		)
		tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
	end
end)

onEvent("Loop", function()
	if next_load and os.time() >= next_load then
		next_load = nil
		is_smol = true
		newGame(next_xml, room.mirroredMap)
	end
end)