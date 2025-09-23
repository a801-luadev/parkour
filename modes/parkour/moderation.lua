do
local to_do = {}
local pdataRequest = {}
local cached_files = {
	[tostring(files["sanction"])] = false,
}
local reported = {}

-- if it doesn't require save, we can call callback right away using cache
-- returns true if it hits the cache
local function schedule(fileid, save, callback)
	if not save and cached_files[tostring(files[fileid])] then
		callback(cached_files[tostring(files[fileid])])
		return true
	end

	to_do[#to_do + 1] = { fileid, save, callback }
end

-- by principle the room player is in has the most up to date player data
-- and changing player data outside of player's current room is not allowed
-- so whether you want to save it or not we can return the cached pdata
-- also returns true if data is from the cache
local function schedule_player(name, save, callback, timeoutCallback)
	if players_file[name] then
		callback(players_file[name])
		if save then
			savePlayerData(name)
		end
		return true
	end
	pdataRequest[name] = { callback, os.time() + 1000, save, timeoutCallback }
	system.loadPlayerData(name)
end

local function checkWeeklyWinners(player, data)
	if not room.playerList[player] then return end
	local id = tostring(room.playerList[player].id)

	if not weeklyfile or not weeklyfile.wl or not weeklyfile.wl[id] then 
		return
	end

	if os.time() < weeklyfile.wl[id] then
		return
	end

	if data.badges[3] ~= 1 then
		data.badges[3] = 1
		NewBadgeInterface:show(player, 3, 1)
		savePlayerData(player)
	end

	schedule("leaderboard", true, function(filedata)
		filedata.weekly.wl[id] = nil
	end)
end

local function sendBanLog(playerName, time, target, minutes)
    if not time then
        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned.", target)
    elseif time > 2 then
        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned for " .. minutes .. " minutes.", target)
    elseif time == 2 then
        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned permanently.", target)
    else
        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned.", target)
    end
end

onEvent("GameDataLoaded", function(data, fileid)
	local action
	local save
	local len = #to_do

	for index = 1, len do
		action = to_do[index]
		if files[action[1]] == tonumber(fileid) then
			action[3](data)
			save = action[2]
			to_do[index] = false
		end
	end

	for index = len, 1, -1 do
		if not to_do[index] then
			table.remove(to_do, index)
		end
	end

	if cached_files[fileid] ~= nil then
		cached_files[fileid] = data
	end

	if data.sanction then
		local now = os.time()
		local playerList = room.playerList
		local id, banInfo, banDays

		for player, pdata in next, players_file do
			if playerList[player] and in_room[player] then
				id = tostring(playerList[player].id)
				banInfo = id and data.sanction[id]

				if banInfo and banInfo.timestamp ~= pdata.lastsanction then
					pdata.bancount = banInfo.level
					pdata.lastsanction = banInfo.timestamp
					pdata.bannedby = data.mods[banInfo.info] or banInfo.info
					pdata.banned = banInfo.time

					savePlayerData(player)

					local minutes = pdata.banned and math.ceil((pdata.banned - os.time()) / 1000 / 60)
                    if ranks.hidden[pdata.bannedby] then
                        for moderator in next, in_room do
                            if ranks.admin[moderator] or ranks.mod[moderator] then
                                sendBanLog(player, pdata.banned, moderator, minutes)
                            end
                        end
                    else
                        sendBanLog(player, pdata.banned, nil, minutes)
                	end
				end

				if pdata.banned and (pdata.banned == 2 or os.time() < pdata.banned) then
					if not banInfo then
						data:setSanction(id, {
							timestamp = 0,
							time = pdata.banned,
							level = pdata.banned == 2 and 4 or 1,
						})
						save = true
					end

					if pdata.banned == 2 then
						translatedChatMessage("permbanned", player)
					else
						local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
						translatedChatMessage("tempbanned", player, minutes)
					end
				end
			end
		end
	end

	if save or (data.ranking or data.weekly) then
		eventSavingFile(fileid, data)
	end
end)

local function playerDataRequests(player, data)
	local fetchData = pdataRequest[player]
	if fetchData then
		fetchData[1](data)

		if fetchData[3] then
			system.savePlayerData(player, json.encode(data))
		end

		pdataRequest[player] = nil
	end
end

local function updateSanctions(playerID, playerName, time, moderator, minutes)
	schedule("sanction", true, function(data)
		local now = os.time()

		playerID = tostring(playerID)
		playerName = playerName or playerID
		time = time or (now + minutes * 60 * 1000)

		local baninfo = data.sanction[playerID]
		if time > 0 then
			if baninfo and (baninfo.time == 2 or baninfo.time > now) and not minutes then
				tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " is banned already.", moderator)
				return
			end
		else
			if not baninfo or baninfo.time < 1 then
				tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " doesn't seem to be banned.", moderator)
				return
			end
		end

		local sanctionLevel = baninfo and baninfo.level or 0
		if time == 1 then
			sanctionLevel = math.min(4, sanctionLevel + 1)
			if sanctionLevel == 1 then
				time = now + 86400000 -- 1 day
				minutes = 1440
			elseif sanctionLevel == 2 then
				time = now + 86400000 * 7
				minutes = 10080
			elseif sanctionLevel == 3 then
				time = now + 86400000 * 30
				minutes = 43200
			else
				time = 2 -- permanent ban
				minutes = 2
			end
		elseif time == -1 then
			sanctionLevel = math.max(0, sanctionLevel - 1)
			time = 0
			minutes = 0
		end

		if time == 0 and in_room[playerName] then
			enableSpecMode(playerName, false)
		end

		data:setSanction(playerID, {
			timestamp = now,
			time = time,
			info = moderator,
			level = sanctionLevel
		})

		sendPacket(
			"common",
			packets.rooms.ban_logs,
			playerID .. "\000" ..
			playerName .. "\000" ..
			time .. "\000" ..
			moderator .. "\000" ..
			minutes .. "\000" ..
			-- prev sanction
			(baninfo and baninfo.timestamp or "-") .. "\000" ..
			(baninfo and baninfo.time or "-") .. "\000" ..
			(baninfo and baninfo.info and (data.mods[baninfo.info] or baninfo.info) or "-") .. "\000" ..
			(baninfo and baninfo.level or "-")
		)
		sendBanLog(playerName, time, moderator, minutes)
	end)
