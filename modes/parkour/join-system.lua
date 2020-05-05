onEvent("PacketReceived", function(packet_id, packet)
	if packet_id == 0 then
		if packet == room.name then
			tfm.exec.setRoomMaxPlayers(20)
			addNewTimer(15000, tfm.exec.setRoomMaxPlayers, 12)
		end
	end
end)