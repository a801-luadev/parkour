--[[
	Note: I'm needing to refactor this to make it fit with the module.
]]

--[[
	Here's how it does work:

	We use playerdata. To do so, we need to share a "stream channel" (the user).
	Transformice's playerdata does only work when the player we're requesting to load/save
	the data is online. And that's why we use Sharpiebot#0000 as the "stream channel",
	since it will always be online.

	We also need a communication protocol. Firstly we define our messages:
	Starting with - -> Dead communication
	Starting with _ -> Heartbeat (keep alive)
	Starting with ? -> Any room request
	Starting with ! -> Syncing room (tunnel) answer
	Every packet will have the expire date first, followed by a colon
	and then by the message. If the date expires, we set the "dead communication"
	message, just to warn any room that has acquired the lock, that it will be
	forcibly released once this "dead communication" message expires.

	Once we want to communicate, we need to make sure that no other room will
	overwrite our messages! To do so, we apply a "lock". If the player data is empty
	the lock is free, and any room can feel free to acquire it. They do so by
	setting their name as a message. Once they do it, they need to load the data
	and check if their name is still here. If it is, then no other room will try
	to overwrite our messages, and we can freely start our communication.
]]

local stream_bot = "Sharpiebot#0000"

local acquire_stream
local set_stream_failure_callback
local set_stream_request_callback
local send_stream_message
local wait_stream_answer
local toggle_heartbeat_system
local release_stream
do
	local heartbeat = false
	local last_message = 0
	local message_lifetime = 2500
	local heartbeat_every = 2000
	local next_heartbeat = 0
	local acquiring = false
	local request_callback = nil
	local failure_callback = nil
	local is_handler = false
	local answer_waiter, answer_args = nil, nil
	local acquire_waiter, acquire_args = nil, nil
	local time = os.time
	local unpack = table.unpack
	local room_name = tfm.get.room.name

	function acquire_stream(callback, ...)
		acquiring = true
		acquire_waiter, acquire_args = callback, {...}
	end

	function toggle_heartbeat_system(state)
		heartbeat = state
	end

	function wait_stream_answer(callback, ...)
		answer_waiter, answer_args = callback, {...}
	end

	function release_stream()
		system.savePlayerData(stream_bot, "")
	end

	function set_stream_request_callback(callback)
		request_callback = callback
	end

	function send_stream_message(prefix, message, when)
		when = when or time()
		system.savePlayerData(stream_bot, (when + message_lifetime) .. ":" .. prefix .. message)
	end

	function set_stream_failure_callback(callback)
		failure_callback = callback
	end

	local function try_heartbeat()
		local now = time()
		if heartbeat and now >= next_heartbeat then
			send_stream_message("_", "", now)
			next_heartbeat = now + heartbeat_every
		end
	end

	onEvent("PlayerDataLoaded", function(player, data)
		if player ~= stream_bot then return end

		local date, msg = string.match(data, "^(%d+):(.+)$")
		if date then
			date = tonumber(date)
			now = time()
			if date <= now then
				if msg == "-" then
					system.savePlayerData(stream_bot, "")
					date, msg = 0, ""
				else
					send_stream_message("-", "", now)
					date, msg = now + message_lifetime, "-"
				end
			elseif date <= last_message then
				return try_heartbeat()
			end
			last_message = date
		else
			date, msg = 0, ""
		end

		if msg == "-" then
			if failure_callback and (answer_waiter or request_callback) then
				answer_waiter = nil
				failure_callback()
			end
			return
		end

		if request_callback then
			request_callback(msg)
		else
			if acquiring then
				if msg == "" then
					send_stream_message("", room_name)
				elseif msg == room_name then
					acquiring = false
					acquire_waiter(unpack(acquire_args))
					acquire_waiter = nil
				end
			elseif answer_waiter and string.sub(msg, 1, 1) == "!" then
				local last_args = answer_args
				answer_waiter(msg, unpack(answer_args))
				if last_args == answer_args then
					answer_waiter = nil
				end
			end
		end
		try_heartbeat()
	end)
end