do
  local DEBUG_PRINT_PDATA_LOAD = false
  local DEBUG_PRINT_PDATA_SAVE = false
  local DEBUG_PRINT_FILE_LOAD = false
  local DEBUG_PRINT_FILE_SAVE = false

  local loader = string.match(({ pcall(0) })[2], "^(.-)%.")

  force_christmas_debug = true
  force_lemonade_debug = true
  force_stats_count_debug = true

  -- Room
  local isActuallyTribe = tfm.get.room.isTribeHouse
	tfm.get.room.uniquePlayers = 4
  tfm.get.room.isTribeHouse = false
  --tfm.get.room.debugLanguage = "tr"

  --{% require-file "scripts/debugui.lua" %}

  -- Event Hooks
  local hookEvent
  do
    local original, hook = {}, {}

    setmetatable(_G, {
      __index = function(tbl, key)
        if original[key] then
          return hook[key]
        end

        return rawget(tbl, key)
      end,
      __newindex = function(tbl, key, val)
        if hook[key] then
          original[key] = val
          return
        end

        return rawset(_G, key, val)
      end,
    })

    function hookEvent(name, func)
      hook[name] = function(...)
        return func(original[name], ...)
      end
    end
  end

  -- Tribe House Alternatives
  if tfm.exec.getPlayerSync() == nil and isActuallyTribe then
    tfm.exec.chatMessage = function(message, playerName)
      print(tostring(playerName) .. ' -- ' .. tostring(message))
    end

    local timers, timerCount = {}, 0

    system.newTimer = function(callback, time, loop, arg1, arg2, arg3, arg4)
      time = tonumber(time)
      if type(callback) ~= "function" or not time or time < 500 then
        error(debug.traceback())
        return
      end

      timerCount = 1 + timerCount
      timers[timerCount] = { callback, time, loop, arg1, arg2, arg3, arg4 }
      timers[timerCount][0] = os.time() + time
      return timerCount
    end

    system.removeTimer = function(timerId)
      if timerId then
        timers[timerId] = nil
      end
    end

    hookEvent('eventLoop', function(eventLoop, ...)
      local dead, count = {}, 0
      local now = os.time()

      for id, args in next, timers do
        if now >= args[0] then
          args[1](id, args[4], args[5], args[6], args[7])

          if args[3] then
            args[0] = now + args[2]
          else
            count = 1 + count
            dead[count] = id
          end
        end
      end

      for i=1, count do
        timers[dead[i]] = nil
      end

      eventLoop(...)
    end)

    -- supress warnings
    tfm.exec.setRoomMaxPlayers = function(number)
      print("tfm.exec.setRoomMaxPlayers(" .. tostring(number) .. ")")
    end

    -- supress warnings
    tfm.exec.getPlayerSync = function() return loader end
  end


  -- Utility Functions
  local function measureTime(str, threshold, func, ...)
    local t = os.time()
    func(...)
    local diff = os.time() - t
    if diff > threshold then
      print("# " .. str .. " took " .. diff .. " ms")
    end
  end

  local function printDebugData(data, header, ...)
    print(("<J>" .. tostring(header)):format(...))
    print(tostring(data):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('\000', '\\0'))
    print("<ROSE>==================")
  end


  -- Event Execution Time Log
  -- hookEvent('eventGameDataLoaded', function(original, data, id)
  --   measureTime("Executing eventGameDataLoaded:" .. id, 5, original, data, id)
  -- end)

  -- hookEvent('eventSavingFile', function(original, id, data)
  --   measureTime("Executing eventSavingFile:" .. id, 0, original, id, data)
  -- end)


  -- Player Data
	local pdata = {
    ["Tocutoeltuco#5522"] = [[{ "week_r": "12/10/2020", "kill": "0", "c": 9007, "killedby": "Lays#1146", "report": true, "tracki": 1, "playerid": 5419276, "badges": [ 0, 0, 0, 1, 1, 1, 1, 1 ], "settings": [ 0, 46, 1, 0, 1, 0, 0, 0, null ], "keys": [ 32, 0, 219, 81, 17, 0, 0, 0, 85, 0, 0, 0, 221 ], "killed": 1741305011082, "cpower": 3, "cc": 3005, "ec": [ 29, 0, 0, 3, 0, 2, 5, 0, 0, 0, 0, 0, 85 ], "week_c": 0, "coins": 10371, "room": "*#parkour4test", "banned": 0, "week": [ 15, 1765749600000 ], "cslen": [ 1, 1, 1, 2, 1, 2, 1, 0, 1 ], "cskins": [ 109, 222, 236, 76, 240, 164, 2001, 218, 237, 148 ], "skins": [ 59, 26, 12, 56, 203, 93, 126, 52, 158, 116, 5, 4, 3, 182, 85, 72, 97, 212, 104, 110, 51, 68, 94, 123, 50, 40, 54, 6, 32, 229, 214, 215, 2005, 2002, 2004, 2006, 2003 ], "v": 12, "claim": 1758642851080, "quests": [ { "id": 5, "pg": 0, "tg": 622 }, { "id": 3, "pg": 4, "tg": 7 }, { "pr": 7, "pg": 11, "tg": 40, "id": 6 }, { "id": 2, "pg": 136, "tg": 160 }, { "id": 3, "pg": 14, "tg": 37 }, { "id": 5, "pg": 0, "tg": 766 }, { "pr": 13, "pg": 83, "tg": 120, "id": 6 }, { "id": 1, "pg": 39, "tg": 120 } ], "lastsanction": 1764889392120, "commu": "en", "hour": {}, "tc": 6000, "hour_r": 1765925685536, "namecolor": 16777215, "langue": "en", "powers": [ 4, 2, 6, 7, 8, 5, 3 ], "bancount": 3, "powuse": [ 0, 0, 7, 10, 10, 99, 65 ], "bannedby": "Lays#1146", "hidden": true }]],
  }

	system.loadPlayerData = function(name)
    if DEBUG_PRINT_PDATA_LOAD then
      printDebugData(pdata[name], "Loading player data for %s", tostring(name))
    end

    if eventPlayerDataLoaded then
      system.newTimer(function()
        measureTime("Loading player data for " .. tostring(name), 5, function()
          local data = pdata[name] or pdata["Tocutoeltuco#5522"]
          eventPlayerDataLoaded(name, data)
        end)
      end, 500, false)
    end
	end

	system.savePlayerData = function(name, data)
    if DEBUG_PRINT_PDATA_SAVE then
      printDebugData(data, "Saving player data for %s", tostring(name))
    end

		pdata[name] = tostring(data)
	end


  -- Files
  local files = {}

  system.loadFile = function(id)
    id = tostring(id)

    if DEBUG_PRINT_FILE_LOAD then
      printDebugData(files[id], "Loading file %s", tostring(id))
    end

    if eventFileLoaded then
      system.newTimer(function()
        measureTime("Loading file " .. tostring(id), 5, function()
          eventFileLoaded(id, files[id])
        end)
      end, 500, false)
    end
  end

  system.saveFile = function(data, id)
    id = tostring(id)
    files[id] = data

    if DEBUG_PRINT_FILE_SAVE then
      printDebugData(files[id], "Saving file %s", tostring(id))
    end

    if eventFileSaved then
      system.newTimer(function()
        eventFileSaved(id)
      end, 500, false)
    end
  end


  -- Parkour Files
  {% require-package "tech/filemanager" %}
  {% require-file "modes/parkour/filemanagers.lua" %}

  local function saveFile(id, data)
    system.saveFile(filemanagers[tostring(id)]:dump(data), id)
  end

  {% require-file "scripts/file_init.lua" %}
  {% require-file "scripts/file_leaderboard.lua" %}
  {% require-file "scripts/file_sanction.lua" %}
  {% require-file "scripts/file_shop.lua" %}
  {% require-file "scripts/file_npc.lua" %}
end
