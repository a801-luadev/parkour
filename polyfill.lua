do
  local DEBUG_PRINTS = true

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


  -- Chat Message Alternative
  if tfm.exec.getPlayerSync() == nil then
    tfm.exec.chatMessage = function(message, playerName)
      print(tostring(playerName) .. ' -- ' .. tostring(message))
    end
  end


  -- Player Data
	local pdata = {}

	system.loadPlayerData = function(name)
    if DEBUG_PRINTS then
      print("<J>Loading player data for " .. name)
      print(tostring(pdata[name] or ""):gsub('&', '&amp;'):gsub('<', '&lt;'))
      print("<ROSE>==================")
    end

		eventPlayerDataLoaded(name, pdata[name] or "")
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
      eventFileLoaded(id, files[id])
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
      eventFileSaved(id)
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
