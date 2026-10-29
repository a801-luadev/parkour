local loaded_leaderboard = false
do
max_leaderboard_rows = 73
local max_weekleaderboard_rows = 31
local max_roomleaderboard_rows = 99

weeklyfile = {}

local decodeBoard, encodeBoard = LeaderboardRW.decode, LeaderboardRW.encode


-- A board stays in memory between loads. Rows are kept sorted as they're
-- updated, and they're only decoded again when the file's string changes.
--   rows: the rows, and player name -> position (what the interfaces read)
--   ids: playerid -> position
--   raw: the string the rows match (as loaded, or as we saved it)
--   changed: the rows differ from raw
local function newBoard(max_rows)
	return {
		rows = {},
		ids = {},
		total = 0,
		max_rows = max_rows,
	}
end

local overall = newBoard(max_leaderboard_rows)
local coins = newBoard(max_leaderboard_rows)
local weekly = newBoard(max_weekleaderboard_rows)

local function clearBoard(board)
	board.rows, board.ids, board.total = {}, {}, 0
	board.changed = true
end

local function indexBoard(board)
	local rows, ids = board.rows, board.ids
	local row
	for pos = 1, board.total do
		row = rows[pos]
		ids[row[1]] = pos
		rows[row[2]] = pos
	end
end

local function readBoard(board, raw)
	board.changed = false
	if raw == board.raw then return end

	local rows, total = decodeBoard(raw, board.max_rows)
	board.rows, board.ids, board.total = rows, {}, total
	board.raw = raw

	indexBoard(board)
end

local function removeBanned(board)
	local rows, ids, total = board.rows, board.ids, board.total
	local write, row = 0

	for read = 1, total do
		row = rows[read]

		if bans[row[1]] then
			ids[row[1]] = nil
			if rows[row[2]] == read then
				rows[row[2]] = nil
			end
		else
			write = write + 1
			if write ~= read then
				rows[write] = row
				ids[row[1]] = write
				rows[row[2]] = write
			end
		end
	end

	if write == total then return end

	for pos = write + 1, total do
		rows[pos] = nil
	end
	board.total = write
	board.changed = true
end

-- moves a row to a position, shifting the rows in between
local function moveRow(board, row, from, to)
	local rows, ids = board.rows, board.ids
	local shifted

	if from > to then
		for pos = from, to + 1, -1 do
			shifted = rows[pos - 1]
			rows[pos] = shifted
			ids[shifted[1]] = pos
			rows[shifted[2]] = pos
		end
	else
		for pos = from, to - 1 do
			shifted = rows[pos + 1]
			rows[pos] = shifted
			ids[shifted[1]] = pos
			rows[shifted[2]] = pos
		end
	end

	rows[to] = row
	ids[row[1]] = to
	rows[row[2]] = to
end

-- puts a player's score in the board. Rows with the same score keep their
-- order, and a new row goes after the rows with its score.
local function updateBoard(board, name, id, score, community)
	local rows, total = board.rows, board.total
	local pos = board.ids[id]
	local row, to

	if pos then
		row = rows[pos]
		if row[3] == score and row[2] == name and row[4] == community then return end

		if row[2] ~= name then
			if rows[row[2]] == pos then
				rows[row[2]] = nil
			end
			row[2] = name
			rows[name] = pos
		end
		row[3], row[4] = score, community
		board.changed = true

		to = pos
		while to > 1 and score > rows[to - 1][3] do
			to = to - 1
		end
		if to == pos then
			while to < total and score < rows[to + 1][3] do
				to = to + 1
			end
		end

		if to ~= pos then
			moveRow(board, row, pos, to)
		end
		return
	end

	-- can't make the board
	if score <= 0 or (total >= board.max_rows and score <= rows[total][3]) then return end

	total = total + 1
	to = total
	while to > 1 and score > rows[to - 1][3] do
		to = to - 1
	end
	moveRow(board, {id, name, score, community}, total, to)

	if total > board.max_rows then
		row = rows[total]
		board.ids[row[1]] = nil
		if rows[row[2]] == total then
			rows[row[2]] = nil
		end
		rows[total] = nil
		total = total - 1
	end

	board.total = total
	board.changed = true
end

local function writeBoard(board)
	if not board.changed then return end
	board.raw = encodeBoard(board.rows, board.total)
	return board.raw
end