end

newCmd({ name = {"ban", "unban"},
	perm = "ban",
	min_args = 1,
	log = true,
	chatlog = true,
	fn = function(player, args)
	local targetPlayer = args[1]
	local moderator = player
	local time = args[0] == 'ban' and 1 or -1 -- ban time changes depending on players previous bans

	-- Ban by player id
	if tonumber(targetPlayer) then
		tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
		updateSanctions(targetPlayer, nil, time, moderator)
		return
	end

	targetPlayer = capitalize(targetPlayer)
	if not string.find(targetPlayer, "#", 1, true) then
		targetPlayer = targetPlayer .. "#0000"
	end

	tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
	-- Ban a player using their name (in the room)
	local roomPlayer = room.playerList[targetPlayer]
	if roomPlayer then
		updateSanctions(roomPlayer.id, targetPlayer, time, moderator)
		return
	end

	reported[targetPlayer] = nil

	-- Ban a player using their name
	schedule_player(targetPlayer, false, function(pdata)
		if not pdata.playerid then
			tfm.exec.chatMessage("<v>[#] <r>The player cannot be (un)banned this way, try player id.", player)
			return
		end

		updateSanctions(pdata.playerid, targetPlayer, time, moderator)
	end, function()
		tfm.exec.chatMessage("<v>[#] <r>Player doesn't seem to be online, try player id.", player)
	end)
end })

local function handleAdminBan(player, ban, targetPlayer, playerID, sanctionTime, minutes)
	-- Ban using name (must be in the same room)
	tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
	if not playerID then
		local roomPlayer = room.playerList[targetPlayer]

		if not roomPlayer then
			tfm.exec.chatMessage("<v>[#] <r>You cannot ban a player with their player name if you don't share the same room. Please use their player ID instead.", player)
			return
		end

		updateSanctions(roomPlayer.id, targetPlayer, sanctionTime, player, minutes)
		return
	end

	-- Ban by player id
	updateSanctions(playerID, nil, sanctionTime, player, minutes)
