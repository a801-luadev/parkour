--[[
	Project: Parkour
	Author: Nettoork#0000
	Created: 19:30 22/01/2019
]]--

local playerDataDefault = {
	modules = {
		drawbattle = {

		},
		parkour = {
			cm = 0
		}
	}
}

-- Bibliotecas de design ✓
local design = {
	ui = require('ui-design');
	button = require('button');
}

-- Biblioteca json ✓
local json = require("json")

-- Biblioteca string-to-boolean ✓
local stb = require("string-to-boolean")

-- Biblioteca parse-xml ✓
local xmlp = require('parse-xml')

-- Biblioteca wait-time ✓
local wait = require('wait-time')

local update_message = '"Money doesn\'t bring happiness — for those who don\'t know what to do with it.", Machado de Assis.\n<B><VP>Freezertag</VP></B> with news! <B><R>/room #parkour0freezertag</R></B>'
for name, data in next, translations do
	if not data.update then
		data.update = update_message
	end
end

-- Língua da sala ✓
local roomLangue = translations[tfm.get.room.community] and tfm.get.room.community or 'en'

-- Função (Traduzir Mensagem) ✓
local translate = function(message)
	return translations[roomLangue][message]
end

-- Variáveis básicas ✓
local maps = {} -- Mapas ✓
local rankingInfo = {} -- Informações de Ranking ✓
local leaderboardPlayers = {} -- Jogadores que precisam ser atualizados no ranking ✓
local leaderboard = {} -- Tabela que será filtrada posteriormente para mostrar a tela de Ranking ✓
local bannedPlayers = {}  -- Jogadores que precisam ser colocados na lista de banidos ✓
local stringData = "" -- Data dos arquivos ✓
local mapsFilter = {} -- Tabela onde os mapas ficarão para serem filtrados ✓
local database = {} -- Dados dos jogadores ✓
local firstTimeLoad = true -- Se está sendo carregado pela primeira vez ✓
local levels = {0} -- Levels do mapa ✓
local mapAuthor = false -- Autor do mapa atual ✓
local objects = {} -- Objetos do mapa ✓
local admins = {"Nettoork#0000", "Bodykudo#0000", "Tocutoeltuco#0000"} -- Admins do minigame ✓
local mods = {} -- Moderadores do minigame ✓
local mapcs = {"Blood#3565", "Lezkip#0000", "Brsowl#0000", "Star#8558"} -- Mapcrews do minigame ✓
local powers = { -- Poderes ✓
	{name = translate('snowball'), maps = 0, image = {url = '16896d045f9.png', x = 50, y = 40}, key = "E", keyCode = 69};
	{name = translate('fly'), maps = 3, image = {url = '16896d06614.png', x = 47, y = 33}, key = translate('space'), keyCode = 32};
	{name = translate('ballon'), maps = 5, image = {url = '16896d0252b.png', x = 35, y = 20}, keyBind = {en = {key = "Q", keyCode = 81}, fr = {key = "F", keyCode = 70}}};
	{name = translate('speed'), maps = 10, image = {url = '16896ed356d.png', x = 35, y = 25}, key = "SHIFT", keyCode = 16};
	{name = translate('teleport'), maps = 25, image = {url = '16896d00614.png', x = 30, y = 20}, use = translate('mouseClick')};
	{name = translate('smallbox'), maps = 50, image = {url = '1689fd4ffc4.jpg', x = 50, y = 40}, keyBind = {en = {key = "Z", keyCode = 90}, fr = {key = "G", keyCode = 71}}};
	{name = translate('cloud'), maps = 100, image = {url = '1689fe8325e.png', x = 15, y = 25}, key = "X", keyCode = 88};
	{name = translate('masterBallon'), maps = 200, image = {url = '168ab7be931.png', x = 15, y = 20}, key = "Q", keyCode = 81};
	{name = translate('bubble'), maps = 400, image = {url = '168ab822a4b.png', x = 30, y = 20}, key = "Q", keyCode = 81};
	{name = translate('rip'), maps = 700, image = {url = '169495313ad.png', x = 38, y = 23}, key = "V", keyCode = 86};
	{name = translate('choco'), maps = 1500, image = {url = '16d2ce46c57.png', x = 20, y = 56}, key = "CTRL", keyCode = 17};
}
local community = { -- Lista de comunidades e suas imagens ✓
	xx = "1651b327097.png",
	ar = "1651b32290a.png",
	bg = "1651b300203.png",
	br = "1651b3019c0.png",
	cn = "1651b3031bf.png",
	cz = "1651b304972.png",
	de = "1651b306152.png",
	ee = "1651b307973.png",
	es = "1651b309222.png",
	fi = "1651b30aa94.png",
	fr = "1651b30c284.png",
	gb = "1651b30da90.png",
	hr = "1651b30f25d.png",
	hu = "1651b310a3b.png",
	id = "1651b3121ec.png",
	il = "1651b3139ed.png",
	it = "1651b3151ac.png",
	jp = "1651b31696a.png",
	lt = "1651b31811c.png",
	lv = "1651b319906.png",
	nl = "1651b31b0dc.png",
	ph = "1651b31c891.png",
	pl = "1651b31e0cf.png",
	ro = "1651b31f950.png",
	ru = "1651b321113.png",
	tr = "1651b3240e8.png",
	vk = "1651b3258b3.png"
}
local powersKey = {} -- Poderes para keyboard e mouse ✓

