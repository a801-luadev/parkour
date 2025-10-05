-- Stuff related to the chat (not keyboard nor interface)

local fastest = {}

local GameInterface
local setNameColor

do
local fetching_player_room = {}
local roompw = {}
local init_time = os.time()
local visitors = { _len=0 }
local next_easter_egg = os.time() + math.random(30, 60) * 60 * 1000

local function checkRoomRequest(player, data)
	local fetch = fetching_player_room[player]
	if fetch then
		if data.commu then
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s community: <d>" .. data.commu, fetch[1])
		end
		if data.room then
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. data.room, fetch[1])
		end
		fetching_player_room[player] = nil
	end
end

onEvent("NewGame", function()
	fastest = {}

	if is_tribe then
		translatedChatMessage("tribe_house")
	elseif room.uniquePlayers < min_save then
		translatedChatMessage("min_players", nil, room.uniquePlayers, min_save)
	end

	for player in next, in_room do
		checkMapQuest(player)
	end
end)

onEvent("NewPlayer", function(player)
	if levels then
		if is_tribe then
			translatedChatMessage("tribe_house", player)
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
		end
	end
	
	if not visitors[player] and visitors._len < 50 then
		visitors[player] = os.time()
		visitors._len = visitors._len + 1
		visitors[visitors._len] = player
	end

	if roompw and roompw.password then
		tfm.exec.setRoomPassword(roompw.password)
	end
end)

onEvent("PlayerLeft", function(player)
	if roompw and roompw.password then
		tfm.exec.setRoomPassword(roompw.password)
	end
end)

onEvent("PlayerCompleted", function(player, info, file)
	local id = info.id

	victory[player] = os.time() + 10000 * (1 + math.max(0, file.bancount or 0))

	if records_admins then
		translatedChatMessage("records_completed", player)
	end

	-- If the player joined the room after the map started,
	-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
	local taken = (os.time() - (times.generated[player] or times.map_start)) / 1000

	if not fastest.record or taken < fastest.record then
		local old = fastest.player

		fastest.record = taken
		fastest.player = player
		fastest.submitted = nil

		if old and in_room[old] then
			setNameColor(old)
		end

		if records_admins then
			translatedChatMessage("records_submit", player)
		end

		if taken < 20 and doStatsCount() then
			sendPacket(
				"common",
				packets.rooms.suspicious,
				player .. "\000" ..
				id .. "\000" ..
				file.c .. "\000" ..
				taken .. "\000" ..
				room.currentMap .. "\000" ..
				room.shortName .. "\000" ..
				room.uniquePlayers
			)
		end
	end

	setNameColor(player) -- just in case PlayerRespawn triggers first

	if file.settings[7] == 0 then
		translatedChatMessage("finished", player, player, taken)
	end

	for _player in next, in_room do
		if players_file[_player] and players_file[_player].settings[7] == 1 then
			translatedChatMessage("finished", _player, player, taken)
		end
	end

	eventLeaderboardUpdate(player, taken)

	if records_admins then
		tfm.exec.chatMessage(
			"<v>[#] <d>" .. room.currentMap .. " - CP: " ..
			(checkpoint_info.version == 0 and "old" or "new")
			, player
		)
	end

	if is_tribe then
		translatedChatMessage("tribe_house", player)

	elseif room.uniquePlayers < min_save or player_count < min_save then
		translatedChatMessage(
			"min_players",
			player,
			math.min(room.uniquePlayers, player_count),
			min_save
		)

	elseif count_stats and not records_admins and not review_mode then
		local power
		for index = 1, #powers do
			power = powers[index]

			if file.c == power.maps then
				for _player in next, in_room do
					translatedChatMessage("unlocked_power", _player, player, translatedMessage(power.name, _player))
				end
				break
			end
		end
	end
end)

do
	local function fn(player, args)
		local link = links[args[0]]
		if not link then return end
		tfm.exec.chatMessage("<rose>" .. link, player)
	end

	for name in next, links do
		newCmd({ name = name, fn = fn })
	end

	onEvent("RawTextAreaCallback", function(id, player, callback)
		if links[callback] then
			tfm.exec.chatMessage("<rose>" .. links[callback], player)
		end
	end)
end

