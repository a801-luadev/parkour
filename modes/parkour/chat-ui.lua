-- Stuff related to the chat (not keyboard nor interface)

local fetching_player_room = {}
local roompw = {}
local roomcreators = {}
local fastest = {}
local next_easter_egg = os.time() + math.random(30, 60) * 60 * 1000

local GameInterface
local setNameColor

local function capitalize(str)
	local first = string.sub(str, 1, 1)
	if first == "+" then
		return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
	else
		return string.upper(first) .. string.lower(string.sub(str, 2))
	end
end

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
end)

onEvent("NewPlayer", function(player)
	if levels then
		if is_tribe then
			translatedChatMessage("tribe_house", player)
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
		end
	end
	
	if roomcreators and #roomcreators < 10 then
		roomcreators[1 + #roomcreators] = player
	end
end)

onEvent("PlayerWon", function(player)
	if not room.playerList[player] then return end
	local id = room.playerList[player].id
	if bans[id] then return end
	if victory[player] then return end
	local file = players_file[player]
	if not file then return end
	if not levels then return end

	victory[player] = true
	setNameColor(player) -- just in case PlayerRespawn triggers first

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
	end

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

onEvent("ChatCommand", function(player, msg)
	local cmd, args, pointer = "", {}, -1
	for slice in string.gmatch(msg, "%S+") do
		pointer = pointer + 1
		if pointer == 0 then
			cmd = string.lower(slice)
		else
			args[pointer] = slice
		end
	end

	eventParsedChatCommand(player, cmd, pointer, args)
end)

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	local max_args = quantity

	if cmd == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)
		return

	elseif cmd == "discord" then
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
		return

	elseif cmd == "submit" then
		if not records_admins then return end
		local map = tonumber(string.sub(room.currentMap, 2))

		if fastest.player ~= player then
			return translatedChatMessage("records_not_fastest", player)
		end
		if fastest.submitted then
			return translatedChatMessage("records_already_submitted", player)
		end

		fastest.submitted = true
		fastest.wait_send = true
		
		tfm.exec.chatMessage("<v>[#] <d>You can't send record with this way, check Records Discord server: https://discord.gg/zbjVYAxYzp", player)

	elseif cmd == "pause" then -- logged
		if not ranks.admin[player] then return end

		local total = tonumber(args[1]) or 31

		local finish = os.time() + (total - usedRuntime)
		while os.time() < finish do end

		tfm.exec.chatMessage("<v>[#] <d>used " .. (total - usedRuntime) .. "ms of runtime", player)
		max_args = 1

	elseif cmd == "give" then -- logged
		if not perms[player] or not perms[player].give_command then return end

		if quantity < 2 then
			return translatedChatMessage("invalid_syntax", player)
		end

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
			if quantity < 4 then
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
			if quantity < 4 then
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
			
			if quantity < 2 then
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

			if quantity > 2 and string.lower(args[3]) == "nil" then
				tfm.exec.chatMessage("<v>[#] <d>removed custom namecolor from " .. target, player)
				file.namecolor = nil
				setNameColor(target)

			else
				ui.showColorPicker(room.playerList[target].id, player, file.namecolor, target .. "'s namecolor")
				return
			end

		else
			return tfm.exec.chatMessage("<v>[#] <r>idk wtf is <b>" .. thing .. "</b>", player)
		end

		savePlayerData(target)

	elseif cmd == "roommod" then
		local has_perm = perms[player] and perms[player].change_roommod
		local is_owner = records_admins and records_admins[player]
		if not has_perm and not is_owner then
			return
		end

		local target = args[1]
		if quantity < 1 or records_admins[target] or not room.playerList[target] then
			return translatedChatMessage("invalid_syntax", player)
		end

		records_admins[target] = 1
		tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is a room mod now.")

		-- don't log room owner actions
		if is_owner then
			return
		end

	elseif cmd == "deroommod" then
		local has_perm = perms[player] and perms[player].change_roommod
		local is_owner = records_admins and records_admins[player]
		if not has_perm and not is_owner then
			return
		end

		local target = args[1]
		if quantity < 1 or records_admins[target] ~= 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		records_admins[target] = nil
		tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is not a room mod anymore.")

		-- don't log room owner actions
		if is_owner then
			return
		end

	elseif cmd == "creators" then
		if not perms[player] or not perms[player].view_creators then return end

		tfm.exec.chatMessage("<v>[#] <bl>People in the room when the module was loaded:", player)
		for i=1, #roomcreators, 10 do
			tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(roomcreators, ' ', i, math.min(i+9, #roomcreators)), player)
		end

	elseif cmd == "pw" then
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
		return

	elseif cmd == "roomlimit" then -- logged
		if not perms[player] or not perms[player].set_room_limit then return end

		local limit = tonumber(args[1])
		if not limit then
			return translatedChatMessage("invalid_syntax", player)
		end

		tfm.exec.setRoomMaxPlayers(limit)
		tfm.exec.chatMessage("<v>[#] <d>Set room max players to " .. limit .. ".", player)
		max_args = 1

	elseif cmd == "langue" then
		if quantity == 0 then
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
		return

	elseif cmd == "forcestats" then -- logged
		if not perms[player] or not perms[player].force_stats then return end

		if records_admins then
			return tfm.exec.chatMessage("<v>[#] <r>you can't forcestats in a records room", player)
		end

		count_stats = true
		tfm.exec.chatMessage("<v>[#] <d>count_stats set to true", player)
		max_args = 0

	elseif cmd == "room" then -- logged
		if quantity == 0 or capitalize(args[1]) == player then
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
		max_args = 1

	else
		return
	end

	logCommand(player, cmd, math.min(quantity, max_args), args)
end)

onEvent("ColorPicked", function(id, player, color)
	if not perms[player] or not perms[player].set_name_color then return end
	if color == -1 then return end

	for name, data in next, room.playerList do
		if data.id == id then
			local file = players_file[name]
			if not file then
				return tfm.exec.chatMessage("<v>[#] <r>" .. name .. " has left the room :(", player)
			end
			file.namecolor = color

			tfm.exec.chatMessage(
				string.format("<v>[#] <d>set name color of %s to <font color='#%06x'>#%06x</font>", name, color, color),
				player
			)
			setNameColor(name)

			savePlayerData(name)

			logCommand(player, string.format("give %s namecolor #%06x", name, color))
			return
		end
	end
end)

onEvent("RawTextAreaCallback", function(id, player, callback)
	if callback == "discord" then
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
	elseif callback == "map_submission" then
		tfm.exec.chatMessage("<rose>" .. links.maps, player)
	elseif callback == "forum" then
		tfm.exec.chatMessage("<rose>" .. links.forum, player)
	elseif callback == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)
	elseif callback == "github" then
		tfm.exec.chatMessage("<rose>" .. links.github, player)
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

	if data.settings[6] == 1 then
		translatedChatMessage("welcome", player)
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
		--translatedChatMessage("forum_topic", player, links.forum)
		translatedChatMessage("report", player)
		--translatedChatMessage("donate", player)
	
		if is_before_anniversary then
			translatedChatMessage("anniversary", player)
		elseif is_anniversary then
			translatedChatMessage("anniversary_start", player)
		elseif is_after_anniversary then
			translatedChatMessage("anniversary_end", player)
		end

		if records_admins then
			translatedChatMessage("records_enabled", player, links.records)

			if string.find(room.lowerName, string.lower(player), 1, true) then
				records_admins[player] = true
				translatedChatMessage("records_admin", player)
			end
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

onEvent("GameStart", function()
	system.disableChatCommandDisplay("donate")
	system.disableChatCommandDisplay("discord")
	system.disableChatCommandDisplay("submit")
	system.disableChatCommandDisplay("pause")
	system.disableChatCommandDisplay("give")
	system.disableChatCommandDisplay("pw")
	system.disableChatCommandDisplay("roomlimit")
	system.disableChatCommandDisplay("langue")
	system.disableChatCommandDisplay("forcestats")
	system.disableChatCommandDisplay("room")
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
