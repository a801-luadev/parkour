do
-- requests waiting for eventSanctionDataLoaded
local ban_requests = {} -- target -> list of {moderator, time, ts}
local sanction_requests = {} -- target -> moderator -> needs a sanction file lookup
local reported = {}

-- false until the first sanction load has filled bans (game.lua holds wins
-- until then)
sanction_ready = false

-- bans (game.lua: id -> sanction ts) of the active bans in the sanction file.
-- Globals: modules are close to the 200 locals limit
do
	local ban_ends = {} -- id -> end of the active temp bans in bans
	local decoded_ts -- the sanction.ts bans was decoded from

	-- bans from the file, unless it's the one bans already has
	function decodeBans(sanction)
		if sanction.ts == decoded_ts then return end
		SanctionRW.decodeActive(sanction, bans, ban_ends)
		decoded_ts = sanction.ts
	end

	-- our own save: bans already has its rows
	function setDecodedTs(ts)
		decoded_ts = ts
	end

	-- bans for a row
	function cacheBan(id, ts, time, now)
		if time == 2 or time > now then
			bans[id] = ts
			ban_ends[id] = time ~= 2 and time or nil
		else
			bans[id] = nil
			ban_ends[id] = nil
		end
	end

	-- removes the temp bans that ended
	function dropEndedBans(now)
		local ended, count = {}, 0
		for id, stop in next, ban_ends do
			if stop <= now then
				count = count + 1
				ended[count] = id
			end
		end
		for index = 1, count do
			ban_ends[ended[index]] = nil
			bans[ended[index]] = nil
		end
	end
end

local queueSanctionJob, printSanctions, viewSanction, updateSanctions

