do
  local DEBUG_PRINTS = false

  local loader = string.match(({ pcall(0) })[2], "^(.-)%.")
  local ranks = {
    [loader] = 1,
  }
  local maps = { 4612890,4746775,5027504,5615419,5674149,5889600,5965494,6108521,6108646,6151153,6174675,6180642,6194607,6210970,6295010,6316456,6608954,6661142,6661151,6661155,6661169,6661172,6661182,6661185,6661188,6661190,6661191,6661212,6692082,6781318,7106881,7137341,7290120,7294514,7432833,7506432,7565716,7566459,7568359,7570693,7571727,7573465,7574000,7574622,7578163,7579000,7582006,7589934,7594671,7597298,7597820,7598149,7598208,7598750,7598784,7606060,7607788,7618265,7623076,7623375,7623689,7623883,7626311,7630792,7631757,7633369,7633753,7634454,7634715,7634990,7635668,7635730,7636035,7636491,7636940,7636962,7637709,7637767,7638012,7638026,7640633,7641381,7641758,7643522,7644848,7645085,7645936,7645958,7646182,7646959,7647260,7647393,7647505,7647559,7647837,7647840,7648023,7648073,7648155,7648256,7648542,7648748,7648947,7651282,7651719,7652281,7652516,7652530,7652716,7652736,7652941,7652979,7653176,7653393,7653641,7654379,7654810,7655829,7656250,7656463,7656993,7657088,7657106,7657455,7657473,7657625,7657685,7658097,7658974,7659373,7659415,7659528,7659573,7659581,7659600,7659612,7659787,7660213,7660233,7660237,7661141,7661543,7661627,7661677,7661805,7661883,7662933,7663149,7664028,7664203,7664290,7664365,7664860,7664952,7665143,7666146,7666289,7666518,7666729,7666858,7666879,7666902,7666977,7667326,7667333,7667831,7667983,7668136,7668588,7668998,7669038,7669508,7669793,7669842,7671066,7671525,7672093,7672353,7672411,7673095,7673231,7673383,7673545,7673916,7675203,7676096,7677024,7677072,7677254,7677727,7677975,7678002,7678044,7678336,7678353,7678377,7678622,7678676,7678709,7679559,7679634,7679804,7680753,7680795,7680817,7681166,7681171,7681284,7681355,7682202,7682428,7682554,7682753,7683247,7683429,7683760,7683962,7684006,7684129,7684247,7684277,7685100,7686820,7686886,7687674,7688089,7688209,7688273,7689043,7689092,7689226,7689498,7690494,7690816,7690831,7690882,7690892,7690914,7691262,7691732,7692171,7692281,7692330,7692589,7692596,7692679,7692753,7693452,7693537,7693560,7693754,7693792,7694292,7695521,7697370,7697371,7697372,7698515,7698612,7698960,7699228,7699881,7699969,7700050,7700293,7700719,7700738,7700991,7701083,7701766,7702446,7702503,7702730,7703480,7706303,7707267,7707500,7709862,7711727,7711771,7713014,7713969,7715135,7715385,7716199,7718602,7719504,7719604,7720358,7722630,7723570,7723659,7724468,7727211,7727850,7729196,7731385,7732454,7733177,7734204,7734306,7735504,7736844,7742839,7749506,7769456,7783873,7795599,7804070,7821715,7857950,7864773 }
  local maps2 = { 6163393,6534290,6650429,6661186,6800745,6807607,6809154,7158034,7171137,7197746,7197833,7308569,7322660,7398189,7496109,7571737,7573427,7577606,7589819,7590861,7623232,7631751,7632451,7633661,7634376,7635335,7635369,7636088,7637382,7638067,7639005,7639520,7651329,7659247,7680160,7681400,7683277,7686626,7687039,7689470,7692090,7693740,7698560,7705686,7707661,7713073,7715830,7717601,7720264,7724450,7732368,7732462,7734970,7739560,7740628,7741031,7746618,7746824,7748538,7751288,7753648,7755029,7768553,7783065,7795409,7796140,7800612,7824529,7828750,7836144,7837745,7839339,7871961,7873197,7920730,7941079,7942934,7944603,7944761,7947150,873188,898704,917344 }
  local maps3  = { 7568533,7569215,7613775,7689580,7719521,7751927,7792890,7862381,7862384,7871955,7922358,7942228 }

  -- Room
	tfm.get.room.name = "*#parkour0test"
	tfm.get.room.uniquePlayers = 4
  tfm.get.room.isTribeHouse = false
  --tfm.get.room.debugLanguage = "tr"


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

	saveFile(40, {
		ranks = ranks,
		maps = maps,
		maps2 = maps2,
		maps3 = maps3,
	})

	saveFile(21, {
		ranking = {},
		weekly = {
      ranks = {},
      ts = "1/1/2020",
      wl = {}
    },
	})

	saveFile(43, {
    mods = { 'Lays#1146' },
		sanction = {
      ["1"] = {
        timestamp = 0,
        time = os.time() + 1000 * 60 * 60 * 24,
        info = 0,
        level = 1,
      }
    },
	})
end
