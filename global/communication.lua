--[[
	-- should not work in tribehouse

	pipeHandler(pipe, data)
	channelHandler(load_now)
	sendPacket(channel, id, packet)

	eventPacketSent(channel)
	eventPacketReceived(channel, id, packet)
	eventRetrySendData(channel)
	eventCantSendData(channel)
]]

channels = {
	canRead = true,

	-- isRead, doClean, ttl, customStructure, bots (pipes)
	common = { -- to bots (common data, low traffic)
		room.name == "*#parkour4bots", true, 10000,
		false,
		"Sharpiebot#0000", "D_shades#0780"
	},
	victory = { -- to bots (all victory logs, high traffic)
		room.name == "*#parkour4bots", true, 10000,
		"(...........[^\000]+)\000",
		"A_801#0015"
	},
	bots = { -- from bots (all orders, low traffic)
		room.name ~= "*#parkour4bots", false, 10000,
		false,
		"Parkour#8558"
	}
}

function sendPacket(channel, id, packet) end -- do nothing in tribehouse
if not is_tribe then
	local read = {}
	local write = {}

	local tbl
	for name, data in next, channels do
		if name ~= "canRead" then
			tbl = data[1] and read or write

			tbl[name] = {
				name = name,
				read = data[1],
				clean = data[2],
				ttl = data[3],
				structure = data[4],
				buffer = nil
			}
			for index = 5, #data do
				-- bot names (pipes)
				tbl[name][index - 4] = data[index]
				-- last id in pipe
				tbl[name][ data[index] ] = 0

				channels[ data[index] ] = tbl[name]
			end

			tbl[name].pipes = #data - 4
			if not data[1] then -- write channel
				-- select random pipe (if there are many, load will distribute)
				tbl[name].selected = math.random(0, #data - 5)
				-- retries left for this channel
				tbl[name].retries = #data - 4
			end
		end
	end

	local next_load = os.time() + 10000
	local timeout

	local decoder = {
		["&0"] = "&", ["&1"] = ";", ["&2"] = ","
	}
	local encoder = {
		["&"] = "&0", [";"] = "&1", [","] = "&2"
	}

	function sendPacket(channel, id, packet)
		channel = write[channel]

		if not channel then
			error("Unkown channel: " .. channel, 2)
		end

		local buffer = channel.buffer or ""
		if #buffer + #packet > 1985 then -- too large
			buffer = ""
		end

		if channel.structure then
			buffer = buffer .. packet
		else
			buffer = buffer .. ";" .. id .. "," .. string.gsub(packet, "[&;,]", encoder)
		end

		channel.buffer = buffer
	end

	function pipeHandler(pipe, data)
		local channel = channels[pipe]
		if not channel then return end -- not a channel!

		local expire, data = string.match(data, "^(%d+);(.*)$")
		if not expire then
			expire, data = 0, ""
		end
		expire = tonumber(expire)

		local now = os.time()

		if channel.read then
			if channel[pipe] >= expire or now >= expire then
				-- already read or expired
				return
			end

			channel[pipe] = expire

			if eventPacketReceived then
				if channel.structure then
					for packet in string.gmatch(data, channel.structure) do
						eventPacketReceived(channel.name, -1, packet)
					end

				else
					for id, packet in string.gmatch(data, "(%d+),([^;]*)") do
						packet = string.gsub(packet, "&[012]", decoder)

						eventPacketReceived(channel.name, tonumber(id), packet)
					end
				end
			end

			if channel.clean then
				system.savePlayerData(pipe, "")
			end

		elseif channel.buffer then -- is write and has something to send
			if channel[ channel.selected + 1 ] ~= pipe then
				-- loaded too late
				return
			end

			local buffer = channel.buffer
			channel.buffer = nil

			if now < expire then -- data didn't expire, we have to keep it
				if #data + #buffer <= 1985 then -- if it doesn't fit, we just delete old data
					buffer = data .. buffer
				end
			end

			if string.sub(buffer, 1, 1) ~= ";" then
				buffer = ";" .. buffer
			end

			if eventPacketSent then
				eventPacketSent(channel.name)
			end

			system.savePlayerData(pipe, (now + channel.ttl) .. buffer)
		end
	end
	onEvent("PlayerDataLoaded", pipeHandler)

	function channelHandler(load_now)
		local now = os.time()

		if timeout and now >= timeout then
			local retry = false

			for name, data in next, write do
				if data.buffer then
					if data.retries > 0 then
						retry = true
						data.retries = data.retries - 1
						data.selected = (data.selected + 1) % data.pipes

						system.loadPlayerData(data[ data.selected + 1 ])

						if eventRetrySendData then
							eventRetrySendData(name)
						end

					elseif eventCantSendData then
						eventCantSendData(name)
					end
				end
			end

			if retry then
				timeout = now + 1500
			else
				timeout = nil
			end
		end

		if load_now == true or now >= next_load then
			-- load_now may be an int since it's executed in eventLoop
			next_load = now + 10000
			timeout = now + 1500

			for name, data in next, write do
				if data.buffer then
					data.retries = data.pipes
					system.loadPlayerData(data[ data.selected + 1 ])
				end
			end

			if channels.canRead then
				for name, data in next, read do
					for index = 1, data.pipes do
						system.loadPlayerData(data[index])
					end
				end
			end
		end
	end
	onEvent("Loop", channelHandler)
end