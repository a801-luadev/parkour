-- Loads player data of other players, parsing only what each request needs.
--
-- requestPlayerData(name, kind) asks for a kind of data, and the answer comes
-- as the kind's event, so each feature's runtime is measured on its own:
--   PDATA_STAFF: eventStaffDataLoaded(name, commu, isHidden)
--   PDATA_ROOM:  eventRoomDataLoaded(name, commu, room)
--   PDATA_FULL:  eventOutPlayerDataParsed(name, data)
--   PDATA_SANCTION: eventSanctionDataLoaded(name, data)
--     data is either the parsed data or a table with only the sanction fields
--     (playerid, banned, bancount, lastsanction, bannedby, killed, kill, killedby)
-- If the server doesn't answer in time (they're offline):
--   eventPlayerDataTimeout(name, kind)
--
-- PDATA_JOIN loads the data of a player who joined the room: it becomes their
-- players_file and eventPlayerDataParsed(name, data) is triggered. It never
-- times out, since the player has to get their data however long it takes.
--
-- Requests for the same player are merged into a single load. Players in the
-- room are answered from players_file.

local PDATA_STAFF = 1
local PDATA_ROOM = 2
local PDATA_FULL = 3
local PDATA_JOIN = 4
local PDATA_SANCTION = 5

-- defined in files.lua
local parseOutPlayerData, parseRoomPlayerData

local requestPlayerData
do
	local REQUEST_TIMEOUT = 1000
	-- merged requests needing this many kinds parse the whole data at once
	local FULL_PARSE_KINDS = 3

	local find, match, tonumber = string.find, string.match, tonumber

	-- {key, pattern, is number}
	local sanctionFields = {
		{"playerid", nil, true},
		{"banned", nil, true},
		{"bancount", nil, true},
		{"lastsanction", nil, true},
		{"bannedby"},
		{"killed", nil, true},
		{"kill", nil, true},
		{"killedby"},
	}
	for index = 1, #sanctionFields do
		-- old data may store numbers as strings
		sanctionFields[index][2] = '"' .. sanctionFields[index][1] .. '":%s*"?([^",}%s]*)'
	end

	-- fromRaw reads the few keys a kind needs straight from the json,
	-- fromData answers from a parsed file. A kind without fromRaw needs a full parse.
	-- Only use top-level keys that hold a single value in fromRaw.
	-- Kinds with flatOnly need a full parse for data older than v0,
	-- since their keys were somewhere else back then.
	local kinds = {
		[PDATA_STAFF] = {
			fromRaw = function(name, raw)
				eventStaffDataLoaded(
					name,
					match(raw, '"commu":%s*"([^"]*)"'),
					find(raw, '"hidden":%s*true') ~= nil
				)
			end,
			fromData = function(name, data)
				eventStaffDataLoaded(name, data.commu, data.hidden == true)
			end,
		},
		[PDATA_ROOM] = {
			fromRaw = function(name, raw)
				eventRoomDataLoaded(
					name,
					match(raw, '"commu":%s*"([^"]*)"'),
					match(raw, '"room":%s*"([^"]*)"')
				)
			end,
			fromData = function(name, data)
				eventRoomDataLoaded(name, data.commu, data.room)
			end,
		},
		[PDATA_FULL] = {
			fromData = function(name, data)
				eventOutPlayerDataParsed(name, data)
			end,
		},
		[PDATA_SANCTION] = {
			flatOnly = true,
			fromRaw = function(name, raw)
				local data, field, value = {}
				for index = 1, #sanctionFields do
					field = sanctionFields[index]
					value = match(raw, field[2])
					if value and field[3] then
						value = tonumber(value)
					end
					data[field[1]] = value
				end
				eventSanctionDataLoaded(name, data)
			end,
			fromData = function(name, data)
				eventSanctionDataLoaded(name, data)
			end,
		},
	}

	local pending = {} -- name -> request
	-- requests in the order they were made, which is also their expiry order
	-- since they all use the same timeout. Answered ones stay until they expire.
	local queue = {_first = 1, _last = 0}

	local function answer(name, request, raw, data)
		pending[name] = nil

		local requested = request.kinds
		if not data then
			local parse = request.count >= FULL_PARSE_KINDS or requested[PDATA_FULL]
			if not parse then
				for kind in next, requested do
					if kinds[kind].flatOnly then
						-- data from v0 on has a top-level "v":number
						parse = not find(raw, '"v":%s*%d')
						break
					end
				end
			end
			if parse then
				data = parseOutPlayerData(name, raw)
			end
		end

		for kind in next, requested do
			if data then
				kinds[kind].fromData(name, data)
			else
				kinds[kind].fromRaw(name, raw)
			end
		end
	end

	function requestPlayerData(name, kind)
		if channels[name] then return end -- bots' pipes

		if kind == PDATA_JOIN then
			system.loadPlayerData(name)
			return
		end

		local request = pending[name]
		if request then
			if not request.kinds[kind] then
				request.kinds[kind] = true
				request.count = request.count + 1
			end
			return
		end

		if players_file[name] then
			kinds[kind].fromData(name, players_file[name])
			return
		end

		request = {
			name = name,
			expires = os.time() + REQUEST_TIMEOUT,
			kinds = {[kind] = true},
			count = 1,
		}
		pending[name] = request
		queue._last = queue._last + 1
		queue[queue._last] = request

		-- players in the room get their data loaded when they join,
		-- so their requests are answered when it gets parsed
		if not in_room[name] then
			system.loadPlayerData(name)
		end
	end

	onEvent("PlayerDataLoaded", function(name, raw)
		if channels[name] then return end -- bots' pipes

		if in_room[name] then
			-- requests for them get answered when it triggers eventPlayerDataParsed
			if string.sub(name, 1, 1) ~= "*" then
				parseRoomPlayerData(name, raw)
			end
			return
		end

		local request = pending[name]
		if request then
			answer(name, request, raw)
		end
	end)

	onEvent("PlayerDataParsed", function(name, data)
		local request = pending[name]
		if not request then return end

		answer(name, request, nil, data)
	end)

	onEvent("Loop", function()
		local now = os.time()
		local index, last = queue._first, queue._last
		local request

		while index <= last do
			request = queue[index]
			if now < request.expires then break end

			queue[index] = nil
			index = index + 1

			if pending[request.name] == request then
				pending[request.name] = nil

				for kind in next, request.kinds do
					eventPlayerDataTimeout(request.name, kind)
				end
			end
		end

		queue._first = index
	end)
end