newCmd({ name = "submit",
	fn = function(player, args)
		if not records_admins then return end
		-- local map = tonumber(string.sub(room.currentMap, 2))

		-- if fastest.player ~= player then
		-- 	return translatedChatMessage("records_not_fastest", player)
		-- end
		-- if fastest.submitted then
		-- 	return translatedChatMessage("records_already_submitted", player)
		-- end

		-- fastest.submitted = true
		-- fastest.wait_send = true
		
		tfm.exec.chatMessage("<v>[#] <d>You can't send records with this way, check Records Discord server: https://discord.gg/zbjVYAxYzp", player)
	end })

newCmd({ name = "verify",
	fn = function(player, args)
		if args._len < 1 or #args[1] > 60 or args[1]:sub(1, 3) ~= "tfm" then
			return translatedChatMessage("invalid_syntax", player)
		end
		if not checkCooldown(player, "verify", 120 * 1000) then
			return translatedChatMessage("cooldown", player)
		end
		sendPacket("common", packets.rooms.verify, player .. "\000" .. args[1])
		translatedChatMessage("verify_sent", player)
	end
})

newCmd({ name = "pause",
	rank = "admin",
	log = true,
	fn = function(player, args)
		local total = tonumber(args[1]) or 31
		local finish = os.time() + (total - usedRuntime)
		while os.time() < finish do end
		tfm.exec.chatMessage("<v>[#] <d>used " .. (total - usedRuntime) .. "ms of runtime", player)
	end })

newCmd({ name = "runtime",
	rank = "admin",
	fn = function(player, args)
		tfm.exec.chatMessage("<v>[#] <d>used " .. usedRuntime .. "ms for cycle " .. (cycleId - startCycle) .. " and spent total of " .. totalRuntime .. "ms", player)
	end })

newCmd({ name = "give",
	perm = "give_command",
	min_args = 2,
	fn = function(player, args, cmd)
		local target = capitalize(args[1])
		if not string.find(target, "#", 1, true) then
			target = target .. "#0000"
		end

		local file = players_file[target]
		if not file or not room.playerList[target] then
			return tfm.exec.chatMessage("<v>[#] <r>wtf u doin <b>" .. target .. "</b> is not here??¿¿¿", player)
		end

		local thing = string.lower(args[2])
		if thing == "maps" then
			if args._len < 4 then
				return tfm.exec.chatMessage("<v>[#] <r>u gotta specify an action and a quantity noob", player)
			end

			local action, quantity = string.lower(args[3]), tonumber(args[4])
			if not quantity then
				return tfm.exec.chatMessage("<v>[#] <r>" .. args[4] .. " doesnt look like a number; did u fail math?", player)
			end

			if action == "add" then
				file.c = file.c + quantity
			elseif action == "sub" then
				file.c = file.c - quantity
			elseif action == "set" then
				file.c = quantity
			elseif action == "migrate" then
				file.c = file.c + quantity
				file.migrated = true
			else
				return tfm.exec.chatMessage("<v>[#] <r>" .. action .. " doesnt look like an action wtf", player)
			end

			tfm.exec.chatMessage("<v>[#] <d>" .. target .. "'s new map count: " .. file.c, player)

		elseif thing == "badge" then
			if args._len < 4 then
				return tfm.exec.chatMessage("<v>[#] <r>u gotta specify a badge group and badge id", player)
			end

			local group, badge = tonumber(args[3]), tonumber(args[4])
			if not group then
				return tfm.exec.chatMessage("<v>[#] <r>" .. args[3] .. " doesnt look like a badge group?", player)
			elseif not badge then
				return tfm.exec.chatMessage("<v>[#] <r>" .. args[4] .. " doesnt look like a badge id?", player)
			elseif group < 1 or group > #badges then
				return tfm.exec.chatMessage(
					"<v>[#] <r>there are " .. #badges .. " badge groups but u want to give the n° " .. badge .. "?", player
				)
			elseif badge < 0 or badge > #badges[group] then
				return tfm.exec.chatMessage(
					"<v>[#] <r>that group has ids 0-" .. #badges[group] .. " but u want " .. badge .. "?", player
				)
			elseif badges[group].filePriority then
				return tfm.exec.chatMessage("<v>[#] <r>that badge group can only be affected by bots", player)
			end

			file.badges[group] = badge
			if badge > 0 then
				NewBadgeInterface:show(target, group, badge)
			end

			tfm.exec.chatMessage("<v>[#] <d>badge group " .. group .. " affected on player " .. target, player)

		elseif thing == "migration" then
			file.migrated = true
			tfm.exec.chatMessage("<v>[#] <d>given migration flag to " .. target, player)

		elseif thing == "coins" then
			if args._len < 3 then
				return translatedChatMessage("invalid_syntax", player)
			end

			local coin_count = args[3]
			if not tonumber(coin_count) then
				tfm.exec.chatMessage("<v>[#] <d> doesnt look like a number", player)
				return
			end

			file.coins = file.coins + coin_count
			tfm.exec.chatMessage("<v>[#] <d>" .. target .. "'s new coin count: " .. file.coins, player)

		elseif thing == "namecolor" then
			if not perms[player].set_name_color then
				return tfm.exec.chatMessage("<v>[#] <r>u cant set a player's namecolor", player)
			end

			if args._len > 2 then
				if string.lower(args[3]) == "nil" then
					tfm.exec.chatMessage("<v>[#] <d>removed custom namecolor from " .. target, player)
					file.namecolor = nil
				else
					local color = string.match(args[3], "^#?(%x%x%x%x%x%x)$")
					color = color and tonumber(color, 16)
					if not color then
						return tfm.exec.chatMessage("<v>[#] <r>" .. args[3] .. " doesnt look like a color", player)
					end

					file.namecolor = color
					tfm.exec.chatMessage(
						string.format("<v>[#] <d>set name color of %s to <font color='#%06x'>#%06x</font>", target, color, color),
						player
					)
				end

				setNameColor(target)

			else
				ui.showColorPicker(room.playerList[target].id, player, file.namecolor, target .. "'s namecolor")
				return
			end

		else
			return tfm.exec.chatMessage("<v>[#] <r>idk wtf is <b>" .. thing .. "</b>", player)
		end

		savePlayerData(target)
		chatlogCmd(cmd, player, args)
		logCmd(cmd, player, args)
	end })

