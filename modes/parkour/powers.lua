local max_leaderboard_rows
local leaderboard
local keyboard

no_powers = {}
local used_powers = {_count = 0}
disable_powers = room.name:lower():find('nohelp') and true
local first_player = nil

local keys
local powers
local checkKill
local getPowerUpgrade

do
local facing = {}
local cooldowns = {}
local obj_whitelist = {_count = 0, _index = 1}
local keybindings = {}
local cooldownMultiplier = 1
local cooldownSlots = {}
local booster = {}

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

	if keyInfo[down] < 0 then
		keyInfo[down] = 0
		return
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

local function clearCooldownSlot(player, index)
	if not cooldownSlots[player] then return end
	tfm.exec.removeImage(cooldownSlots[player][index], true)
	cooldownSlots[player][index] = nil
end

function checkCooldown(player, name, long, img, scale, show)
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
		if not cooldownSlots[player] then
			cooldownSlots[player] = {}
		end

		local slotIndex = #cooldownSlots[player] + 1
		cooldownSlots[player][slotIndex] = tfm.exec.addImage(img, ":1", slotIndex * 30, 384, player, scale, scale, 0, 1, 0.5, 0.5)
		addNewTimer(long, clearCooldownSlot, player, slotIndex)
	end

	return true
end

local function despawnableObject(when, id, ...)
	if not id then return end
	local obj = addShamanObject(id, ...)
	if obj then
		addNewTimer(when, tfm.exec.removeObject, obj)
	end
	return obj
end

local function spawnSkinObj2(when, so, skin, tab, ...)
	skin = skin and (shop_skins[skin] or file_skins[skin])
	so = so or skin and skin.so or default_skins_by_cat[tab]
	if not so then return end

	local obj = despawnableObject(when, so, ...)
	if not obj then return end
	if not skin or not skin.img then return end
	tfm.exec.addImage(
		skin.img,
		"#"..obj,
		0, 0, nil,
		skin.scale or 1, skin.scale or 1, 0, 1,
		skin.x or 0.5, skin.y or 0.52
	)
end

local function spawnSkinObj(when, player, tab, ...)
	local skin = players_file[player] and players_file[player]:getEquipped(tab)
	return spawnSkinObj2(when, nil, skin, tab, ...)
end

local function fixHourCount(data)
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

	return save or offset > 0
end

