local files = {
	[1] = 20, -- maps, ranks, chats
	[2] = 21,  -- ranking, weekly
	[3] = 23 -- lowmaps, sanction
}

local to_do = {}
local pdataRequest = {}
local sanctions_file = {}
local maps_loaded = false
local sanctions_loaded = false

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

	if data.badges[3] ~= 1 then
		players_file[player].badges[3] = 1
		NewBadgeInterface:show(player, 3, 1)
		savePlayerData(player)
	end

	schedule(2, true, function(data)
		data.weekly.wl[id] = nil
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

	if data.lowmaps then
		maps_loaded = true
	end

	if data.sanction then
		sanctions_file = data.sanction

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

		sanctions_loaded = true
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
			if baninfo and (baninfo.time == 2 or baninfo.time > now) then
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

		sendPacket("common", 9, playerName .. "\000" .. time .. "\000" .. moderator .. "\000" .. minutes)
		sendBanLog(playerName, time, moderator, minutes)
	end)
end

local function inGameLogCommand(p, command, args)
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

	local minutes = tonumber(args[2])
	local targetPlayer = args[1]
	local playerID = tonumber(targetPlayer)

	if cmd == "pban" and (not minutes or minutes < 0) then
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

local function handleBancount(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] and not ranks.mod[player] then
		return
	end

	if quantity < 1 then
		translatedChatMessage("invalid_syntax", player)
		return
	end

	local requestplayer = capitalize(args[1])
	if not tonumber(requestplayer) then
		if not string.find(requestplayer, "#", 1, true) then
			requestplayer = requestplayer .. "#0000"
		end

		if in_room[requestplayer] then
			requestplayer = tostring(room.playerList[requestplayer].id)
		else
			tfm.exec.chatMessage("<v>[#] <r>"..requestplayer.." is not here. Try player id.", player)
			return
		end
	end

	if quantity < 2 then
		if sanctions_loaded then
			if sanctions_file[requestplayer] and sanctions_file[requestplayer].time then

				local minutes
				if sanctions_file[requestplayer].time == 0 then
					minutes = 0
				elseif sanctions_file[requestplayer].time == 2 then
					minutes = 2
				else
					minutes = math.floor((sanctions_file[requestplayer].time - os.time()) / 1000 / 60)
				end

				local banLevel = sanctions_file[requestplayer].level or 0

				tfm.exec.chatMessage("<v>[#] <PT>" .. capitalize(args[1]) .. " <j>have <PT>" .. banLevel .. "</PT> bans in record and currently banned for <PT>" .. minutes .. "</PT> minutes.", player)		
			else
				tfm.exec.chatMessage("<v>[#] <j>" .. capitalize(args[1]) .. " has no ban.", player)
				return
			end
		else
			tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
			schedule(3, false, function(data)
				if data.sanction and data.sanction[requestplayer] and data.sanction[requestplayer].time then

					local minutes
					if data.sanction[requestplayer].time == 0 then
						minutes = 0
					elseif data.sanction[requestplayer].time == 2 then
						minutes = 2
					else
						minutes = math.floor((data.sanction[requestplayer].time - os.time()) / 1000 / 60)
					end
					
					local banLevel = data.sanction[requestplayer].level or 0

					tfm.exec.chatMessage("<v>[#] <PT>" .. capitalize(args[1]) .. " <j>have <PT>" .. banLevel .. "</PT> bans in record and currently banned for <PT>" .. minutes .. "</PT> minutes.", player)		
				else
					tfm.exec.chatMessage("<v>[#] <j>" .. capitalize(args[1]) .. " has no ban.", player)
					return
				end
			end)
		end
	elseif args[2] == "reset" and ranks.admin[player] then
		tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
		schedule(3, true, function(data)
			if data.sanction and data.sanction[requestplayer] and data.sanction[requestplayer].level then
				data.sanction[requestplayer].level = 0

				tfm.exec.chatMessage("<v>[#] <j> ".. requestplayer .. "'s ban count has been reset.", player)		
			else
				tfm.exec.chatMessage("<v>[#] <j>" .. requestplayer .. " has no ban.", player)
				return
			end
		end)
	end
end

local function warnPlayer(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] and not ranks.mod[player] then
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

	if not ranks.admin[player] then
		logCommand(player, "kill", math.min(quantity, 2), args)
		sendPacket("common", 10, requestplayer .. "\000" .. killedTime .. "\000" .. player)
	end

	schedule_player(requestplayer, true, function(pdata)
		pdata.killed = os.time() + killedTime * 60 * 1000
		pdata.kill = killedTime

		tfm.exec.chatMessage("<v>[#] <V>"..requestplayer.. " <j>can't use their powers for <b>"..killedTime.."</b> minutes.", nil)
		translatedChatMessage("killed", requestplayer, killedTime)


		system.loadPlayerData(requestplayer)
	end)
end

local function handleSetrank(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.bot[player] then
		return
	end

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
		if pdata.bannedby then
            local extra = "unbanned"
            if pdata.banned and pdata.banned > 0 then
                local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
                extra = "banned <V>" .. minutes .. " <j>minutes"
            end
            local banCount = pdata.bancount or "none"
            tfm.exec.chatMessage("<v>[#] <j>" .. requestplayer .. " has been " .. extra .. " by <V>"..pdata.bannedby.." <j>and have <V>"..banCount.." <j>bans in record.", player)
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
			if weeklyfile and weeklyfile.ts and weeklyfile.wl then
				local currentList = {}

				for name in pairs(weeklyfile.wl) do
					table.insert(currentList, name)
				end

				local currentWeek =  table.concat(currentList, ",")
				tfm.exec.chatMessage("<v>[#] <j>Timestamp: "..weeklyfile.ts, player)
				tfm.exec.chatMessage("<v>[#] <j>Current week: "..currentWeek, player)
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
			tfm.exec.chatMessage("<v>[#] <j>Level: "..playerFile.level, player)
		end
	end
end

function roomAnnouncement(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.manager[player] then
		return
	end

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

	if not in_room[playerName] then
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

		local selectedSkin = shop_items[skinType][skinNumber]

		if (not skinType or not skinNumber) or (not tonumber(skinType) or not tonumber(skinNumber)) or (selectedSkin == nil) then
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
	if not ranks.admin[player] then 
		if mouseImages[player] then
			tfm.exec.removeImage(mouseImages[player][2], false)
			tfm.exec.killPlayer(player)
			mouseImages[player] = nil
		end
		return 
	end

	local playerName = args[1]
	local imageURL = args[2]

	if not playerName or not imageURL or not room.playerList[playerName] then
		return translatedChatMessage("invalid_syntax", player)
	end

	local scale = tonumber(args[3]) or 1
	local offsetX = tonumber(args[4]) or 0
	local offsetY = tonumber(args[5]) or 0
	local opacity = tonumber(args[6]) or 1

	if mouseImages[playerName] then
		tfm.exec.removeImage(mouseImages[playerName][2], false)
	end

	if imageURL == "remove" then
		mouseImages[playerName] = nil
		return
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
	["file"] = fileActions,
	["kill"] = warnPlayer,
	["announcement"] = roomAnnouncement,
	["coins"] = editCoins,
	["christmas"] = setChristmasMap,
	["snow"] = disableSnow,
	["link"] = linkMouse,
	["size"] = changeMouseSize,
	["image"] = addMouseImage,
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