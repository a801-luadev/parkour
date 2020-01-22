require("hide-warning")

local stable = require("string-to-boolean").parse
local wait = require("wait-time").check
local sleep = require("sleep")

local admins = {"Nettoork#0000", "Tocutoeltuco#0000"}
admins = stable(admins)

local config = {
	freezer_radius = 50;
	unfreezer_radius = 70;
	start_hp = 3;
	hp_chance = 30;
	players_per_freezers = 10;
	freezer_delay = 2000;
	unfreezer_delay = 15000;
	game_time = 170;
	max_players = 25;
	object_start_id = 100000;
	select_freezers_time = 10000;
	end_game_time = 30000;
	min_moving_players = 5;
}


local maps = {4675995, 4391574, 6166453, 2241886, 4412155, 4440887, 4737903, 4716310, 3704277, 4447699, 4650301, 5208188, 4137198, 4404369, 4388705, 4565774, 4738138, 5377664, 4789606, 4412126, 4830225, 4547683, 4360147, 3683632, 7243771, 7159670, 7647688, 7134009, 3322416, 2434771, 6923268, 6865350, 6808085, 6202454, 6109514, 3367828, 2064173, 5020313, 4081307, 4787601, 4743573, 7647551, 4529713, 7647472, 7647541, 7647493, 7647497, 7647498, 7647514, 7647519, 7647524, 7647591, 7647557, 7647594, 7647598, 7647601, 7647604, 7647611, 7647776, 7647826, 7659231, 7659238, 7659239, 7659241, 7659320, 7659325, 7659444, 7659327, 7659328, 7659329, 7659330, 7659334, 7659336, 7659447, 7659340, 7659341, 7659345, 7659429, 7659433, 7659441}

local cache = {}
local db = {}
local game = {}
local banned_players = {}

tfm.exec.setRoomMaxPlayers(config.max_players)

local function reset_game()
	game = {
		players = {};
		freezers = {};
		freezed = {};
		unfreezer_alive = 0;
		freezer_alive = 0;
		ending = false;
		started = false;
		potencial_players = {};
		give_cheese = false;
		set_freezers = false;
	}
end

