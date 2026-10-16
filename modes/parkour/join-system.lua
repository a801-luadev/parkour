local room_max_players = 12
local relock_ts

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == packets.bots.join then
		if packet == room.shortName and actual_player_count >= room.moduleMaxPlayers then
			tfm.exec.setRoomMaxPlayers(actual_player_count + 10)
			relock_ts = 15000 + os.time()
		end
	elseif id == packets.bots.change_lock then
		local roomName, limit = string.match(packet, "^([^\000]+)\000([^\000]+)$")
		if roomName == room.shortName then
			limit = tonumber(limit)
			if not limit then return end
			tfm.exec.setRoomMaxPlayers(limit)
		end
	end
end)

onEvent("Loop", function()
	if relock_ts and os.time() > relock_ts then
		tfm.exec.setRoomMaxPlayers(room_max_players)
	end
end)
