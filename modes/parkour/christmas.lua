local christmas

do
  local day = tonumber(os.date("%d"))
  local month = tonumber(os.date("%m"))
  local is_christmas_time = (month == 12 and day >= 15) or (month == 1 and day <= 15) or force_christmas_debug

  if is_christmas_time then
    christmas = {
      bonusId = 999,
      imageName = "18c73e40d6d.png",
      imageTarget = "!999",
      prizes = { 10, 50, 100, 250, 500, 750, 1000 },
      chances = { 8600, 1000, 200, 139, 50, 10, 1 },
    }

    christmas.reset = function()
      christmas.rounds = math.random(2, 4)
      christmas.timestamp = os.time() + math.random(15, 30) * 60 * 1000
    end

    christmas.nextRound = function()
      christmas.rounds = 0
      christmas.timestamp = 0
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
      if prize > 50 then
        translatedChatMessage("found_gift" .. msg, nil, player, prize)
      else
        translatedChatMessage("found_gift" .. msg, player, player, prize)
      end

      tfm.exec.removeBonus(christmas.bonusId, player)
      tfm.exec.removeImage(christmas.images[player], true)

      return prize
    end

    christmas.reset()
  end
end