-- the sanction file: jobs and the sync of players' data
do
	-- jobs waiting for the sanction file, run in order. ts: when the command
	-- was typed, in whole seconds as the file keeps it
	--   {"set", id, name, time, moderator, minutes, ts}
	--   {"reset", id, name, player}
	--   {"view", id, name, player}
	--   {"writeback", id, name, ts, time, moderator, level}: a row only pdata has
	local sanction_jobs = {_count = 0}
	local loaded_sanction -- data.sanction of the last load, for views and lookups
	-- rows we wrote, until a later load shows them: id -> {ts, time, moderator, level}
	local unconfirmed = {}

	queueSanctionJob = function(job)
		sanction_jobs._count = sanction_jobs._count + 1
		sanction_jobs[sanction_jobs._count] = job
		scheduleFile("sanction")
	end

	local function roomPlayerById(id)
		local info
		for player in next, in_room do
			info = room.playerList[player]
			if info and info.id == id then
				return player
			end
		end
	end

	local function writeRow(sanction, id, ts, time, moderator, level, now)
		SanctionRW.write(sanction, id, ts, time, SanctionRW.modIndex(sanction, moderator), level)
		cacheBan(id, ts, time, now)
		unconfirmed[id] = {ts, time, moderator, level}
	end

	-- packets.rooms.ban_logs. prev: {ts, time, moderator, level} or nil; kind:
	-- cmd, pdata (a pdata row written back) or correction (pdata corrected)
	local function sendBanLogPacket(id, name, time, moderator, minutes, prev, ts, level, kind)
		sendPacket(
			"common",
			packets.rooms.ban_logs,
			table.concat({
				id, name, time, moderator, minutes,
				prev and prev[1] or "-",
				prev and prev[2] or "-",
				prev and prev[3] or "-",
				prev and prev[4] or "-",
				ts, level, kind,
			}, "\000")
		)
	end

	local function sendBanLog(player, time, target, minutes)
		if not time then
			sendChatFmt("<j>%s has been unbanned.", target, player)
		elseif time > 2 then
			sendChatFmt("<j>%s has been banned for %s minutes.", target, player, minutes)
		elseif time == 2 then
			sendChatFmt("<j>%s has been banned permanently.", target, player)
		else
			sendChatFmt("<j>%s has been unbanned.", target, player)
		end
	end

	-- a file row newer than the player's data: applied to it and announced
	local function applyRow(player, pdata, id, ts, time, moderator, level, now)
		local was_banned = bans[id] or pdata.banned == 2 or (pdata.banned or 0) > now

		pdata.bancount = time == 2 and 4 or level
		pdata.lastsanction = ts
		pdata.bannedby = moderator
		pdata.banned = time

		savePlayerData(player)

		local minutes = math.ceil((time - now) / 1000 / 60)
		if ranks.hidden[moderator] then
			for staff in next, in_room do
				if ranks.admin[staff] or ranks.mod[staff] then
					sendBanLog(player, time, staff, minutes)
				end
			end
		else
			sendBanLog(player, time, nil, minutes)
		end

		cacheBan(id, ts, time, now)
		if time == 2 or time > now then
			enableSpecMode(player, true)
		elseif was_banned then
			enableSpecMode(player, false)
		end
	end

	-- pdata vs the file row of a player in the room: the newer ts wins. With
	-- can_write (on a load), a row only pdata has is written back, and an
	-- archived or legacy ban that only pdata has is corrected once. Returns
	-- whether it changed the file, whether it changed pdata, and (without
	-- can_write) whether pdata has a row to write back
	local function syncPlayer(player, pdata, id, sanction, now, can_write)
		local ps = pdata.lastsanction and math.floor(pdata.lastsanction / 1000) or -1
		local ts, time, mod, level = SanctionRW.find(sanction, id)

		if ts and ts / 1000 > ps then
			applyRow(player, pdata, id, ts, time, mod ~= 0 and sanction.mods[mod] or nil, level, now)
			return false, true
		end
		if ts and ts / 1000 == ps then return end

		if ts or ps >= (sanction.archived or 0) then
			if not can_write then return false, false, true end

			local ptime = pdata.banned or 0
			local plevel = ptime == 2 and 4 or pdata.bancount or 0
			writeRow(sanction, id, pdata.lastsanction, ptime, pdata.bannedby, plevel, now)
			sendBanLogPacket(
				id, player, ptime, pdata.bannedby or "-",
				ptime > 2 and math.floor((ptime - pdata.lastsanction) / 60000 + 0.5) or 0,
				ts and {ts, time, SanctionRW.modName(sanction, mod), level},
				SanctionRW.fileTs(pdata.lastsanction), plevel, "pdata"
			)
			return true
		end

		if not can_write then return end

		-- archived or legacy: corrected to unbanned level 0, never written to the file
		local banned = pdata.banned
		if not (banned == 2 or (banned or 0) > now or (pdata.bancount or 0) > 0) then return end

		sendBanLogPacket(
			id, player, 0, "-", 0,
			{pdata.lastsanction or "-", banned or "-", pdata.bannedby or "-", pdata.bancount or "-"},
			pdata.lastsanction or "-", 0, "correction"
		)
		pdata.banned = 0
		pdata.bancount = 0
		savePlayerData(player)

		cacheBan(id, 0, 0, now)
		enableSpecMode(player, false)
		return false, true
	end

	printSanctions = function(target, kind, name, pid, timestamp, time, level, mod, minutes)
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

		sendChatFmt(
			"<n>(%s) <n2>%s</n2> %s%s%s%s%s<g>[level %s] [ts %s] [pid %s]",
			target,
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
		)
	end

	-- answers a view from the sanction file (data.sanction)
	local function printSanctionOnLoad(sanction, targetID, targetName, player)
		local ts, time, mod, level = SanctionRW.find(sanction, targetID)
		if not ts then
			sendChatFmt("<r>%s not found in file data", player, targetID)
			return
		end
		printSanctions(
			player,
			'file',
			targetName or targetID,
			targetID,
			ts,
			time,
			level,
			tostring(SanctionRW.modName(sanction, mod))
		)
	end

	-- runs the queued jobs in order, returns true if one changed the file
	local runSanctionJobs
	do
		-- returns true if it changed the file
		local function setSanction(sanction, playerID, playerName, time, moderator, minutes, ts, now)
			local pts, ptime, pmod, plevel = SanctionRW.find(sanction, playerID)

			-- a row written after the command was typed wins
			if pts and pts > ts then
				sendChatFmt("<r>%s has a newer sanction, command dropped.", moderator, playerName)
				return
			end

			time = time or (ts + minutes * 60 * 1000)

			if time > 0 then
				if pts and (ptime == 2 or ptime > now) and not minutes then
					sendChatFmt("<r>%s is banned already.", moderator, playerName)
					return
				end
			else
				if not pts or ptime < 1 then
					sendChatFmt("<r>%s doesn't seem to be banned.", moderator, playerName)
					return
				end
			end

			local sanctionLevel = plevel or 0
			if time == 1 then
				sanctionLevel = math.min(4, sanctionLevel + 1)
				if sanctionLevel == 1 then
					time = ts + 86400000 -- 1 day
					minutes = 1440
				elseif sanctionLevel == 2 then
					time = ts + 86400000 * 7
					minutes = 10080
				elseif sanctionLevel == 3 then
					time = ts + 86400000 * 30
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
			-- perma bans are always level 4
			if time == 2 then
				sanctionLevel = 4
			end

			local prev = pts and {pts, ptime, SanctionRW.modName(sanction, pmod), plevel}
			writeRow(sanction, playerID, ts, time, moderator, sanctionLevel, now)

			sendBanLogPacket(playerID, playerName, time, moderator, minutes, prev, ts, sanctionLevel, "cmd")
			sendBanLog(playerID, time, moderator, minutes)
			return true
		end

		-- returns true if it changed the file
		local function resetSanction(sanction, targetID, targetName, player)
			local ts, time, mod, level = SanctionRW.find(sanction, targetID)
			if time == 2 then
				sendChatFmt("<r>Can't reset %s: perma bans are always level 4, unban first.", player, targetName or targetID)
				return
			end
			if not ts or level == 0 then
				sendChatFmt("<j>%s's sanction level is already at zero.", player, targetName or targetID)
				return
			end

			SanctionRW.setLevel(sanction, targetID, 0)
			sendChatFmt("<j>%s's sanction level has been reset.", player, targetName or targetID)
			return true
		end

		-- a row only the player's data had (their room closed before saving
		-- it); returns true if it changed the file
		local function writeBack(sanction, id, name, ts, time, moderator, level, now)
			local pts, ptime, pmod, plevel = SanctionRW.find(sanction, id)
			if pts and pts >= SanctionRW.fileTs(ts) then return end
			if not pts and ts / 1000 < (sanction.archived or 0) then return end

			if time == 2 then
				level = 4
			end
			writeRow(sanction, id, ts, time, moderator, level, now)
			sendBanLogPacket(
				id, name, time, moderator or "-",
				time > 2 and math.floor((time - ts) / 60000 + 0.5) or 0,
				pts and {pts, ptime, SanctionRW.modName(sanction, pmod), plevel},
				SanctionRW.fileTs(ts), level, "pdata"
			)
			return true
		end

		runSanctionJobs = function(sanction, now)
			local jobs = sanction_jobs
			if jobs._count == 0 then return end

			local changed, job, kind
			local written = {}
			for index = 1, jobs._count do
				job = jobs[index]
				jobs[index] = nil
				kind = job[1]

				if kind == "set" then
					if setSanction(sanction, job[2], job[3], job[4], job[5], job[6], job[7], now) then
						changed = true
						written[job[2]] = true
					end
				elseif kind == "writeback" then
					if writeBack(sanction, job[2], job[3], job[4], job[5], job[6], job[7], now) then
						changed = true
					end
				elseif kind == "reset" then
					if resetSanction(sanction, job[2], job[3], job[4]) then
						changed = true
					end
				else
					printSanctionOnLoad(sanction, job[2], job[3], job[4])
				end
			end
			jobs._count = 0

			-- players here follow the rows the jobs wrote
			local player, pdata
			for id in next, written do
				player = roomPlayerById(id)
				pdata = player and players_file[player]
				if pdata then
					syncPlayer(player, pdata, id, sanction, now, false)
					checkBan(player, pdata, id)
				end
			end

			return changed
		end
	end

	-- rows we wrote that a load doesn't show (another room saved over them
	-- from an older copy) are written again; returns true if it changed the file
	local function confirmRows(sanction, now)
		local changed, ts
		local confirmed, count = {}, 0
		for id, row in next, unconfirmed do
			ts = SanctionRW.find(sanction, id)
			if ts and ts >= SanctionRW.fileTs(row[1]) then
				count = count + 1
				confirmed[count] = id
			else
				SanctionRW.write(sanction, id, row[1], row[2], SanctionRW.modIndex(sanction, row[3]), row[4])
				cacheBan(id, row[1], row[2], now)
				changed = true
			end
		end
		-- removed after the traversal: LuaJ's next fails on a removed key
		for index = 1, count do
			unconfirmed[confirmed[index]] = nil
		end
		return changed
	end

	onEvent("GameDataLoaded", function(data, fileid)
		local sanction = data.sanction
		if not sanction then return end

		local now = os.time()
		decodeBans(sanction)
		dropEndedBans(now)
		loaded_sanction = sanction

		local save = SanctionRW.prune(sanction, now)
		if confirmRows(sanction, now) then
			save = true
		end

		-- players here: their data vs the file, before the jobs read the levels
		local pdata, info
		for player in next, in_room do
			pdata = players_file[player]
			info = room.playerList[player]

			if pdata and info then
				if syncPlayer(player, pdata, info.id, sanction, now, true) then
					save = true
				end
				checkBan(player, pdata, info.id)
			end
		end

		if runSanctionJobs(sanction, now) then
			save = true
		end

		if save then
			sanction.ts = now
			setDecodedTs(now)
			eventSavingFile(fileid, data)
		end

		sanction_ready = true
	end)

	-- on join, before game.lua's checkBan: their data vs the last loaded file.
	-- A row only their data has is written back by a job, so it reaches the
	-- file even if they leave before the load; corrections wait for a load
	function syncJoinSanction(player, data)
		local info = room.playerList[player]
		if not (data and loaded_sanction and info and in_room[player]) then return end

		local _, _, newer = syncPlayer(player, data, info.id, loaded_sanction, os.time(), false)
		if newer then
			queueSanctionJob({
				"writeback", info.id, player, data.lastsanction,
				data.banned or 0, data.bannedby, data.bancount or 0,
			})
		end
	end

	-- answered at once from the last load, or queued until the first one
	viewSanction = function(targetID, targetName, player, shownAs)
		if loaded_sanction then
			printSanctionOnLoad(loaded_sanction, targetID, targetName, player)
			return
		end

		sendChatFmt("Checking file data for %s's sanctions...", player, shownAs)
		queueSanctionJob({"view", targetID, targetName, player})
	end

	updateSanctions = function(playerID, playerName, time, moderator, minutes, ts)
		playerID = tonumber(playerID)
		playerName = playerName or playerID

		if not playerID then
			return sendChatFmt('<r>Invalid player id', moderator)
		end

		queueSanctionJob({"set", playerID, playerName, time, moderator, minutes, ts or SanctionRW.fileTs(os.time())})
	end
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

	-- Ban a player using their name, answered in SanctionDataLoaded
	local requests = ban_requests[targetPlayer]
	if not requests then
		requests = {_count = 0}
		ban_requests[targetPlayer] = requests
	end
	requests._count = requests._count + 1
	requests[requests._count] = {moderator, time, SanctionRW.fileTs(os.time())}

	requestPlayerData(targetPlayer, PDATA_SANCTION)
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

	if ranks.admin[player] then
		if args[2] == "reset" then
			if not targetID then
				tfm.exec.chatMessage("<v>[#] <r>You must provide a player id.", player)
				return
			end

			tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
			queueSanctionJob({"reset", targetID, targetName, player})

			chatlogCmd(cmd, player, args)
			logCmd(cmd, player, args)

			return
		end
	end

	if targetName then
		if not players_file[targetName] then
			sendChatFmt("Checking player data for %s's sanctions...", player, targetName)
		end

		-- answered in SanctionDataLoaded
		local requests = sanction_requests[targetName]
		if not requests then
			requests = {}
			sanction_requests[targetName] = requests
		end
		requests[player] = not targetID -- the id comes from their data

		requestPlayerData(targetName, PDATA_SANCTION)
	end

	if targetID then
		viewSanction(targetID, targetName, player, targetID)
	end
