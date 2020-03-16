local room = tfm.get.room
local max_leaderboard_rows = 70
local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
local leaderboard = {}
local default_leaderboard_user = {0, nil, 0, "xx"}
-- {id, name, completed_maps, community}

local function leaderboardSort(a, b)
	return a[3] > b[3]
end

local function checkPlayersPosition()
	local pointer = #leaderboard
	local cache = {}

	local to_remove, count = {}, 0
	local id
	for index = 1, pointer do
		id = leaderboard[index][1]
		if bans[id] then
			count = count + 1
			to_remove[count] = index
		else
			cache[id] = leaderboard[index]
		end
	end

	for index = count, 1, -1 do
		pointer = pointer - 1
		table.remove(leaderboard, to_remove[index])
	end

	local completed, data, file
	for player in next, in_room do
		file = players_file[player]
		if file and file.parkour then
			completed = players_file[player].parkour.c
			data = room.playerList[player]

			if not bans[data.id] then
				if cache[data.id] then
					cache[data.id][2] = player
					cache[data.id][3] = completed
					cache[data.id][4] = data.community
				else
					pointer = pointer + 1
					leaderboard[pointer] = {
						data.id,
						player,
						completed,
						data.community
					}
				end
			end
		end
	end

	table.sort(leaderboard, leaderboardSort)

	for index = max_leaderboard_rows + 1, pointer do
		leaderboard[index] = nil
	end
end

onEvent("GameDataLoaded", function(data)
	if data.ranking then
		leaderboard = data.ranking

		checkPlayersPosition()
	end
end)