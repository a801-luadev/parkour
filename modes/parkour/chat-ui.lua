-- Stuff related to the chat (not keyboard nor interface)

local fetching_player_room = {}
local roompw = {}
local fastest = {}

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
end)

onEvent("PlayerWon", function(player)
	local id = room.playerList[player].id
	if bans[id] then return end
	if not players_file[player] then return end

	-- If the player joined the room after the map started,
	-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
	local taken = (os.time() - (generated_at[player] or map_start)) / 1000

	if count_stats and taken <= 45 and not review_mode and not is_tribe then
		sendPacket(1, room.name .. "\000" .. player .. "\000" .. id .. "\000" .. room.currentMap .. "\000" .. taken)
	elseif not fastest.record or taken < fastest.record then
		local old = fastest.player

		fastest.record = taken
		fastest.player = player

		if old and in_room[old] then
			setNameColor(old)
		end
	end

	if players_file[player].parkour.congrats == 0 then
		translatedChatMessage("finished", player, player, taken)
	end

	for _player in next, in_room do
		if players_file[_player] and players_file[_player].parkour.congrats == 1 then
			translatedChatMessage("finished", _player, player, taken)
		end
	end

	if is_tribe then
		translatedChatMessage("tribe_house", player)
	elseif room.uniquePlayers < min_save or player_count < min_save then
		translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
	elseif count_stats and not review_mode then
		local power
		for index = 1, #powers do
			power = powers[index]

			if players_file[player].parkour.c == power.maps then
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
	if cmd == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)

	elseif cmd == "give" then
		if not perms[player] or not perms[player].give_command then return end

		if quantity < 2 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local target = capitalize(args[1])
		if not string.find(target, "#", 1, true) then
			target = target .. "#0000"
		end

		local file = players_file[target]
		if not file then
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
				file.parkour.c = file.parkour.c + quantity
			elseif action == "sub" then
				file.parkour.c = file.parkour.c - quantity
			elseif action == "set" then
				file.parkour.c = quantity
			else
				return tfm.exec.chatMessage("<v>[#] <r>" .. action .. " doesnt look like an action wtf", player)
			end

			tfm.exec.chatMessage("<v>[#] <d>" .. target .. "'s new map count: " .. file.parkour.c, player)

		elseif thing == "badge" then
			if quantity < 4 then
				return tfm.exec.chatMessage("<v>[#] <r>u gotta specify a badge id and whether to give or remove it", player)
			end

			local badge, action = tonumber(args[3]), string.lower(args[4])
			if not badge then
				return tfm.exec.chatMessage("<v>[#] <r>" .. badge .. " doesnt look like a badge id?", player)
			elseif badge < 1 or badge > #badges then
				return tfm.exec.chatMessage(
					"<v>[#] <r>there are " .. #badges .. " badges but u want to give the n° " .. badge .. "?", player
				)
			end

			if action == "give" then
				file.parkour.badges[badge] = 1
				NewBadgeInterface:show(player, badge)
			elseif action == "remove" then
				file.parkour.badges[badge] = 0
			else
				return tfm.exec.chatMessage("<v>[#] <r>" .. action .. " doesnt look like an action wtf", player)
			end

			tfm.exec.chatMessage("<v>[#] <d>badge " .. badge .. " affected on player " .. target, player)

		elseif thing == "migration" then
			file.migrated = true
			tfm.exec.chatMessage("<v>[#] <d>given migration flag to " .. target, player)

		else
			return tfm.exec.chatMessage("<v>[#] <r>idk wtf is <b>" .. thing .. "</b>", player)
		end

		savePlayerData(target)

	elseif cmd == "pw" then
		if not perms[player] or not perms[player].enable_review then return end

		if not review_mode and not ranks.admin[player] then
			return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of a room without review mode.", player)
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

	elseif cmd == "roomlimit" then
		if not perms[player] or not perms[player].set_room_limit then return end

		local limit = tonumber(args[1])
		if not limit then
			return translatedChatMessage("invalid_syntax", player)
		end

		tfm.exec.setRoomMaxPlayers(limit)
		tfm.exec.chatMessage("<v>[#] <d>Set room max players to " .. limit .. ".", player)

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

	elseif cmd == "forcestats" then
		if not perms[player].force_stats then return end

		count_stats = true
		tfm.exec.chatMessage("<v>[#] <d>count_stats set to true", player)

	elseif cmd == "room" then
		if not perms[player] or not perms[player].get_player_room then return end

		if quantity == 0 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local fetching = capitalize(args[1])
		fetching_player_room[fetching] = {player, os.time() + 1000}
		system.loadPlayerData(fetching)
	end
end)

onEvent("RawTextAreaCallback", function(id, player, callback)
	if callback == "discord" then
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
	elseif callback == "map_submission" then
		tfm.exec.chatMessage("<rose>" .. links.maps, player)
	elseif callback == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)
	elseif callback == "github" then
		tfm.exec.chatMessage("<rose>" .. links.github, player)
	end
end)

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if action == "_help" then
		tfm.exec.chatMessage("<v>[#] <d>" .. translatedMessage("help_" .. args, player), player)
	end
end)

onEvent("OutPlayerDataParsed", checkRoomRequest)

onEvent("PlayerDataParsed", function(player, data)
	if data.langue and translations[data.langue] then
		player_langs[player] = translations[data.langue]
	end

	translatedChatMessage("welcome", player)
	translatedChatMessage("donate", player)

	checkRoomRequest(player, data)
end)

onEvent("PlayerDataUpdated", checkRoomRequest)

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
end)

onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 4 then -- !announce
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	elseif packet_id == 5 then -- !cannounce
		local commu, msg = string.match(packet, "^([^\000]+)\000(.+)$")
		if commu == room.community then
			tfm.exec.chatMessage("<vi>[" .. commu .. "] [#parkour] <d>" .. msg)
		end
	elseif packet_id == 6 then -- pw request
		if packet == room.name then
			if roompw.password then
				sendPacket(5, room.name .. "\000" .. roompw.password .. "\000" .. roompw.owner)
			else
				sendPacket(5, room.name .. "\000")
			end
		end
	end
end)

onEvent("GameStart", function()
	system.disableChatCommandDisplay("donate")
	system.disableChatCommandDisplay("give")
	system.disableChatCommandDisplay("pw")
	system.disableChatCommandDisplay("roomlimit")
	system.disableChatCommandDisplay("langue")
	system.disableChatCommandDisplay("forcestats")
	system.disableChatCommandDisplay("room")
end)