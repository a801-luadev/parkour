if tfm.get.room.name ~= "*#parkour0maps" then
	translatedChatMessage("maps_not_available")
	emergencyShutdown(true)
else
	tfm.exec.setRoomMaxPlayers(50)
	eventGameStart()
end