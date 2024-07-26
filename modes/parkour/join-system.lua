local room_max_players = 12

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == packets.bots.join then
		if packet == room.shortName then
			tfm.exec.setRoomMaxPlayers(room_max_players + 10)
			addNewTimer(15000, tfm.exec.setRoomMaxPlayers, room_max_players)
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