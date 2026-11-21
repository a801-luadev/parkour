local function ValentineInterface(valentine)
  local fountain = {}

  local materials = valentine.materials
  local material_count = #materials
  local deposits = {}
  local isOpen = {}
  local images = {}

  local PANEL_X, PANEL_Y, SLOT_W, ROW_H = 7, 28, 58, 20
  local PANEL_W = SLOT_W * material_count + 8
  local BUTTON_W, BUTTON_GAP = 70, 14
  local BUTTON_Y = PANEL_Y + ROW_H + 14

  local PANEL_TA = allocateId("textarea", 40000)
  local ADD_BUTTON = allocateId("textarea", 40000)
  local REMOVE_BUTTON = allocateId("textarea", 40000)
  local READY_BUTTON = allocateId("textarea", 40000)
  local countTAs = {}

  for i=1, material_count do
    countTAs[i] = allocateId("textarea", 40000)
  end

  local function calculateRings(amounts)
    local total = 0
    for i=1, material_count do
      total = total + (amounts[i] or 0) * materials[i].rarity
    end
    return math.floor(total / valentine.ringCost), total
  end

  local function buttonText(color, label, event)
    local text = "<font color='" .. color .. "' size='10'><b>" .. label .. "</b></font>"
    if event then
      text = "<a href='event:" .. event .. "'>" .. text .. "</a>"
    end
    return "<p align='center'>" .. text .. "</p>"
  end

  function fountain.updateButtons(player)
    if not isOpen[player] then return end

    ui.updateTextArea(
      ADD_BUTTON,
      buttonText("#FFFFFF", translatedMessage("valentine_add_all", player), "valentine_add_all"),
      player
    )
    ui.updateTextArea(
      REMOVE_BUTTON,
      buttonText("#FF9AA2", translatedMessage("valentine_remove_all", player), "valentine_remove_all"),
      player
    )
  end

  function fountain.updateReady(player)
    if not isOpen[player] then return end

    local ready = valentine.session.ready[player]
    ui.updateTextArea(
      READY_BUTTON,
      buttonText(
        ready and "#B5F2C0" or "#7EE08F",
        translatedMessage(ready and "valentine_cancel" or "valentine_ready", player),
        "valentine_ready"
      ),
      player
    )
  end

  function fountain.seal()
    local text
    for name in next, isOpen do
      text = buttonText("#FFFFFF", translatedMessage("valentine_sealed", name))
      ui.updateTextArea(ADD_BUTTON, text, name)
      ui.updateTextArea(REMOVE_BUTTON, text, name)
    end
  end

  local function isSealed()
    return valentine.session.endTime - os.time() <= 10000
  end

  function fountain.refresh(player)
    if not isOpen[player] then return end

    local file = players_file[player]
    if not file then return end

    for i=1, material_count do
      ui.updateTextArea(
        countTAs[i],
        "<p align='left'><font size='11' color='#FFFFFF'><b>x" .. file:getItemAmount(materials[i].ec, 0) .. "</b></font></p>",
        player
      )
    end
  end

  local function removeImages(player)
    local img = images[player]
    if img then
      for i=1, material_count do
        tfm.exec.removeImage(img[i])
      end
      images[player] = nil
    end
  end

  function fountain.show(player)
    local file = players_file[player]
    if not file then return end

    isOpen[player] = true
    removeImages(player)

    local x
    local img = {}
    images[player] = img

    ui.addTextArea(PANEL_TA, "", player, PANEL_X, PANEL_Y, PANEL_W, ROW_H, 0x070707, 0x6B3550, 0.75, false)

    for i=1, material_count do
      x = PANEL_X + 6 + (i - 1) * SLOT_W
      ui.addTextArea(countTAs[i], "", player, x + 18, PANEL_Y + 2, SLOT_W - 20, ROW_H - 4, 0, 0, 0, false)
      img[i] = tfm.exec.addImage(materials[i].image, "~1", x, PANEL_Y + 3, player, 0.5, 0.5)
    end

    ui.addTextArea(ADD_BUTTON, "", player, PANEL_X, BUTTON_Y, BUTTON_W, ROW_H, 0x24101A, 0x6B3550, 0.75, false)
    ui.addTextArea(
      REMOVE_BUTTON, "", player,
      PANEL_X + BUTTON_W + BUTTON_GAP, BUTTON_Y, BUTTON_W, ROW_H, 0x24101A, 0x6B3550, 0.75, false
    )
    ui.addTextArea(
      READY_BUTTON, "", player,
      PANEL_X + (BUTTON_W + BUTTON_GAP) * 2, BUTTON_Y, BUTTON_W, ROW_H, 0x24101A, 0x6B3550, 0.75, false
    )

    fountain.refresh(player)
    fountain.updateButtons(player)
    fountain.updateReady(player)
  end

  function fountain.hide(player)
    isOpen[player] = nil

    ui.removeTextArea(PANEL_TA, player)
    for i=1, material_count do
      ui.removeTextArea(countTAs[i], player)
    end
    ui.removeTextArea(ADD_BUTTON, player)
    ui.removeTextArea(REMOVE_BUTTON, player)
    ui.removeTextArea(READY_BUTTON, player)

    removeImages(player)
  end

  local function removeDeposit(player)
    if not deposits[player] then return end

    local session = valentine.session
    deposits[player] = nil
    session.depositCount = session.depositCount - 1

    if session.ready[player] then
      session.ready[player] = nil
      session.readyCount = session.readyCount - 1
    end
  end

  function fountain.addAll(player)
    local session = valentine.session
    if session.mode ~= "deposit" or deposits[player] then return end
    if not checkCooldown(player, "valentine_add", 1000) then return end

    if isSealed() then
      translatedChatMessage("valentine_deposits_disabled", player)
      return
    end

    local file = players_file[player]
    if not file then return end

    local amounts = {}
    for i=1, material_count do
      amounts[i] = file:getItemAmount(materials[i].ec, 0)
    end

    local rings, total = calculateRings(amounts)
    if rings < 1 then
      translatedChatMessage("valentine_insufficient_materials", player)
      return
    end

    local maxGain = valentine.ringLimit - file:getItemAmount(valentine.ringEcIndex, 0)
    if maxGain < 1 then
      translatedChatMessage("valentine_ring_limit", player)
      return
    end

    rings = math.min(rings, maxGain)

    local needed = rings * valentine.ringCost
    local value, remove
    for i=1, material_count do
      value = materials[i].rarity
      remove = math.min(amounts[i], math.floor((total - needed) / value))
      if remove > 0 then
        amounts[i] = amounts[i] - remove
        total = total - remove * value
      end
    end

    deposits[player] = amounts
    valentine.session.depositCount = valentine.session.depositCount + 1
    translatedChatMessage("valentine_materials_selected", player, rings)
  end

  function fountain.clearAll(player)
    local session = valentine.session
    if session.mode ~= "deposit" or not deposits[player] then return end
    if not checkCooldown(player, "valentine_clear", 1000) then return end

    if isSealed() then
      translatedChatMessage("valentine_deposits_disabled", player)
      return
    end

    removeDeposit(player)
    fountain.updateReady(player)
    translatedChatMessage("valentine_selection_cleared", player)
  end

  function fountain.hasDeposit(player)
    return deposits[player] ~= nil
  end

  function fountain.getDeposits()
    return deposits
  end

  function fountain.clearAllDeposits()
    deposits = {}
    local session = valentine.session
    session.ready = {}
    session.readyCount = 0
    session.depositCount = 0
  end

  function fountain.clearPlayer(player)
    removeDeposit(player)
    isOpen[player] = nil
    images[player] = nil
  end

  return fountain
end
