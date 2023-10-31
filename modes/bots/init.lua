local addTextArea
do
	local add = ui.addTextArea
	local gsub = string.gsub
	function addTextArea(id, data, target)
		return add(id, gsub(data, "([Hh][Tt])([Tt][Pp])", "%1<%2"), target)
	end
end

local bit = bit or bit32
local packets = {
	send_room = bit.lshift(2, 8) + 255,
	send_webhook = bit.lshift(3, 8) + 255,
	load_map = bit.lshift(11, 8) + 255,
	weekly_reset = bit.lshift(12, 8) + 255,
	command_log = bit.lshift(26, 8) + 255,
	ban_logs = bit.lshift(32, 8) + 255,
	kill_logs = bit.lshift(33, 8) + 255,
	map_votes = bit.lshift(34, 8) + 255,
}

local parkour_bot = "Parkour#0568"

onEvent("TextAreaCallback", function(id, player, data)
	if player ~= parkour_bot then return end

	if id == packets.send_room then
		local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
		packet_id = tonumber(packet_id)
		if not packet_id then return end

		eventSendingPacket(packet_id, packet)

	elseif id == packets.load_map then
		tfm.exec.newGame(data)
	end
	
end)

onEvent("SendingPacket", function(id, packet)

	if id == 4 then -- !announcement
		tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
	end

	sendPacket("bots", id, packet)
end)

onEvent("PacketReceived", function(channel, id, packet, map, time)
	if channel ~= "common" then return end

	if id == 4 then
		addTextArea(packets.weekly_reset, packet, parkour_bot)

	elseif id == 7 then
		addTextArea(packets.command_log, packet, parkour_bot)

	elseif id == 9 then
		addTextArea(packets.ban_logs, packet, parkour_bot)

	elseif id == 10 then
		addTextArea(packets.kill_logs, packet, parkour_bot)
		
	elseif id == 11 then
		addTextArea(packets.map_votes, packet, parkour_bot)
	end
end)

tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableMortCommand(true)
tfm.exec.newGame(0)
tfm.exec.setRoomMaxPlayers(50)
