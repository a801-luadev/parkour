-- Stuff related to the keyboard and game interface (not chat)

local interfaces = {
	[72] = HelpInterface,
	[76] = LeaderboardInterface,
	[79] = OptionsInterface,
	[80] = PowersInterface
}
local interfaces_ordered = {_count = 0}
local profile_request = {}
local update_at = 0
local previous_power_quantity = 0
local reset_powers = false
local online_staff = {
	next_request = 0,
	next_show = 0,
	requesters = {_count = 0}
}
local shown_ranks = {"trainee", "mod", "mapper", "manager", "admin"}
no_help = {}
local map_polls = {}
local current_poll

local function closeAllInterfaces(player)
	for index = 1, interfaces_ordered._count do
		if interfaces_ordered[index].open[player] then
			interfaces_ordered[index]:remove(player)
			break
		end
	end

	if Profile.open[player] then
		Profile:remove(player)
	end
	if PowerTracker.open[player] then
		PowerTracker:remove(player)
	end
	if Staff.open[player] then
		Staff:remove(player)
	end
end

local function checkProfileRequest(player, data)
	local fetch = profile_request[player]
	if fetch then
		local requester = fetch[1]
		if Profile.open[requester] then
			Profile:update(requester, player, data)
		else
			closeAllInterfaces(requester)
			Profile:show(requester, player, data)
		end
		profile_request[player] = nil
	end
end

local function toggleInterface(interface, player)
	if not players_file[player] then return end
	if not checkCooldown(player, "interfaceTrigger", 500) then return end

	if not interface.open[player] then
		closeAllInterfaces(player)

		interface:showDefault(player)
	else
		interface:remove(player)
	end
end

function setNameColor(player)
	local file = players_file[player]
	if file then
		if file.hidden then
			tfm.exec.setNameColor(
				player,

				fastest.player == player and 0xFFFFFF
				or victory[player] and 0xFFFF00
				or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3
				or 0x148DE6
			)
			return
		elseif file.namecolor then
			tfm.exec.setNameColor(
				player,

				fastest.player == player and 0xFFFFFF
				or victory[player] and 0xFFFF00
				or file.namecolor
			)
			return
		end
	end

	tfm.exec.setNameColor(
		player,

		fastest.player == player and 0xFFFFFF -- fastest
		or victory[player] and 0xFFFF00 -- has won

		or (ranks.admin[player] or ranks.bot[player]) and 0xE7342A -- admin / bot
		or ranks.manager[player] and 0xD0A9F0 -- manager
		or (ranks.mod[player] or ranks.trainee[player]) and 0xFFAAAA -- moderator
		or ranks.mapper[player] and 0x25C059 -- mapper
		or ranks.translator[player] and 0xE0B856 -- translator
		
		or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
		or 0x148DE6 -- default
	)
end

local function showPoll(player)
	if not current_poll then return end

	local interface = current_poll.interface
	local results
	if perms[player] and perms[player].start_round_poll then
		results = current_poll.results
		interface = interface.closer
	elseif current_poll.with_close then
		interface = interface.closer
	end

	if current_poll.interface.open[player] then
		interface:update(player, current_poll.translation, current_poll.title, current_poll.buttons, results)
	else
		interface:show(player, current_poll.translation, current_poll.title, current_poll.buttons, results)
	end
end

onEvent("GameStart", function()
	for key, interface in next, interfaces do
		interfaces_ordered._count = interfaces_ordered._count + 1
		interfaces_ordered[ interfaces_ordered._count ] = interface
	end
end)

onEvent("Keyboard", function(player, key, down, x, y)
	local interface = interfaces[key]
	if interface then
		toggleInterface(interface, player)

	elseif key == (players_file[player] and players_file[player].settings[2]) or key == 46 then
		if not checkCooldown(player, "keyMort", 1000) then return end

		tfm.exec.killPlayer(player)

	elseif key == 70 then
		if not players_file[player] then return end
		if not checkCooldown(player, "keyHelp", 3000) then return end

		local file = players_file[player]

		if file.settings[8] == 1 then
			file.settings[8] = 0

			if no_help[player] then
				tfm.exec.removeImage(no_help[player])
				no_help[player] = nil
			end
		else
			file.settings[8] = 1

			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end

		savePlayerData(player)
	end
end)

