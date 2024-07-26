local addTextArea
do
	local add = ui.addTextArea
	local gsub = string.gsub
	function addTextArea(id, data, target)
		return add(id, gsub(data, "([Hh][Tt])([Tt][Pp])", "%1<%2"), target)
	end
end

local loading_file_time = os.time() + 11000
local loading_file_id
local pdata_requested = {}

local bit = bit or bit32
local callbacks = {
	send_room = bit.lshift(2, 8) + 255,
	load_map = bit.lshift(11, 8) + 255,
	load_file = bit.lshift(40, 8) + 255,
	load_pdata = bit.lshift(41, 8) + 255,
	send_update = bit.lshift(42, 8) + 255,
}
local textareas = {
	heartbeat = 1 + 255,
	action_error = 2 + 255,
}

local parkour_bot = "Parkour#0568"

onEvent("TextAreaCallback", function(id, player, data)
	if player ~= parkour_bot then return end

	if id == callbacks.send_room then
		local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
		packet_id = tonumber(packet_id)
		if not packet_id then return end

		eventSendingPacket(packet_id, packet)

	elseif id == callbacks.send_update then
		local seconds = tonumber(data)
		if not seconds then return end

		eventSendingPacket(packets.bots.game_update, os.time() + seconds * 1000)

	elseif id == callbacks.load_map then
		tfm.exec.newGame(data)

	elseif id == callbacks.load_file then
		local file_id = tonumber(data)

		if not file_id or file_id < 0 or file_id > 100 then
			addTextArea(textareas.action_error, "invalid file id", parkour_bot)
			return
		end

		if loading_file_id then
			addTextArea(textareas.action_error, "already loading a file", parkour_bot)
			return
		end

		loading_file_id = file_id

	elseif id == callbacks.load_pdata then
		pdata_requested[data] = os.time() + 2000
		system.loadPlayerData(data)
	end
end)

onEvent("SendingPacket", function(id, packet)
	if id == packets.bots.announce then -- !announcement
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	end

	sendPacket("bots", id, packet)
end)

onEvent("PacketReceived", function(channel, id, packet, map, time)
	if channel ~= "common" then return end

	if id <= 255 then -- see textareas
		addTextArea(id, packet, parkour_bot)
	end
end)

onEvent("Loop", function()
	addTextArea(textareas.heartbeat, "", parkour_bot)

	if loading_file_id and os.time() > loading_file_time then
		system.loadFile(loading_file_id)

		loading_file_time = os.time() + 11000
		loading_file_id = nil
	end

	local clear = {}
	local now = os.time()
	for name, ts in next, pdata_requested do
		if now > ts then
			clear[1+#clear] = name
		end
	end
	for i=1, #clear do
		pdata_requested[clear[i]] = nil
	end
end)

onEvent("FileLoaded", function(file, data)
	tfm.exec.playMusic(tostring(data), 'file:' .. tostring(file), 0, false, false, parkour_bot)
end)

onEvent("PlayerDataLoaded", function(player, file)
	if not pdata_requested[player] then return end
	pdata_requested[player] = nil
	tfm.exec.playMusic(tostring(file), 'pdata:' .. tostring(player), 0, false, false, parkour_bot)
end)

tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableMortCommand(true)
tfm.exec.newGame(0)
tfm.exec.setRoomMaxPlayers(50)
