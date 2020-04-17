local kill_cooldown = {}
local save_update = false
local update_at = 0
local ban_actions = {_count = 0}
local open = {}
local powers_img = {}
local help_img = {}
local toggle_positions = {
	[1] = 107,
	[2] = 132,
	[3] = 157,
	[4] = 183,
	[5] = 209,
	[6] = 236,
	[7] = 262
}
local community_images = {
	xx = "1651b327097.png",
	ar = "1651b32290a.png",
	bg = "1651b300203.png",
	br = "1651b3019c0.png",
	cn = "1651b3031bf.png",
	cz = "1651b304972.png",
	de = "1651b306152.png",
	ee = "1651b307973.png",
	es = "1651b309222.png",
	fi = "1651b30aa94.png",
	fr = "1651b30c284.png",
	gb = "1651b30da90.png",
	hr = "1651b30f25d.png",
	hu = "1651b310a3b.png",
	id = "1651b3121ec.png",
	il = "1651b3139ed.png",
	it = "1651b3151ac.png",
	jp = "1651b31696a.png",
	lt = "1651b31811c.png",
	lv = "1651b319906.png",
	nl = "1651b31b0dc.png",
	ph = "1651b31c891.png",
	pl = "1651b31e0cf.png",
	ro = "1651b31f950.png",
	ru = "1651b321113.png",
	tr = "1651b3240e8.png",
	vk = "1651b3258b3.png"
}

local function addButton(id, text, action, player, x, y, width, height, disabled, left)
	id = 2000 + id * 3
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
	for i = 2000 + id * 3, 2000 + id * 3 + 2 do
		ui.removeTextArea(i, player)
	end
end