onEvent("TextAreaCallback", function(id, player, callback)
	if player == "Tocutoeltuco#5522" and callback == "room_state_check" then
		return ui.addTextArea(id, usedRuntime .. "\000" .. totalRuntime .. "\000" .. (cycleId - startCycle), player)
	end

	if not players_file[player] then return end

	local position = string.find(callback, ":", 1, true)
	local action, args
	if not position then
		eventRawTextAreaCallback(id, player, callback)
	else
		eventParsedTextAreaCallback(id, player, string.sub(callback, 1, position - 1), string.sub(callback, position + 1))
	end
end)

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if cmd == "lb" then
		toggleInterface(LeaderboardInterface, player)

	elseif cmd == "help" then
		toggleInterface(HelpInterface, player)

	elseif cmd == "op" then
		toggleInterface(OptionsInterface, player)

	elseif cmd == "poll" then
		if not perms[player] or not perms[player].start_round_poll then return end

		if quantity == 0 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local action = string.lower(args[1])
		if action == "start" then
			if current_poll then
				return tfm.exec.chatMessage(
					"<v>[#] <r>There is already an ongoing poll on this map. Use <b>!poll see</b> to see the results.", player
				)
			end

			current_poll = {
				interface = polls.small[3],
				voters = {},
				with_close = false,
				with_results = false,
				translation = true,
				title = "like_map",
				buttons = {"yes", "no", "idk"},
				results = {total = 0, [1] = 0, [2] = 0, [3] = 0}
			}
			for player in next, in_room do
				if victory[player] or (perms[player] and perms[player].start_round_poll) then
					showPoll(player)
				end
			end

		elseif action == "see" then
			if not current_poll then
				return tfm.exec.chatMessage(
					"<v>[#] <r>There is not an active poll on this map. Use <b>!poll start</b> to start a quick one.", player
				)
			end

			showPoll(player)

		elseif action == "stop" then
			if not current_poll then
				return tfm.exec.chatMessage(
					"<v>[#] <r>There is not an active poll on this map. Use <b>!poll start</b> to start a quick one.", player
				)
			end

			if global_poll then
				return tfm.exec.chatMessage(
					"<v>[#] <r>The current poll is automated. You can't stop it.", player
				)
			end

			local to_remove, count = {}, 0
			for player in next, current_poll.interface.open do
				count = count + 1
				to_remove[count] = player
			end

			for index = 1, count do
				current_poll.interface:remove(to_remove[index])
			end

			current_poll = nil

		else
			return tfm.exec.chatMessage("<v>[#] <r>Unknown action: <b>" .. action .. "</b>.", player)
		end

	elseif cmd == "staff" then
		if Staff.open[player] then return end

		local now = os.time()
		if now >= online_staff.next_request then
			online_staff = {
				next_request = now + 60000,
				next_show = now + 1000,
				requesters = {_count = 1, [1] = player}
			}
			online = {}
			hidden = {}

			local requested = {}
			local member
			for _, rank in next, shown_ranks do
				for index = 1, ranks[rank]._count do
					member = ranks[rank][index]

					if not requested[member] then
						requested[member] = true
						system.loadPlayerData(member)
					end
				end
			end

		elseif online_staff.next_show ~= 0 then
			online_staff.requesters._count = online_staff.requesters._count + 1
			online_staff.requesters[ online_staff.requesters._count ] = player

		else
			closeAllInterfaces(player)
			Staff:show(player)
		end

	elseif cmd == "hide" then
		if not perms[player] or not perms[player].hide then return end
		if ranks.hidden[player] then
			return tfm.exec.chatMessage("<v>[#] <r>You're a hidden staff. You can't use this command.", player)
		end

		players_file[player].hidden = not players_file[player].hidden

		if players_file[player].hidden then
			tfm.exec.chatMessage("<v>[#] <d>You're now hidden. Your nickname will be blue and you won't appear in staff list.", player)
		else
			tfm.exec.chatMessage("<v>[#] <d>You're now visible. Everything's back to normal.", player)
		end
		setNameColor(player)

		savePlayerData(player)

	elseif cmd == "track" then
		if not perms[player] or not perms[player].use_tracker then return end

		if PowerTracker.open[player] then return end

		closeAllInterfaces(player)
		PowerTracker:show(player, used_powers)

	elseif cmd == "profile" or cmd == "p" then
		if not checkCooldown(player, "interfaceTrigger", 500) then return end

		if quantity == 0 then
			if Profile.open[player] then
				Profile:update(player, player)
			else
				closeAllInterfaces(player)
				Profile:show(player, player)
			end

		else
			local request = capitalize(args[1])
			if not string.find(request, "#", 1, true) then
				request = request .. "#0000"
			end

			if request == "Parkour#8558" or request == "Holybot#0000" then
				return translatedChatMessage("cant_load_bot_profile", player)
			end

			if players_file[request] then
				if Profile.open[player] then
					Profile:update(player, request)
				else
					closeAllInterfaces(player)
					Profile:show(player, request)
				end
			else
				profile_request[request] = {player, os.time() + 1000}
				system.loadPlayerData(request)
			end
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disableMinimalistMode(true)

	system.disableChatCommandDisplay("lb")
	system.disableChatCommandDisplay("help")
	system.disableChatCommandDisplay("op")
	system.disableChatCommandDisplay("staff")
	system.disableChatCommandDisplay("track")
	system.disableChatCommandDisplay("profile")
	system.disableChatCommandDisplay("p")
	system.disableChatCommandDisplay("hide")
	system.disableChatCommandDisplay("poll")
