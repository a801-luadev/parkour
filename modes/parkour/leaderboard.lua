local room = tfm.get.room
local max_leaderboard_rows = 70
local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
local leaderboard = {}
-- {id, name, completed_maps, community}
local default_leaderboard_user = {0, nil, 0, "xx"}

local function leaderboardSort(a, b)
	return a[3] > b[3]
end

local remove, sort = table.remove, table.sort

local function checkPlayersPosition()
	local totalRankedPlayers = #leaderboard
	local cachedPlayers = {}

	local playerId

	local toRemove, counterRemoved = {}, 0
	for player = 1, totalRankedPlayers do
		playerId = leaderboard[player][1]

		if bans[id] then
			counterRemoved = counterRemoved + 1
			toRemove[counterRemoved] = index
		else
			cachedPlayers[id] = index
		end
	end

	for index = counterRemoved, 1, -1 do
		remove(leaderboard, toRemove[index])
	end
	toRemove = nil

	totalRankedPlayers = totalRankedPlayers - counterRemoved

	local cacheData
	local playerFile, playerData, completedMaps

	for player in next, in_room do
		playerFile = players_file[player]

		if file and file.parkour then
			completedMaps = playerFile.parkour.c
			playerData = room.playerList[player]
			playerId = playerData.id

			if not bans[playerId] then
				cacheData = cachedPlayers[playerId]
				if cacheData then
					cacheData = leaderboard[cacheData]
					cacheData[2] = player
					cacheData[3] = completedMaps
					cacheData[4] = data.community
				else
					totalRankedPlayers = totalRankedPlayers + 1
					leaderboard[totalRankedPlayers] = {
						playerId,
						player,
						completedMaps,
						data.community
					}
				end
			end
		end
	end

	sort(leaderboard, leaderboardSort)

	for index = max_leaderboard_rows + 1, totalRankedPlayers do
		leaderboard[index] = nil
	end
end

onEvent("GameDataLoaded", function(data)
	if data.ranking then
		leaderboard = data.ranking

		checkPlayersPosition()
	end
end)
