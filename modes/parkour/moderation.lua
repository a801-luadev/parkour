local files = {
	[1] = 20, -- maps, ranks, chats
	[2] = 22, -- lowmaps, banned
	[3] = 23 -- sanction
}

local to_do = {}
local pdataRequest = {}
local sanctions_file = {}
local maps_loaded = false

local function schedule(fileid, save, callback)
	to_do[#to_do + 1] = { fileid, save, callback }
end

local function schedule_player(name, save, callback, timeoutCallback)
	if players_file[name] then
		callback(players_file[name])
		if save then 
			system.savePlayerData(name, json.encode(players_file[name]))
		end
	else
		pdataRequest[name] = { callback, os.time() + 1000, save, timeoutCallback }
		system.loadPlayerData(name)
	end
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

local function sendBanLog(playerName, time, moderator, minutes)
	if not time then
		tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned.", moderator)
	elseif time > 2 then
		tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned for " .. minutes .. " minutes.", moderator)
	elseif time == 2 then
		tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned permanently.", moderator)
	elseif time == 1 then
		tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned. (pending)", moderator)
	else
		tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned. (pending)", moderator)
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

	if data.lowmaps then
		maps_loaded = true
	end

	if data.sanction then
		sanctions_file = data.sanction

		local now = os.time()
		local count, to_remove = 0

		-- wipe expired bans
		for id, sanctiondata in pairs(data.sanction) do
			if sanctiondata.time and sanctiondata.time > 2 and now >= sanctiondata.time then
				if count == 0 then
					count = 1
					to_remove = {id}
				else
					count = count + 1
					to_remove[count] = id
				end
			end
		end

		for index = 1, count do
			local id = to_remove[index]
			if data.sanction[id] then
				data.sanction[id] = nil
			end
		end

		local playerList = room.playerList
		local id, banInfo, banDays

		for player, pdata in next, players_file do
			if playerList[player] and in_room[player] then
				id = tostring(playerList[player].id)
				banInfo = id and data.sanction[id]

				if banInfo and banInfo.timestamp ~= pdata.lastsanction then
					if banInfo.time == 1 then -- !ban
						pdata.bancount = pdata.bancount + 1

						if pdata.bancount == 1 then
							pdata.banned = now + 86400000 -- 1 day
						elseif pdata.bancount == 2 then
							pdata.banned = now + 86400000 * 7
						elseif pdata.bancount == 3 then
							pdata.banned = now + 86400000 * 30
						else
							pdata.banned = 2 -- permanent ban
						end
					elseif banInfo.time == 0 then -- !punban
						pdata.banned = nil
					elseif banInfo.time == -1 then -- !unban
						pdata.bancount = pdata.bancount - 1
						pdata.banned = nil
					else
						pdata.banned = banInfo.time
					end

					pdata.lastsanction = banInfo.timestamp
					pdata.bannedby = banInfo.info
					
					savePlayerData(player)
					
					if pdata.banned == nil then
						data.sanction[id] = nil
						save = true
					else
						banInfo.time = pdata.banned
						save = true
					end

					local minutes = pdata.banned and math.floor((pdata.banned - os.time()) / 1000 / 60)
					for moderator in pairs(room.playerList) do
						if ranks.admin[moderator] or ranks.mod[moderator] then
							sendBanLog(player, pdata.banned, moderator, minutes)
						end
					end
				end

				if pdata.banned and (pdata.banned == 2 or os.time() < pdata.banned) then
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
			if baninfo and (baninfo.time == 1 or baninfo.time > now) then
				tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " is banned already.", moderator)
				return
			end
		else
			if not baninfo or baninfo.time < 1 then
				tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " doesn't seem to be banned.", moderator)
				return
			end
		end

		data.sanction[playerID] = {
			timestamp = now,
			time = time,
			info = moderator,
		}

		sendBanLog(playerName, time, moderator, minutes)
	end)
end

local function logCommand(p, command, args)
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

	logCommand(player, cmd, args)

	local targetPlayer = args[1]
	local moderator = player
	local time = cmd == 'ban' and 1 or -1 -- ban time changes depending on players previous bans

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
		if not pdata.bancount or not pdata.playerid then
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

	local minutes = tonumber(args[2])
	local targetPlayer = args[1]
	local playerID = tonumber(targetPlayer)

	if cmd == "pban" and not minutes or minutes < 0 then
		return translatedChatMessage("invalid_syntax", player)
	end

	local sanctionTime

	if cmd == "pban" then
		if minutes == 1 then
			sanctionTime = 2
		else
			sanctionTime = nil
		end
	else
		sanctionTime = 0
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
	logCommand(player, cmd, args)

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
			schedule(2, true, function(data)
				updateMapList(data.lowmaps, mapcode, true)
				tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
			end)
		else
			schedule(1, true, function(data)
				updateMapList(data.maps, mapcode, true)
				tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
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
				tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the low priority list: " .. table.concat(removeHigh, ", "), player)
			end)
		end

		if #removeLow > 0 then
			schedule(2, true, function(data)
				for i = 1, #removeLow do
					updateMapList(data.lowmaps, removeLow[i], false)
				end
				tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the high priority list: " .. table.concat(removeLow, ", "), player)
			end)
		end
	end