newCmd({ name = "roommod",
	min_args = 1,
	fn = function(player, args, cmd)
		if not records_admins then return end

		local has_perm = perms[player] and perms[player].change_roommod
		local is_owner = records_admins[player]
		if not has_perm and not is_owner then
			return
		end

		local target = args[1]
		if records_admins[target] or not room.playerList[target] then
			return translatedChatMessage("invalid_syntax", player)
		end

		records_admins[target] = 1
		tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is a room mod now.")

		chatlogCmd(cmd, player, args, records_admins)

		-- don't log room owner actions
		if is_owner then
			return
		end

		logCmd(cmd, player, args)
	end })

newCmd({ name = "deroommod",
	min_args = 1,
	fn = function(player, args, cmd)
		if not records_admins then return end

		local has_perm = perms[player] and perms[player].change_roommod
		local is_owner = records_admins[player]
		if not has_perm and not is_owner then
			return
		end

		local target = args[1]
		if records_admins[target] ~= 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		records_admins[target] = nil
		tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is not a room mod anymore.")

		chatlogCmd(cmd, player, args, records_admins)

		-- don't log room owner actions
		if is_owner then
			return
		end

		logCmd(cmd, player, args)
	end })

newCmd({ name = {"creators", "visitors"},
	perm = "view_creators",
	fn = function(player, args)
		local startIndex = math.max(1, tonumber(args[1]) or 1)
		local endIndex = math.min(startIndex + 9, visitors._len)
	
		local creatorsEndIndex = startIndex - 1

		for i=startIndex, endIndex do
			if visitors[visitors[i]] < init_time + 1000 then
				creatorsEndIndex = i
			end
		end

		tfm.exec.chatMessage(
			("<v>[#] <j>Visitors %s-%s/%s: <ch>%s <bl>%s"):format(
				startIndex, endIndex, visitors._len,
				table.concat(visitors, " ", startIndex, creatorsEndIndex),
				table.concat(visitors, " ", creatorsEndIndex + 1, endIndex)
			), player
		)
	end })

newCmd({ name = "pw?",
	rank = "admin",
	fn = function(player, args)
		tfm.exec.chatMessage("<v>[#] <d>owner: <bl>" .. tostring(roompw.owner), player)
		tfm.exec.chatMessage("<v>[#] <d>password: <bl>" .. tostring(roompw.password), player)
	end })

