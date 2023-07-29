max_leaderboard_rows = 73
local max_weekleaderboard_rows = 31
local loaded_leaderboard = false
leaderboard = {}
weekleaderboard = {}
-- {id, name, completed_maps, community}
weeklyfile = {}
local default_leaderboard_user = {0, nil, 0, "xx"}

local function leaderboardSort(a, b)
	return a[3] > b[3]
end

local remove, sort = table.remove, table.sort

local function checkPlayersPosition(week)
	local max_lb_rows = week and max_weekleaderboard_rows or max_leaderboard_rows
	local lb = week and weekleaderboard or leaderboard
	local totalRankedPlayers = #lb
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
	local playerFile, playerData, completedMaps

	for player in next, in_room do
		playerFile = players_file[player]

		if playerFile then
			completedMaps = week and playerFile.week[1] or playerFile.c
			playerData = room.playerList[player]
			if playerData then
				playerId = playerData.id

				if not bans[playerId] then
					cacheData = cachedPlayers[playerId]
					if cacheData then
						cacheData[2] = player
						cacheData[3] = completedMaps
						cacheData[4] = playerData.community
					else
						totalRankedPlayers = totalRankedPlayers + 1
						lb[totalRankedPlayers] = {
							playerId,
							player,
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

	if not week then
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

		checkPlayersPosition(false)
	end

	if data.weekly then
		local ts = os.time() --+ 60 * 60 * 1000
		local now = os.date("*t", ts / 1000)
		now.wday = now.wday - 1
		if now.wday == 0 then
			now.wday = 7
		end

		local new_reset = os.date("%d/%m/%Y", ts - now.wday * 24 * 60 * 60 * 1000)
		if new_reset ~= data.weekly.ts then

			if #weekleaderboard > 2 and weekleaderboard[1][3] > 30 then
				data.weekly.lw = data.weekly.cw
				data.weekly.cw = {}
				data.weekly.cw[tostring(weekleaderboard[1][1])] = true
				data.weekly.cw[tostring(weekleaderboard[2][1])] = true
				data.weekly.cw[tostring(weekleaderboard[3][1])] = true
			end

			data.weekly.ts = new_reset
			data.weekly.ranks = {}
		end

		if timed_maps.week.last_reset ~= new_reset then
			timed_maps.week.last_reset = new_reset

			for player, data in next, players_file do
				if data.week[2] ~= new_reset then
					data.week = {0, new_reset}
				end
			end

			tfm.exec.chatMessage("<j>The weekly leaderboard has been reset.")
		end

		weeklyfile = data.weekly
		weekleaderboard = data.weekly.ranks

		checkPlayersPosition(true)
	end
end)

local function in_table(value, tbl)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

local function checkWeeklyWinners(player, data)
	local id = tostring(room.playerList[player].id)

	if (not weeklyfile.lw or not weeklyfile.lw[id]) and (not weeklyfile.cw or not weeklyfile.cw[id]) then 
		return
	end

	if data.badges[3] ~= 1 then
		players_file[player].badges[3] = 1
		NewBadgeInterface:show(player, 3, 1)
		savePlayerData(player)
	end
end


onEvent("PlayerDataParsed", checkWeeklyWinners)