end

local function handleBancount(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	if quantity < 1 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

	local requestplayer = capitalize(args[1])
	if not string.find(requestplayer, "#", 1, true) then
		requestplayer = requestplayer .. "#0000"
	end

	if quantity < 2 then
		schedule_player(requestplayer, false, function(pdata)
			tfm.exec.chatMessage("<v>[#] <r>" .. requestplayer .. " have " .. pdata.bancount .. " bans in record.", player)
		end)
	elseif args[2] == "reset" then
		schedule_player(requestplayer, true, function(pdata)
			pdata.bancount = 0
			tfm.exec.chatMessage("<v>[#] <r>" .. requestplayer .. "'s ban count has been reset.", player)
		end)
	end
end

local function handleSetrank(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	if args[1] == player then
		return tfm.exec.chatMessage("<v>[#] <r>You can't change your rank.", player)
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
end

local function handleBanInfo(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	if quantity < 1 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

	local requestplayer = capitalize(args[1])
	if not string.find(requestplayer, "#", 1, true) then
		requestplayer = requestplayer .. "#0000"
	end

	schedule_player(requestplayer, false, function(pdata)
		if pdata.bannedby and pdata.banned then
			local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
			local banCount = pdata.bancount or "none"
			tfm.exec.chatMessage("<v>[#] <j>" .. requestplayer .. " has been banned for <V>" .. minutes .. " <j>minutes by <V>"..pdata.bannedby.." <j>and have <V>"..banCount.." <j>bans in record.", player)
		else
			tfm.exec.chatMessage("<v>[#] <j>" .. requestplayer .. " has no ban.", player)
		end
	end)
end

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
			if weeklyfile and weeklyfile.ts and weeklyfile.cw then
				local currentList = {}

				for name in pairs(weeklyfile.cw) do
					table.insert(currentList, name)
				end

				local currentWeek =  table.concat(currentList, ",")
				tfm.exec.chatMessage("<v>[#] <j>Timestamp: "..weeklyfile.ts, player)
				tfm.exec.chatMessage("<v>[#] <j>Current week: "..currentWeek, player)

				if not weeklyfile.lw then return end
				
				local lastList = {}

				for name in pairs(weeklyfile.lw) do
					table.insert(lastList, name)
				end

				local lastWeek =  table.concat(lastList, ",")
				tfm.exec.chatMessage("<v>[#] <j>Last week: "..lastWeek, player)
			else
				tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
			end

		elseif fileAction == "last" then
			tfm.exec.chatMessage("<v>[#] <j>Last weekly reset: "..timed_maps.week.last_reset, player)

		elseif fileAction == "add" then

			if quantity < 3 then
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
		end
	end

	if fileName == "sanction" then
		if not sanctions_file then 
			tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet.", player)
			return
		end

		local fileAction = args[2]

		if fileAction == "list" then
			local page = tonumber(args[3]) or 1
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
			if not tonumber(args[2]) then
				tfm.exec.chatMessage("<v>[#] <j>"..args[2].." doesn't seem like player id?", player)
				return
			end

			if not sanctions_file[args[2]] then 
				tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
				return
			end

			local playerFile = sanctions_file[args[2]]
			tfm.exec.chatMessage("<v>[#] <j>Timestamp: "..playerFile.timestamp, player)
			tfm.exec.chatMessage("<v>[#] <j>Time: "..playerFile.time, player)
			tfm.exec.chatMessage("<v>[#] <j>Info: "..playerFile.info, player)
		end
	end
end

local function migrateBans(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

	schedule(2, false, function(bdata)
		tfm.exec.chatMessage("<v>[#] <j>Fetched.", player)
		schedule(3, true, function(sdata)
			for playerID, times in pairs(bdata.banned) do
				if times == 1 then times = 2 end
				sdata.sanction[playerID] = {
					timestamp = 0,
					time = times,
					info = "-",
				}
			end
			tfm.exec.chatMessage("<v>[#] <j>Migrated.", player)
		end)
	end)

end

local commandDispatch = {
	["ban"] = handleBan,
	["unban"] = handleBan,
	["pban"] = handleAdminBan,
	["punban"] = handleAdminBan,
	["addmap"] = handleMap,
	["removemap"] = handleMap,
	["bancount"] = handleBancount,
	["setrank"] = handleSetrank,
	["baninfo"] = handleBanInfo,
	["migratebans"] = migrateBans,
	["file"] = fileActions
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

onEvent("PlayerDataParsed", playerDataRequests)
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

onEvent("GameStart", function()
	system.disableChatCommandDisplay(nil)
end)