newCmd({ name = "pw",
	fn = function(player, args)
		if not records_admins or not records_admins[player] then
			if not perms[player] or not perms[player].enable_review then return end

			if not review_mode and not ranks.admin[player] then
				return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of a room without review mode.", player)
			end
		end

		if roompw.owner and roompw.owner ~= player and not ranks.admin[player] then
			return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of this room. Ask " .. roompw.owner .. " to do so.", player)
		end

		local password = table.concat(args, " ")
		tfm.exec.setRoomPassword(password)

		if password == "" then
			roompw.owner = nil
			roompw.password = nil
			return tfm.exec.chatMessage("<v>[#] <d>Room password disabled by " .. player .. ".")
		end
		tfm.exec.chatMessage("<v>[#] <d>Room password changed by " .. player .. ".")
		tfm.exec.chatMessage("<v>[#] <d>You set the room password to: " .. password, player)

		if not roompw.owner then
			roompw.owner = player
		end
		roompw.password = password
	end })

newCmd({ name = "roomlimit",
	min_args = 1,
	fn = function(player, args, cmd)
		if not perms[player] or not perms[player].set_room_limit and not perms[player].set_room_limit_review then return end

		local limit = tonumber(args[1])
		if not limit then
			return translatedChatMessage("invalid_syntax", player)
		end

		local review_only = not perms[player].set_room_limit and perms[player].set_room_limit_review
		if review_only and not review_mode then
			return tfm.exec.chatMessage("<r>Enable review mode first.", player)
		end

		tfm.exec.setRoomMaxPlayers(limit)
		tfm.exec.chatMessage("<v>[#] <d>Set room max players to " .. limit .. ".", player)

		chatlogCmd(cmd, player, args)
		logCmd(cmd, player, args)
	end })

newCmd({ name = {"langue", "lang"},
	fn = function(player, args, cmd)
		if args._len == 0 then
			tfm.exec.chatMessage("<v>[#] <d>Available languages:", player)
			for name, data in next, translations do
				if name ~= "pt" then
					tfm.exec.chatMessage("<d>" .. name .. " - " .. data.fullname, player)
				end
			end
			tfm.exec.chatMessage("<d>Type <b>!langue ID</b> to switch your language.", player)
		elseif players_file[player] then
			local lang = string.lower(args[1])
			if translations[lang] then
				player_langs[player] = translations[lang]
				players_file[player].langue = lang
				translatedChatMessage("new_lang", player)

				savePlayerData(player)
			else
				tfm.exec.chatMessage("<v>[#] <r>Unknown language: <b>" .. lang .. "</b>", player)
			end
		end
	end })

newCmd({ name = "forcestats",
	perm = "force_stats",
	log = true,
	chatlog = true,
	fn = function(player, args)
		if records_admins then
			return tfm.exec.chatMessage("<v>[#] <r>you can't forcestats in a records room", player)
		end

		if args[1] and args[1] ~= room.currentMap then
			return
		end

		count_stats = true
		tfm.exec.chatMessage("<v>[#] <d>count_stats set to true", player)
		args[1] = room.currentMap
		args[2] = room.xmlMapInfo and room.xmlMapInfo.permCode or -1
		showStats()
	end })

newCmd({ name = "room",
	fn = function(player, args, cmd)
		if args._len == 0 or capitalize(args[1]) == player then
			tfm.exec.chatMessage("<v>[#] <d>" .. room.name, player)
			return
		end

		if not perms[player] or not perms[player].get_player_room then return end

		local fetching = capitalize(args[1])
		if in_room[fetching] then
			tfm.exec.chatMessage("<v>[#] <d>" .. fetching .. " is here ._.", player)
			return
		end

		fetching_player_room[fetching] = { player, os.time() + 1000 }
		system.loadPlayerData(fetching)
		logCmd(cmd, player, args)
	end })

