if room.name == "*#parkour0maps" then
	recv_channel, send_channel = "Holybot#0000", "Sharpiebot#0000"
else
	recv_channel, send_channel = "Sharpiebot#0000", "Holybot#0000"
end

function sendPacket(packet_id, packet) end
if not is_tribe then
	--[[
		Packets from 0maps:
			0 - join request
			1 - game update
			2 - !kill
			3 - !ban
			4 - !announcement

		Packets to 0maps:
			0 - room crash
			1 - suspect
			2 - ban field set to playerdata
	]]

	local last_id = os.time() - 10000
	local next_channel_load = 0
	local add_packet_data
	local buffer

	local common_decoder = {
		["&0"] = "&",
		["&1"] = ";",
		["&2"] = ","
	}
	local common_encoder = {
		["&"] = "&0",
		[";"] = "&1",
		[","] = "&2"
	}

	function sendPacket(packet_id, packet)
		if not add_packet_data then
			add_packet_data = ""
		end

		add_packet_data = add_packet_data .. ";" .. packet_id .. "," .. string.gsub(packet, "[&;,]", common_encoder)
	end

	packet_handler = function(player, data)
		if player == send_channel then
			if not buffer then return end
			local send_id
			send_id, data = string.match(data, "^(%d+)(.*)$")
			if not send_id then
				send_id, data = 0, ""
			else
				send_id = tonumber(send_id)
			end

			local now = os.time()
			if now < send_id + 10000 then
				buffer = data .. buffer
			end

			system.savePlayerData(player, now .. buffer)
			buffer = nil
			if eventPacketSent then
				eventPacketSent()
			end
		elseif player == recv_channel then
			if data == "" then
				data = "0"
			end

			local send_id
			send_id, data = string.match(data, "^(%d+)(.*)$")
			send_id = tonumber(send_id)
			if send_id <= last_id then return end
			last_id = send_id

			if eventPacketReceived then
				for packet_id, packet in string.gmatch(data, ";(%d+),([^;]+)") do
					packet = string.gsub(packet, "&[012]", common_decoder)

					eventPacketReceived(tonumber(packet_id), packet)
				end
			end
		end
	end
	onEvent("PlayerDataLoaded", packet_handler)

	onEvent("Loop", function()
		local now = os.time()
		if now >= next_channel_load then
			next_channel_load = now + 10000

			eventChannelLoad()
			if add_packet_data then
				buffer = add_packet_data
				add_packet_data = nil
				system.loadPlayerData(send_channel)
			end
			system.loadPlayerData(recv_channel)
		end
	end)
end