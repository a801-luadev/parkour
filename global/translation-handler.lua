local player_langs = {}

local translatedChatMessage
do
	local chatMessage = tfm.exec.chatMessage
	function translatedChatMessage(what, who, ...)
		if not who then
			for player in next, player_langs do
				translatedChatMessage(what, player, ...)
			end
			return
		end
		local text = player_langs[who][what]
		if not text then
			text = "%" .. what .. "%"
		elseif select("#", ...) > 0 then
			done, text = pcall(string.format, text, ...)
			if not done then
				error(debug.traceback())
			end
		end
		chatMessage(text, who)
	end
end

onEvent("NewPlayer", function(player)
	player_langs[player] = translations[tfm.get.room.playerList[player].community]
end)