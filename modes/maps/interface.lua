local mapper_bot = "Tocutoeltuco#5522"

local join_epoch = os.time({year=2020, month=1, day=1, hour=0})
local map_changes = {
	removing = {},
	adding = {}
}
local packets = {
	handshake     = bit32.lshift( 1, 8) + 255,
	list_forum    = bit32.lshift( 2, 8) + 255,
	list_maps     = bit32.lshift( 3, 8) + 255,
	unreads       = bit32.lshift( 4, 8) + 255,
	open_votation = bit32.lshift( 5, 8) + 255,
	new_comment   = bit32.lshift( 6, 8) + 255,
	new_map_vote  = bit32.lshift( 7, 8) + 255,
	delete_msg    = bit32.lshift( 8, 8) + 255,
	restore_msg   = bit32.lshift( 9, 8) + 255,
	change_status = bit32.lshift(10, 8) + 255,
	new_votation  = bit32.lshift(11, 8) + 255,
	perm_map      = bit32.lshift(12, 8) + 255,

	migrate_data  = bit32.lshift(13, 8) + 255, -- This packet is not related to the map system, but is here so we don't use a lot of resources.

	send_webhook  = bit32.lshift(14, 8) + 255, -- This packet is not related to the map system, but is here so we don't use a lot of resources.

	room_crash    = bit32.lshift(15, 8) + 255,

	join_request  = bit32.lshift(16, 8) + 255
}
local last_update
local messages_cache = {}
local system_maps = {_count = 0}
local forum = {ongoing = {}, archived = {}, by_code = {}}
local loaded = {
	data = false,
	system = false
}
local version = {
	lua = "1.1.0-pool",
	bot = nil
}
local changing_perm = {}
local menu_part = {}
local decoder = {
	["&0"] = "&",
	["&1"] = ","
}
local join_requests = {_count = 0}
local room = room

function send_bot_room_crash()
	for index = 1, webhooks._count do
		ui.addTextArea(packets.send_webhook, webhooks[index], mapper_bot)
	end
	ui.addTextArea(packets.room_crash, "", mapper_bot)
end

local function decodePacketString(str)
	return string.gsub(str, "&[01]", decoder)
end

local function setPagination(player, page)
	ui.addTextArea(14, "<a href='event:maps_page:1'>&lt;&lt;</a>", player, 15, 363, 25, 19, 1, 0, 1, true)
	ui.addTextArea(15, "<a href='event:maps_page:" .. math.max(page - 1, 1) .. "'>&lt;</a>", player, 50, 363, 15, 19, 1, 0, 1, true)
	ui.addTextArea(16, "<p align='center'>" .. page, player, 80, 363, 50, 19, 1, 0, 1, true)
	ui.addTextArea(17, "<a href='event:maps_page:" .. (page + 1) .. "'>&gt;</a>", player, 145, 363, 15, 19, 1, 0, 1, true)
	ui.addTextArea(18, "<a href='event:maps_page:0'>&gt;&gt;</a>", player, 175, 363, 25, 19, 1, 0, 1, true)
end

local function updatePagination(player, page)
	ui.updateTextArea(15, "<a href='event:maps_page:" .. math.max(page - 1, 1) .. "'>&lt;</a>", player)
	ui.updateTextArea(16, "<p align='center'>" .. page, player)
	ui.updateTextArea(17, "<a href='event:maps_page:" .. (page + 1) .. "'>&gt;</a>", player)
end

local function formatComment(comment, can_delete, player)
	local actions, msg

	if comment.deleted then
		msg = translatedMessage("deleted_by", player, comment.deleted_by)
		actions = translatedMessage("see_restore", player, "sm:" .. comment.id, "rm:" .. comment.id) -- restore_msg
	else
		msg = "<n>" .. comment.msg
		if can_delete then
			actions = translatedMessage("delete", player, "dm:" .. comment.id)
		end
	end

	return (
			"<j>" .. comment.author .. " " ..
			(can_delete and actions or "") ..
			msg
	)
end

local function closeSection(player)
	if not menu_part[player] then return end

	for id = 20, 19 + 2 * (menu_part[player] == 1 and 16 or 5) do
		ui.removeTextArea(id, player)
	end
end

