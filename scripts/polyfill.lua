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
    ["Tocutoeltuco#5522"] = [[{"v":7,"hour_r":1713634097913,"coins":200000,"killed":0,"cc":0,"cskins":[164,212,703,2840,309],"skins":{"2838":1,"1":1,"2855":1,"333":1,"324":1,"46":1,"314":1,"319":1,"125":1,"2805":1,"336":1,"327":1,"325":1,"317":1,"158":1,"147":1,"246":1,"28":1,"2807":1,"142":1,"358":1,"229":1,"164":1,"347":1,"161":1,"261":1,"126":1,"707":1,"361":1,"355":1,"150":1,"253":1,"351":1,"251":1,"203":1,"140":1,"2825":1,"313":1,"703":1,"2823":1,"709":1,"2859":1,"109":1,"165":1,"706":1,"2842":1,"350":1,"713":1,"702":1,"708":1,"162":1,"309":1,"230":1,"2844":1,"360":1,"704":1,"260":1,"701":1,"2801":1,"263":1,"157":1,"257":1,"2806":1,"256":1,"705":1,"212":1,"2840":1,"219":1,"2820":1,"2":1,"222":1,"712":1,"7":1,"2824":1,"2841":1,"718":1,"2857":1,"138":1,"2827":1,"244":1,"241":1,"722":1,"710":1,"154":1,"116":1,"228":1,"716":1,"720":1,"128":1,"717":1},"bancount":0,"week":[0,"14/04/2024"],"report":true,"settings":[1,46,1,1,1,1,1,1,null],"hour":{},"c":6000,"keys":{},"badges":[0,1,0,0,0,0],"kill":0,"quests":[{"id":3,"pg":0,"tg":7},{"id":4,"pg":0,"tg":60},{"id":5,"pg":0,"tg":233},{"id":2,"pg":0,"tg":170},{"id":2,"pg":0,"tg":710},{"id":4,"pg":0,"tg":40},{"id":1,"pg":0,"tg":155},{"id":5,"pg":0,"tg":325}],"room":"*#parkour0test","commu":"en","playerid":5419276,"tc":0}]],
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