-- Filtrar poderes para o script ✓
for i, v in next, powers do
	if v.keyBind then
		if tfm.get.room.community == 'fr' then
			powers[i].key = v.keyBind.fr.key
			powers[i].keyCode = v.keyBind.fr.keyCode
		else
			powers[i].key = v.keyBind.en.key
			powers[i].keyCode = v.keyBind.en.keyCode
		end
	end
	powersKey[v.name] = { key = v.keyCode or false, maps = v.maps }
end

-- Filtrar lista de admins ✓
admins = stb.parse(admins)
mods = stb.parse(mods)
mapcs = stb.parse(mapcs)

-- Limitar o número de jogadores na sala ✓
tfm.exec.setRoomMaxPlayers(12)

-- Desativar os comandos da sala ✓
for i, v in next, {"next", "gameTime", "addMap", "removeMap", "testMap", "endMap", "ranking", "leaderboard", "l", "r", "ban", "unban", "help"} do
	system.disableChatCommandDisplay(v)
end

-- Função (Atualizar Ranking) ✓
local updateRanking = function()
	rankingInfo = {}
	if leaderboard and leaderboard[1] then
		for i = 1, 4 do
			rankingInfo[i] = {
				position = '<font size="12"><p align="center"><V>',
				username = '<font size="12"><p align="center"><T>',
				community = {},
				maps = '<font size="12"><p align="center"><VP>'
			}
			for v = 1, 14 do
				v = v + 14 * (i - 1)
				local user = leaderboard[v]
				if user then
					rankingInfo[i].position = rankingInfo[i].position .. '#'..v..'\n'
					rankingInfo[i].username = rankingInfo[i].username..(v == 1 and '<CS>' or v == 2 and '<N>' or v == 3 and '<CE>' or '')..user.nm..(v == 3 and "</CE></N></CS>" or '')..'\n'
					rankingInfo[i].maps = rankingInfo[i].maps .. user.cm .. '\n'
					rankingInfo[i].community[v] = user.co
				end
			end
		end
	end
end

-- Função (Atualizar informação de jogadores banidos) ✓
local updateBanned = function()
	for name, data in next, tfm.get.room.playerList do -- updateBanned
		if not data.isDead and bannedPlayers[name] then
			tfm.exec.killPlayer(name)
		elseif data.isDead and not bannedPlayers[name] then
			tfm.exec.respawnPlayer(name)
		end
	end
end

-- Função (Criar dados de um jogador) ✓
local createDatabase = function(name)
	database[name] = {
		level = 1;
		havePower = false;
		powersPage = 1;
		powersPageImages = {};
		powersPageOpened = false;
		leaderboardOpened = false;
		leaderboardCommunity = {};
		data = false;
		leaderboardPage = 1;
	}
end