end

newCmd({ name = "pban",
	rank = "admin",
	min_args = 2,
	fn = function(player, args)
	local isPerma = args[2] == "perma"
	local minutes = tonumber(args[2])
	local targetPlayer = args[1]
	local playerID = tonumber(targetPlayer)
	local sanctionTime

	if isPerma or minutes == 1 then
		minutes = 1
		sanctionTime = 2
	end

	if not minutes or minutes < 0 then
		return translatedChatMessage("invalid_syntax", player)
	end

	handleAdminBan(player, true, targetPlayer, playerID, sanctionTime, minutes)
	chatlogCmd(cmd, player, args)
	logCmd(cmd, player, args)
end })

newCmd({ name = "punban",
	rank = "admin",
	min_args = 1,
	log = true,
	chatlog = true,
	fn = function(player, args)
	local targetPlayer = args[1]
	local playerID = tonumber(targetPlayer)
	handleAdminBan(player, false, targetPlayer, playerID, 0, 0)
end })

newCmd({ name = {"addmap", "removemap"},
	perm = "manage_maps",
	min_args = 2,
	fn = function(player, args)
	local diffMap = { diff1="maps", diff2="maps2", diff3="maps3" }
	local rotation = diffMap[args[1]]
	if not rotation then
		tfm.exec.chatMessage("<v>[#] <r>Type a valid difficulty: diff1-3", player)
		return
	end

	local diffIndex = tonumber(args[1]:sub(5,5))
	local codeMap, indexList = {}, {}
	local mapcode, rotation_index
	local addmap = args[0] == "addmap"

	for i=2,args._len do
		mapcode = args[i]:gsub("^@", "")
		mapcode = tonumber(mapcode)
		if not mapcode then
			return tfm.exec.chatMessage("<v>[#] <r>Invalid map code: " .. args[i], player)
		end

		if not codeMap[mapcode] then
			rotation_index = table_find(maps[diffIndex].list, mapcode)

			if addmap and rotation_index then
				tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " is already in rotation.", player)
				return
			elseif not addmap and not rotation_index then
				tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " is not in rotation.", player)
				return
			else
				indexList[1 + #indexList] = rotation_index or mapcode
				codeMap[mapcode] = true
			end
		end
	end

	if #indexList == 0 then
		return
	end

	table.sort(indexList)
	tfm.exec.chatMessage("<v>[#] <j>Scheduled map update job.", player)
	schedule("init", true, function(data)
		local rotation_table = data[rotation]

		if addmap then
			for mapcode in next, codeMap do
				rotation_table[1 + #rotation_table] = mapcode
			end
		else
			local index
			for i=#indexList, 1, -1 do
				index = indexList[i]
				indexList[i] = rotation_table[index]
				table.remove(rotation_table, index)
			end
		end

		tfm.exec.chatMessage("<v>[#] <j>Updated maps: " .. table.concat(indexList, ' '), player)
	end)

	chatlogCmd(cmd, player, args, ranks.mapper)
	logCmd(cmd, player, args)
end })

local function printSanctions(target, kind, name, pid, timestamp, time, level, mod, minutes)
	local banState = ""

	if not time then
		banState = "has never been banned before "
	elseif time == 0 then
		banState = "was unbanned "
	elseif time == 2 or time > os.time() then
		banState = "is <r>currently banned</r> "
	else
		banState = "was banned "
	end

	local byMod = mod and ("by <bv>" .. mod .. "</bv> ") or ""
	local forMinutes = ""
	local onDate = ""
	local minRemaining = ""

	if timestamp then
		if time then
			if time == 2 then
				forMinutes = "permanently "
			elseif time > 2 then
				local minutes = math.floor((time - timestamp) / 1000 / 60)
				forMinutes = "for <v>" .. minutes .. "</v> minutes "
			end
		end

		onDate = "on <bl>" .. os.date("%B %d %Y %H:%M.%S", timestamp) .. "</bl> (france time) "
	end

	if time and minutes then
		forMinutes = "for <v>" .. minutes .. "</v> minutes "
	end

	if time and time > 2 then
		local minutes = math.floor((time - os.time()) / 1000 / 60)

		if minutes >= 0 then
			minRemaining = "and has <v>" .. minutes .. "</v> minutes remaining "
		end
	end

	tfm.exec.chatMessage(
		("<v>[#] <n>(%s) <n2>%s</n2> %s%s%s%s%s<g>[level %s] [ts %s] [pid %s]"):format(
			kind,
			name,
			banState,
			byMod,
			forMinutes,
			onDate,
			minRemaining,
			level or 0,
			time or "-",
			pid or "-"
		),
		target
	)
