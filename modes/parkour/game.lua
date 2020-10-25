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
local hidden = {}
local players_level = {}
local generated_at = {}
local spec_mode = {}
local checkpoints = {}
local players_file
review_mode = false
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

	checkpoints[player] = tfm.exec.addImage("17557263644.png", "_51", x - 15, y - 15, player)
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

		local next_level = levels[ players_level[player] + 1 ]

		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
			tfm.exec.addBonus(0, next_level.x, next_level.y, players_level[player] + 1, 0, false, player)
		end
	end

	if records_admins then
		bindKeyboard(player, 78, true, true) -- N key
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
	elseif records_admins and key == 78 then
		if checkCooldown(player, "redo_key", 500) then
			eventParsedChatCommand(player, "redo")
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

	if victory_count == player_count and not less_time then
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
	victory = {_last_level = {}}
	players_level = {}
	generated_at = {}
	map_start = os.time()

	if records_admins then
		less_time = true
	else
		less_time = false
	end

	local start_x, start_y
	if levels then
		start_x, start_y = levels[2].x, levels[2].y
		tfm.exec.addBonus(0, start_x, start_y, 2, 0, false)

		for player in next, in_room do
			if checkpoints[player] then
				tfm.exec.removeImage(checkpoints[player])
			end
			addCheckpointImage(player, start_x, start_y)
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

		for name in next, in_room do
			if spec_mode[name] then
				tfm.exec.killPlayer(name)
			end
		end
	end
end)

onEvent("PlayerBonusGrabbed", function(player, bonus)
	if not levels then return end
	local level = levels[bonus]
	if not level then return end
	if not players_level[player] then return end
	if bonus ~= players_level[player] + 1 then return end
	if os.time() < cp_available[player] then return tfm.exec.addBonus(0, level.x, level.y, bonus, 0, false, player) end

	players_level[player] = bonus
	if not victory[player] then
		tfm.exec.setPlayerScore(player, bonus, false)
	end
	tfm.exec.removeImage(checkpoints[player])

	if bonus == #levels then
		if victory[player] then -- !cp
			translatedChatMessage("reached_level", player, bonus)
		else
			victory._last_level[player] = true
			tfm.exec.giveCheese(player)
			tfm.exec.playerVictory(player)
			tfm.exec.respawnPlayer(player)
			tfm.exec.movePlayer(player, level.x, level.y)
			return
		end
	else
		translatedChatMessage("reached_level", player, bonus)

		local next_level = levels[bonus + 1]
		addCheckpointImage(player, next_level.x, next_level.y)

		tfm.exec.addBonus(0, next_level.x, next_level.y, bonus + 1, 0, false, player)
	end

	if level.stop then
		tfm.exec.movePlayer(player, 0, 0, true, 1, 1, false)
	end
end)

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if cmd == "review" then
		local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
		local normal_cond = (perms[player] and
							perms[player].enable_review and
							not records_admins and

							(string.find(room.lowerName, "review") or
							 ranks.admin[player]))
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

		tfm.exec.removeBonus(players_level[player] + 1, player)
		players_level[player] = checkpoint
		tfm.exec.killPlayer(player)
		if not victory[player] then
			tfm.exec.setPlayerScore(player, checkpoint, false)
		end

		local next_level = levels[checkpoint + 1]
		if checkpoints[player] then
			tfm.exec.removeImage(checkpoints[player])
		end
		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
			tfm.exec.addBonus(0, next_level.x, next_level.y, checkpoint + 1, 0, false, player)
		end

	elseif cmd == "spec" then
		if not perms[player] or not perms[player].spectate then return end

		enableSpecMode(player, not spec_mode[player])
		players_file[player].spec = spec_mode[player]
		savePlayerData(player)

	elseif cmd == "time" then
		if not records_admins or not records_admins[player] then
			if not perms[player] then return end
			if not perms[player].set_map_time then
				if perms[player].set_map_time_review then
					if not review_mode then
						return tfm.exec.chatMessage("<v>[#] <r>You can only change the map time with review mode enabled.", player)
					end
				else return end
			end
		end

		local time = tonumber(args[1])
		if not time then
			return translatedChatMessage("invalid_syntax", player)
		end

		tfm.exec.setGameTime(time)

	elseif cmd == "redo" then
		if not records_admins or not generated_at[player] then return end

		players_level[player] = 1
		generated_at[player] = nil
		victory[player] = nil
		victory_count = victory_count - 1

		tfm.exec.setPlayerScore(player, 1, false)
		tfm.exec.killPlayer(player)
		tfm.exec.respawnPlayer(player)
		for key = 0, 2 do
			bindKeyboard(player, key, true, true)
		end

		local x, y = levels[2].x, levels[2].y
		if checkpoints[player] then
			tfm.exec.removeImage(checkpoints[player])
		end
		addCheckpointImage(player, x, y)
		tfm.exec.addBonus(0, x, y, 2, 0, false, player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
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
	system.disableChatCommandDisplay("redo")
end)