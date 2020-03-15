local next_file_load = os.time() + math.random(60500, 61500)
local file_id = 0
local players_file = {}
local room = tfm.get.room

local showMigrationPopup

local data_migrations = {
	["0.0"] = function(player, data)
		data.parkour = data.modules.parkour
		data.drawbattle = data.modules.drawbattle

		data.modules = nil

		data.parkour.v = "0.3" -- version
		data.parkour.c = data.parkour.cm -- completed maps
		data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
		data.parkour.mort = 1 -- /mort hotkey
		data.parkour.pcool = 1 -- power cooldowns
		data.parkour.pbut = 1 -- powers button
		data.parkour.keyboard = room.playerList[player].community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
		data.parkour.killed = 0

		data.parkour.cm = nil
	end,
	["0.1"] = function(player, data)
		data.parkour.v = "0.3"
		data.parkour.ckpart = 1
		data.parkour.mort = 1
		data.parkour.pcool = 1
		data.parkour.pbut = 1
		data.parkour.keyboard = room.playerList[player].community == "fr" and 0 or 1
		data.parkour.killed = 0
	end,
	["0.2"] = function(player, data)
		data.parkour.v = "0.3"
		data.parkour.killed = 0
	end
}

local function savePlayerData(player)
	if not players_file[player] then return end

	system.savePlayerData(
		player,
		json.encode(players_file[player])
	)
end

onEvent("PlayerDataLoaded", function(player, data)
	if player == stream_bot then return end

	local corrupt
	if data == "" then
		data = {}
		showMigrationPopup(player)
	else
		local done
		done, data = pcall(json.decode, data)

		if not done then
			data = {}
			translatedChatMessage("corrupt_data", player)
			corrupt = true
		end
	end

	if not data.parkour then
		if data.modules then
			data.parkour = {v = "0.0"}
		else
			data.parkour = {
				v = "0.1", -- version
				c = 0 -- completed maps
			}
		end
	end

	local migration = data_migrations[data.parkour.v or "0.0"]
	while migration do
		corrupt = true -- just so this process is made only once
		migration(player, data)
		migration = data_migrations[data.parkour.v]
	end

	players_file[player] = data

	if corrupt then
		savePlayerData(player)
	end

	eventPlayerDataParsed(player, data)
end)

onEvent("SavingFile", function(id, data)
	system.saveFile(json.encode(data), id)
end)

onEvent("FileLoaded", function(id, data)
	data = json.decode(data)
	eventGameDataLoaded(data)
	eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
end)

onEvent("Loop", function()
	if os.time() >= next_file_load then
		system.loadFile(file_id)
		next_file_load = os.time() + math.random(60500, 61500)
	end
end)

onEvent("GameStart", function()
	system.loadFile(file_id)
	next_file_load = os.time() + math.random(60500, 61500)
end)

onEvent("NewPlayer", function(player)
	system.loadPlayerData(player)
end)