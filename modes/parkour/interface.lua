local room = tfm.get.room
local save_update = false
local update_at = 0
local ban_actions = {_count = 0}
local open = {}
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

local function addButton(id, text, action, player, x, y, width, height, disabled)
	id = 2000 + id * 3
	if not disabled then
		text = "<a href='event:" .. action .. "'>" .. text .. "</a>"
	end
	text = "<p align='center'>" .. text .. "</p>"
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

function showMigrationPopup(player)
	addWindow(
		5,
		"<p align='center'><font size='20'><vp><b>" .. translatedMessage("important", player) .. "</b></vp>\n\n" .. translatedMessage("data_migration", player),
		player, 168, 46, 365, 260
	)
	addButton(5, "Close", "close_migration", player, 185, 346, 426, 20, false)
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
		or ranks.admin[player] and 0xD7342A -- admin
		or ranks.manager[player] and 0x843DA4 -- manager
		or ranks.mod[player] and 0xFFAAAA -- moderator
		or ranks.mapper[player] and 0x25C059 -- mapper
		or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
		or 0x148DE6 -- default
	)
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

local function showLeaderboard(player, page)
	if open[player].powers then
		closePowers(player)
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

	addButton(1, "&lt;                       ", "leaderboard_" .. page - 1, player, 185, 346, 210, 20, not (page > 0)                    )
	addButton(2, "&gt;                       ", "leaderboard_" .. page + 1, player, 410, 346, 210, 20, not (page < max_leaderboard_pages))
end

local function showPowers(player, page)
	if open[player].leaderboard then
		closeLeaderboard(player)
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

	addButton(1, "&lt;   ", "power_" .. page - 1, player, 170, 300, 40, 20, not (page > 0)          )
	addButton(2, "&gt;   ", "power_" .. page + 1, player, 590, 300, 40, 20, not powers[page * 3 + 3])
end

local function toggleLeaderboard(player)
	if open[player].leaderboard then
		closeLeaderboard(player)
	else
		showLeaderboard(player, 0)
	end
end

onEvent("TextAreaCallback", function(id, player, callback)
	if callback == "powers" then
		if open[player].powers then
			closePowers(player)
		else
			showPowers(player, 0)
		end
	elseif callback == "leaderboard" then
		if open[player].leaderboard then
			closeLeaderboard(player)
		else
			showLeaderboard(player, 0)
		end
	elseif string.sub(callback, 1, 6) == "power_" then
		showPowers(player, tonumber(string.sub(callback, 7)) or 0)
	elseif string.sub(callback, 1, 12) == "leaderboard_" then
		showLeaderboard(player, tonumber(string.sub(callback, 13)) or 0)
	elseif callback == "migration" then
		tfm.exec.chatMessage("<rose>/room *#drawbattle0migration", player)
	elseif callback == "close_migration" then
		removeButton(5, player)
		removeWindow(5, player)
	end
end)

onEvent("GameDataLoaded", function(data)
	if data.banned then
		local send_saved = {}

		bans = {}
		for player in next, data.banned do
			bans[tonumber(player)] = true
		end

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

			-- TODO: Send a webhok
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

	if save_update then
		data.update = save_update
		save_update = nil
	end

	update_at = data.update or 0
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
	tfm.exec.addImage("16894c35340.png", ":1", 762, 32, player)
	ui.addTextArea(0, "<a href='event:powers'><font size='50'> </font></a>", player, 762, 32, 36, 32, 0, 0, 0, true)

	translatedChatMessage("welcome", player)
	translatedChatMessage("discord", player, discord_link)
	translatedChatMessage("map_submissions", player, map_submissions)

	system.bindKeyboard(player, 76, true, true)

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

	for _player in next, in_room do
		setNameColor(_player)
	end
end)

onEvent("PlayerWon", function(player, taken)
	if generated_at[player] then
		-- If the player joined the room after the map started,
		-- eventPlayerWon's time is wrong.
		taken = (os.time() - generated_at[player]) / 1000
	else
		taken = taken / 100
	end

	translatedChatMessage("finished", nil, player, taken)

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

	elseif cmd == "ban" then
		if not perms[player] or not perms[player].ban then return end

		if pointer < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end

		local affected = capitalize(args[1])
		if not in_room[affected] then
			return translatedChatMessage("user_not_in_room", player, affected)
		end

		ban_actions._count = ban_actions._count + 1
		ban_actions[ban_actions._count] = {"ban", room.playerList[affected].id, player}
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
		translatedChatMessage("action_within_minute", player)

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

	elseif cmd == "update" then
		if not perms[player] or not perms[player].show_update then return end

		save_update = os.time() + 60000 * 3 -- 3 minutes
		translatedChatMessage("action_within_minute", player)
	end
end)

onEvent("Keyboard", function(player, key)
	if key == 76 then
		toggleLeaderboard(player)
	end
end)

onEvent("GameStart", function()
	tfm.exec.disableMinimalistMode(true)
	system.disableChatCommandDisplay("lb", true)
	system.disableChatCommandDisplay("ban", true)
	system.disableChatCommandDisplay("unban", true)
	system.disableChatCommandDisplay("rank", true)
	system.disableChatCommandDisplay("update", true)
end)