end

newCmd({ name = {"sanctions", "bancount", "baninfo"},
	perm = "view_sanctions",
	min_args = 1,
	fn = function(player, args, cmd)
	local targetName = capitalize(args[1])
	local targetID = tonumber(targetName)

	if targetID then
		targetName = nil
	else
		if not string.find(targetName, "#", 1, true) then
			targetName = targetName .. "#0000"
		end

		if room.playerList[targetName] then
			targetID = room.playerList[targetName].id
		end
	end

	if targetID then
		targetID = tostring(targetID)
	end

	if ranks.admin[player] then
		if args[2] == "reset" then
			if not targetID then
				tfm.exec.chatMessage("<v>[#] <r>You must provide a player id.", player)
				return
			end

			tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
			schedule("sanction", true, function(data)
				local file = data.sanction and data.sanction[targetID]
				if not file or not file.level or file.level == 0 then
					tfm.exec.chatMessage(
						("<v>[#] <j>%s's sanction level is already at zero."):format(
							targetName or targetID
						),
						player
					)
					return
				end

				file.level = 0
				tfm.exec.chatMessage(
					("<v>[#] <j>%s's sanction level has been reset."):format(
						targetName or targetID
					),
					player
				)
			end)

			chatlogCmd(cmd, player, args)
			logCmd(cmd, player, args)

			return
		end
	end

	if targetName then
		local is_cached = schedule_player(targetName, false, function(pdata)
			if pdata.kill or pdata.killed then
				printSanctions(
					player,
					'powerban',
					targetName,
					pdata.playerid,
					pdata.killed ~= 0 and pdata.kill ~= 0 and
					(pdata.killed - pdata.kill * 60 * 1000) or nil,
					pdata.killed ~= 0 and pdata.killed or nil,
					'-',
					pdata.killedby,
					pdata.kill
				)
			end

			printSanctions(
				player,
				'pdata',
				targetName,
				pdata.playerid,
				pdata.lastsanction,
				pdata.banned,
				pdata.bancount,
				pdata.bannedby
			)

			if not targetID and pdata.playerid then
				targetID = pdata.playerid
				local is_cached = schedule("sanction", false, function(data)
					local file = data and data.sanction and data.sanction[targetID]
					if not file then
						tfm.exec.chatMessage(
							("<v>[#] <r>%s not found in file data"):format(targetID),
							player
						)
						return
					end
					printSanctions(
						player,
						'file',
						targetName or targetID,
						targetID,
						file.timestamp,
						file.time,
						file.level,
						tostring(data.mods[file.info] or file.info)
					)
				end)
				if not is_cached then
					tfm.exec.chatMessage(
						("<v>[#] <bl>Checking file data for %s's sanctions..."):format(targetName),
						player
					)
				end
			end
		end)
		if not is_cached then
			tfm.exec.chatMessage(
				("<v>[#] <bl>Checking player data for %s's sanctions..."):format(targetName),
				player
			)
		end
	end

	if targetID then
		local is_cached = schedule("sanction", false, function(data)
			local file = data and data.sanction and data.sanction[targetID]
			if not file then
				tfm.exec.chatMessage(
					("<v>[#] <r>%s not found in file data"):format(targetID),
					player
				)
				return
			end
			printSanctions(
				player,
				'file',
				targetName or targetID,
				targetID,
				file.timestamp,
				file.time,
				file.level,
				tostring(data.mods[file.info] or file.info)
			)
		end)
		if not is_cached then
			tfm.exec.chatMessage(
				("<v>[#] <bl>Checking file data for %s's sanctions..."):format(targetID),
				player
			)
		end
	end
end })

