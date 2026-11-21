-- force_valentine_debug: runs the event outside of its dates, only for tests
-- !valentine craft / exit: opens the fountain room in a tribe house, only for tests
do
  local function is_valentine_time()
    if force_valentine_debug then return true end
    local month = tonumber(os.date("%m"))
    local day = tonumber(os.date("%d"))
    return month == 1 and day >= 31 or month == 2 or month == 3 and day <= 1
  end

  local function isCraftRoom()
    local roomName = room.lowerName
    local isValentine = string.find(roomName, "valentine", 1, true)
    local isVillage = string.find(roomName, "village", 1, true)
    return isValentine and not isVillage
  end

  if is_valentine_time() then
    local WAIT, ROUND, CRAFT = 0, 1, 2
    local KISS_EMOTE = 3

    local valentine = {
      ev = tonumber(os.date("%Y")) % 100 * 10000 + 301,
      state = WAIT,
      rewardCount = 3,
      ringEcIndex = shop_currencies.ring.id,
      ringLimit = shop_currencies.ring.limit,
      ringCost = 12,
      materialLimit = shop_currencies.rose.limit,
      materials = {
        { name = "valentine_rose", ec = shop_currencies.rose.id, rarity = 1, weight = 30, image = "img@19bd39f4739" },
        { name = "valentine_ribbon", ec = shop_currencies.ribbon.id, rarity = 1, weight = 25, image = "img@19bd39f3249" },
        { name = "valentine_chocolate", ec = shop_currencies.chocolate.id, rarity = 2, weight = 35, image = "img@19bd39f5ba6" },
        { name = "valentine_envelope", ec = shop_currencies.envelope.id, rarity = 3, weight = 10, image = "img@19bd39efef5" },
      },
      claimed = {},
      msgIndex = 1,
      forceNext = false,
      session = {
        mode = nil,
        endTime = 0,
        duration = 300000,
        minPlayers = 2,
        ready = {},
        readyCount = 0,
        depositCount = 0,
      },
      npc = { x = 680, y = 249 },
      bgImage = "img@19bc98e97af",
      map = '<C><P MEDATA=";;;;-0;0:::1-"/><Z><S><S T="12" X="115" Y="285" L="230" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="685" Y="285" L="230" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="400" Y="315" L="270" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="400" Y="305" L="35" H="35" P="0,0,0.3,0.2,45,0,0,0"/><S T="12" X="-5" Y="200" L="10" H="800" P="0,0,0,0.2,0,0,0,0"/><S T="12" X="805" Y="200" L="10" H="800" P="0,0,0,0.2,0,0,0,0"/><S T="12" X="275" Y="280" L="11" H="39" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="525" Y="280" L="11" H="39" P="0,0,0.3,0.2,0,0,0,0"/></S><D><P X="380" Y="527" T="19" C="329cd2" P="0,0"/><DS X="100" Y="249"/></D><O/><L/></Z></C>',
    }
    activeEvents.valentine = valentine
    local valentine_fountain = ValentineInterface(valentine)

    valentine.normalNewMap = newMap
    valentine.craftNewMap = function()
      tfm.exec.newGame(valentine.map)
      ui.setMapName("♥ " .. translatedMessage("valentine_event_name", nil) .. " ♥")
    end

    if isCraftRoom() then
      valentine.state = CRAFT
      newMap = valentine.craftNewMap
    end

    function valentine.resetRound()
      valentine.claimed = {}
      if valentine.state ~= CRAFT then
        valentine.state = WAIT
      end
    end

    function valentine.reset()
      valentine.rounds = math.random(2, 4)
      valentine.timestamp = os.time() + math.random(15, 30) * 60 * 1000
      valentine.resetRound()
    end

    function valentine.debug(player, cmd, quantity, args)
      valentine.rounds = 0
      valentine.timestamp = 0
      tfm.exec.chatMessage("<J>Valentine round will start next map", player)
    end

    newCmd({ name = "valentine",
      rank = "admin",
      fn = function(player, args, cmd)
        local subcmd = args[1]

        if subcmd == "collect" then
          valentine.forceNext = true
          tfm.exec.chatMessage("<J>Valentine kiss round will be forced on next map", player)

        elseif subcmd == "reset" then
          valentine.reset()
          valentine.forceNext = false
          tfm.exec.chatMessage("<J>Valentine event reseted.", player)

        elseif subcmd == "timer" then
          local duration = tonumber(args[2])
          if not duration or duration < 1 then
            tfm.exec.chatMessage("<R>Usage: !valentine timer <seconds>", player)
            return
          end

          if valentine.session.mode == "deposit" then
            valentine.session.endTime = os.time() + (duration * 1000)
            tfm.exec.setGameTime(duration)
            tfm.exec.chatMessage("<J>Fountain timer set to " .. duration .. " seconds.", player)
          else
            tfm.exec.chatMessage("<R>No active fountain session!", player)
          end

        elseif subcmd == "give" then
          local target = args[2]
          local amount = tonumber(args[3])

          if not target or not amount then
            tfm.exec.chatMessage("<R>Usage: !valentine give <player> <amount>", player)
            return
          end

          if not in_room[target] then
            tfm.exec.chatMessage("<R>Player not found in room!", player)
            return
          end

          local file = players_file[target]
          if not file then
            tfm.exec.chatMessage("<R>Player data not loaded!", player)
            return
          end

          file:updateItem(valentine.ringEcIndex, 0, amount)
          savePlayerData(target)
          tfm.exec.chatMessage("<J>Gave " .. amount .. " rings to " .. target, player)

        elseif subcmd == "setmat" then
          local target = args[2]

          if not target then
            tfm.exec.chatMessage("<R>Usage: !valentine setmat <player>", player)
            return
          end

          if not in_room[target] then
            tfm.exec.chatMessage("<R>Player not found in room!", player)
            return
          end

          local file = players_file[target]
          if not file then
            tfm.exec.chatMessage("<R>Player data not loaded!", player)
            return
          end

          local count = tonumber(args[3]) or 99
          local index = tonumber(args[4])

          local material
          for i = 1, #valentine.materials do
            if not index or index == i then
              material = valentine.materials[i]
              file:updateItem(material.ec, 0, count)
            end
          end

          savePlayerData(target)
          valentine_fountain.refresh(target)
          tfm.exec.chatMessage("<J>Set materials to " .. count .. " for " .. target, player)

        elseif subcmd == "craft" then
          valentine.state = CRAFT
          newMap = valentine.craftNewMap
          valentine.craftNewMap()
          tfm.exec.chatMessage("<J>Valentine craft room enabled. Use !valentine exit to go back.", player)

        elseif subcmd == "exit" then
          if isCraftRoom() then
            tfm.exec.chatMessage("<R>This is a real craft room, there is nowhere to go back to.", player)
            return
          end

          valentine.state = WAIT
          valentine.session.mode = nil
          valentine_fountain.clearAllDeposits()
          valentine.resetRound()
          for name in next, in_room do
            valentine_fountain.hide(name)
          end
          tfm.exec.chatMessage("<J>Valentine craft room disabled.", player)

          if not valentine.normalNewMap then
            tfm.exec.chatMessage("<R>Normal map loader was not found.", player)
            return
          end

          newMap = valentine.normalNewMap
          local done, err = pcall(newMap)
          if not done then
            tfm.exec.chatMessage("<R>" .. tostring(err), player)
          end

        elseif subcmd == "status" then
          tfm.exec.chatMessage(
            "<J>State: " .. valentine.state ..
            " | Fountain: " .. tostring(valentine.session.mode) ..
            " | Craft room: " .. tostring(isCraftRoom() and true or false) ..
            " | Rounds: " .. tostring(valentine.rounds) ..
            " | Time: " .. tostring(valentine.timestamp) .. "/" .. tostring(os.time()),
            player
          )
        else
          tfm.exec.chatMessage("<J>!valentine [collect, reset, timer, give, setmat, craft, exit, status]", player)
        end
      end })

    local function selectMaterial(difficulty)
      local list = valentine.materials
      local weights, totalWeight = {}, 0
      local weight, mat

      for i=1, #list do
        mat = list[i]
        weight = mat.weight
        if mat.rarity == 2 then
          weight = weight * (1 + (difficulty - 1) * 0.8)
        elseif mat.rarity == 3 then
          weight = weight * (1 + (difficulty - 1) * 1.5)
        end
        weights[i] = weight
        totalWeight = totalWeight + weight
      end

      local random = math.random() * totalWeight
      local current = 0
      for i=1, #list do
        current = current + weights[i]
        if random <= current then
          return i
        end
      end
      return 1
    end

    function valentine.startRound()
      valentine.state = ROUND
      valentine.claimed = {}
      valentine.msgIndex = math.random(1, 3)
      translatedChatMessage("valentine_msg_" .. valentine.msgIndex)
    end

    function valentine.initRound()
      valentine.rounds = valentine.rounds - 1

      if valentine.rounds > 0 or valentine.timestamp > os.time() then
        valentine.resetRound()
        return
      end

      valentine.reset()
      valentine.startRound()
    end

    function valentine.spawnNpc(target)
      tfm.exec.addNPC("Cupid", {
        title = 432,
        look = "298;0,58_ffffff+ff7979+ff7979+ff7979+ffffff+ffffff+ffffff+ffffff+ffffff,50_ffffff+ffc1c1+ffffff+ffffff,0,53_ffffff+ffffff+ffffff+ffffff+ffffff+ffffff+ffffff+ffffff,111_ffffff+fdfdfd+ffffff+ffffff+ffffff+ffffff+ffd3d3+ffd3d3,0,84,37,0,0,0",
        x = valentine.npc.x,
        y = valentine.npc.y,
        female = false,
        lookLeft = true,
      }, target)
    end

    function valentine.claim(player)
      local file = players_file[player]
      if not file then return end

      valentine.claimed[player] = true

      local difficulty = math.max(1, current_difficulty or 1)
      local gained, gainedCount = {}, 0
      local index, material

      for _ = 1, valentine.rewardCount do
        index = selectMaterial(difficulty)
        material = valentine.materials[index]

        if file:getItemAmount(material.ec, 0) < valentine.materialLimit then
          file:updateItem(material.ec, 0, 1)
          gained[index] = (gained[index] or 0) + 1
          gainedCount = gainedCount + 1
        end
      end

      if gainedCount == 0 then
        translatedChatMessage("valentine_material_limit", player)
        return
      end

      savePlayerData(player)

      local names, count = {}, 0
      for i=1, #valentine.materials do
        if gained[i] then
          count = count + 1
          names[count] = translatedMessage(valentine.materials[i].name, player) .. " x" .. gained[i]
        end
      end

      translatedChatMessage("valentine_found", player, table.concat(names, ", "))
      translatedChatMessage("valentine_collect_hint", player)

      local info = room.playerList[player]
      if info then
        for i = -2, 2 do
          tfm.exec.displayParticle(5, info.x + i * 14, info.y - 12 - (2 - math.abs(i)) * 6, 0, -1.2, 0, 0)
        end
      end
    end

    function valentine.startSession()
      local session = valentine.session
      session.mode = "deposit"
      session.endTime = os.time() + session.duration

      valentine_fountain.clearAllDeposits()
      tfm.exec.setGameTime(600)

      for name in next, in_room do
        valentine_fountain.hide(name)
        valentine_fountain.show(name)
      end

      translatedChatMessage("valentine_fountain_begin")
    end

    function valentine.endSession()
      local session = valentine.session
      session.endTime = os.time() + 30000
      tfm.exec.setGameTime(30)

      valentine_fountain.clearAllDeposits()

      for name in next, in_room do
        valentine_fountain.hide(name)
      end

      translatedChatMessage("valentine_fountain_end")
      translatedChatMessage("valentine_village_hint")
    end

    function valentine.finalize()
      local session = valentine.session
      if session.mode ~= "deposit" then return end
      session.mode = "result"

      local deposits = valentine_fountain.getDeposits()
      local list, count = {}, 0
      local totalPoints = 0
      local file, ok, points, amount

      for name, amounts in next, deposits do
        file = players_file[name]
        ok = file and in_room[name]
        points = 0

        if ok then
          for i=1, #valentine.materials do
            amount = amounts[i] or 0
            if amount > 0 and file:getItemAmount(valentine.materials[i].ec, 0) < amount then
              ok = false
              break
            end
            points = points + amount * valentine.materials[i].rarity
          end
        end

        if ok and points > 0 then
          count = count + 1
          list[count] = { name = name, points = points }
          totalPoints = totalPoints + points
        end
      end

      if count == 0 then
        translatedChatMessage("valentine_fountain_no_offerings")
        return
      end

      local totalRings = math.floor(totalPoints / valentine.ringCost)
      if totalRings < 1 then
        translatedChatMessage("valentine_fountain_fizzles")
        return
      end

      local given = 0
      local entry, share, reward
      for i=1, count do
        entry = list[i]
        file = players_file[entry.name]
        share = entry.points / totalPoints

        reward = math.max(0, math.min(
          math.ceil(totalRings * share),
          valentine.ringLimit - file:getItemAmount(valentine.ringEcIndex, 0)
        ))

        for m=1, #valentine.materials do
          amount = deposits[entry.name][m] or 0
          if amount > 0 then
            file:updateItem(valentine.materials[m].ec, 0, -amount)
          end
        end

        if reward > 0 then
          file:updateItem(valentine.ringEcIndex, 0, reward)
          given = given + reward
        end

        savePlayerData(entry.name)

        entry.share = math.floor(share * 100)
        entry.reward = reward
        translatedChatMessage("valentine_fountain_reward", entry.name, reward, entry.share)
      end

      table.sort(list, function(a, b) return a.points > b.points end)
      translatedChatMessage("valentine_fountain_complete", nil, count, given)

      for i=1, math.min(3, count) do
        entry = list[i]
        translatedChatMessage("valentine_top_contributor", nil, i, entry.name, entry.share, entry.reward)
      end

      valentine.endSession()
    end

    function valentine.toggleReady(player)
      local session = valentine.session
      if session.mode ~= "deposit" or not valentine_fountain.hasDeposit(player) then return end

      if session.ready[player] then
        session.ready[player] = nil
        session.readyCount = session.readyCount - 1
      else
        session.ready[player] = true
        session.readyCount = session.readyCount + 1
      end

      valentine_fountain.updateReady(player)

      if session.depositCount > 0 and session.readyCount == session.depositCount then
        if math.floor((session.endTime - os.time()) / 1000) > 15 then
          session.endTime = os.time() + 15000
          tfm.exec.setGameTime(15)
        end
      end
    end

    function valentine.startCraft()
      map_name = nil
      ui.setMapName("♥ " .. translatedMessage("valentine_event_name", nil) .. " ♥")

      tfm.exec.addImage(valentine.bgImage, "?1", 0, 0)
      valentine.spawnNpc()
      valentine.startSession()
    end

    valentine.reset()

    onEvent("NewGame", function()
      if valentine.state == CRAFT then
        valentine.startCraft()
        return
      end

      local forced = valentine.forceNext
      valentine.forceNext = false

      if forced then
        valentine.startRound()
      elseif stats_enabled then
        valentine.initRound()
      else
        valentine.resetRound()
      end
    end)

    onEvent("NewPlayer", function(player, init)
      if valentine.state == CRAFT then
        if init then return end
        tfm.exec.addImage(valentine.bgImage, "?1", 0, 0, player)
        valentine.spawnNpc(player)
        translatedChatMessage("valentine_welcome_craft", player)
      elseif valentine.state == ROUND then
        translatedChatMessage("valentine_msg_" .. valentine.msgIndex, player)
      end
    end)

    onEvent("PlayerDataParsed", function(player)
      if valentine.state == CRAFT and valentine.session.mode == "deposit" then
        valentine_fountain.show(player)
      end
    end)

    onEvent("PlayerLeft", function(player)
      valentine_fountain.clearPlayer(player)
    end)

    onEvent("PlayerCompleted", function(player)
      if valentine.state ~= ROUND or review_mode then return end
      if valentine.claimed[player] then return end
      translatedChatMessage("valentine_kiss_hint", player)
    end)

    onEvent("EmotePlayed", function(player, emote)
      if emote ~= KISS_EMOTE or valentine.state ~= ROUND then return end
      if review_mode or spec_mode[player] or valentine.claimed[player] then return end

      if not victory[player] then
        if checkCooldown(player, "valentine_kiss", 5000) then
          translatedChatMessage("valentine_finish_first", player)
        end
        return
      end

      valentine.claim(player)
    end)

    onEvent("TextAreaCallback", function(id, player, event)
      if valentine.state ~= CRAFT or event:sub(1, 10) ~= "valentine_" then return end

      if event == "valentine_add_all" then
        valentine_fountain.addAll(player)
      elseif event == "valentine_remove_all" then
        valentine_fountain.clearAll(player)
      elseif event == "valentine_ready" then
        if not checkCooldown(player, "valentine_ready", 500) then return end
        valentine.toggleReady(player)
      end
    end)

    onEvent("Loop", function()
      if valentine.state ~= CRAFT then return end

      local session = valentine.session
      if session.mode == "deposit" then
        if session.endTime - os.time() > 10000 then return end

        if actual_player_count < session.minPlayers then
          translatedChatMessage("valentine_need_players")
          session.endTime = os.time() + session.duration
          tfm.exec.setGameTime(30)
          return
        end

        valentine_fountain.seal()
        valentine.finalize()
      elseif session.mode == "result" then
        if session.endTime - os.time() <= 0 then
          valentine.startSession()
        end
      end
    end)
  end
end
