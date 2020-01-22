function parseTable(tb)
	local finalTable = {}
	for i, v in next, tb do
		finalTable[v] = true
	end
	return finalTable
end

local game = {
	items = {
		{1, 3},
		{1, 2, 3, 4},
		{2, 2, 4, 4, 10},
		{2, 4, 10, 10, 40}
	},
	config = {
		map = '<C><P H="2000" /><Z><S><S P="0,0,0.3,0.2,0,0,0,0" L="300" o="324650" X="1000" c="2" Y="700" T="12" H="2600" /><S H="2600" L="300" o="324650" X="-200" c="2" Y="700" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S H="400" L="3000" o="2a40" X="400" c="4" Y="200" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S H="400" L="3000" o="56b8ea" X="400" c="4" Y="1800" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="3db0eb" X="400" c="4" Y="1400" T="12" H="400" /><S P="0,0,0.3,0.2,720,0,0,0" L="3000" lua="-1" H="40" c="3" Y="1980" T="6" X="400" /><S H="400" L="3000" o="1fa2e6" X="400" c="4" Y="1000" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="16395" X="400" c="4" Y="600" T="12" H="400" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="99" c="4" Y="1187" T="13" H="10" /><S H="10" L="40" o="ffffff" X="127" c="4" Y="1168" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="170" c="4" Y="1169" T="13" H="10" /><S H="10" L="40" o="ffffff" X="214" c="4" Y="1178" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="188" c="4" Y="1208" T="13" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="140" c="4" Y="1208" T="13" H="10" /><S H="10" L="40" o="ffffff" X="229" c="4" Y="1192" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="686" c="4" Y="981" T="13" H="10" /><S H="10" L="40" o="ffffff" X="662" c="4" Y="1028" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="706" c="4" Y="1018" T="13" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="635" c="4" Y="990" T="13" H="10" /><S H="10" L="40" o="ffffff" X="607" c="4" Y="1018" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S H="10" L="30" o="ffffff" X="618" c="4" Y="1354" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="30" o="ffffff" X="600" c="4" Y="1338" T="13" H="10" /><S H="10" L="30" o="ffffff" X="593" c="4" Y="1365" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="30" o="ffffff" X="566" c="4" Y="1343" T="13" H="10" /><S H="10" L="30" o="ffffff" X="559" c="4" Y="1362" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="42" o="1c1c1c" X="240" c="4" Y="341" T="13" H="10" /><S P="0,0,0.3,0.2,140,0,0,0" L="244" o="1f1f1f" X="241" c="4" Y="343" T="12" H="32" /><S H="17" L="230" o="979797" X="241" c="4" Y="343" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="219" c="4" Y="361" T="12" H="12" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="263" c="4" Y="325" T="12" H="12" /><S H="10" L="36" o="323232" X="241" c="4" Y="342" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S H="10" L="10" o="969696" X="249" c="4" Y="323" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="167" c="4" Y="405" T="12" H="12" /><S H="12" L="30" o="c0c0c0" X="193" c="4" Y="383" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="315" c="4" Y="281" T="12" H="12" /><S H="12" L="30" o="c0c0c0" X="289" c="4" Y="303" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S H="10" L="10" o="ffffff" X="73" c="4" Y="-95" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="395" c="4" Y="-183" T="12" H="10" /><S H="10" L="10" o="ffffff" X="738" c="4" Y="-269" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="637" c="4" Y="-89" T="12" H="10" /><S H="10" L="10" o="ffffff" X="221" c="4" Y="-298" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="496" c="4" Y="-366" T="12" H="10" /><S H="10" L="10" o="ffffff" X="100" c="4" Y="-410" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="563" c="4" Y="319" T="12" H="10" /><S H="10" L="10" o="ffffff" X="451" c="4" Y="192" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="65" c="4" Y="250" T="12" H="10" /><S H="10" L="10" o="ffffff" X="206" c="4" Y="136" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="701" c="4" Y="124" T="12" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="1018" X="400" c="3" Y="-400" T="12" H="800" /><S X="400" L="3000" lua="-2" H="40" c="2" Y="1980" T="6" P="0,0,10,0,720,0,0,0" /></S><D><T Y="32" D="" X="399" /><T Y="32" D="" X="27" /><T Y="32" D="" X="778" /><T Y="32" D="" X="589" /><T Y="32" D="" X="204" /><F Y="30" D="" X="203" /><F Y="30" D="" X="26" /><F Y="30" D="" X="399" /><F Y="30" D="" X="588" /><F Y="30" D="" X="776" /><DS Y="1947" X="400" /></D><O /></Z></C>',
		max_players = 25,
		game_time = 300,
		forbidden_items = parseTable({17, 32, 1700, 1701, 1702, 1703, 1704})
	},
	objects = {},
	current_shaman = nil,
	change_map = false,
	remove_object = true
}

