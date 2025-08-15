local translatedChatMessage
local channels, sendPacket, pipeHandler, channelHandler
local initializingModule = true

local onEvent, totalRuntime, startCycle, cycleId, usedRuntime
do
	-- Configuration
	local CYCLE_DURATION = 4100
	local RUNTIME_LIMIT = 30
	local DONT_SCHEDULE = {
		["Loop"] = true,
		["Keyboard"] = true,
		["After"] = true
	}

	-- Optimization
	local os_time = os.time
	local math_floor = math.floor

	-- Runtime breaker
	startCycle = math_floor(os_time() / CYCLE_DURATION)
	cycleId = 0
	usedRuntime = 0
	totalRuntime = 0
	local stoppingAt = 0
	local checkingRuntime = false
	local paused = false
	local scheduled = {_count = 0, _pointer = 1}
	local pausedEventInfo

	-- Listeners
	local events = {}

	local function errorHandler(name, msg)
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.disableMortCommand(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.newGame(7946879)
		tfm.exec.setGameTime(99999)

		for _, event in next, events do
			event._count = 0
		end

		tfm.exec.chatMessage(name .. " - " .. msg)

		if room.name == "*#parkour4bots" then
			ui.addTextArea(0, "*4bots\000" .. name .. "\000" .. msg)
			return
		end

		translatedChatMessage("emergency_mode")

		if is_tribe then return end

		tfm.exec.setRoomMaxPlayers(1)

		channels.canRead = false
		sendPacket("common", 0, room.shortName .. "\000" .. name .. "\000" .. msg)
		channelHandler(true) -- load channel now to send all the data

		events.Loop._count = 1
		events.Loop[1] = channelHandler

		events.PlayerDataLoaded._count = 2
		events.PlayerDataLoaded[1] = pipeHandler
		events.PlayerDataLoaded[2] = function(player)
			if channels[player] and channels[player].buffer then
				events.Loop._count = 0
				events.PlayerDataLoaded._count = 0
			end
		end
	end

	-- isDirect = not a scheduled or an indirect call
	local function callListeners(evt, a, b, c, d, e, offset, isDirect)
		local pause_index
		for index = offset, evt._count do
			if not initializingModule and os_time() >= stoppingAt then
				if index < evt._count then
					-- If this event didn't end, we need to resume from
					-- where it has been left!
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, index}
				end

				if not paused then
					pausedEventInfo = { _len=9 }
					if not isDirect then
						pausedEventInfo[10] = evt._name
						pausedEventInfo[11] = a
						pausedEventInfo[12] = b
						pausedEventInfo[13] = c
						pausedEventInfo[14] = d
						pausedEventInfo[15] = e
						pausedEventInfo[16] = index
						pausedEventInfo[17] = evt._lines[index]
					end
					translatedChatMessage("paused_events")
				end

				paused = true
				cycleId = cycleId + 2

				break
			end

			pause_index = index
			evt[index](a, b, c, d, e)
		end

		if isDirect then
			if eventAfter and not paused then
				eventAfter()
			end

			if paused then
				pausedEventInfo[1] = evt._name
				pausedEventInfo[2] = a
				pausedEventInfo[3] = b
				pausedEventInfo[4] = c
				pausedEventInfo[5] = d
				pausedEventInfo[6] = e
				pausedEventInfo[7] = offset
				pausedEventInfo[8] = pause_index
				pausedEventInfo[9] = evt._lines[pause_index]
			end
		end
	end

	local function resumeModule()
		local count = scheduled._count

		if pausedEventInfo then
			for i=1, 17 do
				pausedEventInfo._len = pausedEventInfo[i] and i or pausedEventInfo._len
				pausedEventInfo[i] = tostring(pausedEventInfo[i] or ""):sub(1, 20)
			end

			sendPacket(
				"common", packets.rooms.paused_events,
				room.shortName .. "\000" ..
				(cycleId - startCycle) .. "\000" ..
				totalRuntime .. "\000" ..
				room.uniquePlayers .. "\000" ..
				table.concat(pausedEventInfo, '\000', 1, pausedEventInfo._len)
			)
			pausedEventInfo = nil
		end

		local event
		for index = scheduled._pointer, count do
			event = scheduled[index]
			callListeners(event[1], event[2], event[3], event[4], event[5], event[6], event[7], false)

			if paused then
				if scheduled._count > count then
					-- If a new event has been scheduled, it is this one.
					-- It should be the first one to run on the next attempt to resume.
					event[7] = scheduled[ scheduled._count ][7]

					-- So we set it to start from here
					scheduled._pointer = index
					-- and remove the last item, since we don't want it to
					-- execute twice!
					scheduled._count = scheduled._count - 1
				else
					-- If no event has been scheduled, this one has successfully ended.
					-- We just tell the next attempt to resume to start from the next one.
					scheduled._pointer = index + 1
				end
				return
			end
		end

		-- delete all the scheduled tables since they just use ram!
		scheduled = {_count = 0, _pointer = 1}
		translatedChatMessage("resumed_events")
	end

	local function registerEvent(name)
		local evt = events[name]
		local schedule = not DONT_SCHEDULE[name]

		local event
		event = function(a, b, c, d, e)
			if initializingModule then
				local done, result = pcall(callListeners, evt, a, b, c, d, e, 1, false)
				if not done then
					errorHandler(name, result)
				end
				return
			end

			if checkingRuntime then
				if paused then
					if schedule then
						scheduled._count = scheduled._count + 1
						scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
					end
					return
				end
				-- Directly call callListeners since there's no need of
				-- two error handlers
				callListeners(evt, a, b, c, d, e, 1, false)
				return
			end

			-- If we call any event inside this one, we don't need to
			-- perform all the runtime breaker checks.
			checkingRuntime = true
			local start = os_time()
			local thisCycle = math_floor(start / CYCLE_DURATION)

			if thisCycle > cycleId then
				-- new runtime cycle
				totalRuntime = totalRuntime + usedRuntime

				cycleId = thisCycle
				usedRuntime = 0
				stoppingAt = start + RUNTIME_LIMIT

				-- if this was paused, we need to resume!
				if paused then
					paused = false
					--checkingRuntime = false

					local done, result = pcall(resumeModule)
					if not done then
						errorHandler("resuming", result)
						return
					end

					-- if resuming took a lot of runtime, we have to
					-- pause again
					if paused then
						usedRuntime = usedRuntime + os_time() - start
						if schedule then
							scheduled._count = scheduled._count + 1
							scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
						end
						return
					end
				end
			else
				stoppingAt = start + RUNTIME_LIMIT - usedRuntime
			end

			if paused then
				if schedule then
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
				end
				checkingRuntime = false
				return
			end

			local done, result = pcall(callListeners, evt, a, b, c, d, e, 1, true)
			if not done then
				errorHandler(name, result)
				return
			end

			checkingRuntime = false
			usedRuntime = usedRuntime + os_time() - start
		end

		return event
	end

	function onEvent(name, callback)
		local evt = events[name]

		if not evt then
			-- Unregistered event
			evt = {_count = 0, _name=name, _lines={}}
			events[name] = evt

			_G["event" .. name] = registerEvent(name)
		end

		-- Register callback
		evt._count = evt._count + 1
		evt[ evt._count ] = callback
		evt._lines[ evt._count ] = debug.traceback(nil, 2):match(':(%d+)')
	end
end
