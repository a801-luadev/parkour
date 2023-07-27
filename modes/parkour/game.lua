local min_save = 4

local check_position = 6
local player_count = 0
local victory_count = 0
local less_time = false
local victory = {_last_level = {}}
local bans = {}
local in_room = {}
local online = {}
local hidden = {}
local players_level = {}
local times = {
	map_start = 0,
	generated = {},
	checkpoint = {},
	movement = {}
}
local spec_mode = {}
local checkpoints = {}
local players_file
review_mode = false
local cp_available = {}

local checkpoint_info = {
	version = 1, -- 0 = old, 1 = new
	radius = 15 ^ 2, -- radius of 15px
	next_version = 1
}
local AfkInterface
local checkCooldown
local savePlayerData
local ranks
local bindKeyboard

local changePlayerSize = function() end
if string.find(room.name, "test", 1, true) then
	-- only enable on testing rooms
	changePlayerSize = tfm.exec.changePlayerSize
end

local function addCheckpointImage(player, x, y)
	if not x then
		local level = levels[ players_level[player] + 1 ]
		if not level then return end
		x, y = level.x, level.y
	end

	local data = room.playerList[player]
	local img
	if data and data.spouseId then
		img = "17797d878fa.png" -- soulmate
	else
		img = "17797d860b6.png" -- no soulmate
	end

	checkpoints[player] = tfm.exec.addImage(img, "!1", x - 15, y - 15, player)
end

local function showStats()
	-- Shows if stats count or not

	if not room.xmlMapInfo then return end

	local text = (count_stats and
		room.uniquePlayers >= min_save and
		player_count >= min_save and
		not records_admins and
		not is_tribe and
		not review_mode) and "<v>Stats count" or "<r>Stats don't count"

	ui.setMapName(string.format(
		"<j>%s<bl> - %s<g>   |   %s",
		room.xmlMapInfo.author, room.currentMap, text
	))
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
			tfm.exec.setGameTime(5)
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

	showStats()
end

local function checkBan(player, data, id)
	if not id then
		id = room.playerList[player]
		if not id or not in_room[player] then
			return
		end
		id = id.id
	end

	if data.banned and (data.banned == 2 or os.time() < data.banned) then
		bans[id] = true

		enableSpecMode(player, true)

		if data.banned == 2 then
			translatedChatMessage("permbanned", player)
		else
			local minutes = math.floor((data.banned - os.time()) / 1000 / 60)
			translatedChatMessage("tempbanned", player, minutes)
		end
	elseif bans[id] then
		bans[id] = false
		enableSpecMode(player, false)
	elseif id == 0 then
		enableSpecMode(player, true)
	end
end

local band, rshift = bit32.band, bit32.rshift
local function checkTitleAndNextFieldValue(player, title, sumValue, _playerData, _playerID)
	local field = _playerData[title.field]

	if field < title.requirement then
		local newValue = field + sumValue

		if newValue >= title.requirement then
			system.giveEventGift(player, title.code)

			sendPacket("common", 9, _playerID .. "\000" .. player .. "\000" .. title.code)
		end

		return newValue
	else
		return field
	end
end

onEvent("NewPlayer", function(player)
	spec_mode[player] = nil
	in_room[player] = true

	player_count = player_count + 1

	cp_available[player] = 0
	times.movement[player] = os.time()

	for key = 0, 2 do
		bindKeyboard(player, key, true, true)
	end

	if levels then
		tfm.exec.respawnPlayer(player)

		if victory[player] then
			victory_count = victory_count + 1
		end

		local level
		if players_level[player] then
			level = levels[ players_level[player] ]
			if level then
				tfm.exec.movePlayer(player, level.x, level.y)
			end
		else
			level = levels[1]
			players_level[player] = 1
			tfm.exec.movePlayer(player, levels[1].x, levels[1].y)
		end

		changePlayerSize(player, level.size)
		tfm.exec.setPlayerScore(player, players_level[player], false)

		local next_level = levels[ players_level[player] + 1 ]

		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, next_level.x, next_level.y, players_level[player] + 1, 0, false, player)
			end
		end
	end

	if records_admins then
		bindKeyboard(player, 66, true, true) -- B key
	end

	showStats()
end)

onEvent("Keyboard", function(player, key)
	if key >= 0 and key <= 2 then
		local now = os.time()
		if players_level[player] == 1 and not times.generated[player] then
			times.generated[player] = now
			times.checkpoint[player] = now
			if records_admins then
				tfm.exec.freezePlayer(player, false)
			end
		end
		times.movement[player] = now

		if AfkInterface.open[player] then
			enableSpecMode(player, false)
			AfkInterface:remove(player)
		end

	elseif records_admins and key == 66 then
		if checkCooldown(player, "redo_key", 500) then
			eventParsedChatCommand(player, "redo")
		end
	end
end)

