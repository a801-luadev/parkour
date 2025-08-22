local min_save = 4

local check_position = 6
local player_count = 0
local actual_player_count = 0
local victory_count = 0
local less_time = false
local victory = {_last_level = {}}
local in_room = {}
local online = {}
local hidden = {}
local bonusOffset = 0
local players_level = {}
local times = {
	map_start = 0,
	generated = {},
	checkpoint = {},
	movement = {}
}
local activeEvents = {}
local spec_mode = {}
local checkpoints = {}
local players_file
review_mode = false
local cp_available = {}
local map_name
local map_gravity = 10

local save_queue

local difficulty_color = { 'vp', 'j', 'ch2' }
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
local showStats

local lastOpenedMap
local lastPlayerLeft
local lastUniquePlayerCount = room.uniquePlayers

-- anniversary on march 6
local is_anniversary, is_before_anniversary, is_after_anniversary
do
	local now = os.time()
	local date_current = os.date("*t", now / 1000)

	local function anniversaryTime(day)
		return os.time({ year=date_current.year, month=3, day=6+day, hour=0 })
	end

	local date_anniversary = os.date("*t", anniversaryTime(0) / 1000)
	local wday = date_anniversary.wday - 1

	if wday == 0 then
		wday = 7
	end

	local week_before = anniversaryTime(1 - wday - 7)
	local anniversary_week = anniversaryTime(1 - wday)
	local week_after = anniversaryTime(7 + 1 - wday)
	local week_after_end = anniversaryTime(7 + 1 - wday + 3)

	is_before_anniversary = now >= week_before and now < anniversary_week
	is_anniversary = now >= anniversary_week and now < week_after
	is_after_anniversary = now >= week_after and now < week_after_end
end

do
	local newGame = tfm.exec.newGame
	tfm.exec.newGame = function(code, reversed)
		code = tostring(code)
		lastOpenedMap = code:sub(1, 1) == '@' and code:sub(2) or code
		newGame(code, reversed)
	end

	local respawnPlayer = tfm.exec.respawnPlayer
	tfm.exec.respawnPlayer = function(player)
		local info = room.playerList[player]
		if info and info.look:find('327;', 1, true) == 1 then
			tfm.exec.setPlayerLook(player, "1;0,0,0,0,0,0,0,0,0,0,0,0")
			translatedChatMessage("bad_outfit", player)
		end
		return respawnPlayer(player)
	end
end

local changePlayerSize = function(name, size)
	size = tonumber(size)
	if name and size and victory[name] and size > 1 then
		size = 1
	end
	return tfm.exec.changePlayerSize(name, size)
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

local function doStatsCount()
	return count_stats and
		room.uniquePlayers >= min_save and
		player_count >= min_save and
		not records_admins and
		not is_tribe and
		not review_mode or force_stats_count_debug
end

local function rewardSkin(player, id)
	local pdata = players_file[player]
	if not pdata or not pdata:addItem(id) then return end
	local skin = shop_skins[id]
	if not skin then return end
	local power = shop_tabs[skin.tab]
	if not power then return end
	for _player in next, in_room do
		translatedChatMessage("unlocked_skin", _player, player, translatedMessage(power, _player))
	end
	return true
end

function showStats()
	-- Shows if stats count or not

	if not map_name then return end

	local text = doStatsCount() and
		"<v>Stats count" or
		(
			review_mode and
			"<bv>Review Mode" or
			"<r>Stats don't count"
		)
	local colortag = difficulty_color[current_difficulty]

	ui.setMapName(string.format(
		"%s%s<g>   |   %s",
		map_name,
		colortag and string.format(
			' - <%s>%s',
			colortag,
			('★'):rep(current_difficulty)
		)
		or current_difficulty == 4 and ' - <bv>In-Review'
		or '',
		text
	))
end

local function enableSpecMode(player, enable)
	if spec_mode[player] and enable then return end
	if not spec_mode[player] and not enable then return end

	if enable then
		spec_mode[player] = true
		tfm.exec.killPlayer(player)
		tfm.exec.setPlayerScore(player, -1, false)

		player_count = player_count - 1
		if victory[player] then
			victory_count = victory_count - 1
		elseif player_count == victory_count and not less_time then
			tfm.exec.setGameTime(5)
			less_time = true
		end
	else
		spec_mode[player] = nil
		tfm.exec.setPlayerScore(player, players_level[player] or 1, false)

		if (not levels) or (not players_level[player]) then return end

		local level = levels[ players_level[player] ]

		cp_available[player] = os.time() + 750
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
		bans[id] = data.lastsanction

		enableSpecMode(player, true)

		if data.banned == 2 then
			translatedChatMessage("permbanned", player)
		else
			local minutes = math.floor((data.banned - os.time()) / 1000 / 60)
			translatedChatMessage("tempbanned", player, minutes)
		end
	elseif bans[id] then
		if not data.lastsanction or bans[id] > data.lastsanction then
			enableSpecMode(player, true)
		else
			bans[id] = false
			enableSpecMode(player, false)
		end
	elseif id == 0 then
		enableSpecMode(player, true)
	end