-- Função (Split) ✓
local split = function(t, s)
	local a={}
	for i in string.gmatch(t, "[^" .. (s or "%s") .. "]+") do
		a[#a + 1] = i
	end
	return a
end

-- Função (Novo jogo) ✓
local newGame = function()
	if #mapsFilter == 0 then
		for index, map in next, maps do
			mapsFilter[#mapsFilter + 1] = map
		end
	end
	tfm.exec.newGame(table.remove(mapsFilter, math.random(#mapsFilter)))
end

-- Função (Adicionar ao jogador mais um mapa completado) ✓
local addMapFinished = function(name)
	local data = database[name].data
	if data and not name:find("^*") then
		if not data.modules.parkour then
			data.modules.parkour = {
				cm = 0
			}
		end
		data.modules.parkour.cm = data.modules.parkour.cm + 1
		system.savePlayerData(name, json.encode(data))
		system.loadPlayerData(name)
	end
end

-- Função (Dar novo level a um jogador) ✓
local levelUp = function(name)
	database[name].level = database[name].level + 1
	if database[name].level == #levels then
		tfm.exec.giveCheese(name)
		tfm.exec.playerVictory(name)
		database[name].havePower = true
	else
		tfm.exec.chatMessage("<D>"..translate("newLevel").." <VP>"..database[name].level.."</VP>.</D>", name)
	end
	tfm.exec.setPlayerScore(name, database[name].level, false)
end

-- Função (Verificar e alterar a cor do nick dos jogadores) ✓
local setColorName = function(name)
	if database[name] then
		if database[name].havePower then
			tfm.exec.setNameColor(name, 0xFEFF00)
		elseif admins[name] then
			tfm.exec.setNameColor(name, math.random(0x000000, 0xFFFFFF)) -- 0xFA3737
		elseif mapcs[name] then
			tfm.exec.setNameColor(name, 0xF494FF)
		elseif mods[name] then
			tfm.exec.setNameColor(name, 0x5CB8FE)
		elseif name == mapAuthor then
			tfm.exec.setNameColor(name, 0x10FFF3)
		else
			tfm.exec.setNameColor(name, 0x148DE6)
		end
	end
end

-- Função (Verificar e alterar a cor do nick dos jogadores) ✓
local checkPlayerLeaderboard = function(name)
	if leaderboard and database[name] and database[name].data and leaderboard[#leaderboard] and leaderboard[#leaderboard].cm and database[name].data.modules.parkour.cm >= leaderboard[#leaderboard].cm then
		leaderboardPlayers[name] = true
	end
end

-- Função (Organizar a ordem do ranking) ✓
local organizeLeaderboard = function(rank, maxPlayer)
	local toOrganize = {}
	local finalTable = {}
	local dataP = {}
	for i, v in next, rank do
		if not dataP[v.nm] then
			toOrganize[#toOrganize + 1] = {v.nm, v.cm}
			dataP[v.nm] = v
		end
	end
	table.sort(toOrganize, function(a,b) return a[1] > b[1] end)
	table.sort(toOrganize, function(a,b) return a[2] > b[2] end)
	for i, v in next, toOrganize do
		if #finalTable <= maxPlayer and dataP[v[1]] then
			finalTable[#finalTable + 1] = dataP[v[1]]
		end
	end
	return finalTable
end

-- Função (Fechar a loja dos poderes do jogador) ✓
closePowers = function(name)
	database[name].powersPageOpened = false
	design.ui.remove(1, name)
	design.button.remove(1, name)
	design.button.remove(2, name)
	ui.removeTextArea(2, name)
	ui.removeTextArea(3, name)
	for i, v in next, database[name].powersPageImages do
		tfm.exec.removeImage(v, name)
	end
	local page = database[name].powersPage + 2 * (database[name].powersPage - 1)
	for i = 312893, 312895 do
		ui.removeTextArea(i, name)
	end
	database[name].powersPageImages = {}
	database[name].powersPage = 1
end

-- Função (Mostrar os poderes do jogador) ✓
showPowers = function(name, list)
	if not database[name].data then return end
	database[name].powersPageOpened = true
	if database[name].leaderboardOpened then
		closeLeaderboard(name)
	end
	design.ui.create(1, "<p align='center'><font size='40'><B>"..translate('powers').."</B></font></p>", name, 150, 76, 400, 200)
	ui.addTextArea(2, '', name, 160, 140, 480, 195, 0x1D464F, 0x193E46, 1, true)
	page = list + 2 * (list-1)
	for i, v in next, database[name].powersPageImages do
		if v and i < page or i > page + 2 then
			tfm.exec.removeImage(v, name)
		end
	end
	for i = page, page + 2 do
		if powers[i] then
			local canUse = database[name].data.modules.parkour.cm >= powers[i].maps and '<VP>'..(powers[i].key and translate('press')..' '..powers[i].key or powers[i].use and translate('use')..' '..powers[i].use or '') or database[name].data.modules.parkour.cm..'/'..powers[i].maps
			ui.addTextArea(312893 + (page - i + 2), '<p align=\'center\'><B><D>'..(powers[i].name or 'undefined')..'</D></B>\n\n\n\n\n\n\n\n'..canUse, name, 170 + (i-page) * 160, 150, 140, 125, 0x1c3a3e, 0x193E46, 1, true)
			database[name].powersPageImages[i] = tfm.exec.addImage(powers[i].image.url, '&1', powers[i].image.x + 170 + (i-page) * 160, powers[i].image.y + 150, name)
		else
			ui.removeTextArea(312893 + (page - i + 2), name)
		end
	end
	ui.addTextArea(3, '<p align=\'center\'><BV><B>'..translate('finishedRounds')..': '..database[name].data.modules.parkour.cm..'</B></p></BV>', name, 230, 300, 340, 20, 0x1c3a3e, 0x193E46, 1, true)
	if powers[page + 3] then
		design.button.create(2, ">   ", "power_right", name, 590, 300, 40, 20)
	else
		design.button.create(2, ">   ", "power_right", name, 590, 300, 40, 20, true)
	end
	if page > 3 then
		design.button.create(1, "&lt;   ", "power_left", name, 170, 300, 40, 20)
	else
		design.button.create(1, "&lt;   ", "power_left", name, 170, 300, 40, 20, true)
	end
end

-- Função (Mostrar Ranking) ᙭
showLeaderboard = function(name, page)
	database[name].leaderboardOpened = true
	if database[name].powersPageOpened then
		closePowers(name)
	end
	for i, v in next, database[name].leaderboardCommunity do
		tfm.exec.removeImage(v, name)
	end
	database[name].leaderboardCommunity = {}
	if not page or page > 5 or page < 1 then
		page = 1
	end
	design.ui.create(1, "<p align='center'><font size='28'><B><D>"..translate('leaderboard').."</D></B></font>\n<font color='#32585E'>"..string.rep('¯', 50).."</font></p>", name, 168, 46, 365, 260)
	ui.addTextArea(1, '<V><p align="center">Position', name, 180, 100, 50, 20, 1, 1, 0, true)
	ui.addTextArea(2, '<V><p align="center">Username', name, 246, 100, 176, 20, 1, 1, 0, true)
	ui.addTextArea(3, '<V><p align="center">Community', name, 435, 100, 70, 20, 1, 1, 0, true)
	ui.addTextArea(4, '<V><p align="center">Completed maps', name, 518, 100, 105, 20, 1, 1, 0, true)
	ui.addTextArea(5, rankingInfo[page].position, name, 183, 130, 50, 235, 0x203F43, 0x193E46, 1, true)
	ui.addTextArea(6, rankingInfo[page].username, name, 246, 130, 176, 235, 0x203F43, 0x193E46, 1, true)
	ui.addTextArea(7, '', name, 435, 130, 70, 235, 0x203F43, 0x193E46, 1, true)
	ui.addTextArea(8, rankingInfo[page].maps, name, 518, 130, 100, 235, 0x203F43, 0x193E46, 1, true)
	for i = 1, 14 do
		local p = i + 14 * (page - 1)
		local v = rankingInfo[page].community[p] or leaderboard[p] and 'xx'
		if v then
			database[name].leaderboardCommunity[#database[name].leaderboardCommunity + 1] = tfm.exec.addImage(community[v] or community['xx'], '&1', 460, 134 + 14*(i-1), name)
		end
	end
	design.button.create(1, "&lt;                       ", "leaderboard_left", name, 185, 346, 210, 20, not(page > 1))
	design.button.create(2, ">                       ", "leaderboard_right", name, 410, 346, 210, 20, not (rankingInfo[page + 1]))
end

-- Função (Fechar ranking) ᙭
closeLeaderboard = function(name)
	database[name].leaderboardOpened = false
	design.ui.remove(1, name)
	design.button.remove(1, name)
	design.button.remove(2, name)
	for i = 1, 8 do
		ui.removeTextArea(i, name)
	end
	for i, v in next, database[name].leaderboardCommunity do
		tfm.exec.removeImage(v, name)
	end
	database[name].leaderboardCommunity = {}
end

-- Evento (Novo mapa) ✓
onEvent("NewGame", function()

	mapAuthor = tfm.get.room.xmlMapInfo.author
	tfm.exec.setGameTime(1080)
	levels = {0}
	for name in next, database do
		database[name].havePower = false
		database[name].level = 1
		tfm.exec.setPlayerScore(name, database[name].level, false)
		setColorName(name)
	end
	local xml = xmlp.parse(tfm.get.room.xmlMapInfo.xml)
	for i = 1, #xml[1][2][3] do
		local v = xml[1][2][3][i].xarg
		levels[#levels + 1] = {
			x = v.X,
			y = v.Y
		}
	end
	for i = 1, #xml[1][2][2] do
		local v = xml[1][2][2][i].xarg
		if v.T == "19" and v.C == "329cd2" then
			levels[#levels + 1] = {
				x = v.X,
				y = v.Y-25
			}
		end
	end
end)

-- Evento (Jogador entra na toca) ✓
onEvent("PlayerWon", function(name, time)
	tfm.exec.respawnPlayer(name)
	if database[name].havePower then
		tfm.exec.chatMessage("<D>"..translate("youWon").." "..(time/100).." "..translate("seconds").."! "..translate("youWon2").."</D>", name)
		for username in next, tfm.get.room.playerList do
			if username ~= name then
				tfm.exec.chatMessage("<D>"..name.." "..translate("finishParkour").." "..(time/100).." "..translate("seconds")..", "..translate("congrats").."!</D>", username)
			end
		end
		if tfm.get.room.uniquePlayers >= 4 then
			if not tfm.get.room.name:find("^\42\03") then
				addMapFinished(name)
				if database[name].data and not name:find("^*") then
					local cm = database[name].data.modules.parkour.cm
					for i, v in next, powers do
						if v.maps == cm then
							tfm.exec.chatMessage("<CE>"..name.." "..translate("unlockedPower").." <VP>"..v.name.."</VP>.</CE>")
							break
						end
					end
				end
			else
				tfm.exec.chatMessage(translate('noTribeHouse'), name)
			end
		else
			tfm.exec.chatMessage(translate('minPlayers'), name)
		end
		checkPlayerLeaderboard(name)
	end
end)

-- Evento (TextArea selecionada) ✓
onEvent("TextAreaCallback", function(id, name, ref)
	if not wait.check('eventTextAreaCallback', name, 1000) then return end
	if ref == 'powers' then
		if database[name].powersPageOpened then
			closePowers(name)
		else
			showPowers(name, database[name].powersPage)
		end
	elseif ref == 'power_left' then
		if database[name].powersPage <= 1 then return end
		database[name].powersPage = database[name].powersPage - 1
		showPowers(name, database[name].powersPage)
	elseif ref == 'power_right' then
		if database[name].powersPage >= #powers/3 then return end
		database[name].powersPage = database[name].powersPage + 1
		showPowers(name, database[name].powersPage)
	elseif ref == 'leaderboard_left' then
		if database[name].leaderboardPage <= 1 then return end
		database[name].leaderboardPage = database[name].leaderboardPage - 1
		showLeaderboard(name, database[name].leaderboardPage)
	elseif ref == 'leaderboard_right' then
		if database[name].leaderboardPage >= 4 then return end
		database[name].leaderboardPage = database[name].leaderboardPage + 1
		showLeaderboard(name, database[name].leaderboardPage)
	end
end)

-- Evento (Dados de um jogador é carregado) ✓
onEvent("PlayerDataLoaded", function(name, data)
	if data == '' then
		system.savePlayerData(name, json.encode(playerDataDefault))
		system.loadPlayerData(name)
	else
		database[name].data = json.decode(data)
	end
	checkPlayerLeaderboard(name)
end)

-- Evento (Novo Jogador) ✓
onEvent("NewPlayer", function(name)
	tfm.exec.lowerSyncDelay(name)
	tfm.exec.addImage('16894c35340.png', ':1', 762, 32, name)
	system.bindMouse(name, true)
	ui.addTextArea(-321312, '<a href=\'event:powers\'><font size=\'50\'> </font></a>', name, 762, 32, 36, 32, 1, 1, 0, true)
	if not database[name] then
		createDatabase(name)
		tfm.exec.chatMessage("<ROSE>"..translate("welcome")..", "..name.."!</ROSE>", name)
	else
		tfm.exec.chatMessage("<ROSE>"..translate("welcomeAgain")..", "..name.."!</ROSE>", name)
	end
	system.loadPlayerData(name)
	tfm.exec.chatMessage(translate("welcome2")..'\n'..translate("update"), name)
	for i, v in next, {16, 17, 32, 67, 69, 70, 71, 72, 76, 81, 86, 88, 90} do
		system.bindKeyboard(name, v, true)
	end
	tfm.exec.setPlayerScore(name, database[name].level, false)
	updateBanned()
end)

-- Evento (Sempre que um jogador reviver) ✓
onEvent("PlayerRespawn", function(name)
	local db = levels[database[name].level]
	if db and type(db) == "table" then
		tfm.exec.movePlayer(name, db.x, db.y)
	end
	setColorName(name)
end)

-- Evento (Jogador clica com o mouse) ✓
onEvent("Mouse", function(name, x, y)
	if database[name].havePower and database[name].data then
		if database[name].data.modules.parkour.cm >= powersKey[translate('teleport')].maps and wait.check('teleport', name, 10000) then
			tfm.exec.movePlayer(name, x, y)
		end
	end
end)

-- Evento (Sempre que um jogador apertar alguma tecla) ✓
onEvent("Keyboard", function(name, key, down, x, y)
	if key == 72 then
		tfm.exec.chatMessage(translate("help"), name)
	elseif key == 76 then
		if database[name].leaderboardOpened then
			closeLeaderboard(name)
		else
			if wait.check('leaderboard', name, 1000) then
				showLeaderboard(name, database[name].leaderboardPage)
			end
		end
	end
	if database[name].havePower and database[name].data then
		local facingRight = tfm.get.room.playerList[name].isFacingRight
		local parkour = database[name].data.modules.parkour
		if key == powersKey[translate('fly')].key and parkour.cm >= powersKey[translate('fly')].maps then
			tfm.exec.movePlayer(name,0,0,true,0,-50,false)
		elseif key == powersKey[translate('snowball')].key and parkour.cm >= powersKey[translate('snowball')].maps and wait.check('snowball', name, 5000) then
			table.insert(objects, {tfm.exec.addShamanObject(34, facingRight and x + 20 or x - 20, y, 0, facingRight and 10 or -10), os.time() + 5000})
		elseif key == powersKey[translate('ballon')].key and wait.check('ballon', name, 10000) then
			if parkour.cm >= powersKey[translate('bubble')].maps then
				table.insert(objects, {tfm.exec.addShamanObject(59, x, y+12, 0), os.time() + 4000})
			elseif parkour.cm >= powersKey[translate('masterBallon')].maps then
				table.insert(objects, {tfm.exec.addShamanObject(2804, x, y+10, 0), os.time() + 3000})
			elseif parkour.cm >= powersKey[translate('ballon')].maps then
				table.insert(objects, {tfm.exec.addShamanObject(28, x, y+10, 0), os.time() + 2000})
			end
		elseif key == powersKey[translate('speed')].key and parkour.cm >= powersKey[translate('speed')].maps and wait.check('speed', name, 1000) then
			tfm.exec.movePlayer(name, 0, 0, true, facingRight and 60 or -60, 0, true)
		elseif key == powersKey[translate('smallbox')].key and parkour.cm >= powersKey[translate('smallbox')].maps and wait.check('smallbox', name, 10000) then
			table.insert(objects, {tfm.exec.addShamanObject(1, x, y+10, 0), os.time() + 3000})
		elseif key == powersKey[translate('cloud')].key and parkour.cm >= powersKey[translate('cloud')].maps and wait.check('cloud', name, 10000) then
			table.insert(objects, {tfm.exec.addShamanObject(57, x, y+10, 0), os.time() + 2000})
		elseif key == powersKey[translate('rip')].key and parkour.cm >= powersKey[translate('rip')].maps and wait.check('rip', name, 10000) then
			table.insert(objects, {tfm.exec.addShamanObject(90, x, y+10, 0), os.time() + 4000})
		elseif key == powersKey[translate('choco')].key and parkour.cm >= powersKey[translate('choco')].maps and wait.check('choco', name, 25000) then
			table.insert(objects, {tfm.exec.addShamanObject(46, x + (facingRight and 20 or -20), y-30, 90), os.time() + 4000})
		end
	end
end)

-- Evento (Jogador utilize algum comando) ✓
onEvent("ChatCommand", function(name, command)
	local arg = split(command, " ")
	if arg[1] == 'ranking' or arg[1] == 'leaderboard' or arg[1] == 'r' or arg[2] == 'l' then
		if database[name].leaderboardOpened then
			closeLeaderboard(name)
		else
			if wait.check('leaderboard', name, 1000) then
				showLeaderboard(name, database[name].leaderboardPage)
			end
		end
	elseif arg[1] == 'help' then
		tfm.exec.chatMessage(translate("help"), name)
	end
	if admins[name] then
		if arg[1] == "next" then
			newGame(arg[2])
		elseif arg[1] == "gameTime" then
			tfm.exec.setGameTime(tonumber(arg[2]))
		elseif arg[1] == "addMap" and arg[2] then
			local js = json.decode(stringData)
			local oneMap = false

			if js and js.maps then
				for i = 2, #arg do
					local map = tonumber(tostring(arg[i]:gsub('@', '')))
					local found_map = false

					for o, a in next, js.maps do
						if a == '@'..map then
							tfm.exec.chatMessage(a.." already exists!", name)
							found_map = true
							break;
						end
					end

					if not found_map then
						js.maps[#js.maps + 1] = map
						maps[#maps + 1] = map
						oneMap = true
					end

				end

				if oneMap then
					local js2 = json.encode(js)
					local success = js2 and system.saveFile(js2, 2)

					if success then
						stringData = js2
						tfm.exec.chatMessage("Maps were added", name)
					else
						tfm.exec.chatMessage("ERROR, maps not added", name)
					end
				else
					tfm.exec.chatMessage("No maps!", name);
				end
			else
				tfm.exec.chatMessage("JSON error", name);
			end
		elseif arg[1] == "removeMap" and arg[2] then
			local map = tonumber(tostring(arg[2]:gsub("@", "")))
			if map then
				local js = json.decode(stringData)
				if js and js.maps then
					for i, v in next, js.maps do
						if v == arg[2] then
							table.remove(js.maps, i)
							local js2 = json.encode(js)
							local success = js2 and system.saveFile(js2, 2)
							if success then
								stringData = js2
								tfm.exec.chatMessage("Map @"..map.." removed", name)
							else
								tfm.exec.chatMessage("ERROR, map not removed", name)
							end
							return
						end
					end
				else
					tfm.exec.chatMessage("JSON error", name)
				end
				tfm.exec.chatMessage("Map not found", name)
			end
		elseif arg[1] == 'testMap' and arg[2] then
			local map = tonumber(tostring(arg[2]:gsub("@", "")))
			if map then
				tfm.exec.newGame(arg[2])
			end
		elseif arg[1] == 'endMap' then
			for i, v in next, levels do
				levelUp(arg[2] or name)
			end
		end
	end
	if admins[name] or mods[name] then
		if arg[1] == 'ban' and arg[2] then
			if bannedPlayers[arg[2]] then
				tfm.exec.chatMessage('The player '..arg[2]..' was already banned.', name)
			else
				bannedPlayers[arg[2]] = true
				tfm.exec.chatMessage('The player '..arg[2]..' has been banned.', name)
				updateBanned()
				if tfm.get.room.playerList[arg[2]] then
					tfm.exec.chatMessage("<R>The player "..arg[2].." has been banned from room.</R>")
				end
			end
		elseif arg[1] == 'unban' and arg[2] then
			if bannedPlayers[arg[2]] then
				bannedPlayers[arg[2]] = false
				tfm.exec.chatMessage('The player '..arg[2]..' has been unbanned.', name)
				updateBanned()
			else
				tfm.exec.chatMessage("The player "..arg[2].." hasn't banned.", name)
			end
		end
	end
end)

-- Evento (Loop do jogo) ✓
onEvent("Loop", function(currentTime, timeRemaining)
	if timeRemaining <= 0 then
		newGame()
		return
	end
	for name, info in next, tfm.get.room.playerList do
		if database[name] then
			local level = levels[database[name].level + 1]
			if level then
				if info.x <= level.x+15 and info.x >= level.x-15 and info.y <= level.y+15 and info.y >= level.y-15 then
					levelUp(name)
				end
				tfm.exec.displayParticle(math.random(21, 23), math.random((level.x-10),(level.x+10)),math.random((level.y-10),(level.y+10)),0,0,0,0,name)
			end
		end
		if admins[name] then
			setColorName(name)
		end
	end
	for i, v in next, objects do
		if v[2] < os.time() then
			tfm.exec.removeObject(v[1])
			table.remove(objects, i)
			break
		end
	end
	if wait.check('ranking', 'loop', math.random(70000, 90000)) then
		if firstTimeLoad then
			firstTimeLoad = false
		else
			system.loadFile(2)
		end
	end
end)

-- Evento (Quando um jogador morrer) ✓
onEvent("PlayerDied", function(name)
	updateBanned()
end)

-- Desativar automatizações do Transformice ✓
for index, value in next, {'AutoShaman', 'AutoNewGame', 'AutoTimeLeft', 'PhysicalConsumables', 'AfkDeath', 'DebugCommand', 'AutoScore', 'MinimalistMode'} do
	tfm.exec['disable' .. value]()
end

-- Evento (Quando um arquivo é carregado) ✓
onEvent("FileLoaded", function(id, result)
	if id == "2" then
		stringData = result -- String que será usada por todos
		local js = json.decode(result) -- Arquivo JSON filtrado e passado para Tabela
		local haveMap = maps[1] -- Se os mapas já foram carregados
		if not haveMap then -- Carregar os mapas
			if js and js.maps then
				for i, v in next, js.maps do
					maps[#maps + 1] = v
				end
			else
				maps = {"@7171137"}
			end
			-- Iniciar jogo ✓
			newGame()
		end
		if js then
			if not js.ranking then js.ranking = {} end
			for i = 1, #js.ranking do
				for o, a in next, leaderboardPlayers do
					if js.ranking[i].nm == o then
						js.ranking[i].cm = database[o] and database[o].data and database[o].data.modules.parkour.cm or js.ranking[i].cm
						if tfm.get.room.playerList[o] then
							js.ranking[i].co = tfm.get.room.playerList[o].community or tfm.get.room.community
						end
						leaderboardPlayers[o] = nil
						break
					end
				end
			end
			for i, v in next, leaderboardPlayers do
				if tfm.get.room.playerList[i] then
					js.ranking[#js.ranking + 1] = {nm = i, cm = database[i].data.modules.parkour.cm, co = tfm.get.room.playerList[i].community}
				end
			end
			leaderboardPlayers = {}
			leaderboard = organizeLeaderboard(js.ranking, 70) or {}
			js.ranking = leaderboard
			if not haveMap then
				table.foreach(tfm.get.room.playerList, checkPlayerLeaderboard)
			end
			system.saveFile(json.encode(js), 2)
			updateRanking()
			updateBanned()
		end
	end
end)

system.loadFile(2)