newCmd({ name = "kill",
	perm = "kill",
	min_args = 2,
	fn = function(player, args)
	local requestplayer = capitalize(args[1])
	local killedTime = tonumber(args[2])

	if not killedTime then
		tfm.exec.chatMessage("<v>[#] <r>" ..args[2].. " doesn't seem like a number.", player)
		return
	end
	
	if not string.find(requestplayer, "#", 1, true) then
		requestplayer = requestplayer .. "#0000"
	end

	local roomPlayer = room.playerList[requestplayer]
	if not in_room[requestplayer] or not roomPlayer then
		tfm.exec.chatMessage("<v>[#] <r>" ..requestplayer.. " isn't here.", player)
		return
	end

	reported[requestplayer] = nil

	chatlogCmd(cmd, player, args)
	schedule_player(requestplayer, true, function(pdata)
		sendPacket(
			"common",
			packets.rooms.kill_logs,
			requestplayer .. "\000" ..
			killedTime .. "\000" ..
			player .. "\000" ..
			roomPlayer.id .. "\000" ..
			(args[3] or '') .. "\000" ..
			pdata.killed .. "\000" ..
			pdata.kill .. "\000" ..
			(pdata.killedby or '-')
		)

		pdata.killedby = player
		pdata.killed = os.time() + killedTime * 60 * 1000
		pdata.kill = killedTime

		tfm.exec.chatMessage("<v>[#] <V>"..requestplayer.. " <j>can't use their powers for <b>"..killedTime.."</b> minutes.", nil)
		translatedChatMessage("killed", requestplayer, killedTime)
		checkKill(requestplayer)
	end)
end })

newCmd({ name = "setrank",
	rank = "admin",
	min_args = 2,
	fn = function(player, args)
	local targetPlayer = capitalize(args[1])
	local newRanks = {}
	local ID = 0

	if not string.find(targetPlayer, "#", 1, true) then
		targetPlayer = targetPlayer .. "#0000"
	end

	if args[2] ~= "none" then
		for i = 2, #args do
			if ranks_id[args[i]] then
				ID = ID + ranks_id[args[i]]
				newRanks[args[i]] = true
			else
				return tfm.exec.chatMessage("<v>[#] <r>Invalid rank: " .. args[i], player)
			end
		end
	end

	if ID == 0 then
		player_ranks[targetPlayer] = nil
		ID = nil
		tfm.exec.chatMessage("<v>[#] <r>All ranks removed from " .. targetPlayer, player)
	else
		player_ranks[targetPlayer] = newRanks
		tfm.exec.chatMessage("<v>[#] <r>Ranks has been set.", player)
	end

	schedule("init", true, function(data)
		data.ranks[targetPlayer] = ID
	end)
	logCmd(cmd, player, args)
end })

local printSanctionList

