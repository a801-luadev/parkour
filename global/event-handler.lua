local translatedChatMessage
local packet_handler
local send_channel
local sendPacket
local add_packet_data, buffer
local initializingModule = true

local onEvent
do
	-- Configuration
	local CYCLE_DURATION = 4100
	local RUNTIME_LIMIT = 30
	local DONT_SCHEDULE = {
		["Loop"] = true,
		["Keyboard"] = true
	}

	-- Optimization
	local os_time = os.time
	local math_floor = math.floor

	-- Runtime breaker
	local cycleId = 0
	local usedRuntime = 0
	local stopingAt = 0
	local checkingRuntime = false
	local paused = false
	local scheduled = {_count = 0, _pointer = 1}

	-- Listeners
	local events = {}

	local function errorHandler(name, msg)
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.disableMortCommand(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.newGame(7685178)
		tfm.exec.setGameTime(99999)

		for _, event in next, events do
			event._count = 0
		end

		if room.name == "*#parkour4bots" then
			ui.addTextArea(bit32.lshift(255, 8) + 255, name .. "\000" .. msg)
			return
		end

		tfm.exec.chatMessage(name .. " - " .. msg)
		translatedChatMessage("emergency_mode")

		if is_tribe then return end

		tfm.exec.setRoomMaxPlayers(1)

		sendPacket(0, room.name .. "\000" .. name .. "\000" .. msg)
		system.loadPlayerData(send_channel)
		buffer = add_packet_data

		events.PlayerDataLoaded._count = 2
		events.PlayerDataLoaded[1] = packet_handler
		events.PlayerDataLoaded[2] = function(player)
			if player == send_channel then
				events.PlayerDataLoaded._count = 0
			end
		end
	end

	local function callListeners(evt, a, b, c, d, e, offset)
		for index = offset, evt._count do
			evt[index](a, b, c, d, e)

			if not initializingModule and os_time() >= stopingAt then
				if index < evt._count then
					-- If this event didn't end, we need to resume from
					-- where it has been left!
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, index + 1}
				end

				paused = true
				cycleId = cycleId + 2
				translatedChatMessage("paused_events")
				break
			end
		end
	end

	local function resumeModule()
		local count = scheduled._count

		local event
		for index = scheduled._pointer, count do
			event = scheduled[index]
			callListeners(event[1], event[2], event[3], event[4], event[5], event[6], event[7])

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
				local done, result = pcall(callListeners, evt, a, b, c, d, e, 1)
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
				callListeners(evt, a, b, c, d, e, 1)
				return
			end

			-- If we call any event inside this one, we don't need to
			-- perform all the runtime breaker checks.
			checkingRuntime = true
			local start = os_time()
			local thisCycle = math_floor(start / CYCLE_DURATION)

			if thisCycle > cycleId then
				-- new runtime cycle
				cycleId = thisCycle
				usedRuntime = 0
				stopingAt = start + RUNTIME_LIMIT

				-- if this was paused, we need to resume!
				if paused then
					paused = false
					checkingRuntime = false

					local done, result = pcall(resumeModule)
					if not done then
						errorHandler("resuming", result)
						return
					end

					usedRuntime = usedRuntime + os_time() - start

					-- if resuming took a lot of runtime, we have to
					-- pause again
					if paused then
						if schedule then
							scheduled._count = scheduled._count + 1
							scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
						end
						return
					end
				end
			else
				stopingAt = start + RUNTIME_LIMIT - usedRuntime
			end

			if paused then
				if schedule then
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
				end
				checkingRuntime = false
				return
			end

			local done, result = pcall(callListeners, evt, a, b, c, d, e, 1)
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
			evt = {_count = 0}
			events[name] = evt

			_G["event" .. name] = registerEvent(name)
		end

		-- Register callback
		evt._count = evt._count + 1
		evt[ evt._count ] = callback
	end
end