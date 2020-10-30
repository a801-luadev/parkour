local room_max_players = 12

onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 0 then
		if packet == room.shortName then
			tfm.exec.setRoomMaxPlayers(room_max_players + 10)
			addNewTimer(15000, tfm.exec.setRoomMaxPlayers, room_max_players)
		end
	end
end)