newCmd({ name = "file",
	rank = "admin",
	min_args = 2,
	fn = function(player, args, cmd)
	local fileName = args[1]

	if fileName == "weekly" then
		local fileAction = args[2]
		if fileAction == "view" then
			if weeklyfile and weeklyfile.ts and weeklyfile.wl then
				tfm.exec.chatMessage(('<v>[#] <j>Timestamp: %s <bl>(%s)'):format(
					tonumber(weeklyfile.ts) and os.date("%Y %B %d", weeklyfile.ts) or '???',
					tostring(weeklyfile.ts)
				), player)
				tfm.exec.chatMessage("<v>[#] <j>Unclaimed badge winners:", player)

				for name, ts in next, weeklyfile.wl do
					tfm.exec.chatMessage(('<v>%s<bl>: %s <g>(%s)'):format(
						name,
						tonumber(ts) and os.date("%Y %B %d", ts) or '???',
						tostring(ts)
					), player)
				end
			else
				tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
			end

		elseif fileAction == "last" then
			local date = "???"
			if last_weekly_reset_ts then
				date = os.date("%Y %B %d", last_weekly_reset_ts)
			end
			tfm.exec.chatMessage(
				("<v>[#] <j>Last weekly reset: <j>%s <bl>(%s)"):format(
					date,
					tostring(last_weekly_reset_ts)
				),
				player
			)

		elseif fileAction == "add" then
			if args._len < 3 then
				translatedChatMessage("invalid_syntax", player)
				return
			end

			local count = tonumber(args[4]) or 100

			local requestplayer = capitalize(args[3])
			if not string.find(requestplayer, "#", 1, true) then
				requestplayer = requestplayer .. "#0000"
			end

			schedule_player(requestplayer, true, function(pdata)
				pdata.week[1] = pdata.week[1] + count
				tfm.exec.chatMessage("<v>[#] <j>"..requestplayer.."'s new weekly count: "..pdata.week[1], player)
			end)

			chatlogCmd(cmd, player, args)
			logCmd(cmd, player, args)
		end
	elseif fileName == "maps" then
		local category = args[2]
		local len
		for j=1,3 do
			if category == "all" or category == tostring(j) then
				len = maps[j].count
				tfm.exec.chatMessage("<v>[#] <v>diff" .. tostring(j) .. " maps: " .. tostring(len), player)
				printList(maps[j].list, 20, len, player)
			end
		end
	elseif fileName == "staff" then
		local rankName = args[2]
		if rankName == "all" then
			local list, count
			for staffName, hasRanks in next, player_ranks do
				list, count = {}, 0
				for rankName in next, hasRanks do
					count = count + 1
					list[count] = rankName
				end
				tfm.exec.chatMessage("<v>[#] <v>" .. staffName .. "<bl>: " .. table.concat(list, ' '), player)
			end
			return
		end

		local list = ranks[rankName]
		if not list then
			tfm.exec.chatMessage("<v>[#] <r>Invalid rank namme.", player)
			return
		end

		tfm.exec.chatMessage("<v>[#] <j>" .. rankName .. ":", player)
		printList(list, 10, list._count, player)

	elseif fileName == "sanction" then
		local fileAction = args[2]
		if fileAction == "list" then
			local page = tonumber(args[3]) or 1
			printSanctionList(player, nil, page)
		else
			printSanctionList(player, fileAction)
		end
	end
end })

printSanctionList = function(player, targetID, page)
	local is_cached = schedule("sanction", false, function(data)
		local sanctions_file = data.sanction
		if not targetID then
			local page_size = 90

			if not data._keys then
				tfm.exec.chatMessage("<v>[#] <r>Not loaded yet", player)
				return
			end

			local playerIDs, len = {}, 0
			for id in next, data._keys do
				len = len + 1
				playerIDs[len] = id
			end

			local totalPages = math.ceil(len / page_size)

			if not page or page < 1 or page > totalPages then
				tfm.exec.chatMessage("<v>[#] <j>Invalid page number. Available pages: 1 - " .. totalPages, player)
				return
			end

			local startIndex = (page - 1) * page_size + 1
			local endIndex = math.min(startIndex + page_size - 1, len)
			local message = table.concat(playerIDs, ', ', startIndex, endIndex)

			tfm.exec.chatMessage("<v>[#] <j>Count: " .. len, player)
			tfm.exec.chatMessage("<v>[#] <j>" ..message, player)
		else
			if not tonumber(targetID) then
				tfm.exec.chatMessage("<v>[#] <j>"..targetID.." doesn't seem like player id?", player)
				return
			end

			if not sanctions_file[targetID] then 
				tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
				return
			end

			local playerFile = sanctions_file[targetID]
			tfm.exec.chatMessage("<v>[#] <j>Timestamp: "..playerFile.timestamp, player)
			tfm.exec.chatMessage("<v>[#] <j>Time: "..playerFile.time, player)
			tfm.exec.chatMessage("<v>[#] <j>Info: "..tostring(data.mods[playerFile.info] or playerFile.info), player)
			tfm.exec.chatMessage("<v>[#] <j>Level: "..playerFile.level, player)
		end
	end)

	if not is_cached then
		tfm.exec.chatMessage("<v>[#] <j>Loading the sanctions file...", player)
	end
