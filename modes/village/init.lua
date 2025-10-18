tfm.exec.newGame = function() end

onEvent("NewPlayer", function(player, init)
  victory[player] = 0
  setNameColor(player)
end)

onEvent("Loop", function(time, remaining)
  if remaining < 10000 then
    tfm.exec.setGameTime(3600)
  end
end)

onEvent("GameStart", function()
  cooldownMultiplier = 2
  room_max_players = 200
  tfm.exec.setRoomMaxPlayers(room_max_players)
end)
