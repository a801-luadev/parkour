if tfm.get.room.name ~= "*#parkour0maps" then
	translatedChatMessage("maps_not_available")
	emergencyShutdown(true)
else
	eventGameStart()
	tfm.exec.setRoomMaxPlayers(50)
end