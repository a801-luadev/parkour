local translatedChatMessage
local next_file_load
local send_bot_room_crash
local file_id

local webhooks = {_count = 0}
local runtime = 0
local room = tfm.get.room
local onEvent
do
	local os_time = os.time
	local math_floor = math.floor
	local runtime_check = 0
	local events = {}
	local scheduled = {_count = 0, _pointer = 1}
	local paused = false
	local runtime_threshold = 30
	local _paused = false

	local function runScheduledEvents()
		local count, pointer = scheduled._count, scheduled._pointer

		local data
		while pointer <= count do
			data = scheduled[pointer]
			-- An event can have up to 5 arguments. In this case, this is faster than table.unpack.
			data[1](data[2], data[3], data[4], data[5], data[6])
			pointer = pointer + 1

			if runtime >= runtime_threshold then
				scheduled._count = count
				scheduled._pointer = pointer
				return false
			end
		end
		scheduled._pointer = pointer
		return true
	end

	local function emergencyShutdown(limit_players, keep_webhooks)
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

		if keep_webhooks and next_file_load then
			if room.name == "*#parkour0maps" then
				send_bot_room_crash()
			else
				events.Loop._count = 1
				events.Loop[1] = function()
					if os.time() >= next_file_load then
						system.loadFile(file_id)
						next_file_load = os.time() + math.random(60500, 63000)
					end
				end

				events.FileLoaded._count = 1 -- There's already a decode/encode.
				events.SavingFile._count = 2
				events.SavingFile[2] = function()
					events.Loop._count = 0
					events.FileLoaded._count = 0
					events.SavingFile._count = 0
					events.GameDataLoaded._count = 0
				end

				events.GameDataLoaded._count = 1
				events.GameDataLoaded[1] = function(data)
					local now = os.time()
					if not data.webhooks or os.time() - data.webhooks[1] > 300000 then -- 5 minutes
						data.webhooks = {math.floor(os.time())}
					end

					local last = #data.webhooks
					for index = 1, webhooks._count do
						data.webhooks[last + index] = webhooks[index]
					end
					webhooks._count = 0
				end
			end
		end
	end

	function onEvent(name, callback)
		local evt
		if events[name] then
			evt = events[name]
		else
			evt = {_count = 0}
			events[name] = evt

			-- An event can have up to 5 arguments. In this case, this is faster than `...`
			local function caller(when, a, b, c, d, e)
				for index = 1, evt._count do
					evt[index](a, b, c, d, e)

					if os_time() >= when then
						break
					end
				end
			end

			local schedule = name ~= "Loop" and name ~= "Keyboard" -- schedule everything but eventLoop and eventKeyboard
			local done, result
			local event_fnc
			event_fnc = function(a, b, c, d, e)
				local start = os_time()
				local this_check = math_floor(start / 4000)
				if runtime_check < this_check then
					runtime_check = this_check
					runtime = 0
					paused = false

					if not runScheduledEvents() then
						runtime_check = this_check + 1
						paused = true
						return
					end

					if _paused then
						translatedChatMessage("resumed_events")
						_paused = false

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[CODE]:`** `" .. tfm.get.room.name .. "` is now resumed."
					end
				elseif paused then
					if schedule then
						scheduled._count = scheduled._count + 1
						scheduled[scheduled._count] = {event_fnc, a, b, c, d, e}
					end
					return
				end

				done, result = pcall(caller, start + runtime_threshold - runtime, a, b, c, d, e)
				if not done then
					local args = json.encode({a, b, c, d, e})
					translatedChatMessage("code_error", nil, name, "", args, result)
					tfm.exec.chatMessage(result)

					webhooks._count = webhooks._count + 1
					webhooks[webhooks._count] = "**`[CRASH]:`** `" .. tfm.get.room.name .. "` has crashed. <@212634414021214209>: `" .. name .. "`, `" .. result .. "`"

					return emergencyShutdown(true, true)
				end

				runtime = runtime + (os_time() - start)

				if runtime >= runtime_threshold then
					if not _paused then
						translatedChatMessage("paused_events")

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[CODE]:`** `" .. tfm.get.room.name .. "` has been paused."
					end

					runtime_check = this_check + 1
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
