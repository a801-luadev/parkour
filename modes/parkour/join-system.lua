local room_max_players = 20

onEvent("PacketReceived", function(channel, id, packet)
	if channel ~= "bots" then return end

	if id == 0 then
		if packet == room.shortName then
			tfm.exec.setRoomMaxPlayers(room_max_players + 10)
			addNewTimer(15000, tfm.exec.setRoomMaxPlayers, room_max_players)
		end
	end
end)