onEvent("PlayerLeft", function(player)
	players_file[player] = nil
	in_room[player] = nil
	times.movement[player] = nil

	if spec_mode[player] then return end

	player_count = player_count - 1

	if victory[player] then
		victory_count = victory_count - 1
	elseif player_count == victory_count and not less_time then
		tfm.exec.setGameTime(5)
		less_time = true
	end

	if not AfkInterface.open[player] then
		local required = 4 - player_count

		if required > 0 then
			local to_remove = {}

			for name in next, AfkInterface.open do
				enableSpecMode(name, false)
				to_remove[required] = name
				required = required - 1
				if required == 0 then break end
			end

			for name = 1, #to_remove do
				AfkInterface:remove(name)
			end
		end
	end

	showStats()
end)

onEvent("PlayerDied", function(player)
	local info = room.playerList[player]

	if not info then return end
	if info.id == 0 then return end
	if bans[info.id] then return end
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
	if bans[ room.playerList[player].id ] then return end
	if victory[player] then return end

	victory_count = victory_count + 1
	victory._last_level[player] = false

	if victory_count == player_count and not less_time then
		tfm.exec.setGameTime(5)
		less_time = true
	end
end)

onEvent("PlayerRespawn", function(player)
	cp_available[player] = os.time() + 750

	if not room.playerList[player] then return end
	if bans[room.playerList[player].id] then return tfm.exec.killPlayer(player) end
	if (not levels) or (not players_level[player]) then return end

	if (players_level[player] == 1
		and not times.generated[player]
		and records_admins) then
		tfm.exec.freezePlayer(player, true)
	end

	local level = levels[ players_level[player] ]
	if not level then return end
	tfm.exec.movePlayer(player, level.x, level.y)
end)

onEvent("NewGame", function()
	check_position = 6
	victory_count = 0
	victory = {_last_level = {}}
	players_level = {}
	times.generated = {}
	times.map_start = os.time()
	checkpoint_info.version = checkpoint_info.next_version

	if submode == "smol" then
		count_stats = false
	end

	if records_admins then
		less_time = true
	else
		less_time = false
	end

	local start_x, start_y
	if levels then
		start_x, start_y = levels[2].x, levels[2].y
		if checkpoint_info.version == 1 then
			tfm.exec.addBonus(0, start_x, start_y, 2, 0, false)
		end

		for player in next, in_room do
			if checkpoints[player] then
				tfm.exec.removeImage(checkpoints[player])
			end
			addCheckpointImage(player, start_x, start_y)
		end

		local size = levels[1].size
		for player in next, in_room do
			players_level[player] = 1
			changePlayerSize(player, size)
			tfm.exec.setPlayerScore(player, 1, false)
		end

		if records_admins then
			for player in next, in_room do
				tfm.exec.freezePlayer(player, true)
			end
		end
	end

	for player in next, spec_mode do
		tfm.exec.killPlayer(player)
	end

	showStats()
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

		local now = os.time()
		local player
		for name in next, in_room do
			player = room.playerList[name]
			if player then
				if spec_mode[name] or player.id == 0 or bans[player.id] then
					tfm.exec.killPlayer(name)
				elseif (player_count > 4
						and not records_admins
						and not review_mode
						and not victory[name]
						and now >= times.movement[name] + 120000) then -- 2 mins afk
					enableSpecMode(name, true)
					AfkInterface:show(name)
				end
			end
		end

		if checkpoint_info.version ~= 0 then return end

		local last_level = #levels
		local level_id, next_level, player
		local taken
		for name in next, in_room do
			player = room.playerList[name]
			if player and now >= cp_available[name] then
				level_id = (players_level[name] or 1) + 1
				next_level = levels[level_id]

				if next_level then
					if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_info.radius then
						taken = (now - (times.checkpoint[player] or times.map_start)) / 1000
						times.checkpoint[player] = now
						players_level[name] = level_id

						if next_level.size ~= levels[ level_id - 1 ].size then
							-- need to change the size
							changePlayerSize(name, next_level.size)
						end

						if not victory[name] then
							tfm.exec.setPlayerScore(name, level_id, false)
						end
						tfm.exec.removeImage(checkpoints[name])

						if level_id == last_level then
							if victory[name] then -- !cp
								translatedChatMessage("reached_level", name, level_id, taken)
							else
								victory._last_level[name] = true
								tfm.exec.giveCheese(name)
								tfm.exec.playerVictory(name)
								tfm.exec.respawnPlayer(name)
								tfm.exec.movePlayer(name, next_level.x, next_level.y)
							end
						else
							translatedChatMessage("reached_level", name, level_id, taken)
							addCheckpointImage(name, levels[level_id + 1].x, levels[level_id + 1].y)
						end
					end
				end
			end
		end
	end
end)