local function addWindow(id, text, player, x, y, width, height)
	if width < 0 or height and height < 0 then
		return
	elseif not height then
		height = width/2
	end
	id = 1000 + id * 8

	ui.addTextArea(id    , ""  , player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
	ui.addTextArea(id + 1, ""  , player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
	ui.addTextArea(id + 2, ""  , player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
	ui.addTextArea(id + 3, ""  , player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 4, ""  , player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 5, ""  , player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 6, ""  , player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
	ui.addTextArea(id + 7, text, player, x+3            , y+3             , width+94    , height+64, 0x1c3a3e, 0x232a35, 1, true)
end

local function removeWindow(id, player)
	for i = 1000 + id * 8, 1000 + id * 8 + 7 do
		ui.removeTextArea(i, player)
	end
end

local function addToggle(id, player, state)
	local x, y = 603, toggle_positions[id]
	local _id = id
	id = 6000 + id * 3

	ui.addTextArea(id, "", player, x, y, 20, 7, 0x232a35, 0x232a35, 1, true)
	if not state then
		ui.addTextArea(id + 1, "", player, x + 3, y + 3, 1, 1, 0x78462b, 0x78462b, 1, true)
	else
		ui.addTextArea(id + 1, "", player, x + 16, y + 3, 1, 1, 0xbeb17d, 0xbeb17d, 1, true)
	end
	ui.addTextArea(id + 2, "<a href='event:toggle:" .. _id .. ":" .. (state and "0" or "1") .. "'>\n\n\n", player, x - 7, y - 7, 30, 20, 1, 1, 0, true)
end

local function removeToggle(id, player)
	for i = 6000 + id * 3, 6000 + id * 3 + 2 do
		ui.removeTextArea(i, player)
	end
end

local function closeLeaderboard(player)
	if not open[player].leaderboard then return end

	removeWindow(1, player)
	removeButton(1, player)
	removeButton(2, player)
	for id = 1, 8 do
		ui.removeTextArea(id, player)
	end

	local images = open[player].images
	for index = 1, images._count do
		tfm.exec.removeImage(images[index])
	end
	images._count = 0

	open[player].leaderboard = false
end

local function closePowers(player)
	if not open[player].powers then return end

	removeWindow(1, player)
	removeButton(1, player)
	removeButton(2, player)
	ui.removeTextArea(1, player)
	ui.removeTextArea(2, player)

	local images = open[player].images
	for index = 1, images._count do
		tfm.exec.removeImage(images[index])
	end
	images._count = 0

	for index = 3000, 2999 + #powers do
		ui.removeTextArea(index, player)
	end

	open[player].powers = false
end

local function removeOptionsMenu(player)
	if not open[player].options then return end

	removeWindow(6, player)
	removeButton(6, player)

	for toggle = 1, 7 do
		removeToggle(toggle, player)
	end

	savePlayerData(player)

	open[player].options = nil
end

local function removeHelpMenu(player)
	if not open[player].help then return end

	removeWindow(7, player)

	ui.removeTextArea(10000, player)

	for button = 7, 11 do
		removeButton(button, player)
	end

	open[player].help = nil
end

local function showOptionsMenu(player)
	if open[player].leaderboard then
		closeLeaderboard(player)
	elseif open[player].powers then
		closePowers(player)
	elseif open[player].help then
		removeHelpMenu(player)
	end
	open[player].options = true

	addWindow(6, translatedMessage("options", player), player, 168, 46, 365, 260)
	addButton(6, "Close", "close_options", player, 185, 346, 426, 20, false)

	addToggle(1, player, players_file[player].parkour.ckpart == 1) -- particles for checkpoints
	addToggle(2, player, players_file[player].parkour.keyboard == 1) -- qwerty keyboard
	addToggle(3, player, players_file[player].parkour.mort == 1) -- M or DEL hotkey
	addToggle(4, player, players_file[player].parkour.pcool == 1) -- power cooldowns
	addToggle(5, player, players_file[player].parkour.pbut == 1) -- powers button
	addToggle(6, player, players_file[player].parkour.hbut == 1) -- help button
	addToggle(7, player, players_file[player].parkour.congrats == 1) -- congratulations message
end

local function showHelpMenu(player, tab)
	if open[player].leaderboard then
		closeLeaderboard(player)
	elseif open[player].powers then
		closePowers(player)
	elseif open[player].options then
		removeOptionsMenu(player)
	end
	open[player].help = true

	addWindow(7, "\n\n\n" .. translatedMessage("help_" .. tab, player) .. "\n\n\n", player, 200, 50, 300, 260)

	ui.addTextArea(10000, "", player, 210, 60, 390, 30, 0x1c3a3e, 0x1c3a3e, 1, true)

	addButton(7, translatedMessage("help", player), "help:help", player, 210, 60, 80, 18, tab == "help")
	addButton(8, translatedMessage("staff", player), "help:staff", player, 310, 60, 80, 18, tab == "staff")
	addButton(9, translatedMessage("rules", player), "help:rules", player, 410, 60, 80, 18, tab == "rules")
	addButton(10, translatedMessage("contribute", player), "help:contribute", player, 510, 60, 80, 18, tab == "contribute")

	addButton(11, "Close", "close_help", player, 210, 352, 380, 18, false)
end

local function capitalize(str)
	local first = string.sub(str, 1, 1)
	if first == "+" then
		return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
	else
		return string.upper(first) .. string.lower(string.sub(str, 2))
	end
end

local function setNameColor(player)
	tfm.exec.setNameColor(
		player,

		victory[player] and 0xFEFF00 -- has won
		or ranks.admin[player] and 0xE7342A -- admin
		or ranks.manager[player] and 0x843DA4 -- manager
		or ranks.mod[player] and 0xFFAAAA -- moderator
		or ranks.mapper[player] and 0x25C059 -- mapper
		or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
		or 0x148DE6 -- default
	)
end

local function showLeaderboard(player, page)
	if open[player].powers then
		closePowers(player)
	elseif open[player].options then
		removeOptionsMenu(player)
	elseif open[player].help then
		removeHelpMenu(player)
	end
	open[player].leaderboard = true

	local images = open[player].images
	for index = 1, images._count do
		tfm.exec.removeImage(images[index])
	end
	images._count = 0

	if not page or page < 0 then
		page = 0
	elseif page > max_leaderboard_pages then
		page = max_leaderboard_pages
	end

	addWindow(
		1,
		string.format(
			"<p align='center'><font size='28'><B><D>%s</D></B></font>\n<font color='#32585E'>%s</font></p>",
			translatedMessage("leaderboard", player),
			string.rep("¯", 50)
		),
		player,
		168, 46, 365, 260
	)
	ui.addTextArea(1, '<V><p align="center">' .. translatedMessage("position", player), player, 180, 100, 50, 20, 1, 1, 0, true)
	ui.addTextArea(2, '<V><p align="center">' .. translatedMessage("username", player), player, 246, 100, 176, 20, 1, 1, 0, true)
	ui.addTextArea(3, '<V><p align="center">' .. translatedMessage("community", player), player, 435, 100, 70, 20, 1, 1, 0, true)
	ui.addTextArea(4, '<V><p align="center">' .. translatedMessage("completed", player), player, 518, 100, 105, 20, 1, 1, 0, true)

	ui.addTextArea(7, "", player, 435, 130, 70, 235, 0x203F43, 0x193E46, 1, true)
	default_leaderboard_user[2] = translatedMessage("unknown", player)
	local positions, names, completed = "", "", ""
	local position, row
	for index = page * 14, page * 14 + 13 do
		position = index + 1
		if position > max_leaderboard_rows then break end
		positions = positions .. "#" .. position .. "\n"
		row = leaderboard[position] or default_leaderboard_user

		if position == 1 then
			names = names .. "<cs>" .. row[2] .. "</cs>\n"
		elseif position == 2 then
			names = names .. "<n>" .. row[2] .. "</n>\n"
		elseif position == 3 then
			names = names .. "<ce>" .. row[2] .. "</ce>\n"
		else
			names = names .. row[2] .. "\n"
		end

		completed = completed .. row[3] .. "\n"

		images._count = images._count + 1
		images[images._count] = tfm.exec.addImage(
			community_images[row[4]] or community_images["xx"],
			"&1",
			460,
			134 + 14 * (index - page * 14),
			player
		)
	end
	ui.addTextArea(5, "<font size='12'><p align='center'><v>" .. positions , player, 183, 130, 50 , 235, 0x203F43, 0x193E46, 1, true)
	ui.addTextArea(6, "<font size='12'><p align='center'><t>" .. names     , player, 246, 130, 176, 235, 0x203F43, 0x193E46, 1, true)
	ui.addTextArea(8, "<font size='12'><p align='center'><vp>" .. completed, player, 518, 130, 100, 235, 0x203F43, 0x193E46, 1, true)

	addButton(1, "&lt;                       ", "leaderboard_p:" .. page - 1, player, 185, 346, 210, 20, not (page > 0)                    )
	addButton(2, "&gt;                       ", "leaderboard_p:" .. page + 1, player, 410, 346, 210, 20, not (page < max_leaderboard_pages))
end

local function showPowers(player, page)
	if not players_file[player] then return end

	if open[player].leaderboard then
		closeLeaderboard(player)
	elseif open[player].options then
		removeOptionsMenu(player)
	elseif open[player].help then
		removeHelpMenu(player)
	end
	open[player].powers = true

	local images = open[player].images
	for index = 1, images._count do
		tfm.exec.removeImage(images[index])
	end
	images._count = 0

	addWindow(1, "<p align='center'><font size='40'><b>" .. translatedMessage("powers", player), player, 150, 76, 400, 200)
	ui.addTextArea(1, "", player, 160, 140, 480, 195, 0x1D464F, 0x193E46, 1, true)

	local completed = players_file[player].parkour.c
	local power, canUse
	for index = page * 3, page * 3 + 2 do
		power = powers[index + 1]
		if power then
			canUse = completed >= power.maps
			ui.addTextArea(
				3000 + index,
				string.format(
					"<p align='center'><b><d>%s\n\n\n\n\n\n\n\n<n>%s",
					power.name and translatedMessage(power.name, player) or "undefined",
					canUse and (
						power.click and
						translatedMessage("click", player) or
						translatedMessage("press", player, player_keys[player][power])
					) or completed .. "/" .. power.maps
				),
				player,
				170 + (index - page * 3) * 160,
				150,
				140,
				125,
				0x1c3a3e,
				0x193e46,
				1,
				true
			)
			images._count = images._count + 1
			images[images._count] = tfm.exec.addImage(
				power.image.url,
				"&1",
				power.image.x + 170 + (index - page * 3) * 160,
				power.image.y + 150,
				player
			)
		else
			ui.removeTextArea(3000 + index, player)
		end
	end

	ui.addTextArea(2, translatedMessage("completed_maps", player, completed), player, 230, 300, 340, 20, 0x1c3a3e, 0x193E46, 1, true)

	addButton(1, "&lt;   ", "power:" .. page - 1, player, 170, 300, 40, 20, not (page > 0)          )
	addButton(2, "&gt;   ", "power:" .. page + 1, player, 590, 300, 40, 20, not powers[page * 3 + 3])
end

local function toggleLeaderboard(player)
	if open[player].leaderboard then
		closeLeaderboard(player)
	else
		showLeaderboard(player, 0)
	end
end

local function showPowersButton(player)
	powers_img[player] = tfm.exec.addImage("17136ef539e.png", ":1", 744, 32, player)
	ui.addTextArea(0, "<a href='event:powers'><font size='50'>  </font></a>", player, 739, 32, 30, 32, 0, 0, 0, true)
end

local function showHelpButton(player, x)
	help_img[player] = tfm.exec.addImage("17136f9eefd.png", ":1", x, 32, player)
	ui.addTextArea(-2, "<a href='event:help_button'><font size='50'>  </font></a>", player, x - 5, 32, 30, 32, 0, 0, 0, true)
end

local function removePowersButton(player)
	tfm.exec.removeImage(powers_img[player])
	ui.removeTextArea(0, player)
end

local function removeHelpButton(player)
	tfm.exec.removeImage(help_img[player])
	ui.removeTextArea(-2, player)
end

onEvent("TextAreaCallback", function(id, player, callback)
	local position = string.find(callback, ":", 1, true)
	local action, args
	if not position then
		action = callback
	else
		action = string.sub(callback, 1, position - 1)
		args = string.sub(callback, position + 1)
	end

	if action == "powers" then
		if open[player].powers then
			closePowers(player)
		else
			showPowers(player, 0)
		end
	elseif action == "help_button" then
		if open[player].help then
			removeHelpMenu(player)
		else
			showHelpMenu(player, "help")
		end
	elseif action == "leaderboard" then
		if open[player].leaderboard then
			closeLeaderboard(player)
		else
			showLeaderboard(player, 0)
		end
	elseif action == "power" then
		showPowers(player, tonumber(args) or 0)
	elseif action == "leaderboard_p" then
		showLeaderboard(player, tonumber(args) or 0)
	elseif action == "settings" then
		if open[player].options then
			removeOptionsMenu(player)
		else
			showOptionsMenu(player)
		end
	elseif action == "close_options" then
		removeOptionsMenu(player)
	elseif action == "close_help" then
		removeHelpMenu(player)
	elseif action == "help" then
		if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" then return end
		showHelpMenu(player, args)
	elseif action == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)
	elseif action == "github" then
		tfm.exec.chatMessage("<rose>" .. links.github, player)
	elseif action == "toggle" then
		local t_id, state = string.match(args, "^(%d+):([01])$")
		if not t_id then return end
		state = state == "1"

		if t_id == "1" then -- particles for checkpoints
			players_file[player].parkour.ckpart = state and 1 or 0
			ck.particles[player] = state

			if state then
				if ck.images[player] then
					tfm.exec.removeImage(ck.images[player])
				end
			else
				addCheckpointImage(player)
			end

		elseif t_id == "2" then -- qwerty keyboard
			players_file[player].parkour.keyboard = state and 1 or 0

			if victory[player] then
				unbind(player)
			end
			player_keys[player] = state and keyPowers.qwerty or keyPowers.azerty
			if victory[player] and not no_powers[player] then
				bindNecessary(player)
			end

		elseif t_id == "3" then -- M or DEL hotkey
			players_file[player].parkour.mort = state and 1 or 0

			if state then
				system.bindKeyboard(player, 77, true, true)
				system.bindKeyboard(player, 46, true, false)
			else
				system.bindKeyboard(player, 77, true, false)
				system.bindKeyboard(player, 46, true, true)
			end
		elseif t_id == "4" then -- power cooldowns
			players_file[player].parkour.pcool = state and 1 or 0

		elseif t_id == "5" then -- powers button
			players_file[player].parkour.pbut = state and 1 or 0

			if state then
				showPowersButton(player)
				if players_file[player].parkour.hbut == 1 then
					removeHelpButton(player)
					showHelpButton(player, 714)
				end
			else
				removePowersButton(player)
				if players_file[player].parkour.hbut == 1 then
					removeHelpButton(player)
					showHelpButton(player, 744)
				end
			end

		elseif t_id == "6" then -- help button
			players_file[player].parkour.hbut = state and 1 or 0

			if state then
				showHelpButton(player, players_file[player].parkour.pbut == 1 and 714 or 744)
			else
				removeHelpButton(player)
			end

		elseif t_id == "7" then -- congratulations message
			players_file[player].parkour.congrats = state and 1 or 0
		end

		addToggle(tonumber(t_id), player, state)
	end
end)

onEvent("GameDataLoaded", function(data)
	if data.banned then
		bans = {}
		for player in next, data.banned do
			bans[tonumber(player)] = true
		end

		if ban_actions._count > 0 then
			local send_saved = {}
			local to_respawn = {}
			local action
			for index = 1, ban_actions._count do
				action = ban_actions[index]

				if not send_saved[action[3]] then
					send_saved[action[3]] = true
					translatedChatMessage("data_saved", action[3])
				end

				if action[1] == "ban" then
					bans[action[2]] = true
					data.banned[tostring(action[2])] = 1 -- 1 so it uses less space
					to_respawn[action[2]] = nil
				else
					bans[action[2]] = nil
					data.banned[tostring(action[2])] = nil
					to_respawn[action[2]] = true
				end

				webhooks._count = webhooks._count + 1
				webhooks[webhooks._count] = "**`[BANS]:`** **" .. action[3] .. "** has " .. action[1] .. "ned a player. (ID: **" .. action[2] .. "**)"
			end
			ban_actions = {_count = 0}

			for id in next, to_respawn do
				for player, data in next, room.playerList do
					if data.id == id then
						tfm.exec.respawnPlayer(player)
					end
				end
			end
		end
	end

	if data.update then
		if save_update then
			data.update = save_update
			save_update = nil
		end

		update_at = data.update or 0
	end
end)

onEvent("PlayerRespawn", setNameColor)

onEvent("NewGame", function()
	for player in next, in_room do
		setNameColor(player)
	end

	if is_tribe then
		translatedChatMessage("tribe_house")
	elseif room.uniquePlayers < min_save then
		translatedChatMessage("min_players", nil, room.uniquePlayers, min_save)
	end
end)

onEvent("NewPlayer", function(player)
	tfm.exec.lowerSyncDelay(player)

	translatedChatMessage("welcome", player)
	translatedChatMessage("discord", player, links.discord)
	translatedChatMessage("map_submissions", player, links.maps)
	translatedChatMessage("type_help", player)

	system.bindKeyboard(player, 76, true, true)
	system.bindKeyboard(player, 79, true, true)
	system.bindKeyboard(player, 72, true, true)
	system.bindKeyboard(player, 80, true, true)

	tfm.exec.addImage("1713705576b.png", ":1", 772, 32, player)
	ui.addTextArea(-1, "<a href='event:settings'><font size='50'>  </font></a>", player, 767, 32, 30, 32, 0, 0, 0, true)

	if levels then
		if is_tribe then
			translatedChatMessage("tribe_house", player)
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
		end
	end

	open[player] = {
		images = {_count = 0}
	}
	kill_cooldown[player] = 0

	for _player in next, in_room do
		setNameColor(_player)
	end
end)

onEvent("PlayerDataParsed", function(player, data)
	system.bindKeyboard(player, data.parkour.mort == 1 and 77 or 46, true, true)
	if data.parkour.pbut == 1 then
		showPowersButton(player)
	end
	if data.parkour.hbut == 1 then
		showHelpButton(player, data.parkour.pbut == 1 and 714 or 744)
	end
end)

onEvent("PlayerWon", function(player)
	if bans[ room.playerList[player].id ] then return end

	-- If the player joined the room after the map started,
	-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
	local taken = (os.time() - (generated_at[player] or map_start)) / 1000

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
	elseif room.uniquePlayers < min_save then
		translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
	else
		local power
		for index = 1, #powers do
			power = powers[index]

			if players_file[player].parkour.c == power.maps then
				translatedChatMessage("unlocked_power", nil, player, power.name)
				break
			end
		end
	end
end)

onEvent("Loop", function()
	local now = os.time()
	if update_at >= now then
		local minutes = math.floor((update_at - now) / 60000)
		local seconds = math.floor((update_at - now) / 1000) % 60
		for player in next, in_room do
			ui.addTextArea(100000, translatedMessage("module_update", player, minutes, seconds), player, 0, 380, 800, 20, 1, 1, 0.7, true)
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

	if cmd == "lb" then
		toggleLeaderboard(player)

	elseif cmd == "donate" then
		tfm.exec.chatMessage("<rose>" .. links.donation, player)

	elseif cmd == "help" then
		showHelpMenu(player, "help")

	elseif cmd == "ban" then
		if not perms[player] or not perms[player].ban then return end

		if pointer < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local id = tonumber(args[1])
		if not id then
			local affected = capitalize(args[1])
			if not in_room[affected] then
				return translatedChatMessage("user_not_in_room", player, affected)
			end

			id = room.playerList[affected].id
		end

		ban_actions._count = ban_actions._count + 1
		ban_actions[ban_actions._count] = {"ban", id, player}
		bans[id] = true
		translatedChatMessage("action_within_minute", player)

	elseif cmd == "unban" then
		if not perms[player] or not perms[player].unban then return end

		if pointer < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local id = tonumber(args[1])
		if (not id) or (not bans[id]) then
			return translatedChatMessage("arg_must_be_id", player)
		end

		ban_actions._count = ban_actions._count + 1
		ban_actions[ban_actions._count] = {"unban", id, player}
		bans[id] = nil
		translatedChatMessage("action_within_minute", player)

	elseif cmd == "kill" then
		if not perms[player] or not perms[player].ban then return end

		if pointer < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local minutes
		if pointer > 1 then
			minutes = tonumber(args[2])

			if not minutes then
				return translatedChatMessage("invalid_syntax", player)
			end
		end

		local affected = capitalize(args[1])
		if not in_room[affected] then
			if not minutes then
				return translatedChatMessage("user_not_in_room", player)
			end

			killing[affected] = {player, minutes}
			return system.loadPlayerData(affected)
		end

		if minutes then
			translatedChatMessage("kill_minutes", affected, minutes)
			players_file[affected].parkour.killed = os.time() + minutes * 60 * 1000
			savePlayerData(affected)
		else
			translatedChatMessage("kill_map", affected)
		end

		webhooks._count = webhooks._count + 1
		webhooks[webhooks._count] = "**`[BANS]:`** `" .. room.name .. "` `" .. player .. "`: `!kill " .. affected .. " " .. minutes .. "`"

		no_powers[affected] = true
		unbind(affected)

	elseif cmd == "review" then
		if not perms[player] or not perms[player].enable_review then return end

		if string.find(room.name, "review") then
			review_mode = true
			return tfm.exec.chatMessage("<v>[#] <d>Review mode enabled.")
		end
		tfm.exec.chatMessage("<v>[#] <r>You can't enable review mode in this room.", player)

	elseif cmd == "cp" then
		if not review_mode then return end

		local checkpoint = tonumber(args[1])
		if not checkpoint then
			return translatedChatMessage("invalid_syntax", player)
		end

		if not levels[checkpoint] then return end

		players_level[player] = checkpoint
		tfm.exec.setPlayerScore(player, checkpoint, false)
		tfm.exec.killPlayer(player)

		if ck.particles[player] == false then
			tfm.exec.removeImage(ck.images[player])
			local next_level = levels[checkpoint + 1]
			if next_level then
				addCheckpointImage(player, next_level.x, next_level.y)
			end
		end

	elseif cmd == "rank" then
		if not perms[player] or not perms[player].set_player_rank then return end

		if pointer < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end
		args[1] = string.lower(args[1])

		if args[1] == "add" or args[1] == "rem" then
			if pointer < 2 then
				return translatedChatMessage("invalid_syntax", player)
			end
			if updater and updater ~= player then
				return translatedChatMessage("cant_update", player)
			end

			local rank_name = string.lower(args[3])
			if not ranks[rank_name] then
				return translatedChatMessage("invalid_rank", player, rank_name)
			end

			if not ranks_update then
				ranks_update = {}
				updater = player
			end

			local affected = capitalize(args[2])
			if not ranks.admin[player] then
				if ranks.admin[affected] or ranks.manager[affected] then
					return translatedChatMessage("cant_edit", player)
				end
			end

			if args[1] == "add" and ranks[rank_name][affected] then
				return translatedChatMessage("has_rank", player, affected, rank_name)
			elseif args[1] == "rem" and not ranks[rank_name][affected] then
				return translatedChatMessage("doesnt_have_rank", player, affected, rank_name)
			end

			if not ranks_update[affected] then
				rank_id = 0
				for rank, id in next, ranks_id do
					if ranks[rank][affected] then
						rank_id = rank_id + id
					end
				end
				ranks_update[affected] = rank_id
			end

			if args[1] == "add" then
				ranks_update[affected] = ranks_update[affected] + ranks_id[rank_name]
			else
				ranks_update[affected] = ranks_update[affected] - ranks_id[rank_name]
			end

			translatedChatMessage("rank_save", player)

		elseif args[1] == "save" then
			saving_ranks = true
			translatedChatMessage("action_within_minute", player)

		elseif args[1] == "list" then
			local msg
			for rank, players in next, ranks do
				msg = "Users with the rank " .. rank .. ":"
				for player in next, players do
					msg = msg .. "\n - " .. player
				end
				tfm.exec.chatMessage(msg, player)
			end

		else
			return translatedChatMessage("invalid_syntax", player)
		end

	elseif cmd == "staff" then
		local texts = {}
		local text, _first
		for player, ranks in next, player_ranks do
			if player ~= "Tocutoeltuco#5522" then
				text = "\n- <v>" .. player .. "</v> ("
				_first = true
				for rank in next, ranks do
					if _first then
						text = text .. rank
						_first = false
					else
						text = text .. ", " .. rank
					end
				end
				texts[player] = text .. ")"
			end
		end

		text = "<v>[#]<n> <d>Parkour staff:</d>"

		for i = 1, #ranks_order do
			for player in next, ranks[ranks_order[i]] do
				if texts[player] then
					text = text .. texts[player]
					texts[player] = nil
				end
			end
		end

		tfm.exec.chatMessage(text, player)

	elseif cmd == "update" then
		if not perms[player] or not perms[player].show_update then return end

		save_update = os.time() + 60000 * 3 -- 3 minutes
		translatedChatMessage("action_within_minute", player)

	elseif cmd == "map" then
		if not perms[player] or not perms[player].change_map then return end

		if pointer > 0 then
			tfm.exec.newGame(args[1])
		else
			newMap()
		end

	elseif cmd == "spec" then
		if not perms[player] or not perms[player].spectate then return end

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

	elseif cmd == "room" then
		if not perms[player] or not perms[player].get_player_room then return end

		if pointer == 0 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local fetching = capitalize(args[1])
		fetching_player_room[fetching] = {player, os.time() + 1000}
		system.loadPlayerData(fetching)

	elseif cmd == "op" then
		showOptionsMenu(player)
	end
end)

onEvent("Keyboard", function(player, key)
	if key == 76 then
		if loaded_leaderboard then
			toggleLeaderboard(player)
		else
			return translatedChatMessage("leaderboard_not_loaded", player)
		end
	elseif key == 77 or key == 46 then
		local now = os.time()
		if now >= (kill_cooldown[player] or os.time()) then
			tfm.exec.killPlayer(player)
			kill_cooldown[player] = now + 1000
		end
	elseif key == 79 then
		if open[player].options then
			removeOptionsMenu(player)
		else
			showOptionsMenu(player)
		end
	elseif key == 72 then
		if open[player].help then
			removeHelpMenu(player)
		else
			showHelpMenu(player, "help")
		end
	elseif key == 80 then
		if open[player].powers then
			closePowers(player)
		else
			showPowers(player, 0)
		end
	end
end)

onEvent("GameStart", function()
	tfm.exec.disableMinimalistMode(true)
	system.disableChatCommandDisplay("lb", true)
	system.disableChatCommandDisplay("ban", true)
	system.disableChatCommandDisplay("unban", true)
	system.disableChatCommandDisplay("kill", true)
	system.disableChatCommandDisplay("rank", true)
	system.disableChatCommandDisplay("update", true)
	system.disableChatCommandDisplay("map", true)
	system.disableChatCommandDisplay("spec", true)
	system.disableChatCommandDisplay("op", true)
	system.disableChatCommandDisplay("donate", true)
	system.disableChatCommandDisplay("help", true)
	system.disableChatCommandDisplay("staff", true)
	system.disableChatCommandDisplay("room", true)
	system.disableChatCommandDisplay("review", true)
	system.disableChatCommandDisplay("cp", true)
end)