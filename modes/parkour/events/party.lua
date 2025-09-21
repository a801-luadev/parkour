do
local function initParty()

if records_admins then return end

local party = {}
activeEvents.party = party

local partyHost = {}

local function isPartyHost(name)
  local time = partyHost[name]
  if not time then return end
  if os.time() > time then
    partyHost[name] = nil
    return
  end
  return true
end

newCmd({ name = "partyhost",
  rank = "admin",
  fn = function(player, args, cmd)
  if not args[1] then
    local now = os.time()
    sendChatFmt('<j>Party Hosts:', player)
    for name, expires in next, partyHost do
      if now < expires then
        sendChatFmt("<v>%s<BL>: %s min", player, name, (expires-now) / 60 / 1000)
      end
    end
    return
  end

  chatlogCmd(cmd, player, args)

  local time = os.time() + 60 * 60 * 1000 -- 1 hour

  if args[2] then
    time = tonumber(args[2])
    if not time and args[2] ~= "remove" then
      sendChatFmt('<r>Second parameter should be either "remove" or a number in minutes', player)
      return
    end

    if time then
      time = os.time() + time * 60 * 1000
    end
  end

  if args[1] == '*' and args[2] == 'remove' then
    partyHost = {}
    sendChatFmt('<r>Party host list is clear now!', player)
    return
  end

  partyHost[args[1]] = time or nil
  if partyHost[args[1]] then
    sendChatFmt('<vp>%s is a party host now!', player, args[1])
  else
    sendChatFmt('<r>%s is not a party host anymore!', player, args[1])
  end
end })

newCmd({ name = "link",
  min_args = 1,
  fn = function(player, args, cmd)
  if not ranks.admin[player] and not isPartyHost(player) then
    return
  end

  if not args[1] then return end
  if not args[2] then 
    args[2] = player
  end

  local firstPlayer = args[1]
  local secondPlayer = args[2]

  if not ranks.admin[player] and (not victory[firstPlayer] or not victory[secondPlayer]) then
    return sendChatFmt('<r>Target players must complete the map', player)
  end

  tfm.exec.linkMice(firstPlayer, secondPlayer, true)

  if not ranks.admin[player] then
    chatlogCmd(cmd, player, args, partyHost)
  end
end })

newCmd({ name = "size",
  min_args = 2,
  fn = function(player, args, cmd)
  if not ranks.admin[player] and not isPartyHost(player) then return end

  local target = args[1]
  if not room.playerList[target] then
    return sendChatFmt('<r>Target player is not in the room', player)
  end
  if not ranks.admin[player] and not victory[target] then
    return sendChatFmt('<r>Target player must complete the map', player)
  end

  local size = tonumber(args[2])
  if not size then
    return sendChatFmt('<r>Second parameter should be a number', player)
  end

  tfm.exec.changePlayerSize(target, size)

  if not ranks.admin[player] then
    chatlogCmd(cmd, player, args, partyHost)
  end
end })

newCmd({ name = "look",
  min_args = 1,
  fn = function(player, args, cmd)
  if not ranks.admin[player] and not isPartyHost(player) then return end

  local target = args[1]
  local look = args[2]

  if target ~= "*" and not room.playerList[target] then
    return sendChatFmt('<r>Target player is not in the room', player)
  end

  if target == "*" then
    for target, info in next, playerList do
      tfm.exec.setPlayerLook(target, look or info.look)
    end
  else
    local info = room.playerList[target]
    tfm.exec.setPlayerLook(target, look or info.look)
  end

  if not ranks.admin[player] then
    chatlogCmd(cmd, player, args, partyHost)
  end
end })

newCmd({ name = "npc",
  min_args = 1,
  rank = "admin",
  fn = function(player, args, cmd)
  local info = room.playerList[player]
  if not info then return end

  local name = args[1]
  local look = args[2] ~= 'remove' and args[2] ~= 'default' and args[2] or nil
  local x = args[2] == 'remove' and -9000 or info.x
  local y = args[2] == 'remove' and -9000 or info.y
  local title = args[3]
  local lookLeft = args[4] == 'left'
  local lookAtPlayer = args[4] == 'auto'
  local female = args[5] == 'f'

  tfm.exec.addNPC(name, {
    x = x,
    y = y,
    title = title,
    look = look,
    female = female,
    lookLeft = lookLeft,
    lookAtPlayer = lookAtPlayer,
  })

  if not ranks.admin[player] then
    chatlogCmd(cmd, player, args, partyHost)
  end
end })