onEvent("PlayerBonusGrabbed", function(player, bonus)
	if checkpoint_info.version ~= 1 then return end
	if not levels then return end
	local level = levels[bonus]
	if not level then return end
	if not players_level[player] then return end
	if bonus ~= players_level[player] + 1 then return end
	if os.time() < cp_available[player] then return tfm.exec.addBonus(0, level.x, level.y, bonus, 0, false, player) end

	local taken = (os.time() - (times.checkpoint[player] or times.map_start)) / 1000
	times.checkpoint[player] = os.time()
	players_level[player] = bonus

	if level.size ~= levels[ bonus - 1 ].size then
		-- need to change the size
		changePlayerSize(player, level.size)
	end

	if not victory[player] then
		tfm.exec.setPlayerScore(player, bonus, false)
	end
	tfm.exec.removeImage(checkpoints[player])

	if bonus == #levels then
		if victory[player] then -- !cp
			translatedChatMessage("reached_level", player, bonus, taken)
		else
			victory._last_level[player] = true
			tfm.exec.giveCheese(player)
			tfm.exec.playerVictory(player)
			tfm.exec.respawnPlayer(player)
			tfm.exec.movePlayer(player, level.x, level.y)
			return
		end
	else
		translatedChatMessage("reached_level", player, bonus, taken)

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

		count_stats = false
		review_mode = not review_mode
		if review_mode then
			tfm.exec.chatMessage("<v>[#] <d>Review mode enabled by " .. player .. ".")
		else
			tfm.exec.chatMessage("<v>[#] <d>Review mode disabled by " .. player .. ".")
		end
		showStats()

	elseif cmd == "cp" then
		local checkpoint = tonumber(args[1])
		if not checkpoint then
			return translatedChatMessage("invalid_syntax", player)
		end

		if checkpoint == 0 then
			checkpoint = #levels
		end

		if not levels[checkpoint] then return end

		if not review_mode then
			if not victory[player] then return end
			if not checkCooldown(player, "cp_command", 10000) then
				return translatedChatMessage("cooldown", player)
			end
		end

		if checkpoint_info.version == 1 then
			tfm.exec.removeBonus(players_level[player] + 1, player)
		end
		players_level[player] = checkpoint
		changePlayerSize(player, levels[checkpoint].size)
		times.checkpoint[player] = os.time()
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
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, next_level.x, next_level.y, checkpoint + 1, 0, false, player)
			end
		end

	elseif cmd == "spec" then
		if not players_file[player] then return end
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
		if not records_admins or not times.generated[player] then return end

		if checkpoint_info.version == 1 then
			tfm.exec.removeBonus(players_level[player] + 1, player)
		end

		players_level[player] = 1
		changePlayerSize(player, levels[1].size)
		times.generated[player] = nil
		times.checkpoint[player] = nil
		victory[player] = nil
		victory_count = victory_count - 1

		tfm.exec.setPlayerScore(player, 1, false)
		tfm.exec.killPlayer(player)
		tfm.exec.respawnPlayer(player)

		local x, y = levels[2].x, levels[2].y
		if checkpoints[player] then
			tfm.exec.removeImage(checkpoints[player])
		end
		addCheckpointImage(player, x, y)
		if checkpoint_info.version == 1 then
			tfm.exec.addBonus(0, x, y, 2, 0, false, player)
		end

	elseif cmd == "setcp" then
		if not records_admins or not records_admins[player] then
			if not perms[player] or not perms[player].set_checkpoint_version then return end
		end

		local version = tonumber(args[1])
		if not version then
			return tfm.exec.chatMessage("<v>[#] <r>Usage: <b>!setcp 1</b> or <b>!setcp 2</b>.", player)
		end
		if version ~= 1 and version ~= 2 then
			return tfm.exec.chatMessage("<v>[#] <r>Checkpoint version can either be 1 or 2.", player)
		end

		checkpoint_info.next_version = version - 1
		tfm.exec.chatMessage("<v>[#] <d>Changes will be applied in the next round.", player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	if players_file[player].spec then
		enableSpecMode(player, true)
		tfm.exec.chatMessage("<v>[#] <d>Your spec mode has been carried to this room since it's enabled.", player)
	end

	checkBan(player, data)
end)

onEvent("PlayerDataUpdated", function(player, data)
	checkBan(player, data)
end)

onEvent("GameDataLoaded", function(data)
	if data.sanction then
		local oldBans = bans
		bans = {}
		for pid, value in pairs(data.sanction) do
			if value and value.time then
				if value.time == 1 or value.time == 2 or os.time() < value.time then
					bans[tonumber(pid)] = true
				end
			end
		end

		for player, data in next, room.playerList do
			if in_room[player] then
				if bans[data.id] then
					if AfkInterface.open[player] then
						AfkInterface:remove(player)
					end
					enableSpecMode(player, true)
				elseif oldBans[data.id] then
					enableSpecMode(player, false)
				end
			end
		end
	end
end)

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == 3 then -- !ban
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
					showStats()
					if victory[player] then
						victory_count = victory_count - 1
					elseif player_count == victory_count and not less_time then
						tfm.exec.setGameTime(5)
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
			sendPacket("common", 2, data.id .. "\000" .. val)
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
	system.disableChatCommandDisplay("setcp")
end)