local shop_powers = {}
shop_powers[1] = {
	name = "snowball",
	cooldown_img = "17127e6674c.png",
	cooldown = 12500,

	cond = function(player, key, down, x, y)
		return not isAieMap
	end,

	fnc = function(self, player, key, down, x, y)
		local right = facing[player]
		spawnSkinObj(5000, player, 9, x + (right and 20 or -20), y, right and 0 or 180, right and 10 or -10)
	end
}
shop_powers[2] = {
	name = "snowmouse",
	cooldown_img = "1507c1da0e8.png",
	cooldown_scale = 0.36,
	cooldown = 15000,

	fnc = function(self, player, key, down, x, y)
		local id = allocateId("textarea", 1000, 10000)
		local antiGrav = map_gravity <= 0
		local img = tfm.exec.addImage("1507c1da0e8.png", "_101", x, y - 10, nil, 0.8, 0.8 * (antiGrav and -1 or 1), 0, 1, 0.5, antiGrav and -0.5 or 0.5)
		local img2 = tfm.exec.addImage("img@194284eba8d", "!101", x, y - 10, nil, 0.5, 0.5, math.random(400) / 100, 1, 0.5, 0.5)

		local g1 = allocateId("ground", 1000, 10000)
		local g2 = allocateId("ground", 1000, 10000)
		local g3 = allocateId("ground", 1000, 10000)
		local j1 = allocateId("joint", 1000, 10000)
		local j2 = allocateId("joint", 1000, 10000)
		local j3 = allocateId("joint", 1000, 10000)

		tfm.exec.addPhysicObject(g1, x, y, {
			type = 14,
			miceCollision = false,
			groundCollision = false,
		})
		tfm.exec.addPhysicObject(g2, x, y - 20, {
			type = 14,
			miceCollision = false,
			groundCollision = false,
			dynamic = true,
			mass = 1,
			foreground = true,
		})
		tfm.exec.addPhysicObject(g3, x, y - 40, {
			type = 14,
			miceCollision = false,
			groundCollision = false,
			dynamic = true,
			mass = 1,
		})

		tfm.exec.addImage("img@194284eba8d", "+" .. g2, 0, 0, nil, 0.5, 0.5, math.random(400) / 100, 1, 0.5, 0.5)

		tfm.exec.addJoint(j1, g2, g1, {type = 1, axis = "0,1"})
		tfm.exec.addJoint(j2, g3, g1, {
			type = 3, forceMotor = 50, speedMotor = 1,
			point1 = x .. "," .. (y - 30),
		})
		tfm.exec.addJoint(j3, g3, g2, {type = 0})

		ui.addTextArea(id, "<a href='event:freeze'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", nil, x - 32, y - 26, 64, 56, 0, 0, 0)
		addNewTimer(self.cooldown, self.despawn, id, img, img2, g1, g2, g3)
	end,

	despawn = function(id, img, img2, g1, g2, g3)
		ui.removeTextArea(id)
		tfm.exec.removeImage(img)
		tfm.exec.removeImage(img2)
		tfm.exec.removePhysicObject(g1)
		tfm.exec.removePhysicObject(g2)
		tfm.exec.removePhysicObject(g3)
	end
}
shop_powers[3] = {
	name = "ghost",
	cooldown_img = "149c068e42f.png",
	cooldown_scale = 0.5,
	cooldown = 2 * 60 * 1000,
	noChairCooldown = true,

	cond = function(player, key, down, x, y)
		return not ghost[player] and not golem[player]
	end,

	fnc = function(self, player, key, down, x, y)
		local scale = facing[player] and 1 or -1
		ghost[player] = tfm.exec.addImage("16ddff86413.png", "%" .. player, 0, 0, nil, scale, 1, 0, 1, scale * 0.5, 0.5)
		tfm.exec.setPlayerGravityScale(player, 0, 0)
		updatePlayerCollision(player)
		bindKeyboard(player, 1, true, true)
		bindKeyboard(player, 3, true, true)
	end
}
shop_powers[4] = {
	name = "campfire",
	cooldown_img = "173dee98c61.png",
	cooldown_scale = 0.4,
	cooldown = 30000,

	fnc = function(self, player, key, down, x, y)
		local id = allocateId("textarea", 1000, 10000)
		local antiGrav = map_gravity <= 0
		local img = tfm.exec.addImage("17426539be5.png", "_101", x, y, nil, 1, antiGrav and -1 or 1, 0, 1, 0.5, antiGrav and -0.5 or 0.5)
		ui.addTextArea(id, "<a href='event:emote:11'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", nil, x - 32, y - 26, 64, 56, 0, 0, 0)
		addNewTimer(self.cooldown, self.despawn, img, id)
	end,

	despawn = function(img, id)
		tfm.exec.removeImage(img)
		ui.removeTextArea(id)
	end
}
shop_powers[5] = {
	name = "booster",
	cooldown_img = "img@1943409e46e",
	cooldown_scale = 0.5,
	cooldown = 5000,

	fnc = function(self, player, key, down, x, y, vx, vy)
		local right = facing[player]
		local id = allocateId("bonus", 1000, 10000)
		local angle = vx and vy and (vx ~= 0 or vy ~= 0) and math.atan2(vy, vx) or (right and 0 or math.pi)
		x = x + (right and 20 or -20)
		local img = tfm.exec.addImage("img@1943409e46e", "!99", x, y, nil, 1, 1, angle, 1, 0.5, 0.5)
		tfm.exec.addBonus(0, x, y, id, 0, false, nil)
		booster[id] = angle
		addNewTimer(self.cooldown, self.despawn, id, img)
	end,

	despawn = function(id, img)
		tfm.exec.removeBonus(id)
		tfm.exec.removeImage(img)
		booster[id] = nil
	end
}
shop_powers[6] = {
	name = "arrow",
	cooldown_img = "16d67f42439.png",
	cooldown_scale = 0.7,
	cooldown = 5000,

	fnc = function(self, player, key, down, x, y)
		despawnableObject(5000, 0, nil, x, y + 5)
	end
}
shop_powers[7] = {
	name = "golem",
	cooldown_img = "img@198c8bc6054",
	cooldown_scale = 0.5,
	cooldown = 2* 60 * 1000,
	despawn_time = 20 * 1000,

	cond = function(player, key, down, x, y)
		local skinID = players_file[player]:getEquipped(7)
		local skin = skinID and (shop_skins[skinID] or file_skins[skinID])
		return skin and not ghost[player] and not golem[player]
	end,

	fnc = function(self, player, key, down, x, y)
		local skinID = players_file[player]:getEquipped(7)
		local skin = skinID and (shop_skins[skinID] or file_skins[skinID])
		if not skin then return end
		local imgID = tfm.exec.addImage(
			skin.img or "img@196c5a94386",
			"$" .. player,
			0, 0, nil,
			skin.scale or 1, skin.scale or 1, 0, 1,
			skin.x or 0.5, skin.y or 0.52,
			true
		)
		golem[player] = true
		updatePlayerCollision(player)
		addNewTimer(self.despawn_time - 1000, self.fadeOutImage, imgID)
		addNewTimer(self.despawn_time, self.despawn, player)
	end,

	fadeOutImage = function(imgID)
		tfm.exec.removeImage(imgID, true)
	end,

	despawn = function(player)
		golem[player] = nil
		updatePlayerCollision(player)
	end
}