end

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

onEvent("NewPlayer", function(player, init)
	-- Auto kick duplicate souris accounts
	if player:sub(1, 1) == "*" then
		if not init and lastUniquePlayerCount == room.uniquePlayers then
			tfm.exec.kickPlayer(player)
		end
	end
	lastUniquePlayerCount = room.uniquePlayers

	ui.removeTextArea(987, nil)
	spec_mode[player] = nil
	in_room[player] = true

	player_count = player_count + 1
	actual_player_count = actual_player_count + 1

	if not room.isTribeHouse and actual_player_count > room.moduleMaxPlayers then
		sendPacket(
			"common",
			packets.rooms.lock_fixed,
			room.shortName .. "\000" ..
			actual_player_count .. "\000" ..
			room.moduleMaxPlayers .. "\000" ..
			(lastPlayerLeft or "-") .. "\000" ..
			player
		)
		tfm.exec.setRoomMaxPlayers(room.moduleMaxPlayers)
	end

	cp_available[player] = 0
	times.movement[player] = os.time()

	for key = 0, 3 do
		bindKeyboard(player, key, true, true)
		if key == 3 then
			bindKeyboard(player, key, false, true)
		end
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

		if level.cheese then
			tfm.exec.giveCheese(player)
		elseif level.uncheese then
			tfm.exec.removeCheese(player)
		end

		local next_level = levels[ players_level[player] + 1 ]

		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, next_level.x, next_level.y, bonusOffset + players_level[player] + 1, 0, false, player)
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
	lastUniquePlayerCount = room.uniquePlayers

	if smol_completions and smol_completions._maxName == player then
		smol_completions[smol_completions._maxName] = nil
		smol_completions._max = 0
		smol_completions._maxName = nil

		for name, score in next, smol_completions do
			if name ~= '_maxName' and score > smol_completions._max then
				smol_completions._max = score
				smol_completions._maxName = name
			end
		end

		if smol_completions._maxName then
			translatedChatMessage("smol_best", nil, smol_completions._maxName, smol_completions._max)
		end
	end

	players_file[player] = nil
	in_room[player] = nil
	times.movement[player] = nil
	lastPlayerLeft = player
	actual_player_count = actual_player_count - 1

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
	if info.id == 0 or player:sub(1, 1) == "*" then return end
	if bans[info.id] then return end
	if (not levels) or (not players_level[player]) then return end

	local level = levels[ players_level[player] ]
	tfm.exec.linkMice(player, player, false)

	if not spec_mode[player] then
		cp_available[player] = os.time() + 750
		tfm.exec.respawnPlayer(player)
		if level then
			tfm.exec.movePlayer(player, level.x, level.y)
		end
	end
end)

onEvent("PlayerWon", function(player)
	if not room.playerList[player] then return end
	if bans[ room.playerList[player].id ] then return end
	if victory[player] then return end

	if smol_completions and player:sub(1, 1) ~= "*" then
		smol_completions[player] = 1 + (smol_completions[player] or 0)

		if smol_completions[player] > smol_completions._max then
			smol_completions._max = smol_completions[player]

			if smol_completions._maxName ~= player then
				smol_completions._maxName = player
				translatedChatMessage("smol_best", nil, player, smol_completions._max)
			end
		end
	end

	victory_count = victory_count + 1
	victory._last_level[player] = false
	tfm.exec.linkMice(player, player, false)

	if victory_count == player_count and not less_time then
		tfm.exec.setGameTime(5)
		less_time = true
		return
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
	
	tfm.exec.linkMice(player, player, false)

	local level = levels[ players_level[player] ]
	if not level then return end
	tfm.exec.movePlayer(player, level.x, level.y)

	if level.cheese then
		tfm.exec.giveCheese(player)
	elseif level.uncheese then
		tfm.exec.removeCheese(player)
	end
end)

