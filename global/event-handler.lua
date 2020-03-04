local translatedChatMessage

runtime = 0
local onEvent
do
	local os_time = os.time
	local math_floor = math.floor
	local table_unpack = table.unpack
	local runtime_check = 0
	local events = {}
	local scheduled = {_count = 0, _pointer = 1}
	local paused = false
	local runtime_threshold = 30
	local _paused = false

	local function runScheduledEvents()
		local ret_val = true
		local count, pointer = scheduled._count, scheduled._pointer

		local data
		while pointer <= count do
			data = scheduled[pointer]
			data[1](table_unpack(data, 2))
			pointer = pointer + 1

			if runtime > runtime_threshold then
				scheduled._count = count
				ret_val = false
				break
			end
		end
		scheduled._pointer = pointer
		return ret_val
	end

	local function emergencyShutdown(limit_players)
		if limit_players then
			translatedChatMessage("emergency_mode")
			tfm.exec.setRoomMaxPlayers(1)
		end
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
	end

	function onEvent(name, callback)
		local evt
		if events[name] then
			evt = events[name]
		else
			evt = {_count = 0}
			events[name] = evt

			local schedule = name ~= "Loop" -- schedule everything but eventLoop
			local done, result
			local event_fnc
			event_fnc = function(...)
				local start = os_time()
				local max_runtime = runtime_threshold - runtime
				local this_check = math_floor(start / 4000)
				if runtime_check ~= this_check then
					runtime_check = this_check
					runtime = 0
					paused = false

					if not runScheduledEvents() then
						return
					end

					if _paused then
						translatedChatMessage("resumed_events")
						_paused = false
					end
				elseif paused then
					scheduled._count = scheduled._count + 1
					scheduled[scheduled._count] = {event_fnc, ...}
					return
				end

				for index = 1, evt._count do
					done, result = pcall(evt[index], ...)
					if not done then
						local args = json.encode({...})
						translatedChatMessage("code_error", nil, name, index, args, result)

						return emergencyShutdown(true)
					end

					if (os_time() - start) > max_runtime then
						break
					end
				end

				runtime = runtime + (os_time() - start)

				if runtime >= runtime_threshold then
					if not _paused then
						translatedChatMessage("paused_events")
					end

					paused = true
					_paused = true
					scheduled._count = 0
					scheduled._pointer = 1
				end
			end

			_G["event" .. name] = event_fnc
		end

		evt._count = evt._count + 1
		evt[evt._count] = callback
	end
end