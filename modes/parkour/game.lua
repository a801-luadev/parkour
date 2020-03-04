local checkpoint_range = 450 -- radius of 20px
local min_save = 4

local check_position = 6
local player_count = 0
local victory_count = 0
local less_time = false
local victory = {}
local room = tfm.get.room
local bans = {}
local in_room = {}
local players_level = {}
local generated_at = {}

local function generatePlayer(player, save_at)
	players_level[player] = 1
	generated_at[player] = save_at or os.time()
end

onEvent("NewPlayer", function(player)
	in_room[player] = true
	player_count = player_count + 1

	if levels then
		tfm.exec.respawnPlayer(player)

		if victory[player] then
			victory_count = victory_count + 1
		end

		if players_level[player] then
			local level = levels[ players_level[player] ]
			if level then
				tfm.exec.movePlayer(player, level.x, level.y)
			end
		else
			generatePlayer(player)
		end
		tfm.exec.setPlayerScore(player, players_level[player], false)
	end
end)

onEvent("PlayerLeft", function(player)
	player_count = player_count - 1
	in_room[player] = nil

	if victory[player] then
		victory_count = victory_count - 1
	elseif player_count == victory_count and not less_time then
		tfm.exec.setGameTime(20)
		less_time = true
	end
end)

onEvent("PlayerDied", function(player)
	if bans[room.playerList[player].id] then return end
	if (not levels) or (not players_level[player]) then return end

	local level = levels[ players_level[player] ]

	tfm.exec.respawnPlayer(player)
	tfm.exec.movePlayer(player, level.x, level.y)
end)

onEvent("PlayerWon", function(player, elapsed)
	victory_count = victory_count + 1
	victory[player] = true

	if victory_count == player_count then
		tfm.exec.setGameTime(20)
		less_time = true
	end
end)

onEvent("NewGame", function()
	check_position = 6
	victory_count = 0
	less_time = false
	victory = {}
	players_level = {}
	generated_at = {}

	for player in next, in_room do
		generatePlayer(player, os.time())
		tfm.exec.setPlayerScore(player, 1, false)
	end
end)

onEvent("Loop", function()
	if not levels then return end


	if check_position > 0 then
		check_position = check_position - 1
	else
		local last_level = #levels
		local level_id, next_level, player
		for name in next, in_room do
			if bans[room.playerList[name].id] then
				tfm.exec.killPlayer(name)
			else
				level_id = players_level[name] + 1
				next_level = levels[level_id]

				if next_level then
					player = room.playerList[name]

					if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_range then
						players_level[name] = level_id
						tfm.exec.setPlayerScore(name, level_id, false)
						if level_id == last_level then
							tfm.exec.giveCheese(name)
							tfm.exec.playerVictory(name)
							tfm.exec.respawnPlayer(name)
							tfm.exec.movePlayer(name, next_level.x, next_level.y)
						else
							translatedChatMessage("reached_level", name, level_id)
						end
					else
						tfm.exec.displayParticle(
							math.random(21, 23),
							next_level.x + math.random(-10,10),
							next_level.y + math.random(-10,10),
							0, 0, 0, 0,
							name
						)
					end
				end
			end
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disablePhysicalConsumables(true)
	tfm.exec.setRoomMaxPlayers(12)
	tfm.exec.disableAutoScore(true)
end)