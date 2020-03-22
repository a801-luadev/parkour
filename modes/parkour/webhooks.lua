webhooks = {_count = 0}

onEvent("GameDataLoaded", function(data)
	local now = os.time()
	if not data.webhooks or os.time() >= data.webhooks[1] then
		data.webhooks = {math.floor(os.time()) + 300000} -- 5 minutes
	end

	local last = #data.webhooks
	for index = 1, webhooks._count do
		data.webhooks[last + index] = webhooks[index]
	end
	webhooks._count = 0
end)