onEvent("NewGame", function()
	tfm.exec.disablePhysicalConsumables(true)
	tfm.exec.disableMinimalistMode(true)

	roomleaderboard = {}
	check_position = 6
	victory_count = 0
	victory = {_last_level = {}}
	players_level = {}
	times.generated = {}
	times.map_start = os.time()
	checkpoint_info.version = checkpoint_info.next_version
	bonusOffset = bonusOffset == 0 and 500 or 0

  local info = room.xmlMapInfo
  local xml = info and info.xml
  local code = room.currentMap
  local smolified = info and info.author == '#Module'
	local original_author = xml and xml:match('%s+PKAUTHOR="(.-)"%s*')

	if original_author and original_author ~= '#Module' then
		info.author = original_author:gsub('<', ''):gsub('&', '')
	end

  code = code:sub(1, 1) == '@' and code:sub(2) or code

  -- xmlMapInfo doesn't reset if the map doesn't have an xml
  if xml and tostring(info.mapCode) == code and not smolified then
		map_name = ("<J>%s <BL>- %s"):format(info.author:gsub('#0000$', ''), room.currentMap)
		map_gravity = tonumber(xml:match('G=".-,(.-)"')) or 10
	end

	-- prevent /np abuse
	if code ~= lastOpenedMap then
		count_stats = false
	end

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
			tfm.exec.addBonus(0, start_x, start_y, bonusOffset + 2, 0, false)
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
			tfm.exec.linkMice(player, player, false)
			tfm.exec.movePlayer(player, levels[1].x, levels[1].y)

			if levels[1].cheese then
				tfm.exec.giveCheese(player)
			elseif levels[1].uncheese then
				tfm.exec.removeCheese(player)
			end
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
				if spec_mode[name] or player.id == 0 or name:sub(1, 1) == "*" or bans[player.id] then
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

						if next_level.cheese then
							tfm.exec.giveCheese(name)
						elseif next_level.uncheese then
							tfm.exec.removeCheese(name)
						end

						if not victory[name] then
							tfm.exec.setPlayerScore(name, level_id, false)
						end
						tfm.exec.removeImage(checkpoints[name])
						
						tfm.exec.linkMice(player, player, false)

						if level_id == last_level then
							translatedChatMessage("reached_level", name, level_id-1, taken)
							if not victory[name] then -- !cp
								victory._last_level[name] = true
								tfm.exec.giveCheese(name)
								tfm.exec.playerVictory(name)
								tfm.exec.respawnPlayer(name)
								tfm.exec.movePlayer(name, next_level.x, next_level.y)
							end
						else
							translatedChatMessage("reached_level", name, level_id-1, taken)
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
	local checkpointIndex = bonus - bonusOffset
	local level = levels[checkpointIndex]
	if not level then return end
	if not players_level[player] then return end
	if checkpointIndex ~= players_level[player] + 1 then return end
	if os.time() < cp_available[player] then return tfm.exec.addBonus(0, level.x, level.y, bonus, 0, false, player) end

	local taken = (os.time() - (times.checkpoint[player] or times.map_start)) / 1000
	times.checkpoint[player] = os.time()
	players_level[player] = checkpointIndex

	if level.size ~= levels[ checkpointIndex - 1 ].size then
		-- need to change the size
		changePlayerSize(player, level.size)
	end

	if level.cheese then
		tfm.exec.giveCheese(player)
	elseif level.uncheese then
		tfm.exec.removeCheese(player)
	end

	if not victory[player] then
		tfm.exec.setPlayerScore(player, checkpointIndex, false)
	end
	tfm.exec.removeImage(checkpoints[player])
	tfm.exec.linkMice(player, player, false)

	if checkpointIndex == #levels then
		translatedChatMessage("reached_level", player, checkpointIndex-1, taken)
		if not victory[player] then -- !cp
			victory._last_level[player] = true
			tfm.exec.giveCheese(player)
			tfm.exec.playerVictory(player)
			tfm.exec.respawnPlayer(player)
			tfm.exec.movePlayer(player, level.x, level.y)
			return
		end
	else
		translatedChatMessage("reached_level", player, checkpointIndex-1, taken)

		local next_level = levels[checkpointIndex + 1]
		addCheckpointImage(player, next_level.x, next_level.y)

		tfm.exec.addBonus(0, next_level.x, next_level.y, bonus + 1, 0, false, player)
	end

	if level.stop then
		tfm.exec.movePlayer(player, 0, 0, true, 1, 1, false)
		tfm.exec.killPlayer(player)
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

		if review_mode and disable_powers then
			disable_powers = false
			tfm.exec.chatMessage("<v>[#] <d>Powers enabled by " .. player .. ".")
		end

		count_stats = false
		review_mode = not review_mode
		if review_mode then
			tfm.exec.chatMessage("<v>[#] <d>Review mode enabled by " .. player .. ".")
		else
			tfm.exec.chatMessage("<v>[#] <d>Review mode disabled by " .. player .. ".")
			tfm.exec.setRoomMaxPlayers(room_max_players)
			tfm.exec.chatMessage("<v>[#] <d>Room limit is restored to " .. room_max_players, player)
		end
		showStats()

	elseif cmd == "cp" then
		if not levels then return end
		local checkpoint = tonumber(args[1])
		if not checkpoint then
			if players_level[args[1]] then
				checkpoint = players_level[args[1]]
			else
				return translatedChatMessage("invalid_syntax", player)
			end
		end

		if checkpoint == 0 then
			checkpoint = #levels
		end
		
		if checkpoint < 0 and checkpoint >= #levels*-1 then
			checkpoint = #levels + checkpoint 
		end

		if not levels[checkpoint] then return end

		if not review_mode then
			if not victory[player] then return end
		end
		if not players_level[player] then return end

		if checkpoint_info.version == 1 then
			tfm.exec.removeBonus(players_level[player] + 1, player)
		end
		cp_available[player] = os.time() + 750
		players_level[player] = checkpoint
		changePlayerSize(player, levels[checkpoint].size)
		times.checkpoint[player] = os.time()
		tfm.exec.killPlayer(player)
		if not victory[player] then
			tfm.exec.setPlayerScore(player, checkpoint, false)
		end

		if levels[checkpoint].cheese then
			tfm.exec.giveCheese(player)
		elseif levels[checkpoint].uncheese then
			tfm.exec.removeCheese(player)
		end

		local next_level = levels[checkpoint + 1]
		if checkpoints[player] then
			tfm.exec.removeImage(checkpoints[player])
		end
		if next_level then
			addCheckpointImage(player, next_level.x, next_level.y)
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, next_level.x, next_level.y, bonusOffset + checkpoint + 1, 0, false, player)
			end
		else
			if not records_admins then
				victory._last_level[player] = true
			end
		end

	elseif cmd == "spec" then
		if not players_file[player] then return end
		if not perms[player] or not perms[player].spectate then return end

		if args[1] then
			if not perms[player].set_spectate and not review_mode then return end
			if not room.playerList[args[1]] or not players_file[args[1]] then
				return translatedChatMessage("invalid_syntax", player)
			end

			enableSpecMode(args[1], not spec_mode[args[1]])
			inGameLogCommand(player, cmd, args)
			logCommand(player, cmd, quantity, args)
		else
			enableSpecMode(player, not spec_mode[player])
			players_file[player].spec = spec_mode[player]
			savePlayerData(player)
		end

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
		inGameLogCommand(player, "time", args)

	elseif cmd == "redo" then
		if not (records_admins or review_mode) then return end
		if not players_level[player] then return end

		if checkpoint_info.version == 1 then
			tfm.exec.removeBonus(players_level[player] + 1, player)
		end

		cp_available[player] = os.time() + 750
		players_level[player] = 1
		changePlayerSize(player, levels[1].size)
		times.generated[player] = nil
		times.checkpoint[player] = nil
		victory[player] = nil
		victory_count = victory_count - 1

		tfm.exec.setPlayerScore(player, 1, false)
		tfm.exec.killPlayer(player)
		tfm.exec.respawnPlayer(player)

		if levels[1].cheese then
			tfm.exec.giveCheese(player)
		elseif levels[1].uncheese then
			tfm.exec.removeCheese(player)
		end

		local x, y = levels[2].x, levels[2].y
		if checkpoints[player] then
			tfm.exec.removeImage(checkpoints[player])
		end
		addCheckpointImage(player, x, y)
		if checkpoint_info.version == 1 then
			tfm.exec.addBonus(0, x, y, bonusOffset + 2, 0, false, player)
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
		if bans == data then return end
		bans = data
		for player, data in next, room.playerList do
			if in_room[player] then
				if bans[data.id] then
					if AfkInterface.open[player] then
						AfkInterface:remove(player)
					end
					enableSpecMode(player, true)
				end
			end
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