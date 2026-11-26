local in_room = {}
local players_file = {}
local actual_player_count = 0

local savePlayerData

onEvent("NewPlayer", function(player, init)
	in_room[player] = true

	-- tells the module bot the room is healthy
	if player == "Parkour#5522" then
		tfm.exec.playMusic("alive", "", 0, false, false, player)
	end
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)
