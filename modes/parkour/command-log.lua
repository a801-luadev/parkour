local function logCommand(author, cmd, quantity, args)
	if quantity and quantity > 0 and args then
		cmd = cmd .. " " .. table.concat(args, " ", 1, quantity)
	end

	sendPacket("common", 7, room.shortName .. "\000" .. author .. "\000" .. cmd)
end