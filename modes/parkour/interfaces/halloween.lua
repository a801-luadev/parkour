local function HalloweenInterface(halloween)
  local cauldron = {}
  local CLEAR_ALL_BUTTON = allocateId("textarea", 40000)
  local ADD_ALL_BUTTON = allocateId("textarea", 40000)

  local materials = halloween.materials
  local material_count = halloween.materialTypes
  local deposits = {}
  local isOpen = {}

  local cauldronTAs = {}
  local matCountTAs = {}
  local images = {}

  for i=1, material_count do
    cauldronTAs[i] = allocateId("textarea", 40000)
    matCountTAs[i] = allocateId("textarea", 40000)
    deposits[i] = {}
  end

  function cauldron.show(player)
    local file = players_file[player]
    if not file then return end

    isOpen[player] = true

    local currentTime = os.time()
    local remaining = halloween.cauldron.endTime - currentTime
    local remainingSeconds = math.floor(remaining / 1000)
    local mm = math.floor(remainingSeconds / 60)
    local ss = remainingSeconds % 60
    local timeLabel = string.format("<p align='center'><font size='13'><B><N>%s: %02d:%02d</B></font></p>", translatedMessage("halloween_ritual", player), mm, ss)
    ui.addTextArea(halloween.cauldron.labels.timerTA, timeLabel, player, 300, 25, 200, 18, 0, 0, 0, false)

    images[player] = {
      [1] = tfm.exec.addImage("199c8c59d72.png", "!10", 25, 54, player, 1, 1, 0, 1, 0, 0, true),
    }

    local count, row, col, x, y, material
    for i=1, material_count do
      material = materials[i]
      count = file:getItemAmount(material.ec, 0)
      x = 90 + (i - 1) * 110
      y = 60

      images[player][1 + i] = tfm.exec.addImage(material.image, "!10", x, y, player, 1, 1, 0, 1, 0, 0, true)
      ui.addTextArea(matCountTAs[i], "<p align='center'><font color='#ffffff' size='15'><B>" .. count .. "</B></font></p>", player, x + 20, y + 2, 60, 30, 0, 0, 0, false)

      row = math.floor((i - 1) / 3)
      col = (i - 1) % 3
      x = 350 + col * 40
      y = 260 + row * 25

      images[player][1 + material_count + i] = tfm.exec.addImage(material.image, "!10", x, y, player, 0.5, 0.5, 0, 1, 0, 0, true)
      ui.addTextArea(cauldronTAs[i], "<p align='left'><font size='10'><B>0</B></font></p>", player, x + 15, y, 30, 30, 0, 0, 0, false)
    end
    local last_index = 1 + material_count * 2

    ui.addTextArea(ADD_ALL_BUTTON, "<p align='center'><a href='event:cauldron_add_all'><font size='12' color='#ffffff'><B>" .. translatedMessage("halloween_add_all", player) .. "</B></font></a>", player, 90, 127, 120, 30, 0, 0, 0, false)
    images[player][last_index + 1] = tfm.exec.addImage("199c8c5ece8.png", "!10", 50, 100, player, 1, 1, 0, 1, 0, 0, true)

    ui.addTextArea(CLEAR_ALL_BUTTON, "<p align='center'><a href='event:cauldron_clear_all'><font size='12' color='#ffffff'><B>" .. translatedMessage("halloween_remove_all", player) .. "</B></font></a>", player, 640, 127, 120, 30, 0, 0, 0, false)
    images[player][last_index + 2] = tfm.exec.addImage("199c8c6076f.png", "!10", 600, 100, player, 1, 1, 0, 1, 0, 0, true)

    images[player]._len = last_index + 2
  end

  function cauldron.hide(player)
    isOpen[player] = nil

    ui.removeTextArea(halloween.cauldron.labels.potTA, player)
    --ui.removeTextArea(halloween.cauldron.labels.timerTA, player)

    for i=1, material_count do
      ui.removeTextArea(cauldronTAs[i], player)
    end

    ui.removeTextArea(CLEAR_ALL_BUTTON, player)
    ui.removeTextArea(ADD_ALL_BUTTON, player)

    local img = images[player]
    if img then
      for i=1, img._len do
        tfm.exec.removeImage(img[i])
      end
      images[player] = nil
    end

    for i=1, material_count do
      ui.removeTextArea(matCountTAs[i], player)
    end
  end
  
  local function hasDeposits(player)
    for i=1, material_count do
      if deposits[i][player] then
        return true
      end
    end
  end

  local function hasAvailableMaterials(player)
    local file = players_file[player]
    if not file then return false end

    for i=1, material_count do
      if file:getItemAmount(materials[i].ec, 0) > 0 then
        return true
      end
    end
    return false
  end

  function cauldron.clearAll(player)
    if not checkCooldown(player, "cauldron_clear", 1000) or not hasDeposits(player) then
      return
    end

    if halloween.cauldron.active then
      local remaining = halloween.cauldron.endTime - os.time()
      if math.floor(remaining / 1000) <= 10 then
        translatedChatMessage("halloween_deposits_disabled", player)
        return
      end
    end

    for i=1, material_count do
      deposits[i][player] = nil
    end

    cauldron.updateCauldronDisplay()
    translatedChatMessage("halloween_all_deposits_cleared", player)
  end

  function cauldron.clearAllDeposits()
    for i=1, material_count do
      deposits[i] = {}
    end
  end

  local function calculatePotionValue(_deposits)
    local total, max, amount, rarity = 0, 1200
    for i=1, material_count do
      amount = _deposits[i]
      if amount then
        rarity = materials[i].rarity
        total = total + (amount * rarity)
      end
    end
    return total * 100 / max
  end

  local function adjustDepositsForPotionLimit(currentPotion, _deposits, potionFromDeposits)
    potionFromDeposits = math.floor(potionFromDeposits)
    if potionFromDeposits < 1 then
      return
    end
    
    local maxGain = 200 - currentPotion
    if currentPotion >= 200 or maxGain < 1 then
      return
    end
    
    local totalVal = 0
    for i = 1, material_count do
      if _deposits[i] then
        totalVal = totalVal + _deposits[i] * materials[i].rarity
      end
    end
    
    local refund = 0
    for i = 1, material_count do
      if _deposits[i] then
        local amt = _deposits[i]
        local r = materials[i].rarity
        local contribution = amt * r
        
        local newVal = totalVal - contribution
        local newPotions = math.floor(newVal / 12)
        local currentPotions = math.floor(totalVal / 12)
        
        if newPotions == currentPotions and newPotions >= 1 then
          totalVal = newVal
          refund = refund + amt
          _deposits[i] = nil
        elseif newPotions < currentPotions then
          local targetPotions = math.min(currentPotions, maxGain)
          local targetVal = targetPotions * 12
          local excess = totalVal - targetVal
          
          if excess > 0 then
            local toRemove = math.min(amt, math.floor(excess / r))
            if toRemove > 0 then
              _deposits[i] = amt - toRemove
              totalVal = totalVal - toRemove * r
              refund = refund + toRemove
            end
          end
        end
      end
    end
    
    local finalPotions = math.floor(totalVal / 12)
    if finalPotions < 1 then
      return nil
    end
    
    return math.min(finalPotions, maxGain), refund
  end

  function cauldron.disableDeposits()
    local disabledText
    for player in next, isOpen do
      disabledText = "<p align='center'><font size='12' color='#ffffff'><B>" .. translatedMessage("halloween_deposits_disabled_ui", player) .. "</B></font></p>"
      ui.updateTextArea(ADD_ALL_BUTTON, disabledText, player)
      ui.updateTextArea(CLEAR_ALL_BUTTON, disabledText, player)
    end
  end

  function cauldron.addAll(player)
    if not checkCooldown(player, "cauldron_add", 1000) or hasDeposits(player) or not hasAvailableMaterials(player) then
      return
    end

    if halloween.cauldron.active then
      local remaining = halloween.cauldron.endTime - os.time()
      if math.floor(remaining / 1000) <= 10 then
        translatedChatMessage("halloween_deposits_disabled", player)
        return
      end
    end
  
  local file = players_file[player]
  if not file then return end
  
    local _deposits = {}
    for i=1, material_count do
      _deposits[i] = file:getItemAmount(materials[i].ec, 0)
      if _deposits[i] == 0 then _deposits[i] = nil end
    end

    local potionFromDeposits = calculatePotionValue(_deposits)
    if potionFromDeposits < 1 then
      translatedChatMessage("halloween_insufficient_materials", player)
      return
    end

    local currentPotion = file:getItemAmount(13, 0)
    local potionGain, refundAmount = adjustDepositsForPotionLimit(currentPotion, _deposits, potionFromDeposits)
    if not potionGain then
      translatedChatMessage("halloween_potion_limit_reached", player)
      return
    end

    for i=1, material_count do
      if _deposits[i] then
        deposits[i][player] = _deposits[i]
      end
    end

    cauldron.updateCauldronDisplay()

    if refundAmount and refundAmount > 0 then
      translatedChatMessage("halloween_materials_limited", player, potionGain)
    else
      translatedChatMessage("halloween_all_materials_selected", player)
    end
  end

  function cauldron.updateCauldronDisplay()
    local sum
    for i=1, material_count do
      sum = 0
      for _, count in next, deposits[i] do
        sum = sum + count
      end
      ui.updateTextArea(cauldronTAs[i], "<p align='left'><font size='10'><B>" .. sum .. "</B></font></p>")
    end
  end
  
  function cauldron.getAllDeposits()
    return deposits
  end

  function cauldron.clearPlayerDeposits(player)
    for i=1, material_count do
      deposits[i][player] = nil
    end
  end

  return cauldron
end