local function closeMapsMenu(player)
	part = menu_part[player]
	if part then
		if part == 1 or part == 2 or part == 3 then
			ui.addTextArea(10, "<a href='event:maps_menu:" .. part .. "'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
		else
			ui.addTextArea(10, "<a href='event:0_view:" .. part .. "'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
		end
	else
		ui.addTextArea(10, "<a href='event:maps_menu:1'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
	end

	for id = 11, 19 do
		ui.removeTextArea(id, player)
	end

	closeSection(player)

	menu_part[player] = nil
end

local function openVotation(player, code, page)
	local votation = forum.by_code[code]

	closeSection(player)

	if not votation then
		if (not perms[player]) or not perms[player].vote_map then
			return translatedChatMessage("cant_open_votation", player, code)
		end

		return ui.addTextArea(packets.new_votation, player .. "," .. code, mapper_bot)
	end

	local can_delete = (perms[player] and perms[player].delete_comments) and "1" or "0"
	ui.addTextArea(
		packets.open_votation,
		player .. "," .. (page * 12 - 12) .. "," .. can_delete .. "," .. room.playerList[player].id .. "," .. code .. "," .. votation.comments_quantity,
		mapper_bot
	)

	menu_part[player] = code
end

local function _openVotation(player, code, page, comments, can_delete, vote)
	page = page / 12

	local votation = forum.by_code[code]

	for index = 14, 18 do
		ui.removeTextArea(index, player) -- remove pagination
	end

	ui.addTextArea(
		20,
		translatedMessage(
			"map_info", player,
			code, votation.map.author,
			translatedMessage(votation.map.permed and "permed" or "not_permed", player),
			translatedMessage(votation.archived and "archived" or "not_archived", player),
			math.floor(votation.votes / ranks.mapper._count * 100)
		),
		player, 15, 65, 770, 20, 1, 0, 1, true
	)

	ui.addTextArea(
		21,
		(perms[player] and perms[player].vote_map) and
		translatedMessage(
			"map_actions_staff", player,
			"c_page:" .. code .. "," .. math.max(page, 1), page + 1, "c_page:" .. code .. "," .. page + 2,
			"comment:" .. code,
			vote and (
				(vote == "1" and "<vp>+</vp> " or "<r>-</r> ") .. translatedMessage("delete", player, "delete_vote:" .. code)
			) or (
				"<a href='event:downvote:" .. code .. "'><r>[-]</r></a> <a href='event:upvote:" .. code .. "'><vp>[+]</vp></a>"
			),
			votation.archived and "dearchive:" .. code or "archive:" .. code,
			translatedMessage(votation.archived and "dearchive" or "archive", player),
			votation.map.permed and "deperm:" .. code or "perm:" .. code,
			translatedMessage(votation.map.permed and "deperm" or "perm", player),
			"load_map:" .. code
		) or
		translatedMessage(
			"map_actions_user", player,
			"c_page:" .. code .. "," .. math.max(page, 1), page + 1, "c_page:" .. code .. "," .. page + 2,
			"comment:" .. code
		),
		player, 15, 361, 770, 20, 1, 0, 1, true
	)

	local text
	local comment = comments[1]

	if comment then
		text = formatComment(comment, can_delete, player)

		for index = 2, #comments do
			comment = comments[index]

			text = text .. "\n" .. formatComment(comment, can_delete, player)
		end
	else
		text = translatedMessage("no_comments", player)
	end

	ui.addTextArea(22, text, player, 15, 100, 770, 245, 0x324650, 0, 1, true)
end

local function openPermedMapsMenu(player, page)
	local last_page = math.ceil(system_maps._count / 16)
	if not page then
		page = last_page - 1
	else
		page = math.max(math.min(page, last_page), 1) - 1
	end

	local open = translatedMessage("open", player)

	local txt = 20
	local offset = 0
	local left = true
	local map
	for index = page * 16 + 1, page * 16 + 16 do
		map = system_maps[index]
		if not map then break end
		if left then
			offset = offset + 1
		end
		ui.addTextArea(txt, (left and "<j>" or "<p align='right'><j>") .. map.author .. " <bl>- @" .. map.code, player, left and 20 or 540, 35 + offset * 35, 240, 20, 0x324650, 0, 1, true)
		ui.addTextArea(txt + 1, "<a href='event:view:" .. map.code .. "'>" .. open .. "</a>", player, left and 240 or 510, 35 + offset * 35, 50, 20, 1, 0, 1, true)
		left = not left
		txt = txt + 2
	end

	local pagination_fnc = type(menu_part[player]) == "number" and updatePagination or setPagination
	pagination_fnc(player, page + 1)
end

local function openVotationsMenu(player, page, archived)
	local list = archived and forum.archived or forum.ongoing

	local last_page = math.ceil(#list / 5)
	if not page then
		page = last_page - 1
	else
		page = math.max(math.min(page, last_page), 1) - 1
	end

	ui.addTextArea(
		packets.unreads,
		room.playerList[player].id .. "," .. player .. "," .. (page * 5) .. ",5," .. (archived and "1" or "0"),
		mapper_bot
	)

	local pagination_fnc = type(menu_part[player]) == "number" and updatePagination or setPagination
	pagination_fnc(player, page + 1)
end

local function _openVotationsMenu(player, page, archived, votations, unreads)
	if not archived then
		ui.addTextArea(19, translatedMessage("load_from_thread", player), player, 550, 363, 237, 19, 1, 0, 1, true)
		archived = ""
	else
		archived = "<bl>(" .. translatedMessage("archived", player) .. ")"
	end

	local permed = translatedMessage("permed", player)
	local not_permed = translatedMessage("not_permed", player)
	local open = translatedMessage("open", player)

	local votation
	for index = 1, #votations do
		votation = votations[index]

		ui.addTextArea(
			18 + index * 2,
			translatedMessage(
				"conversation_info", player,
				votation.map.author, votation.map.code,
				votation.map.permed and permed or not_permed,
				translatedMessage("points", player, math.floor(votation.votes / ranks.mapper._count * 100)),
				archived,
				votation.started == " " and "Unknown" or votation.started,
				votation.last_comment == " " and "Unknown" or votation.last_comment,
				votation.comments_quantity, votation.comments_quantity - unreads[votation.map.code]
			), player,
			20, 20 + index * 50, 765, 35, 0x324650, 0, 1, true
		)
		ui.addTextArea(19 + index * 2, "<a href='event:view:" .. votation.map.code .. "'>" .. open .. "</a>", player, 740, 25 + index * 50, 35, 20, 1, 0, 1, true)
	end
end

local function openMapsMenu(player, where)
	if not where then return end

	ui.removeTextArea(10, player)

	local permed_open, permed_close, ongoing_open, ongoing_close, archived_open, archived_close
	if where == 1 then permed_open, permed_close = "b", "b"
	elseif where == 2 or where == 0 then ongoing_open, ongoing_close = "b", "b"
	else archived_open, archived_close = "b", "b"
	end
	if not permed_open then permed_open, permed_close = "a href='event:maps_menu:1'", "a" end
	if not ongoing_open then ongoing_open, ongoing_close = "a href='event:maps_menu:2'", "a" end
	if not archived_open then archived_open, archived_close = "a href='event:maps_menu:3'", "a" end

	ui.addTextArea(11, "", player, 10, 30, 780, 355, 0x324650, 0, 1, true)
	ui.addTextArea(
		13, string.format(
			"<p align='center'><%s>%s</%s> | <%s>%s</%s> | <%s>%s</%s></p>",
			permed_open, translatedMessage("permed_maps", player), permed_close,
			ongoing_open, translatedMessage("ongoing_votations", player), ongoing_close,
			archived_open, translatedMessage("archived_votations", player), archived_close
		), player, 10, 30, 780, 20, 1, 0, 1, true
	)
	ui.addTextArea(12, "<p align='center'><a href='event:close_maps'><b>X</b></a></p>", player, 770, 30, 20, 20, 0xaa0000, 0, 1, true)

	if menu_part[player] then
		closeSection(player)
	end

	setPagination(player, 1)

	if where == 1 then
		openPermedMapsMenu(player, 1)
	elseif where == 2 then
		openVotationsMenu(player, 1, false)
	elseif where == 3 then
		openVotationsMenu(player, 1, true)
	end

	menu_part[player] = where
end

onEvent("GameDataLoaded", function(data)
	if not loaded.data then
		loaded.data = true

		if room.playerList[mapper_bot] then
			eventNewPlayer(mapper_bot)
		else
			translatedChatMessage("missing_bot", nil, links.discord)
		end
	end

	if data.maps then
		local countA, countB = #data.maps, #map_changes.removing
		for index = countA, 1, -1 do
			for _index = 1, countB do
				if map_changes.removing[_index] == data.maps[index] then
					table.remove(map_changes.removing, _index)
					table.remove(data.maps, index)
					countB = countB - 1
					countA = countA - 1
					break
				end
			end
		end

		for index = 1, #map_changes.adding do
			countA = countA + 1
			data.maps[countA] = map_changes.adding[index]
		end

		map_changes.removing = {}
		map_changes.adding = {}

		for code, status in next, changing_perm do
			if status == "" then
				changing_perm[code] = false
			end
		end
	end
end)

onEvent("GameDataLoaded", function(data)
	if loaded.system then
		if data.webhooks then
			for index = 2, #data.webhooks do
				ui.addTextArea(packets.send_webhook, data.webhooks[index], mapper_bot)
			end

			data.webhooks = {math.floor(os.time()) + 300000}
		end

	end
	if data.update then
		if last_update and data.update > last_update then
			ui.addTextArea(packets.send_webhook, "**[UPDATE]** The module is gonna be updated soon.", mapper_bot)
		end
		last_update = data.update
	end
end)

onEvent("NewPlayer", function(player)
	if not loaded.data then return end

	if player == mapper_bot and not loaded.system then
		ui.addTextArea(packets.handshake, version.lua, mapper_bot)
		version.bot = nil
	end

	if version.bot and not loaded.system then
		translatedChatMessage("version_mismatch", player, version.bot, version.lua)
	end

	if not loaded.system then return end

	if player == mapper_bot then
		translatedChatMessage("mapper_joined", nil, player, "bot")
	elseif perms[player] then
		local player_ranks = ""

		for rank, players in next, ranks do
			if players[player] then
				if player_ranks ~= "" then
					player_ranks = player_ranks .. ", "
				end
				player_ranks = player_ranks .. "parkour-" .. rank
			end
		end

		translatedChatMessage("mapper_joined", nil, player, player_ranks)
	end

	ui.addTextArea(10, "<a href='event:maps_menu:1'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
end)

onEvent("PlayerLeft", function(player)
	if not loaded.system then return end

	if player == mapper_bot then
		translatedChatMessage("mapper_left", nil, player, "bot")
		loaded.system = false
		version.bot = nil
		for affected in next, menu_part do
			closeMapsMenu(affected)
			menu_part[affected] = 1
		end
		ui.removeTextArea(10)
		menu_part = {}

	elseif perms[player] then
		local player_ranks = ""

		for rank, players in next, ranks do
			if players[player] then
				if player_ranks ~= "" then
					player_ranks = player_ranks .. ", "
				end
				player_ranks = player_ranks .. "parkour-" .. rank
			end
		end

		translatedChatMessage("mapper_left", nil, player, player_ranks)
	end
end)

onEvent("TextAreaCallback", function(id, player, cb)
	if player == mapper_bot or not loaded.system then return end

	local position = string.find(cb, ":", 1, true)
	local action, args
	if not position then
		action = cb
	else
		action = string.sub(cb, 1, position - 1)
		args = string.sub(cb, position + 1)
	end

	if action == "maps_menu" then
		local where = tonumber(args)
		if (not where) or where < 1 or where > 3 then return end -- just a bot trying to break the module

		openMapsMenu(player, where)

	elseif action == "close_maps" then
		closeMapsMenu(player)

	elseif action == "view" or action == "0_view" then
		if not args then return end -- just a bot trying to break the module

		if action == "0_view" then
			openMapsMenu(player, 0)
		end

		openVotation(player, args, 1)

	elseif action == "maps_page" then
		local page = tonumber(args)
		if (not args) or (not menu_part[player]) or page < 0 then return end -- just a bot trying to break the module

		if menu_part[player] == 1 then
			openPermedMapsMenu(player, page)
		elseif menu_part[player] == 2 then
			openVotationsMenu(player, page, false)
		elseif menu_part[player] == 3 then
			openVotationsMenu(player, page, true)
		else
			--openVotation(player, menu_part[player], page)
		end

	elseif action == "c_page" then
		local map, page = string.match(args, "^(%d+),(%d+)$")
		if not map or not page or not forum.by_code[map] then return end

		openVotation(player, map, tonumber(page))

	elseif action == "comment" then
		local map = tonumber(args)
		if not map or not forum.by_code[args] then return end

		ui.addPopup(map, 2, translatedMessage("write_comment", player), player, 190, 190, 420, true)

	elseif action == "upvote" or action == "downvote" or action == "delete_vote" then
		local map = tonumber(args)
		if not perms[player] or not perms[player].vote_map or not map or not forum.by_code[args] then return end -- just a bot trying to break the module

		local vote = action == "upvote" and "1" or (action == "downvote" and "0" or " ")
		ui.addTextArea(packets.new_map_vote, room.playerList[player].id .. "," .. map .. "," .. vote, mapper_bot)
		openVotation(player, args, 1)

	elseif action == "archive" or action == "dearchive" then
		local map = tonumber(args)
		local votation = forum.by_code[args]
		if not perms[player] or not perms[player].vote_map or not map or not votation then return end -- just a bot trying to break the module

		if votation.archived and action == "archive" then return
		elseif not votation.archived and action == "dearchive" then return end

		if action == "archive" then
			if votation.archived then return end
			ui.addTextArea(packets.change_status, map .. ",1", mapper_bot)

			for index, vot in next, forum.ongoing do
				if vot == votation then
					table.remove(forum.ongoing, index)
					break
				end
			end

			forum.archived[#forum.archived + 1] = votation
			votation.archived = true

		elseif action == "dearchive" then
			if not votation.archived then return end
			ui.addTextArea(packets.change_status, map .. ",0", mapper_bot)

			for index, vot in next, forum.archived do
				if vot == votation then
					table.remove(forum.archived, index)
					break
				end
			end

			forum.ongoing[#forum.ongoing + 1] = votation
			votation.archived = false
		end

		openVotation(player, args, 1)

	elseif action == "perm" then
		local map = tonumber(args)
		local votation = forum.by_code[args]
		if not perms[player] or not map or not votation then return end -- just a bot trying to break the module
		if not perms[player].perm_map then
			return translatedChatMessage("not_enough_permissions", player)
		end
		if votation.map.permed then
			return translatedChatMessage("already_permed", player)
		end
		if changing_perm[args] then
			return translatedChatMessage("cant_perm_right_now", player)
		end
		changing_perm[args] = true

		ui.addTextArea(packets.perm_map, player .. "," .. args .. ",1", mapper_bot)
		translatedChatMessage("starting_perm_change", player)

	elseif action == "deperm" then
		local map = tonumber(args)
		local votation = forum.by_code[args]
		if not perms[player] or not map or not votation then return end -- just a bot trying to break the module
		if not perms[player].perm_map then
			return translatedChatMessage("not_enough_permissions", player)
		end
		if not votation.map.permed then
			return translatedChatMessage("already_depermed", player)
		end
		if changing_perm[args] then
			return translatedChatMessage("cant_perm_right_now", player)
		end
		changing_perm[args] = true

		ui.addTextArea(packets.perm_map, player .. "," .. args .. ",0", mapper_bot)
		translatedChatMessage("starting_perm_change", player)

	elseif action == "dm" then -- delete_msg
		local msg = tonumber(args)
		if not perms[player] or not perms[player].delete_comments or not msg then return end -- just a bot trying to break the module

		ui.addTextArea(packets.delete_msg, room.playerList[player].id .. "," .. msg, mapper_bot)
		openVotation(player, menu_part[player], 1)

	elseif action == "sm" then -- see_msg
		local msg = tonumber(args)
		if not perms[player] or not perms[player].delete_comments or not msg or not messages_cache[msg] then return end -- just a bot trying to break the module

		tfm.exec.chatMessage("<vp>\n" .. messages_cache[msg].msg, player)

	elseif action == "rm" then -- restore_msg
		local msg = tonumber(args)
		if not perms[player] or not perms[player].delete_comments or not msg or not messages_cache[msg] then return end -- just a bot trying to break the module

		ui.addTextArea(packets.restore_msg, msg, mapper_bot)
		openVotation(player, menu_part[player], 1)

	elseif action == "load_map" then
		local map = tonumber(args)
		if not perms[player] or not perms[player].vote_map or not map then return end -- just a bot trying to break the module

		translatedChatMessage("mapper_loaded", nil, player)
		tfm.exec.newGame(map)

	elseif action == "load_custom" then
		if not perms[player] or not perms[player].vote_map then return end

		ui.addPopup(0, 2, translatedMessage("write_map", player), player, 190, 190, 420, true)
	end
end)

onEvent("TextAreaCallback", function(id, player, cb)
	if player ~= mapper_bot then return end

	if id == packets.handshake then
		if cb == "ok" then
			loaded.system = true
			changing_perm = {}

			translatedChatMessage("mapping_loaded", nil, version.lua)
			for player in next, in_room do
				eventNewPlayer(player)
			end
		elseif string.sub(cb, 1, 7) == "not ok;" then
			version.bot = string.sub(cb, 8)

			for player in next, in_room do
				if player ~= mapper_bot then
					eventNewPlayer(player)
				end
			end
		end

	elseif loaded.system then
		if id == packets.list_forum then
			forum = {ongoing = {}, archived = {}, by_code = {}}
			local ongoing_count, archived_count = 0, 0
			local votation, stored_perm, stored_archive
			for slice in string.gmatch(cb, "[^,]+") do
				if not votation then
					votation = {
						map = {
							author = slice
						}
					}
				elseif not votation.map.code then
					votation.map.code = slice
				elseif not stored_perm then
					stored_perm = true
					votation.map.permed = slice == "1"
				elseif not votation.votes then
					votation.votes = tonumber(slice)
				elseif not stored_archive then
					stored_archive = true
					votation.archived = slice == "1"
				elseif not votation.started then
					votation.started = slice
				elseif not votation.last_comment then
					votation.last_comment = slice
				else
					votation.comments_quantity = tonumber(slice)

					if not votation.archived then
						ongoing_count = ongoing_count + 1
						forum.ongoing[ongoing_count] = votation
					else
						archived_count = archived_count + 1
						forum.archived[archived_count] = votation
					end
					forum.by_code[votation.map.code] = votation

					votation = nil
					stored_perm = false
					stored_archive = false
				end
			end

		elseif id == packets.list_maps then
			system_maps = {}
			local count = 0
			local author
			for slice in string.gmatch(cb, "[^,]+") do
				if not author then
					author = slice
				else
					count = count + 1
					system_maps[count] = {
						author = author,
						code = slice
					}
					author = nil
				end
			end

			system_maps._count = count

		elseif id == packets.unreads then
			local unreads, votations, count = {}, {}, 0
			local id, affected, page, archived, map
			for slice in string.gmatch(cb, "[^,]+") do
				if not id then
					id = tonumber(slice)
				elseif not affected then
					affected = slice
				elseif not page then
					page = tonumber(slice)
				elseif not archived then
					archived = slice
				elseif not map then
					map = slice
				else
					unreads[map] = tonumber(slice)
					map = nil
				end
			end

			for map, unread in next, unreads do
				count = count + 1
				votations[count] = forum.by_code[map]
			end

			_openVotationsMenu(affected, page, archived == "1", votations, unreads)

		elseif id == packets.open_votation then
			local messages, count, msg = {}, 0
			local user, code, page, can_delete, msg_id, msg_author, deleted_by, vote, votes
			for slice in string.gmatch(cb, "[^,]+") do
				if not user then
					user = slice
				elseif not code then
					code = slice
				elseif not page then
					page = tonumber(slice)
				elseif not can_delete then
					can_delete = slice
				elseif not vote then
					vote = slice
				elseif not votes then
					votes = tonumber(slice)
				elseif not msg_id then
					msg_id = slice
				elseif not msg_author then
					msg_author = slice
				elseif not deleted_by then
					deleted_by = slice
				else
					msg = {
						id = msg_id,
						author = msg_author,
						msg = decodePacketString(slice),
						deleted = deleted_by ~= " ",
						deleted_by = deleted_by
					}
					count = count + 1
					messages[count] = msg

					if msg.deleted then
						messages_cache[tonumber(msg_id)] = msg
					end

					msg_id = nil
					msg_author = nil
					deleted_by = nil
				end
			end

			forum.by_code[code].votes = votes

			if vote == " " then
				vote = nil
			end
			_openVotation(user, code, page, messages, can_delete == "1", vote)

		elseif id == packets.new_votation then
			local player, result, code, author, permed = string.match(cb, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")

			if result == "0" then
				local votation = {
					map = {
						author = author,
						code = code,
						permed = permed == "1"
					},
					votes = 0,
					archived = false,
					started = " ",
					last_comment = " ",
					comments_quantity = 0
				}
				forum.ongoing[#forum.ongoing + 1] = votation
				forum.by_code[code] = votation
				openVotation(player, code, 1)
			elseif result == "1" then
				translatedChatMessage("map_does_not_exist", player)
			elseif result == "2" then
				translatedChatMessage("invalid_map_perm", player)
			elseif result == "3" then
				translatedChatMessage("cant_use_this_map", player)
			elseif result == "4" then
				translatedChatMessage("invalid_map_p41", player)
			end

		elseif id == packets.perm_map then
			local player, perm, result, can_perm, code, author = string.match(cb, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")

			if can_perm == "1" then
				changing_perm[code] = "" -- so it is not changed until the next save
			end

			if result == "0" then
				forum.by_code[code].map.permed = perm == "1"

				local from, to
				if perm == "1" then
					from, to = "22", "41"
					system_maps._count = system_maps._count + 1
					system_maps[system_maps._count] = {
						author = author,
						code = code
					}
					map_changes.adding[#map_changes.adding + 1] = tonumber(code)
				else
					from, to = "41", "22"
					for index = 1, system_maps._count do
						if system_maps[index].code == code then
							table.remove(system_maps, index)
							system_maps._count = system_maps._count - 1
							break
						end
					end
					map_changes.removing[#map_changes.removing + 1] = tonumber(code)
				end

				translatedChatMessage("perm_changed", player, code, from, to)
				openVotation(player, code, 1)
			elseif result == "1" then
				translatedChatMessage("map_does_not_exist", player)
			elseif result == "2" then
				translatedChatMessage("invalid_map_perm_specific", player, perm == "1" and "22" or "41")
			elseif result == "3" then
				translatedChatMessage("cant_use_this_map", player)
			elseif result == "4" then
				translatedChatMessage("invalid_map_p41", player)
			elseif result == "5" then
				translatedChatMessage("invalid_map_p22", player)
			elseif result == "6" then
				translatedChatMessage("got_map_info", player)
			elseif result == "7" then
				translatedChatMessage("cant_perm_right_now", player)
			end

		elseif id == packets.migrate_data then
			local player, data = string.match(cb, "^([^,]+),(.*)$")
			system.savePlayerData(player, data)
			ui.addTextArea(packets.migrate_data, player, mapper_bot)

		elseif id == packets.join_request then
			join_requests._count = join_requests._count + 1
			join_requests[join_requests._count] = cb
		end
	end
end)

onEvent("PopupAnswer", function(id, player, answer)
	if not loaded.system then return end

	if id == 0 then -- create new votation
		if not perms[player] or not perms[player].vote_map then return end

		local map = string.match(answer, "^@(%d+)$")
		if not map then
			return translatedChatMessage("invalid_map", player)
		end

		if forum.by_code[map] then
			openVotation(player, map, 1)
			return translatedChatMessage("map_already_voting", player)
		end

		return ui.addTextArea(packets.new_votation, player .. "," .. map, mapper_bot)
	end

	local code = tostring(id)
	local votation = forum.by_code[code]
	if not votation then return end

	local length = #answer
	if length < 10 or length > 100 then
		return translatedChatMessage("invalid_length", player, length)
	end

	votation.comments_quantity = votation.comments_quantity + 1
	votation.last_comment = player
	if votation.started == " " then
		votation.started = player
	end

	ui.addTextArea(packets.new_comment, id .. "," .. room.playerList[player].id .. "," .. answer, mapper_bot)
	openVotation(player, code, 1)
end)

onEvent("JoinSystemDataLoaded", function(bot, data)
	local now = os.time() - join_epoch
	for idx = 1, join_requests._count do
		data[join_requests[idx]] = {false, now + 45000}
	end
	if join_requests._count > 0 then
		join_requests._count = 0
		ui.addTextArea(packets.join_request, "requested", mapper_bot)
	end

	local recv = ""
	for room_name, expire in next, data do
		if expire[1] then
			recv = recv .. "\001" .. room_name .. "\002" .. (expire[2] + join_epoch) .. "\002" .. expire[3]
			join_to_delete._count = join_to_delete._count + 1
			join_to_delete[join_to_delete._count] = room_name
		end
	end
	if recv ~= "" then
		ui.addTextArea(packets.join_requests, "received" .. recv, mapper_bot)
	end

	for idx = 1, join_to_delete._count do
		data[join_to_delete[idx]] = nil
	end

	system.savePlayerData(bot, json.encode(data))
end)