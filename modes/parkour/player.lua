local in_room = {}
local players_file = {}

local savePlayerData

onEvent("NewPlayer", function(player, init)
	in_room[player] = true
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil
end)
