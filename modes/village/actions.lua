local npc_shop = {}

function npc_actions.sell_power(player, npc)
  local shop = npc_shop[npc.name]
  if not shop then
    local price = tonumber(npc.param[2])
    local amount = tonumber(npc.param[3])
    local power_id = tonumber(npc.param[1])
    if not price or not amount or not power_id or not npc.param[4] then
      return
    end
    shop = {
      name = npc.name,
      button = "buy",
      message = "npc_sell_power",
      left_disabled = true,
      left_image = "18b29f6977c.png",
      left_amount = price,
      right_amount = amount,
      right_button = "buy",
      right_image = npc.param[4],
      power_id = power_id,
    }
    npc_shop[npc.name] = shop
  end
  NPCInterface:show(player, shop)
end

onEvent("TradeNPC", function(player, npc)
  local shop = npc_shop[npc]
  local file = players_file[player]
  if not shop or not file then return end

  if file.coins >= shop.left_amount then
    if not file:updateItem(shop.power_id, 8, shop.right_amount) then
      return
    end

    file.coins = file.coins - shop.left_amount

    savePlayerData(player)

    if NPCInterface.open[player] then
      NPCInterface:remove(player)
    end
  else
    NPCInterface:update(player, shop, "insufficient_coins")
  end
end)
