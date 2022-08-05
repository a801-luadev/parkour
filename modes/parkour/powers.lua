local max_leaderboard_rows
local leaderboard
local keyboard

no_powers = {}
local facing = {}
local cooldowns = {}
local obj_whitelist = {_count = 0, _index = 1}
local keybindings = {}
local used_powers = {_count = 0}

-- Keep track of the times the key has been binded and wrap system.bindKeyboard
function bindKeyboard(player, key, down, active)
	if not keybindings[player] then
		if not active then return end

		keybindings[player] = {
			[key] = {
				[down] = 0,
				[not down] = 0
			}
		}
	end

	local keyInfo = keybindings[player][key]
	if not keyInfo then
		if not active then return end

		keyInfo = {
			[down] = 1,
			[not down] = 0
		}
		keybindings[player][key] = keyInfo
	elseif active then
		keyInfo[down] = keyInfo[down] + 1
	else
		keyInfo[down] = keyInfo[down] - 1
	end

	if keyInfo[down] == 1 then
		system.bindKeyboard(player, key, down, true)
	elseif keyInfo[down] == 0 then
		system.bindKeyboard(player, key, down, false)
	end
end

local function addShamanObject(id, x, y, ...)
	obj_whitelist._count = obj_whitelist._count + 1
	obj_whitelist[obj_whitelist._count] = {id, x, y}
	return tfm.exec.addShamanObject(id, x, y, ...)
end

function checkCooldown(player, name, long, img, x, y, show)
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

	if show then
		addNewTimer(
			long, tfm.exec.removeImage,
			tfm.exec.addImage(img, ":1", x, y, player)
		)
	end

	return true
end

local function despawnableObject(when, ...)
	local obj = addShamanObject(...)
	addNewTimer(when, tfm.exec.removeObject, obj)
	return obj
end

local function fixHourCount(player, data)
	local reset = data.hour_r
	local hour = data.hour
	local count = #hour
	local save = false

	local now = os.time()
	if now - reset >= 3600000 then -- 1 hour
		save = true

		local index
		local absolute
		for i = 1, count do
			absolute = hour[i] * 10000 + reset

			if now - absolute >= 3600000 then
				hour[i] = nil
			else
				index = i + 1 -- avoid hour check as they're younger than 1 hour
				-- change offset
				hour[i] = math.floor((absolute - now) / 10000)
				break
			end
		end

		if index then
			for i = index, count do
				hour[i] = math.floor(
					(hour[i] * 10000 + reset - now) / 10000
				)
			end
		end

		data.hour_r = now
		reset = now
	else
		for i = 1, count do
			if now - (hour[i] * 10000 + reset) >= 3600000 then
				hour[i] = nil
			else
				break
			end
		end
	end

	-- Normalize indexes
	local offset = 0
	for i = 1, count do
		if hour[i] then
			if offset == 0 then
				break
			end

			hour[i - offset] = hour[i]
		else
			offset = offset + 1
		end
	end

	for i = count - offset + 1, count do
		hour[i] = nil
	end

	if player and (save or offset > 0) then
		savePlayerData(player)
	end

	return save or offset > 0
end