end })

local function printPlayerSanctions(player, targetName, pdata, fileLookup)
	if pdata.kill or pdata.killed then
		-- old data stores kill as a string ("0" ~= 0 would be true)
		local kill = tonumber(pdata.kill) or 0
		printSanctions(
			player,
			'powerban',
			targetName,
			pdata.playerid,
			pdata.killed ~= 0 and kill ~= 0 and
			(pdata.killed - kill * 60 * 1000) or nil,
			pdata.killed ~= 0 and pdata.killed or nil,
			'-',
			pdata.killedby,
			pdata.kill and kill
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

	if fileLookup and pdata.playerid then
		viewSanction(pdata.playerid, targetName, player, targetName)
	end
end

onEvent("SanctionDataLoaded", function(name, pdata)
	local requests = ban_requests[name]
	if requests then
		ban_requests[name] = nil

		-- a newer row only their data has goes to the file first, so the
		-- level comes from it (the job checks it against the fresh file)
		if pdata.playerid and pdata.lastsanction then
			queueSanctionJob({
				"writeback", pdata.playerid, name, pdata.lastsanction,
				pdata.banned or 0, pdata.bannedby, pdata.bancount or 0,
			})
		end

		local request
		for index = 1, requests._count do
			request = requests[index]
			if pdata.playerid then
				updateSanctions(pdata.playerid, name, request[2], request[1], nil, request[3])
			else
				tfm.exec.chatMessage("<v>[#] <r>The player cannot be (un)banned this way, try player id.", request[1])
			end
		end
	end

	requests = sanction_requests[name]
	if requests then
		sanction_requests[name] = nil

		for moderator, fileLookup in next, requests do
			printPlayerSanctions(moderator, name, pdata, fileLookup)
		end
	end
end)

onEvent("PlayerDataTimeout", function(name, kind)
	if kind ~= PDATA_SANCTION then return end

	local requests = ban_requests[name]
	if requests then
		ban_requests[name] = nil

		for index = 1, requests._count do
			tfm.exec.chatMessage("<v>[#] <r>Player doesn't seem to be online, try player id.", requests[index][1])
		end
	end

	requests = sanction_requests[name]
	if requests then
		sanction_requests[name] = nil

		for moderator in next, requests do
			sendChatFmt('<r>Could not load player data for %s, try id', moderator, name)
		end
	end
end)

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

	local pdata = players_file[requestplayer]
	if not pdata then
		sendChatFmt("<r>Pdata of %s hasn't loaded yet.", player, requestplayer)
		return
	end

	chatlogCmd(cmd, player, args)
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
	savePlayerData(requestplayer)

	sendChatFmt("<V>%s <j>can't use their powers for <b>%s</b> minutes.", nil, requestplayer, killedTime)
	translatedChatMessage("killed", requestplayer, killedTime)
	checkKill(requestplayer)
end })

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

			-- player data can only be changed in the room the player is in
			if not in_room[requestplayer] then
				tfm.exec.chatMessage("<v>[#] <r>" .. requestplayer .. " isn't here.", player)
				return
			end

			local pdata = players_file[requestplayer]
			if not pdata then
				sendChatFmt("<r>Pdata of %s hasn't loaded yet.", player, requestplayer)
				return
			end

			pdata.week[1] = pdata.week[1] + count
			savePlayerData(requestplayer)
			sendChatFmt("<j>New weekly count for %s: %s", player, requestplayer, pdata.week[1])

			chatlogCmd(cmd, player, args)
			logCmd(cmd, player, args)
		end
	elseif fileName == "maps" then
		local category = args[2]
		local len
		for j=1,5 do
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
	end
end })

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

	if reason == "troll" or reason == "force" then
		local reported_data = players_file[reportedName]

		if not reported_data or (reported_data.killed and reported_data.killed > os.time()) then
			return translatedChatMessage("report_invalid", playerName)
		end
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
	rank = "admin",
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

	local target = args[1]

	if target == "*" then
		for name in next, room.playerList do
			tfm.exec.kickPlayer(name)
		end
		return
	end

	if args[2] then
		local file = players_file[target]
		if file and in_room[target] then
			file.kick = tonumber(args[2])
			savePlayerData(target)
		end
	end

	tfm.exec.kickPlayer(target)
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

onEvent("PlayerDataParsed", function(player, data)
	if data and data.kick and (data.kick == 1 or os.time() < data.kick) then
		tfm.exec.kickPlayer(player)
	end
end)
end