end)

onEvent("PollVote", function(poll, player, button)
	if not current_poll or current_poll.voters[player] then return end

	if global_poll then
		sendPacket("common", 8, tostring(button)) -- 1 = yes, 2 = no, 3 = idk
	end

	current_poll.voters[player] = true
	current_poll.results.total = current_poll.results.total + 1
	current_poll.results[button] = current_poll.results[button] + 1

	local closer = current_poll.interface.closer
	if current_poll.with_results then
		if not current_poll.with_close then
			current_poll.interface:remove(player)
			closer:show(player, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
		else
			closer:update(player, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
		end

		for voter in next, current_poll.voters do
			if voter ~= player and closer.open[voter] then
				closer:update(voter, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
			end
		end

	elseif current_poll.with_close then
		closer:remove(player)
	
	else
		current_poll.interface:remove(player)
	end

	for viewer in next, closer.open do
		if perms[viewer] and perms[viewer].start_round_poll then
			closer:update(viewer, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
		end
	end
end)

onEvent("RawTextAreaCallback", function(id, player, callback)
	if callback == "settings" then
		toggleInterface(OptionsInterface, player)

	elseif callback == "help_button" then
		toggleInterface(HelpInterface, player)

	elseif callback == "powers" then
		toggleInterface(PowersInterface, player)
	end
end)

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if action == "emote" then
		local emote = tonumber(args)
		if not emote then return end

		tfm.exec.playEmote(player, emote)
	end
end)

onEvent("NewPlayer", function(player)
	for key in next, interfaces do
		bindKeyboard(player, key, true, true)
	end
	bindKeyboard(player, 70, true, true) -- F key

	for _player, img in next, no_help do
		tfm.exec.addImage("1722eeef19f.png", "$" .. _player, -10, -35, player)
	end

	for _player in next, in_room do
		setNameColor(_player)
	end

	if (current_poll
		and not current_poll.voters[player]
		and (victory[player] or (perms[player] and perms[player].start_round_poll))) then
		showPoll(player)
	end
end)

onEvent("PlayerWon", function(player)
	if (current_poll
		and not current_poll.voters[player]) then
		showPoll(player)
	end
end)

onEvent("PlayerLeft", function(player)
	GameInterface.open[player] = nil
end)

onEvent("PlayerRespawn", function(player)
	if no_help[player] then
		no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
	end
	setNameColor(player)
end)

onEvent("NewGame", function(player)
	reset_powers = false
	no_help = {}

	if current_poll then
		local to_remove, count = {}, 0
		for player in next, current_poll.interface.open do
			count = count + 1
			to_remove[count] = player
		end

		for index = 1, count do
			current_poll.interface:remove(to_remove[index])
		end

		current_poll = nil
	end

	if global_poll then
		-- execute as bot as it has all the permissions
		eventParsedChatCommand("Tocutoeltuco#5522", "poll", 1, {"start"})
	end

	for player in next, in_room do
		if players_file[player] and players_file[player].settings[8] == 1 then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end
		setNameColor(player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	bindKeyboard(player, data.settings[2], true, true)

	if data.settings[8] == 1 then
		no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
	end

	checkProfileRequest(player, data)

	setNameColor(player)

	GameInterface:show(player)
end)

onEvent("OutPlayerDataParsed", checkProfileRequest)

onEvent("Loop", function(elapsed)
	local now = os.time()

	local to_remove, count = {}, 0
	for player, data in next, profile_request do
		if now >= data[2] then
			count = count + 1
			to_remove[count] = player
			translatedChatMessage("cant_load_profile", data[1], player)
		end
	end

	if not reset_powers and elapsed >= 27000 then
		used_powers = {_count = 0}
		reset_powers = true
	end

	if previous_power_quantity ~= used_powers._count then
		previous_power_quantity = used_powers._count

		for player in next, PowerTracker.open do
			PowerTracker:update(player, used_powers)
		end
	end

	for idx = 1, count do
		profile_request[to_remove[idx]] = nil
	end

	if update_at >= now then
		local minutes = math.floor((update_at - now) / 60000)
		local seconds = math.floor((update_at - now) / 1000) % 60
		for player in next, in_room do
			ui.addTextArea(-1, translatedMessage("module_update", player, minutes, seconds), player, 0, 380, 800, 20, 1, 1, 0.7, true)
		end
	end

	if online_staff.next_show ~= 0 and now >= online_staff.next_show then
		online_staff.next_show = 0

		local room_commu = room.community
		local rank_lists = {}
		local commu, players, list
		local rank_name, rank, info
		local player, tbl, hide
		for i = 1, #shown_ranks do
			rank_name = shown_ranks[i]
			rank = ranks[rank_name]

			if rank_name == "trainee" then
				rank_name = "mod"
			end

			info = rank_lists[rank_name]
			if info then
				players, list, hide = info.players, info.list, info.hide
			else
				players, list, hide = {_count = 0}, {_count = 0}, {_count = 0}
				rank_lists[rank_name] = {
					players = players,
					list = list,
					hide = hide
				}
			end

			for index = 1, rank._count do
				player = rank[index]
				commu = online[player]

				if commu then
					if commu == room_commu then
						tbl = list
					else
						tbl = players
					end
				elseif hidden[player] then
					tbl = hide
					commu = true
				end

				if commu then
					tbl._count = tbl._count + 1
					tbl[ tbl._count ] = player
				end
			end
		end

		local offset
		for rank_name, data in next, rank_lists do
			tbl = {_count = data.list._count + data.players._count + data.hide._count}

			for i = 1, data.list._count do
				tbl[i] = data.list[i]
			end

			offset = data.list._count
			for i = 1, data.players._count do
				tbl[i + offset] = data.players[i]
			end

			offset = offset + data.players._count
			for i = 1, data.hide._count do
				tbl[i + offset] = data.hide[i]
			end

			Staff.sorted_members[rank_name] = tbl
		end

		local player
		for index = 1, online_staff.requesters._count do
			player = online_staff.requesters[index]
			closeAllInterfaces(player)
			Staff:show(player)
		end
	end
end)

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == 1 then -- game update
		update_at = tonumber(packet)
	end
end)