end

newCmd({ name = {"announcement", "announce"},
	rank = "manager",
	min_args = 1,
	log = true,
	chatlog = true,
	fn = function(player, args, cmd)
		local text = table.concat(args, " ")
		tfm.exec.chatMessage("<ROSE>Ξ [Parkour] <N>" .. text)
	end })

newCmd({ name = "report",
	fn = function(playerName, args, cmd)
	if is_tribe then
		return
	end

	local pdata = players_file[playerName]
	local player = room.playerList[playerName]
	if not pdata or not player or not pdata.report or bans[player.id] then
		return
	end

	local timestamp = os.time()
	local regDate = player.registrationDate
	-- Accounts registered less than 1 week ago
	if not regDate or regDate > timestamp - 7 * 24 * 60 * 60 * 1000 then
		return
	end

	if args._len == 0 then
		toggleInterface(ReportInterface, playerName)
		return
	end

	if ReportValidReasons[args[1]] then
		ReportInterface:show(playerName, args[1])
		return
	end

	local reportedName = args[1]:lower():gsub('^+?[a-z]', string.upper)
	local reportedPlayer = room.playerList[reportedName]
	if not reportedPlayer then
		return translatedChatMessage("reported_not_here", playerName)
	end
	if reportedPlayer.id == 0 or reportedName:sub(1, 1) == "*" or bans[reportedPlayer.id] or reportedName == playerName then
		return translatedChatMessage("reported_invalid", playerName)
	end

	if args._len == 1 then
		ReportInterface:show(playerName, nil, reportedName)
		return
	end

	local reason = table.concat(args, ' ', 2, args._len)
	if #reason < 3 then
		return translatedChatMessage("reason_too_short", playerName)
	end

	if reported[reportedName] then
		if reported[reportedName][playerName] then
			return translatedChatMessage("report_done", playerName)
		end
	else
		reported[reportedName] = {}
	end

	reported[reportedName][playerName] = true

	sendPacket(
		"common", packets.rooms.report,
		timestamp .. "\000" ..
		player.id .. "\000" ..
		playerName .. "\000" ..
		reportedPlayer.id .. "\000" ..
		reportedName .. "\000" ..
		room.shortName .. "\000" ..
		reason
	)
	translatedChatMessage("report_done", playerName)
	chatlogCmd(cmd, playerName, args)
end })

newCmd({ name = "karma",
	rank = "mod",
	min_args = 1,
	fn = function(playerName, args, cmd)
	local target = args[1]:lower():gsub('^+?[a-z]', string.upper)
	local pdata = players_file[target]
	if not room.playerList[target] or not pdata then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	if args._len == 1 then
		if pdata.report then
			tfm.exec.chatMessage('<v>[#] <vp>' .. target .. ' can use !report.', playerName)
		else
			tfm.exec.chatMessage('<v>[#] <r>' .. target .. ' cannot use !report.', playerName)
		end
		return
	end

	local yes = args[2] == 'yes'
	if not yes and args[2] ~= 'no' then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	if pdata.report == yes then
		tfm.exec.chatMessage('<v>[#] <bl>Nothing changed.', playerName)
		return
	end

	pdata.report = yes
	pdata.karma = playerName
	savePlayerData(target)
	tfm.exec.chatMessage('<v>[#] <n>Done.', playerName)
	chatlogCmd(cmd, playerName, args)
	logCmd(cmd, playerName, args)
end })

newCmd({ name = "skip",
	perm = "skip_map",
	min_args = 1,
	fn = function(playerName, args, cmd)
	if os.time() < map_change_cd and not review_mode then
		tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", playerName)
		return
	end

	local reason = table.concat(args, ' ')
	local mapCode = room.currentMap
	local uniquePlayers = room.uniquePlayers

	if not review_mode then
		sendPacket("common", packets.rooms.skip_map, room.shortName .. "\000" .. playerName .. "\000" .. reason .. "\000" .. mapCode .. "\000" .. uniquePlayers .. "\000" .. player_count .. "\000" .. victory_count .. "\000" .. actual_player_count)
	end

	newMap()
	chatlogCmd(cmd, playerName, args)
end })

