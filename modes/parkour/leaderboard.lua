local loaded_leaderboard = false
do
max_leaderboard_rows = 73
local max_weekleaderboard_rows = 31
-- {id, name, completed_maps, community}
weeklyfile = {}
local default_leaderboard_user = {0, nil, 0, "xx"}

local function leaderboardSort(a, b)
	return a[3] > b[3]
end

local function roomLeaderboardSort(a, b)
	return a[3] < b[3]
end

local remove, sort = table.remove, table.sort

local function checkPlayersPosition(lb, max_lb_rows)
	local totalRankedPlayers = #lb or 0
	local cachedPlayers = {}

	local playerId, position

	local toRemove, counterRemoved = {}, 0
	for player = 1, totalRankedPlayers do
		position = lb[player]
		playerId = position[1]

		if bans[playerId] then
			counterRemoved = counterRemoved + 1
			toRemove[counterRemoved] = player
		else
			cachedPlayers[playerId] = position
		end
	end

	for index = counterRemoved, 1, -1 do
		remove(lb, toRemove[index])
	end
	toRemove = nil

	totalRankedPlayers = totalRankedPlayers - counterRemoved

	local cacheData
	local playerFile, playerData, completedMaps, name

	for player in next, in_room do
		playerFile = players_file[player]

		if playerFile then
			if lb == leaderboard then
				completedMaps = playerFile.c
			elseif lb == weekleaderboard then
				completedMaps = playerFile.week[1]
			elseif lb == coinleaderboard then
				completedMaps = playerFile.coins
			end
			playerData = room.playerList[player]
			if playerData then
				playerId = playerData.id

				if not bans[playerId] then
					cacheData = cachedPlayers[playerId]
					name = player
					if cacheData then
						cacheData[2] = name
						cacheData[3] = completedMaps
						cacheData[4] = playerData.community
					else
						totalRankedPlayers = totalRankedPlayers + 1
						lb[totalRankedPlayers] = {
							playerId,
							name,
							completedMaps,
							playerData.community
						}
					end
				end
			end
		end
	end

	sort(lb, leaderboardSort)

	for index = max_lb_rows + 1, totalRankedPlayers do
		lb[index] = nil
	end

	if lb == leaderboard then
		local name, badges, badge
		for pos = 1, #lb do
			name = lb[pos][2]
			lb[name] = pos

			if pos <= 70 and players_file[name] then
				badges = players_file[name].badges
				badge = math.ceil(pos / 14)

				if badges[2] == 0 or badges[2] > badge then
					badges[2] = badge
					NewBadgeInterface:show(name, 2, badge)
					savePlayerData(name)
				end
			end
		end
	else
		for index = 1, #lb do
			lb[lb[index][2]] = index
		end
	end
end

onEvent("GameDataLoaded", function(data)
	if data.ranking then
		if not loaded_leaderboard then
			loaded_leaderboard = true

			translatedChatMessage("leaderboard_loaded")
		end

		leaderboard = data.ranking
		checkPlayersPosition(leaderboard, max_leaderboard_rows)
	end

	if data.coinranking then
		coinleaderboard = data.coinranking
		checkPlayersPosition(coinleaderboard, max_leaderboard_rows)
	end

	if data.weekly then
		weeklyfile = data.weekly
		weekleaderboard = data.weekly.ranks

		local ts = os.time() --+ 60 * 60 * 1000
		local file_reset = tonumber(data.weekly.ts) or WEEKLY_RESET_INIT
		local a_day = 24 * 60 * 60 * 1000
		local a_week = 7 * a_day

		local new_reset = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
		if ts - file_reset >= a_week then
			if #weekleaderboard > 2 and weekleaderboard[1][3] > 30 then
				local unlocks_at = ts + a_day
				data.weekly.wl[tostring(weekleaderboard[1][1])] = unlocks_at
				data.weekly.wl[tostring(weekleaderboard[2][1])] = unlocks_at
				data.weekly.wl[tostring(weekleaderboard[3][1])] = unlocks_at
			end

			if #weekleaderboard > 2 then
				sendPacket(
					"common", 4,
					os.date("%d/%m/%Y", file_reset) .. "\000" .. os.date("%d/%m/%Y", ts - a_day) ..
					"\000" .. weekleaderboard[1][4] .. "\000" .. weekleaderboard[1][2] .. "\000" .. weekleaderboard[1][3] ..
					"\000" .. weekleaderboard[2][4] .. "\000" .. weekleaderboard[2][2] .. "\000" .. weekleaderboard[2][3] ..
					"\000" .. weekleaderboard[3][4] .. "\000" .. weekleaderboard[3][2] .. "\000" .. weekleaderboard[3][3]
				)
			end

			data.weekly.ts = tostring(new_reset)
			data.weekly.ranks = {}
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

		checkPlayersPosition(weekleaderboard, max_weekleaderboard_rows)
	end
end)

onEvent("LeaderboardUpdate", function(player, time)
	local playerData = room.playerList[player]
	local completedTime = tonumber(time)

	if playerData then
		local playerId = playerData.id
		local playerCommunity = playerData.community
		local playerCount = #roomleaderboard

		roomleaderboard[playerCount + 1] = {
			playerId,
			player,
			completedTime,
			playerCommunity
		}

		sort(roomleaderboard, roomLeaderboardSort)

		if playerCount == 99 then
			roomleaderboard[99] = nil
		end
	end
end)
end