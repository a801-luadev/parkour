do
  local function is_halloween_time()
    if force_halloween_debug then return true end
    local month = tonumber(os.date("%m"))
    local day = tonumber(os.date("%d"))
    return month == 10 and day >= 20 or month == 11 and day <= 20
  end

  if is_halloween_time() then

    cp_img = {
      [true] = "img@19a0879fecd", -- soulmate
      [false] = "img@19a087a2182", -- no soulmate
    }

    local WAIT, COLLECT, DEPOSIT, DISTRIBUTING = 0, 1, 2, 3

    local halloween = {
      potionEcIndex = 13,
      state = WAIT,
      materialTypes = 6,
      minPlayers = 4,
      materials = {
        { name = "halloween_bone", ec = 7, rarity = 1, weight = 30, image = "199f896d411.png" },
        { name = "halloween_spider_silk", ec = 8, rarity = 1, weight = 25, image = "199f89752fb.png" },
        { name = "halloween_bat_wing", ec = 9, rarity = 2, weight = 20, image = "199f896b77a.png" },
        { name = "halloween_ghost_dust", ec = 10, rarity = 2, weight = 15, image = "199f89719a6.png" },
        { name = "halloween_pumpkin_seed", ec = 11, rarity = 3, weight = 7, image = "199f8973539.png" },
        { name = "halloween_crystal_shard", ec = 12, rarity = 3, weight = 3, image = "199f896f0ea.png" },
      },
      collect = { items = {}, bonus = {}, bonus_rev = {}, images = {}, collected={} },
      cauldron = {
        active = false,
        endTime = 0,
        duration = 300000,
        labels = {
          potTA = allocateId("textarea", 40000),
          timerTA = allocateId("textarea", 40000),
        },
      },
    }
    activeEvents.halloween = halloween
    local halloween_cauldron = HalloweenInterface(halloween)

    local function compareContribution(a, b)
      return a.value > b.value
    end

    function halloween.reset()
      halloween.rounds = math.random(2, 4)
      halloween.timestamp = os.time() + math.random(15, 30) * 60 * 1000
      halloween.state = WAIT
      halloween.cauldron.active = false
    end

    function halloween.resetForceFlags()
      halloween.forceNext = false
      halloween.forceCollect = false
      halloween.forceCauldron = false
    end

    function halloween.isCauldronAllowed()
      local roomName = room.lowerName
      local isCauldron = string.find(roomName, "cauldron", 1, true)
      local isRecords = string.find(roomName, "records", 1, true)
      local isVillage = string.find(roomName, "village", 1, true)
      return isCauldron and not isRecords and not isVillage
    end

    if halloween.isCauldronAllowed() then
      newMap = function()
        tfm.exec.newGame('<C><P PKAUTHOR="Halloween Ritual"/><Z><S><S T="12" X="400" Y="200" L="800" H="400" P="0,0,0.3,0.2,0,0,0,0" o="324650" c="4" i="0,0,199af526a9c.png"/><S T="12" X="408" Y="399" L="800" H="20" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="12" X="359" Y="243" L="10" H="28" P="0,0,0.3,0.2,-20,0,0,0" o="324650" m=""/><S T="12" X="362" Y="322" L="10" H="28" P="0,0,0.5,0.2,20,0,0,0" o="324650" m=""/><S T="12" X="410" Y="328" L="10" H="28" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="12" X="448" Y="323" L="10" H="32" P="0,0,0.5,0.2,-40,0,0,0" o="324650" m=""/><S T="12" X="460" Y="239" L="10" H="28" P="0,0,0.3,0.2,30,0,0,0" o="324650" m=""/><S T="13" X="380" Y="279" L="40" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="434" Y="278" L="40" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="406" Y="290" L="40" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="12" X="407" Y="241" L="100" H="12" P="0,0,0.3,0,0,0,0,0" o="324650" m=""/><S T="12" X="400" Y="-5" L="1500" H="10" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="155" Y="301" L="31" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="631" Y="299" L="29" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="675" Y="346" L="24" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="12" X="223" Y="349" L="19" H="38" P="0,0,0.3,0.2,-10,0,0,0" o="324650" m=""/><S T="12" X="564" Y="323" L="19" H="38" P="0,0,0.3,0.2,10,0,0,0" o="324650" m=""/><S T="12" X="60" Y="238" L="20" H="101" P="0,0,0.3,0.2,-10,0,0,0" o="324650" m=""/></S><D><P X="428" Y="-316" T="19" C="329cd2" P="0,0"/><DS X="408" Y="225"/></D><O/><L/></Z></C>')
        ui.setMapName("Halloween Ritual")
      end
    end

    newCmd({ name = "halloween",
      rank = "admin",
      fn = function(player, args, cmd)
        local subcmd = args[1]

        if subcmd == "collect" then
          halloween.forceCollect = true
          halloween.forceNext = true
          tfm.exec.chatMessage("<J>Halloween collection phase will be forced on next map", player)

        elseif subcmd == "reset" then
          halloween.reset()
          halloween.resetForceFlags()
          tfm.exec.chatMessage("<J>Halloween event reseted.", player)

        elseif subcmd == "timer" then
        local duration = tonumber(args[2])
        if not duration or duration < 1 then
            tfm.exec.chatMessage("<R>Usage: !halloween timer <seconds>", player)
          return
        end

        if halloween.cauldron.active then
          halloween.cauldron.endTime = os.time() + (duration * 1000)
          tfm.exec.setGameTime(duration)
            tfm.exec.chatMessage("<J>Cauldron timer set to " .. duration .. " seconds.", player)
          else
            tfm.exec.chatMessage("<R>No active cauldron session!", player)
          end

        elseif subcmd == "give" then
          local targetPlayer = args[2]
          local amount = tonumber(args[3])

          if not targetPlayer or not amount then
            tfm.exec.chatMessage("<R>Usage: !halloween give <player> <amount>", player)
            return
          end

          if not in_room[targetPlayer] then
            tfm.exec.chatMessage("<R>Player not found in room!", player)
            return
          end

          local file = players_file[targetPlayer]
          if not file then
            tfm.exec.chatMessage("<R>Player data not loaded!", player)
            return
          end

          file:updateItem(halloween.potionEcIndex, 0, amount)
          savePlayerData(targetPlayer)

          tfm.exec.chatMessage("<J>Gave " .. amount .. " potions to " .. targetPlayer, player)

        elseif subcmd == "setmat" then
          local targetPlayer = args[2]

          if not targetPlayer then
            tfm.exec.chatMessage("<R>Usage: !halloween setmat <player>", player)
            return
          end

          if not in_room[targetPlayer] then
            tfm.exec.chatMessage("<R>Player not found in room!", player)
            return
          end

          local file = players_file[targetPlayer]
          if not file then
            tfm.exec.chatMessage("<R>Player data not loaded!", player)
            return
          end

          local count = tonumber(args[3]) or 99
          local index = tonumber(args[4])

          local material
          for i = 1, halloween.materialTypes do
            if not index or index == i then
              material = halloween.materials[i]
              file:updateItem(material.ec, 0, count)
            end
          end

          savePlayerData(targetPlayer)
          tfm.exec.chatMessage("<J>Set materials to " .. count .. " for " .. targetPlayer, player)

        elseif subcmd == "status" then
          local stateNames = {"WAIT", "COLLECT", "DEPOSIT", "DISTRIBUTING"}
          local stateName = stateNames[halloween.state + 1] or "UNKNOWN"
          local roomName = room.lowerName or room.name or "unknown"
          local isCauldronRoom = string.find(roomName, "cauldron", 1, true) ~= nil

          tfm.exec.chatMessage("<J>State: " .. stateName .. " | Room: " .. roomName .. " (Cauldron: " .. tostring(isCauldronRoom) .. ") | Rounds: " .. tostring(halloween.rounds) .. " | Active: " .. tostring(halloween.cauldron.active) .. " | Time: " .. tostring(halloween.timestamp) .. "/" .. tostring(os.time()), player)
        else
          tfm.exec.chatMessage("<J>!halloween [collect, reset, timer, give, setmat, status]", player)
      end
    end })

    local function selectMaterial(difficulty)
      local totalWeight = 0
      for i=1, halloween.materialTypes do
        local mat = halloween.materials[i]
        local weight = mat.weight
        if mat.rarity == 2 then
          weight = weight * (1 + (difficulty - 1) * 0.8)
        elseif mat.rarity == 3 then
          weight = weight * (1 + (difficulty - 1) * 1.5)
        end
        totalWeight = totalWeight + weight
      end

      local random = math.random() * totalWeight
      local current = 0
      for i=1, halloween.materialTypes do
        local mat = halloween.materials[i]
        local weight = mat.weight
        if mat.rarity == 2 then
          weight = weight * (1 + (difficulty - 1) * 0.8)
        elseif mat.rarity == 3 then
          weight = weight * (1 + (difficulty - 1) * 1.5)
        end
        current = current + weight
        if random <= current then
          return i
        end
      end
      return 1
    end

    function halloween.createCollectibles()
      local difficulty = current_difficulty or 1
      local num = 3
      local item

      for i=1, num do
        item = { x = math.random(50, 1580), y = math.random(50, 700), type = selectMaterial(difficulty) }
        halloween.collect.items[i] = item
        if not halloween.collect.bonus_rev[i] then
          halloween.collect.bonus_rev[i] = allocateId("bonus", 20000)
          halloween.collect.bonus[halloween.collect.bonus_rev[i]] = i
        end
      end
      halloween.collect.items._len = num

      local msgIndex = math.min(5, math.random(1, 5))
      translatedChatMessage("halloween_msg_" .. msgIndex)
      translatedChatMessage("halloween_collect_hint")
    end

    function halloween.resetRound()
      for i=1, 3 do
        halloween.collect.images[i] = {}
        halloween.collect.items[i] = {}
        halloween.collect.collected[i] = {}
      end
      halloween.state = WAIT
    end

    function halloween.initRound()
      halloween.rounds = halloween.rounds - 1

      if halloween.rounds > 0 or halloween.timestamp > os.time() then
        halloween.resetRound()
        return
      end

      halloween.reset()
      halloween.state = COLLECT
      halloween.createCollectibles()
      halloween.render()
    end

    function halloween.render(target)
      if not target then
        for name in next, in_room do
          halloween.render(name)
        end
        return
      end

      if halloween.state == COLLECT and halloween.collect.items._len then
        local item, material
        local images = halloween.collect.images
        for i=1, halloween.collect.items._len do
          item = halloween.collect.items[i]
          material = halloween.materials[item.type]
          if not halloween.collect.collected[i][target] then
            images[i][target] = tfm.exec.addImage(material.image, "!999", item.x, item.y, target, 1, 1, 0, 1, 0.5, 0.5, true)
            tfm.exec.addBonus(0, item.x, item.y, halloween.collect.bonus_rev[i], 0, false, target)
          else
            tfm.exec.addImage(material.image, "!999", item.x, item.y, target, 1, 1, 0, 0.3, 0.5, 0.5, true)
          end
        end
      end
    end

    local function startCauldronSession()
      if actual_player_count < halloween.minPlayers then
        translatedChatMessage("halloween_cauldron_need_players")
        return
      end

      halloween.state = DEPOSIT
      halloween.cauldron.active = true
      halloween.cauldron.endTime = os.time() + halloween.cauldron.duration
      halloween_cauldron.clearAllDeposits()
      halloween_cauldron.updateCauldronDisplay()
      tfm.exec.setGameTime(600)

      for name in next, in_room do
        halloween_cauldron.hide(name)
        halloween_cauldron.show(name)
      end

      translatedChatMessage("halloween_cauldron_ritual_begin")
    end

    local function finalizeCauldronSession()
      if halloween.state == DISTRIBUTING then
        return
      end

      halloween.cauldron.active = false
      halloween.state = DISTRIBUTING

      local allDeposits = halloween_cauldron.getAllDeposits()
      local hasDeposits = false

      for i=1, halloween.materialTypes do
        for _, amount in next, allDeposits[i] do
          if amount > 0 then
            hasDeposits = true
            break
          end
        end
        if hasDeposits then break end
      end

      if not hasDeposits then
        translatedChatMessage("halloween_cauldron_no_offerings")
        ui.removeTextArea(halloween.cauldron.labels.potTA)
        --ui.removeTextArea(halloween.cauldron.labels.timerTA)
        return
      end

      local maxPossibleValue = 0
      for i=1, halloween.materialTypes do
        maxPossibleValue = maxPossibleValue + (100 * halloween.materials[i].rarity)
      end

      local playerValues, remove = {}, {}
      local totalValue = 0
      local file, material

      for i=1, halloween.materialTypes do
        material = halloween.materials[i]
        for player, amount in next, allDeposits[i] do
          file = players_file[player]
          if file and in_room[player] and file:getItemAmount(material.ec, 0) >= amount then
            playerValues[player] = (playerValues[player] or 0) + (amount * material.rarity)
          else
            remove[player] = true
            allDeposits[i][player] = 0
          end
        end
      end

      for player, playerValue in next, playerValues do
        if not remove[player] then
          totalValue = totalValue + playerValue
        end
      end

      for player in next, remove do
        playerValues[player] = nil
      end

      if totalValue <= 0 then
        translatedChatMessage("halloween_cauldron_fizzles")
        return
      end

      local potionRatio = 100 / maxPossibleValue
      local totalPotion = math.floor(totalValue * potionRatio)
      local topContributors = {}
      local participants, contributionRatio, potionReward = 0
      local actualTotalPotions = 0

      for player, playerValue in next, playerValues do
        participants = participants + 1
        file = players_file[player]
        contributionRatio = playerValue / totalValue
        potionReward = math.ceil(totalPotion * contributionRatio)

        for i=1, halloween.materialTypes do
          amount = allDeposits[i][player]
          if amount and amount > 0 and halloween.materials[i] then
            file:updateItem(halloween.materials[i].ec, 0, -amount)
          end
        end

        if potionReward > 0 then
          file:updateItem(halloween.potionEcIndex, 0, potionReward)
          actualTotalPotions = actualTotalPotions + potionReward
        end

        savePlayerData(player)
        translatedChatMessage("halloween_cauldron_reward", player, potionReward, math.floor(contributionRatio * 100))

        table.insert(topContributors, {
          name = player,
          value = playerValue,
          ratio = math.floor(contributionRatio * 100),
          reward = potionReward
        })
      end

      table.sort(topContributors, compareContribution)
      translatedChatMessage("halloween_cauldron_complete", nil, participants, actualTotalPotions)

      for i = 1, math.min(3, #topContributors) do
        local contributor = topContributors[i]
        translatedChatMessage("halloween_cauldron_top_contributor", nil, i, contributor.name, contributor.ratio, contributor.reward)
      end

      halloween_cauldron.clearAllDeposits()

      for name in next, in_room do
        halloween_cauldron.hide(name)
      end

      ui.removeTextArea(halloween.cauldron.labels.potTA)
      translatedChatMessage("halloween_cauldron_ritual_end")
      translatedChatMessage("halloween_cauldron_hint")
      halloween.cauldron.endTime = os.time() + 30000
      tfm.exec.setGameTime(30)
    end

    local function updateCauldronTimer()
      local currentTime = os.time()
      local remaining = halloween.cauldron.endTime - currentTime

      if halloween.state == DEPOSIT and halloween.cauldron.active then
        if remaining <= 0 then
          finalizeCauldronSession()
          return
        end
        local remainingSeconds = math.floor(remaining / 1000)
        local mm = math.floor(remainingSeconds / 60)
        local ss = remainingSeconds % 60
        local label = string.format("<p align='center'><font size='13'><B><N>%02d:%02d", mm, ss)

        if remainingSeconds <= 10 then
          halloween_cauldron.disableDeposits()
          finalizeCauldronSession()
          return
        end

        ui.updateTextArea(halloween.cauldron.labels.timerTA, label)

      elseif halloween.state == DISTRIBUTING then
        if remaining <= 0 then
          startCauldronSession()
        else
          local remainingSeconds = math.floor(remaining / 1000)
          local mm = math.floor(remainingSeconds / 60)
          local ss = remainingSeconds % 60
          local label = string.format("<p align='center'><font size='13'><B><R>%02d:%02d", mm, ss)

          ui.updateTextArea(halloween.cauldron.labels.timerTA, label)
        end
      elseif remaining <= 0 and halloween.cauldron.endTime > 0 then
        startCauldronSession()
      end
    end

    halloween.reset()
    halloween.resetForceFlags()

    onEvent("NewGame", function()
      if halloween.isCauldronAllowed() then
        startCauldronSession()
        return
      end

      local shouldRun = doStatsCount() or halloween.forceNext or halloween.forceCollect or halloween.forceCauldron

      if shouldRun then
        if halloween.forceCauldron then
          halloween.state = DEPOSIT
          startCauldronSession()
          halloween.forceCauldron = false
        elseif halloween.forceCollect then
          halloween.state = COLLECT
          halloween.createCollectibles()
          halloween.render()
          halloween.forceCollect = false
        else
          halloween.initRound()
        end
        halloween.resetForceFlags()
      else
        halloween.resetRound()
      end
    end)

    onEvent("PlayerBonusGrabbed", function(player, bonus)
      if halloween.state ~= COLLECT then return end
      local cindex = halloween.collect.bonus[bonus]
      if not cindex then return end
      local item = halloween.collect.items[cindex]
      if not item then return end
      if halloween.collect.collected[cindex][player] then return end

      local pdata = players_file[player]
      if not pdata then return end

      local material = halloween.materials[item.type]
      local currentAmount = pdata:getItemAmount(material.ec, 0)

      if currentAmount >= 100 then
        translatedChatMessage("halloween_material_limit", player)
        return
      end

      halloween.collect.collected[cindex][player] = true
      pdata:updateItem(material.ec, 0, 1)
      savePlayerData(player)

      local mat = halloween.materials[item.type]
      local materialName = translatedMessage(mat.name, player)
      translatedChatMessage("halloween_found_material", player, materialName)

      local images = halloween.collect.images[cindex]
      if images[player] then
        tfm.exec.removeImage(images[player], true)
        tfm.exec.addImage(mat.image, "!999", item.x, item.y, player, 1, 1, 0, 0.3, 0.5, 0.5, true)
        images[player] = nil
      end
    end)

    onEvent("PlayerDataParsed", function(player, init)
      if halloween.isCauldronAllowed() then
        if halloween.cauldron.active then
          if halloween.state == DEPOSIT then
            halloween_cauldron.show(player)
          end
        elseif actual_player_count >= halloween.minPlayers then
          startCauldronSession()
        end
        return
      end
      if halloween.state == WAIT then return end  
      halloween.render(player)
      if halloween.isCauldronAllowed() and halloween.cauldron.active then
        halloween_cauldron.show(player)
        halloween_cauldron.updateCauldronDisplay()
      end
    end)

    onEvent("NewPlayer", function(player)
      if halloween.state == COLLECT then
        local msgIndex = math.min(5, math.random(1, 5))
        translatedChatMessage("halloween_msg_" .. msgIndex, player)
      end
    end)

    onEvent("PlayerLeft", function(player)
      if halloween.collect.images[player] then
        halloween.collect.images[player] = nil
      end

      if halloween.state == DEPOSIT and halloween.cauldron.active then
        if actual_player_count < halloween.minPlayers then
          halloween.cauldron.active = false
          halloween.state = WAIT
          for name in next, in_room do
            halloween_cauldron.hide(name)
          end
          translatedChatMessage("halloween_cauldron_cancelled")
          return
        end

        halloween_cauldron.clearPlayerDeposits(player)
        halloween_cauldron.updateCauldronDisplay()
      end
    end)

    onEvent("TextAreaCallback", function(id, player, event)
      if event == "cauldron_clear_all" then
        halloween_cauldron.clearAll(player)
        return
      elseif event == "cauldron_add_all" then
        halloween_cauldron.addAll(player)
        return
      end
    end)

    onEvent("Loop", function()
      if halloween.state == DEPOSIT or halloween.state == DISTRIBUTING then
        updateCauldronTimer()
      end
    end)
  end
end