local function resetWeekly(data)
	local ts = os.time() --+ 60 * 60 * 1000
	local file_reset = tonumber(data.weekly.ts) or WEEKLY_RESET_INIT
	local a_day = 24 * 60 * 60 * 1000
	local a_week = 7 * a_day
	local rows = weekly.rows

	local new_reset = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
	if ts - file_reset >= a_week then
		if weekly.total > 2 and rows[1][3] > 30 then
			local unlocks_at = ts + a_day
			data.weekly.wl[tostring(rows[1][1])] = unlocks_at
			data.weekly.wl[tostring(rows[2][1])] = unlocks_at
			data.weekly.wl[tostring(rows[3][1])] = unlocks_at
		end

		if weekly.total > 2 then
			sendPacket(
				"common", 4,
				os.date("%d/%m/%Y", file_reset) .. "\000" .. os.date("%d/%m/%Y", ts - a_day) ..
				"\000" .. rows[1][4] .. "\000" .. rows[1][2] .. "\000" .. rows[1][3] ..
				"\000" .. rows[2][4] .. "\000" .. rows[2][2] .. "\000" .. rows[2][3] ..
				"\000" .. rows[3][4] .. "\000" .. rows[3][2] .. "\000" .. rows[3][3]
			)
		end

		data.weekly.ts = tostring(new_reset)
		clearBoard(weekly)
	end

	if last_weekly_reset_ts ~= new_reset then
		last_weekly_reset_ts = new_reset

		for player, data in next, players_file do
			if data.week[2] ~= new_reset then
				data.week = {0, new_reset}
			end
		end

		tfm.exec.chatMessage("<j>The weekly leaderboard has been reset.")
	end
end

-- gives the position badge, and the weekly podium badge once it unlocks
local function giveBadges(player, file, id, wl, now)
	local pos = overall.ids[id]
	if pos and pos <= 70 then
		local badges = file.badges
		local badge = math.ceil(pos / 14)

		if badges[2] == 0 or badges[2] > badge then
			badges[2] = badge
			NewBadgeInterface:show(player, 2, badge)
			savePlayerData(player)
		end
	end

	if not wl then return end
	id = tostring(id)
	if not wl[id] or now < wl[id] then return end

	if file.badges[3] ~= 1 then
		file.badges[3] = 1
		NewBadgeInterface:show(player, 3, 1)
		savePlayerData(player)
	end
	wl[id] = nil
	return true
end

onEvent("GameDataLoaded", function(data, fileid)
	local ranking, coinranking, weekfile = data.ranking, data.coinranking, data.weekly
	if not (ranking or coinranking or weekfile) then return end

	if ranking then
		if not loaded_leaderboard then
			loaded_leaderboard = true

			translatedChatMessage("leaderboard_loaded")
		end

		readBoard(overall, ranking)
		removeBanned(overall)
	end

	if coinranking then
		readBoard(coins, coinranking)
		removeBanned(coins)
	end

	local wl
	if weekfile then
		weeklyfile = weekfile
		wl = weekfile.wl
		if not wl then
			wl = {}
			weekfile.wl = wl
		end

		readBoard(weekly, weekfile.ranks)
		removeBanned(weekly)
		resetWeekly(data)
	end

	local changed = false
	local now = os.time()
	local file, info, id, community

	for player in next, in_room do
		file = players_file[player]
		info = room.playerList[player]

		if file and info then
			id = info.id

			if not bans[id] then
				community = info.community

				if ranking then
					updateBoard(overall, player, id, file.c, community)
				end
				if coinranking then
					updateBoard(coins, player, id, file.coins, community)
				end
				if weekfile then
					updateBoard(weekly, player, id, file.week[1], community)
				end
			end
		end
	end

	-- positions are final now
	for player in next, in_room do
		file = players_file[player]
		info = room.playerList[player]

		if file and info then
			if giveBadges(player, file, info.id, wl, now) then
				changed = true
			end
		end
	end

	if ranking then
		leaderboard = overall.rows
		data.ranking = writeBoard(overall) or ranking
		changed = changed or overall.changed
	end
	if coinranking then
		coinleaderboard = coins.rows
		data.coinranking = writeBoard(coins) or coinranking
		changed = changed or coins.changed
	end
	if weekfile then
		weekleaderboard = weekly.rows
		weekfile.ranks = writeBoard(weekly) or weekfile.ranks
		-- a reset clears the board, so it counts as a change too
		changed = changed or weekly.changed
	end

	if changed then
		eventSavingFile(fileid, data)
	end
end)

onEvent("LeaderboardUpdate", function(player, time)
	local playerData = room.playerList[player]
	local completedTime = tonumber(time)

	if not playerData or not completedTime then return end

	local rows = roomleaderboard
	local total = #rows

	-- can't make a full board
	if total >= max_roomleaderboard_rows and completedTime >= rows[total][3] then return end

	-- shift slower times down, a new time goes after the equal ones
	local pos = total + 1
	while pos > 1 and completedTime < rows[pos - 1][3] do
		rows[pos] = rows[pos - 1]
		pos = pos - 1
	end

	rows[pos] = {
		playerData.id,
		player,
		completedTime,
		playerData.community
	}

	if total >= max_roomleaderboard_rows then
		rows[total + 1] = nil
	end
end)
end