tfm.exec.setRoomMaxPlayers(game.config.max_players)

onEvent("Loop", function(start_time, remaining)
	local has_player_alive = false
	local most_long_Y = 0

	for name, data in next, tfm.get.room.playerList do
		local y = math.abs(data.y - 1947)

		if data.isShaman and start_time >= 15000  then
			if data.isDead then
				if not game.change_map then
					game.change_map = true

					if y <= 400 then
						tfm.exec.setGameTime(20)
						ui.removeTextArea(1)
					end
				end
			elseif not game.change_map then
				if y >= 600 then
					tfm.exec.setShaman(name, false)
					game.change_map = true
				end
			end
		end

		if not data.isDead then
			has_player_alive = true
			tfm.exec.changePlayerSize(name, 1)

			if most_long_Y < y then
				most_long_Y = y
			end
		end
	end

	if not has_player_alive or remaining <= 0 then
		tfm.exec.newGame(game.config.map)
		return
	end

	if remaining >= 183000 then
		ui.addTextArea(1, translatedMessage("remvove_floor", nil, math.floor(remaining/1000) - 180), nil, 5, 1760, 800, 40, 1, 1, 0, false)
	elseif remaining >= 181000 then
		for name, data in next, tfm.get.room.playerList do
			if not data.isDead and data.isShaman then
				tfm.exec.setShaman(name, false)
			end
		end

		ui.removeTextArea(1)
		tfm.exec.removePhysicObject(-1)
		tfm.exec.removePhysicObject(-2)
	end

	if most_long_Y >= 500 and start_time >= 15000 then
		local itemId = math.floor(most_long_Y/400)
		local item = game.items[itemId]

		if item then
			if game.remove_object then
				tfm.exec.removePhysicObject(-2)
				game.remove_object = false
			end

			for i = 1, 2 do
				game.objects[#game.objects + 1] = {time = os.time() + 15000, id = tfm.exec.addShamanObject(item[math.random(#item)], math.random(-100, 900), -200)}
			end
		end

		local objects = game.objects
		for id, data in next, objects do
			if os.time() > data.time then
				table.remove(game.objects, id)
				tfm.exec.removeObject(data.id)
			end
		end
	end
end)

onEvent("NewGame", function()
	tfm.exec.setGameTime(game.config.game_time)
	game.change_map = false
	game.remove_object = true
	game.objects = {}

	for name, data in next, tfm.get.room.playerList do
		if data.isShaman then
			tfm.exec.setShamanMode(name, 1)
			tfm.exec.chatMessage(translatedMessage("you_are_shaman"), name)
		else
			tfm.exec.chatMessage(translatedMessage("you_are_crew_member"), name)
		end
	end
end)

onEvent("SummoningStart", function(name, itemType)
	if game.config.forbidden_items[itemType] then
		tfm.exec.setShamanMode(name, 1)
	end
end)

onEvent("SummoningEnd", function(name, itemType, x, y, ang, data)
	if game.config.forbidden_items[itemType] then
		tfm.exec.removeObject(data.id)
	end
end)

onEvent("NewPlayer", function(name)
	tfm.exec.chatMessage(translatedMessage("welcome"), name)
end)

for index, value in next, {'AutoNewGame', 'AutoTimeLeft', 'PhysicalConsumables', 'DebugCommand', 'MinimalistMode', 'AllShamanSkills'} do
	tfm.exec['disable' .. value]()
end

tfm.exec.newGame(game.config.map)