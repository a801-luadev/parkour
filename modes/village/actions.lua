local npc_shop = {}

local function parseSellerNpc(npc, reward)
  local coin_type = tonumber(npc.param[1])
  local price = tonumber(npc.param[2])
  local amount = tonumber(npc.param[3])
  local message, left_image, right_image = npc.param[4], npc.param[5], npc.param[6]

  local shop = {
    name = npc.name,
    message = message,
    left_disabled = true,
    left_image = left_image,
    left_amount = price,
    right_amount = amount,
    right_button = "buy",
    right_image = right_image,
    coin_type = coin_type,
    reward = reward,
  }

  if reward == 'power' then
    shop.power_id = tonumber(npc.param[7])
  elseif reward == 'badge' then
    shop.badge_group = tonumber(npc.param[7])
    shop.badge_index = tonumber(npc.param[8])
  elseif reward == 'skin' then
    shop.skin_id = tonumber(npc.param[7])
  end

  return shop
end

function npc_actions.sell_power(player, npc)
  local shop = npc_shop[npc.name]
  if not shop then
    shop = parseSellerNpc(npc, 'power')
    npc_shop[npc.name] = shop
  end
  NPCInterface:show(player, shop)
end

function npc_actions.sell_badge(player, npc)
  local shop = npc_shop[npc.name]
  if not shop then
    shop = parseSellerNpc(npc, 'badge')
    npc_shop[npc.name] = shop
  end
  NPCInterface:show(player, shop)
end

function npc_actions.sell_skin(player, npc)
  local shop = npc_shop[npc.name]
  if not shop then
    shop = parseSellerNpc(npc, 'skin')
    npc_shop[npc.name] = shop
  end
  NPCInterface:show(player, shop)
end

function npc_actions.multishop(player, npc)
  local shop = npc_shop[npc.name]
  if not shop then
    local skin_id, skin, currency
    local message = npc.param[1]
    local first = {}

    shop = first

    for i=2, #npc.param do
      skin_id = tonumber(npc.param[i])
      skin = shop_skins[skin_id]

      if skin then
        currency = shop_currencies[skin.currency]

        if currency then
          shop.next = {
            name = npc.name,
            message = message,
            left_disabled = true,
            left_image = currency.shop_img or currency.img or currency.coin_img,
            left_amount = skin.price,
            right_amount = 1,
            right_button = "buy",
            right_image = skin.shop_img or skin.img,
            coin_type = currency.id,
            reward = "skin",
            skin_id = skin_id,
            prev = shop,
          }
          shop = shop.next
        end
      end
    end

    if not first.next then return end

    if first.next == shop then
      first = shop
      shop.prev = nil
      shop.next = nil
    else
      shop.next = first.next
      first.next.prev = shop
      first = shop
    end

    npc_shop[npc.name] = first
  end
  NPCInterface:show(player, shop)
end

function npc_actions.chat(player, npc)
  if not checkCooldown(player, "npc_" .. npc.name, 5000) then return end
  local msg_type = npc.param[1]
  local key = npc.param[2]
  if msg_type == 'random' then
    local first = npc.param[3]
    local last = npc.param[4]
    key = key .. '_' .. math.random(first, last)
  end
  translatedChatMessage(key, player)
end

onEvent("TradeNPC", function(player, shop)
  local file = players_file[player]
  if not shop or not file then return end

  if shop.coin_type == 0 then
    if file.coins < shop.left_amount then
      NPCInterface:update(player, shop, "insufficient_coins")
      return
    end
  else
    if file:getItemAmount(shop.coin_type, 0) < shop.left_amount then
      NPCInterface:update(player, shop, "insufficient_event_coins")
      return
    end
  end

  if shop.reward == 'power' then
    if not file:updateItem(shop.power_id, 8, shop.right_amount) then return end
    translatedChatMessage("npc_thanks", player)
  elseif shop.reward == 'badge' then
    if file.badges[shop.badge_group] == shop.badge_index then
      if NPCInterface.open[player] then
        NPCInterface:update(player, shop, "npc_already_have")
      end
      return translatedChatMessage("npc_already_have", player)
    end
    file.badges[shop.badge_group] = shop.badge_index
    if shop.badge_index > 0 then
      NewBadgeInterface:show(player, shop.badge_group, shop.badge_index)
    end
  elseif shop.reward == 'skin' then
    if file:findItem(shop.skin_id) then
      if NPCInterface.open[player] then
        NPCInterface:update(player, shop, "npc_already_have")
      end
      return translatedChatMessage("npc_already_have", player)
    end
    if not rewardSkin(player, shop.skin_id) then return end
  else
    return
  end

  if shop.coin_type == 0 then
    file.coins = file.coins - shop.left_amount
  else
    file:updateItem(shop.coin_type, 0, -shop.left_amount)
  end

  savePlayerData(player)

  if NPCInterface.open[player] then
    NPCInterface:update(player, shop, "npc_thanks")
  end
end)
