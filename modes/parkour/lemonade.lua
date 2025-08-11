do
  local day = tonumber(os.date("%d"))
  local month = tonumber(os.date("%m"))
  local is_lemonade_time = (month == 7 and day >= 23) or month == 8 or force_lemonade_debug

  if is_lemonade_time then
    local WAIT, COLLECT, TRADE = 0, 1, 2
    local lemonade = {
      bonus = {},
      bonus_rev = {},
      collectibles = {
        -- ec index, image
        { 3, "ice", "img@197ed411401" },
        { 4, "sugar", "img@197ed41077c" },
        { 5, "water", "img@197ed410214" },
        { 6, "lemon", "img@197ed3a7e0a" },
      },
      jug = {
        -- ids = {},
        -- progress = {},
        x = 575, y = 430,
        "img@198241a0cb3", -- empty
        "img@198241a1567", -- lemon
        "img@198241a22cd", -- water
        "img@198241a2d2a", -- sugar
        "img@198241a380c", -- mix
        "img@198241a4666", -- ice
      },
      countTA = {
        -- x, y, id, width
        [2] = { 650, 395, nil, 40 },
        [3] = { 817, 390 },
        [4] = { 471, 395 },
        [5] = { 791, 380 },
        [6] = { 505, 395 },
      },
      buttonTA = {
        -- progress, ec index, x, y, w, h, ta id
        lemon = { 1, 6, 505, 425, 25, 20 },
        water = { 2, 5, 793, 402, 25, 41 },
        sugar = { 3, 4, 475, 425, 20, 20 },
        mix = { 4, nil, 612, 418, 28, 27 },
        ice = { 5, 3, 824, 410, 24, 34 },
        glass = { 6, nil, 704, 417, 23, 28 },
      },
      npcs = {
        Askosu = {
          x = 1085,
          y = 500,
          title = 537,
          look = "290;0,46,151,0,0,116_edc5c4+edc5c4+edc5c4,75_17110b+17110b+ffffff+f7ccdd+f1c6c9+e6b3b7,12,109_ffc862+ffd588+ffc862+f1d49f+6b3c2f+fefefe+e8796c,0,0,0",
          message = "lemonade_balloon",
          right_image = "img@197ed06bf10",
          itemID = 213,
          price = 10,
        },
        Tascion = {
          x = 1287,
          y = 94,
          title = 104,
          look = "172;0,0,113_a3d7fc+b3e2ff+c7e5f7+c7e5f7+dcf1ff+dcf1ff+dcf1ff,0,0,130_afe0ff+bfe5ff+fafafa+bfe6ff+ebf6ff+bfe6ff+bfe6ff,69_c7e5f7+8fd0ff+e9f6ff+a2d7fc+c7e5f7+a2d7fc,2,78,0,0,0",
          message = "lemonade_cloud",
          right_image = "img@197ed06d073",
          itemID = 214,
          price = 20,
        },
        Lays = {
          x = 430,
          y = 525,
          title = 212,
          look = "8;12_f8a500+f8a500+f8a500+f8a500+f8a500+f8a500,0,18,24,0,0,0,5,9_e07323+3d1f07,0,0,0",
          message = "lemonade_rip",
          right_image = "img@197ecff508b",
          itemID = 215,
          price = 30,
        },
        Jaw = {
          x = 120,
          y = 530,
          title = 509,
          look = "159;127_f9683f+fff0e2,52_f9683f+ffff00+e0cae0+7343cb+dddddd+eaddea+7343cb+ffff00+895bac,0,0,0,0,0,0,45_f9683f+ffffff+f9683f+efefef+f9683f+eeeeee+f9683f,0,0,0",
          message = "lemonade_badge",
          right_image = "img@197eae1cec8",
          badgeGroup = 7,
          badge = 1,
          price = 40,
        },
      },
    }
    activeEvents.lemonade = lemonade

    -- counter ta ids
    for i=2, 6 do
      lemonade.countTA[i][3] = allocateId("textarea", 40000)
    end

    -- button ta ids
    for _, ta in next, lemonade.buttonTA do
      ta[7] = allocateId("textarea", 40000)
    end

    -- bonus id for item pickups
    for i=1, 3 do
      lemonade.bonus_rev[i] = allocateId("bonus", 20000)
      lemonade.bonus[lemonade.bonus_rev[i]] = i
    end

    -- prepare npc definitions
    for name, def in next, lemonade.npcs do
      def.name = name
      def.button = "buy"
      def.interactive = true
      def.lookAtPlayer = true
      def.left_disabled = true
      def.left_image = "img@198008a0cb4"
      def.left_amount = def.price
      def.right_amount = "1"
      def.right_button = "buy"
    end

    local xml = [[<C><P L="1500" H="600" PKAUTHOR="Lemonade Festival"/><Z><S><S T="0" X="750" Y="545" L="1502" H="10" P="0,0,0.3,0.2,0,0,0,0" N="" m=""/><S T="12" X="748" Y="274" L="1495" H="546" P="0,0,0.3,0.2,0,0,0,0" o="324650" c="4" i="0,0,197c77274f0.png"/><S T="0" X="-5" Y="263" L="11" H="568" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="4" X="517" Y="479" L="33" H="10" P="0,0,20,0.2,0,0,0,0" m=""/><S T="4" X="560" Y="479" L="34" H="10" P="0,0,20,0.2,0,0,0,0" m=""/><S T="4" X="626" Y="479" L="33" H="10" P="0,0,20,0.2,0,0,0,0" m=""/><S T="4" X="692" Y="479" L="32" H="10" P="0,0,20,0.2,0,0,0,0" m=""/><S T="4" X="769" Y="479" L="68" H="10" P="0,0,20,0.2,0,0,0,0" m=""/><S T="0" X="666" Y="310" L="269" H="48" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="13" X="347" Y="517" L="10" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="16" X="348" Y="529" L="38" H="17" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="16" X="256" Y="374" L="10" H="116" P="0,0,0.3,0.2,55,0,0,0" m=""/><S T="16" X="311" Y="404" L="10" H="206" P="0,0,0.3,0.2,90,0,0,0" m=""/><S T="16" X="355" Y="369" L="10" H="128" P="0,0,0.3,0.2,120,0,0,0" m=""/><S T="16" X="305" Y="331" L="10" H="20" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="4" X="1040" Y="264" L="10" H="401" P="0,0,20,0.2,0,0,0,0" m=""/><S T="0" X="1140" Y="520" L="156" H="10" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="0" X="1338" Y="520" L="153" H="10" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="0" X="1507" Y="265" L="10" H="573" P="0,0,0.3,0.2,0,0,0,0" m=""/><S T="12" X="750" Y="-40" L="1500" H="70" P="0,0,0.3,0.2,0,0,0,0" o="6A7495" N=""/><S T="4" X="331" Y="223" L="10" H="238" P="0,0,20,0.2,0,0,0,0" m=""/><S T="13" X="1129" Y="379" L="21" P="0,0,0.3,0.5,0,0,0,0" o="324650" m=""/><S T="13" X="1254" Y="116" L="26" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="1232" Y="106" L="26" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="1217" Y="121" L="26" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/><S T="13" X="1205" Y="113" L="26" P="0,0,0.3,0.2,0,0,0,0" o="324650" m=""/></S><D><P X="142" Y="519" T="68" P="0,0"/><P X="157" Y="519" T="68" P="0,0"/><P X="800" Y="-15" T="19" C="329cd2" P="0,0"/><DS X="1454" Y="524"/></D><O><O X="600" Y="-40" C="22" P="0"/></O><L/></Z></C>]]
    lemonade.map = xml

    function lemonade.resetWait()
      lemonade.state = WAIT
      lemonade.tradeNext = false
      lemonade.can_collect = nil
      lemonade.jug.ids = nil
      lemonade.jug.progress = nil
      lemonade.items = nil
    end

    function lemonade.resetRound()
      lemonade.rounds = math.random(2, 4)
      lemonade.timestamp = os.time() + math.random(15, 30) * 60 * 1000
    end

    function lemonade.reset()
      lemonade.resetWait()
      lemonade.resetRound()
      lemonade.chance = 0
    end

    function lemonade.debug(player, cmd, quantity, args)
      if args[2] == "trade" then
        next_map = lemonade.map
        lemonade.tradeNext = true
        tfm.exec.chatMessage("<J>Lemonade trade map will appear next round", player)
      elseif args[2] == "chance" then
        tfm.exec.chatMessage("<J>Chance of craft map appearing: " .. tostring(lemonade.chance), player)
      else
        lemonade.rounds = 0
        lemonade.timestamp = 0
        tfm.exec.chatMessage("<J>Lemonade items will appear next round", player)
      end
    end

    function lemonade.renderJug(player)
      local jug = lemonade.jug
      if jug.ids[player] then
        tfm.exec.removeImage(jug.ids[player], true)
      end
      jug.ids[player] = tfm.exec.addImage(
        jug[jug.progress[player]], "!999",
        jug.x, jug.y, player, 1, 1, 0, 1, 0.5, 0.5, true
      )
    end

    function lemonade.render(target)
      if not target then
        for name in next, room.playerList do
          lemonade.render(name)
        end
        return
      end

      local file = players_file[target]
      if not file then return end

      if file.settings[6] == 1 then
        translatedChatMessage("lemonade_welcome", target)
      end

      if lemonade.state == COLLECT then
        local items, item, collectible = lemonade.items
        local seen = {}
        for i=1, #items do
          item = items[i]
          collectible = lemonade.collectibles[item.i]

          if lemonade.can_collect[i][target] ~= false then
            lemonade.can_collect[i][target] = tfm.exec.addImage(collectible[3], "!999", item.x, item.y, target, 1, 1, 0, 1, 0.5, 0.5)
            tfm.exec.addBonus(0, item.x, item.y, lemonade.bonus_rev[i], 0, false, target)

            if not seen[item.i] then
              seen[item.i] = true
              translatedChatMessage("lemonade_" .. collectible[2], target)
            end
          else
            tfm.exec.addImage(collectible[3], "!999", item.x, item.y, target, 1, 1, 0, 0.3, 0.5, 0.5)
          end
        end
      elseif lemonade.state == TRADE then
        map_name = nil
        ui.setMapName("Lemonade Festival")

        lemonade.jug.progress[target] = 1
        lemonade.renderJug(target)

        for ecIndex, ta in next, lemonade.countTA do
          ui.addTextArea(
            ta[3], "<vp><p align='center'><font color='#000000' size='18'>" .. file:getItemAmount(ecIndex, 0),
            target, ta[1], ta[2], ta[4] or 30, nil, 0, 0, 0, false
          )
        end

        for kind, ta in next, lemonade.buttonTA do
          ui.addTextArea(
            ta[7], "<a href='event:lemonade_" .. kind .. "'><font size='50'>  ",
            target, ta[3], ta[4], ta[5], ta[6], 0, 0, 0, false
          )
        end

        for name, def in next, lemonade.npcs do
          tfm.exec.addNPC(name, def, target)
        end
      end
    end

    function lemonade.updateCounter(target, ecIndex)
      local ta = lemonade.countTA[ecIndex]
      local file = players_file[target]
      if not ta or not file then return end
      ui.updateTextArea(ta[3], "<vp><p align='center'><font color='#000000' size='18'>" .. file:getItemAmount(ecIndex, 0), target)
    end

    function lemonade.hideTrade(target)
      for _, ta in next, lemonade.countTA do
        ui.removeTextArea(ta[3], target)
      end
      for _, ta in next, lemonade.buttonTA do
        ui.removeTextArea(ta[7], target)
      end
    end

    function lemonade.initTrade()
      if current_map == lemonade.map and lemonade.tradeNext then
        lemonade.reset()
        lemonade.state = TRADE
        lemonade.jug.ids = {}
        lemonade.jug.progress = {}
        lemonade.render()
        tfm.exec.setGameTime(360)
        return true
      end
    end

    function lemonade.initRound()
      lemonade.rounds = lemonade.rounds - 1

      if lemonade.rounds > 0 or lemonade.timestamp > os.time() then
        lemonade.resetWait()
        return
      end

      lemonade.resetRound()
      lemonade.state = COLLECT
      lemonade.chance = lemonade.chance + 25
      lemonade.can_collect = {}

      lemonade.generate(current_difficulty)

      for i=1, 3 do
        lemonade.can_collect[i] = {}
      end

      lemonade.render()

      if math.random(1, 100) <= lemonade.chance then
        next_map = lemonade.map
        lemonade.tradeNext = true
      end
    end

    function lemonade.generate(difficulty)
      difficulty = math.max(1, math.min(3, difficulty))

      lemonade.items = {}
      for i=1, difficulty do
        lemonade.items[i] = {
          i = math.random(1, #lemonade.collectibles),
          x = math.random(50, 750),
          y = math.random(50, 350),
        }
      end
    end

    function lemonade.getCollectible(player, index)
      local item = lemonade.items[index]
      if not item then return end
      local img = lemonade.can_collect[index][player]
      if not img then return end
      local collectible = lemonade.collectibles[item.i]
      return collectible, item, img
    end

    function lemonade.collect(player, index)
      local collectible, item, img = lemonade.getCollectible(player, index)
      tfm.exec.removeImage(img, true)
      tfm.exec.addImage(collectible[3], "!999", item.x, item.y, player, 1, 1, 0, 0.3, 0.5, 0.5, true)
      lemonade.can_collect[index][player] = false
    end

    lemonade.reset()

    onEvent("NewGame", function()
      if lemonade.initTrade() then
        return
      end

      lemonade.hideTrade()

      if doStatsCount() then
        lemonade.initRound()
      else
        lemonade.resetWait()
      end
    end)

    onEvent("PlayerDataParsed", function(player, init)
      if lemonade.state == WAIT then return end
      lemonade.render(player)
    end)

    onEvent("PlayerBonusGrabbed", function(player, bonus)
      if lemonade.state ~= COLLECT or review_mode then return end

      local index = lemonade.bonus[bonus]
      if not index then return end

      local pdata = players_file[player]
      if not pdata then return end

      local collectible = lemonade.getCollectible(player, index)
      local ecIndex = collectible and collectible[1]
      if not ecIndex then return end

      -- limit to 10 per item
      if pdata:getItemAmount(ecIndex, 0) == 10 then
        translatedChatMessage("lemonade_toomuch", player)
        return
      end

      lemonade.collect(player, index)
      pdata:updateItem(ecIndex, 0, 1)
      savePlayerData(player)
      translatedChatMessage("lemonade_found", player)
    end)

    onEvent("TalkToNPC", function(player, npc)
      if lemonade.state ~= TRADE or review_mode then return end
      if not checkCooldown(player, "npc_" .. npc, 1000) then return end

      local shop = lemonade.npcs[npc]
      local file = players_file[player]
      if not shop or not file then return end

      if shop.itemID then
        if file:findItem(shop.itemID) then return end
      elseif shop.badgeGroup and shop.badge then
        if file.badges[shop.badgeGroup] == shop.badge then return end
      end

      NPCInterface:show(player, shop)
    end)

    onEvent("TextAreaCallback", function(id, player, event)
      if lemonade.state ~= TRADE or review_mode then return end
      if event:sub(1, 9) ~= "lemonade_" then return end
      if not checkCooldown(player, "lemonadeta", 500) then return end
      local param = event:sub(10)

      local file = players_file[player]
      if not file then return end

      local btn = lemonade.buttonTA[param]
      local p = tfm.get.room.playerList[player]
      if not btn or not p or btn[7] ~= id then return end

      -- make sure it has the item
      if btn[2] and file:getItemAmount(btn[2], 0) < 1 then
        return
      end

      if lemonade.jug.progress[player] ~= btn[1] then
        return
      end

      if lemonade.jug.progress[player] == 6 then
        lemonade.jug.progress[player] = 1
        lemonade.renderJug(player)

        if file:getItemAmount(2, 0) > 99 then return end -- limited to 100 lemonades

        -- check ingredients first
        for i=3, 6 do
          if file:getItemAmount(i, 0) < 1 then
            translatedChatMessage("lemonade_insufficient", player)
            return
          end
        end

        -- make sure player receives the lemonade first
        if not file:updateItem(2, 0, 1) then return end

        -- remove 1 of each ingredient
        for i=3, 6 do file:updateItem(i, 0, -1) end
        for i=2, 6 do lemonade.updateCounter(player, i) end
        savePlayerData(player)
        return
      end

      lemonade.jug.progress[player] = lemonade.jug.progress[player] + 1
      lemonade.renderJug(player)
    end)

    onEvent("TradeNPC", function(player, npc)
      if lemonade.state ~= TRADE or review_mode then return end

      local shop = lemonade.npcs[npc]
      local file = players_file[player]
      if not shop or not file then return end

      if file:getItemAmount(2, 0) >= shop.price then
        if shop.itemID then
          if not rewardSkin(player, shop.itemID) then return end
        elseif shop.badgeGroup and shop.badge then
          if file.badges[shop.badgeGroup] == shop.badge then return end

          file.badges[shop.badgeGroup] = shop.badge

          if shop.badge > 0 then
            NewBadgeInterface:show(player, shop.badgeGroup, shop.badge)
          end
        end

        file:updateItem(2, 0, -shop.price)
        lemonade.updateCounter(player, 2)
        savePlayerData(player)

        if NPCInterface.open[player] then
          NPCInterface:remove(player)
        end
      else
        NPCInterface:update(player, shop, "lemonade_insufficient")
      end
    end)
  end
end