newCmd({ name = "sync",
	rank = "mod",
	fn = function(playerName, args, cmd)
	if args._len == 0 then
		return sendChatFmt("<j>Current sync: <v>%s", playerName, tfm.exec.getPlayerSync())
	end

	local target = args[1]
	if not in_room[target] then
		return sendChatFmt("<r>Player isn't in the room.", playerName)
	end

	tfm.exec.setPlayerSync(target)
	sendChatFmt("<j>New sync: <v>%s", playerName, target)

	chatlogCmd(cmd, playerName, args)
	logCmd(cmd, playerName, args)
end })

newCmd({ name = "kick",
	rank = "admin",
	min_args = 1,
	fn = function(playerName, args, cmd)
	if playerName ~= "Parkour#0568" then
		return
	end

	if args[1] == "*" then
		for name in next, room.playerList do
			tfm.exec.kickPlayer(name)
		end
		return
	end

	if args[2] then
		local file = players_file[args[1]]
		if file then
			file.kick = tonumber(args[2])
			savePlayerData(args[1])
		end
	end

	tfm.exec.kickPlayer(args[1])
	chatlogCmd(cmd, playerName, args)
	logCmd(cmd, playerName, args)
end })

newCmd({ name = "claim",
	rank = "admin",
	min_args = 3,
	fn = function(playerName, args)
	if playerName ~= "Parkour#0568" then return end

	local target, nonce, nextCmd = args[1], args[2], args[3]
	local file = players_file[target]
	if not file then return end

	nonce = tonumber(nonce)
	if not nonce or file.claim and file.claim >= nonce then return end

	file.claim = nonce
	savePlayerData(target)

	chatlogCmd(cmd, playerName, args)
	args.chatlogged = false

	table.remove(args, 1)
	table.remove(args, 1)
	table.remove(args, 1)
	args[0] = string.lower(nextCmd)
	args._len = args._len - 3
	args[-1] = table.concat(args, ' ', 0, args._len)
	execCmd(playerName, args)
	translatedChatMessage("claim_done", target)
end })

newCmd({ name = "ping",
	perm = "ping",
	fn = function(playerName, args)
	local target = args[1] or playerName
	local targetPlayer = target and room.playerList[target]

	if not targetPlayer then
		return tfm.exec.chatMessage('<v>[#] <r>Player isn\'t in the room.', playerName)
	end

	tfm.exec.chatMessage('<v>[#] ' .. target .. '<n>\'s average latency: <bl>~' .. targetPlayer.averageLatency, playerName)
end })

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == packets.bots.report_feedback then
		local reported_name, handler, response, target = string.match(
			packet,
			"^([^\000]+)\000([^\000]+)\000([^\000]*)\000([^\000]*)$"
		)

		if in_room[handler] and not target then
			eventChatCommand(handler, "sanctions " .. reported_name)
		end

		if response == "" then return end
		local report = reported[reported_name]
		if target ~= "" then
			if report then
				report[target] = nil
			end
			translatedChatMessage("report_" .. response, target)
		elseif report then
			reported[reported_name] = nil
			for target in next, report do
				translatedChatMessage("report_" .. response, target)
			end
		end
	end
end)

onEvent("PlayerDataParsed", checkWeeklyWinners)
onEvent("PlayerDataParsed", playerDataRequests)
onEvent("PlayerDataParsed", function(player, data)
	if data and data.kick and (data.kick == 1 or os.time() < data.kick) then
		tfm.exec.kickPlayer(player)
	end
end)
onEvent("OutPlayerDataParsed", playerDataRequests)

onEvent("Loop", function(elapsed)
	local now = os.time()
	
	local to_remove, count = {}, 0
	for player, data in next, pdataRequest do
		if now >= data[2] then
			count = count + 1
			to_remove[count] = player
		end
	end
	
	local name
	for idx = 1, count do
		name = to_remove[idx]
		if pdataRequest[name][4] then
			pdataRequest[name][4](name)
		end
		pdataRequest[name] = nil
	end
end)
end