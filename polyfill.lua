do
  local DEBUG_PRINTS = false

  local loader = string.match(({ pcall(0) })[2], "^(.-)%.")
  local ranks = {
    [loader] = 1,
  }
  local maps = { 4612890, 7631757, 5027504, 7673383 }
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
    ["Tocutoeltuco#5522"] = [[{"v":7,"hour_r":1713634097913,"coins":892299,"killed":0,"cc":0,"cskins":[164,212,703,2840,309],"skins":{"2838":1,"1":1,"2855":1,"333":1,"324":1,"46":1,"314":1,"319":1,"125":1,"2805":1,"336":1,"327":1,"325":1,"317":1,"158":1,"147":1,"246":1,"28":1,"2807":1,"142":1,"358":1,"229":1,"164":1,"347":1,"161":1,"261":1,"126":1,"707":1,"361":1,"355":1,"150":1,"253":1,"351":1,"251":1,"203":1,"140":1,"2825":1,"313":1,"703":1,"2823":1,"709":1,"2859":1,"109":1,"165":1,"706":1,"2842":1,"350":1,"713":1,"702":1,"708":1,"162":1,"309":1,"230":1,"2844":1,"360":1,"704":1,"260":1,"701":1,"2801":1,"263":1,"157":1,"257":1,"2806":1,"256":1,"705":1,"212":1,"2840":1,"219":1,"2820":1,"2":1,"222":1,"712":1,"7":1,"2824":1,"2841":1,"718":1,"2857":1,"138":1,"2827":1,"244":1,"241":1,"722":1,"710":1,"154":1,"116":1,"228":1,"716":1,"720":1,"128":1,"717":1},"bancount":0,"week":[0,"14/04/2024"],"report":true,"settings":[1,46,1,1,1,1,1,0,null],"hour":{},"c":0,"keys":{},"badges":[0,1,0,0,0,0],"kill":0,"quests":[{"id":3,"pg":0,"tg":7},{"id":4,"pg":0,"tg":60},{"id":5,"pg":0,"tg":233},{"id":2,"pg":0,"tg":170},{"id":2,"pg":0,"tg":710},{"id":4,"pg":0,"tg":40},{"id":1,"pg":0,"tg":155},{"id":5,"pg":0,"tg":325}],"room":"*#parkour0test","commu":"en","playerid":5419276,"tc":0}]]
  }

	system.loadPlayerData = function(name)
    if DEBUG_PRINTS then
      print("<J>Loading player data for " .. name)
      print(tostring(pdata[name] or ""):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

    if eventPlayerDataLoaded then
      system.newTimer(function()
        eventPlayerDataLoaded(name, pdata[name] or pdata["Tocutoeltuco#5522"])
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
