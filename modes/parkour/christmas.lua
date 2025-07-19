do
  local day = tonumber(os.date("%d"))
  local month = tonumber(os.date("%m"))
  local is_christmas_time = (month == 12 and day >= 15) or (month == 1 and day <= 15) or force_christmas_debug

  if is_christmas_time then
    shop_skins["1"] = {img = "18c72bad79e.png", x = 0.5, y = 0.50}
    shop_skins["2"] = {img = "18c72ba3321.png", x = 0.5, y = 0.50}
    shop_skins["7"] = {img = "18c72bb2589.png", x = 0.5, y = 0.52}
    shop_skins["28"] = {img = "18c72bccb7c.png", x = 0.5, y = 0.30}
    shop_skins["46"] = {img = "18c72ba881a.png", x = 0.5, y = 0.52}

    findValueTbl(shop_items[1], "id", 1).image = "18c72bd8ad1.png"
    findValueTbl(shop_items[2], "id", 2).image = "18c72bd3975.png"
    findValueTbl(shop_items[3], "id", 7).image = "18c72bddd28.png"
    findValueTbl(shop_items[4], "id", 28).image = "18c72bb89a4.png"
    findValueTbl(shop_items[5], "id", 46).image = "18c72bfa272.png"
    findValueTbl(shop_items[8], "id", 2).hidden = false

    local christmas = {
      bonusId = allocateId("bonus", 20000),
      imageName = "18c73e40d6d.png",
      imageTarget = "!999",
      prizes = { 10, 50, 100, 250, 500, 750, 1000, 0 },
      chances = { 8600, 1000, 200, 139, 49, 10, 1, 1 },
    }
    activeEvents.christmas = christmas

    christmas.reset = function()
      christmas.rounds = math.random(2, 4)
      christmas.timestamp = os.time() + math.random(15, 30) * 60 * 1000
    end

    christmas.debug = function(player, cmd, quantity, args)
      christmas.rounds = 0
      christmas.timestamp = 0
      tfm.exec.chatMessage("<J>Christmas gifts will appear next round", player)
    end

    christmas.createGift = function(player)
      if not christmas.isGiftRound or christmas.collected[player] then
        return
      end

      christmas.images[player] = tfm.exec.addImage(
        christmas.imageName, christmas.imageTarget,
        christmas.gift_x, christmas.gift_y, player,
        1, 1, 0, 1, 0.5, 0.5, true
      )
      tfm.exec.addBonus(0, christmas.gift_x, christmas.gift_y, christmas.bonusId, 0, false, player)
      translatedChatMessage(christmas.msg, player)
    end

    christmas.resetRound = function()
      christmas.isGiftRound = false
    end

    christmas.initRound = function()
      christmas.rounds = christmas.rounds - 1

      if christmas.rounds > 0 or christmas.timestamp > os.time() then
        christmas.resetRound()
        return
      end

      christmas.isGiftRound = true
      christmas.collected = {}
      christmas.images = {}
      christmas.gift_x = math.random(50, 1580) 
      christmas.gift_y = math.random(50, 700)
      christmas.msg = "find_gift" .. math.random(1, 5)

      for player in next, room.playerList do
        christmas.createGift(player)
      end

      christmas.reset()
    end

    christmas.collectGift = function(player)
      if not christmas.isGiftRound or christmas.collected[player] then
        return
      end

      christmas.collected[player] = true

      local randomValue = math.random(0, 100 * 100)
      local totalChance = 0
      local prize = 0

      for i=1, #christmas.chances do
        totalChance = totalChance + christmas.chances[i]

        if randomValue <= totalChance then
          prize = christmas.prizes[i]
          break
        end
      end

      local msg = math.random(1, 5)
      if prize > 50 or prize == 0 then
        translatedChatMessage("found_gift" .. msg, nil, player, prize)
      else
        translatedChatMessage("found_gift" .. msg, player, player, prize)
      end

      tfm.exec.removeBonus(christmas.bonusId, player)
      tfm.exec.removeImage(christmas.images[player], true)

      return prize
    end

    christmas.reset()

    onEvent("NewGame", function()
      if doStatsCount() then
        christmas.initRound()
      else
        christmas.resetRound()
      end
    end)

    onEvent("NewPlayer", function(player, init)
      christmas.createGift(player)
    end)

    onEvent("PlayerBonusGrabbed", function(player, bonus)
      if christmas.bonusId == bonus then
        local prize = christmas.collectGift(player)
        local pdata = players_file[player]
        if pdata and prize then
          pdata.coins = pdata.coins + prize
          if pdata:getItemAmount(1, 0) ~= 100 then
            pdata:updateItem(1, 0, 1)
          end
          if pdata:getItemAmount(1, 0) >= 30 then
            if not rewardSkin(player, "bigBox", 200.1) -- ice cube
            and not rewardSkin(player, "cloud", 57.1) -- reindeer sleigh
            and not rewardSkin(player, "rip", 1028) then -- snowy anvil
              return -- has all of them
            end
            pdata:updateItem(1, 0, -30)
            queueForSave(player)
          end
        end
        return
      end
    end)
  end
end
