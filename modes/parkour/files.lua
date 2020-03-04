local next_file_load = os.time() + 61000
local file_id = 0
local players_file = {}

local showMigrationPopup

local data_migrations = {
	["0.0"] = function(player, data)
		data.parkour = data.modules.parkour
		data.drawbattle = data.modules.drawbattle

		data.modules = nil

		data.parkour.v = "0.1"
		data.parkour.c = data.parkour.cm
		data.parkour.cm = nil
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
end)

onEvent("FileLoaded", function(id, data)
	data = json.decode(data)
	eventGameDataLoaded(data)
	system.saveFile(json.encode(data), id)
end)

onEvent("Loop", function()
	if os.time() >= next_file_load then
		system.loadFile(file_id)
		next_file_load = os.time() + 61000
	end
end)

onEvent("GameStart", function()
	system.loadFile(file_id)
	next_file_load = os.time() + 61000
end)

onEvent("NewPlayer", function(player)
	system.loadPlayerData(player)
end)