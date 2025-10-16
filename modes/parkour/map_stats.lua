do
  local PLAYER_TRESHOLD = 8
  local RATIO_TRESHOLD = 0.5

  local stats, views

  onEvent("NewGame", function()
    if stats and views and stats._len > 0 and stats._valid >= (RATIO_TRESHOLD * stats._len) then
      local view_count = 0

      for _ in next, views do
        view_count = view_count + 1
      end

      local freqgroups = {}
      local index
      local valid

      for i=1, stats._len do
        index = math.floor(stats[i][1] / 10) + 1
        index = math.min(index, 31) -- 5min+

        -- total time, freq, total completions
        freqgroups[index] = freqgroups[index] or {0, 0, 0}
        freqgroups[index][1] = freqgroups[index][1] + stats[i][1]
        freqgroups[index][2] = freqgroups[index][2] + stats[i][2]
        freqgroups[index][3] = freqgroups[index][3] + 1
      end

      local to_send, count = {}, 0

      for i=1, 31 do
        if freqgroups[i] then
          -- convert to average values
          to_send[count + 1] = math.floor(freqgroups[i][1] / freqgroups[i][3])
          to_send[count + 2] = math.floor(freqgroups[i][2] / freqgroups[i][3])
          to_send[count + 3] = freqgroups[i][3]
          count = count + 3
        end
      end

			sendPacket(
				"common",
				packets.rooms.map_stats,
				room.shortName .. "\000" ..
				stats.code .. "\000" ..
				view_count .. "\000" ..
        table.concat(to_send, "\000")
			)
    end

    stats, views = nil, nil

    if records_admins or submode == "smol" or tfm_mode == "village" then return end
    if not room.xmlMapInfo or (room.xmlMapInfo.permCode ~= 41 and room.xmlMapInfo.permCode ~= 42) then return end

    stats = { code = room.currentMap, _len = 0, _valid = 0 }
    views = {}

    for player in next, in_room do
      views[player] = true
    end
  end)

  onEvent("NewPlayer", function(player)
    if not views then return end

    views[player] = true
  end)

  onEvent("PlayerCompleted", function(player, info, file)
    if not stats then return end

    local time = (os.time() - (times.generated[player] or times.map_start)) / 1000

    stats._len = stats._len + 1
    stats[stats._len] = { time, file.c }

    if doStatsCount() and room.uniquePlayers >= PLAYER_TRESHOLD then
      stats._valid = stats._valid + 1
    end
  end)
end
