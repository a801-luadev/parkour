local checkpoint_range = 15 ^ 2 -- radius of 15px
local min_save = 4

local check_position = 6
local player_count = 0
local victory_count = 0
local map_start = 0
local less_time = false
local victory = {_last_level = {}}
local bans = {[0] = true} -- souris banned
local in_room = {}
local online = {}
local players_level = {}
local generated_at = {}
local spec_mode = {}
local ck = {
	particles = {},
	images = {}
}
local players_file
local review_mode = false
local cp_available = {}

local checkCooldown
local savePlayerData
local ranks
local bindKeyboard

local function addCheckpointImage(player, x, y)
	if not x then
		local level = levels[ players_level[player] + 1 ]
		if not level then return end
		x, y = level.x, level.y
	end

	ck.images[player] = tfm.exec.addImage("150da4a0616.png", "_51", x - 20, y - 30, player)
end

local function enableSpecMode(player, enable)
	if spec_mode[player] and enable then return end
	if not spec_mode[player] and not enable then return end

	if enable then
		spec_mode[player] = true
		tfm.exec.killPlayer(player)

		player_count = player_count - 1
		if victory[player] then
			victory_count = victory_count - 1
		elseif player_count == victory_count and not less_time then
			tfm.exec.setGameTime(20)
			less_time = true
		end
	else
		spec_mode[player] = nil

		if (not levels) or (not players_level[player]) then return end

		local level = levels[ players_level[player] ]

		tfm.exec.respawnPlayer(player)
		tfm.exec.movePlayer(player, level.x, level.y)

		player_count = player_count + 1
		if victory[player] then
			victory_count = victory_count + 1
		end
	end
end

onEvent("NewPlayer", function(player)
	spec_mode[player] = nil
	in_room[player] = true
	player_count = player_count + 1
	cp_available[player] = 0

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
			players_level[player] = 1
			tfm.exec.movePlayer(player, levels[1].x, levels[1].y)

			for key = 0, 2 do
				bindKeyboard(player, key, true, true)
			end
		end

		tfm.exec.setPlayerScore(player, players_level[player], false)
	end
end)

onEvent("Keyboard", function(player, key)
	if key >= 0 and key <= 2 then
		if players_level[player] == 1 and not generated_at[player] then
			generated_at[player] = os.time()

			for key = 0, 2 do
				bindKeyboard(player, key, true, false)
			end
		end
	end
end)

onEvent("PlayerLeft", function(player)
	players_file[player] = nil
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
	if not room.playerList[player] then return end
	if bans[room.playerList[player].id] then return end
	if (not levels) or (not players_level[player]) then return end

	local level = levels[ players_level[player] ]

	if not spec_mode[player] then
		tfm.exec.respawnPlayer(player)
		if level then
			tfm.exec.movePlayer(player, level.x, level.y)
		end
	end
end)

onEvent("PlayerWon", function(player)
	victory_count = victory_count + 1
	victory[player] = true
	victory._last_level[player] = false

	if victory_count == player_count then
		tfm.exec.setGameTime(20)
		less_time = true
	end
end)

onEvent("PlayerRespawn", function(player)
	cp_available[player] = os.time() + 750

	if not room.playerList[player] then return end
	if bans[room.playerList[player].id] then return tfm.exec.killPlayer(player) end
	if (not levels) or (not players_level[player]) then return end

	local level = levels[ players_level[player] ]
	if not level then return end
	tfm.exec.movePlayer(player, level.x, level.y)
end)

