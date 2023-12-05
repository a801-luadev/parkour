do
  local DEBUG_PRINTS = false

  local loader = string.match(({ pcall(0) })[2], "^(.-)%.")
  local ranks = {
    [loader] = 1,
  }
  local maps = { 7941862, 7631757, 7646210, 7673383 }
  local lowmaps = { 7692171, 7690882, 7692589 }

  -- Room
	tfm.get.room.name = "*#parkour0test"
	tfm.get.room.uniquePlayers = 4
  tfm.get.room.isTribeHouse = false


  -- Tribe House Alternatives
  if tfm.exec.getPlayerSync() == nil then
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

    local eventLoop

    local function loop(...)
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
    end

    setmetatable(_G, {
      __index = function(tbl, key)
        if key == 'eventLoop' then
          return loop
        end

        return rawget(tbl, key)
      end,
      __newindex = function(tbl, key, val)
        if key == 'eventLoop' then
          eventLoop = val
          return
        end

        return rawset(_G, key, val)
      end,
    })
  end


  -- Player Data
	local pdata = {
    ["Tocutoeltuco#5522"] = [[{aaaaaaaaaaaaaaaa}]]
  }

	system.loadPlayerData = function(name)
    if DEBUG_PRINTS then
      print("<J>Loading player data for " .. name)
      print(tostring(pdata[name] or ""):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

    if eventPlayerDataLoaded then
      system.newTimer(function()
        eventPlayerDataLoaded(name, pdata[name] or "")
      end, 500, false)
    end
	end

	system.savePlayerData = function(name, data)
    if DEBUG_PRINTS then
      print("<J>Savig player data for " .. name)
      print(tostring(data):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

		pdata[name] = tostring(data)
	end


  -- Files
  local files = {}

  system.loadFile = function(id)
    id = tostring(id)

    if DEBUG_PRINTS then
      print("<J>Loading file-" .. id)
      print(tostring(files[id]):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

    if eventFileLoaded then
      system.newTimer(function()
        eventFileLoaded(id, files[id])
      end, 500, false)
    end
  end

  system.saveFile = function(data, id)
    id = tostring(id)
    files[id] = data

    if DEBUG_PRINTS then
      print("<J>Saving file-" .. id)
      print(tostring(files[id]):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

    if eventFileSaved then
      system.newTimer(function()
        eventFileSaved(id)
      end, 500, false)
    end
  end


  -- Parkour Files
  {% require-file "tech/filemanager/init.lua" %}
  {% require-file "modes/parkour/sanctionfilemanager.lua" %}
  {% require-file "modes/parkour/filemanagers.lua" %}

  local function saveFile(id, data)
    system.saveFile(filemanagers[tostring(id)]:dump(data), id)
  end

	saveFile(20, {
		maps = maps,
		ranks = ranks,
		chats = {
			mod = "",
			mapper = "",
		},
	})

	saveFile(21, {
		ranking = {},
		weekly = {
      ranks = {},
      ts = "1/1/2020",
      wl = {}
    },
	})

	saveFile(23, {
		lowmaps = lowmaps,
		sanction = {
      ["1"] = {
        timestamp = 0,
        time = os.time() + 1000 * 60 * 60 * 24,
        info = "-",
        level = 1,
      }
    },
	})
end
