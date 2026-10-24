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
		["After"] = true,
		["ContactListener"] = true,
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
	local pausedCycle = -1
	local pausedAt = "" -- event name and listener line that hit the limit
	local childTime = 0 -- time spent in nested events inside the running listener
	local scheduled = {_count = 0, _pointer = 1}

	-- Listeners
	local events = {}

	local function errorHandler(name, msg)
		-- The failed call never finished: reset the runtime breaker so the
		-- emergency mode listeners can run
		checkingRuntime = false
		paused = false
		scheduled = {_count = 0, _pointer = 1}

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

		if room.starting == "@#" then
			ui.addTextArea(0, room.shortName .. "\000" .. name .. "\000" .. msg)
			return
		end

		translatedChatMessage("emergency_mode")

		if is_tribe then return end

		tfm.exec.setRoomMaxPlayers(1)

		channels.canRead = false
		sendPacket("common", 0, room.shortName .. "\000" .. name .. "\000" .. msg)
		channelHandler(true) -- load channel now to send all the data
		onEvent("Loop", channelHandler)
		onEvent("PlayerDataLoaded", pipeHandler)
	end

	-- isDirect = not a scheduled or an indirect call
	-- returns true if the rest of this event has been scheduled to resume later
	local function callListeners(evt, a, b, c, d, e, f, g, offset, isDirect)
		local total, calls = evt._runtime, evt._calls
		local now, elapsed, outerChildTime
		local continued = false

		-- Runtime is measured per cycle, for direct and nested calls alike
		if cycleId ~= evt._cycle then
			evt._cycle = cycleId

			for index = 1, evt._count do
				total[index] = 0
				calls[index] = 0
			end
		end

		-- The time a listener ends at is also when the next one starts at
		local ts = os_time()
		for index = offset, evt._count do
			if not initializingModule and ts >= stoppingAt then
				-- This listener didn't run yet, we need to resume from it!
				scheduled._count = scheduled._count + 1
				scheduled[ scheduled._count ] = {evt, a, b, c, d, e, f, g, index}
				continued = true

				if not paused then
					translatedChatMessage("paused_events")

					-- Remember which cycle got paused, so its runtime can be
					-- reported no matter when the module resumes
					pausedCycle = cycleId
					pausedAt = evt._name .. "\001" .. evt._lines[index]
					cycleId = cycleId + 2
				end

				paused = true

				break
			end

			-- Only the listener's own time is recorded: the time spent in
			-- events it calls is already recorded by their own listeners
			outerChildTime = childTime
			childTime = 0

			evt[index](a, b, c, d, e, f, g)
			now = os_time()
			elapsed = now - ts
			ts = now

			total[index] = total[index] + elapsed - childTime
			calls[index] = 1 + calls[index]
			childTime = outerChildTime + elapsed
		end

		if isDirect then
			if eventAfter and not paused then
				eventAfter()
			end
		end

		return continued
	end

	local function resumeModule()
		local count = scheduled._count

		do
			-- Every listener that spent runtime in the paused cycle, as
			-- line \001 ms \001 calls
			-- (line numbers are unique in the build, so event names aren't needed)
			local arr, n = {}, 0
			local runtime, calls, lines

			for name, evt in next, events do
				if evt._cycle == pausedCycle then
					runtime, calls, lines = evt._runtime, evt._calls, evt._lines

					for index = 1, evt._count do
						if runtime[index] > 0 then
							n = 1 + n
							arr[n] = lines[index] .. "\001" .. runtime[index] .. "\001" .. calls[index]
						end
					end
				end
			end

			if n ~= 0 then
				local sendOrRecv = room.starting == "@#" and eventPacketReceived or sendPacket
				sendOrRecv(
					"common", packets.rooms.paused_events,
					room.shortName .. "\000" ..
					(cycleId - startCycle) .. "\000" ..
					totalRuntime .. "\000" ..
					room.uniquePlayers .. "\000" ..
					pausedAt .. "\000" ..
					table.concat(arr, '\000', 1, n)
				)
			end
		end

		local event
		for index = scheduled._pointer, count do
			event = scheduled[index]
			local continued = callListeners(event[1], event[2], event[3], event[4], event[5], event[6], event[7], event[8], event[9], false)

			if paused then
				if continued then
					-- This event didn't end, and the last scheduled item is its rest
					-- (events it called may have been scheduled before it).
					-- It should be the first one to run on the next attempt to resume.
					event[9] = scheduled[ scheduled._count ][9]

					-- So we set it to start from here
					scheduled._pointer = index
					-- and remove the last item, since we don't want it to
					-- execute twice!
					scheduled._count = scheduled._count - 1
				else
					-- This one has successfully ended. Anything scheduled during it
					-- (events it called) stays in the queue after the current items.
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
		event = function(a, b, c, d, e, f, g)
			if initializingModule then
				local done, result = pcall(callListeners, evt, a, b, c, d, e, f, g, 1, false)
				if not done then
					errorHandler(name, result)
				end
				return
			end

			if checkingRuntime then
				if paused then
					if schedule then
						scheduled._count = scheduled._count + 1
						scheduled[ scheduled._count ] = {evt, a, b, c, d, e, f, g, 1}
					end
					return
				end
				-- Directly call callListeners since there's no need of
				-- two error handlers
				callListeners(evt, a, b, c, d, e, f, g, 1, false)
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
							scheduled[ scheduled._count ] = {evt, a, b, c, d, e, f, g, 1}
						end
						checkingRuntime = false
						return
					end
				end
			else
				stoppingAt = start + RUNTIME_LIMIT - usedRuntime
			end

			if paused then
				if schedule then
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, f, g, 1}
				end
				checkingRuntime = false
				return
			end

			local done, result = pcall(callListeners, evt, a, b, c, d, e, f, g, 1, true)
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
			evt = {_count = 0, _name=name, _lines={}, _cycle=-1, _runtime={}, _calls={}}
			events[name] = evt

			_G["event" .. name] = registerEvent(name)
		end

		-- Register callback
		evt._count = evt._count + 1
		evt[ evt._count ] = callback
		evt._lines[ evt._count ] = debug.traceback(nil, 2):match(':(%d+)') or "0"
		evt._runtime[ evt._count ] = 0
		evt._calls[ evt._count ] = 0
	end
end