onEvent("NewGame", function()
	check_position = 6
	victory_count = 0
	less_time = false
	victory = {_last_level = {}}
	players_level = {}
	generated_at = {}
	map_start = os.time()

	local start_x, start_y
	if levels then
		start_x, start_y = levels[2].x, levels[2].y

		for player, particles in next, ck.particles do
			if not particles then
				if ck.images[player] then
					tfm.exec.removeImage(ck.images[player])
				end
				addCheckpointImage(player, start_x, start_y)
			end
		end
	end

	for player in next, in_room do
		players_level[player] = 1
		tfm.exec.setPlayerScore(player, 1, false)

		for key = 0, 2 do
			bindKeyboard(player, key, true, true)
		end
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
		for player, to_give in next, victory._last_level do
			if not victory[player] and to_give then
				eventPlayerWon(player)
			end
		end

		local last_level = #levels
		local level_id, next_level, player
		local particle = 29--math.random(21, 23)
		local x, y = math.random(-10, 10), math.random(-10, 10)
		local now = os.time()

		for name in next, in_room do
			player = room.playerList[name]
			if spec_mode[name] then
				tfm.exec.killPlayer(name)
			elseif now >= cp_available[name] then
				level_id = (players_level[name] or 1) + 1
				next_level = levels[level_id]

				if next_level then
					if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_range then
						players_level[name] = level_id
						if not victory[name] then
							tfm.exec.setPlayerScore(name, level_id, false)
						end
						if ck.particles[name] == false then
							tfm.exec.removeImage(ck.images[name])
						end

						if level_id == last_level then
							if victory[name] then -- !cp
								translatedChatMessage("reached_level", name, level_id)
							else
								victory._last_level[name] = true
								tfm.exec.giveCheese(name)
								tfm.exec.playerVictory(name)
								tfm.exec.respawnPlayer(name)
								tfm.exec.movePlayer(name, next_level.x, next_level.y)
							end
						else
							translatedChatMessage("reached_level", name, level_id)

							if ck.particles[name] == false then
								addCheckpointImage(name, levels[level_id + 1].x, levels[level_id + 1].y)
							end
						end
					elseif ck.particles[name] then
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

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if cmd == "review" then
		local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
		local normal_cond = perms[player] and perms[player].enable_review and (string.find(room.name, "review") or ranks.admin[player])
		if not tribe_cond and not normal_cond then
			return tfm.exec.chatMessage("<v>[#] <r>You can't toggle review mode in this room.", player)
		end

		review_mode = not review_mode
		if review_mode then
			tfm.exec.chatMessage("<v>[#] <d>Review mode enabled by " .. player .. ".")
		else
			tfm.exec.chatMessage("<v>[#] <d>Review mode disabled by " .. player .. ".")
		end

	elseif cmd == "cp" then
		if not review_mode then
			if not victory[player] then return end
			if not checkCooldown(player, "cp_command", 10000) then
				return translatedChatMessage("cooldown", player)
			end
		end

		local checkpoint = tonumber(args[1])
		if not checkpoint then
			return translatedChatMessage("invalid_syntax", player)
		end

		if not levels[checkpoint] then return end

		players_level[player] = checkpoint
		tfm.exec.killPlayer(player)
		if not victory[player] then
			tfm.exec.setPlayerScore(player, checkpoint, false)
		end

		if ck.particles[player] == false then
			tfm.exec.removeImage(ck.images[player])
			local next_level = levels[checkpoint + 1]
			if next_level then
				addCheckpointImage(player, next_level.x, next_level.y)
			end
		end

	elseif cmd == "spec" then
		if not perms[player] or not perms[player].spectate then return end

		enableSpecMode(player, not spec_mode[player])
		players_file[player].spec = spec_mode[player]
		savePlayerData(player)

	elseif cmd == "time" then
		if not perms[player] then return end
		if not perms[player].set_map_time then
			if perms[player].set_map_time_review then
				if not review_mode then
					return tfm.exec.chatMessage("<v>[#] <r>You can only change the map time with review mode enabled.", player)
				end
			else return end
		end

		local time = tonumber(args[1])
		if not time then
			return translatedChatMessage("invalid_syntax", player)
		end

		tfm.exec.setGameTime(time)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	ck.particles[player] = data.parkour.ckpart == 1

	if levels and not ck.particles[player] then
		local next_level = levels[(players_level[player] or 1) + 1]
		if next_level then
			if ck.images[player] then
				tfm.exec.removeImage(ck.images[player])
			end
			addCheckpointImage(player, next_level.x, next_level.y)
		end
	end

	if players_file[player].spec then
		enableSpecMode(player, true)
		tfm.exec.chatMessage("<v>[#] <d>Your spec mode has been carried to this room since it's enabled.", player)
	end

	if data.banned and (data.banned == 2 or os.time() < data.banned) then
		bans[room.playerList[player].id] = true

		enableSpecMode(player, true)

		if data.banned == 2 then
			translatedChatMessage("permbanned", player)
		else
			local minutes = math.floor((data.banned - os.time()) / 1000 / 60)
			translatedChatMessage("tempbanned", player, minutes)
		end
	end
end)

onEvent("GameDataLoaded", function(data)
	if data.banned then
		bans = {[0] = true}
		for id, value in next, data.banned do
			if value == 1 or os.time() < value then
				bans[tonumber(id)] = true
			end
		end

		local id, ban
		for player, pdata in next, players_file do
			if room.playerList[player] and in_room[player] then
				id = room.playerList[player].id
				ban = data.banned[tostring(id)]

				if ban then
					if ban == 1 then
						pdata.banned = 2
					else
						pdata.banned = ban
					end
					savePlayerData(player)
					sendPacket(2, id .. "\000" .. ban)
				end

				if pdata.banned and (pdata.banned == 2 or os.time() < pdata.banned) then
					bans[id] = true

					if pdata.banned == 2 then
						translatedChatMessage("permbanned", player)
					else
						local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
						translatedChatMessage("tempbanned", player, minutes)
					end
				end
			end
		end

		for player, data in next, room.playerList do
			if in_room[player] and bans[data.id] then
				enableSpecMode(player, true)
			end
		end
	end
end)

onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 3 then -- !ban
		local player, val = string.match(packet, "^([^\000]+)\000[^\000]+\000([^\000]+)$")
		local file, data = players_file[player], room.playerList[player]
		if in_room[player] and data and file then
			file.banned = val == "1" and 2 or tonumber(val)
			bans[data.id] = file.banned == 2 or os.time() < file.banned

			if bans[data.id] then
				if not spec_mode[player] then
					spec_mode[player] = true
					tfm.exec.killPlayer(player)

					player_count = player_count - 1
					if victory[player] then
						victory_count = victory_count - 1
					elseif player_count == victory_count and not less_time then
						tfm.exec.setGameTime(20)
						less_time = true
					end
				end

				if file.banned == 2 then
					translatedChatMessage("permbanned", player)
				else
					local minutes = math.floor((file.banned - os.time()) / 1000 / 60)
					translatedChatMessage("tempbanned", player, minutes)
				end

			elseif spec_mode[player] then
				enableSpecMode(player, false)
			end

			savePlayerData(player)
			sendPacket(2, data.id .. "\000" .. val)
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disablePhysicalConsumables(true)
	tfm.exec.setRoomMaxPlayers(room_max_players)
	tfm.exec.setRoomPassword("")
	tfm.exec.disableAutoScore(true)

	system.disableChatCommandDisplay("review")
	system.disableChatCommandDisplay("cp")
	system.disableChatCommandDisplay("spec")
	system.disableChatCommandDisplay("time")
end)