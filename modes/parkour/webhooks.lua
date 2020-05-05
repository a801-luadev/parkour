webhooks = {_count = 0}

onEvent("ChannelLoad", function()
	for index = 1, webhooks._count do
		sendPacket(1, webhooks[index])
	end
end)