-- in small x: positive -> towards the sides, negative -> towards the center
powers = {
	{
		name = "fly", maps = 5,
		id = 1,
		isVisual = true,

		small = "173db50edf6.png", big = "173db512e9c.png", -- icons
		lockedSmall = "173db51091f.png", lockedBig = "173db5151fd.png",
		smallX = 0, smallY = -10,
		bigX = 0, bigY = -10,

		cooldown = nil,
		default = {5, 4}, -- SPACE

		fnc = function(player, key, down, x, y)
			if ghost[player] then
				tfm.exec.movePlayer(player, 0, 0, true, 0, 0, false)
			else
				tfm.exec.movePlayer(player, 0, 0, true, nil, -50 * (map_gravity == 0 and 0 or (map_gravity > 0 and 1 or -1)), false)
			end
		end
	},
	{
		name = "speed", maps = 10,
		id = 2,
		isVisual = true,

		small = "173db21af6a.png", big = "173db214773.png",
		lockedSmall = "173db21d270.png", lockedBig = "173db217990.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e682ff.png",

		cooldown = 1000,
		default = {4, 1}, -- SHIFT

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
		end
	},
	{
		name = "shop_power", maps = 15,
		id = 3,

		small = "173db1165c1.png", big = "173db111ba4.png",
		lockedSmall = "173db118b89.png", lockedBig = "173db114395.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e6674c.png",

		proxyFor = function(player)
			local power_id = players_file[player]:getEquipped(8)
			local power = shop_powers[power_id]
			return power
		end,
		default = {2, 4}, -- E

		fnc = function(player, key, down, x, y, vx, vy)
			local file = players_file[player]
			local id = file:getEquipped(8)
			local power = shop_powers[id]
			if not power then return end
			if not review_mode then
				local updated = file:updateItem(id, 8, -1)
				if updated then
					savePlayerData(player)
				end
			end
			return power:fnc(player, key, down, x, y, vx, vy)
		end
	},
	{
		name = "balloon", maps = 20,
		id = 4,

		small = "173db033fb8.png", big = "173db02a545.png",
		lockedSmall = "173db039519.png", lockedBig = "173db035f01.png",
		smallX = 0, smallY = -10,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e5b2d5.png",

		cooldown = 10000,
		default = {2, 2}, -- Q, A

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(2000, player, 4, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0, 0, 0, false, antiGrav and {
				fixedYSpeed = map_gravity == 0 and 0.1 or 0.8,
			} or nil)
		end,

		upgrades = {
			{
				name = "masterBalloon", maps = 200,
				id = 4,

				small = "173db167a26.png", big = "173db165783.png",
				smallX = 0, smallY = 10,
				bigX = 0, bigY = 10,

				cooldown_img = "17127e5b2d5.png",

				fnc = function(player, key, down, x, y)
					local antiGrav = map_gravity <= 0
					spawnSkinObj(3000, player, 4, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0, 0, 0, false, antiGrav and {
						fixedYSpeed = map_gravity == 0 and 0.1 or 0.8,
					} or nil)
				end
			},
			{
				name = "bubble", maps = 400,
				id = 4,

				small = "173db16a824.png", big = "173db175547.png",
				smallX = 0, smallY = 0,
				bigX = 0, bigY = 0,

				cooldown_img = "17127e5b2d5.png",

				fnc = function(player, key, down, x, y)
					local skinID = players_file[player]:getEquipped(4)
					local antiGrav = map_gravity <= 0
					spawnSkinObj2(4000, skinID == 28 and 59 or nil, skinID, 4, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0, 0, 0, false, antiGrav and {
						fixedYSpeed = map_gravity == 0 and 0.1 or 0.8,
					} or nil)
				end
			},
		}
	},
	{
		name = "teleport", maps = 35,
		id = 5,
		isVisual = true,

		small = "173db226b7a.png", big = "173db21f2b7.png",
		lockedSmall = "173db22ee81.png", lockedBig = "173db223336.png",
		smallX = 10, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e73965.png",

		cooldown = 10000,
		click = {},

		fnc = tfm.exec.movePlayer
	},
	{
		name = "smallbox", maps = 50,
		id = 6,

		small = "173db0ecb64.png", big = "173db0cd7fb.png",
		lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
		smallX = 10, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e77dbe.jpg",

		cooldown = 10000,
		default = {4, 3}, -- Z, W

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(3000, player, 1, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0)
		end
	},
	{
		name = "cloud", maps = 100,
		id = 7,

		small = "173db14a1d6.png", big = "173db145497.png",
		lockedSmall = "173db15baf3.png", lockedBig = "173db15868b.png",
		smallX = 0, smallY = 10,
		bigX = 0, bigY = 20,

		cooldown_img = "17127e5f927.png",

		cooldown = 10000,
		default = {4, 4}, -- X

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(2000, player, 6, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0)
		end
	},
	{
		name = "rip", maps = 700,
		id = 8,

		small = "173db33e169.png", big = "173db33602c.png",
		lockedSmall = "173db3407b0.png", lockedBig = "173db33ac9c.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e69ea4.png",

		cooldown = 10000,
		default = {4, 6}, -- V

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(4000, player, 7, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0)
		end
	},
	{
		name = "choco", maps = 1500,
		id = 9,

		small = "173db2812bc.png", big = "173db27b241.png",
		lockedSmall = "173db2853a0.png", lockedBig = "173db27dba6.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127fc6b27.png",

		cooldown = 25000,
		default = {5, 1}, -- CTRL

		fnc = function(player, key, down, x, y)
			spawnSkinObj(4000, player, 5, x + 20 * (facing[player] and 1 or -1), y - 30, 90)
		end
	},
	{
		name = "bigBox", maps = 2500,
		id = 10,

		small = "173db0ecb64.png", big = "173db0cd7fb.png",
		lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "17127e77dbe.jpg",

		cooldown = 25000,
		default = {4, 7}, -- B

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(4000, player, 2, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0)
		end
	},
	{
		name = "trampoline", maps = 4000,
		id = 11,

		small = "173db3307ed.png", big = "173db3288d3.png",
		lockedSmall = "173db3335b7.png", lockedBig = "173db32e496.png",
		smallX = 0, smallY = 0,
		bigX = 0, bigY = 0,

		cooldown_img = "171cd9f5188.png",

		cooldown = 25000,
		default = {4, 8}, -- N

		fnc = function(player, key, down, x, y)
			local antiGrav = map_gravity <= 0
			spawnSkinObj(4000, player, 3, x, y + 10 * (antiGrav and -1 or 1), antiGrav and 180 or 0)
		end
	},
	{
		name = "pig", maps = 5000,
		id = 12,

		small = "173deea75bd.png", big = "173deea2cc0.png",
		lockedSmall = "173deea9a02.png", lockedBig = "173deea4edc.png",
		smallX = 0, smallY = 20,
		bigX = 0, bigY = 15,

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
			local id1 = allocateId("ground", 1000, 10000)
			local id2 = allocateId("ground", 1000, 10000)
			local sprite = powers.pig.piggies[math.random(#powers.pig.piggies)]
			local yScale = map_gravity <= 0 and -1 or 1
			local img = tfm.exec.addImage(sprite, "_101", x + 5, y + 5, nil, 1, yScale, 0, 1, 0.5, 0.5 * yScale)

			local circles = {
				type = 14,
				friction = 0.3,
			}
			tfm.exec.addPhysicObject(id1, x + 13, y, circles)
			tfm.exec.addPhysicObject(id2, x - 5, y + 2, circles)

			addNewTimer(5000, powers.pig.explode, id1, id2, img, x, y)
			if yScale == 1 then
				addNewTimer(
					5000,
					tfm.exec.removeImage,
					tfm.exec.addImage("17797e8de0d.png", "_102", x - 30, y - 28)
				)
			end
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
		name = "link", maps = 6000,
		id = 13,
		noChairCooldown = true,

		small = "18a1f4da09f.png", big = "18a1f4d198c.png",
		lockedSmall = "18a1f563110.png", lockedBig = "18a1f4e3528.png",
		smallX = 0, smallY = 10,
		bigX = 0, bigY = 20,

		cooldown_img = "18a1f569408.png",

		cooldown = 60000,
		default = {2, 8}, -- U

		cond = function(player, key, down, x, y)
			local soulmate = tfm.get.room.playerList[player].spouseName
			soulmate = soulmate and capitalize(soulmate)

			if not soulmate or not in_room[soulmate] then return false end

			local soulmateInfo = tfm.get.room.playerList[soulmate]
			local distance = math.sqrt(math.pow(x - soulmateInfo.x, 2) + math.pow(y - soulmateInfo.y, 2))

			local soulmate_check = not soulmateInfo.isDead and distance < 200

			return soulmate_check
		end,

		fnc = function(player, key, down, x, y)
			local soulmate = tfm.get.room.playerList[player].spouseName
			tfm.exec.linkMice(player, soulmate, true)
		end
	},
	{
		name = "sink", ranking = 70,
		id = 14,

		small = "173deeb1e05.png", big = "173deeac174.png",
		lockedSmall = "173deeb3dac.png", lockedBig = "173deeaf781.png",
		smallX = 0, smallY = 10,
		bigX = 5, bigY = 10,

		cooldown_img = "1741cfd281e.png",

		cooldown = 30000,
		default = {4, 5}, -- C

		fnc = function(player, key, down, x, y)
			local id = allocateId("ground", 1000, 10000)
			local img = tfm.exec.addImage("17426b19d76.png", "_101", x - 20, y - 10)
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
				id = 14,

				small = "173db3f2c95.png", big = "173db3f0d81.png",
				smallX = 0, smallY = -10,
				bigX = 10, bigY = 0,

				cooldown_img = "171cd9e02d3.png",

				fnc = function(player, key, down, x, y)
					local id = allocateId("ground", 1000, 10000)
					local img = tfm.exec.addImage("171cd3eddf1.png", "_101", x - 20, y - 20)
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
				id = 14,

				small = "173deeb8924.png", big = "173deeb6576.png",
				smallX = 0, smallY = 5,
				bigX = 5, bigY = 10,

				cooldown_img = "1741cfd8396.png",

				fnc = function(player, key, down, x, y)
					local id = allocateId("ground", 1000, 10000)
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
		name = "ladder", ranking = 28,
		id = 15,

		small = "img@19461bc077d", big = "img@19461bc077d",
		lockedSmall = "img@19530ca5bbe", lockedBig = "img@19530ca5bbe",
		smallScale = 0.75,
		smallX = 15, smallY = 10,
		bigX = 20, bigY = 0,

		cooldown_img = "img@19461bc077d",
		cooldown_scale = 0.4,

		cooldown = 30000,
		default = {3, 8}, -- J

		fnc = function(player, key, down, x, y)
			local id = allocateId("textarea", 1000, 10000)
			tfm.exec.addPhysicObject(id, x, y, {
				height = 100,
				width = 30,
				type = 9,
				miceCollision = false,
			})
			local img = tfm.exec.addImage("img@19461bc077d", "+" .. id, 0, 0, nil, 1, 1, 0, 1, 0.5, 0.5)
			addNewTimer(5000, powers.ladder.despawn, img, id)
		end,

		despawn = function(img, id)
			tfm.exec.removeImage(img)
			tfm.exec.removePhysicObject(id)
		end
	},
	{
		name = "chair", ranking = 14,
		id = 16,

		small = "1745a769e88.png", big = "1745a765105.png",
		lockedSmall = "1745a76c506.png", lockedBig = "1745a7675e6.png",
		smallX = 0, smallY = 10,
		bigX = 10, bigY = 10,

		cooldown_img = "17459a21979.png",

		cooldown = 15000,
		default = {3, 6}, -- G

		fnc = function(player, key, down, x, y)
			local id = allocateId("ground", 1000, 10000)
			local yScale = map_gravity <= 0 and -1 or 1
			local img = tfm.exec.addImage("17459a230e9.png", "_101", x - 1, y + 10, nil, 1, yScale, 0, 1, 0.5, 0.5 * yScale)
			tfm.exec.addPhysicObject(id, x - 5, y + 10 + 10 * yScale, {
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

keys = {
	triggers = {}
}

function getPowerUpgrade(completed, pos, power, strict, with_review)
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
		power = getPowerUpgrade(completed, pos, powers[index], true, review_mode or is_anniversary)

		if (power and
			(power.isVisual or (not records_admins and submode ~= "smol"))) then
			if power.click then
				system.bindMouse(player, true)
			end

			if powers[index].key or player_keys[index] then
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
				elseif key then
					triggers[key] = {_count = 1, [1] = power}
					bindKeyboard(player, key, true, true)

					if power.click then
						bindKeyboard(player, key, false, true)
					end
				end
			end
		end
	end

	bindKeyboard(player, 0, true, true)
	bindKeyboard(player, 2, true, true)
	bindKeyboard(player, 113, true, true)

	keys.triggers[player] = triggers
end

function unbind(player)
	if not keys.triggers[player] then return end

	bindKeyboard(player, 0, true, false)
	bindKeyboard(player, 2, true, false)
	bindKeyboard(player, 113, true, false)
	for key in next, keys.triggers[player] do
		bindKeyboard(player, key, true, false)
	end
	system.bindMouse(player, false)

	keys.triggers[player] = nil
end

function checkKill(player)
	local data = players_file[player]
	if not data then return end

	local had_powers = not no_powers[player]
	no_powers[player] = data.killed > os.time() or nil
	if no_powers[player] then
		translatedChatMessage("kill_minutes", player, math.ceil((data.killed - os.time()) / 1000 / 60))
	end

	if victory[player] then
		if had_powers then
			unbind(player)
		end
		if not no_powers[player] then
			bindNecessary(player)
		end
	end
end

local function addTracklist(power, player, x, y)
	if not power.isVisual then
		used_powers._count = used_powers._count + 1
		used_powers[ used_powers._count ] = {player, power.name, x, y}
	end
end

do
local function usePower(player, _power, key, down, x, y, chairCd, onlyVisual, vx, vy)
	local power = _power.proxyFor and _power.proxyFor(player) or _power

	if key == -1 then -- mouse click
		if power.click and not power.click[player] and keys[player][power.id] then
			return
		end
	else
		if power.click then
			power.click[player] = down
			return
		end
	end

	if not down then return end
	if onlyVisual and not power.isVisual then return end
	if chairCd and not power.isVisual and not power.noChairCooldown then return end
	if power.cond and not power.cond(player, key, down, x, y) then return end

	if power.cooldown and not checkCooldown(
		player, power.name, power.cooldown * cooldownMultiplier,
		power.cooldown_img, power.cooldown_scale,
		players_file[player].settings[3] == 1
	) then return end

	if key == -1 then -- mouse click
		_power.fnc(player, x, y)
	else
		_power.fnc(player, key, down, x, y, vx, vy)
	end

	addTracklist(power, player, x, y)

	if doStatsCount() then
		if power_quest[player] and (power_quest[player].w or power_quest[player].d) then
			local save = false
			local file = players_file[player].quests
			if power_quest[player].w and power_quest[player].w == power.id then
				quests[6].updateProgress(player, file[power_quest[player].wi], true)
				save = true
			end
			if power_quest[player].d and power_quest[player].d == power.id then
				quests[6].updateProgress(player, file[power_quest[player].di], false)
				save = true
			end

			if save then
				savePlayerData(player)
			end
		end
	end
end

onEvent("Keyboard", function(player, key, down, x, y, vx, vy)
	if not victory[player] or not players_file[player] or not keys.triggers[player] then return end
	if spec_mode[player] then return end

	if key == 0 or key == 2 then
		facing[player] = key == 2
		if ghost[player] then
			if ghost[player] ~= -1 then
				tfm.exec.removeImage(ghost[player])
			end
			local scale = facing[player] and 1 or -1
			ghost[player] = tfm.exec.addImage("16ddff86413.png", "%" .. player, 0, 0, nil, scale, 1, 0, 1, scale * 0.5, 0.5)
		end
		return
	end

	if key == 1 or key == 3 then
		if ghost[player] then
			tfm.exec.movePlayer(player, 0, 0, true, nil, (key - 2) * 50, false)
		end
		return
	end

	if key == 113 then
		if not checkCooldown(player, "badgeSmiley", 5000) then return end
		local pbg = players_file[player] and players_file[player].badges
		if not pbg then return end

		local available = {}
		for index=1, #badges do
			if badges[index] and pbg[index] and pbg[index] > 0 then
				available[1 + #available] = index
			end
		end

		if #available == 0 then return end

		local index = available[math.random(#available)]
		local badge = badges[index][pbg[index]]

		addNewTimer(
			3000,
			tfm.exec.removeImage,
			tfm.exec.addImage(badge[2], '$'..player, 0, -40, nil, 1, 1, 0, 1, 0.5, 0.5, false)
		)
		return
	end

	if mapIsAboutToChange then return end

	local power = keys.triggers[player][key]
	if power then
		local chairCd = victory[player] > os.time() and
			chair_pos and ((x - chair_pos[1]) ^ 2 + (y - chair_pos[2]) ^ 2) <= 10000
		local onlyVisual = records_admins or disable_powers or submode == "smol"
		for index = 1, power._count do
			if power[index] then
				usePower(player, power[index], key, down, x, y, chairCd, onlyVisual, vx, vy)
			end
		end
	end
end)

onEvent("Mouse", function(player, x, y)
	if not victory[player] or not players_file[player] then return end
	if mapIsAboutToChange then return end

	local power = powers.teleport
	local chairCd = victory[player] > os.time() and
		chair_pos and ((x - chair_pos[1]) ^ 2 + (y - chair_pos[2]) ^ 2) <= 10000
	local onlyVisual = records_admins or disable_powers or submode == "smol"
	if players_file[player].c >= power.maps or review_mode then
		usePower(player, power, -1, true, x, y, chairCd, onlyVisual)
	end
end)
end

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
	powers.teleport.click[player] = nil
	ghost[player] = nil
	golem[player] = nil
	cooldownSlots[player] = nil
end)

onEvent("PlayerDataParsed", function(player, data)
	keys[player] = {}
	for index = 1, #data.keys do
		if data.keys[index] > 0 then
			keys[player][index] = data.keys[index]
		end
	end

	checkKill(player)

	if fixHourCount(data) then
		savePlayerData(player)
	end
end)

onEvent("PlayerDataUpdated", function(player, data)
	checkKill(player)

	if data.quests then
		for i = 1, #data.quests do
			if data.quests[i].id == 6 then
				if not power_quest[player] then
					power_quest[player] = {}
				end

				if i <= 4 then
					power_quest[player].d = data.quests[i].pr
					power_quest[player].di = i
				else
					power_quest[player].w = data.quests[i].pr
					power_quest[player].wi = i
				end
			end
		end
	end

	if fixHourCount(data) then
		savePlayerData(player)
	end
end)

onEvent("PlayerWon", function(player)
	if not room.playerList[player] then return end
	local id = room.playerList[player].id
	if bans[ id ] then return end
	if victory[player] then return end
	local file = players_file[player]
	if not file or not levels then return end

	if doStatsCount() then
		local earned_coins = (is_anniversary and 2 or 1) * current_difficulty

		file.c = file.c + 1
		file.coins = file.coins + earned_coins

		file.tc = math.max(
			checkTitleAndNextFieldValue(player, titles.press_m, 1, file, id),
			checkTitleAndNextFieldValue(player, titles.piglet, 1, file, id)
		)

		file.cc = checkTitleAndNextFieldValue(player, titles.checkpoint, #levels - 1 --[[total checkpoints but spawn]], file, id)

		file.hour[#file.hour + 1] = math.floor((os.time() - file.hour_r) / 10000) -- convert to ms and count every 10s
		file.week[1] = file.week[1] + 1

		local hour_count = #file.hour

		if hour_count >= 30 and hour_count % 5 == 0 then
			if hour_count >= 35 then
				sendPacket("common", packets.rooms.hourly_record,
					room.shortName .. "\000" ..
					room.playerList[player].id .. "\000" ..
					player .. "\000" ..
					hour_count .. "\000" ..
					(room.uniquePlayers or 1) .. "\000" ..
					room.currentMap .. "\000" ..
					(room.xmlMapInfo and room.xmlMapInfo.permCode or -1)
				)
			end

			local badge = math.ceil((hour_count - 29) / 5)
			if badge <= #badges[4] then
				if file.badges[4] == 0 or file.badges[4] < badge then
					file.badges[4] = badge
					NewBadgeInterface:show(player, 4, badge)
				end
			end
		end

		if first_player == nil then
			first_player = player
		end

		if file.quests then
			for questIndex = 1, #file.quests do
				local questID = file.quests[questIndex].id
				local isWeekly = questIndex > 4

				if questID < 6 then
					quests[file.quests[questIndex].id].updateProgress(player, file.quests[questIndex], isWeekly)
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
	first_player = nil

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
		if file and fixHourCount(file) then
			savePlayerData(player)
		end
		unbind(player)
	end

	for player in next, ghost do
		bindKeyboard(player, 1, true, false)
		bindKeyboard(player, 3, true, false)
	end
	ghost, golem = {}, {}
end)

onEvent("NewPlayer", function(player)
	for player2 in next, in_room do
		updatePlayerCollision(player2)

		if ghost[player2] then
			tfm.exec.setPlayerGravityScale(player2, 0, 0)
		end
	end
end)

onEvent("PlayerDied", function(player)
	if ghost[player] then
		ghost[player] = nil
		bindKeyboard(player, 1, true, false)
		bindKeyboard(player, 3, true, false)
	end
	golem[player] = nil
	updatePlayerCollision(player)
end)

onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
	if not ranks.admin[player] and not ranks.mapper[player] and not ranks.manager[player] then
		return
	end

	if cmd == "disablepowers" then
		if not ranks.admin[player] and not review_mode then
			return tfm.exec.chatMessage("<v>[#] <r>Enable review mode first.", player) 
		end
		disable_powers = true
		tfm.exec.chatMessage("<v>[#] <d>Powers disabled by " .. player .. ".")
	elseif cmd == "enablepowers" then
		if not ranks.admin[player] and not review_mode then
			return tfm.exec.chatMessage("<r>[#] Enable review mode first.", player) 
		end
		disable_powers = false
		tfm.exec.chatMessage("<v>[#] <d>Powers enabled by " .. player .. ".")
	elseif cmd == "cooldown" then
		if not ranks.admin[player] or not review_mode then return end
		cooldownMultiplier = tonumber(args[1]) or 1
		tfm.exec.chatMessage("<v>[#] <d>Cooldown multiplier = " .. cooldownMultiplier, player)
		inGameLogCommand(player, cmd, args)
	end
end)

onEvent("PlayerBonusGrabbed", function(player, bonus)
	local angle = booster[bonus]
	if not angle then return end
	tfm.exec.removeBonus(bonus, player)
	if no_help[player] then return end
	local vx, vy = math.cos(angle), math.sin(angle)
	tfm.exec.movePlayer(player, 0, 0, true, vx * 120, vy * 120, true)
end)

end
