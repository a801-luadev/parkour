local player_langs = {}

local translatedMessage
do
	local community = tfm.get.room.community
	function translatedMessage(what, who, ...)
		local lang
		if who then
			lang = player_langs[who]
		else
			lang = translations[community]
		end
		local text = lang and lang[what] or nil
		if not text then
			return "%" .. what .. "%"
		elseif select("#", ...) > 0 then
			done, text = pcall(string.format, text, ...)
			if not done then
				error(debug.traceback(what .. "," .. text))
			end
		end
		return text
	end
end

--local translatedChatMessage
do
	local chatMessage = tfm.exec.chatMessage
	function translatedChatMessage(what, who, ...)
		if not who then
			for player in next, player_langs do
				translatedChatMessage(what, player, ...)
			end
			return
		end
		local msg = translatedMessage(what, who, ...)
		local length = #msg

		while length > 1000 do
			chatMessage(string.sub(msg, 1, 1000), who)
			msg = string.sub(msg, 1001)
			length = length - 1000
		end
		if length > 0 then
			chatMessage(msg, who)
		end
	end
end

onEvent("NewPlayer", function(player)
	player_langs[player] = translations[tfm.get.room.playerList[player].community]
end)