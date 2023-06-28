local files = {
	[1] = 20, -- maps, ranks, chats
	[2] = 22 -- lowmaps, banned
}

local loaded = false
local saving = {}
local to_do = {}
local ban_request = {}

local file_actions = {
	ban_change = {2, true, function(data, id, value, old)
		id = tostring(id)
		if not old or tonumber(old) == data.banned[id] then
			data.banned[id] = value
		end
	end},

    high_map_change = {1, true, function(data, map, add)
		for index = #data.maps, 1, -1 do
			if data.maps[index] == map then
				if not add then
					table.remove(data.maps, index)
				end
				return
			end
		end

		if add then
			data.maps[#data.maps + 1] = map
		end
	end},

	low_map_change = {2, true, function(data, map, add)
		for index = 1, #data.lowmaps do
			if data.lowmaps[index] == map then
				if not add then
					table.remove(data.lowmaps, index)
				end
				return
			end
		end

		if add then
			data.lowmaps[#data.lowmaps + 1] = map
		end
	end},

    modify_rank = {1, true, function(data, player, newrank)
		data.ranks[player] = newrank
	end},
}

local function schedule(action, arg1, arg2, arg3)
	to_do[#to_do + 1] = {file_actions[action], arg1, arg2, arg3}
	next_file_check = os.time() + 4000
end


onEvent("FileLoaded", function(file, data)
	data = filemanagers[file]:load(data)
	file = tonumber(file)
	local save = false

	local action
	for index = 1, #to_do do
		action = to_do[index][1]
		if files[action[1]] == file then
			if action[2] then
				save = true
			end

			action[3](data, to_do[index][2], to_do[index][3])
			to_do[index] = nil
		end
	end
	for index = #to_do, 1, -1 do
		if not to_do[index] then
			table.remove(to_do, index)
		end
	end

	eventGameDataLoaded(data)

	if data.banned then
		local now = os.time()
		local count, to_remove = 0

		-- wipe expired bans
		for id, value in next, data.banned do
			if value > 1 and now >= value then
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
			data.banned[to_remove[index]] = nil
		end
	end

	if save then
		eventSavingFile(tostring(file), data)
	end
end)

local function banPlayer(player, data, requester, ban)
	if not data.bancount or not data.playerid then 
		tfm.exec.chatMessage("<v>[#] <r>"..player.. " must have joined any parkour room after the last update. [v"..data.v.."]", requester) 
		return
	end

	if ban then
		if data.banned and (data.banned == 2 or os.time() < data.banned) then tfm.exec.chatMessage("<v>[#] <r>"..player.. " has already been banned.", requester) return end
			data.bancount = data.bancount + 1
			if data.bancount < 4 then
				data.banned = os.time()+tonumber((data.bancount)*1440)*60*1000
				schedule("ban_change", data.playerid, data.banned)
				tfm.exec.chatMessage("<v>[#] <r>"..player.. " has banned for " ..((data.bancount)*1440).. " minutes.", requester)
			else
				schedule("ban_change", data.playerid, 1)
				data.banned = 2
				tfm.exec.chatMessage("<v>[#] <r>"..player.. " has permbanned.", requester)
			end
		system.savePlayerData(player, json.encode(data))
	else
		if data.banned and (data.banned == 2 or os.time() < data.banned) then 
			data.banned = nil
			schedule("ban_change", data.playerid, 0)
			tfm.exec.chatMessage("<v>[#] <r>"..player.. " has unbanned.", requester)

			data.bancount = data.bancount - 1
			system.savePlayerData(player, json.encode(data))
		else
			tfm.exec.chatMessage("<v>[#] <r>"..player.. " not banned (yet).", requester) 
			return 
		end
	end
end

local function checkBanRequest(player, data)
	local fetch = ban_request[player]
	if fetch then

		if fetch[3] == "bancount" then
			tfm.exec.chatMessage(data.bancount, fetch[1])
			tfm.exec.chatMessage("<v>[#] <r>"..player.. " have " ..data.bancount.. " bans in record.", fetch[1]) 

			return
		end

		if fetch[3] == "resetbancount" then
			data.bancount = 0
			system.savePlayerData(player, data)
			tfm.exec.chatMessage("<v>[#] <r>"..player.. "'s bans has been reset", fetch[1]) 
			return
		end

		local isban = fetch[3]
		local requester = fetch[1]
		if isban then
			banPlayer(player, data, requester, true)
		else
			banPlayer(player, data, requester, false)
		end
		ban_request[player] = nil
	end
end

function showChatCommands(p, command, args)
	local commandtext = table.concat(args, " ")
	for playername, player in pairs(tfm.get.room.playerList) do
		if ranks.admin[playername] or ranks.mod[playername] then
			tfm.exec.chatMessage("<BL>Ξ ["..p.."]<N2> !"..command.." "..commandtext, playername)
		end
	end
end

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	local max_args = quantity
	if cmd == "ban" or cmd == "unban" then -- for mods / !ban Username and !unban Username 
		if not ranks.admin[player] and not perms[player].ban then return end
		
		requestplayer = capitalize(args[1])
		if not string.find(requestplayer, "#", 1, true) then
			requestplayer = requestplayer .. "#0000"
		end

		showChatCommands(player, cmd, args)

		if quantity < 1 then 
			return tfm.exec.chatMessage("<v>[#] Provide an username.<r>", player) 
		end

		if players_file[args[1]] then 
			banPlayer(args[1], players_file[args[1]],player, cmd == "ban")
		else
			ban_request[args[1]] = {player, os.time() + 1000, cmd == "ban"}
			system.loadPlayerData(args[1])
		end

	elseif cmd == "pban" or cmd == "punban" then -- only admins / !pban [username or id] [minutes or 1 for perm] - !punban [username or id]
		if not ranks.admin[player] then return end

		if quantity < 1 then 
			return tfm.exec.chatMessage("<v>[#] Provide an username.<r>", player) 
		end

		local minutes = args[2]
		if not tonumber(args[1]) then 
			local p = args[1] and tfm.get.room.playerList[args[1]]
			playerid = p and p.id or nil

			if playerid == nil then 
				return tfm.exec.chatMessage("<v>[#] <r>You must be in the same room as the player to ban them using their username. \n<v>[>] <J>/c Recordsbot#8598 id "..args[1], player)
			end
		else
			playerid = args[1]
		end

		if cmd == "punban" then 
			schedule("ban_change", playerid, 0)
			tfm.exec.chatMessage("<v>[#] <r>"..playerid.. " has unbanned.", player)
		end

		if cmd == "pban" then
			if minutes == 1 then
			schedule("ban_change", playerid, 1)
			return tfm.exec.chatMessage("<v>[#] <r>"..playerid.. " has permbanned.", player)
			else
				if not tonumber(minutes) then 
					return tfm.exec.chatMessage(minutes .. " doesnt look like a number ", player)
				end

				minutes = os.time()+tonumber(minutes)*60*1000
				schedule("ban_change", playerid, minutes)
				tfm.exec.chatMessage("<v>[#] <r>" ..playerid.. " has banned for " ..(tonumber(args[2])).. " minutes", player)
			end
		end


	elseif cmd == "addmap" or cmd == "removemap" then -- !addmap code [low/high] or !removemap code [low/high]
		if not ranks.admin[player] and not ranks.mapper[player] and not ranks.manager[player] then
			return
		end
		
		local rotation = args[2]
		local mapcode = args[1]

		showChatCommands(player, cmd, args)

		if not tonumber(mapcode) then
			mapcode = mapcode:gsub("^@", "")
		end

		if quantity < 2 then 
			if cmd == "addmap" then
				return tfm.exec.chatMessage("<v>[#] <r>!addmap [code] [low/high]", player)
			elseif cmd == "removemap" then
				return tfm.exec.chatMessage("<v>[#] <r>!removemap [code] [low/high]", player)
			end
		end

		if rotation ~= "low" and rotation ~= "high" then 
			return tfm.exec.chatMessage("<v>[#] <r>Select a priority option: low, high", player)
		end

		if not tonumber(mapcode) then
			return tfm.exec.chatMessage("<v>[#] <r>"..mapcode.." doesn't look like a map code!?", player)  
		end

		local isAddMap = (cmd == "addmap")
		schedule(rotation .. "_map_change", tonumber(mapcode), isAddMap)

		if isAddMap then
			tfm.exec.chatMessage("<v>[#] <r>Map @"..mapcode.." adding to the "..rotation.." priority list...", player)
		else
			tfm.exec.chatMessage("<v>[#] <r>Map @"..mapcode.." removing from the "..rotation.." priority list...", player)
		end

	elseif cmd == "bancount" then -- only admins / !bancount username or !bancount username reset to reset bancount
		if not ranks.admin[player] then return end
		if quantity < 1 then 
			return tfm.exec.chatMessage("<v>[#] <r>!bancount PlayerName or !bancount PlayerName reset", player) 
		end

		showChatCommands(player, cmd, args)

			if not tonumber(args[1]) then
				requestplayer = capitalize(args[1])
				if not string.find(requestplayer, "#", 1, true) then
					requestplayer = requestplayer .. "#0000"
				end
			end

			if quantity < 2 then 
				if players_file[requestplayer] then 
					local file = players_file[args[1]]
					local getPlayerBanCount = file.bancount
					tfm.exec.chatMessage(getPlayerBanCount, player)
					tfm.exec.chatMessage("<v>[#] <r>"..args[1].. " have " ..getPlayerBanCount.. " bans in record.", player) 

				else
					ban_request[requestplayer] = {player, os.time() + 1000, "bancount"}
					system.loadPlayerData(requestplayer)
				end
			return
			end

			if args[2] == "reset" then
				if players_file[requestplayer] then 
					local file = players_file[args[1]]
					file.bancount = 0
					savePlayerData(requestplayer)
					tfm.exec.chatMessage("<v>[#] <r>"..args[1].. "'s bans has been reset", player) 
				else
					ban_request[requestplayer] = {player, os.time() + 1000, "resetbancount"}
					system.loadPlayerData(requestplayer)
				end
			return
		end 

    elseif cmd == "setperm" then -- !setperm username [0 = remove / 1 = add] [bot,manager,mod,mapper,trainee,translator,hidden]
		if not ranks.admin[player] and not ranks.bot[player] then return end
		local p = args[1]
        local action = args[2]
        local rank = args[3]

		if quantity < 2 then 
			return tfm.exec.chatMessage("<v>[#] <r>!setperm [PlayerName#TAG] [action] [rank]", player) 
		end

		if not tonumber(action) then
			return tfm.exec.chatMessage("<v>[#] <r>Action must be 1 or 0", player)
		end

		if tonumber(action) > 1 or tonumber(action) < 0 then 
			return tfm.exec.chatMessage("<v>[#] <r>Action must be 1 or 0", player)
		end

		if rank ~= "bot" and rank ~= "manager" and rank ~= "mod" and rank ~= "mapper" and rank ~= "trainee" and rank ~= "translator" and rank ~= "hidden" then
			return tfm.exec.chatMessage("<v>[#] <r>Invalid rank, available ranks: bot, manager, mod, mapper, trainee, translator, hidden", player)
		end

        if not player_ranks[p] then
			player_ranks[p] = {
				[rank] = action == "1"
			}
		else
			player_ranks[p][rank] = action == "1"
		end

		local id = 0
		for rank, has in next, player_ranks[p] do
			if has then
				id = id + ranks_id[rank]
			end
		end

		if id == 0 then
			player_ranks[p] = nil
			id = nil
		end

		schedule("modify_rank", p, id)
		if tonumber(action) == 1 then 
			tfm.exec.chatMessage("<v>[#] <r>"..p.."'s rank has been set to "..rank, player)
		else
			tfm.exec.chatMessage("<v>[#] <r>"..p.." is no longer "..rank, player)
		end
end end)

onEvent("PlayerDataParsed", function(player, data)
	checkBanRequest(player, data)
end)

onEvent("OutPlayerDataParsed", checkBanRequest)


onEvent("Loop", function(elapsed)
	local now = os.time()

	local to_remove, count = {}, 0
	for player, data in next, ban_request do
		if now >= data[2] then
			count = count + 1
			to_remove[count] = player
			translatedChatMessage("cant_load_profile", data[1], player)
		end
	end

	for idx = 1, count do
		ban_request[to_remove[idx]] = nil
	end
end)