local mouseImages = {}
local function applyImage(player, img, factorY)
  if mouseImages[player] and mouseImages[player][0] then return img[2] or 0 end
  return tfm.exec.addImage(img[1], img[10] .. player, img[5], img[6], nil, img[3] * img[4] * img[9], img[4] * factorY, 0, img[7], 0.5 * img[3] * img[9], 0.5, false)
end

newCmd({ name = "image",
  fn = function(player, args, cmd)
  if args._len == 0 then
    if mouseImages[player] then
      mouseImages[player][0] = not mouseImages[player][0]
      if mouseImages[player][0] then
        if mouseImages[player][2] then
          tfm.exec.removeImage(mouseImages[player][2], false)
        end
        tfm.exec.killPlayer(player)
      end
    end
    return
  end

  if not ranks.admin[player] and not isPartyHost(player) then return end

  local playerName = args[1]
  local imageURL = args[2]
  local scale = tonumber(args[3]) or 1
  local offsetX = tonumber(args[4]) or 0
  local offsetY = tonumber(args[5]) or 0
  local opacity = tonumber(args[6]) or 1
  local invert = scale < 0 and -1 or 1
  local alwaysActive = false
  local imgTarget = '%'

  scale = math.abs(scale)

  if imageURL then
    alwaysActive = ranks.admin[player] and imageURL:sub(1, 1) == '*'
    imageURL = alwaysActive and imageURL:sub(2) or imageURL
    imgTarget = imageURL:sub(1, 1) == '$' and '$' or '%'
    imageURL = imgTarget == '$' and imageURL:sub(2) or imageURL
  end

  if not ranks.admin[player] then
    chatlogCmd(cmd, player, args, partyHost)
  end

  if not imageURL then
    return sendChatFmt('<r>Missing image parameter', player)
  end

  if playerName == "*" then
    if imageURL == "remove" then
      for _, img in next, mouseImages do
        if img[2] then
          tfm.exec.removeImage(img[2], false)
        end
      end
      mouseImages = {}
      return
    elseif imageURL then
      for name in next, in_room do	
        if mouseImages[name] and mouseImages[name][2] then
          tfm.exec.removeImage(mouseImages[name][2], false)
        end

        local img = {imageURL, nil, 1, scale, offsetX, offsetY, opacity, alwaysActive, invert, imgTarget}
        img[0] = mouseImages[name] and mouseImages[name][0]
        if alwaysActive or victory[name] then
          img[2] = applyImage(name, img, 1)
          if not img[2] then
            return translatedChatMessage("invalid_syntax", player)
          end
        end

        mouseImages[name] = img
        translatedChatMessage("new_image", name)
      end
      return
    end
  end

  if not playerName or not room.playerList[playerName] then
    return sendChatFmt('<r>Target player is not in the room', player)
  end

  if mouseImages[playerName] and mouseImages[playerName][2] then
    tfm.exec.removeImage(mouseImages[playerName][2], false)
  end

  if imageURL == "remove" then
    mouseImages[playerName] = nil
    return
  elseif not mouseImages[playerName] or mouseImages[playerName][1] ~= imageURL then
    translatedChatMessage("new_image", playerName)
  end

  local img = {imageURL, nil, 1, scale, offsetX, offsetY, opacity, alwaysActive, invert, imgTarget}
  img[0] = mouseImages[playerName] and mouseImages[playerName][0]
  if alwaysActive or victory[playerName] then
    img[2] = applyImage(playerName, img, 1)
    if not img[2] then
      return translatedChatMessage("invalid_syntax", player)
    end
  end
  mouseImages[playerName] = img
end })

onEvent("Keyboard", function(player, key, down)
  local img = mouseImages[player]

  if not img or img[0] or not img[8] and not victory[player] then return end
  if not (key == 0 or key == 2 or key == 3) then return end

  if img[2] then
    tfm.exec.removeImage(img[2], false)
  end

  if key == 2 then
    img[3] = 1
    img[2] = applyImage(player, img, 1)
  elseif key == 0 then
    img[3] = -1
    img[2] = applyImage(player, img, 1)
  elseif key == 3 then
    img[2] = applyImage(player, img, down and 0.5 or 1)
  end
end)

end
initParty()
end
