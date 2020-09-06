-- Stuff related to the keyboard and game interface (not chat)

local interfaces = {
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
local shown_ranks = {"mod", "mapper", "manager", "admin"}
no_help = {}
local map_polls = {}
local current_poll

-- legacy code (i'm too lazy to remake the help window; i'll do it soon)
local help = {}
local scrolldata = {
	players = {},
	texts = {}
}

local function addButton(id, text, action, player, x, y, width, height, disabled, left)
	id = -2000 + id * 3
	if not disabled then
		text = "<a href='event:" .. action .. "'>" .. text .. "</a>"
	end
	if not left then
		text = "<p align='center'>" .. text .. "</p>"
	end
	local color = disabled and 0x2a424b or 0x314e57

	ui.addTextArea(id    , ""  , player, x-1, y-1, width, height, 0x7a8d93, 0x7a8d93, 1, true)
	ui.addTextArea(id + 1, ""  , player, x+1, y+1, width, height, 0x0e1619, 0x0e1619, 1, true)
	ui.addTextArea(id + 2, text, player, x  , y  , width, height, color   , color   , 1, true)
end

local function removeButton(id, player)
	for i = -2000 + id * 3, -2000 + id * 3 + 2 do
		ui.removeTextArea(i, player)
	end
end

local function scrollWindow(id, player, up, force)
	local data = scrolldata.players[player]
	if not data then return end

	local old = data[2]
	data[2] = up and math.max(data[2] - 1, 1) or math.min(data[2] + 1, data[3])
	if data[2] == old and not force then return end

	ui.addTextArea(-1000 + id * 9 + 8, data[1][data[2]], player, data[4], data[5], data[6], data[7], 0, 0, 0, true)

	if not data.behind_img then
		data.behind_img = tfm.exec.addImage("1719e0e550a.png", "&1", data[8], data[9], player)
	end
	if data.img then
		tfm.exec.removeImage(data.img)
	end
	data.img = tfm.exec.addImage("1719e173ac6.png", "&2", data[8], data[9] + (125 / (data[3] - 1)) * (data[2] - 1), player)
end

local function addWindow(id, text, player, x, y, width, height, isHelp)
	if width < 0 or height and height < 0 then
		return
	elseif not height then
		height = width/2
	end
	local _id = id
	id = -1000 + id * 9

	ui.addTextArea(id    , "", player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
	ui.addTextArea(id + 1, "", player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
	ui.addTextArea(id + 2, "", player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
	ui.addTextArea(id + 3, "", player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 4, "", player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 5, "", player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 6, "", player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)

	if text[1] then -- it is a table
		if scrolldata.players[player] and scrolldata.players[player].img then
			tfm.exec.removeImage(scrolldata.players[player].img)
			tfm.exec.removeImage(scrolldata.players[player].behind_img)
		end
		scrolldata.players[player] = {text, 1, #text, x+3, y+40, width+70, height, x+width+85, y+40, _id}
		ui.addTextArea(id + 7, "", player, x+3, y+3, width+94, height+64, 0x1c3a3e, 0x232a35, 1, true)
		scrollWindow(_id, player, true, true)
	else
		ui.addTextArea(id + 7, (isHelp and "\n\n\n" or "") .. text, player, x+3, y+3, width+94, height+64, 0x1c3a3e, 0x232a35, 1, true)
	end
end

local function removeWindow(id, player)
	if scrolldata.players[player] and scrolldata.players[player].img then
		tfm.exec.removeImage(scrolldata.players[player].img)
		tfm.exec.removeImage(scrolldata.players[player].behind_img)
	end
	scrolldata.players[player] = nil
	for i = -1000 + id * 9, -1000 + id * 9 + 8 do
		ui.removeTextArea(i, player)
	end
end

local function removeHelpMenu(player)
	if not help[player] then return end

	removeWindow(7, player)

	for index = -20002, -20000 do
		ui.removeTextArea(index, player)
	end

	for button = 7, 12 do
		removeButton(button, player)
	end

	help[player] = nil
end

local function showHelpMenu(player, tab)
	help[player] = true

	if scrolldata.players[player] and scrolldata.players[player].img then
		tfm.exec.removeImage(scrolldata.players[player].img)
		tfm.exec.removeImage(scrolldata.players[player].behind_img)
	end
	scrolldata.players[player] = nil

	addWindow(7, scrolldata.texts[player_langs[player].name .. "_help_" .. tab], player, 100, 50, 500, 260, true)

	ui.addTextArea(-20000, "", player, 155, 55, 490, 30, 0x1c3a3e, 0x1c3a3e, 1, true)
	ui.addTextArea(-20001, "", player, 155, 358, 490, 17, 0x1c3a3e, 0x1c3a3e, 1, true)

	addButton(7, translatedMessage("help", player), "help:help", player, 160, 60, 80, 18, tab == "help")
	addButton(8, translatedMessage("staff", player), "help:staff", player, 260, 60, 80, 18, tab == "staff")
	addButton(9, translatedMessage("rules", player), "help:rules", player, 360, 60, 80, 18, tab == "rules")
	addButton(10, translatedMessage("contribute", player), "help:contribute", player, 460, 60, 80, 18, tab == "contribute")
	addButton(11, translatedMessage("changelog", player), "help:changelog", player, 560, 60, 80, 18, tab == "changelog")

	addButton(12, "", "close_help", player, 160, 362, 480, 10, false)
	ui.addTextArea(-20002, "<a href='event:close_help'><p align='center'>Close\n", player, 160, 358, 480, 15, 0, 0, 0, true)
end

onEvent("NewPlayer", function(player)
	bindKeyboard(player, 38, true, true)
	bindKeyboard(player, 40, true, true)
	bindKeyboard(player, 72, true, true)
end)

onEvent("Keyboard", function(player, key)
	if key == 38 or key == 40 then
		if help[player] then
			scrollWindow(7, player, key == 38)
		end

	elseif key == 72 then -- h
		if help[player] then
			removeHelpMenu(player)
		else
			showHelpMenu(player, "help")
		end
	end
end)

onEvent("ParsedChatCommand", function(player, cmd)
	if cmd == "help" then
		showHelpMenu(player, "help")
	end
end)

onEvent("RawTextAreaCallback", function(id, player, callback)
	if callback == "help_button" then
		if help[player] then
			removeHelpMenu(player)
		else
			showHelpMenu(player, "help")
		end

	elseif callback == "close_help" then
		removeHelpMenu(player)
	end
end)

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if action == "help" then
		if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" and args ~= "changelog" then return end
		showHelpMenu(player, args)
	end
end)

onEvent("GameStart", function()
	system.disableChatCommandDisplay("help")

	local help_texts = {"help_help", "help_staff", "help_rules", "help_contribute", "help_changelog"}

	local count, page, newline, key, text
	for name, translation in next, translations do
		for index = 1, #help_texts do
			key = name .. "_" .. help_texts[index]
			text = translation[help_texts[index]]
			count = 0
			scrolldata.texts[key] = {}
			text = "\n" .. text
			for slice = 1, #text, (help_texts[index] == "help_staff" and 700 or 800) + (name == "ru" and 250 or 0) do
				page = string.sub(text, slice)
				newline = string.find(page, "\n")
				if newline then
					page = string.sub(page, newline)
					while string.sub(page, 1, 1) == "\n" do
						page = string.sub(page, 2)
					end
					count = count + 1
					scrolldata.texts[key][count] = page
				else
					break
				end
			end
			if (#text < 1100
				or help_texts[index] == "help_help"
				or help_texts[index] == "help_contribute"
				or help_texts[index] == "help_changelog") then
				scrolldata.texts[key] = string.sub(text, 2)
			end
		end
	end
end)
-- end of legacy code

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
	if players_file[player] and players_file[player].hidden then
		tfm.exec.setNameColor(
			player,

			fastest.player == player and 0xFFFFFF
			or victory[player] and 0xFFFF00
			or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3
			or 0x148DE6
		)
		return
	end

	tfm.exec.setNameColor(
		player,

		fastest.player == player and 0xFFFFFF -- fastest
		or victory[player] and 0xFFFF00 -- has won

		or (ranks.admin[player] or ranks.bot[player]) and 0xE7342A -- admin / bot
		or ranks.manager[player] and 0xD0A9F0 -- manager
		or (ranks.mod[player] and ranks.mapper[player]) and 0x1
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

	elseif key == 77 or key == 46 then
		if not checkCooldown(player, "keyMort", 1000) then return end

		tfm.exec.killPlayer(player)

	elseif key == 70 then
		if not players_file[player] then return end
		if not checkCooldown(player, "keyHelp", 3000) then return end

		local file = players_file[player].parkour

		if file.help == 1 then
			file.help = 0

			if no_help[player] then
				tfm.exec.removeImage(no_help[player])
				no_help[player] = nil
			end
		else
			file.help = 1

			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end

		savePlayerData(player)
	end
end)

onEvent("TextAreaCallback", function(id, player, callback)
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
				showPoll(player)
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

	if current_poll and not current_poll.voters[player] then
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

	for player in next, in_room do
		if players_file[player] and players_file[player].parkour.help == 1 then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end
		setNameColor(player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	bindKeyboard(player, data.parkour.mort == 1 and 77 or 46, true, true)

	if data.parkour.help == 1 then
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
		local commu, players, list
		for _, rank_name in next, shown_ranks do
			rank = ranks[rank_name]
			list = {_count = 0}
			players = {_count = 0}

			for index = 1, rank._count do
				commu = online[rank[index]]
				
				if commu then
					if commu == room_commu then
						list._count = list._count + 1
						list[ list._count ] = rank[index]
					else
						players._count = players._count + 1
						players[ players._count ] = rank[index]
					end
				end
			end

			for index = 1, players._count do
				list[ list._count + index ] = players[index]
			end

			list._count = list._count + players._count
			Staff.sorted_members[rank_name] = list
		end

		local player
		for index = 1, online_staff.requesters._count do
			player = online_staff.requesters[index]
			closeAllInterfaces(player)
			Staff:show(player)
		end
	end
end)

onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 1 then -- game update
		update_at = os.time() + 60000
	end
end)