local split = function(t, s)
	local a={}
	for i in string.gmatch(t, "[^" .. (s or "%s") .. "]+") do
		a[#a + 1] = i
	end
	return a
end

local function translate(message)
	return translations[config.room_language] and translations[config.room_language][message] or translations[config.room_language][message]
end

local function freeze(freezer_name)
	for name, data in next, tfm.get.room.playerList do
		local freezer = tfm.get.room.playerList[freezer_name]

		if math.abs(data.x - freezer.x) <= config.freezer_radius and math.abs(data.y - freezer.y) <= config.freezer_radius then
			if not game.freezers[name] and not data.isDead then
				if wait("player_freeze", freezer_name, config.freezer_delay, false) then
					tfm.exec.killPlayer(name)
					game.freezed[name] = tfm.exec.addShamanObject(54, data.x, data.y, 0, 0, 0, false)

					translatedChatMessage("freezed", name)

					if game.players[name].hp > 0 then
						updateLife(name, -1)
					end

					if game.players[name].hp < 1 then
						translatedChatMessage("noLife", name)
						translatedChatMessage("nowPopsicle", nil, name)
					else
						translatedChatMessage("freezedLife", name, game.players[name].hp)
					end
					tfm.exec.setNameColor(freezer_name, 0x009DFF)
				end
				break
			end
		end
	end
end

local function unfreeze(unfreezer_name)
	local noLife

	for name, id in next, game.freezed do
		local object = tfm.get.room.objectList[id]
		local unfreezer = tfm.get.room.playerList[unfreezer_name]

		if math.abs(object.x - unfreezer.x) <= config.unfreezer_radius and math.abs(object.y - unfreezer.y) <= config.unfreezer_radius then
			if game.players[name].hp > 0 then
				if wait("player_freeze", unfreezer_name, config.unfreezer_delay, false) then
					game.players[name].x = object.x
					game.players[name].y = object.y

					tfm.exec.removeObject(id)
					ui.removeTextArea(config.object_start_id + id)

					tfm.exec.respawnPlayer(name)
					translatedChatMessage("unfreezed", name, unfreezer_name)
					db[name].chance = db[name].chance + 1

					local lucky = math.random(100)
					if lucky <= 15 then
						translatedChatMessage("gotHp", unfreezer_name, name)
						updateLife(unfreezer_name, 1)
					else
						translatedChatMessage("unfreezedsomeone", unfreezer_name, name)
					end

					game.freezed[name] = nil
				end
			else
				noLife = true
			end
			break
		end
	end

	if noLife then
		translatedChatMessage("playerWithoutLife", unfreezer_name)
	end
end

function change_map()
	if #cache == 0 then
		for index, map in next, maps do
			cache[#cache + 1] = map
		end
	end
	tfm.exec.newGame(table.remove(cache, math.random(#cache)), math.random(1, 5) == 1 and true or false)
end

function updateLife(name, to_inc)
	if to_inc then
		game.players[name].hp = game.players[name].hp + to_inc
	end

	local hp = game.players[name].hp
	tfm.exec.setPlayerScore(name, hp, false)

	for i, v in next, game.players[name].lifes do
		tfm.exec.removeImage(v)
	end

	if hp > 0 then
		for i = 1, hp do
			game.players[name].lifes[#game.players[name].lifes + 1] = tfm.exec.addImage('1674802a592.png', ':1', 5 + (28 * (i - 1)), 23, name)
		end
	end
end

onEvent("NewGame", function()
	tfm.exec.setGameTime(config.game_time)

	if game and game.freezed then
		for i, id in next, game.freezed do
			ui.removeTextArea(config.object_start_id + id)
		end
	end

	reset_game()
	ui.removeTextArea(1)

	for name, data in next, tfm.get.room.playerList do
		game.players[name] = {
			hp = 3;
			lifes = {};
		}

		tfm.exec.setPlayerScore(name, game.players[name].hp, false)
		tfm.exec.setNameColor(name, 0xB5B5B5)
		game.unfreezer_alive = game.unfreezer_alive + 1

		if banned_players[name] then
			tfm.exec.killPlayer(name)
			updateLife(name, game.players[name] * -1)
		else
			updateLife(name)
		end
	end
end)

function updateChance(name, chance)
	local c = ("%.2d"):format(chance)
	c = tonumber(c:find("0") == 1 and c:sub(2) or c)

	if c < 0 then
		c = 0
	end

	ui.addTextArea(1, translatedMessage("chance", name, tostring(c)).."%", name, 10, 380, 0, 0, 1, 1, 0, true)
end

onEvent("Loop", function(s, r)
	if not game.set_freezers and s >= config.select_freezers_time and s <= config.select_freezers_time+2000 then
		game.set_freezers = true
		local total_chance, total_data = 0, 0

		local pont = 0

		for name, data in next, game.potencial_players do
			pont = pont + 1
		end

		local isdead = {}

		for name, data in next, tfm.get.room.playerList do
			if pont >= config.min_moving_players and  not game.potencial_players[name] and not data.isDead then
				tfm.exec.killPlayer(name)
				isdead[name] = true
			else
				total_data = total_data + 1
				total_chance = total_chance + db[name].chance
			end
		end

		local players = {}

		for name, data in next, tfm.get.room.playerList do
			if not data.isDead and not isdead[name] then
				players[#players + 1] = name
			end
		end

		local p = math.floor(#players/config.players_per_freezers) + 1
		for i = 1, p do
			local rand = math.random() * total_chance

			local found = false

			while not found do
				for id, name in next, players do
					if rand < db[name].chance then
						total_chance = total_chance - db[name].chance
						game.freezers[#game.freezers + 1] = table.remove(players, id)
						game.unfreezer_alive = game.unfreezer_alive - 1
						game.freezer_alive = game.freezer_alive + 1
						db[name].chance = 1
						ui.removeTextArea(1, name)
						found = true
						break
					else
						rand = rand - db[name].chance
					end
				end
			end
		end

		if #game.freezers <= 0 then
			return change_map()
		end

		game.freezers = stable(game.freezers)

		for name, data in next, tfm.get.room.playerList do
			if not data.isDead then
				if game.freezers[name] then
					translatedChatMessage("are_freezer", name)
					tfm.exec.setNameColor(name, 0x009DFF)
					updateLife(name, game.players[name].hp * -1)
				else
					db[name].chance = db[name].chance + 1
					total_chance = total_chance + 1
					translatedChatMessage("are_unfreezer", name, config.start_hp)
				end
			end
		end

		for name, data in next, db do
			if not game.freezers[name] then
				updateChance(name, data.chance*100/total_chance)
			end
		end

		game.started = true
	elseif not game.give_cheese and r >= config.end_game_time and r <= config.end_game_time+2000 and game.unfreezer_alive > 0 then
		game.give_cheese = true
		end_game(false)
	elseif game.freezer_alive and (r <= 0 or (game.freezer_alive <= 0 and game.unfreezer_alive <= 0)) then
		change_map()
	end

	if game.ending then
		for name in next, admins do
			local p = tfm.get.room.playerList[name]
			if p and not p.isDead and not game.freezers[name] then
				tfm.exec.setNameColor(name, math.random(0x000000, 0xFFFFFF))
			end
		end
	elseif not game.started then
		for name, data in next, tfm.get.room.playerList do
			if not data.isDead and (data.movingLeft or data.movingRight or data.isJumping) then
				game.potencial_players[name] = data
			end
		end
	end

	if game.freezed then
		for name, id in next, game.freezed do
			local object = tfm.get.room.objectList[id]

			if object and game.players[name].hp > 0 then
				ui.addTextArea(config.object_start_id + id, "<B><font color='#000000'>" .. name .. "</font></B>\n<p align='center'><B><R>"..game.players[name].hp.." hp</R></B>", nil, object.x - (string.len(name) * 4), object.y - 10, 0, 0, 1, 1, 0, false)
			else
				game.freezed[name] = nil
				ui.removeTextArea(config.object_start_id + id)
				break
			end
		end
	end
end)

function end_game(freezers_won)
	if not game.ending then
		game.ending = true

		if freezers_won then
			for name, data in next, tfm.get.room.playerList do
				if not data.isDead and game.freezers[name] then
					tfm.exec.giveCheese(name)
				end
			end
		else
			for name, data in next, tfm.get.room.playerList do
				if not data.isDead and not game.freezers[name] then
					tfm.exec.giveCheese(name)
				end
			end
		end

		for name in next, game.players do
			updateLife(name, game.players[name].hp * -1)
		end

		local ids = {}

		for i, v in next, tfm.get.room.objectList do
			ids[#ids + 1] = v.id
		end
		for i, v in next, ids do
			tfm.exec.removeObject(v)
		end

		for i, id in next, game.freezed do
			ui.removeTextArea(config.object_start_id + id)
		end

		game.freezed = {}
		tfm.exec.setGameTime(30)
	end
end

function check_players(name, died)
	if not game.freezers[name] then
		game.unfreezer_alive = game.unfreezer_alive + (died and -1 or 1)

		if game.unfreezer_alive <= 0 then
			return end_game(true)
		end
	else
		game.freezer_alive = game.freezer_alive + (died and -1 or 1)
		game.freezers[name] = nil

		for _ in next, game.freezers do
			return
		end

		return end_game()
	end

	if game.freezer_alive <= 0 and game.unfreezer_alive <= 0 then
		return change_map()
	end
end

onEvent("Keyboard", function(name, key, down, x, y)
	if key == 32 then
		if not tfm.get.room.playerList[name].isDead and not game.ending then
			if wait("wait_keyboard", name, 1000, false) then
				if game and game.freezers and game.freezers[name] then
					freeze(name)
				else
					unfreeze(name)
				end
			end
		end
	end
end)

onEvent("PlayerDied", function(name)
	check_players(name, true)
end)

onEvent("PlayerLeft", function(name)
	if game.players[name] then
		game.players[name].hp = 0
	end
end)

onEvent("PlayerWon", function(name)
	check_players(name, true)
	db[name].chance = db[name].chance + 5
end)

onEvent("PlayerRespawn", function(name)
	check_players(name)

	if game.players[name].x then
		tfm.exec.movePlayer(name, game.players[name].x, game.players[name].y)
	end
end)

onEvent("NewPlayer", function(name)
	tfm.exec.bindKeyboard(name, 32, true, true)
	tfm.exec.lowerSyncDelay(name)

	db[name] = {
		chance = 1;
	}

	translatedChatMessage("welcome", name)
end)

onEvent("ChatCommand", function(name, command)
	local arg = split(command, " ")

	if admins[name] then
		if arg[1] == 'ban' and arg[2] then
			if banned_players[arg[2]] then
				tfm.exec.chatMessage('ERROR', name)
			else
				translatedChatMessage("player_banned", nil, arg[2])
				banned_players[arg[2]] = true
				tfm.exec.killPlayer(arg[2])
			end
		elseif arg[1] == 'unban' and arg[2] then
			if banned_players[arg[2]] then
				translatedChatMessage("player_unbanned", nil, arg[2])
				banned_players[arg[2]] = nil
			else
				tfm.exec.chatMessage('ERROR', name)
			end
		end
	end

end)

for index, value in next, {'AutoShaman', 'AutoNewGame', 'AutoTimeLeft', 'AutoScore', 'PhysicalConsumables', 'DebugCommand', 'MinimalistMode'} do
	tfm.exec['disable' .. value]()
end

change_map()