local checkpoint_range = 15 ^ 2 -- radius of 15px
local min_save = 4

local check_position = 6
local player_count = 0
local victory_count = 0
local map_start = 0
local less_time = false
local victory = {}
local room = tfm.get.room
local bans = {}
local in_room = {}
local players_level = {}
local generated_at = {}
local spec_mode = {}
local ck_particles = {}
local ck_images = {}
local check_funcorp = false
local funcorp_enabled = false
local check_funcorp_at = os.time() + 1000

local function generatePlayer(player, when)
	players_level[player] = 1
	generated_at[player] = save_at
end

local function addCheckpointImage(player, x, y)
	if not x then
		local level = levels[ players_level[player] + 1 ]
		if not level then return end
		x, y = level.x, level.y
	end

	ck_images[player] = tfm.exec.addImage("150da4a0616.png", "_0", x - 20, y - 30, player)
end

onEvent("NewPlayer", function(player)
	spec_mode[player] = nil
	in_room[player] = true
	player_count = player_count + 1

	if player_count > 12 then
		tfm.exec.setRoomMaxPlayers(12)
		tfm.exec.disablePhysicalConsumables(true)
	end

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
			generatePlayer(player, os.time())
		end

		tfm.exec.setPlayerScore(player, players_level[player], false)
	end
end)

onEvent("PlayerLeft", function(player)
	in_room[player] = nil

	if spec_mode[player] then return end

	player_count = player_count - 1

	if victory[player] then
		victory_count = victory_count - 1
	elseif player_count == victory_count and not less_time then
		tfm.exec.setGameTime(20)
		less_time = true
	end
end)

onEvent("PlayerDied", function(player)
	if room.playerList[player] then return end
	if bans[room.playerList[player].id] then return end
	if (not levels) or (not players_level[player]) then return end

	local level = levels[ players_level[player] ]

	if not spec_mode[player] then
		tfm.exec.respawnPlayer(player)
		tfm.exec.movePlayer(player, level.x, level.y)
	end
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
	map_start = os.time()

	local start_x, start_y
	if levels then
		start_x, start_y = levels[2].x, levels[2].y

		for player, particles in next, ck_particles do
			if not particles then
				if ck_images[player] then
					tfm.exec.removeImage(ck_images[player])
				end
				addCheckpointImage(player, start_x, start_y)
			end
		end
	end

	for player in next, in_room do
		generatePlayer(player, map_start)
		tfm.exec.setPlayerScore(player, 1, false)
	end

	for player in next, spec_mode do
		tfm.exec.killPlayer(player)
	end
end)

onEvent("Loop", function()
	if not levels then return end

	if check_position > 0 then
		check_position = check_position - 1
	else
		local last_level = #levels
		local level_id, next_level, player
		local particle = 29--math.random(21, 23)
		local x, y = math.random(-10, 10), math.random(-10, 10)

		for name in next, in_room do
			player = room.playerList[name]
			if bans[player.id] then
				tfm.exec.killPlayer(name)
			else
				level_id = players_level[name] + 1
				next_level = levels[level_id]

				if next_level then
					if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_range then
						players_level[name] = level_id
						tfm.exec.setPlayerScore(name, level_id, false)
						if ck_particles[name] == false then
							tfm.exec.removeImage(ck_images[name])
						end

						if level_id == last_level then
							tfm.exec.giveCheese(name)
							tfm.exec.playerVictory(name)
							tfm.exec.respawnPlayer(name)
							tfm.exec.movePlayer(name, next_level.x, next_level.y)
						else
							translatedChatMessage("reached_level", name, level_id)

							if ck_particles[name] == false then
								addCheckpointImage(name, levels[level_id + 1].x, levels[level_id + 1].y)
							end
						end
					elseif ck_particles[name] then
						tfm.exec.displayParticle(
							particle,
							next_level.x + x,
							next_level.y + y,
							0, 0, 0, 0,
							name
						)
					end
				end
			end
		end
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	ck_particles[player] = data.parkour.ckpart == 1

	if levels and not ck_particles[player] then
		local next_level = levels[players_level[player] + 1]
		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disablePhysicalConsumables(true)
	tfm.exec.setRoomMaxPlayers(12)
	tfm.exec.disableAutoScore(true)
end)