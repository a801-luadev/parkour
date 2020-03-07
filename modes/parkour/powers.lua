local room = tfm.get.room
local is_tribe = string.sub(room.name, 2, 2) == "\3"

local facing = {}
local despawning = {}
local cooldowns = {}

local function checkCooldown(player, name, long)
	if cooldowns[player] then
		if cooldowns[player][name] and os.time() < cooldowns[player][name] then
			return false
		end
		cooldowns[player][name] = os.time() + long
	else
		cooldowns[player] = {
			[name] = os.time() + long
		}
	end
	return true
end

local function despawnableObject(when, ...)
	local obj = tfm.exec.addShamanObject(...)
	if despawning[when] then
		despawning[when]._count = despawning[when]._count + 1
		despawning[when][despawning[when]._count] = {obj, os.time() + when}
	else
		despawning[when] = {
			_count = 1,
			_pointer = 1,
			[1] = {obj, os.time() + when}
		}
	end
end

local powers = {
	{
		name = 'snowball',
		maps = 0,
		cooldown = 5000,
		image = {url = '16896d045f9.png', x = 50, y = 40},

		qwerty = {key = "E", keyCode = 69},

		fnc = function(player, key, down, x, y)
			local right = facing[player]
			despawnableObject(5000, 34, x + (right and 20 or -20), y, 0, right and 10 or -10)
		end
	},
	{
		name = 'fly',
		maps = 3,
		cooldown = nil,
		image = {url = '16896d06614.png', x = 47, y = 33},

		qwerty = {key = "SPACE", keyCode = 32},

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, 0, -50, false)
		end
	},
	{
		name = 'balloon',
		maps = 5,
		cooldown = 10000,
		image = {url = '16896d0252b.png', x = 35, y = 20},

		qwerty = {key = "B", keyCode = 66},

		fnc = function(player, key, down, x, y)
			if players_file[player].parkour.c < 200 then
				despawnableObject(2000, 28, x, y + 10)
			end
		end
	},
	{
		name = 'speed',
		maps = 10,
		cooldown = 1000,
		image = {url = '16896ed356d.png', x = 35, y = 25},

		qwerty = {key = "SHIFT", keyCode = 16},

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
		end
	},
	{
		name = 'teleport',
		maps = 25,
		cooldown = 10000,
		image = {url = '16896d00614.png', x = 30, y = 20},

		click = true,

		fnc = tfm.exec.movePlayer
	},
	{
		name = 'smallbox',
		maps = 50,
		cooldown = 10000,
		image = {url = '1689fd4ffc4.jpg', x = 50, y = 40},

		qwerty = {key = "Z", keyCode = 90},
		azerty = {key = "W", keyCode = 87},

		fnc = function(player, key, down, x, y)
			despawnableObject(3000, 1, x, y + 10)
		end
	},
	{
		name = 'cloud',
		maps = 100,
		cooldown = 10000,
		image = {url = '1689fe8325e.png', x = 15, y = 25},

		qwerty = {key = "X", keyCode = 88},

		fnc = function(player, key, down, x, y)
			despawnableObject(2000, 57, x, y + 10)
		end
	},
	{
		name = 'masterBalloon',
		maps = 200,
		cooldown = 10000,
		image = {url = '168ab7be931.png', x = 15, y = 20},

		qwerty = {key = "C", keyCode = 67},

		fnc = function(player, key, down, x, y)
			if players_file[player].parkour.c < 400 then
				despawnableObject(3000, 2804, x, y + 10)
			end
		end
	},
	{
		name = 'bubble',
		maps = 400,
		cooldown = 10000,
		image = {url = '168ab822a4b.png', x = 30, y = 20},

		qwerty = {key = "Q", keyCode = 81},
		azerty = {key = "A", keyCode = 65},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 59, x, y + 12)
		end
	},
	{
		name = 'rip',
		maps = 700,
		cooldown = 10000,
		image = {url = '169495313ad.png', x = 38, y = 23},

		qwerty = {key = "V", keyCode = 86},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 90, x, y + 10)
		end
	},
	{
		name = 'choco',
		maps = 1500,
		cooldown = 25000,
		image = {url = '16d2ce46c57.png', x = 20, y = 56},

		qwerty = {key = "CTRL", keyCode = 17},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, 90)
		end
	}
}

local keyPowers, clickPowers = {
	qwerty = {},
	azerty = {}
}, {}
local player_keys = {}

local function bindNecessary(player)
	for key, power in next, player_keys[player] do
		if type(key) == "number" and players_file[player].parkour.c >= power.maps then
			system.bindKeyboard(player, key, true, true)
		end
	end

	for index = 1, #clickPowers do
		if players_file[player].parkour.c >= clickPowers[index].maps then
			system.bindMouse(player, true)
			break
		end
	end
end

local function unbind(player)
	for key, power in next, player_keys[player] do
		if type(key) == "number" then
			system.bindKeyboard(player, key, true, false)
		end
	end

	system.bindMouse(player, false)
end

onEvent("Keyboard", function(player, key, down, x, y)
	if key == 0 then
		facing[player] = false
		return
	elseif key == 2 then
		facing[player] = true
		return
	end

	local power = player_keys[player][key]
	if not power then return end

	if (not power.cooldown) or checkCooldown(player, power.name, power.cooldown) then
		power.fnc(player, key, down, x, y)
	end
end)

onEvent("Mouse", function(player, x, y)
	local power, cooldown
	for index = 1, #clickPowers do
		power = clickPowers[index]
		cooldown = (not power.cooldown) or checkCooldown(player, power.name, power.cooldown)
		if players_file[player] and players_file[player].parkour.c >= power.maps and cooldown then
			if power.fnc(player, x, y) == "break" then
				break
			end
		end
	end
end)

onEvent("NewPlayer", function(player)
	system.bindKeyboard(player, 0, true, true)
	system.bindKeyboard(player, 2, true, true)

	local keyboard = room.playerList[player].community == "fr" and "azerty" or "qwerty"
	player_keys[player] = keyPowers[keyboard]

	if victory[player] then
		bindNecessary(player)
	else
		unbind(player)
	end
end)

onEvent("PlayerWon", function(player)
	if room.uniquePlayers >= min_save and not is_tribe then
		completed = players_file[player].parkour.c + 1
		players_file[player].parkour.c = completed
		savePlayerData(player)
	end

	bindNecessary(player)
end)

onEvent("NewGame", function()
	facing = {}
	cooldowns = {}
	despawning = {}

	for player in next, in_room do
		unbind(player)
	end
end)

onEvent("GameStart", function()
	local clickPointer = 0
	local power
	for index = 1, #powers do
		power = powers[index]
		if power.click then
			clickPointer = clickPointer + 1
			clickPowers[clickPointer] = power
		else
			if not power.azerty then
				power.azerty = power.qwerty
			end

			keyPowers.qwerty[power.qwerty.keyCode] = power
			keyPowers.azerty[power.azerty.keyCode] = power

			keyPowers.qwerty[power] = power.qwerty.key
			keyPowers.azerty[power] = power.azerty.key
		end
	end
end)

onEvent("Loop", function()
	local now = os.time()
	local obj, newPointer
	for when, despawn in next, despawning do
		newPointer = despawn._pointer
		for index = despawn._pointer, despawn._count do
			obj = despawn[index]

			if now >= obj[2] then
				tfm.exec.removeObject(obj[1])
				newPointer = index + 1
			else
				break
			end
		end
		despawn._pointer = newPointer
	end
end)