onEvent("ColorPicked", function(id, player, color)
	if not perms[player] or not perms[player].set_name_color then return end
	if color == -1 then return end

	for name, data in next, room.playerList do
		if data.id == id then
			local file = players_file[name]
			if not file then
				return tfm.exec.chatMessage("<v>[#] <r>" .. name .. " has left the room :(", player)
			end
			eventChatCommand(player, string.format("give %s namecolor #%06x", name, color))
			return
		end
	end
end)

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if action == "_help" then
		tfm.exec.chatMessage("<v>[#] <d>" .. translatedMessage("help_" .. args, player), player)
	elseif action == "msg" then
		tfm.exec.chatMessage("<j>" .. args, player)
	end
end)

onEvent("OutPlayerDataParsed", checkRoomRequest)

onEvent("PlayerDataParsed", function(player, data)
	if data.langue and translations[data.langue] then
		player_langs[player] = translations[data.langue]
	end

	checkRoomRequest(player, data)
	checkMapQuest(player)

	if records_admins then
		if string.find(room.lowerName, string.lower(player), 1, true) then
			records_admins[player] = true
		end
	end

	if data.settings[6] == 1 then
		translatedChatMessage("welcome", player)
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
		--translatedChatMessage("forum_topic", player, links.forum)
		translatedChatMessage("report", player)
		--translatedChatMessage("donate", player)

		local now = os.time()
		for key, t in next, app_times do
			if now < t then
				translatedChatMessage(key, player, links[key])
			end
		end
	
		if is_before_anniversary then
			translatedChatMessage("anniversary", player)
		elseif is_anniversary then
			translatedChatMessage("anniversary_start", player)
		elseif is_after_anniversary then
			translatedChatMessage("anniversary_end", player)
		end

		if records_admins then
			translatedChatMessage("records_enabled", player, links.records)

			if records_admins[player] then
				translatedChatMessage("records_admin", player)
			end
		end

		if disable_powers then
			translatedChatMessage("powers_disabled", player)
		end
	end
end)

onEvent("Loop", function()
	local now = os.time()

	local to_remove, count = {}, 0
	for player, data in next, fetching_player_room do
		if now >= data[2] then
			count = count + 1
			to_remove[count] = player
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n> is offline.", data[1])
		end
	end

	for idx = 1, count do
		fetching_player_room[to_remove[idx]] = nil
	end

	if now >= next_easter_egg then
		next_easter_egg = now + math.random(30, 60) * 60 * 1000

		if os.date("%d/%m/%Y", now + 60 * 60 * 1000) == "28/02/2021" then
			translatedChatMessage("easter_egg_" .. math.random(0, 13))
		end
	end
end)

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == 4 then -- !announce
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	elseif id == 5 then -- !cannounce
		local commu, msg = string.match(packet, "^([^\000]+)\000(.+)$")
		if commu == room.community then
			tfm.exec.chatMessage("<vi>[" .. commu .. "] [#parkour] <d>" .. msg)
		end
	elseif id == 6 then -- pw request
		if packet == room.shortName then
			if roompw.password then
				sendPacket("common", 5, room.shortName .. "\000" .. roompw.password .. "\000" .. roompw.owner)
			else
				sendPacket("common", 5, room.shortName .. "\000")
			end
		end
	elseif id == 7 then -- remote room announcement
		local targetRoom, targetPlayer, msg = string.match(
			packet,
			"^([^\000]+)\000([^\000]+)\000(.+)$"
		)
		-- an announcement might target a room, a player or both
		if room.name == targetRoom then
			-- targets a room
			tfm.exec.chatMessage(msg)

		elseif players_file[targetPlayer] then
			-- targets a player (regardless of the room)
			tfm.exec.chatMessage(msg, targetPlayer)
		end
	end
end)

if records_admins then
	onEvent("CantSendData", function(channel)
		if channel == "common" and fastest.wait_send then
			fastest.submitted = false
			fastest.wait_send = false
			tfm.exec.chatMessage(
				"<v>[#] <r>Your record couldn't be submitted. Type <b>!submit</b> again in a few minutes.",
				fastest.player
			)
		end
	end)

	onEvent("RetrySendData", function(channel)
		if channel == "common" and fastest.wait_send then
			tfm.exec.chatMessage(
				"<v>[#] <r>Failed to send your record. Retrying in a moment.",
				fastest.player
			)
		end
	end)

	onEvent("PacketSent", function(channel)
		if channel == "common" and fastest.wait_send then
			translatedChatMessage("records_submitted", fastest.player, room.currentMap)
			fastest.wait_send = false
		end
	end)
end
end