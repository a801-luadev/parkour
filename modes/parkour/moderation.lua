local files = {
	[1] = 20, -- maps, ranks, chats
	[2] = 21,  -- ranking, weekly
	[3] = 23 -- lowmaps, sanction
}

local to_do = {}
local pdataRequest = {}
local maps_loaded = false
local cached_files = {
	[tostring(files[3])] = false,
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

local function updateMapList(mapList, map, add)
	for index = #mapList, 1, -1 do
		if mapList[index] == map then
			table.remove(mapList, index)
			break
		end
	end

	if add then
		mapList[#mapList + 1] = map
	end
end

local function in_table(value, tbl)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
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
		savePlayerData(player, true)
	end

	schedule(2, true, function(filedata)
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

	if data.lowmaps then
		maps_loaded = true
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
					pdata.bannedby = banInfo.info
					pdata.banned = banInfo.time

					savePlayerData(player)

					local minutes = pdata.banned and math.floor((pdata.banned - os.time()) / 1000 / 60)
                    if ranks.hidden[pdata.bannedby] then
                        for moderator in pairs(room.playerList) do
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
						local sanctionLevel = pdata.banned == 2 and 4 or 1
                        data.sanction[tostring(id)] = {
                            timestamp = 0,
                            time = pdata.banned,
                            info = "-",
							level = sanctionLevel,
                        }
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
	schedule(3, true, function(data)
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

		data.sanction[playerID] = {
			timestamp = now,
			time = time,
			info = moderator,
			level = sanctionLevel
		}

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
			(baninfo and baninfo.info or "-") .. "\000" ..
			(baninfo and baninfo.level or "-")
		)
		sendBanLog(playerName, time, moderator, minutes)
	end)
end

function inGameLogCommand(p, command, args)
	local commandtext = table.concat(args, " ")
	for playername, player in pairs(tfm.get.room.playerList) do
		if ranks.admin[playername] or ranks.mod[playername] then
			tfm.exec.chatMessage("<BL>Ξ [" .. p .. "]<N2> !" .. command .. " " .. commandtext, playername)
		end
	end
end

local function handleBan(player, cmd, quantity, args)
	if not ranks.admin[player] and (not perms[player] or not perms[player].ban) then
		return
	end

	if quantity < 1 then
		return translatedChatMessage("invalid_syntax", player)
	end

	inGameLogCommand(player, cmd, args)

	local targetPlayer = args[1]
	local moderator = player
	local time = cmd == 'ban' and 1 or -1 -- ban time changes depending on players previous bans

	logCommand(player, cmd, math.min(quantity, 2), args)

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
end

local function handleAdminBan(player, cmd, quantity, args)
	if not ranks.admin[player] then
		return
	end

	if cmd == "pban" and quantity < 2 then
		return translatedChatMessage("invalid_syntax", player)
	end

	if cmd == "punban"  and quantity < 1 then
		return translatedChatMessage("invalid_syntax", player)
	end

	local isPerma = args[2] == "perma"
	local minutes = tonumber(args[2])
	local targetPlayer = args[1]
	local playerID = tonumber(targetPlayer)

	if cmd == "pban" and (not minutes or minutes < 0) then
		return translatedChatMessage("invalid_syntax", player)
	end

	inGameLogCommand(player, cmd, args)

	local sanctionTime

	if cmd == "pban" then
		if isPerma or minutes == 1 then
			sanctionTime = 2
		else
			sanctionTime = nil
		end
	else
		sanctionTime = 0
		minutes = 0
	end

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

local function handleMap(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.mapper[player] and not ranks.manager[player] then
		return
	end

	local addmap = cmd == "addmap" and true or false

	inGameLogCommand(player, cmd, args)

	if addmap then
		logCommand(player, "addmap", math.min(quantity, 3), args)
	else
		logCommand(player, "removemap", math.min(quantity, 2), args)
	end

	if not maps_loaded then
		tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds.", player)
		return
	end

	if addmap and quantity < 2 then
		return translatedChatMessage("invalid_syntax", player)
	end

	if not addmap and quantity < 1 then
		return translatedChatMessage("invalid_syntax", player)
	end

	local mapcode = args[1]
	if not tonumber(mapcode) then
		mapcode = mapcode:gsub("^@", "")
		if not tonumber(mapcode) then
			return tfm.exec.chatMessage("<v>[#] <r>Invalid map code", player)
		end
	end

	for i = 1, #to_do do
		if to_do[i] and tonumber(to_do[i][2]) == tonumber(mapcode) then
			tfm.exec.chatMessage("<v>[#] <r>Please wait for a minute before taking any action with the same map.", player)
			return
		end
	end

	if addmap then
		mapcode = tonumber(mapcode)
		local rotation = args[2]
		if rotation ~= "low" and rotation ~= "high" then
			tfm.exec.chatMessage("<v>[#] <r>Select a priority: low, high", player)
			return
		end

		if in_table(mapcode, maps.list_low) or in_table(mapcode, maps.list_high) then
			tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " is already in rotation.", player)
			return
		end

		if rotation == "low" then
			schedule(3, true, function(data)
				updateMapList(data.lowmaps, mapcode, true)
				tfm.exec.chatMessage("<v>[#] <j>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
			end)
		else
			schedule(1, true, function(data)
				updateMapList(data.maps, mapcode, true)
				tfm.exec.chatMessage("<v>[#] <j>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
			end)
		end

	else
		for i = 1, #args do
			mapcode = args[i]:gsub("^@", "")
			mapcode = mapcode and tonumber(mapcode) 
			if not mapcode then
				return tfm.exec.chatMessage("<v>[#] <r>Invalid map code: "..args[i], player)
			end
			args[i] = mapcode
		end

		local removeHigh = {}
		local removeLow = {}
		local notFound = {}

		for i = 1, #args do
			mapcode = args[i]
			if in_table(mapcode, maps.list_high) then
				removeHigh[1 + #removeHigh] = mapcode
			elseif in_table(mapcode, maps.list_low) then
				removeLow[1 + #removeLow] = mapcode
			else
				notFound[1 + #notFound] = mapcode
			end
		end

		if #notFound > 0 then
			tfm.exec.chatMessage("<v>[#] <r>Could not find following maps in any of the priority lists: " .. table.concat(notFound, ", "), player)
		end
		
		if #removeHigh > 0 or #removeLow > 0 then
			tfm.exec.chatMessage("<v>[#] <j>Scheduled remaining maps to be removed.", player)
		end

		if #removeHigh > 0 then
			schedule(1, true, function(data)
				for i = 1, #removeHigh do
					updateMapList(data.maps, removeHigh[i], false)
				end
				tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the high priority list: " .. table.concat(removeHigh, ", "), player)
			end)
		end

		if #removeLow > 0 then
			schedule(3, true, function(data)
				for i = 1, #removeLow do
					updateMapList(data.lowmaps, removeLow[i], false)
				end
				tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the low priority list: " .. table.concat(removeLow, ", "), player)
			end)
		end
	end
end

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

local function handleSanctions(player, cmd, quantity, args)
	if not perms[player] or not perms[player].view_sanctions then
		return
	end

	if quantity < 1 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

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

			inGameLogCommand(player, cmd, args)

			tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
			schedule(3, true, function(data)
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
				local is_cached = schedule(3, false, function(data)
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
						file.info
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
		local is_cached = schedule(3, false, function(data)
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
				file.info
			)
		end)
		if not is_cached then
			tfm.exec.chatMessage(
				("<v>[#] <bl>Checking file data for %s's sanctions..."):format(targetID),
				player
			)
		end
	end
end

local function warnPlayer(player, cmd, quantity, args)
	if not ranks.admin[player] and (not perms[player] or not perms[player].kill) then
		return
	end

	inGameLogCommand(player, cmd, args)

	if quantity < 2 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

	local requestplayer = capitalize(args[1])
	local killedTime = args[2]

	if not tonumber(killedTime) then
		tfm.exec.chatMessage("<v>[#] <r>" ..killedTime.. " doesn't seem like a number.", player)
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

	logCommand(player, "kill", math.min(quantity, 2), args)
	sendPacket(
		"common",
		packets.rooms.kill_logs,
		requestplayer .. "\000" ..
		killedTime .. "\000" ..
		player .. "\000" ..
		roomPlayer.id
	)

	schedule_player(requestplayer, true, function(pdata)
		sendPacket(
			"common",
			packets.rooms.prev_kill,
			requestplayer .. "\000" ..
			roomPlayer.id .. "\000" ..
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
end

local function handleSetrank(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	inGameLogCommand(player, cmd, args)

	if args[1] == player then
		tfm.exec.chatMessage("<v>[#] <r>You can't change your rank.", player)
		return
	end

	local targetPlayer = capitalize(args[1])
	local newRanks = {}
	local ID = 0

	if not string.find(targetPlayer, "#", 1, true) then
		targetPlayer = targetPlayer .. "#0000"
	end

	if quantity < 2 then
		translatedChatMessage("invalid_syntax", player)
		return
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

	schedule(1, true, function(data)
		data.ranks[targetPlayer] = ID
	end)
	logCommand(player, cmd, quantity, args)
end

local printSanctionList

local function fileActions(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	if quantity < 2 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

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

			if quantity < 3 then
				translatedChatMessage("invalid_syntax", player)
				return
			end

			inGameLogCommand(player, cmd, args)

			local count = tonumber(args[4]) or 100

			local requestplayer = capitalize(args[3])
			if not string.find(requestplayer, "#", 1, true) then
				requestplayer = requestplayer .. "#0000"
			end

			schedule_player(requestplayer, true, function(pdata)
				pdata.week[1] = pdata.week[1] + count
				tfm.exec.chatMessage("<v>[#] <j>"..requestplayer.."'s new weekly count: "..pdata.week[1], player)
			end)
		end
	elseif fileName == "maps" then
		local category = args[2]
		local len
		if category == "all" or category == "high" then
			len = #maps.list_high
			tfm.exec.chatMessage("<v>[#] <v>high maps: " .. tostring(len), player)
			for i=1, len, 20 do
				tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(maps.list_high, ' ', i, math.min(i+19, len)), player)
			end
		end
		if category == "all" or category == "low" then
			len = #maps.list_low
			tfm.exec.chatMessage("<v>[#] <v>low maps: " .. tostring(len), player)
			for i=1, len, 20 do
				tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(maps.list_low, ' ', i, math.min(i+19, len)), player)
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
		for i=1, list._count, 10 do
			tfm.exec.chatMessage(table.concat(list, ' ', i, math.min(i+9, list._count)), player)
		end

	elseif fileName == "sanction" then
		local fileAction = args[2]
		if fileAction == "list" then
			local page = tonumber(args[3]) or 1
			printSanctionList(player, nil, page)
		else
			printSanctionList(player, fileAction)
		end
	end
end

printSanctionList = function(player, targetID, page)
	local is_cached = schedule(3, false, function(data)
		local sanctions_file = data.sanction
		if not targetID then
			local page_size = 180

			local playerIDs, len = {}, 0
			for playerID in next, sanctions_file do
				len = len + 1
				playerIDs[len] = playerID
			end
			table.sort(playerIDs)

			local totalPages = math.ceil(len / page_size)

			if not page or page < 1 or page > totalPages then
				tfm.exec.chatMessage("<v>[#] <j>Invalid page number. Available pages: 1 - " .. totalPages, player)
				return
			end

			local startIndex = (page - 1) * page_size + 1
			local endIndex = math.min(startIndex + page_size - 1, len)
			local message = table.concat(playerIDs, ', ', startIndex, endIndex)

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
			tfm.exec.chatMessage("<v>[#] <j>Info: "..playerFile.info, player)
			tfm.exec.chatMessage("<v>[#] <j>Level: "..playerFile.level, player)
		end
	end)

	if not is_cached then
		tfm.exec.chatMessage("<v>[#] <j>Loading the sanctions file...", player)
	end
end

function roomAnnouncement(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.manager[player] then
		return
	end

	inGameLogCommand(player, cmd, args)

	local announcementtext = table.concat(args, " ")
	tfm.exec.chatMessage("<ROSE>Ξ [Parkour] <N>"..announcementtext)
end

local function editCoins(player, cmd, quantity, args)
	if not ranks.admin[player] then
		return
	end

	if quantity < 2 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

	local playerName = args[1]
	local action = args[2]

	if not in_room[playerName] or not players_file[playerName] then
		return tfm.exec.chatMessage(playerName.." is not here.", player)
	end

	if action == "show" then
		local result = ""
		for key, value in pairs(players_file[playerName].skins) do
			result = result .. key .. ", "
		end
		result = result:sub(1, -3)
		
		tfm.exec.chatMessage("Current coins: " ..players_file[playerName].coins, player)
		tfm.exec.chatMessage("Skins: " ..result, player)
		return

	elseif action == "default" then
		players_file[playerName].cskins = { 1, 2, 7, 28, 46 }
		savePlayerData(playerName)
		tfm.exec.chatMessage("<v>[#] <j>Current skins set default for " ..playerName, player)

	elseif action == "refund" then
		if quantity < 3 then
			translatedChatMessage("invalid_syntax", player)
			return
		end

		local skinType = tonumber(args[3])
		local skinNumber = tonumber(args[4])

		local selectedSkin = skinType and skinNumber and shop_items[skinType] and shop_items[skinType][skinNumber]
		if not selectedSkin then
			return tfm.exec.chatMessage("Invalid skin type or skin number.", player)
		end

		if not players_file[playerName].skins[tostring(selectedSkin.id)] then
			return tfm.exec.chatMessage("The player doesn't have this skin. ", player)
		end
		
		players_file[playerName].skins[tostring(selectedSkin.id)] = nil
		players_file[playerName].coins = players_file[playerName].coins + tonumber(selectedSkin.price)

		for i = #players_file[playerName].cskins, 1, -1 do
			if players_file[playerName].cskins[i] == tonumber(selectedSkin.id) then
				players_file[playerName].cskins[i] = shop_items[skinType][1].id
			end
		end

		savePlayerData(playerName)
		tfm.exec.chatMessage("<v>[#] <j>Refunded " ..selectedSkin.price.. " coins (" ..skinType.. "/" ..skinNumber..") to the "..playerName, player)

	end

	inGameLogCommand(player, cmd, args)
end

local function setChristmasMap(player, cmd, quantity, args)
	if not ranks.admin[player] then
		return
	end

	gift_conditions._completed = gift_conditions._complete - 1
	gift_conditions._ts = os.time()
end

local function disableSnow(player, cmd, quantity, args)
	tfm.exec.snow(0, 10)
end

local function linkMouse(player, cmd, quantity, args)
	if not ranks.admin[player] then
		return
	end

	if not args[1] then return end
	if not args[2] then 
		args[2] = player
	end

	local firstPlayer = args[1]
	local secondPlayer = args[2]

	tfm.exec.linkMice(firstPlayer, secondPlayer, true)
end

local function changeMouseSize(player, cmd, quantity, args)
	if not ranks.admin[player] then return end

	local target = args[1]
	local size = tonumber(args[2])
	if not room.playerList[target] or not size then
		return translatedChatMessage("invalid_syntax", player)
	end

	tfm.exec.changePlayerSize(target, size)
	return
end

local mouseImages = {}
local function addMouseImage(player, cmd, quantity, args)
	if quantity == 0 then
		if mouseImages[player] then
			tfm.exec.removeImage(mouseImages[player][2], false)
			tfm.exec.killPlayer(player)
			mouseImages[player] = nil
		end
		return
	end

	if not ranks.admin[player] then return end

	local playerName = args[1]
	local imageURL = args[2]
	local scale = tonumber(args[3]) or 1
	local offsetX = tonumber(args[4]) or 0
	local offsetY = tonumber(args[5]) or 0
	local opacity = tonumber(args[6]) or 1

	if playerName == "*" then
		if imageURL == "remove" then
			for _, img in next, mouseImages do
				tfm.exec.removeImage(img[2], false)
			end
			mouseImages = {}
			return
		elseif imageURL then
			for name in next, tfm.get.room.playerList do	
				if mouseImages[name] then
					tfm.exec.removeImage(mouseImages[name][2], false)
				end

				local imageID = tfm.exec.addImage(imageURL, '%'..name, offsetX, offsetY, nil, scale, scale, 0, opacity, 0.5, 0.5, false)
				mouseImages[name] = {imageURL, imageID, 1, scale, offsetX, offsetY, opacity}

				translatedChatMessage("new_image", name)
			end
			return
		end
	end

	if not playerName or not imageURL or not room.playerList[playerName] then
		return translatedChatMessage("invalid_syntax", player)
	end


	if mouseImages[playerName] then
		tfm.exec.removeImage(mouseImages[playerName][2], false)
	end

	if imageURL == "remove" then
		mouseImages[playerName] = nil
		return
	elseif not mouseImages[playerName] or mouseImages[playerName][1] ~= imageURL then
		translatedChatMessage("new_image", playerName)
	end

	local imageID = tfm.exec.addImage(imageURL, '%'..playerName, offsetX, offsetY, nil, scale, scale, 0, opacity, 0.5, 0.5, false)
	mouseImages[playerName] = {imageURL, imageID, 1, scale, offsetX, offsetY, opacity}
end

onEvent("Keyboard", function(player, key, down)
	local img = mouseImages[player]

	if not img then return end

	if key == 2 then
		tfm.exec.removeImage(img[2], false)
		local imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[4], img[4], 0, img[7], 0.5, 0.5, false)
		img[2] = imageID
		img[3] = 1
	elseif key == 0 then
		tfm.exec.removeImage(img[2], false)
		local imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, -img[4], img[4], 0, img[7], -0.5, 0.5, false)
		img[2] = imageID
		img[3] = -1
	elseif key == 3 then
		tfm.exec.removeImage(img[2], false)
		local anchorX = img[3] == 1 and 0.5 or -0.5
		local imageID

		if down then
			imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[3] * img[4], img[4] / 2.0, 0, img[7], anchorX, 0.5, false)
		else
			imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[3] * img[4], img[4], 0, img[7], anchorX, 0.5, false)
		end

		img[2] = imageID
	end
end)

local function handleReport(playerName, cmd, quantity, args)
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

	if quantity < 2 then
		return translatedChatMessage("cmd_usage_report", playerName)
	end

	local reportedName = args[1]:lower():gsub('^+?[a-z]', string.upper)
	local reportedPlayer = room.playerList[reportedName]
	if not reportedPlayer then
		return translatedChatMessage("reported_not_here", playerName)
	end
	if reportedPlayer.id == 0 or reportedName:sub(1, 1) == "*" or bans[reportedPlayer.id] or reportedName == playerName then
		return translatedChatMessage("reported_invalid", playerName)
	end

	local reason = table.concat(args, ' ', 2, quantity)
	if #reason < 5 then
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
end

local function handleKarma(playerName, cmd, quantity, args)
	if not ranks.admin[playerName] and not ranks.mod[playerName] then
		return
	end

	if quantity < 1 then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	local target = args[1]:lower():gsub('^+?[a-z]', string.upper)
	local pdata = players_file[target]
	if not room.playerList[target] or not pdata then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	if quantity == 1 then
		if pdata.report then
			tfm.exec.chatMessage('<v>[#] <vp>' .. target .. ' can use !report.', playerName)
		else
			tfm.exec.chatMessage('<v>[#] <r>' .. target .. ' cannot use !report.', playerName)
		end
		return
	end

	inGameLogCommand(playerName, cmd, args)

	local yes = args[2] == 'yes'
	if not yes and args[2] ~= 'no' then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	if pdata.report == yes then
		tfm.exec.chatMessage('<v>[#] <bl>Nothing changed.', playerName)
		return
	end

	pdata.report = yes
	savePlayerData(target)
	tfm.exec.chatMessage('<v>[#] <n>Done.', playerName)
	logCommand(playerName, cmd, math.min(quantity, 2), args)
end

local function skipMap(playerName, cmd, quantity, args)
	if not perms[playerName] or not perms[playerName].skip_map then
		return
	end

	if quantity < 1 then
		return translatedChatMessage("invalid_syntax", playerName)
	end

	if os.time() < map_change_cd and not review_mode then
		tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", playerName)
		return
	end

	local reason = args[1]
	local mapCode = room.currentMap
	local uniquePlayers = room.uniquePlayers

	sendPacket("common", packets.rooms.skip_map, room.shortName .. "\000" .. playerName .. "\000" .. reason .. "\000" .. mapCode .. "\000" .. uniquePlayers .. "\000" .. player_count .. "\000" .. victory_count)
	
	newMap()
	inGameLogCommand(playerName, cmd, args)
end

local commandDispatch = {
	["ban"] = handleBan,
	["unban"] = handleBan,
	["pban"] = handleAdminBan,
	["punban"] = handleAdminBan,
	["addmap"] = handleMap,
	["removemap"] = handleMap,
	["bancount"] = handleSanctions,
	["baninfo"] = handleSanctions,
	["sanctions"] = handleSanctions,
	["setrank"] = handleSetrank,
	["file"] = fileActions,
	["kill"] = warnPlayer,
	["announcement"] = roomAnnouncement,
	["coins"] = editCoins,
	["christmas"] = setChristmasMap,
	["snow"] = disableSnow,
	["link"] = linkMouse,
	["size"] = changeMouseSize,
	["image"] = addMouseImage,
	["report"] = handleReport,
	["karma"] = handleKarma,
	["skip"] = skipMap,
}

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if not player or not cmd or not quantity or not args then
		return
	end
	
	local commandHandler = commandDispatch[cmd]
	if not commandHandler then
		return
	end
	
	commandHandler(player, cmd, quantity, args)
end)

onEvent("PlayerDataParsed", checkWeeklyWinners)
onEvent("PlayerDataParsed", playerDataRequests)
onEvent("OutPlayerDataParsed", playerDataRequests)

onEvent("PlayerLeft", function(player)
	reported[player] = nil
end)

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

onEvent("GameStart", function()
	system.disableChatCommandDisplay(nil)
end)