-- in small x: positive -> towards the sides, negative -> towards the center
local powers
powers = {
	{
		name = "fly", maps = 5,
		isVisual = true,

		small = "173db50edf6.png", big = "173db512e9c.png", -- icons
		lockedSmall = "173db51091f.png", lockedBig = "173db5151fd.png",
		smallX = 0, smallY = -10,
		bigX = 0, bigY = -10,

		cooldown = nil,
		default = {5, 4}, -- SPACE

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, nil, -50, false)
		end
	},
	{
		name = "speed", maps = 10,
		isVisual = true,

		small = "173db21af6a.png", big = "173db214773.png",
		lockedSmall = "173db21d270.png", lockedBig = "173db217990.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 8,
		cooldown_y = 373,
		cooldown_img = "17127e682ff.png",

		cooldown = 1000,
		default = {4, 1}, -- SHIFT

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
		end
	},
	{
		name = "snowball", maps = 15,

		small = "173db1165c1.png", big = "173db111ba4.png",
		lockedSmall = "173db118b89.png", lockedBig = "173db114395.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 30,
		cooldown_y = 374,
		cooldown_img = "17127e6674c.png",

		cooldown = 12500,
		default = {2, 4}, -- E

		fnc = function(player, key, down, x, y)
			local right = facing[player]
			despawnableObject(5000, 34, x + (right and 20 or -20), y, 0, right and 10 or -10)
		end
	},
	{
		name = "balloon", maps = 20,

		small = "173db033fb8.png", big = "173db02a545.png",
		lockedSmall = "173db039519.png", lockedBig = "173db035f01.png",
		smallX = 0, smallY = -10,
		bigX = 0, bigY = 0,

		cooldown_x = 52,
		cooldown_y = 372,
		cooldown_img = "17127e5b2d5.png",

		cooldown = 10000,
		default = {2, 2}, -- Q, A

		fnc = function(player, key, down, x, y)
			despawnableObject(2000, 28, x, y + 10)
		end,

		upgrades = {
			{
				name = "masterBalloon", maps = 200,

				small = "173db167a26.png", big = "173db165783.png",
				smallX = 0, smallY = 10,
				bigX = 0, bigY = 10,

				cooldown_img = "17127e62809.png",

				fnc = function(player, key, down, x, y)
					despawnableObject(3000, 2804, x, y + 10)
				end
			},
			{
				name = "bubble", maps = 400,

				small = "173db16a824.png", big = "173db175547.png",
				smallX = 0, smallY = 0,
				bigX = 0, bigY = 0,

				cooldown_img = "17127e5ca47.png",

				fnc = function(player, key, down, x, y)
					despawnableObject(4000, 59, x, y + 12)
				end
			},
		}
	},
	{
		name = "teleport", maps = 35,
		isVisual = true,

		small = "173db226b7a.png", big = "173db21f2b7.png",
		lockedSmall = "173db22ee81.png", lockedBig = "173db223336.png",
		smallX = 10, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 74,
		cooldown_y = 373,
		cooldown_img = "17127e73965.png",

		cooldown = 10000,
		click = true,

		fnc = tfm.exec.movePlayer
	},
	{
		name = "smallbox", maps = 50,

		small = "173db0ecb64.png", big = "173db0cd7fb.png",
		lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
		smallX = 10, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 96,
		cooldown_y = 373,
		cooldown_img = "17127e77dbe.jpg",

		cooldown = 10000,
		default = {4, 3}, -- Z, W

		fnc = function(player, key, down, x, y)
			despawnableObject(3000, 1, x, y + 10)
		end
	},
	{
		name = "cloud", maps = 100,

		small = "173db14a1d6.png", big = "173db145497.png",
		lockedSmall = "173db15baf3.png", lockedBig = "173db15868b.png",
		smallX = 0, smallY = 10,
		bigX = 0, bigY = 20,

		cooldown_x = 121,
		cooldown_y = 377,
		cooldown_img = "17127e5f927.png",

		cooldown = 10000,
		default = {4, 4}, -- X

		fnc = function(player, key, down, x, y)
			despawnableObject(2000, 57, x, y + 10)
		end
	},
	{
		name = "rip", maps = 700,

		small = "173db33e169.png", big = "173db33602c.png",
		lockedSmall = "173db3407b0.png", lockedBig = "173db33ac9c.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 142,
		cooldown_y = 373,
		cooldown_img = "17127e69ea4.png",

		cooldown = 10000,
		default = {4, 6}, -- V

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 90, x, y + 10)
		end
	},
	{
		name = "choco", maps = 1500,

		small = "173db2812bc.png", big = "173db27b241.png",
		lockedSmall = "173db2853a0.png", lockedBig = "173db27dba6.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 164,
		cooldown_y = 374,
		cooldown_img = "17127fc6b27.png",

		cooldown = 25000,
		default = {5, 1}, -- CTRL

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, 90)
		end
	},
	{
		name = "bigBox", maps = 2500,

		small = "173db0ecb64.png", big = "173db0cd7fb.png",
		lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 186,
		cooldown_y = 374,
		cooldown_img = "17127e77dbe.jpg",

		cooldown = 25000,
		default = {4, 7}, -- B

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 2, x, y + 10, 0)
		end
	},
	{
		name = "trampoline", maps = 4000,

		small = "173db3307ed.png", big = "173db3288d3.png",
		lockedSmall = "173db3335b7.png", lockedBig = "173db32e496.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_x = 208,
		cooldown_y = 374,
		cooldown_img = "171cd9f5188.png",

		cooldown = 25000,
		default = {4, 8}, -- N

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 701, x, y + 10, 0)
		end
	},
	{
		name = "pig", maps = 5000,

		small = "173deea75bd.png", big = "173deea2cc0.png",
		lockedSmall = "173deea9a02.png", lockedBig = "173deea4edc.png",
		smallX = 0, smallY = 20,
		bigX = 0, bigY = 15,

		cooldown_x = 229,
		cooldown_y = 380,
		cooldown_img = "1741cfb9868.png",

		cooldown = 30000,
		default = {3, 9}, -- K

		piggies = {
			"17404198506.png", -- angry
			"174042180f2.png", -- crying
			"174042d5ba0.png", -- love
			"174042eda4f.png", -- blushed
			"174043b0085.png", -- clown
			"1740455e72a.png", -- glasses
			"1740455bd82.png", -- smoking
			"17404561700.png", -- glasses blushed
			"1745e9316ae.png", -- roasted
		},

		fnc = function(player, key, down, x, y)
			local id1 = bit32.bxor(room.playerList[player].id, 32768) -- unfortunately physicobjects only use 16 bits as id
			local id2 = bit32.bxor(room.playerList[player].id, 16384)
			local sprite = powers.pig.piggies[math.random(#powers.pig.piggies)]
			local img = tfm.exec.addImage(sprite, "_51", x - 24, y - 15)

			local circles = {
				type = 14,
				friction = 0.3
			}
			tfm.exec.addPhysicObject(id1, x + 13, y, circles)
			tfm.exec.addPhysicObject(id2, x - 5, y + 2, circles)

			addNewTimer(5000, powers.pig.explode, id1, id2, img, x, y)
			addNewTimer(
				5000,
				tfm.exec.removeImage,
				tfm.exec.addImage("17797e8de0d.png", "_52", x - 30, y - 28)
			)
		end,

		explode = function(id1, id2, img, x, y)
			tfm.exec.removePhysicObject(id1)
			tfm.exec.removePhysicObject(id2)
			tfm.exec.removeImage(img)

			for confetti = 1, 10 do
				tfm.exec.displayParticle(math.random(21, 24), x, y, math.random(-10, 10), math.random(-10, 10))
			end
			tfm.exec.explosion(x, y, 10, 100, true)
		end
	},
	{
		name = "sink", ranking = 70,

		small = "173deeb1e05.png", big = "173deeac174.png",
		lockedSmall = "173deeb3dac.png", lockedBig = "173deeaf781.png",
		smallX = 0, smallY = 10,
		bigX = 5, bigY = 10,

		cooldown_x = 252,
		cooldown_y = 374,
		cooldown_img = "1741cfd281e.png",

		cooldown = 30000,
		default = {4, 5}, -- C

		fnc = function(player, key, down, x, y)
			local id = room.playerList[player].id
			local img = tfm.exec.addImage("17426b19d76.png", "_51", x - 20, y - 10)
			tfm.exec.addPhysicObject(id, x, y + 13, {
				type = 14,
				friction = 0.3,
				width = 30
			})

			addNewTimer(5000, powers.sink.despawn, id, img)
		end,

		despawn = function(id, img)
			tfm.exec.removePhysicObject(id)
			tfm.exec.removeImage(img)
		end,

		upgrades = {
			{
				name = "toilet", ranking = 56,

				small = "173db3f2c95.png", big = "173db3f0d81.png",
				smallX = 0, smallY = -10,
				bigX = 10, bigY = 0,

				cooldown_img = "171cd9e02d3.png",

				fnc = function(player, key, down, x, y)
					local id = room.playerList[player].id
					local img = tfm.exec.addImage("171cd3eddf1.png", "_51", x - 20, y - 20)
					tfm.exec.addPhysicObject(id, x, y + 13, {
						type = 14,
						friction = 0.3,
						width = 30
					})

					addNewTimer(5000, powers.toilet.water, img, id, x, y)
				end,

				water = function(img, id, x, y)
					tfm.exec.removeImage(img)

					local obj = addShamanObject(63, x, y)
					tfm.exec.addPhysicObject(id, x, y - 20, {
						type = 9,
						width = 30,
						height = 60,
						miceCollision = false,
						groundCollision = false,
						foreground = true
					})

					addNewTimer(5000, powers.toilet.despawn, id, obj)
				end,

				despawn = function(id, obj)
					tfm.exec.removePhysicObject(id)
					tfm.exec.removeObject(obj)
				end
			},
			{
				name = "bathtub", ranking = 42,

				small = "173deeb8924.png", big = "173deeb6576.png",
				smallX = 0, smallY = 5,
				bigX = 5, bigY = 10,

				cooldown_img = "1741cfd8396.png",

				fnc = function(player, key, down, x, y)
					local id = room.playerList[player].id
					local img = tfm.exec.addImage("17426f98ce6.png", "!1", x - 48, y - 65)
					tfm.exec.addPhysicObject(id, x, y + 13, {
						type = 14,
						friction = 0.3,
						width = 80
					})

					addNewTimer(5000, powers.bathtub.water, img, id, x, y)
				end,

				water = function(img, id, x, y)
					tfm.exec.removeImage(img)

					tfm.exec.addPhysicObject(id, x, y - 40, {
						type = 9,
						width = 90,
						height = 80,
						miceCollision = false,
						groundCollision = false,
						foreground = true
					})

					addNewTimer(5000, powers.bathtub.despawn, id)
				end,

				despawn = function(id, obj)
					tfm.exec.removePhysicObject(id)
				end
			},
		}
	},
	{
		name = "campfire", ranking = 28,
		isVisual = true,

		small = "173dee9c5d9.png", big = "173dee98c61.png",
		lockedSmall = "173dee9e873.png", lockedBig = "173dee9aaea.png",
		smallX = 0, smallY = 10,
		bigX = 0, bigY = 10,

		cooldown_x = 274,
		cooldown_y = 376,
		cooldown_img = "1741cfdadc9.png",

		cooldown = 15000,
		default = {3, 8}, -- J

		fnc = function(player, key, down, x, y)
			local id = room.playerList[player].id + 2147483648 -- makes 32nd bit 1 so it doesn't play around with the interface textareas

			local img = tfm.exec.addImage("17426539be5.png", "_51", x - 30, y - 26)
			ui.addTextArea(id, "<a href='event:emote:11'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", nil, x - 32, y - 26, 64, 56, 0, 0, 0)
			addNewTimer(powers.campfire.cooldown, powers.campfire.despawn, img, id)
		end,

		despawn = function(img, id)
			tfm.exec.removeImage(img)
			ui.removeTextArea(id)
		end
	},
	{
		name = "chair", ranking = 14,

		small = "1745a769e88.png", big = "1745a765105.png",
		lockedSmall = "1745a76c506.png", lockedBig = "1745a7675e6.png",
		smallX = 0, smallY = 10,
		bigX = 10, bigY = 10,

		cooldown_x = 296,
		cooldown_y = 376,
		cooldown_img = "17459a21979.png",

		cooldown = 15000,
		default = {3, 6}, -- G

		fnc = function(player, key, down, x, y)
			local id = bit32.bxor(room.playerList[player].id, 49152)
			local img = tfm.exec.addImage("17459a230e9.png", "_51", x - 30, y - 20)
			tfm.exec.addPhysicObject(id, x - 5, y + 20, {
				type = 14,
				friction = 0.3,
				width = 32
			})

			addNewTimer(14000, powers.chair.despawn, id, img)
		end,

		despawn = function(id, img)
			tfm.exec.removePhysicObject(id)
			tfm.exec.removeImage(img)
		end
	},
}

local keys = {
	triggers = {}
}

local function getPowerUpgrade(completed, pos, power, strict, with_review)
	if with_review then
		if not power.upgrades then return power end
		return power.upgrades[#power.upgrades]
	end

	if strict then
		if power.ranking and power.ranking < pos then return end
		if not power.ranking and completed < power.maps then return end
	end

	if not power.upgrades then return power end

	local upgrade
	for index = #power.upgrades, 1, -1 do
		upgrade = power.upgrades[index]
		if upgrade.ranking then
			if upgrade.ranking >= pos then
				return upgrade
			end
		elseif (completed or 0) >= upgrade.maps then
			return upgrade
		end
	end

	return power
end

function bindNecessary(player)
	if not keys[player] or not players_file[player] or keys.triggers[player] then return end

	local triggers = {}
	local completed = players_file[player].c
	local pos = leaderboard[player] or max_leaderboard_rows + 1
	local variation_index = players_file[player].settings[5] + 1

	local player_keys = keys[player]
	local power, key
	for index = 1, #powers do
		power = getPowerUpgrade(completed, pos, powers[index], true, review_mode or timed_maps.week.last_reset == "28/02/2021")

		if (power and
			(power.isVisual or (not records_admins and submode ~= "smol"))) then
			if power.click then
				system.bindMouse(player, true)
			else
				if player_keys[index] then
					key = player_keys[index]
				elseif powers[index].key[1] then -- variation qwerty/azerty
					key = keyboard.bindings[ powers[index].key[variation_index] ]
				else
					key = keyboard.bindings[ powers[index].key ]
				end

				if triggers[key] then
					triggers[key]._count = triggers[key]._count + 1
					triggers[key][ triggers[key]._count ] = power
				else
					triggers[key] = {_count = 1, [1] = power}
					bindKeyboard(player, key, true, true)
				end
			end
		end
	end

	bindKeyboard(player, 0, true, true)
	bindKeyboard(player, 2, true, true)

	keys.triggers[player] = triggers
end

function unbind(player)
	if not keys.triggers[player] then return end

	bindKeyboard(player, 0, true, false)
	bindKeyboard(player, 2, true, false)
	for key in next, keys.triggers[player] do
		bindKeyboard(player, key, true, false)
	end
	system.bindMouse(player, false)

	keys.triggers[player] = nil
end

onEvent("Keyboard", function(player, key, down, x, y)
	if not victory[player] or not players_file[player] or not keys.triggers[player] then return end
	if spec_mode[player] then return end

	if key == 0 or key == 2 then
		facing[player] = key == 2
		return
	end

	local power = keys.triggers[player][key]
	if power then
		for index = 1, power._count do
			if power[index] and (not power[index].cooldown or checkCooldown(
				player, power[index].name, power[index].cooldown,

				power[index].cooldown_img,
				power[index].cooldown_x, power[index].cooldown_y,

				players_file[player].settings[3] == 1
			)) and (power[index].isVisual or (not records_admins and submode ~= "smol")) then
				power[index].fnc(player, key, down, x, y)

				if not power[index].isVisual then
					used_powers._count = used_powers._count + 1
					used_powers[ used_powers._count ] = {player, power[index].name}
				end
			end
		end
	end
end)

onEvent("Mouse", function(player, x, y)
	if not victory[player] or not players_file[player] then return end

	local power = powers.teleport
	if players_file[player].c >= power.maps then
		if (not power.cooldown or checkCooldown(
			player, power.name, power.cooldown,

			power.cooldown_img,
			power.cooldown_x, power.cooldown_y,

			players_file[player].settings[3] == 1
		)) and (power.isVisual or (not records_admins and submode ~= "smol")) then
			power.fnc(player, x, y)

			if not power.isVisual then
				used_powers._count = used_powers._count + 1
				used_powers[ used_powers._count ] = {player, power.name}
			end
		end
	end
end)

onEvent("GameStart", function()
	local upgrade
	for index = 1, #powers do
		powers[ powers[index].name ] = powers[index]

		if powers[index].upgrades then
			for _index = 1, #powers[index].upgrades do
				upgrade = powers[index].upgrades[_index]
				powers[ upgrade.name ] = upgrade

				upgrade.cooldown_x = powers[index].cooldown_x
				upgrade.cooldown_y = powers[index].cooldown_y
				upgrade.cooldown = powers[index].cooldown
			end
		end
	end
end)

onEvent("PlayerLeft", function(player)
	keys.triggers[player] = nil
	keybindings[player] = nil
end)

onEvent("PlayerDataParsed", function(player, data)
	keys[player] = {}
	for index = 1, #data.keys do
		if data.keys[index] > 0 then
			keys[player][index] = data.keys[index]
		end
	end

	if data.killed > os.time() then
		no_powers[player] = true
		translatedChatMessage("kill_minutes", player, math.ceil((data.killed - os.time()) / 1000 / 60))
	else
		no_powers[player] = nil
	end

	if victory[player] then
		if not no_powers[player] then
			bindNecessary(player)
		end
	else
		unbind(player)
	end

	-- don't save as it will trigger this twice, and this will be saved
	-- right after this event finishes anyway
	fixHourCount(nil, data)
end)

onEvent("PlayerDataUpdated", function(player, data)
	if data.killed > os.time() then
		if not no_powers[player] then
			no_powers[player] = true
			unbind(player)
		end
		translatedChatMessage("kill_minutes", player, math.ceil((data.killed - os.time()) / 1000 / 60))
	elseif no_powers[player] then
		no_powers[player] = nil
		if victory[player] then
			bindNecessary(player)
		end
	end

	-- don't loop infinitely
	-- calling savePlayerData loads data first, so this will get triggered again
	-- and it will call savePlayerData again, which will load again and trigger
	-- this again.
	if fixHourCount(nil, data) then
		to_save[player] = true
	end
end)

onEvent("PlayerWon", function(player)
	local id = room.playerList[player].id
	if bans[ id ] then return end
	if victory[player] then return end
	local file = players_file[player]
	if not file then return end

	if (count_stats and
		room.uniquePlayers >= min_save and
		player_count >= min_save and
		not records_admins and
		not is_tribe and
		not review_mode) then

		local map_overall, map_weekly = 1, 1
		--[=[
		if timed_maps.week.last_reset == "28/02/2021" then
			map_weekly = 2
		end
		if os.date("%d/%m/%Y", os.time() + 60 * 60 * 1000) == "06/03/2021" then
			map_overall = 2
		end
		]=]

		file.c = file.c + map_overall

		file.tc = math.max(
			checkTitleAndNextFieldValue(player, titles.press_m, map_overall, file, id),
			checkTitleAndNextFieldValue(player, titles.piglet, map_overall, file, id)
		)

		file.cc = checkTitleAndNextFieldValue(player, titles.checkpoint, #levels - 1 --[[total checkpoints but spawn]], file, id)

		file.hour[#file.hour + 1] = math.floor((os.time() - file.hour_r) / 10000) -- convert to ms and count every 10s
		file.week[1] = file.week[1] + map_weekly

		local hour_count = #file.hour

		if hour_count >= 30 and hour_count % 5 == 0 then
			if hour_count >= 35 then
				sendPacket("common", 3, room.shortName .. "\000" .. room.playerList[player].id .. "\000" .. player .. "\000" .. hour_count)
			end

			local badge = math.ceil((hour_count - 29) / 5)
			if badge <= #badges[4] then
				if file.badges[4] == 0 or file.badges[4] < badge then
					file.badges[4] = badge
					NewBadgeInterface:show(player, 4, badge)
				end
			end
		end

		savePlayerData(player)
	end

	if not no_powers[player] then
		bindNecessary(player)
	end
end)

onEvent("NewGame", function()
	local now = os.time()

	local to_remove, count = {}, 0
	for player in next, no_powers do
		if not players_file[player] or players_file[player].killed <= now then
			count = count + 1
			to_remove[count] = player
		end
	end

	for index = 1, count do
		no_powers[to_remove[index]] = nil
	end

	facing = {}
	cooldowns = {}
	obj_whitelist = {_count = 0, _index = 1}

	setmetatable(room.objectList, {
		__newindex = function(self, key, value)
			if self[key] == value then return end

			rawset(self, key, value)

			local obj
			for index = obj_whitelist._index, obj_whitelist._count do
				obj = obj_whitelist[index]
				if obj[1] ~= value.type or obj[2] ~= value.x or obj[3] ~= value.y then
					tfm.exec.removeObject(key)
				else
					obj_whitelist._index = index + 1
				end
				break
			end
		end
	})

	local file
	for player in next, in_room do
		file = players_file[player]
		if file then
			fixHourCount(player, file)
		end
		unbind(player)
	end
end)
