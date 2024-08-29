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
  --[[ File tech/filemanager/init.lua ]]--
  local FileManager
  do
  	FileManager = {}
  	FileManager.__index = FileManager
  
  	local string_byte = string.byte
  	local string_char = string.char
  	local string_sub = string.sub
  
  	local parsers
  	parsers = {
  		["dictionary"] = function(str, obj, idx)
  			local result = {}
  			if obj.length then -- premade dict!
  				local child
  				for i = 1, obj.length do
  					child = obj.map[i]
  					result[child.name], idx = parsers[child.type](str, child, idx)
  				end
  			else
  				local length
  				length, idx = parsers.number(str, nil, idx)
  
  				local strparser = parsers.string
  				local parser, child = parsers[obj.objects.type], obj.objects
  				local name
  				for i = 1, length do
  					name, idx = strparser(str, nil, idx)
  					result[name], idx = parser(str, child, idx)
  				end
  			end
  			return result, idx
  		end,
  
  		["array"] = function(str, obj, idx)
  			local result = {}
  			if obj.length then -- premade map!
  				local child
  				for i = 1, obj.length do
  					child = obj.map[i]
  					result[i], idx = parsers[child.type](str, child, idx)
  				end
  			else
  				local length
  				length, idx = parsers.number(str, nil, idx)
  
  				local parser, child = parsers[obj.objects.type], obj.objects
  				for i = 1, length do
  					result[i], idx = parser(str, child, idx)
  				end
  			end
  			return result, idx
  		end,
  
  		["boolean"] = function(str, obj, idx)
  			return string_sub(str, idx, idx) == "1", idx + 1
  		end,
  
  		["string"] = function(str, obj, idx)
  			local length = obj and obj.length
  			if not length then
  				length, idx = parsers.number(str, nil, idx)
  			end
  
  			return string_sub(str, idx, idx - 1 + length), idx + length
  		end,
  
  		["number"] = function(str, obj, idx)
  			local length = string_byte(str, idx)
  			return tonumber(string_sub(str, idx + 1, idx + length)), idx + 1 + length
  		end
  	}
  
  	local writers
  	writers = {
  		["dictionary"] = function(data, obj, str)
  			if obj.length then -- premade map
  				local child
  				for i = 1, obj.length do
  					child = obj.map[i]
  					str = writers[child.type](data[child.name], child, str)
  				end
  			else
  				local _str = ""
  				local length = 0
  
  				local strwriter = writers.string
  				local writer, child = writers[obj.objects.type], obj.objects
  				for key, value in next, data do
  					_str = strwriter(key, nil, _str)
  					_str = writer(value, child, _str)
  					length = length + 1
  				end
  
  				str = writers.number(length, nil, str) .. _str
  			end
  			return str
  		end,
  
  		["array"] = function(data, obj, str)
  			if obj.length then -- premade map
  				local child
  				for i = 1, obj.length do
  					child = obj.map[i]
  					str = writers[child.type](data[i], child, str)
  				end
  			else
  				local length = #data
  				str = writers.number(length, nil, str)
  
  				local writer, child = writers[obj.objects.type], obj.objects
  				for i = 1, #data do
  					str = writer(data[i], child, str)
  				end
  			end
  			return str
  		end,
  
  		["boolean"] = function(data, obj, str)
  			return str .. (data and "1" or "0")
  		end,
  
  		["string"] = function(data, obj, str)
  			if not (obj and obj.length) then
  				str = writers.number(#data, nil, str)
  			end
  			return str .. data
  		end,
  
  		["number"] = function(data, obj, str)
  			local encoded = tostring(data)
  			return str .. string_char(#encoded) .. encoded
  		end
  	}
  
  	local prepare_object
  	function prepare_object(obj)
  		assert(obj.type, "every object must have a type")
  
  		if obj.type == "dictionary" then
  			assert(obj.objects or obj.map, "a dictionary must have either a premade map or an objects list")
  			assert(not (obj.objects and obj.map), "a dictionary can't have both a premade map and an objects list")
  			assert(not obj.length, "a dictionary can't have the length variable set to it")
  
  			if obj.map then
  				obj.length = #obj.map
  
  				local child
  				for index = 1, obj.length do
  					child = obj.map[index]
  					assert(child.name, "every object in the map of a dictionary must have a name")
  
  					prepare_object(child)
  				end
  			else
  				assert(not obj.objects.name, "the object type in a dynamic dictionary can't have a premade name")
  
  				prepare_object(obj.objects)
  			end
  
  		elseif obj.type == "array" then
  			assert(obj.objects or obj.map, "an array must have either a premade map or an objects list")
  			assert(not (obj.objects and obj.map), "an array can't have both a premade map and an objects list")
  			assert(not obj.length, "an array can't have the length variable set to it")
  
  			if obj.map then
  				obj.length = #obj.map
  
  				local child
  				for index = 1, obj.length do
  					prepare_object(obj.map[index])
  				end
  			else
  				prepare_object(obj.objects)
  			end
  
  		elseif obj.type == "boolean" then
  			-- nothing
  
  		elseif obj.type == "string" then
  			if obj.length then
  				assert(type(obj.length) == "number", "length attribute of a string must be either nil or a number")
  			end
  
  		elseif obj.type == "number" then
  			-- nothing
  
  		else
  			error("unknown object type: '" .. obj.type .. "'")
  		end
  	end
  
  	local validity_checks
  	function validity_checks(data, obj)
  		local data_type = type(data)
  
  		if obj.type == "dictionary" then
  			assert(data_type == "table", "object must be a table in order to be casted to a dictionary")
  			if obj.length then
  				local length = 0
  
  				local valid
  				for key, value in next, data do
  					valid = false
  					length = length + 1
  					for i = 1, obj.length do
  						if obj.map[i].name == key then
  							valid = true
  							validity_checks(value, obj.map[i])
  							break
  						end
  					end
  					assert(valid, "table must have the same keys as the premade dictionary map")
  				end
  
  				assert(length == obj.length, "table must have the same length as the premade dictionary map")
  			else
  				local object = obj.objects
  				for key, value in next, data do
  					assert(type(key) == "string", "table indexes must be strings in order to be casted to a dynamic dictionary")
  					validity_checks(value, object)
  				end
  			end
  
  		elseif obj.type == "array" then
  			assert(data_type == "table", "object must be a table in order to be casted to a array")
  			if obj.length then
  				assert(#data == obj.length, "table must have the same length as the premade array map")
  
  				for i = 1, #data do
  					validity_checks(data[i], obj.map[i])
  				end
  			else
  				local object = obj.objects
  				for i = 1, #data do
  					validity_checks(data[i], object)
  				end
  			end
  
  		elseif obj.type == "boolean" then
  			-- no specific type needed
  
  		elseif obj.type == "string" then
  			assert(data_type == "string", "object must be a string in order to be written as one")
  			if obj.length then
  				assert(#data == obj.length, "string must have the same length as the allocated for the string")
  			end
  
  		elseif obj.type == "number" then
  			assert(data_type == "number", "object must be a number in order to be written as one")
  		end
  	end
  
  	function FileManager.new(struct)
  		return setmetatable({
  			ready = false,
  			struct = struct,
  			validity = true
  		}, FileManager)
  	end
  
  	function FileManager:disableValidityChecks()
  		self.validity = false
  		return self
  	end
  
  	function FileManager:prepare()
  		prepare_object(self.struct)
  		self.ready = true
  		return self
  	end
  
  	function FileManager:load(string)
  		assert(self.ready, "FileManager needs to be prepared before using it")
  		return parsers[self.struct.type](string, self.struct, 1)
  	end
  
  	function FileManager:check(data)
  		validity_checks(data, self.struct)
  		return self
  	end
  
  	function FileManager:dump(data)
  		assert(self.ready, "FileManager needs to be prepared before using it")
  
  		if self.validity then
  			self:check(data)
  		end
  
  		return writers[self.struct.type](data, self.struct, "")
  	end
  end
  --[[ End of file tech/filemanager/init.lua ]]--
  --[[ File modes/parkour/sanctionfilemanager.lua ]]--
  local function string_split(str, deli)
      local parts, len = {}, 0
      for part in str:gmatch('[^'..deli..']+') do
          len = len + 1
          parts[len] = part
      end
      return parts
  end
  
  local SanctionFileManager = {
      lastupdate = "",
      lastdata = nil,
  
      load = function(self, str)
          local data = string_split(str, "\1")
  
          if self.lastupdate == data[1] then
              return self.lastdata
          end
  
          local lowmaps = string_split(data[2], "\2")
          local sanctionList = string_split(data[3], "\2")
  
          for i=1, #lowmaps do
              lowmaps[i] = tonumber(lowmaps[i])
          end
  
          local sanctionDict = {}
          local sanction
  
          for i=1, #sanctionList do
              sanction = string_split(sanctionList[i], "\3")
              sanctionDict[sanction[1]] = {
                  timestamp = tonumber(sanction[2]),
                  time = tonumber(sanction[3]),
                  info = sanction[4] or "UNKNOWN",
                  level = tonumber(sanction[5]),
              }
          end
  
          self.lastupdate = data[1]
          self.lastdata = {
              lowmaps = lowmaps,
              sanction = sanctionDict,
          }
  
          return self.lastdata
      end,
  
      dump = function(self, data)
          local lowmaps = table.concat(data.lowmaps, "\2")
          local sanctionList, len = {}, 0
  
          for name, sanction in next, data.sanction do
              len = len + 1
              sanctionList[len] = table.concat({
                  name,
                  sanction.timestamp,
                  sanction.time,
                  sanction.info,
                  sanction.level,
              }, "\3")
          end
  
          return table.concat({ os.time(), lowmaps, table.concat(sanctionList, "\2") }, "\1")
      end,
  }
  --[[ End of file modes/parkour/sanctionfilemanager.lua ]]--
  --[[ File modes/parkour/filemanagers.lua ]]--
  local filemanagers = {
  	["20"] = FileManager.new({
  		type = "dictionary",
  		map = {
  			{
  				name = "maps",
  				type = "array",
  				objects = {
  					type = "number"
  				}
  			},
  			{
  				name = "ranks",
  				type = "dictionary",
  				objects = {
  					type = "number"
  				}
  			},
  			-- commented because the file is missing migration
  			-- {
  			-- 	name = "map_polls",
  			-- 	type = "array",
  			-- 	objects = {
  			-- 		type = "number"
  			-- 	}
  			-- },
  			{
  				name = "chats",
  				type = "dictionary",
  				map = {
  					{
  						name = "mod",
  						type = "string",
  						length = 10
  					},
  					{
  						name = "mapper",
  						type = "string",
  						length = 10
  					}
  				}
  			}
  		}
  	}):disableValidityChecks():prepare(),
  
  	["21"] = FileManager.new({
  		type = "dictionary",
  		map = {
  			{
  				name = "ranking",
  				type = "array",
  				objects = {
  					type = "array",
  					map = {
  						{
  							type = "number"
  						},
  						{
  							type = "string",
  						},
  						{
  							type = "number"
  						},
  						{
  							type = "string",
  							length = 2
  						}
  					}
  				}
  			},
  			{
  				name = "weekly",
  				type = "dictionary",
  				map = {
  					{
  						name = "ranks",
  						type = "array",
  						objects = {
  							type = "array",
  							map = {
  								{
  									type = "number"
  								},
  								{
  									type = "string",
  								},
  								{
  									type = "number"
  								},
  								{
  									type = "string",
  									length = 2
  								}
  							}
  						}
  					},
  					{
  						name = "ts",
  						type = "string"
  					},
  					{
  						name = "wl",
  						type = "dictionary",
  						objects = {
  							type= "number"
  						}
  					}
  				}
  			}
  		}
  	}):disableValidityChecks():prepare(),
  
  	["23"] = SanctionFileManager,
  }
  --[[ End of file modes/parkour/filemanagers.lua ]]--

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
--
-- Parkour v2
-- MIT License

-- Copyright (c) 2020 Iván Gabriel (Tocutoeltuco)

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--


math.randomseed(os.time())
local data_version = 7
local room = tfm.get.room
local links = {
	donation = "https://a801-luadev.github.io/?redirect=parkour",
	github = "https://github.com/a801-luadev/parkour",
	discord = "https://discord.gg/QRCjyVyg7B",
	maps = "https://atelier801.com/topic?f=6&t=887284",
	records = "https://tfmrecords.com/",
	forum = "https://atelier801.com/topic?f=6&t=892086",
	mod_apps = "https://bit.ly/parkourmods",
	mapper_event = "https://atelier801.com/topic?f=6&t=898915&p=1#m2",
}

local starting = string.sub(room.name, 1, 2)

local is_tribe = starting == "*\003"
local tribe, module_name, submode
local flags = ""

if is_tribe then
	tribe = string.sub(room.name, 3)
end

room.lowerName = string.lower(room.name)
room.shortName = string.gsub(room.name, "%-?#parkour", "", 1)

local function enlargeName(name)
	if string.sub(name, 1, 1) == "*" then
		return "*#parkour" .. string.sub(name, 2)
	else
		return string.sub(name, 1, 2) .. "-#parkour" .. string.sub(name, 3)
	end
end

local function generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomString = ""
    
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        randomString = randomString .. string.sub(chars, randomIndex, randomIndex)
    end
    
    return randomString
end

do
	local savePlayerData = system.savePlayerData
	system.savePlayerData = function(playerName, ...)
		if not playerName then return end
		if tostring(playerName):sub(1, 1) == '*' then return end
		return savePlayerData(playerName, ...)
	end
end

do
	room.moduleMaxPlayers = 50
	local setRoomMaxPlayers = tfm.exec.setRoomMaxPlayers
	function tfm.exec.setRoomMaxPlayers(maxPlayers)
		local ret = setRoomMaxPlayers(maxPlayers)
		room.moduleMaxPlayers = room.maxPlayers
		return ret
	end
end

--[[ Package translations ]]--
--[[ File translations/init.lua ]]--
local translations
translations = setmetatable({}, {
	__index = function()
		return translations.en
	end
})
translations.en = {}
--[[ End of file translations/init.lua ]]--
--[[ End of package translations ]]--
--[[ Package global ]]--
--[[ Package tech/json ]]--
--[[ File tech/json/init.lua ]]--
--
-- json.lua
--
-- Copyright (c) 2019 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-- NOTE: This is a slightly modified version of the script you will find here:
-- https://github.com/rxi/json.lua
-- It has been modified so it uses less runtime, by making the next functions
-- accessible via a single variable and by disabling some encoding/decoding
-- checks. It is not recommended to use this version if you're not 100% sure your
-- data is totally valid.

local string_format = string.format
local string_byte = string.byte
local table_concat = table.concat
local string_gsub = string.gsub
local string_sub = string.sub
local string_find = string.find
local string_char = string.char
local math_floor = math.floor

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------


local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in next, escape_char_map do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return escape_char_map[c] or string_format("\\u%04x", string_byte(c))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val)--, stack)
  local res = {}
  -- stack = stack or {}

  -- Circular reference?
  -- if stack[val] then error("circular reference") end

  -- stack[val] = true

  if rawget(val, 1) ~= nil then-- or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    -- local n = 0
    -- for k in next, val do
    --   if type(k) ~= "number" then
    --     error("invalid table: mixed or invalid key types")
    --   end
    --   n = n + 1
    -- end
    -- if n ~= #val then
    --   error("invalid table: sparse array")
    -- end
    -- Encode
    local len = val.__len or #val
    for i = 1, len do
      res[i] = encode(val[i])--, stack)
    end
    --stack[val] = nil
    return "[" .. table_concat(res, ",") .. "]"

  else
    -- Treat as an object
    local n = 0
    for k, v in next, val do
      -- if type(k) ~= "string" then
      --   error("invalid table: mixed or invalid key types")
      -- end
      n = n + 1
      res[n] = encode(k) .. ":" .. encode(v)--, stack) .. ":" .. encode(v, stack)
    end
    --stack[val] = nil
    return "{" .. table_concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. string_gsub(val, '[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  -- if val ~= val or val <= -math.huge or val >= math.huge then
  --   error("unexpected number value '" .. tostring(val) .. "'")
  -- end
  if val % 1 == 0 then
    return tostring(val)
  else
    return string_format("%.14g", val)
  end
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val)--, stack)
  return type_func_map[type(val)](val)--, stack)
end


json.encode = encode


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[string_sub(str, i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if string_sub(str, i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string_format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  if n <= 0x7f then
    return string_char(n)
  elseif n <= 0x7ff then
    return string_char(math_floor(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string_char(math_floor(n / 4096) + 224, math_floor(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string_char(math_floor(n / 262144) + 240, math_floor(n % 262144 / 4096) + 128,
                       math_floor(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string_format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( string_sub(s, 3, 6),  16 )
  local n2 = tonumber( string_sub(s, 9, 12), 16 )
  -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local last
  for j = i + 1, #str do
    local x = string_byte(str, j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    end

    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = string_sub(str, j + 1, j + 5)
        if not string_find(hex, "%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        if string_find(hex, "^[dD][89aAbB]") then
          has_surrogate_escape = true
        else
          has_unicode_escape = true
        end
      else
        local c = string_char(x)
        if not escape_chars[c] then
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil

    elseif x == 34 then -- '"' (end of string)
      local s = string_sub(str, i + 1, j - 1)
      if has_surrogate_escape then
        s = string_gsub(s, "\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
      end
      if has_unicode_escape then
        s = string_gsub(s, "\\u....", parse_unicode_escape)
      end
      if has_escape then
        s = string_gsub(s, "\\.", escape_char_map_inv)
      end
      return s, j + 1

    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = string_sub(str, i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = string_sub(str, i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if string_sub(str, i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = string_sub(str, i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if string_sub(str, i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if string_sub(str, i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if string_sub(str, i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = string_sub(str, i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = string_sub(str, idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end
--[[ End of file tech/json/init.lua ]]--
--[[ End of package tech/json ]]--
--[[ Package tech/filemanager ]]--
--[[ File tech/filemanager/init.lua ]]--
local FileManager
do
	FileManager = {}
	FileManager.__index = FileManager

	local string_byte = string.byte
	local string_char = string.char
	local string_sub = string.sub

	local parsers
	parsers = {
		["dictionary"] = function(str, obj, idx)
			local result = {}
			if obj.length then -- premade dict!
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					result[child.name], idx = parsers[child.type](str, child, idx)
				end
			else
				local length
				length, idx = parsers.number(str, nil, idx)

				local strparser = parsers.string
				local parser, child = parsers[obj.objects.type], obj.objects
				local name
				for i = 1, length do
					name, idx = strparser(str, nil, idx)
					result[name], idx = parser(str, child, idx)
				end
			end
			return result, idx
		end,

		["array"] = function(str, obj, idx)
			local result = {}
			if obj.length then -- premade map!
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					result[i], idx = parsers[child.type](str, child, idx)
				end
			else
				local length
				length, idx = parsers.number(str, nil, idx)

				local parser, child = parsers[obj.objects.type], obj.objects
				for i = 1, length do
					result[i], idx = parser(str, child, idx)
				end
			end
			return result, idx
		end,

		["boolean"] = function(str, obj, idx)
			return string_sub(str, idx, idx) == "1", idx + 1
		end,

		["string"] = function(str, obj, idx)
			local length = obj and obj.length
			if not length then
				length, idx = parsers.number(str, nil, idx)
			end

			return string_sub(str, idx, idx - 1 + length), idx + length
		end,

		["number"] = function(str, obj, idx)
			local length = string_byte(str, idx)
			return tonumber(string_sub(str, idx + 1, idx + length)), idx + 1 + length
		end
	}

	local writers
	writers = {
		["dictionary"] = function(data, obj, str)
			if obj.length then -- premade map
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					str = writers[child.type](data[child.name], child, str)
				end
			else
				local _str = ""
				local length = 0

				local strwriter = writers.string
				local writer, child = writers[obj.objects.type], obj.objects
				for key, value in next, data do
					_str = strwriter(key, nil, _str)
					_str = writer(value, child, _str)
					length = length + 1
				end

				str = writers.number(length, nil, str) .. _str
			end
			return str
		end,

		["array"] = function(data, obj, str)
			if obj.length then -- premade map
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					str = writers[child.type](data[i], child, str)
				end
			else
				local length = #data
				str = writers.number(length, nil, str)

				local writer, child = writers[obj.objects.type], obj.objects
				for i = 1, #data do
					str = writer(data[i], child, str)
				end
			end
			return str
		end,

		["boolean"] = function(data, obj, str)
			return str .. (data and "1" or "0")
		end,

		["string"] = function(data, obj, str)
			if not (obj and obj.length) then
				str = writers.number(#data, nil, str)
			end
			return str .. data
		end,

		["number"] = function(data, obj, str)
			local encoded = tostring(data)
			return str .. string_char(#encoded) .. encoded
		end
	}

	local prepare_object
	function prepare_object(obj)
		assert(obj.type, "every object must have a type")

		if obj.type == "dictionary" then
			assert(obj.objects or obj.map, "a dictionary must have either a premade map or an objects list")
			assert(not (obj.objects and obj.map), "a dictionary can't have both a premade map and an objects list")
			assert(not obj.length, "a dictionary can't have the length variable set to it")

			if obj.map then
				obj.length = #obj.map

				local child
				for index = 1, obj.length do
					child = obj.map[index]
					assert(child.name, "every object in the map of a dictionary must have a name")

					prepare_object(child)
				end
			else
				assert(not obj.objects.name, "the object type in a dynamic dictionary can't have a premade name")

				prepare_object(obj.objects)
			end

		elseif obj.type == "array" then
			assert(obj.objects or obj.map, "an array must have either a premade map or an objects list")
			assert(not (obj.objects and obj.map), "an array can't have both a premade map and an objects list")
			assert(not obj.length, "an array can't have the length variable set to it")

			if obj.map then
				obj.length = #obj.map

				local child
				for index = 1, obj.length do
					prepare_object(obj.map[index])
				end
			else
				prepare_object(obj.objects)
			end

		elseif obj.type == "boolean" then
			-- nothing

		elseif obj.type == "string" then
			if obj.length then
				assert(type(obj.length) == "number", "length attribute of a string must be either nil or a number")
			end

		elseif obj.type == "number" then
			-- nothing

		else
			error("unknown object type: '" .. obj.type .. "'")
		end
	end

	local validity_checks
	function validity_checks(data, obj)
		local data_type = type(data)

		if obj.type == "dictionary" then
			assert(data_type == "table", "object must be a table in order to be casted to a dictionary")
			if obj.length then
				local length = 0

				local valid
				for key, value in next, data do
					valid = false
					length = length + 1
					for i = 1, obj.length do
						if obj.map[i].name == key then
							valid = true
							validity_checks(value, obj.map[i])
							break
						end
					end
					assert(valid, "table must have the same keys as the premade dictionary map")
				end

				assert(length == obj.length, "table must have the same length as the premade dictionary map")
			else
				local object = obj.objects
				for key, value in next, data do
					assert(type(key) == "string", "table indexes must be strings in order to be casted to a dynamic dictionary")
					validity_checks(value, object)
				end
			end

		elseif obj.type == "array" then
			assert(data_type == "table", "object must be a table in order to be casted to a array")
			if obj.length then
				assert(#data == obj.length, "table must have the same length as the premade array map")

				for i = 1, #data do
					validity_checks(data[i], obj.map[i])
				end
			else
				local object = obj.objects
				for i = 1, #data do
					validity_checks(data[i], object)
				end
			end

		elseif obj.type == "boolean" then
			-- no specific type needed

		elseif obj.type == "string" then
			assert(data_type == "string", "object must be a string in order to be written as one")
			if obj.length then
				assert(#data == obj.length, "string must have the same length as the allocated for the string")
			end

		elseif obj.type == "number" then
			assert(data_type == "number", "object must be a number in order to be written as one")
		end
	end

	function FileManager.new(struct)
		return setmetatable({
			ready = false,
			struct = struct,
			validity = true
		}, FileManager)
	end

	function FileManager:disableValidityChecks()
		self.validity = false
		return self
	end

	function FileManager:prepare()
		prepare_object(self.struct)
		self.ready = true
		return self
	end

	function FileManager:load(string)
		assert(self.ready, "FileManager needs to be prepared before using it")
		return parsers[self.struct.type](string, self.struct, 1)
	end

	function FileManager:check(data)
		validity_checks(data, self.struct)
		return self
	end

	function FileManager:dump(data)
		assert(self.ready, "FileManager needs to be prepared before using it")

		if self.validity then
			self:check(data)
		end

		return writers[self.struct.type](data, self.struct, "")
	end
end
--[[ End of file tech/filemanager/init.lua ]]--
--[[ End of package tech/filemanager ]]--
--[[ File global/packets.lua ]]--
local packets = {}

packets.rooms = {
  crash = 0,
  hourly_record = 3,
  weekly_reset = 4,
  pw_response = 5,
  command_log = 7,
  poll_answer = 8,
  title_logs = 9,
  kill_logs = 10,
  report = 11,
  ban_logs = 12,
  update_error = 13,
  lock_fixed = 14,
  prev_kill = 15,
}

packets.bots = {
  join = 0,
  game_update = 1,
  update_pdata = 2,
  --ban = 3,
  announce = 4,
  cm_announce = 5,
  pw_request = 6,
  room_announce = 7,
  change_lock = 8,
  remote_command = 9,
}
--[[ End of file global/packets.lua ]]--
--[[ File global/event-handler.lua ]]--
local translatedChatMessage
local channels, sendPacket, pipeHandler, channelHandler
local initializingModule = true

local onEvent, totalRuntime, startCycle, cycleId, usedRuntime
do
	-- Configuration
	local CYCLE_DURATION = 4100
	local RUNTIME_LIMIT = 30
	local DONT_SCHEDULE = {
		["Loop"] = true,
		["Keyboard"] = true
	}

	-- Optimization
	local os_time = os.time
	local math_floor = math.floor

	-- Runtime breaker
	startCycle = math_floor(os_time() / CYCLE_DURATION)
	cycleId = 0
	usedRuntime = 0
	totalRuntime = 0
	local stoppingAt = 0
	local checkingRuntime = false
	local paused = false
	local scheduled = {_count = 0, _pointer = 1}

	-- Listeners
	local events = {}

	local function errorHandler(name, msg)
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.disableMortCommand(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.newGame(7946879)
		tfm.exec.setGameTime(99999)

		for _, event in next, events do
			event._count = 0
		end

		tfm.exec.chatMessage(name .. " - " .. msg)

		if room.name == "*#parkour4bots" then
			ui.addTextArea(0, "*4bots\000" .. name .. "\000" .. msg)
			return
		end

		translatedChatMessage("emergency_mode")

		if is_tribe then return end

		tfm.exec.setRoomMaxPlayers(1)

		channels.canRead = false
		sendPacket("common", 0, room.shortName .. "\000" .. name .. "\000" .. msg)
		channelHandler(true) -- load channel now to send all the data

		events.Loop._count = 1
		events.Loop[1] = channelHandler

		events.PlayerDataLoaded._count = 2
		events.PlayerDataLoaded[1] = pipeHandler
		events.PlayerDataLoaded[2] = function(player)
			if channels[player] and channels[player].buffer then
				events.Loop._count = 0
				events.PlayerDataLoaded._count = 0
			end
		end
	end

	local function callListeners(evt, a, b, c, d, e, offset)
		for index = offset, evt._count do
			if not initializingModule and os_time() >= stoppingAt then
				if index < evt._count then
					-- If this event didn't end, we need to resume from
					-- where it has been left!
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, index}
				end

				paused = true
				cycleId = cycleId + 2
				translatedChatMessage("paused_events")
				break
			end

			evt[index](a, b, c, d, e)
		end
	end

	local function resumeModule()
		local count = scheduled._count

		local event
		for index = scheduled._pointer, count do
			event = scheduled[index]
			callListeners(event[1], event[2], event[3], event[4], event[5], event[6], event[7])

			if paused then
				if scheduled._count > count then
					-- If a new event has been scheduled, it is this one.
					-- It should be the first one to run on the next attempt to resume.
					event[7] = scheduled[ scheduled._count ][7]

					-- So we set it to start from here
					scheduled._pointer = index
					-- and remove the last item, since we don't want it to
					-- execute twice!
					scheduled._count = scheduled._count - 1
				else
					-- If no event has been scheduled, this one has successfully ended.
					-- We just tell the next attempt to resume to start from the next one.
					scheduled._pointer = index + 1
				end
				return
			end
		end

		-- delete all the scheduled tables since they just use ram!
		scheduled = {_count = 0, _pointer = 1}
		translatedChatMessage("resumed_events")
	end

	local function registerEvent(name)
		local evt = events[name]
		local schedule = not DONT_SCHEDULE[name]

		local event
		event = function(a, b, c, d, e)
			if initializingModule then
				local done, result = pcall(callListeners, evt, a, b, c, d, e, 1)
				if not done then
					errorHandler(name, result)
				end
				return
			end

			if checkingRuntime then
				if paused then
					if schedule then
						scheduled._count = scheduled._count + 1
						scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
					end
					return
				end
				-- Directly call callListeners since there's no need of
				-- two error handlers
				callListeners(evt, a, b, c, d, e, 1)
				return
			end

			-- If we call any event inside this one, we don't need to
			-- perform all the runtime breaker checks.
			checkingRuntime = true
			local start = os_time()
			local thisCycle = math_floor(start / CYCLE_DURATION)

			if thisCycle > cycleId then
				-- new runtime cycle
				totalRuntime = totalRuntime + usedRuntime

				cycleId = thisCycle
				usedRuntime = 0
				stoppingAt = start + RUNTIME_LIMIT

				-- if this was paused, we need to resume!
				if paused then
					paused = false
					checkingRuntime = false

					local done, result = pcall(resumeModule)
					if not done then
						errorHandler("resuming", result)
						return
					end

					usedRuntime = usedRuntime + os_time() - start

					-- if resuming took a lot of runtime, we have to
					-- pause again
					if paused then
						if schedule then
							scheduled._count = scheduled._count + 1
							scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
						end
						return
					end
				end
			else
				stoppingAt = start + RUNTIME_LIMIT - usedRuntime
			end

			if paused then
				if schedule then
					scheduled._count = scheduled._count + 1
					scheduled[ scheduled._count ] = {evt, a, b, c, d, e, 1}
				end
				checkingRuntime = false
				return
			end

			local done, result = pcall(callListeners, evt, a, b, c, d, e, 1)
			if not done then
				errorHandler(name, result)
				return
			end

			checkingRuntime = false
			usedRuntime = usedRuntime + os_time() - start
		end

		return event
	end

	function onEvent(name, callback)
		local evt = events[name]

		if not evt then
			-- Unregistered event
			evt = {_count = 0}
			events[name] = evt

			_G["event" .. name] = registerEvent(name)
		end

		-- Register callback
		evt._count = evt._count + 1
		evt[ evt._count ] = callback
	end
end
--[[ End of file global/event-handler.lua ]]--
--[[ File global/translation-handler.lua ]]--
local player_langs = {}

local translatedMessage
do
	local community = tfm.get.room.community
	function translatedMessage(what, who, ...)
		local lang
		if who then
			lang = player_langs[who]
		else
			lang = translations[community]
		end
		local text = lang and lang[what] or translations.en[what] or nil
		if not text then
			return "%" .. what .. "%"
		elseif select("#", ...) > 0 then
			done, text = pcall(string.format, text, ...)
			if not done then
				error(debug.traceback(what .. "," .. text))
			end
		end
		return text
	end
end

--local translatedChatMessage
do
	local chatMessage = tfm.exec.chatMessage
	function translatedChatMessage(what, who, ...)
		if not who then
			for player in next, player_langs do
				translatedChatMessage(what, player, ...)
			end
			return
		end
		local msg = translatedMessage(what, who, ...)
		local length = #msg

		while length > 1000 do
			chatMessage(string.sub(msg, 1, 1000), who)
			msg = string.sub(msg, 1001)
			length = length - 1000
		end
		if length > 0 then
			chatMessage(msg, who)
		end
	end
end

onEvent("NewPlayer", function(player)
	if room.playerList[player] then
		player_langs[player] = translations[room.playerList[player].community]
	else
		player_langs[player] = translations[room.community]
	end
end)

onEvent("PlayerLeft", function(player)
	player_langs[player] = nil
end)
--[[ End of file global/translation-handler.lua ]]--
--[[ File global/communication.lua ]]--
--[[
	-- should not work in tribehouse

	pipeHandler(pipe, data)
	channelHandler(load_now)
	sendPacket(channel, id, packet)

	eventPacketSent(channel)
	eventPacketReceived(channel, id, packet)
	eventRetrySendData(channel)
	eventCantSendData(channel)
]]

channels = {
	canRead = true,

	-- isRead, doClean, ttl, customStructure, bots (pipes)
	common = { -- to bots (common data, low traffic)
		room.name == "*#parkour4bots", true, 10000,
		false,
		"Funcorp#0801", "Delphilante#1225",
		"Recordsbot#8598", "Buildtool#0800",
	},
	victory = { -- to bots (all victory logs, high traffic)
		room.name == "*#parkour4bots", true, 10000,
		"(................[^\000]+)\000",
		"Parkour#8558"
	},
	bots = { -- from bots (all orders, low traffic)
		room.name ~= "*#parkour4bots", false, 10000,
		false,
		"Parkour#0568", "Sharpiebot#0000"
	}
}

local read = {}
local write = {}

local tbl
local channelBots = {}
for name, data in next, channels do
	if name ~= "canRead" then
		tbl = data[1] and read or write

		tbl[name] = {
			name = name,
			read = data[1],
			clean = data[2],
			ttl = data[3],
			structure = data[4],
			buffer = nil
		}
		for index = 5, #data do
			-- bot names (pipes)
			tbl[name][index - 4] = data[index]
			-- last id in pipe
			tbl[name][ data[index] ] = 0

			channelBots[ data[index] ] = tbl[name]
		end

		tbl[name].pipes = #data - 4
		if not data[1] then -- write channel
			-- select random pipe (if there are many, load will distribute)
			tbl[name].selected = math.random(0, #data - 5)
			-- retries left for this channel
			tbl[name].retries = #data - 4
		end
	end
end

for key, val in next, channelBots do
	channels[key] = val
end

local next_load = os.time() + 10000
local timeout

local decoder = {
	["&0"] = "&", ["&1"] = ";", ["&2"] = ","
}
local encoder = {
	["&"] = "&0", [";"] = "&1", [","] = "&2"
}

function sendPacket(channel, id, packet)
	channel = write[channel]

	if not channel then
		error("Unknown channel: " .. channel, 2)
	end

	local buffer = channel.buffer or ""
	if #buffer + #packet > 1985 then -- too large
		buffer = ""
	end

	if channel.structure then
		buffer = buffer .. packet
	else
		buffer = buffer .. ";" .. id .. "," .. string.gsub(packet, "[&;,]", encoder)
	end

	channel.buffer = buffer
end

function pipeHandler(pipe, data)
	local channel = channels[pipe]
	if not channel then return end -- not a channel!

	local expire, data = string.match(data, "^(%d+);(.*)$")
	if not expire then
		expire, data = 0, ""
	end
	expire = tonumber(expire)

	local now = os.time()

	if channel.read then
		if channel[pipe] >= expire or now >= expire then
			-- already read or expired
			return
		end

		channel[pipe] = expire

		if eventPacketReceived then
			if channel.structure then
				for packet in string.gmatch(data, channel.structure) do
					eventPacketReceived(channel.name, -1, packet)
				end

			else
				for id, packet in string.gmatch(data, "(%d+),([^;]*)") do
					packet = string.gsub(packet, "&[012]", decoder)

					eventPacketReceived(channel.name, tonumber(id), packet)
				end
			end
		end

		if channel.clean then
			system.savePlayerData(pipe, "")
		end

	elseif channel.buffer then -- is write and has something to send
		if channel[ channel.selected + 1 ] ~= pipe then
			-- loaded too late
			return
		end

		local buffer = channel.buffer
		channel.buffer = nil

		if now < expire then -- data didn't expire, we have to keep it
			if #data + #buffer <= 1985 then -- if it doesn't fit, we just delete old data
				buffer = data .. buffer
			end
		end

		if string.sub(buffer, 1, 1) ~= ";" then
			buffer = ";" .. buffer
		end

		if eventPacketSent then
			eventPacketSent(channel.name)
		end

		system.savePlayerData(pipe, (now + channel.ttl) .. buffer)
	end
end
onEvent("PlayerDataLoaded", pipeHandler)

function channelHandler(load_now)
	local now = os.time()

	if timeout and now >= timeout then
		local retry = false

		for name, data in next, write do
			if data.buffer then
				if data.retries > 0 then
					retry = true
					data.retries = data.retries - 1
					data.selected = (data.selected + 1) % data.pipes

					system.loadPlayerData(data[ data.selected + 1 ])

					if eventRetrySendData then
						eventRetrySendData(name)
					end

				elseif eventCantSendData then
					eventCantSendData(name)
				end
			end
		end

		if retry then
			timeout = now + 1500
		else
			timeout = nil
		end
	end

	if load_now == true or now >= next_load then
		-- load_now may be an int since it's executed in eventLoop
		next_load = now + 10000
		timeout = now + 1500

		for name, data in next, write do
			if data.buffer then
				data.retries = data.pipes
				system.loadPlayerData(data[ data.selected + 1 ])
			end
		end

		if channels.canRead then
			for name, data in next, read do
				for index = 1, data.pipes do
					system.loadPlayerData(data[index])
				end
			end
		end
	end
end
onEvent("Loop", channelHandler)
--[[ End of file global/communication.lua ]]--
--[[ End of package global ]]--

local function initialize_parkour() -- so it uses less space after building
	--[[ Package modes/parkour ]]--
	--[[ File modes/parkour/command-log.lua ]]--
	local function logCommand(author, cmd, quantity, args)
		if quantity and quantity > 0 and args then
			cmd = cmd .. " " .. table.concat(args, " ", 1, quantity)
		end
	
		sendPacket("common", 7, room.shortName .. "\000" .. author .. "\000" .. cmd)
	end
	
	local function inGameLogCommand()end
	--[[ End of file modes/parkour/command-log.lua ]]--
	--[[ File modes/parkour/sanctionfilemanager.lua ]]--
	local function string_split(str, deli)
	    local parts, len = {}, 0
	    for part in str:gmatch('[^'..deli..']+') do
	        len = len + 1
	        parts[len] = part
	    end
	    return parts
	end
	
	local SanctionFileManager = {
	    lastupdate = "",
	    lastdata = nil,
	
	    load = function(self, str)
	        local data = string_split(str, "\1")
	
	        if self.lastupdate == data[1] then
	            return self.lastdata
	        end
	
	        local lowmaps = string_split(data[2], "\2")
	        local sanctionList = string_split(data[3], "\2")
	
	        for i=1, #lowmaps do
	            lowmaps[i] = tonumber(lowmaps[i])
	        end
	
	        local sanctionDict = {}
	        local sanction
	
	        for i=1, #sanctionList do
	            sanction = string_split(sanctionList[i], "\3")
	            sanctionDict[sanction[1]] = {
	                timestamp = tonumber(sanction[2]),
	                time = tonumber(sanction[3]),
	                info = sanction[4] or "UNKNOWN",
	                level = tonumber(sanction[5]),
	            }
	        end
	
	        self.lastupdate = data[1]
	        self.lastdata = {
	            lowmaps = lowmaps,
	            sanction = sanctionDict,
	        }
	
	        return self.lastdata
	    end,
	
	    dump = function(self, data)
	        local lowmaps = table.concat(data.lowmaps, "\2")
	        local sanctionList, len = {}, 0
	
	        for name, sanction in next, data.sanction do
	            len = len + 1
	            sanctionList[len] = table.concat({
	                name,
	                sanction.timestamp,
	                sanction.time,
	                sanction.info,
	                sanction.level,
	            }, "\3")
	        end
	
	        return table.concat({ os.time(), lowmaps, table.concat(sanctionList, "\2") }, "\1")
	    end,
	}
	--[[ End of file modes/parkour/sanctionfilemanager.lua ]]--
	--[[ File modes/parkour/filemanagers.lua ]]--
	local filemanagers = {
		["20"] = FileManager.new({
			type = "dictionary",
			map = {
				{
					name = "maps",
					type = "array",
					objects = {
						type = "number"
					}
				},
				{
					name = "ranks",
					type = "dictionary",
					objects = {
						type = "number"
					}
				},
				-- commented because the file is missing migration
				-- {
				-- 	name = "map_polls",
				-- 	type = "array",
				-- 	objects = {
				-- 		type = "number"
				-- 	}
				-- },
				{
					name = "chats",
					type = "dictionary",
					map = {
						{
							name = "mod",
							type = "string",
							length = 10
						},
						{
							name = "mapper",
							type = "string",
							length = 10
						}
					}
				}
			}
		}):disableValidityChecks():prepare(),
	
		["21"] = FileManager.new({
			type = "dictionary",
			map = {
				{
					name = "ranking",
					type = "array",
					objects = {
						type = "array",
						map = {
							{
								type = "number"
							},
							{
								type = "string",
							},
							{
								type = "number"
							},
							{
								type = "string",
								length = 2
							}
						}
					}
				},
				{
					name = "weekly",
					type = "dictionary",
					map = {
						{
							name = "ranks",
							type = "array",
							objects = {
								type = "array",
								map = {
									{
										type = "number"
									},
									{
										type = "string",
									},
									{
										type = "number"
									},
									{
										type = "string",
										length = 2
									}
								}
							}
						},
						{
							name = "ts",
							type = "string"
						},
						{
							name = "wl",
							type = "dictionary",
							objects = {
								type= "number"
							}
						}
					}
				}
			}
		}):disableValidityChecks():prepare(),
	
		["23"] = SanctionFileManager,
	}
	--[[ End of file modes/parkour/filemanagers.lua ]]--
	--[[ Directory translations/parkour ]]--
	--[[ File translations/parkour/br.lua ]]--
	translations.br = {
		name = "br",
		fullname = "Português",
	
		-- Error messages
		corrupt_map = "<r>Mapa corrompido. Carregando outro.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Não foi possível obter informações deste mapa.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>O mapa requer um ponto de partida (spawn).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>O mapa requer a poltrona final.",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>O mapa requer ao menos um checkpoint (prego amarelo).",
		corrupt_data = "<r>Infelizmente seus dados corromperam e foram reiniciados.",
		min_players = "<r>Para que dados sejam salvos, ao menos 4 jogadores únicos devem estar na sala. <bl>[%s/%s]",
		tribe_house = "<r>Para que dados sejam salvos, você precisa jogar fora de um cafofo de tribo.",
		invalid_syntax = "<r>Sintaxe inválida.",
		code_error = "<r>Um erro aconteceu: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Começando desativação de emergência, novos jogadores não serão mais permitidos. Por favor, vá para outra sala #parkour.",
		leaderboard_not_loaded = "<r>O ranking ainda não foi carregado. Aguarde um minuto.",
		max_power_keys = "<v>[#] <r>Você pode ter no máximo %s poderes na mesma tecla.",
	
		-- Help window
		help = "Ajuda",
		staff = "Staff",
		rules = "Regras",
		contribute = "Contribuir",
		changelog = "Novidades",
		help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></p>\n\n<N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.\n• Clique <a href='event:discord'><o>aqui</o></a> para obter um link de convide para o nosso servidor no Discord e <a href='event:map_submission'><o>aqui</o></a> para obter o link do tópico de avaliação de mapas.\n• Use as setas <o>para cima</o> ou <o>para baixo</o> quando você precisar rolar a página.\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#D0A9F0'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
		help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador intencionalmente usa seus poderes ou consumíveis para fazer com que outros jogadores não consigam terminar o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador é pego trollando, será punido em uma questão de tempo. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
		help_contribute = "<font size='14'>\n<p align='center'>A equipe do parkour adora ter um código aberto, pois isso <t>ajuda a comunidade</t>. Você pode <o>ver</o> ou <o>contribuir</o> com o código no <o><u><a href='event:github'>GitHub</a></u></o>.\n\nManter o módulo é parte de um trabalho <t>voluntário</t>, então qualquer contribuição é <u>bem vinda</u>, seja com a <t>programação</t>, <t>reporte de erros</t>, <t>sugestões</t> e <t>criação de mapas</t>.\nVocê pode <vp>reportar erros</vp> ou <vp>dar sugestões</vp> no nosso <o><u><a href='event:discord'>Discord</a></u></o> e/ou no <o><u><a href='event:github'>GitHub</a></u></o>.\nVocê pode <vp>enviar seus mapas</vp> no nosso <o><u><a href='event:map_submission'>Tópico no Fórum</a></u></o>.\n\nManter o jogo não é caro, mas também não é grátis. Nós adoraríamos se você pudesse incentivar o desenvolvimento do jogo <t>doando qualquer valor</t> <o><u><a href='event:donate'>aqui</a></u></o>.\n<u>Todos os fundos arrecadados serão direcionados para o desenvolvimento do módulo.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Versão 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Sistema de missões implementado. (Aperte <J><B>,</B></J> para abrir painel de missões.)\n\n<font size='11'>• <font size='13'>Adicionado uma opção para desativar as teclas de atalho de todas as interfaces tipo rank, ajuda, loja, etc.\n\n<font size='11'>• <font size='13'>Adicionado <B><J>!cp [PlayerName#tag]</J></B> comando para ir direto para o checkpoint de um jogador especifico.",
	
		-- Congratulation messages
		reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
		unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
	
		-- Information messages
		mod_apps = "<j>As inscrições para moderador do parkour estão abertas! Use esse link: <rose>%s",
		staff_power = "<r>A Staff do Parkour <b>não</b> tem nenhum poder fora das salas #parkour.",
		donate = "<vp>Digite <b>!donate</b> se você gostaria de doar para este módulo!",
		paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
		resumed_events = "<n2>O módulo está se normalizando.",
		welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
		module_update = "<r><b>[Atenção!]</b> <n>O módulo irá atualizar em <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>O ranking foi carregado. Aperte L para abri-lo.",
		kill_minutes = "<R>Seus poderes foram desativados por %s minutos.",
		permbanned = "<r>Você foi banido permanentemente do #parkour.",
		tempbanned = "<r>Você foi banido do #parkour por %s minutos.",
		forum_topic = "<rose>Para mais informações sobre o módulo, acesse o link: %s",
		report = "<j>Quer reportar um jogador? <t><b>/c Parkour#8558 .report NomeJogador#0000</b></t>",
		mapper_event ="<CE><B>Concurso de criação de mapas parkour 2024:</B>\n<n>Nos mostre sua criatividade na criação de mapas pela chance de ganhar <D>quejios <n>e <pt>moedas<n>!\n<R>Inscrições abertas até <B>31 de Janeiro de 2024</B>.\n<PS>Para mais informações, visite: %s", 
	
		-- Easter Eggs
		easter_egg_0  = "<ch>E a contagem regressiva começa...",
		easter_egg_1  = "<ch>Menos de 24 horas restantes!",
		easter_egg_2  = "<ch>Eita, você está muito adiantado! Está muito ansioso?",
		easter_egg_3  = "<ch>Uma surpresa está no forno...",
		easter_egg_4  = "<ch>Você sabe o que está prestes a acontecer...?",
		easter_egg_5  = "<ch>O tempo está passando...",
		easter_egg_6  = "<ch>A surpresa está próxima!",
		easter_egg_7  = "<ch>A festa está prestes a começar...",
		easter_egg_8  = "<ch>Que horas são? Já deu a hora?",
		easter_egg_9  = "<ch>Atente-se, o tempo está passando...",
		easter_egg_10 = "<ch>Apenas sente e relaxe, será amanhã sem horário definido!",
		easter_egg_11 = "<ch>Vamos para a cama mais cedo, o tempo vai passar mais rápido!",
		easter_egg_12 = "<ch>Paciência é uma virtude",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Você ganhará duas vezes mais vitórias no Sábado (GMT+2) e todos os poderes estarão disponíveis na semana de aniversário do Parkour!",
		double_maps_start = "<rose>É A SEMANA DE ANIVERSÁRIO DO PARKOUR! Você ganhará duas vezes mais vitórias e todos os poderes foram ativados. Muito obrigado por jogar com a gente!",
		double_maps_end = "<rose>A semana de aniversário do Parkour terminou. Muito obrigado por jogar com a gente!",
	
		-- Records
		records_enabled = "<v>[#] <d>Modo Records está ativado nesta sala. Dados não serão contados e poderes não estão ativados!\nVocê poderá encontrar mais informações sobre records em <b>%s</b>",
		records_admin = "<v>[#] <d>Você é um administrador desta sala de records. Você pode usar os comandos <b>!map</b>, <b>!setcp</b>, <b>!pw</b> e <b>!time</b>.",
		records_completed = "<v>[#] <d>Você completou o mapa! Se você quiser jogar nele novamente, digite <b>!redo</b>.",
		records_submit = "<v>[#] <d>Wow! Parece que você teve o melhor tempo nesta sala. Se você quiser enviar o record, digite <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Parece que este mapa não está na rotação de mapas do parkour... Você não pode enviar um recorde para ele",
		records_not_fastest = "<v>[#] <r>Parece que você não é o jogador mais rápido na sala...",
		records_already_submitted = "<v>[#] <r>Você já enviou seu recorde para este mapa!",
		records_submitted = "<v>[#] <d>Seu recorde para o mapa <b>%s</b> foi enviado.",
	
		-- Quests
		daily_q = "Diária",
		weekly_q = "Semanal",
		daily_quests = "<p align='center'><font size='20'><B><D>Missões Diárias</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Missões Semanais</D></B></font>",
		quest_1 = "Complete <B><D>%s/%s</D></B> mapas.",
		quest_2 = "Colete <B><D>%s/%s</D></B> checkpoints.",
		quest_3 = "Complete qualquer mapa em primeiro lugar <B><D>%s/%s</D></B> vezes.",
		quest_4 = "Complete um mapa em menos de <B><D>%s</D></B> segundos.",
		quest_5 = "Complete o mapa <B><D>@%s</D></B>",
		quest_6 = "Use o poder <PT><b>%s</b></PT> <B><D>%s/%s</D></B> vezes.",
		next_reset = "<b><D>Reinicia:\n</b></D>%s",
		quest_completed = "<b><D>Parabéns!</D></b> \n¡Você completou uma missão %s!",
		quest_reset = "<V>[#]</V> <O>Suas missões %s foram reiniciadas.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Papai Noel passou por aqui! Procure o presente de Natal no mapa e desembrulhe para uma surpresa!",
	    find_gift2 = "<ch>Som dos sinos em todos os lugares! Um presente especial de natal apareceu magicamente no mapa – corra e ache ele!",
	    find_gift3 = "<ch>Ho, ho, ho! O ajudante do Papai Noel deixou um presente para você nesse mapa!",
	    find_gift4 = "<ch>O espírito natalino no ar! Ache o presente escondido nesse mapa!",
	    find_gift5 = "<ch>Feliz Natal! Os elfos esconderam um presente para você. Você consegue encontrar ele?",
	    found_gift1 = "<ch>Bravo! <J>%s</J> desembrulhou um presente e achou %s moedas dentro!",
	    found_gift2 = "<ch>Parabéns, <J>%s</J>! Você ganhou <J>%s</J> moedas brilhantes de presente do Papai Noel!",
	    found_gift3 = "<ch>Uma vitória para <J>%s</J>! <J>%s</J> mais rico, obrigado Papai Noel!",
	    found_gift4 = "<ch>Parabéns para <J>%s</J> que ganhou <J>%s</J> moedas! O espirito natalino esta com tudo!",
	    found_gift5 = "<ch>Papai Noel concedeu <J>%s</J> com <J>%s</J> lindas moedas!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>VOCê ESTÁ NO MODO AFK</b></bv>\nMOVA-SE PARA RENASCER</font>\n\n<font size='30'><u><t>Lembretes:</t></u></font>\n\n<font size='15'><r>Jogadores com uma linha vermelha em cima deles não querem ajuda!\nTrollar/bloquear outros jogadores no parkour NÃO é permitido!<d>\nEntre em nosso <cep><a href='event:discord'>servidor no Discord</a></cep>!\nQuer contribuir com código? Veja nosso <cep><a href='event:github'>repositório no Github</a></cep>\nVocê tem um mapa bom pra enviar? Mande-o em nosso <cep><a href='event:map_submission'>tópico de submissão de mapas</a></cep>\nCheque nosso <cep><a href='event:forum'>tópico oficial no fórum</a></cep> para mais informações!\nNos apoie com <cep><a href='event:donate'>doações!</a></cep>",
		options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado\n\nMostrar símbolo de não ajudar\n\nDesative as teclas de atalho de todas as interfaces (leaderboard, help, shop, etc.)",
		cooldown = "<v>[#] <r>Aguarde alguns segundos antes de fazer isso novamente.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'>Teclado <b>QWERTY</b>" ..
						 "\n\n<b>Esconder</b> contagem de mapas" ..
						 "\n\nUsar <b>tecla padrão</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complete <v>%s</v> mapas" ..
						"<font size='5'>\n\n</font>para desbloquear" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complete <v>%s</v> mapas" ..
						"<font size='5'>\n\n</font>para evoluir para" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Seja top <v>%s</v>" ..
						"<font size='5'>\n\n</font>para desbloquear" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Seja top <v>%s</v>" ..
						"<font size='5'>\n\n</font>para evoluir para" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Mapas completados"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Ranking Geral"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Ranking Semanal"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Medalhas (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>A contagem de mapas deste jogador é privado. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Posição no Ranking geral: <b><v>%s</v></b>\n\n" ..
					"Posição no Ranking semanal: <b><v>%s</v></b>\n\n%s"),
		map_count = "Contagem de mapas: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Mapas completados: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
			"<b><j>«!»</j></b> Checkpoints coletados: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Medalhas são objetivos que um jogador pode conseguir. Clique nelas para ler suas descrições.",
		help_private_maps = "Este jogador não gosta de divulgar sua contagem de mapas publicamente! Você também pode escondê-la em seu perfil.",
		help_yellow_maps = "Mapas em amarelo são os mapas completados nesta semana.",
		help_red_maps = "Mapas em vermelho são os mapas completados na última hora.",
		help_map_count_title = "Você pode conseguir títulos no <b>Transformice</b> ao completar mapas parkour!",
		help_checkpoint_count_title = "Você pode conseguir títulos no <b>Transformice</b> ao coletar todos os checkpoints em mapas parkour!",
		help_badge_1 = "Este jogador já foi um membro da staff do #parkour no passado.",
		help_badge_2 = "Este jogador está ou já esteve na página 1 do ranking global.",
		help_badge_3 = "Este jogador está ou já esteve na página 2 do ranking global.",
		help_badge_4 = "Este jogador está ou já esteve na página 3 do ranking global.",
		help_badge_5 = "Este jogador está ou já esteve na página 4 do ranking global.",
		help_badge_6 = "Este jogador está ou já esteve na página 5 do ranking global.",
		help_badge_7 = "Este jogador esteve no pódio no fim de um ranking semanal.",
		help_badge_8 = "Este jogador bateu um recorde de 30 mapas por hora.",
		help_badge_9 = "Este jogador bateu um recorde de 35 mapas por hora.",
		help_badge_10 = "Este jogador bateu um recorde de 40 mapas por hora.",
		help_badge_11 = "Este jogador bateu um recorde de 45 mapas por hora.",
		help_badge_12 = "Este jogador bateu um recorde de 50 mapas por hora.",
		help_badge_13 = "Este jogador bateu um recorde de 55 mapas por hora.",
		help_badge_14 = "Este jogador verificou sua conta no servidor oficial do Parkour no Discord (digite <b>!discord</b>).",
		help_badge_15 = "Este jogador teve o tempo mais rápido em 1 mapa.",
		help_badge_16 = "Este jogador teve o tempo mais rápido em 5 mapas.",
		help_badge_17 = "Este jogador teve o tempo mais rápido em 10 mapas.",
		help_badge_18 = "Este jogador teve o tempo mais rápido em 15 mapas.",
		help_badge_19 = "Este jogador teve o tempo mais rápido em 20 mapas.",
		help_badge_20 = "Este jogador teve o tempo mais rápido em 25 mapas.",
		help_badge_21 = "Este jogador teve o tempo mais rápido em 30 mapas.",
		help_badge_22 = "Este jogador teve o tempo mais rápido em 35 mapas.",
		help_badge_23 = "Este jogador teve o tempo mais rápido em 40 mapas.",
		make_public = "tornar público",
		make_private = "tornar privado",
		moderators = "Moderadores",
		mappers = "Mappers",
		managers = "Gerentes",
		administrators = "Administradores",
		close = "Fechar",
		cant_load_bot_profile = "<v>[#] <r>Você não pode ver o perfil deste bot já que o #parkour utiliza-o internamente para funcionar devidamente.",
		cant_load_profile = "<v>[#] <r>O jogador <b>%s</b> parece estar offline ou não existe.",
		like_map = "Você gosta deste mapa?",
		yes = "Sim",
		no = "Não",
		idk = "Não sei",
		vote_map = "<font color='#ffffff' size='13'><b>Você gosta deste mapa? <font size='14'><a href='event:mapPollYes'><PT>Sim</a> <a href='event:mapPollidk'><N>Não sei</a> <a href='event:mapPollNo'><R>Não</a>",
		unknown = "Desconhecido",
		powers = "Poderes",
		press = "<vp>Aperte %s",
		click = "<vp>Use click",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Mapas completados: %s</B></p></BV>",
		leaderboard = "Ranking",
		position = "<V><p align=\"center\">Posição",
		username = "<V><p align=\"center\">Nome",
		community = "<V><p align=\"center\">Comunidade",
		completed = "<V><p align=\"center\">Mapas completados",
		overall_lb = "Geral",
		weekly_lb = "Semanal",
		new_lang = "<v>[#] <d>Idioma definido para Português",
		room = "Sala",
		time = "Tempo",
		buy = "Comprar",
		equip = "Equipe",
		equipped = "<font size = '10'>Equipado</font>",
		saving = "<p align='right'>Salvando...",
	
		-- Power names
		balloon = "Balão",
		masterBalloon = "Balão II",
		bubble = "Balão III",
		fly = "Voar",
		snowball = "Bola de Neve",
		speed = "Velocidade",
		teleport = "Teleporte",
		smallbox = "Caixa Pequena",
		cloud = "Nuvem",
		rip = "Lápide",
		choco = "Choco-tábua",
		bigBox = "Caixa grande",
		trampoline = "Trampolim",
		toilet = "Vaso Sanitário",
		pig = "Leitão",
		sink = "Pia",
		bathtub = "Banheira",
		campfire = "Fogueira",
		chair = "Cadeira",
		link = "Alma gêmea",
	}
	translations.pt = translations.br
	--[[ End of file translations/parkour/br.lua ]]--
	--[[ File translations/parkour/cn.lua ]]--
	translations.cn = {
		name = "cn",
		fullname = "中文",
	
		-- Error messages
		corrupt_map = "<r>地圖崩壞。正在載入另一張。",
		corrupt_map_vanilla = "<r>[錯誤] <n>無法取得此地圖的資訊。",
		corrupt_map_mouse_start = "<r>[錯誤] <n>此地圖需要有起始位置 (小鼠出生點)。",
		corrupt_map_needing_chair = "<r>[錯誤] <n>地圖需要包括終點椅子。",
		corrupt_map_missing_checkpoints = "<r>[錯誤] <n>地圖需要有最少一個重生點 (黃色釘子)。",
		corrupt_data = "<r>不幸地, 你的資料崩壞了而被重置了。",
		min_players = "<r>房間裡需要至少4名玩家才可以保存資料。 <bl>[%s/%s]",
		tribe_house = "<r>在部落之家遊玩的資料不會被儲存。",
		invalid_syntax = "<r>無效的格式。",
		code_error = "<r>發生了錯誤: <bl>%s-%s-%s %s",
		emergency_mode = "<r>正在啟動緊急終止模式, 新玩家無法加入遊戲。請前往另一個　#parkour 房間。",
		leaderboard_not_loaded = "<r>排行榜沒被加載。請稍後片刻。",
		max_power_keys = "<v>[#] <r>你只可以在同一個按鍵使用最多 %s 個能力。",
	
		-- Help window
		help = "幫助",
		staff = "職員",
		rules = "規則",
		contribute = "貢獻",
		changelog = "新聞",
		help_help = "<p align = 'center'><font size = '14'>歡迎來到 <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>你的目標是到達所有重生點直到完成地圖。</J></p>\n\n<N>• 按 <O>O</O>鍵, 輸入 <O>!op</O> 或是點擊右上方的 <O>齒輪</O> 來開啟 <T>選項目錄</T>。\n• 按 <O>P</O> 鍵或是點擊右上方的 <O>拳頭標誌</O> 來開啟 <T>能力目錄</T>。\n• 按 <O>L</O> 鍵或是輸入 <O>!lb</O> 來開啟 <T>排行榜</T>。\n• 按 <O>M</O> 鍵或是 <O>刪除</O> 鍵來 <T>自殺</T>, 你可以在 <J>選項</J> 目錄中激活按鍵。\n• 要知道更多關於我們 <O>職員</O> 的資訊以及 <O>parkour 的規則</O>, 可點擊 <T>職員</T> 及 <T>規則</T> 的分頁查看。\n• 點擊 <a href='event:discord'><o>這裡</o></a> 來取得 discord 邀請連結及 <a href='event:map_submission'><o>這裡</o></a> 來得到提交地圖的論壇連結。\n• 當你想滾動頁面可使用 <o>上</o> 鍵及 <o>下</o> 鍵。\n\n<p align = 'center'><font size = '13'><T>貢獻現在是開放的! 點擊 <O>貢獻</O> 分頁來了解更多!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>免責聲明: Parkour 的職員並不是 Transformice 職員而且在遊戲裡沒有任何權力, 只負責這小遊戲的規管。</r>\nParkour 職員確保小遊戲減少錯誤而運作順暢, 而且可以在有需要時協助玩家。</font></p>\n你可以在聊天框輸入 <D>!staff</D> 來查看職員列表。\n\n<font color = '#E7342A'>工作人員:</font> 他們負責透過更新及修復滴漏洞來維護小遊戲。\n\n<font color = '#D0A9F0'>小隊主管:</font> 他們會觀察管理團隊及地圖團隊, 確保他們在工作上的表現。他們也負責招募新成員加入職員團隊中。\n\n<font color = '#FFAAAA'>管理員:</font> 他們負責執行小遊戲裡的規則以及處分違反規則的玩家。\n\n<font color = '#25C059'>地圖管理員:</font> 他們負責審核, 新增, 以及移除小遊戲裡的地圖來確保你可以享受遊戲過程。",
		help_rules = "<font size = '13'><B><J>所有適用於 Transformice 的條款及細則也適用於 #parkour</J></B></font>\n\n如果你發現任何玩家違反這些規則, 可以在遊戲中私聊 parkour 的管理員。如果沒有管理員在線, 你可以在 discord 伺服器中舉報事件。\n當你舉報的時候, 請提供你所在的伺服器, 房間名稱, 以及玩家名稱。\n• 例如: en-#parkour10 Blank#3495 trolling\n證明, 例如是截圖, 錄象以及gif圖能有效協助舉報, 但不是一定需要的。\n\n<font size = '11'>• 任何 <font color = '#ef1111'>外掛, 瑕疵或漏洞</font> 是不能在 #parkour 房間中使用\n• <font color = '#ef1111'>VPN 刷數據</font> 會被當作 <B>利用漏洞</B> 而不被允許的。 <p align = 'center'><font color = '#cc2222' size = '12'><B>\n任何人被抓到違反規則會被即時封禁。</B></font></p>\n\n<font size = '12'>Transformice 允許搗蛋行為。但是, <font color='#cc2222'><B>我們不允許在 parkour 的搗蛋行為。</B></font></font>\n\n<p align = 'center'><J>惡作劇是指一個玩家有意圖地使用能力或消耗品來阻止其他玩家完成地圖。</j></p>\n• 復仇性的搗蛋行為 <B>並不是一個合理解釋</B> 來搗亂別人而因此你也會被處分。\n• 強迫想自理的玩家接受協助而當他說不用之後仍舊沒有停止此行為也會被視作搗蛋。\n• <J>如果一個玩家不想被協助或是想自理通關, 請你盡力協助其他玩家。</J> 但是如果有另外的玩家需要協助而剛好跟自理玩家在同一個重生點, 你可以協助他們 [兩人]。\n\n如果玩家惡作劇被抓, 會被處分基於時間的懲罰。重覆的搗蛋行為會引至更長及更嚴重的處分。",
		help_contribute = "<font size='14'>\n<p align='center'>Parkour 管理團隊喜愛開放原始碼是因為它能夠<t>協助社群</t>。 你可以在 <o><u><a href='event:github'>GitHub</a></u></o> <o>查看</o> 以及 <o>修改</o> 原始碼。\n\n維護這個小遊戲是 <t>義務性質</t>, 所以任何在 <t>編程</t>, <t>漏洞回饋</t>, <t>建議</t> 及 <t>地圖創作</t> 上提供的幫助將會是十分 <u>歡迎而且非常感激</u>。\n你可以在 <o><u><a href='event:discord'>Discord</a></u></o> 及/或 <o><u><a href='event:github'>GitHub</a></u></o> <vp>匯報漏洞</vp> 和 <vp>提供意見</vp>。\n你可以在我們的 <o><u><a href='event:map_submission'>論壇帖子</a></u></o> 中 <vp>提交你的地圖</vp>。\n\n維護 Parkour 不是很花費, 但也不完全是免費。我們希望你能夠在 <o><u><a href='event:donate'>這裡</a></u></o> <t>捐贈任何金額</t> 來支持我們。\n<u>所有捐款會用來改善這個小遊戲。</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>版本 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>新增了任務系統。 (按 <J><B>,</B></J> 開啟任務頁面。)\n\n<font size='11'>• <font size='13'>新增了一個隱藏所有快捷按鈕例如排行榜, 幫助, 商店等等的選項。\n\n<font size='11'>• <font size='13'>新增 <B><J>!cp [PlayerName#tag]</J></B> 指令用來設定某玩家的重生點作為自己現在的重生點。",
		
		-- Congratulation messages
		reached_level = "<d>恭喜! 你已經到達重生點 <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> 在 <vp>%s</vp> 秒內完成了地圖, <fc>恭喜!",
		unlocked_power = "<ce><d>%s</d> 解鎖了 <vp>%s</vp> 能力。",
	
		-- Information messages
		staff_power = "<r>Parkour 職員 <b>不會</b> 擁有任何在 #parkour 房間以外的權力。",
		donate = "<vp>如果你想為此小遊戲捐款，請輸入<b>!donate</b>！",
		paused_events = "<cep><b>[警告!]</b> <n>小遊戲已達到最高流量限制而被暫停了。",
		resumed_events = "<n2>小遊戲已繼續啟用。",
		welcome = "<n>歡迎來到 <t>#parkour</t>!",
		module_update = "<r><b>[警告!]</b> <n>小遊戲將會在 <d>%02d:%02d</d> 後更新。",
		leaderboard_loaded = "<j>排行榜已載入。請按 L 鍵打開它。",
		kill_minutes = "<R>你的能力已經在 %s 分鐘內暫時取消了。",
		permbanned = "<r>你已經在 #parkour 被永久封禁。",
		tempbanned = "<r>你已經在 #parkour 被封禁了 %s 分鐘。",
		forum_topic = "<rose>更多關於這個小遊戲的資訊可以查看: %s",
		report = "<j>想舉報玩家? <t><b>/c Parkour#8558 .report 玩家名字#0000</b></t>",
		killed = "<v>[#] <r>因為你違反了 parkour 規則, 你現在被禁止在 %s 分鐘內使用你的能力。持續違反規則會導致被封禁遊玩此小遊戲。請按 <b>H鍵</b> 查看規則。",
		mapper_event = "<CE><B>Parkour地圖製作大賽 2024:</B>\n<n>在比賽中向我們展示你的製圖創意以贏得 <D>奶酪幣<n> 及 <pt>parkour 金幣<n>!\n<R>提交地圖的期限至 <B>1月 31日, 2024</B>.\n<PS>更多資訊, 可查看: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>所以要開始倒數了...",
		easter_egg_1  = "<ch>剩下時間少於 24 小時!",
		easter_egg_2  = "<ch>哇, 你挺早的! 你是不是太興奮了?",
		easter_egg_3  = "<ch>一個驚喜在等待你...",
		easter_egg_4  = "<ch>你知道接下來將會發生什麼...?",
		easter_egg_5  = "<ch>時間滴答滴答在過著...",
		easter_egg_6  = "<ch>驚喜快要到了!",
		easter_egg_7  = "<ch>派對很快要開始...",
		easter_egg_8  = "<ch>查看你的時鐘, 是時候了嗎?",
		easter_egg_9  = "<ch>注意, 時間在一直走...",
		easter_egg_10 = "<ch>坐下來放鬆一下, 馬上就到明天了!",
		easter_egg_11 = "<ch>一起早點到床上, 會使時間過得更快!",
		easter_egg_12 = "<ch>最重要是耐心",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>雙倍地圖計算將會在星期六 (GMT+2) 開始, 而且所有能力都可以在這 parkour 生日週使用!",
		double_maps_start = "<rose>這週是 PARKOUR 的生日! 雙倍地圖計算而且所有能力都已被激活使用。感謝跟我們一起遊玩!",
		double_maps_end = "<rose>Parkour 的生日週已完結。感謝各位的遊玩!",
	
		-- Records
		records_enabled = "<v>[#] <d>記錄模式已在這房間啟用。數據不會被記錄而且不能使用能力!\n你可以在這裡查看更多關於記錄模式的資訊: <b>%s</b>",
		records_admin = "<v>[#] <d>你是這房間的管理員。你可以使用以下指令 <b>!map</b>, <b>!setcp</b>, <b>!pw</b> and <b>!time</b>。",
		records_completed = "<v>[#] <d>你已經完成了地圖! 如果你想重新嘗試, 可輸入 <b>!redo</b>。",
		records_submit = "<v>[#] <d>哇! 看來你達成了房間裡最快的通關時間。如果你希望提交你的記錄, 可輸入 <b>!submit</b>。",
		records_invalid_map = "<v>[#] <r>看來這張地圖並不在 parkour 的循環裡... 你不能提交這地圖的記錄!",
		records_not_fastest = "<v>[#] <r>看來你並不是房間裡最快通關的玩家...",
		records_already_submitted = "<v>[#] <r>你已經提交了這地圖的通關時間記錄!",
		records_submitted = "<v>[#] <d>你在地圖 <b>%s</b> 的時間記錄已被提交。",
	
		-- Quests
		daily_q = "每日",
		weekly_q = "每週",
		daily_quests = "<p align='center'><font size='20'><B><D>日常任務</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>每週任務</D></B></font>",
		quest_1 = "完成 <B><D>%s/%s</D></B> 張地圖。",
		quest_2 = "到達 <B><D>%s/%s</D></B> 次重生點。",
		quest_3 = "在任何地圖中以第一名完成地圖 <B><D>%s/%s</D></B> 次。",
		quest_4 = "在 <B><D>%s</D></B> 秒內完成一張地圖。",
		quest_5 = "完成地圖 <B><D>@%s</D></B>",
		quest_6 = "使用 <PT><b>%s</b></PT> 能力 <B><D>%s/%s</D></B> 次。",
		next_reset = "<b><D>下一次重置:\n</b></D>%s",
		quest_completed = "<b><D>恭喜!</D></b> \n你已經完成了一項%s任務!",
		quest_reset = "<V>[#]</V> <O>你的%s任務已經被重置了。</O>",
	
		-- Christmas
		find_gift1 = "<ch>聖誕老人來了! 在地圖中找尋聖誕禮物然後打開看看有什麼驚喜吧!",
	    find_gift2 = "<ch>聖誕鈴聲滿路上! 有一個聖誕禮物神奇地出現在地圖上了 - 找尋它吧!",
	    find_gift3 = "<ch>呵, 呵, 呵! 聖誕老人的小助手在現在的地圖中留下了一個禮物給你找尋!",
	    find_gift4 = "<ch>空氣中充滿著濃厚的聖誕氣氛! 找出在這地圖中隱藏著的禮物吧!",
	    find_gift5 = "<ch>聖誕跑酷快樂! 小精靈們給你藏起了一份禮物。你能找到它嗎?",
	    found_gift1 = "<ch>好耶! <J>%s</J> 打開了禮物而且在裡面找到了 %s 枚金幣!",
	    found_gift2 = "<ch>好耶, <J>%s</J>! 你剛剛從聖誕老人神奇的禮物中得到了 <J>%s</J> 枚金光閃閃的金幣!",
	    found_gift3 = "<ch>是 <J>%s</J> 的勝利! 感謝聖誕老人, 他獲得了更富有的 <J>%s</J> 枚金幣!",
	    found_gift4 = "<ch>恭喜 <J>%s</J> 得到了 <J>%s</J> 枚金幣! 聖誕氣氛更濃烈了!",
	    found_gift5 = "<ch>聖誕老人的禮物賜給了 <J>%s</J> <J>%s</J> 枚非常吸引的金幣!",
	
		-- Miscellaneous
		mod_apps = "<j>Parkour 管理員申請現正開放! 請查看這連結: <rose>%s",
		afk_popup = "\n<p align='center'><font size='30'><bv><b>你正在掛機模式</b></bv>\n隨意移動來復活</font>\n\n<font size='30'><u><t>提示:</t></u></font>\n\n<font size='15'><r>玩家頭上的紅線表示他們不想被協助!\n在parkour惡作劇/阻礙其他玩家通關是不被允許的!<d>\n加入我們的 <cep><a href='event:discord'>discord 伺服器</a></cep>!\n想在編程上貢獻? 查看 <cep><a href='event:github'>github 編程庫</a></cep> 吧。\n你有好的地圖想提交嗎? 在我們的 <cep><ahref='event:map_submission'>地圖提交帖子</a></cep> 上留言吧。\n查看我們的 <cep><a href='event:forum'>官方帖子</a></cep> 來得到更多資訊!\n透過 <cep><a href='event:donate'>捐款</a></cep> 支持我們吧!",
		options = "<p align='center'><font size='20'>Parkour 選項</font></p>\n\n使用 <b>QWERTY</b> 鍵盤 (使用<b>AZERTY</b>請關閉此項)\n\n使用快捷鍵 <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> 來 <b>自殺</b> (使用<b>DEL</b>請關閉此項)\n\n顯示你的能力緩衝時間\n\n顯示能力選項按鈕\n\n顯示幫助按鈕\n\n顯示完成地圖的公告\n\n顯示不用被幫助的標示\n\n隱藏所有快捷按鈕 (排行榜, 幫助, 商店等等。)",
		cooldown = "<v>[#] <r>請等候幾秒再重新嘗試。",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> 鍵盤" ..
						 "\n\n<b>隱藏</b> 地圖通過數" ..
						 "\n\n使用 <b>預設鍵</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>完成 <v>%s</v> 張地圖" ..
						"<font size='5'>\n\n</font>來解鎖" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>完成 <v>%s</v> 張地圖" ..
						"<font size='5'>\n\n</font>來升級到" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>階級 <v>%s</v>" ..
						"<font size='5'>\n\n</font>來解鎖" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>階級 <v>%s</v>" ..
						"<font size='5'>\n\n</font>來升級到" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>完成地圖數"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>整體排行榜"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>每周排行榜"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>徽章 (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>玩家的地圖通過數已設定為私人。 <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"整體排行榜名次: <b><v>%s</v></b>\n\n" ..
					"每周排行榜名次: <b><v>%s</v></b>\n\n%s"),
		map_count = "地圖通過數: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> 完成地圖次數: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> 到達重生點次數: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "徽章是玩家可以得到的成就。點擊它們查看介紹。",
		help_private_maps = "這玩家不想公開分享他的地圖通過數! 你也可以在個人資料中設定隱藏。",
		help_yellow_maps = "黃色標示的地圖是這周完成了的地圖。",
		help_red_maps = "紅色標示的地圖是過去一小時內完成了的地圖。",
		help_map_count_title = "你可以透過完成 parkour 地圖獲得 <b>Transformice</b> 稱號!",
		help_checkpoint_count_title = "你可以透過到達 parkour 裡所有重生點獲得  <b>Transformice</b> 稱號!",
		help_badge_1 = "這玩家曾經是parkour 的職員。",
		help_badge_2 = "這玩家是或曾經達成在整體排行榜的第 1 頁上。",
		help_badge_3 = "這玩家是或曾經達成在整體排行榜的第 2 頁以上。",
		help_badge_4 = "這玩家是或曾經達成在整體排行榜的第 3 頁以上。",
		help_badge_5 = "這玩家是或曾經達成在整體排行榜的第 4 頁以上。",
		help_badge_6 = "這玩家是或曾經達成在整體排行榜的第 5 頁以上。",
		help_badge_7 = "這玩家曾經在每周排行榜中得到前三名。",
		help_badge_8 = "這玩家達成了在一小時內通過 30 張地圖的記錄。",
		help_badge_9 = "這玩家達成了在一小時內通過 35 張地圖的記錄。",
		help_badge_10 = "這玩家達成了在一小時內通過 40 張地圖的記錄。",
		help_badge_11 = "這玩家達成了在一小時內通過 45 張地圖的記錄。",
		help_badge_12 = "這玩家達成了在一小時內通過 50 張地圖的記錄。",
		help_badge_13 = "這玩家達成了在一小時內通過 55 張地圖的記錄。",
		help_badge_14 = "這玩家已經在官方 parkour discord 伺服器上驗證了帳戶 (輸入 <b>!discord</b>)。",
		help_badge_15 = "這玩家以最快的時間完成了 1 張地圖。",
		help_badge_16 = "這玩家以最快的時間完成了 5 張地圖。",
		help_badge_17 = "這玩家以最快的時間完成了 10 張地圖。",
		help_badge_18 = "這玩家以最快的時間完成了 15 張地圖。",
		help_badge_19 = "這玩家以最快的時間完成了 20 張地圖。",
		help_badge_20 = "這玩家以最快的時間完成了 25 張地圖。",
		help_badge_21 = "這玩家以最快的時間完成了 30 張地圖。",
		help_badge_22 = "這玩家以最快的時間完成了 35 張地圖。",
		help_badge_23 = "這玩家以最快的時間完成了 40 張地圖。",
		make_public = "設定為公開",
		make_private = "設定為私人",
		moderators = "管理員",
		mappers = "地圖管理員",
		managers = "小隊主管",
		administrators = "工作人員",
		close = "關閉",
		cant_load_bot_profile = "<v>[#] <r>你不能查看這機器人的個人資料因為 #parkour 利用它來進行內部運作。",
		cant_load_profile = "<v>[#] <r>玩家 <b>%s</b> 看來不在線或是不存在。",
		like_map = "你喜歡這地圖嗎?",
		yes = "是",
		no = "不是",
		idk = "我不知道",
		vote_map = "<font color='#ffffff' size='13'><b>你喜歡這地圖嗎? <font size='14'><a href='event:mapPollYes'><PT>是</a> <a href='event:mapPollidk'><N>我不知道</a> <a href='event:mapPollNo'><R>不是</a>",
		unknown = "不明物",
		powers = "能力",
		press = "<vp>按 %s",
		click = "<vp>左鍵點擊",
		ranking_pos = "排名 #%s",
		completed_maps = "<p align='center'><BV><B>完成的地圖數: %s</B></p></BV>",
		leaderboard = "排行榜",
		position = "<V><p align=\"center\">位置",
		username = "<V><p align=\"center\">用戶名",
		community = "<V><p align=\"center\">社區",
		completed = "<V><p align=\"center\">完成地圖數",
		overall_lb = "主要排名",
		weekly_lb = "每周排名",
		new_lang = "<v>[#] <d>語言已被更換成 繁體中文",
		room = "房間",
		time = "時間",
		buy = "Buy",
		equip = "Equip",
		equipped = "Equipped",
		buy = "買",
		equip = "裝備",
		equipped = "已裝備",
		saving = "<p align='right'>儲存中...",
	
	
		-- Power names
		balloon = "氣球",
		masterBalloon = "氣球 II",
		bubble = "氣球 III",
		fly = "飛行",
		snowball = "雪球",
		speed = "加速",
		teleport = "傳送",
		smallbox = "小箱子",
		cloud = "白雲",
		rip = "墓碑",
		choco = "巧克力棒",
		bigBox = "大箱子",
		trampoline = "彈床",
		toilet = "馬桶",
		pig = "豬",
		sink = "洗手盤",
		bathtub = "浴缸",
		campfire = "營火",
		chair = "椅子",
		link = "伴侣",
	
	}
	translations.ch = translations.cn
	--[[ End of file translations/parkour/cn.lua ]]--
	--[[ File translations/parkour/en.lua ]]--
	translations.en = {
		name = "en",
		fullname = "English",
	
		-- Error messages
		corrupt_map = "<r>Corrupt map. Loading another.",
		corrupt_map_no_perm = "<r>[ERROR] <n>This map is not protected properly.",
		corrupt_map_hole = "<r>[ERROR] <n>Parkour maps cannot contain a mouse hole.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Can not get information of this map.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>This map needs to have a start position (mouse spawn point).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>The map needs to have the end chair.",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>The map needs to have at least one checkpoint (yellow nail).",
		corrupt_data = "<r>Unfortunately, your data was corrupt and has been reset.",
		min_players = "<r>To save your data, there must be at least 4 unique players in the room. <bl>[%s/%s]",
		tribe_house = "<r>Data will not be saved in tribehouses.",
		invalid_syntax = "<r>Invalid syntax.",
		code_error = "<r>An error appeared: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Initiating emergency shutdown, no new players allowed. Please go to another #parkour room.",
		leaderboard_not_loaded = "<r>The leaderboard has not been loaded yet. Wait a minute.",
		max_power_keys = "<v>[#] <r>You can only have at most %s powers in the same key.",
		room_name_length = "<ROSE><b>[ERROR]</b> The room name exceeds the allowed length of <b>45</b> characters. Please choose a shorter name.",
	
		-- Help window
		help = "Help",
		staff = "Staff",
		rules = "Rules",
		contribute = "Contribute",
		changelog = "News",
		help_help = "<p align = 'center'><font size = '14'>Welcome to <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Your goal is to reach all the checkpoints until you complete the map.</J></p>\n\n<N>• Press <O>O</O>, type <O>!op</O> or click the <O>configuration button</O> to open the <T>options menu</T>.\n• Press <O>P</O> or click the <O>hand icon</O> at the top-right to open the <T>powers menu</T>.\n• Press <O>L</O> or type <O>!lb</O> to open the <T>leaderboard</T>.\n• Press the <O>M</O> or <O>Delete</O> key to <T>/mort</T>, you can toggle the keys in the <J>Options</J> menu.\n• To know more about our <O>staff</O> and the <O>rules of parkour</O>, click on the <T>Staff</T> and <T>Rules</T> tab respectively.\n• Click <a href='event:discord'><o>here</o></a> to get the discord invite link and <a href='event:map_submission'><o>here</o></a> to get the map submission topic link.\n• Use <o>up</o> and <o>down</o> arrow keys when you need to scroll.\n\n<p align = 'center'><font size = '13'><T>Contributions are now open! For further details, click on the <O>Contribute</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Parkour staff ARE NOT Transformice staff and DO NOT have any power in the game itself, only within the module.</r>\nParkour staff ensure that the module runs smoothly with minimal issues, and are always available to assist players whenever necessary.</font></p>\nYou can type <D>!staff</D> in the chat to see the staff list.\n\n<font color = '#E7342A'>Administrators:</font> They are responsible for maintaining the module itself by adding new updates and fixing bugs.\n\n<font color = '#D0A9F0'>Team Managers:</font> They oversee the Moderator and Mapper teams, making sure they are performing their jobs well. They are also responsible for recruiting new members to the staff team.\n\n<font color = '#FFAAAA'>Moderators:</font> They are responsible for enforcing the rules of the module and punishing individuals who do not follow them.\n\n<font color = '#25C059'>Mappers:</font> They are responsible for reviewing, adding, and removing maps within the module to ensure that you have an enjoyable gameplay.",
		help_rules = "<font size = '13'><B><J>All rules in the Transformice Terms and Conditions also apply to #parkour</J></B></font>\n\nIf you find any player breaking these rules, whisper the parkour mods in-game. If no mods are online, then it is recommended to report it in the discord server.\nWhen reporting, please include the server, room name, and player name.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidence, such as screenshots, videos and gifs are helpful and appreciated, but not necessary.\n\n<font size = '11'>• No <font color = '#ef1111'>hacks, glitches or bugs</font> are to be used in #parkour rooms\n• <font color = '#ef1111'>VPN farming</font> will be considered an <B>exploit</B> and is not allowed. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nAnyone caught breaking these rules will be immediately banned.</B></font></p>\n\n<font size = '12'>Transformice allows the concept of trolling. However, <font color='#cc2222'><B>we will not allow it in parkour.</B></font></font>\n\n<p align = 'center'><J>Trolling is when a player intentionally uses their powers or consumables to prevent other players from finishing the map.</j></p>\n• Revenge trolling is <B>not a valid reason</B> to troll someone and you will still be punished.\n• Forcing help onto players trying to solo the map and refusing to stop when asked is also considered trolling.\n• <J>If a player does not want help or prefers to solo a map, please try your best to help other players</J>. However if another player needs help in the same checkpoint as the solo player, you can help them [both].\n\nIf a player is caught trolling, they will be punished on a time basis. Note that repeated trolling will lead to longer and more severe punishments.",
		help_contribute = "<font size='14'>\n<p align='center'>The parkour management team loves open source code because it <t>helps the community</t>. You can <o>view</o> and <o>modify</o> the source code on <o><u><a href='event:github'>GitHub</a></u></o>.\n\nMaintaining the module is <t>strictly voluntary</t>, so any help regarding <t>code</t>, <t>bug reports</t>, <t>suggestions</t> and <t>creating maps</t> is always <u>welcome and appreciated</u>.\nYou can <vp>report bugs</vp> and <vp>give suggestions</vp> on <o><u><a href='event:discord'>Discord</a></u></o> and/or <o><u><a href='event:github'>GitHub</a></u></o>.\nYou can <vp>submit your maps</vp> in our <o><u><a href='event:map_submission'>Forum Thread</a></u></o>.\n\nMaintaining parkour is not expensive, but it is not free either. We'd love if you could help us by <t>donating any amount</t> <o><u><a href='event:donate'>here</a></u></o>.\n<u>All donations will go towards improving the module.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Quest system implemented. (Press <J><B>,</B></J> to open the quest page.)\n\n<font size='11'>• <font size='13'>Added an option to disable hotkeys for all interfaces like leaderboard, help, shop etc.\n\n<font size='11'>• <font size='13'>Added the <B><J>!cp [PlayerName#tag]</J></B> command to set your current checkpoint as the specified player's checkpoint.",
		
		-- Congratulation messages
		reached_level = "<d>Congratulations! You've completed level <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> finished the parkour in <vp>%s</vp> seconds, <fc>congratulations!",
		unlocked_power = "<ce><d>%s</d> unlocked the <vp>%s</vp> power.",
	
		-- Information messages
		mod_apps = "<j>Parkour moderator applications are now open! Use this link: <rose>%s",
		staff_power = "<p align='center'><font size='12'><r>Parkour staff <b>do not</b> have any power outside of #parkour rooms.",
		donate = "<vp>Type <b>!donate</b> if you would like to donate for this module!",
		paused_events = "<cep><b>[Warning!]</b> <n>The module has reached it's critical limit and is being paused.",
		resumed_events = "<n2>The module has been resumed.",
		welcome = "<n>Welcome to <t>#parkour</t>!",
		module_update = "<r><b>[Warning!]</b> <n>The module will update in <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>The leaderboard has been loaded. Press L to open it.",
		kill_minutes = "<R>Your powers have been disabled for %s minutes.",
		permbanned = "<r>You have been permanently banned from #parkour.",
		tempbanned = "<r>You have been banned from #parkour for %s minutes.",
		forum_topic = "<rose>For more information about the module visit this link: %s",
		report = "<j>Want to report a parkour player? <t><b>/c Parkour#8558 .report Username#0000</b></t>",
		killed = "<v>[#] <r>You are restricted from using your powers for %s minutes due to your violation of parkour rules. Continued rule violations will result in a ban. Please press <b>H</b> to review the rules.",
		mapper_event = "<CE><B>Parkour mapmaking contest 2024:</B>\n<n>Show us your creativity in map-making for a chance to win <D>cheese coins <n>and <pt>parkour coins<n>!\n<R>Submissions open until <B>January 31, 2024</B>.\n<PS>For more information, visit: %s",
		cmd_usage_report = "<j>Usage: <bl>!report [Player#1234] [reason]",
		reported_not_here = "<bl>Reported player must be in this room.",
		reported_invalid = "<bl>This player cannot be reported.",
		reason_too_short = "<bl>Report reason is too short.",
		report_done = "<j>Thank you for your report.",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Finally the countdown begins...",
		easter_egg_1  = "<ch>Less than 24 hours remaining!",
		easter_egg_2  = "<ch>Woah, you're quite early! Aren't you too excited?",
		easter_egg_3  = "<ch>A surprise is waiting...",
		easter_egg_4  = "<ch>Do you know what's about to happen...?",
		easter_egg_5  = "<ch>The clock keeps ticking...",
		easter_egg_6  = "<ch>The time is near!",
		easter_egg_7  = "<ch>The party is about to begin...",
		easter_egg_8  = "<ch>Check your clock, is it time yet?",
		easter_egg_9  = "<ch>Be careful, time is passing...",
		easter_egg_10 = "<ch>Just sit back and relax, it'll be tomorrow in no time!",
		easter_egg_11 = "<ch>Let's go to bed early, it'll make the time go faster!",
		easter_egg_12 = "<ch>Patience is a virtue",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		anniversary = "<bv>Double parkour coins next week (France time) and all powers are available for parkour's birthday week!",
		anniversary_start = "<rose>IT'S PARKOUR'S BIRTHDAY WEEK! Double parkour coins and all powers have been activated. Thank you for all the support and for playing this module!",
		anniversary_end = "<rose>Parkour's birthday week has ended. Thank you for all the support and for playing this module!",
	
		-- Records
		records_enabled = "<v>[#] <d>Records mode is enabled in this room. Stats won't count and powers aren't enabled!\nYou can find more information about records in <b>%s</b>",
		records_admin = "<v>[#] <d>You're an administrator of this records room. You can use the commands <b>!map</b>, <b>!setcp</b>, <b>!pw</b> and <b>!time</b>.",
		records_completed = "<v>[#] <d>You've completed the map! If you would like to re-do it, type <b>!redo</b>.",
		records_submit = "<v>[#] <d>Wow! Looks like you had the fastest time in the room. If you would like to submit your record, type <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Looks like this map is not in parkour rotation... You can't submit a record for it!",
		records_not_fastest = "<v>[#] <r>Looks like you're not the fastest player in the room...",
		records_already_submitted = "<v>[#] <r>You already submitted your record for this map!",
		records_submitted = "<v>[#] <d>Your record for the map <b>%s</b> has been submitted.",
	
		-- Quests
		daily_q = "Daily",
		weekly_q = "Weekly",
		daily_quests = "<p align='center'><font size='20'><B><D>Daily Quests</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Weekly Quests</D></B></font>",
		quest_1 = "Complete <B><D>%s/%s</D></B> maps.",
		quest_2 = "Collect <B><D>%s/%s</D></B> checkpoints.",
		quest_3 = "Complete any map in first place <B><D>%s/%s</D></B> times.",
		quest_4 = "Complete a map in under <B><D>%s</D></B> seconds.",
		quest_5 = "Complete the map <B><D>@%s</D></B>",
		quest_6 = "Use the <PT><b>%s</b></PT> power <B><D>%s/%s</D></B> times.",
		next_reset = "<b><D>Reset:\n</b></D>%s",
		quest_completed = "<b><D>Congratulations!</D></b> \nYou've completed a %s quest!",
		quest_reset = "<V>[#]</V> <O>Your %s quests have been reset.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Santa has just dropped by! Hunt for the Christmas gift on the map and unwrap a surprise!",
		find_gift2 = "<ch>Jingle all the way! A special Christmas gift has magically appeared on the map – go find it!",
		find_gift3 = "<ch>Ho, ho, ho! Santa's little helper has left a gift for you to find on the current map!",
		find_gift4 = "<ch>The Christmas spirit is in the air! Find the Christmas gift hidden on this map!",
		find_gift5 = "<ch>Merry Parkourmas! The elves have hidden a gift for you. Can you find it?",
		found_gift1 = "<ch>Hooray! <J>%s</J> has unwrapped the gift and found %s coins inside!",
		found_gift2 = "<ch>Hurray, <J>%s</J>! You have just won <J>%s</J> shiny coins from Santa's magical gift!",
		found_gift3 = "<ch>It's a win for <J>%s</J>! <J>%s</J> coins richer thanks to Santa!",
		found_gift4 = "<ch>Congratulations to <J>%s</J> on winning <J>%s</J> coins! The Christmas spirit is shining bright!",
		found_gift5 = "<ch>Santa's gift has bestowed <J>%s</J> with <J>%s</J> dazzling coins!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>YOU'RE ON AFK MODE</b></bv>\nMOVE TO RESPAWN</font>\n\n<font size='30'><u><t>Reminders:</t></u></font>\n\n<font size='15'><r>Players with a red line over them don't want help!\nTrolling/blocking other players in parkour is NOT allowed!<d>\nJoin our <cep><a href='event:discord'>discord server</a></cep>!\nWant to contribute with code? See our <cep><a href='event:github'>github repository</a></cep>\nDo you have a good map to submit? Post it in our <cep><a href='event:map_submission'>map submission topic</a></cep>\nCheck our <cep><a href='event:forum'>official topic</a></cep> for more information!\nSupport us by <cep><a href='event:donate'>donating!</a></cep>",
		options = "<p align='center'><font size='20'>Parkour Options</font></p>\n\nUse <b>QWERTY</b> keyboard (disable if <b>AZERTY</b>)\n\nUse <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> hotkey for <b>/mort</b> (disable for <b>DEL</b>)\n\nShow your power cooldowns\n\nShow powers button\n\nShow help button\n\nShow map completion announcements\n\nShow no help symbol\n\nDisable hotkeys for all interfaces (leaderboard, help, shop, etc.)",
		cooldown = "<v>[#] <r>Wait a few seconds before doing that again.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> keyboard" ..
						 "\n\n<b>Hide</b> map count" ..
						 "\n\nUse <b>default key</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complete <v>%s</v> maps" ..
						"<font size='5'>\n\n</font>to unlock" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complete <v>%s</v> maps" ..
						"<font size='5'>\n\n</font>to upgrade to" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Rank <v>%s</v>" ..
						"<font size='5'>\n\n</font>to unlock" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Rank <v>%s</v>" ..
						"<font size='5'>\n\n</font>to upgrade to" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Completed Maps"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Overall Leaderboard"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Weekly Leaderboard"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Badges (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>This player's map count is private. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Overall leaderboard position: <b><v>%s</v></b>\n\n" ..
					"Weekly leaderboard position: <b><v>%s</v></b>\n\n%s"),
		map_count = "Map count: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Finished maps: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Collected checkpoints: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Badges are accomplishments a player can get. Click over them to see their description.",
		help_private_maps = "This player doesn't like to share their map count publicly! You can hide them too in your profile.",
		help_yellow_maps = "Maps in yellow are the maps completed this week.",
		help_red_maps = "Maps in red are the maps completed in the past hour.",
		help_map_count_title = "You can get <b>Transformice</b> titles by completing parkour maps!",
		help_checkpoint_count_title = "You can get <b>Transformice</b> titles by collecting all checkpoints in parkour maps!",
		help_badge_1 = "This player has been a parkour staff member in the past.",
		help_badge_2 = "This player is or was in the page 1 of the overall leaderboard.",
		help_badge_3 = "This player is or was in the page 2 of the overall leaderboard.",
		help_badge_4 = "This player is or was in the page 3 of the overall leaderboard.",
		help_badge_5 = "This player is or was in the page 4 of the overall leaderboard.",
		help_badge_6 = "This player is or was in the page 5 of the overall leaderboard.",
		help_badge_7 = "This player has been in the podium of the weekly leaderboard when it has reset.",
		help_badge_8 = "This player has got a record of 30 maps per hour.",
		help_badge_9 = "This player has got a record of 35 maps per hour.",
		help_badge_10 = "This player has got a record of 40 maps per hour.",
		help_badge_11 = "This player has got a record of 45 maps per hour.",
		help_badge_12 = "This player has got a record of 50 maps per hour.",
		help_badge_13 = "This player has got a record of 55 maps per hour.",
		help_badge_14 = "This player has verified their discord account in the official parkour server (type <b>!discord</b>).",
		help_badge_15 = "This player has got the fastest time in 1 map.",
		help_badge_16 = "This player has got the fastest time in 5 maps.",
		help_badge_17 = "This player has got the fastest time in 10 maps.",
		help_badge_18 = "This player has got the fastest time in 15 maps.",
		help_badge_19 = "This player has got the fastest time in 20 maps.",
		help_badge_20 = "This player has got the fastest time in 25 maps.",
		help_badge_21 = "This player has got the fastest time in 30 maps.",
		help_badge_22 = "This player has got the fastest time in 35 maps.",
		help_badge_23 = "This player has got the fastest time in 40 maps.",
		make_public = "make public",
		make_private = "make private",
		moderators = "Moderators",
		mappers = "Mappers",
		managers = "Managers",
		administrators = "Administrators",
		close = "Close",
		cant_load_bot_profile = "<v>[#] <r>You can't see this bot's profile since #parkour uses it internally to work properly.",
		cant_load_profile = "<v>[#] <r>The player <b>%s</b> seems to be offline or does not exist.",
		like_map = "Do you like this map?",
		yes = "Yes",
		no = "No",
		idk = "I don't know",
		vote_map = "<font color='#ffffff' size='13'><b>Do you like this map? <font size='14'><a href='event:mapPollYes'><PT>Yes</a> <a href='event:mapPollidk'><N>I don't know</a> <a href='event:mapPollNo'><R>No</a>",
		unknown = "Unknown",
		powers = "Powers",
		press = "<vp>Press %s",
		click = "<vp>Left click",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Completed maps: %s</B></p></BV>",
		leaderboard = "Leaderboard",
		position = "<V><p align=\"center\">Position",
		username = "<V><p align=\"center\">Username",
		community = "<V><p align=\"center\">Community",
		completed = "<V><p align=\"center\">Completed maps",
		overall_lb = "Overall",
		weekly_lb = "Weekly",
		new_lang = "<v>[#] <d>Language set to English",
		room = "Room",
		time = "Time",
		buy = "Buy",
		equip = "Equip",
		equipped = "<font size = '10'>Equipped</font>",
		saving = "<p align='right'>Saving...",
		new_image = "<J>Your appearance has been changed. You can turn it back to normal by typing !image",
	
		-- Power names
		balloon = "Balloon",
		masterBalloon = "Balloon II",
		bubble = "Balloon III",
		fly = "Fly",
		snowball = "Snowball",
		speed = "Speed",
		teleport = "Teleport",
		smallbox = "Small box",
		cloud = "Cloud",
		rip = "Tombstone",
		choco = "Chocoplank",
		bigBox = "Big box",
		trampoline = "Trampoline",
		toilet = "Toilet",
		pig = "Piglet",
		sink = "Sink",
		bathtub = "Bathtub",
		campfire = "Campfire",
		chair = "Chair",
		link = "Soul mate",
	}
	--[[ End of file translations/parkour/en.lua ]]--
	--[[ File translations/parkour/es.lua ]]--
	translations.es = {
		name = "es",
		fullname = "Español",
	
		-- Error messages
		corrupt_map = "<r>Mapa corrupto. Cargando otro.",
		corrupt_map_vanilla = "<r>[ERROR] <n>No se pudo obtener información de este mapa.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>El mapa tiene que tener un punto de inicio de los ratones.",
		corrupt_map_needing_chair = "<r>[ERROR] <n>El mapa tiene que tener el sillón del final.",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>El mapa tiene que tener al menos un checkpoint (anclaje amarillo).",
		corrupt_data = "<r>Tristemente, tus datos estaban corruptos. Se han reiniciado.",
		min_players = "<r>Para guardar datos, deben haber al menos 4 jugadores únicos en la sala. <bl>[%s/%s]",
		tribe_house = "<r>Para guardar datos, debes jugar fuera de una casa de tribu.",
		invalid_syntax = "<r>Sintaxis inválida.",
		code_error = "<r>Apareció un error: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Empezando apagado de emergencia, no se admiten más jugadores. Por favor ve a otra sala #parkour.",
		leaderboard_not_loaded = "<r>La tabla de clasificación aun no ha sido cargada. Espera un minuto.",
		max_power_keys = "<v>[#] <r>Solo puedes tener como máximo %s poderes en la misma tecla.",
	
		-- Help window
		help = "Ayuda",
		staff = "Staff",
		rules = "Reglas",
		contribute = "Contribuir",
		changelog = "Novedades",
		help_help = "<p align = 'center'><font size = '14'>¡Bienvenido a <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Tu objetivo es alcanzar todos los checkpoints hasta que completes el mapa.</J></p>\n\n<N>• Presiona la tecla <O>O</O>, escribe <O>!op</O> o clickea el <O>botón de configuración</O> para abrir el <T>menú de opciones</T>.\n• Presiona la tecla <O>P</O> o clickea el <O>ícono de la mano</O> arriba a la derecha para abrir el <T>menú de poderes</T>.\n• Presiona la tecla <O>L</O> o escribe <O>!lb</O> para abrir el <T>ranking</T>.\n• Presiona la tecla <O>M</O> o <O>Delete</O> como atajo para <T>/mort</T>, podes alternarlas en el menú de <J>Opciones</J>.\n• Para conocer más acerca de nuestro <O>staff</O> y las <O>reglas de parkour</O>, clickea en las pestañas de <T>Staff</T> y <T>Reglas</T>.\n• Click <a href='event:discord'><o>here</o></a> to get the discord invite link and <a href='event:map_submission'><o>here</o></a> to get the map submission topic link.\n• Use <o>up</o> and <o>down</o> arrow keys when you need to scroll.\n\n<p align = 'center'><font size = '13'><T>¡Las contribuciones están abiertas! Para más detalles, ¡clickea en la pestaña <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>NOTA: El staff de Parkour NO ES staff de Transformice y NO TIENEN ningún poder en el juego, sólamente dentro del módulo.</r>\nEl staff de Parkour se asegura de que el módulo corra bien con la menor cantidad de problemas, y siempre están disponibles para ayudar a los jugadores cuando sea necesario.</font></p>\nPuedes escribir <D>!staff</D> en el chat para ver la lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> Son los responsables de mantener el módulo añadiendo nuevas actualizaciones y arreglando bugs.\n\n<font color = '#D0A9F0'>Lideres de Equipos:</font> Ellos supervisan los equipos de Moderadores y Mappers, asegurándose de que hagan un buen trabajo. También son los responsables de reclutar nuevos miembros al staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> Son los responsables de ejercer las reglas del módulo y sancionar a quienes no las sigan.\n\n<font color = '#25C059'>Mappers:</font> Son los responsables de revisar, añadir y quitar mapas en el módulo para asegurarse de que tengas un buen gameplay.",
		help_rules = "<font size = '13'><B><J>Todas las reglas en los Terminos y Condiciones de Transformice también aplican a #parkour</J></B></font>\n\nSi encuentras algún jugador rompiendo estas reglas, susurra a los moderadores de parkour en el juego. Si no hay moderadores online, es recomendable reportarlo en discord.\nCuando reportes, por favor agrega el servidor, el nombre de la sala, y el nombre del jugador.\n• Ej: en-#parkour10 Blank#3495 trollear\nEvidencia, como fotos, videos y gifs ayudan y son apreciados, pero no son necesarios.\n\n<font size = '11'>• No se permite el uso de <font color = '#ef1111'>hacks, glitches o bugs</font>\n• <font color = '#ef1111'>Farmear con VPN</font> será considerado un <B>abuso</B> y no está permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nCualquier persona rompiendo estas reglas será automáticamente baneado.</B></font></p>\n\n<font size = '12'>Transformice acepta el concepto de trollear. Pero <font color='#cc2222'><B>no está permitido en #parkour.</B></font></font>\n\n<p align = 'center'><J>Trollear es cuando un jugador intencionalmente usa sus poderes o consumibles para hacer que otros jugadores no completen el mapa.</j></p>\n• Trollear como venganza <B>no es una razón válida</B> para trollear a alguien y aún así seras sancionado.\n• Ayudar a jugadores que no quieren completar el mapa con ayuda y no parar cuando te lo piden también es considerado trollear.\n• <J>Si un jugador no quiere ayuda, por favor ayuda a otros jugadores</J>. Sin embargo, si otro jugador necesita ayuda en el mismo punto, puedes ayudarlos [a los dos].\n\nSi un jugador es atrapado trolleando, será sancionado en base de tiempo. Trollear repetidas veces llevará a sanciones más largas y severas.",
		help_contribute = "<font size='14'>\n<p align='center'>El equipo de administración de parkour ama el codigo abierto porque <t>ayuda a la comunidad</t>. Podés <o>ver</o> y <o>modificar</o> el código de parkour en <o><u><a href='event:github'>GitHub</a></u></o>.\n\nMantener el módulo es <t>estrictamente voluntario</t>, por lo que cualquier ayuda con respecto al <t>código</t>, <t>reportes de bugs</t>, <t>sugerencias</t> y <t>creación de mapas</t> siempre será <u>bienvenida y apreciada</u>.\nPodés <vp>reportar bugs</vp> y <vp>dar sugerencias</vp> en <o><u><a href='event:discord'>Discord</a></u></o> y/o <o><u><a href='event:github'>GitHub</a></u></o>.\nPodés <vp>enviar tus mapas</vp> en nuestro <o><u><a href='event:map_submission'>Hilo del Foro</a></u></o>.\n\nMantener parkour no es caro, pero tampoco es gratis. Realmente apreciaríamos si pudieras ayudarnos <t>donando cualquier cantidad</t> <o><u><a href='event:donate'>aquí</a></u></o>.\n<u>Todas las donaciones serán destinadas a mejorar el módulo.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Versión 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Se implementó un sistema de misiones. (Presiona <J><B>,</B></J> para abrir el panel de misiones.)\n\n<font size='11'>• <font size='13'>Se añadió una opción para desactivar todas las teclas espciales como ranking, ayuda, tienda, etc.\n\n<font size='11'>• <font size='13'>Se añadió el comando <B><J>!cp [PlayerName#tag]</J></B> para ir al checkpoint del jugador especificado.",
	
		-- Congratulation messages
		reached_level = "<d>¡Felicitaciones! Completaste el nivel <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> completó el parkour en <vp>%s</vp> segundos, <fc>¡felicitaciones!",
		unlocked_power = "<ce><d>%s</d> desbloqueó el poder <vp>%s<ce>.",
	
		-- Information messages
		mod_apps = "<j>¡Las aplicaciones para moderador de parkour están abiertas! Usa este link: <rose>%s",
		staff_power = "<r>El staff de Parkour <b>no tiene</b> ningún poder afuera de las salas de #parkour.",
		donate = "<vp>¡Escribe <b>!donate</b> si te gustaría donar a este módulo!",
		paused_events = "<cep><b>[¡Advertencia!]</b> <n>El módulo está entrando en estado crítico y está siendo pausado.",
		resumed_events = "<n2>El módulo ha sido reanudado.",
		welcome = "<n>¡Bienvenido a <t>#parkour</t>!",
		module_update = "<r><b>[¡Advertencia!]</b> <n>El módulo se actualizará en <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>La tabla de clasificación ha sido cargada. Presiona L para abrirla.",
		kill_minutes = "<R>Tus poderes fueron desactivados por %s minutos.",
		permbanned = "<r>Has sido baneado permanentemente de #parkour.",
		tempbanned = "<r>Has sido baneado de #parkour por %s minutos.",
		forum_topic = "<rose>Para más información del módulo visita este link: %s",
		report = "<j>¿Quieres reportar a un jugador de parkour? <t><b>/c Parkour#8558 .report Usuario#0000</b></t>",
		killed = "<v>[#] <r>Tienes restringido el uso de tus poderes por %s minutos debido tus violaciones de las reglas de parkour. Las infracciones continuas resultarán en un baneo. Presiona <b>H</b> para revisar las reglas.",
		mapper_event = "<CE><B>Concurso de creación de mapas de Parkour 2024:</B>\n<n>¡Muéstranos tu creatividad al crear mapas para tener una posibilidad de ganar <D>quesos <n>y <pt>monedas<n>!\n<R>Inscripciones abiertas hasta el <B>31 de enero de 2024</B>.\n<PS>Para más información, visita: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>La cuenta atrás empezó...",
		easter_egg_1  = "<ch>¡Faltan menos de 24 horas!",
		easter_egg_2  = "<ch>¡Wow, viniste temprano! ¿Estás emocionado?",
		easter_egg_3  = "<ch>Una sorpresa nos espera...",
		easter_egg_4  = "<ch>¿Ya sabes lo que está a punto de pasar...?",
		easter_egg_5  = "<ch>El reloj sigue contando...",
		easter_egg_6  = "<ch>¡La sorpresa se acerca!",
		easter_egg_7  = "<ch>La fiesta está por comenzar...",
		easter_egg_8  = "<ch>Mira tu reloj, ¿ya es hora?",
		easter_egg_9  = "<ch>Ten cuidado, el tiempo pasa rápido...",
		easter_egg_10 = "<ch>Siéntate y relájate, ¡ya será mañana en poco tiempo!",
		easter_egg_11 = "<ch>Iré a dormir temprano, ¡el tiempo pasará más rápido!",
		easter_egg_12 = "<ch>La paciencia es una virtud",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Los mapas cuentan doble el sábado (GMT+2) y todos los poderes están activados por la semana del cumpleaños de parkour!",
		double_maps_start = "<rose>¡ES EL CUMPLEAÑOS DE PARKOUR! Los mapas cuentan doble y todos los poderes están disponibles. ¡Muchas gracias por jugar con nosotros!",
		double_maps_end = "<rose>El cumpleaños de parkour acaba de terminar. ¡Muchas gracias por jugar con nosotros!",
	
		-- Records
		records_enabled = "<v>[#] <d>El modo de récords está activado en esta sala. ¡Las estadísticas no cuentan y los poderes están desactivados!\nPuedes encontrar más información sobre récords en <b>%s</b>",
		records_admin = "<v>[#] <d>Eres un administrador de esta sala de récords. Puedes usar los comandos <b>!map</b>, <b>!setcp</b>, <b>!pw</b> y <b>!time</b>.",
		records_completed = "<v>[#] <d>¡Completaste el mapa! Si te gustaría rehacerlo, escribe <b>!redo</b>.",
		records_submit = "<v>[#] <d>¡Wow! Parece que completaste el mapa con el tiempo más rápido en la sala. Si te gustaría enviar tu record, escribe <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Parece que este mapa no está en la rotación de parkour... ¡No puedes enviar un récord en el!",
		records_not_fastest = "<v>[#] <r>Parece que no eres el más rápido en la sala...",
		records_already_submitted = "<v>[#] <r>¡Ya enviaste un récord para este mapa!",
		records_submitted = "<v>[#] <d>Tu récord para el mapa <b>%s</b> ha sido enviado.",
	
		-- Quests
		daily_q = "Diaria",
		weekly_q = "Semanal",
		daily_quests = "<p align='center'><font size='20'><B><D>Misiones Diarias</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Misiones Semanales</D></B></font>",
		quest_1 = "Completar <B><D>%s/%s</D></B> mapas.",
		quest_2 = "Conseguir <B><D>%s/%s</D></B> checkpoints.",
		quest_3 = "Completa un mapa en primer lugar <B><D>%s/%s</D></B> veces.",
		quest_4 = "Completa un mapa en menos de <B><D>%s</D></B> segundos.",
		quest_5 = "Completa el mapa <B><D>@%s</D></B>",
		quest_6 = "Usa el poder <PT><b>%s</b></PT> <B><D>%s/%s</D></B> veces.",
		next_reset = "<b><D>Reinicio:\n</b></D>%s",
		quest_completed = "<b><D>¡Felicitaciones!</D></b> \n¡Completaste una misión %s!",
		quest_reset = "<V>[#]</V> <O>Tus misiones %s fueron reiniciadas.</O>",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>ESTÁS EN MODO AFK</b></bv>\nMUÉVETE PARA REAPARECER</font>\n\n<font size='30'><u><t>Recordatorios:</t></u></font>\n\n<font size='15'><r>¡Los jugadores con una línea roja sobre ellos no quieren ayuda!\n¡Trollear/bloquear a otros jugadores en parkour NO está permitido!<d>\n¡Únete a nuestro <cep><a href='event:discord'>servidor de discord</a></cep>!\n¿Quieres contribuir con código? Vé a nuestro <cep><a href='event:github'>repositorio de github</a></cep>\n¿Tienes un buen mapa para enviar? Envíalo a nuestro <cep><a href='event:map_submission'>hilo de presentaciones de mapas</a></cep>\n¡Checkea nuestro <cep><a href='event:forum'>hilo oficial</a></cep> para más información!\n¡Ayúdanos <cep><a href='event:donate'>donando!</a></cep>",
		options = "<p align='center'><font size='20'>Opciones de Parkour</font></p>\n\nUsar teclado <b>QWERTY</b> (desactivar si usas <b>AZERTY</b>)\n\nUsar la tecla <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> como atajo para <b>/mort</b> (desactivar si usas <b>DEL</b>)\n\nMostrar tiempos de espera de tus poderes\n\nMostrar el botón de poderes\n\nMostrar el botón de ayuda\n\nMostrar mensajes al completar un mapa\n\nMostrar indicador para no recibir ayuda\n\nDesactivar teclas para todas las interfaces (ranking, ayuda, tienda, etc.)",
		cooldown = "<v>[#] <r>Espera unos segundos antes de hacer eso de nuevo.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'>Teclado <b>QWERTY</b>" ..
						 "\n\n<b>Esconder</b> cantidad de mapas" ..
						 "\n\nUsar <b>tecla original</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Completa <v>%s</v> mapas" ..
						"<font size='5'>\n\n</font>para desbloquear" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Completa <v>%s</v> mapas" ..
						"<font size='5'>\n\n</font>para mejorar a" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Posición <v>%s</v>" ..
						"<font size='5'>\n\n</font>para desbloquear" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Posición <v>%s</v>" ..
						"<font size='5'>\n\n</font>para mejorar a" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Mapas Completados"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Posición General"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Posición Semanal"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Insignias (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>La cantidad de mapas de este jugador es privada. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Posición general: <b><v>%s</v></b>\n\n" ..
					"Posición semanal: <b><v>%s</v></b>\n\n%s"),
		map_count = "Cantidad de mapas: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Mapas completados: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Checkpoints obtenidos: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Las insignias son logros que un usuario puede obtener. Clickéalas para ver su descripción.",
		help_private_maps = "¡A este jugador no le gusta compartir su cantidad de mapas! Podés esconder la tuya en tu perfil.",
		help_yellow_maps = "Los mapas en amarillo fueron completados en esta semana.",
		help_red_maps = "Los mapas en rojo fueron completados en la última hora.",
		help_map_count_title = "¡Puedes obtener títulos al completar mapas de parkour!",
		help_checkpoint_count_title = "¡Puedes obtener títulos al agarrar todos los checkpoints jugando parkour!",
		help_badge_1 = "Este jugador fue un miembro del staff de parkour.",
		help_badge_2 = "Este jugador está o estuvo en la página 1 del ranking general.",
		help_badge_3 = "Este jugador está o estuvo en la página 2 del ranking general.",
		help_badge_4 = "Este jugador está o estuvo en la página 3 del ranking general.",
		help_badge_5 = "Este jugador está o estuvo en la página 4 del ranking general.",
		help_badge_6 = "Este jugador está o estuvo en la página 5 del ranking general.",
		help_badge_7 = "Este jugador estuvo en el podio cuando el ranking semanal se reinició.",
		help_badge_8 = "Este jugador tiene un record de 30 mapas en una hora.",
		help_badge_9 = "Este jugador tiene un record de 35 mapas en una hora.",
		help_badge_10 = "Este jugador tiene un record de 40 mapas en una hora.",
		help_badge_11 = "Este jugador tiene un record de 45 mapas en una hora.",
		help_badge_12 = "Este jugador tiene un record de 50 mapas en una hora.",
		help_badge_13 = "Este jugador tiene un record de 55 mapas en una hora.",
		help_badge_14 = "Este jugador verificó su cuenta de discord en el servidor oficial de parkour (escribe <b>!discord</b>).",
		help_badge_15 = "Este jugador tuvo el tiempo más rápido en 1 mapa.",
		help_badge_16 = "Este jugador tuvo el tiempo más rápido en 5 mapas.",
		help_badge_17 = "Este jugador tuvo el tiempo más rápido en 10 mapas.",
		help_badge_18 = "Este jugador tuvo el tiempo más rápido en 15 mapas.",
		help_badge_19 = "Este jugador tuvo el tiempo más rápido en 20 mapas.",
		help_badge_20 = "Este jugador tuvo el tiempo más rápido en 25 mapas.",
		help_badge_21 = "Este jugador tuvo el tiempo más rápido en 30 mapas.",
		help_badge_22 = "Este jugador tuvo el tiempo más rápido en 35 mapas.",
		help_badge_23 = "Este jugador tuvo el tiempo más rápido en 40 mapas.",
		make_public = "hacer público",
		make_private = "hacer privado",
		moderators = "Moderadores",
		mappers = "Mappers",
		managers = "Líderes",
		administrators = "Administradores",
		close = "Cerrar",
		cant_load_bot_profile = "<v>[#] <r>No puedes ver el perfil de este bot ya que #parkour lo usa internamente para funcionar.",
		cant_load_profile = "<v>[#] <r>El jugador <b>%s</b> parece estar desconectado o no existe.",
		like_map = "¿Te gusta este mapa?",
		yes = "Sí",
		no = "No",
		idk = "No lo sé",
		vote_map = "<font color='#ffffff' size='13'><b>¿Te gusta este mapa? <font size='14'><a href='event:mapPollYes'><PT>Sí</a> <a href='event:mapPollidk'><N>No lo sé</a> <a href='event:mapPollNo'><R>No</a>",
		unknown = "Desconocido",
		powers = "Poderes",
		press = "<vp>Presiona %s",
		click = "<vp>Haz clic",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Mapas completados: %s</B></p></BV>",
		leaderboard = "Tabla de clasificación",
		position = "<V><p align=\"center\">Posición",
		username = "<V><p align=\"center\">Jugador",
		community = "<V><p align=\"center\">Comunidad",
		completed = "<V><p align=\"center\">Mapas completados",
		overall_lb = "General",
		weekly_lb = "Semanal",
		new_lang = "<v>[#] <d>Lenguaje cambiado a Español",
		room = "Sala",
		time = "Tiempo",
		buy = "Comprar",
		equip = "Equipar",
		equipped = "<font size = '10'>Equipado</font>",
	
		-- Power names
		balloon = "Globo",
		masterBalloon = "Globo II",
		bubble = "Globo III",
		fly = "Volar",
		snowball = "Bola de nieve",
		speed = "Velocidad",
		teleport = "Teletransporte",
		smallbox = "Caja pequeña",
		cloud = "Nube",
		rip = "Tumba",
		choco = "Chocolate",
		bigBox = "Caja grande",
		trampoline = "Trampolín",
		toilet = "Inodoro",
		pig = "Cerdito",
		sink = "Lavamanos",
		bathtub = "Bañera",
		campfire = "Fogata",
		chair = "Silla",
		link = "Pareja",
	}
	--[[ End of file translations/parkour/es.lua ]]--
	--[[ File translations/parkour/fr.lua ]]--
	translations.fr = {
		name = "fr",
		fullname = "Français",
	
		-- Error messages
		corrupt_map = "<r>Carte non opérationnelle. Chargement d'une autre.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les informations de cette carte.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise d'arrivée (point final).",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte a besoin d'au moins un point de sauvegarde (étoiles jaunes).",
		corrupt_data = "<r>Malheureusement, tes données ont été corrompues et ont été effacées.",
		min_players = "<r>Pour sauvegarder les données, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
		tribe_house = "<r>Les données ne sont pas sauvegardées dans les maisons de tribu.",
		invalid_syntax = "<r>Syntaxe invalide.",
		code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Mise en place du blocage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon #parkour.",
		leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été encore chargé. Attendez une minute.",
		max_power_keys = "<v>[#] <r>Vous pouvez avoir maximum %s pouvoirs sur la même touche.",
	
		-- Help window
		help = "Aide",
		staff = "Staff",
		rules = "Règles",
		contribute = "Contribuer",
		changelog = "Changements",
		help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font>\n\n<font size = '12'><J>Ton but est d'atteindre tous les points de sauvegarde pour finir la carte.</J></font></p>\n\n<font size = '11'><N>• Appuie sur <O>O</O>, écris <O>!op</O> ou clique sur le <O>bouton de configuration</O> pour ouvrir les <T>options</T>.\n• Appuie sur <O>P</O> ou clique sur la <O>main</O> en haut à droite pour voir les <T>pouvoirs</T>.\n• Appuie sur <O>L</O> ou écris <O>!lb</O> pour ouvrir le <T>classement</T>.\n• Utilise la touche <O>M</O> ou la touche <O>Suppr.</O> comme un raccourci pour <T>/mort</T>, tu peux personnaliser les touches dans les <J>Options</J>.\n• Pour en savoir plus à propos du <O>staff</O> et des <O>règles de parkour</O>, clique sur les pages <T>Staff</T> et <T>Règles</T>.\n• Clique <a href='event:discord'><o>ici</o></a> pour avoir le lien d'invitation Discord et <a href='event:map_submission'><o>ici</o></a> pour avoir le lien pour proposer des maps.\n• Utilise les fléches d'<o>en haut</o> et d'<o>en bas</o> si tu as besoin de scroller.\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! Pour plus d'informations, clique sur la page <O>Contribuer</O> </T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour n'est pas le Staff de Transformice, ils n'ont aucun pouvoir sur le jeu en lui-même, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien, avec le moins de problèmes possible et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff en ligne.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module lui-même en ajoutant des mises à jour et en réparant les bugs.\n\n<font color = '#D0A9F0'>Managers des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement des nouveaux membres du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsable de vérifier, ajouter et de supprimer des cartes dans le module pour rendre vos parties plus agréables.",
		help_rules = "<font size = '13'><B><J>Toutes Les Règles des Termes et des Conditions de Transformice s'appliquent aussi dans #parkour.</J></B></font>\n\nSi vous surprenez un joueur en train d'enfreindre les règles, chuchotez à un modérateur #parkour connecté. Si aucun modérateur n'est en ligne, signalez le joueur dans le serveur Discord.\nPour tous signalements, veuillez inclure : la communauté, le nom du salon, et le nom du joueur.\n• Ex: fr-#parkour10 Blank#3495 troll\nDes preuves, comme des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>• Aucun <font color = '#ef1111'>hack, glitch ou bugs</font> utilisé/abusé n'est pas autorisé dans les salons #parkour\n• <font color = '#ef1111'>Le farm VPN</font> est considéré comme <B>une violation</B> et n'est pas autorisé. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Cependant, <font color='#cc2222'><B>nous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Le troll est quand un joueur utilise ses pouvoirs ou ses objets d’inventaire pour intentionnellement empêcher les autres joueurs de finir la map.</j></p>\n• Le troll en revanche d'un autre troll <B>n'est pas une raison valable</B> et sera sanctionné.\n• Aider un joueur voulant faire la carte seule est aussi considéré comme du troll.\n• <J>Si un joueur veut réaliser la map sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au même point de sauvegarde qu'un autre qui n'en veut pas, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera puni en fonction d’un système de temps. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
		help_contribute = "<font size='14'>\n<p align='center'>L'équipe de direction de parkour aime l'open-source car <t>cela aide la communauté</t>. Vous pouvez <o>voir</o> et <o>modifier</o> le code source sur <o><u><a href='event:github'>GitHub</a></u></o>.\n\nEntretenir le module est <t>strictement volontaire</t>, donc toute aide regardant le <t>développement</t>, <t>des signalements de bugs</t>, <t>des suggestions</t> et <t>la création de maps</t> est toujours <u>la bienvenue et apprécié</u>.\nVous pouvez <vp>signaler des bugs</vp> et <vp>faire des suggestions</vp> sur le <o><u><a href='event:discord'>Discord</a></u></o> et/ou <o><u><a href='event:github'>GitHub</a></u></o>.\nVous pouvez <vp>proposer des cartes</vp> sur le <o><u><a href='event:map_submission'>Forum</a></u></o>.\n\nEntretenir le module n'est pas cher, mais ce n'est pas non plus gratuit. Nous apprécierons si vous nous aidiez en <t>faisant un don</t> <o><u><a href='event:donate'>ici</a></u></o>.\n<u>Toutes les donations iront directement dans l'amélioration du module.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Système de quêtes implémenté. (Appuyez sur <J><B>,</B></J> pour ouvrir l’interface des quêtes.)\n\n<font size='11'>• <font size='13'>Ajout d’une option de désactiver les touches de commande pour afficher les interfaces de classement, d’aide, du magasin etc.\n\n<font size='11'>• <font size='13'>Ajout de la commande <B><J>!cp [NomDuJoueur#Tag]</J></B> pour établir votre point de sauvegarde comme celui du joueur mentionné.",
	
		-- Congratulation messages
		reached_level = "<d>Félicitations ! Vous avez complété le niveau <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> a fini le parkour en <vp>%s</vp> secondes, <fc>félicitations!",
		unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir <vp>%s</vp>.",
	
		-- Information messages
		mod_apps = "<j>Les candidatures pour devenir modérateur de Parkour sont maintenant ouvertes! Rendez-vous sur cette page: <rose>%s",
		staff_power = "<r>Le staff de parkour <b>n'a pas</b> de pouvoir en dehors du module.",
		donate = "<vp>Tapez <b>!donate</b> si vous souhaitez faire un don pour ce module !",
		paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
		resumed_events = "<n2>Le module n'est plus en pause.",
		welcome = "<n>Bienvenue dans <t>#parkour</t>!",
		module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
		kill_minutes = "<R>Tes pouvoirs ont été désactivés pour %s minutes.",
		permbanned = "<r>Tu as été banni de #parkour définitevement.",
		tempbanned = "<r>Tu as été banni de #parkour pendant %s minutes.",
		forum_topic = "<rose>Pour plus d'informations sur le module, visite ce lien: %s",
		report = "<j>Besoin de signaler un joueur? <t><b>/c Parkour#8558 .report Pseudo#0000</b></t>",
		killed = "<v>[#] <r>Vos pouvoirs ont été restreints pendant %s minutes suite à une violation du réglement de parkour. Des violations ultérieures se conclueront par un banissement. Appuyez sur <b>H</b> pour visionner les règles.",
		mapper_event = "<CE><B>Concours de creation de cartes Parkour 2024:</B>\n<n>Mettez vos talents de créateur de cartes au service de Parkour pour tenter de gagner des <D>fromages <n> et des <pt>pièces de Parkour<n>!\n<R>Possibilité de proposer sa carte jusqu'au  <B>31 Janvier 2024</B>.\n<PS>Pour plus d'information, se rendre sur : %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Le compte à rebours a commencé...",
		easter_egg_1  = "<ch>Il reste moins de 24 heures !",
		easter_egg_2  = "<ch>Wow, tu es en avance ! Tu es très excité(e) ?",
		easter_egg_3  = "<ch>Une surprise t'attend...",
		easter_egg_4  = "<ch>Tu sais ce qu'il va se passer...?",
		easter_egg_5  = "<ch>L'horloge tourne...",
		easter_egg_6  = "<ch>La surprise est proche !",
		easter_egg_7  = "<ch>La fête va commencer...",
		easter_egg_8  = "<ch>Regarde l'heure, est-ce le moment ?",
		easter_egg_9  = "<ch>Fais attention, le temps passe...",
		easter_egg_10 = "<ch>Assis-toi et relax, ce sera demain dans peu de temps !",
		easter_egg_11 = "<ch>Allons dormir plus tôt, ça accélérera le temps !",
		easter_egg_12 = "<ch>La patience est une vertue",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Maps doubles Samedi (GMT+2) et tous les pouvoirs sont disponibles pour le semaine d'anniversaire de parkour!",
		double_maps_start = "<rose>C'EST LA SEMAINE D'ANNIVERSAIRE DE PARKOUR! Les double maps et tous les pouvoirs ont été activés. Merci de jouer avec nous!",
		double_maps_end = "<rose>La semaine d'anniversaire de parkour est terminée. Merci de jouer avec nous!",
	
		-- Records
		records_enabled = "<v>[#] <d>Le mode de records a été activé dans ce salon. Les statistiques ne compteront pas et les pouvoirs sont désactivés !\nTu peux trouver plus d'informations à propos des records sur <b>%s</b>",
		records_admin = "<v>[#] <d>Tu es un administrateur de ce salon de records. Vous pouvez utiliser les commandes <b>!map</b>, <b>!pw</b> et <b>!time</b>.",
		records_completed = "<v>[#] <d>Tu as complété la carte ! Si tu veux la refaire, ecrivez <b>!redo</b>.",
		records_submit = "<v>[#] <d>Wow ! On dirait que tu as fait le temps le plus rapide dans ce salon. Si tu veux envoyez voter record, écris <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>On dirait que cette carte n'est pas dans la rotation de parkour... Tu ne peux pas envoyer de records pour celle-ci!",
		records_not_fastest = "<v>[#] <r>On dirait que tu n'es pas le joueur le plus rapide dans ce salon...",
		records_already_submitted = "<v>[#] <r>Tu as déjà envoyé ton record pour cette carte!",
		records_submitted = "<v>[#] <d>Ton record pour la carte <b>%s</b> a été envoyé.",
	
		-- Quests
		daily_q = "Quotidien",
		weekly_q = "Hebdomadaire",
		daily_quests = "<p align='center'><font size='20'><B><D>Missions quotidiennes</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Missions hebdomadaires</D></B></font>",
		quest_1 = "Terminez <B><D>%s/%s</D></B> cartes.",
		quest_2 = "Passez<B><D>%s/%s</D></B> points de sauvegarde.",
		quest_3 = "Soyez le premier à compléter une carte <B><D>%s/%s</D></B> fois.",
		quest_4 = "Terminez une carte en moins de <B><D>%s</D></B> secondes.",
		quest_5 = "Terminez la carte <B><D>@%s</D></B>",
		quest_6 = "Utilisez le pouvoir <PT><b>%s</b></PT> <B><D>%s/%s</D></B> fois.",
		next_reset = "<b><D>Réinitialiser :\n</b></D>%s",
		quest_completed = "<b><D>Félicitations !</D></b> \nVous avez complété une mission %s!",
		quest_reset = "<V>[#]</V> <O>Vos missions %s ont été réinitialisées.</O>",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>VOUS ÊTES DÉSORMAIS AFK</b></bv>\nBOUGEZ POUR REAPPARAÎTRE</font>\n\n<font size='30'><u><t>Rappels:</t></u></font>\n\n<font size='15'><r>Les joueurs avec une ligne rouge au-dessus d'eux ne veulent pas d'aide!\nTroller/bloquer des joueurs est interdit dans parkour!<d>\nRejoins notre <cep><a href='event:discord'>serveur Discord</a></cep>!\nEnvie de contribuer au code? Viens voir notre <cep><a href='event:github'>GitHub</a></cep>\nTu as une bonne carte à nous proposer? Viens la poster sur notre <cep><a href='event:map_submission'>sujet de proposition de cartes</a></cep>\nJettes un oeil à notre <cep><a href='event:forum'>sujet officiel</a></cep> pour plus d'informations!\nSoutiens le module en faisant un <cep><a href='event:donate'>don!</a></cep>",
		options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtiliser le clavier <b>QWERTY</b> (désactiver si votre clavier est en <b>AZERTY</b>)\n\nUtiliser <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> comme raccourci pour <b>/mort</b> (désactiver pour <b>DEL</b>)\n\nAffiche le temps de recharge de vos compétences\n\nAffiche les boutons pour utiliser les compétences\n\nAffiche le bouton d'aide\n\nAffiche les annonces des cartes achevées\n\nAffichage d'un indicateur pour ne pas être aidé.\n\nDésactiver les touches de contrôle pour tous les interfaces (classement, aide, magasin, etc.)",
		cooldown = "<v>[#] <r>Attends quelques secondes avant de pouvoir recommencer.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'>Clavier <b>QWERTY</b>" ..
						 "\n\n<b>Cacher</b> le nombre de cartes" ..
						 "\n\n<b>Touche original</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complète <v>%s</v> maps" ..
						"<font size='5'>\n\n</font>pour débloquer le pouvoir" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Complète <v>%s</v> maps" ..
						"<font size='5'>\n\n</font>pour améliorer le pouvoir" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Rang <v>%s</v> requis" ..
						"<font size='5'>\n\n</font>pour débloquer le pouvoir" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Rang <v>%s</v> requis" ..
						"<font size='5'>\n\n</font>pour améliorer le pouvoir" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Maps complétées"),
		overall_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Classement Global"),
		weekly_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Classement Hebdomadaire"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Badges (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>Le nombre de cartes complétées de ce joueur est privé. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Position dans le classement global: <b><v>%s</v></b>\n\n" ..
					"Position dans le classement hebdomadaire: <b><v>%s</v></b>\n\n%s"),
		map_count = "Nombre de maps complétées: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Maps terminées : <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Checkpoints atteints : <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Les badges sont des accomplissements que peuvent obtenir les joueurs. Clique sur un badge pour voir sa description.",
		help_private_maps = "Ce joueur ne souhaite pas partager son nombre de maps complétées ! Tu peux également le cacher sur ton profil.",
		help_yellow_maps = "Les cartes en jaune sont les cartes complétées cette semaine.",
		help_red_maps = "Les cartes en rouge ont été complétées cette heure-ci.",
		help_map_count_title = "Tu peux recevoir des titres de <b>Transformice</b> en complétant des maps parkour !",
		help_checkpoint_count_title = "Tu peux recevoir des titres de <b>Transformice</b> en atteignant tous les checkpoints dans les maps parkour !",
		help_badge_1 = "Ce joueur a été un membre du staff de parkour.",
		help_badge_2 = "Ce joueur est ou était sur la page 1 du classement global.",
		help_badge_3 = "Ce joueur est ou était sur la page 2 du classement global.",
		help_badge_4 = "Ce joueur est ou était sur la page 3 du classement global.",
		help_badge_5 = "Ce joueur est ou était sur la page 4 du classement global.",
		help_badge_6 = "Ce joueur est ou était sur la page 5 du classement global.",
		help_badge_7 = "Ce joueur a été sur le podium à la fin d'un classement hebdomadaire.",
		help_badge_8 = "Ce joueur a un record de 30 cartes par heure.",
		help_badge_9 = "Ce joueur a un record de 35 cartes par heure.",
		help_badge_10 = "Ce joueur a un record de 40 cartes par heure.",
		help_badge_11 = "Ce joueur a un record de 45 cartes par heure.",
		help_badge_12 = "Ce joueur a un record de 50 cartes par heure.",
		help_badge_13 = "Ce joueur a un record de 55 cartes par heure.",
		help_badge_14 = "Ce joueur a vérifié son compte discord sur le discord officiel de parkour (écris <b>!discord</b>).",
		help_badge_15 = "Ce joueur a obtenu le temps le plus rapide sur 1 carte.",
		help_badge_16 = "Ce joueur a obtenu le temps le plus rapide sur 5 cartes.",
		help_badge_17 = "Ce joueur a obtenu le temps le plus rapide sur 10 cartes.",
		help_badge_18 = "Ce joueur a obtenu le temps le plus rapide sur 15 cartes.",
		help_badge_19 = "Ce joueur a obtenu le temps le plus rapide sur 20 cartes.",
		help_badge_20 = "Ce joueur a obtenu le temps le plus rapide sur 25 cartes.",
		help_badge_21 = "Ce joueur a obtenu le temps le plus rapide sur 30 cartes.",
		help_badge_22 = "Ce joueur a obtenu le temps le plus rapide sur 35 cartes.",
		help_badge_23 = "Ce joueur a obtenu le temps le plus rapide sur 40 cartes.",
		make_public = "Rendre publique",
		make_private = "Rendre privé",
		moderators = "Modérateurs",
		mappers = "Mappers",
		managers = "Manageurs",
		administrators = "Administrateurs",
		close = "Fermer",
		cant_load_bot_profile = "<v>[#] <r>Tu ne peux pas voir le profile de ce robot car #parkour l'utilise intérieurement pour faire fonctionner le module correctement.",
		cant_load_profile = "<v>[#] <r>Le joueur <b>%s</b> semble être hors ligne ou n'existe pas.",
		like_map = "Aimez-vous cette carte?",
		yes = "Oui",
		no = "Non",
		idk = "Je ne sais pas",
		vote_map = "<font color='#ffffff' size='13'><b>Aimez-vous cette carte? <font size='14'><a href='event:mapPollYes'><PT>Oui</a> <a href='event:mapPollidk'><N>Je ne sais pas</a> <a href='event:mapPollNo'><R>Non</a>",
		unknown = "Inconnu",
		powers = "Pouvoirs",
		press = "<vp>Appuyer sur %s",
		click = "<vp>Clique gauche",
		ranking_pos = "Classement #%s",
		completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
		leaderboard = "Classement",
		position = "<V><p align=\"center\">Position",
		username = "<V><p align=\"center\">Pseudo",
		community = "<V><p align=\"center\">Communauté",
		completed = "<V><p align=\"center\">Cartes complétées",
		overall_lb = "Permanent",
		weekly_lb = "Hebdomadaire",
		new_lang = "<v>[#] <d>Langue changée vers Français",
		room = "Salon",
		time = "Temps",
		buy = "Buy",
		equip = "Equip",
		equipped = "<font size = '10'>Equipped</font>",
	
		-- Power names
		balloon = "Ballon",
		masterBalloon = "Ballon II",
		bubble = "Ballon III",
		fly = "Voler",
		snowball = "Boule de neige",
		speed = "Accélération",
		teleport = "Téléportation",
		smallbox = "Petite boîte",
		cloud = "Nuage",
		rip = "Tombe",
		choco = "Planche de chocolat",
		bigBox = "Grande boîte",
		trampoline = "Trampoline",
		toilet = "Toilettes",
		pig = "Cochon",
		sink = "Evier",
		bathtub = "Baignoire",
		campfire = "Feu de Camp",
		chair = "Chaise",
		link = "Âme soeur",
	}
	--[[ End of file translations/parkour/fr.lua ]]--
	--[[ File translations/parkour/he.lua ]]--
	translations.he = {
		name = "he",
		fullname = "עברית",
	
		-- Error messages
		corrupt_map = "<r>מפה משובשת, טוען אחרת.",
		corrupt_map_vanilla = "<r>[שגיאה] <n>לא ניתן לקבל מידע אודות מפה זו.",
		corrupt_map_mouse_start = "<r>[שגיאה] <n>דרוש מקום התחלה במפה זו (נקודת התחלה של העכבר).",
		corrupt_map_needing_chair = "<r>[שגיאה] <n>מפה זו צריכה ספה בנקודה הסופית.",
		corrupt_map_missing_checkpoints = "<r>[שגיאה] <n>נדרשת לפחות נקודת שמירה אחת במפה זו (נקודה צהובה).",
		corrupt_data = "<r>למרבה הצער, נתוניך נפגמו ואופסו.",
		min_players = "<r>על מת שנתוניך ישמרו, חייבים להיות לפחות ארבעה שחקנים שונים בחדר זה. <bl>[%s/%s]",
		tribe_house = "<r>נתונים לא ישמרו בבתי שבט.",
		invalid_syntax = "<r>syntax שגוי.",
		code_error = "<r>שגיאה התגלתה: <bl>%s-%s-%s %s",
		emergency_mode = "<r>מתחיל כיבוי חירום, אין כניסה לשחקנים חדשים. אנא לך לחדר #parkour אחר.",
		leaderboard_not_loaded = "<r>הלוח תוצאות עדיין לא נטען, המתן דקה.",
		max_power_keys = "<v>[#] <r>אתם יכולים שיהיו לכם עד %s כוחות על אותו מקש.",
	
		-- Help window
		help = "עזרה",
		staff = "צוות",
		rules = "חוקים",
		contribute = "תרומה",
		changelog = "חדש",
		help_help = "<p align = 'center'><font size = '14'>ברוך הבא ל-<T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>מטרתך להשיג את כל נקודות השמירה עד שאתה מסיים את המפה.</J></p>\n\n<N>• לחץ <O>ם</O>, כתוב <O>!op</O> או לחץ על <O>גלגל השיניים</O> בכדי לפתוח את <T>ההגדרות</T>.\n• לחץ <O>פ</O> או לחץ על <O>כפתור האגרוף</O> בצד ימין למעלה על מנת לפתוח את <T>תפריט הכוחות</T>.\n• לחץ <O>ך</O> או כתוב <O>!lb</O> בכדי לפתוח את <T>לוח התוצאות</T>.\n• לחץ על <O>צ</O> או כפתור ה-<O>Delete</O> כתחליף ל-<T>/mort</T>, אתה יכול להחליף בין המקשים <J>בהגדרות</J>.\n• על מנת לדעת עוד על <O>הצוות</O> שלנו ועל <O>החוקים של פארקור</O>, לחץ על הכרטיסיות <T>צוות</T> ו<T>חוקים</T> לפי הסדר.\n• לחץ <a href='event:discord'><o>כאן</o></a> בכדי לקבל הזמנה לשרת הדיסקורד ו<a href='event:map_submission'><o>כאן</o></a> בכדי לקבל קישור לנושא הגשת המפות.\n• לחץ על חיצי ה<o>למעלה</o> וה<o>למטה</o> כאשר אתה צריך לגלול.\n\n<p align = 'center'><font size = '13'><T>ניתן כעת לתרום! לפרטים נוספים לחצו על הכרטיסייה <O>תרומה</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>הערה: צוות הפארקור אינו צוות המשחק ואין לו שום כוח במשחק עצמו, אלא רק במודול</r>\nצוות הפארקור מוודא כי המודול רץ בצורה חלקה עם עניינים מינימליים והם תמיד זמינים לעזור לשחקנים מתי שצריך.</font></p>\nאתה יכול לכתוב <D>!staff</D> בצ'אט כדי לראות את רשימת הצוות.\n\n<font color = '#E7342A'>אדמינים:</font> הם אחראים לשמור על המודול עי הוספת עדכונים ותיקוני באגים.\n\n<font color = '#D0A9F0'>מנהלי צוות:</font> הם מפקחים על צוותי הניהול והמפות, מוודאים כי הם מבצעים את עבודתם כשורה. בנוסף, הם האחראים על גיוס חברים חדשים לצוות.\n\n<font color = '#FFAAAA'>מנהלים:</font> הם האחראים לאכוף את חוקי המודול והענשת משתמשים אשר לא שומרים עליהם.\n\n<font color = '#25C059'>צוות מפות:</font> הם האחראים על סקירה, הוספה והסרה של מפות במודול הפארקור בכדי להבטיח שיהיה לכם משחק מהנה.",
		help_rules = "<font size = '13'><B><J>כל החוקים, התנאים וההגבלות של הטראנספורמייס חלים גם על #parkour</J></B></font>\n\nאם אתם מוצאים שחקן אשר עובר על חוקים אלה, שלחו לחישה למנהלי פארקור במשחק. אם אין מנהלים מחוברים, מומלץ לדווח על כך בשרת הדיסקורד.\nכאשר מדווחים, בבקשה כללו את השרת, שם החדר, ושם המשתמש של השחקן.\n• דוגמא: en-#parkour10 Blank#3495 trolling\nהוכחות כגון צילומי מסך, וידאו או גיפס הם יעילים ומוערכים, אך לא חייב.\n\n<font size = '11'>• אין להשתמש ב<font color = '#ef1111'>האקים, גליצ'ים או באגים</font> בחדרי פארקור\n• <font color = '#ef1111'>פארם VPN </font> ייחשב כ<B>ניצול</B> והדבר אסור. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nכל אחד שיתפס עובר על חוקים אלה יורחק באופן מיידי.</B></font></p>\n\n<font size = '12'>טראנספורמייס מרשה לעשות טרולים. עם זאת, <font color='#cc2222'><B>אנו לא נאפשר זאת בפארקור.</B></font></font>\n\n<p align = 'center'><J>טרול זה כאשר שחקן משתמש בכוחותיו או במוצרי זריקה בכוונה תחילה כדי למנוע משחקנים אחרים לסיים את המפה.</j></p>\n• טרול כנקמה הוא <B>אינו סיבה מוצדקת</B> להטריל מישהו ואתם עדיין תענשו.\n• כפיית עזרה על שחקנים שמנסים להשלים לבדם את המפה וסירוב להפסיק כאשר התבקשת לכך ייחשב כטרול.\n• <J>אם שחקן אינו מעוניין בעזרה או מעוניין להשלים לבדו את המפה, אנא נסו ככל יכולתכם לעזור לשחקנים אחרים</J>. עם זאת, אם שחקן אחר צריך עזרה באותה נקודה כמו השחקן השני שרוצה להשלים לבד, אתה יכול לעזור לשניהם.\n\nאם שחקן יתפס מטריל, הוא יענש על בסיס זמן. חשוב לציין כי ביצוע טרול שוב ושוב יוביל לעונשים ארוכים יותר וחמורים יותר.",
		help_contribute = "<font size='14'>\n<p align='center'>צוות הניהול של פארקור אוהב לפתוח את קוד המקור מכיוון שזה <t>עוזר לקהילה</t>. אתה יכול <o>לראות</o> ו<o>לערוך</o> את קוד המקור ב-<o><u><a href='event:github'>GitHub</a></u></o>.\n\nשמירה על המודול היא <t>התנדבותית לחלוטין</t>. לכן, כל עזרה ב<t>קודים</t>, <t>דיווח על באגים</t>, <t>הצעות</t> ו<t>יצירת מפות</t> תמיד <u>מתקבלת בברכה ומוערכת</u>.\nאתה יכול <vp>לדווח אודות באגים</vp> ו<vp>להציע הצעות</vp> ב<o><u><a href='event:discord'>דיסקורד</a></u></o> ו/או ב-<o><u><a href='event:github'>GitHub</a></u></o>.\nאתה יכול <vp>להגיש את מפותיך</vp> ב<o><u><a href='event:map_submission'>נושא הפורום</a></u></o> שלנו.\n\nאחזקת פארקור איננה יקרה, אך גם איננה חינמית. אנו נשמח אם תוכלו לעזור לנו עי <t>תרומה בכל סכום</t> <o><u><a href='event:donate'>כאן</a></u></o>.\n<u>כל התרומות הולכות היישר לשיפור המודול.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.10.0 - 17/04/2021</o></p>\n\n<font size='11'>• <font size='13'><b><j>THREE</J></b> brand new Transformice titles that can only be unlocked by playing <font color='#1A7EC9'><b>#parkour</b></font>!</font>\n• Two new statuses added to the profile.\n• Minor text adjustments.",
	
		-- Congratulation messages
		reached_level = "<d>ברכות! עלית לרמה <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> סיים את הפארקור תוך <vp>%s</vp> שניות, <fc>ברכות!",
		unlocked_power = "<ce><d>%s</d> השיג את הכח <vp>%s</vp>.",
	
		-- Information messages
		mod_apps = "<j>הגשות מועמדות להיות מנהל/ת פארקור פתוחות כעת! השתמש בקישור זה: <rose>%s",
		staff_power = "<r>לצוות פארקור <b>אין</b> שום כוחות מחוץ לחדרי פארקור.",
		donate = "<vp>הקלד <b>!donate</b> אם תרצה לתרום עבור מודול זה!",
		paused_events = "<cep><b>[אזהרה!]</b> <n>המשחק הגיע למגבלה קריטית ונעצר כעת.",
		resumed_events = "<n2>המשחק נמשך.",
		welcome = "<n>ברוכים הבאים ל<t>#parkour</t>!",
		module_update = "<r><b>[אזהרה!]</b> <n>המשחק יעדוכן בעוד <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>לוח התוצאות נטען. לחץ L כדי לפתוח אותו.",
		kill_minutes = "<R>כוחותיך הושבתו ל-%s דקות.",
		permbanned = "<r>הורחקת לצמיתות מ-#parkour.",
		tempbanned = "<r>הורחקת מ-#parkour למשך %s דקות.",
		forum_topic = "<rose>למידע נוסף אודות פארקור כנסו לקישור: %s",
		report = "<j>רוצים לדווח על שחקן? <t><b>/c Parkour#8558 .report Username#0000</b></t>",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>הספירה מתחילה...",
		easter_egg_1  = "<ch>פחות מ24 שעות נותרו!",
		easter_egg_2  = "<ch>וואו, הגעת מוקדם! גם אתה מתרגש?",
		easter_egg_3  = "<ch>הפתעה מחכה...",
		easter_egg_4  = "<ch>אתה יודע מה הולך לקרות...?",
		easter_egg_5  = "<ch>השעון ממשיך לתקתק...",
		easter_egg_6  = "<ch>ההפתעה קרבה!",
		easter_egg_7  = "<ch>המסיבה עוד רגע מתחילה...",
		easter_egg_8  = "<ch>תסתכל בשעות, כבר הגיע הזמן?",
		easter_egg_9  = "<ch>תיזהר, הזמן עובר מהר...",
		easter_egg_10 = "<ch>פשוט שב ותירגע, מחר יגיע במהרה!",
		easter_egg_11 = "<ch>לך לישון מוקדם, זה יגרום לזמן לעבור מהר יותר!",
		easter_egg_12 = "<ch>סבלנות היא מעלה",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>מפות כפולות וכל הכוחות זמינים בשביל שבוע היום הולדת של פארקור!",
		double_maps_start = "<rose>זה שבוע היום הולדת של פארקור! מפות כפולות וכל הכוחות הופעלו.תודה שאתם משחקים איתנו!",
		double_maps_end = "<rose>שבוע היום הולדת של פארקור נגמר. תודה ששיחקתם!",
	
		-- Records
		records_enabled = "<v>[#] <d>מצב שיאים הופעל בחדר זה. סטטיסטיקה לא תיחשב וכוחות לא יפעלו. תוכלו למצוא מידע נוסף על שיאים ב <b>%s</b>",
		records_admin = "<v>[#] <d>הנך מנהל של חדר השיאים הזה. אתה יכול להשתמש בפקודות <b>!map</b>, <b>!setcp</b>, <b>!pw</b> ו-<b>!time</b>.",
		records_completed = "<v>[#] <d>השלמתם את המפה! אם ברצונכם להשלימה שוב, כתבו <b>!redo</b>.",
		records_submit = "<v>[#] <d>וואו! נראה שיש לכם את הזמן הכי מהיר בחדר. אם ברצונכם להגיש את השיא, כתבו <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>נראה כי מפה זו אינה חלק ממפות פארקור... אינכם יכולים להגיש שיא בשבילה!",
		records_not_fastest = "<v>[#] <r>נראה כי אינך השחקן הכי מהיר בחדר...",
		records_already_submitted = "<v>[#] <r>כבר הגשת את השיא שלך בשביל מפה זו!",
		records_submitted = "<v>[#] <d>השיא שלך למפה <b>%s</b> הוגש.",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>אתה במצב AFK</b></bv>\nזוז כדי לחזור</font>\n\n<font size='30'><u><t>תזכורות:</t></u></font>\n\n<font size='15'><r>שחקנים עם קו אדום מעליהם אינם מעוניינים בעזרה!\nהטרלת/חסימת שחקנים אחרים בפארקור אסורה!<d>\nהצטרפו ל<cep><a href='event:discord'>שרת הדיסקורד</a></cep> שלנו!\nרוצה לתרום קוד? ראה את <cep><a href='event:github'>מאגר ה-GitHub</a></cep> שלנו.\nיש לך מפה טובה להגיש?  שלח את זה ב<cep><a href='event:map_submission'>נושא הגשת המפות</a></cep> שלנו\nבידקו את <cep><a href='event:forum'>הנושא הרשמי</a></cep> שלנו למידע נוסף!\nתמוך בנו על ידי <cep><a href='event:donate'>תרומה!</a></cep>",
		options = "<p align='center'><font size='20'>אפשרויות פארקור</font></p>\n\nהשתמש במקלדת <b>QWERTY</b> (כבה אם <b>AZERTY</b> בשימוש)\n\nהשתמש באות <b>צ</b> במקום <b>/mort</b> (משבית את <b>DEL</b>)\n\nהראה את זמן טעינת הכוחות\n\nהראה כפתור כוחות\n\nהראה כפתור עזרה\n\nהראה הכרזות השלמת מפות\n\nהצג סימן 'ללא עזרה'\n\nDisable all UI (leaderboard, help, shop etc.) hotkeys",
		cooldown = "<v>[#] <r>המתן מספר שניות לפני שאתה עושה זאת.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> מקלדת" ..
						 "\n\n<b>הסתר</b> ספירת מפות" ..
						 "\n\nהשתמש ב<b>מקשים מקוריים</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>השלם <v>%s</v> מפות" ..
						"<font size='5'>\n\n</font>בכדי להשיג" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>השלם <v>%s</v> מפות" ..
						"<font size='5'>\n\n</font>כדי לשדרג ל" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>דרגה <v>%s</v>" ..
						"<font size='5'>\n\n</font>בכדי להשיג" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>דרגה <v>%s</v>" ..
						"<font size='5'>\n\n</font>כדי לשדרג ל" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>מפות שהושלמו"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>לוח תוצאות כללי"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>לוח תוצאות שבועי"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>תגים (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>מספר המפות של שחקן זה הינו פרטי. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"דרגה בלוח התוצאות הכללי: <b><v>%s</v></b>\n\n" ..
					"דרגה בלוח התוצאות השבועי: <b><v>%s</v></b>\n\n%s"),
		map_count = "מספר מפות: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		help_badge = "תגים הינם הישגים ששחקן יכול לקבל. לחץ עליהם על מנת לקבל פירוט.",
		help_private_maps = "משתמש זה אינו מעוניין לשתף את מספר המפות שלו בפומבי! אתה יכול להסתיר את זה גם בפרופיל שלך.",
		help_yellow_maps = "מפות בצהוב הן מפות שהושלמו בשבוע זה.",
		help_red_maps = "מפות באדום הן מפות שהושלמו בשעה האחרונה.",
		help_badge_1 = "משתמש זה היה חלק מצוות הפארקור בעבר.",
		help_badge_2 = "משתמש זה נמצא או היה בעמוד הראשון של לוח התוצאות הכללי.",
		help_badge_3 = "משתמש זה נמצא או היה בעמוד השני של לוח התוצאות הכללי.",
		help_badge_4 = "משתמש זה נמצא או היה בעמוד השלישי של לוח התוצאות הכללי.",
		help_badge_5 = "משתמש זה נמצא או היה בעמוד הרביעי של לוח התוצאות הכללי.",
		help_badge_6 = "משתמש זה נמצא או היה בעמוד החמישי של לוח התוצאות הכללי.",
		help_badge_7 = "שחקן זה היה בפודיום בסוף של לוח התוצאות השבועי בסוף שבוע",
		help_badge_8 = "השחקן הזה השיג שיא של 30 מפות תוך שעה.",
		help_badge_9 = "השחקן הזה השיג שיא של 35 מפות תוך שעה.",
		help_badge_10 = "השחקן הזה השיג שיא של 40 מפות תוך שעה.",
		help_badge_11 = "השחקן הזה השיג שיא של 45 מפות תוך שעה.",
		help_badge_12 = "השחקן הזה השיג שיא של 50 מפות תוך שעה.",
		help_badge_13 = "השחקן הזה השיג שיא של 55 מפות תוך שעה.",
		help_badge_14 = "שחקן זה אימת את משתמש הדיסקורד שלו בשרת הדיסקורד הרשמי של פארקור (כתבו <b>!discord</b>).",
		help_badge_15 = "שחקן זה עשה את הזמן המהיר ביותר במפה אחת.",
		help_badge_16 = "שחקן זה עשה את הזמן המהיר ביותר ב-5 מפות.",
		help_badge_17 = "שחקן זה עשה את הזמן המהיר ביותר ב-10 מפות.",
		help_badge_18 = "שחקן זה עשה את הזמן המהיר ביותר ב-15 מפות.",
		help_badge_19 = "שחקן זה עשה את הזמן המהיר ביותר ב-20 מפות.",
		help_badge_20 = "שחקן זה עשה את הזמן המהיר ביותר ב-25 מפות.",
		help_badge_21 = "שחקן זה עשה את הזמן המהיר ביותר ב-30 מפות.",
		help_badge_22 = "שחקן זה עשה את הזמן המהיר ביותר ב-35 מפות.",
		help_badge_23 = "שחקן זה עשה את הזמן המהיר ביותר ב-40 מפות.",
		make_public = "הפוך לציבורי",
		make_private = "הפוך לפרטי",
		moderators = "מנהלים",
		mappers = "צוות מפות",
		managers = "מנהלי צוות",
		administrators = "אדמינים",
		close = "סגור",
		cant_load_bot_profile = "<v>[#] <r>אינך יכול לראות את הפרופיל של הבוט הזה כיוון שפארקור משתמש בו באופן פנימי כדי לעבוד בצורה ראויה.",
		cant_load_profile = "<v>[#] <r>השחקן <b>%s</b> ככל הנראה מנותק או איננו קיים.",
		like_map = "האם אתה אוהב את המפה הזו?",
		yes = "כן",
		no = "לא",
		idk = "לא יודע",
		vote_map = "<font color='#ffffff' size='13'><b>האם אתה אוהב את המפה הזו? <font size='14'><a href='event:mapPollYes'><PT>כן</a> <a href='event:mapPollidk'><N>לא יודע</a> <a href='event:mapPollNo'><R>לא</a>",
		unknown = "לא ידוע",
		powers = "כוחות",
		press = "<vp>לחץ %s",
		click = "<vp>לחיצה שמאלית",
		ranking_pos = "דרגה #%s",
		completed_maps = "<p align='center'><BV><B>מפות שהושלמו: %s</B></p></BV>",
		leaderboard = "לוח תוצאות",
		position = "<V><p align=\"center\">דרגה",
		username = "<V><p align=\"center\">שם משתמש",
		community = "<V><p align=\"center\">קהילה",
		completed = "<V><p align=\"center\">מפות שהושלמו",
		overall_lb = "כללי",
		weekly_lb = "שבועי",
		new_lang = "<v>[#] <d>השפה הוגדרה ל-עברית",
		room = "Room",
		time = "Time",
		buy = "Buy",
		equip = "Equip",
		equipped = "<font size = '10'>Equipped</font>",
	
		-- Power names
		balloon = "בלון",
		masterBalloon = "בלון II",
		bubble = "בלון III",
		fly = "תעופה",
		snowball = "כדור שלג",
		speed = "מהירות",
		teleport = "שיגור",
		smallbox = "קופסא קטנה",
		cloud = "ענן",
		rip = "קבר",
		choco = "קרש שוקולד",
		bigBox = "קופסא גדולה",
		trampoline = "טרמפולינה",
		toilet = "אסלה",
		pig = "חזיר",
		sink = "כיור",
		bathtub = "אמבטיה",
		campfire = "מדורה",
		chair = "כסא",
		link = "נפש תאומה",
	
	}
	--[[ End of file translations/parkour/he.lua ]]--
	--[[ File translations/parkour/hu.lua ]]--
	translations.hu = {
		name = "hu",
		fullname = "Magyar",
	
		-- Error messages
		corrupt_map = "<r>Sérült pálya. Egy másik pálya betöltése folyamatban...",
		corrupt_map_vanilla = "<r>[HIBA] <n>Nem található információ a pályáról.",
		corrupt_map_mouse_start = "<r>[HIBA] <n>Ennek a pályának rendelkeznie kell egy kezdőponttal (egér spawnpointja).",
		corrupt_map_needing_chair = "<r>[HIBA] <n>A pályának rendelkeznie kell egy fotellel.",
		corrupt_map_missing_checkpoints = "<r>[HIBA] <n>A pályának rendelkeznie kell legalább egy ellenőrző ponttal (sárga szög).",
		corrupt_data = "<r>Sajnos az adataid megsérültek, így újra lettek állítva.",
		min_players = "<r>Az adatok mentéséhez legalább 4 egérnek tartózkodnia kell a szobában. <bl>[%s/%s]",
		tribe_house = "<r>Az adatok nem kerülnek megntésre a törzsházakban.",
		invalid_syntax = "<r>Érvénytelen szintakszis.",
		code_error = "<r>Hiba jelent meg: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Vészleállítás kezdeményezése, új játékosok nem engedélyezettek. Kérjük, menj egy másik #parkour szobába.",
		leaderboard_not_loaded = "<r>A ranglista még nem töltött be. Várj egy percet.",
		max_power_keys = "<v>[#] <r>Legfeljebb %s képességet használhatsz ugyanazon a billentyűgombon.",
	
		-- Help window
		help = "Segítség",
		staff = "Személyzet",
		rules = "Szabályzat",
		contribute = "Hozzájárulás",
		changelog = "Hírek",
		help_help = "<p align = 'center'><font size = '14'>Üdvözlünk a <T>#parkour</T>-on!</font></p>\n<font size = '11'><p align='center'><J>A célod, hogy elérd az összes ellenőrző pontot, miközben teljesíted a pályát.</J></p>\n\n<N>• Nyomd meg az <O>O</O> betűt, írd be a <O>!op</O> parancsot vagy kattints a  <O>konfigurációs gombra</O> a <T>beállítások menüjéhez</T> való megnyitáshoz.\n• Nyomd meg a <O>P</O> gombot vagy kattints a <O>kéz ikonra</O> a jobb felső sarokban a <T>képességek menüjéhez</T> való megnyitáshoz.\n• Nyomd meg az <O>L</O> gombot vagy írd be a <O>!lb</O> parancsot a <T>ranglista</T> megnyitásához.\n• Nyomd meg az <O>M</O> gombot vagy a <O>Delete</O> gombot <T>/mort</T> parancshoz, megváltoztathatod a gombokat az <J>Beállítások</J> menüben.\n• Ha szeretnél többet tudni a <O>személyzetről</O> és a <O>parkour szabályairól</O>, akkor kattints a <T>Személyzet</T> és <T>Szabályzat</T> fülre.\n• Kattints <a href='event:discord'><o>ide</o></a> a Discord meghívó linkért és <a href='event:map_submission'><o>ide</o></a> kattintva megkaphatod a pályabenyújtási téma linkjét.\n• Használd a <o>fel</o> és <o>le</o> nyilakat, amikor görgetned kell a menüben.\n\n<p align = 'center'><font size = '13'><T>A hozzájárulások már nyitva vannak! További részletekért kattints a <O>Hozzájárulás</O> fülre!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>FELHÍVÁS: A Parkour személyzet NEM Transformice személyzet és NEM rendelkeznek hatalommal a játékban, csak a modulon belül.</r>\nA Parkour személyzete gondoskodik arról, hogy a modul zökkenőmentesen működjön minimális problémákkal. Ők mindig rendelkezésre állnak, hogy szükség esetén segítsék a játékosokat.</font></p>\nÍrd be a <D>!staff</D> parancsot a chatbe, hogy lásd a személyzet listáját.\n\n<font color = '#E7342A'>Rendszergazdák <i>(admin)</i>:</font> Ők felelnek a modul karbantartásáért az új frissítések és hibák kijavításával.\n\n<font color = '#D0A9F0'>Csapatvezetők <i>(manager)</i>:</font> Ők felügyelik a Moderátorok és Pálya legénység csapatát odafigyelve arra, hogy megfelelően végezzék a munkájukat. Továbbá ők felelősek az új tagok toborzásáért a személyzet csapatába.\n\n<font color = '#FFAAAA'>Moderátorok <i>(mod)</i>:</font> Ők felelnek a modul szabályzatának betartásáért és a rájuk nem hallgató személyek büntetéséért.\n\n<font color = '#25C059'>Pálya legénység <i>(mapper)</i>:</font> Ők felelnek a pályák felülvizsgálatáért, hozzáadásáért és eltávolításáért a modulon belül annak érdekében, hogy a játékmenet élvezetes legyen.",
		help_rules = "<font size = '13'><B><J>A Transformice Általános Szerződési feltételeinek minden szabálya vonatkozik a #parkour-ra</J></B></font>\n\nHa olyan játékost találsz, aki megsérti a szabályokat, akkor suttogásban szólj a moderátoroknak. Ha nem érhető el moderátor, akkor jelentsd a játékost a Discord felületen.\nJelentéskor kérjük, add meg a szerver-, a szoba- és a játékos nevét.\n• Például: hu-#parkour10 Blank#3495 trolling\nA bizonyítékok, mint például képernyőfotók, videók és gifek hasznosak és értékeljük, de nem szükségesek.\n\n<font size = '11'>• A #parkour szobákban nem lehet <font color = '#ef1111'>hacket, glitcheket vagy bugokat</font> használni.\n• A <font color = '#ef1111'>VPN farmolást</font> <B>kizsákmányolásnak</B> tekintjük, és nem engedélyezettek. <p align = 'center'><font color = '#cc2222' size = '12'><B>\n\nBárkit, akit szabályszegésen kapunk, azonnal kitiltjuk.</B></font></p>\n\n<font size = '12'>A Transformice engedélyezi a trollkodást, ettől függetlenül <font color='#cc2222'><B>a parkour-ban nem engedélyezzük ezt.</B></font></font>\n\n<p align = 'center'><J>Trollkodás akkor következik, ha egy játékos szándékosan arra használja a képességeit vagy fogyóeszközeit, hogy más játékosokat megakadályozzon a pálya végig játszásában.</j></p>\n• Bosszúból trollkodni nem megfelelő indok, és még mindig büntetjük.\n• Trollkodásnak tekintjük azt is, amikor egy játékos a kérés ellenére is megpróbálja segíteni azt a játékost, aki egyedül akarja végigjátszani a pályát.\n• <J>Ha egy játékos nem akar segítséget vagy egy pályát jobban szeretné egyedül végigjátszani, kérjük, segíts más játékosnak</J>. Ettől függetlenül, ha egy másik játékosnak segítségre van szüksége ugyan abban az ellenőrző pontban, akkor segíthetsz nekik [mindkettőnek].\n\nHa egy játékos trollkodik, azonnal büntetve lesz. Vedd figyelembe, hogy az ismétlődő trollkodás hosszabb és súlyosabb büntetésekkel jár.",
		help_contribute = "<font size='14'>\n<p align='center'>A parkour menedzsment csapata szereti a nyílt forráskódot, mert ez <t>segít a közösségnek</t>. <o>Megtekintheted</o> és <o>módosíthatod</o> a nyílt forráskódot a <o><u><a href='event:github'>GitHub</a></u></oú>-on.\n\nA modul karbantartása <t>szigorúan önkéntes</t>, ezért a <t>kód</t> olvasásával, <t>hibajelentésekkel</t>, <t>javaslatokkal</t> és <t>pályakészítéssel</t> kapcsolatos bármilyen segítséget <u>mindig örömmel fogadunk és értékeljük</u>.\nTehetsz <vp>hibajelentéseket</vp> és <vp>javaslatokat</vp> a <o><u><a href='event:discord'>Discord</a></u></o>-on és/vagy <o><u><a href='event:github'>GitHub</a></u></o>-on.\nA <vp>pályádat beküldheted</vp> a mi <o><u><a href='event:map_submission'>Fórum témánkba</a></u></o>.\n\nA parkour fenntartása nem drága, de nem is ingyenes. Szeretnénk, ha <t>bármekkora összeggel</t> támogatnál minket <o><u><a href='event:donate'>ide</a></u></o> kattintva.\n<u>Minden támogatás a modul fejlesztésére irányul.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Verzió 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Küldetésrendszer kivitelezve. (Nyomd meg a  <J><B>,</B></J> hogy megnyisd a küldetés oldalt.)\n\n<font size='11'>• <font size='13'>Hozzáadtunk a lehetőséget a gyorsbillenytűk letiltására minden felülethez, mint pl. ranglista, súgó, bolt, stb.)\n\n<font size='11'>• <font size='13'>Hozzáadtuk a <B><J>!cp [JátékosNév#tag]</J></B> parancsot hogy be tudd állítani a saját szintedet az adott játékos szintjére.",	
		
		-- Congratulation messages
		reached_level = "<d>Gratulálunk! Elérted a következő szintet: <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> befejezte a parkour pályát <vp>%s</vp> másodperc alatt. <fc>Gratulálunk!",
		unlocked_power = "<ce><d>%s</d> feloldotta a(z) <vp>%s</vp> képességet.",
	
		-- Information messages
		mod_apps = "<j>A Parkour Moderátor jelentkezések nyitva vannak! Használd ezt a linket: <rose>%s",
		staff_power = "<r>A parkour személyzetének <b>nincs</b> hatalma a #parkour pályákon kívül.",
		donate = "<vp>Írd be a <b>!donate</b> parancsot, ha adományozni szeretnél a modul részére!",
		paused_events = "<cep><b>[Figyelem!]</b> <n>A modul elérte a kritikus határát, így szüneteltetés alatt áll.",
		resumed_events = "<n2>A modul folytatódik.",
		welcome = "<n>Üdvözlünk a <t>#parkour</t>-on!",
		module_update = "<r><b>[Figyelem!]</b> <n>A modul frissül <d>%02d:%02d</d> percen belül.",
		leaderboard_loaded = "<j>A ranglista be lett töltve. Nyomd meg az <b>L</b> gombot a megnyitásához.",
		kill_minutes = "<R>A képességeidet %s percre letiltottuk.",
		permbanned = "<r>Véglegesen ki lettél tiltva a #parkour-ból.",
		tempbanned = "<r>Ki lettél tiltva %s másodpercre a #parkour-ból.",
		forum_topic = "<rose>Ha szeretnél több információt a modulról látogasd meg a linket: %s",
		report = "<j>Jelenteni szeretnél egy parkour játékost? <t><b>/c Parkour#8558 .report Felhasználónév0000</b></t>",
		killed = "<v>[#] <r>A parkour szabályainak megsértése miatt %s percig nem használhatod képességeidet. A szabályok folyamatos megsértése kitiltást von maga után. Nyomd meg a <b>H</b> gombot a szabályok áttekintéséhez.",
		mapper_event = "<CE><B>Parkour pályakészítő verseny 2024:</B>\n<n>Mutasd meg a kreativitásodat pályakészítésben, hogy esélyed legyen nyerni<D>sajt érmét <n>és <pt>parkour érmét<n>!\n<R>Jelentkezni lehet eddig: <B>Január 31, 2024</B>.\n<PS>Több infóért látogass el ide: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Szóval a visszaszámlálás elkezdődött...",
		easter_egg_1  = "<ch>Kevesebb, mint 24 óra maradt hátra!",
		easter_egg_2  = "<ch>Wow, korán érkeztél! Túl izgatott vagy?",
		easter_egg_3  = "<ch>A meglepetés már vár...",
		easter_egg_4  = "<ch>Tudod, hogy mi fog történni...?",
		easter_egg_5  = "<ch>Az óra ketyeg tovább...",
		easter_egg_6  = "<ch>A meglepetés már közel!",
		easter_egg_7  = "<ch>A party épphogy kezdődik...",
		easter_egg_8  = "<ch>Csekkold az órád, eljött már az idő?",
		easter_egg_9  = "<ch>Légy óvatos, az idő eltelik...",
		easter_egg_10 = "<ch>Csak dőlj hátra és pihenj, nemsoká holnap lesz!",
		easter_egg_11 = "<ch>Feküdj le hamar, úgy gyorsabban telik az idő!",
		easter_egg_12 = "<ch>A türelem egy jó tulajdonság",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Dupla pályák egész Szombaton (GMT+2) és az összes erő aktiválva van a parkour szülinapi hetén!",
		double_maps_start = "<rose>ELJÖTT A PARKOUR SZÜLINAPI HETE! Duplán számítanak a pályák, és az összes erő elérhető. Köszönjük, hogy velünk játszol!",
		double_maps_end = "<rose>A parkour szülinapi hete véget ért. Köszönjük, hogy velünk játszol!",
	
		-- Records
		records_enabled = "<v>[#] <d>Rekord mód lett aktiválva ebben a szobában. Az adatok nem számítanak és a képességek nem engedélyezettek!\nTöbb információt találhatsz a Rekordról itt: <b>%s</b>",
		records_admin = "<v>[#] <d>Egy adminisztrátor vagy ebben a Rekord szobában. Használhatod a <b>!map</b>, <b>!setcp</b>, <b>!pw</b> és <b>!time</b> parancsokat.",
		records_completed = "<v>[#] <d>Teljesítetted a pályát! Ha újra akarod csinálni, írd be: <b>!redo</b>.",
		records_submit = "<v>[#] <d>Hűha! Úgy tűnik, te voltál a leggyorsabb a szobában. Ha be szeretnéd küldeni a rekordod, írd be: <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Úgy tűnik, hogy ez a pálya nincs a Parkour körforgásában... Nem tudod benyújtani a rekordod!",
		records_not_fastest = "<v>[#] <r>Úgy tűnik, nem te vagy a leggyorsabb játékos a szobában...",
		records_already_submitted = "<v>[#] <r>Már beküldted a rekordod ehhez a pályához!",
		records_submitted = "<v>[#] <d>A <b>%s</b> rekordod ehhez a pályához be lett küldve.",
	
		-- Quests
		daily_q = "Napi",
		weekly_q = "Heti",
		daily_quests = "<p align='center'><font size='20'><B><D>Napi küldetések</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Heti küldetések</D></B></font>",
		quest_1 = "Teljesíts  <B><D>%s/%s</D></B> pályát.",
		quest_2 = "Gyűjts <B><D>%s/%s</D></B> checkpointot.",
		quest_3 = "Teljesítsd bármelyik pályát az első helyen <B><D>%s/%s</D></B> alkalommal.",
		quest_4 = "Teljesíts egy pályát kevesebb mint <B><D>%s</D></B> másodperc alatt.",
		quest_5 = "Teljesítsd ezt a pályát: <B><D>@%s</D></B>",
		quest_6 = "Használd a/z <PT><b>%s</b></PT> képességet <B><D>%s/%s</D></B> alkalommal.",
		next_reset = "<b><D>Frissül:\n</b></D>%s",
		quest_completed = "<b><D>Gratulálunk!</D></b> \nTeljesítetted a %s küldetést!",
		quest_reset = "<V>[#]</V> <O>A %s küldetéseid frissültek.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Mikulás épp itt volt! Vadássz a Karácsonyi ajándék után a pályán, és bontsd ki a meglepetést!",
	    find_gift2 = "<ch>Cseng és bong az út! Egy különleges Karácsonyi ajándék csodás módon előbukkant a pályán - keresd meg!",
	    find_gift3 = "<ch>Ho, ho, hó! Mikulás kis segédje itthagyott egy ajándékot neked, hogy megtaláld az aktuális pályán!",
	    find_gift4 = "<ch>Karácsony szelleme már köztünk száll! Találd meg a rejtett Karácsonyi ajándékot a pályán!",
	    find_gift5 = "<ch>Boldog Parkourácsonyt! A manók elrejtettek egy titkos ajándékot neked. Meg fogod tudni találni?",
	    found_gift1 = "<ch>Hurrá! <J>%s</J> kibontotta az ajándékot és talált %s érmét benne!",
	    found_gift2 = "<ch>Hurrá, <J>%s</J>! Te nyertél <J>%s</J> fényes érmét a Mikulás varázslatos ajándékából!",
	    found_gift3 = "<ch>A nyertes épp <J>%s</J>! <J>%s</J> érmével gazdagabb, Mikulásnak köszönhetően!",
	    found_gift4 = "<ch>Gratuláció neked <J>%s</J> mert nyertél <J>%s</J> érmét! A Karácsony szelleme fényesen ragyog!",
	    found_gift5 = "<ch>Mikulás ajándéka megjutalmazta <J>%s</J> -t <J>%s</J> káprázatos érmével!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>AFK MÓDBAN VAGY</b></bv>\nMOZOGJ HOGY ÚJRAÉLEDJ</font>\n\n<font size='30'><u><t>Emlékeztetők:</t></u></font>\n\n<font size='15'><r>A játékosok piros vonallal a fejük felett nem kérnek segítséget!\nTrollkodás/blokkolás más játékosokkal szemben a parkourban NEM megengedett!<d>\nCsatlakozz a <cep><a href='event:discord'>discord szerverünkhöz</a></cep>!\nSzertnél közreműködni kódolással? Tekintsd meg a <cep><a href='event:github'>github gyűjteményünket</a></cep>\nVan egy jó pályád amit bemutatnál? Posztold ki a <cep><a href='event:map_submission'>pálya beadvány témához</a></cep>\nCsekkold le a <cep><a href='event:forum'>official topic fület</a></cep> több információért!\nTámogass minket <cep><a href='event:donate'>adománnyal!</a></cep>",
		options = "<p align='center'><font size='20'>Parkour Beállítások</font></p>\n\nHasználd a <b>QWERTY</b> billentyűzetet (tiltsd le, ha <b>AZERTY</b>-d van)\n\nHasználd az <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> gombot a <b>/mort</b> parancshoz (tiltsd le, ha <b>DEL</b> legyen)\n\nMutassa a képességek újratöltési idejét\n\nMutassa a <b>képességek</b> gombot\n\nMutassa a <b>segítség</b> gombot\n\nMutassa a teljesített pályák mennyiségét\n\nJelenítse meg a <b>nincs segítség</b> szimbólumot\n\nGyorsbillentyűk kikapcsolása (ranglista, segítség, bolt, stb.)",
		cooldown = "<v>[#] <r>Várj néhány másodpercet, mielőtt újra ezt tennéd.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> billentyűzet" ..
						 "\n\nTeljesített pályák <b>elrejtése</b>" ..
						 "\n\nUse <b>default key</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Teljesíts <v>%s</v> pályát" ..
						"<font size='5'>\n\n</font>a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>feloldásához"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Teljesíts <v>%s</v> pályát" ..
						"<font size='5'>\n\n</font>a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>frissítéséhez"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Érd el a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>rangot a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>feloldásához"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Érd el a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>rangot a(z) <v>%s</v>" ..
						"<font size='5'>\n\n</font>frissítéséhez"),
		maps_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Teljesített pálya"),
		overall_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'>Pozíció a Teljes ranglistán:" ..
						"<font size='5'>\n\n</font><b><v>%s</v></b>"),
		weekly_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'>Pozíció a Heti ranglistán:" ..
					   "<font size='5'>\n\n</font><b><v>%s</v></b>"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Kitűzők (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>A játékos teljesített pályáinak száma privát. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Pozíció a Teljes ranglistán: <b><v>%s</v></b>\n\n" ..
					"Pozíció a Heti ranglistán: <b><v>%s</v></b>\n\n%s"),
		map_count = "Pályák száma: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Befejezett pályák: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Összegyűjtött ellenőrző pontok: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "A Kitűzők olyan eredmények, melyeket a játékosok szerezhetnek. Kattints rájuk, hogy lásd a leírásukat.",
		help_private_maps = "A játékos nem szeretné nyilvánosan megosztani a Teljesített pályáinak a számát! Te is elrejtheted a profilodon.",
		help_yellow_maps = "A sárga pálya teljesítve lett ezen a héten.",
		help_red_maps = "A piros pálya teljesítve lett az elmúlt egy órában.",
		help_map_count_title = "Szerezhetsz <b>Transformice</b> címeket, ha befejezed a pályákat.",
		help_checkpoint_count_title = "Szerezhetsz <b>Transformice</b> címeket, ha eléred az összes ellenőrző pontot.",
		help_badge_1 = "Ez a játékos korábban a parkour személyzetének tagjai között volt.",
		help_badge_2 = "Ez a játékos Teljes ranglistán az 1. oldalon van/volt.",
		help_badge_3 = "Ez a játékos Teljes ranglistán az 2. oldalon van/volt.",
		help_badge_4 = "Ez a játékos Teljes ranglistán az 3. oldalon van/volt.",
		help_badge_5 = "Ez a játékos Teljes ranglistán az 4. oldalon van/volt.",
		help_badge_6 = "Ez a játékos Teljes ranglistán az 6. oldalon van/volt.",
		help_badge_7 = "Ez a játékos a Heti ranglistán a dobogón volt.",
		help_badge_8 = "Ennek a játékosnak a rekordja 30 pálya/óra.",
		help_badge_9 = "Ennek a játékosnak a rekordja 35 pálya/óra.",
		help_badge_10 = "Ennek a játékosnak a rekordja 40 pálya/óra.",
		help_badge_11 = "Ennek a játékosnak a rekordja 45 pálya/óra.",
		help_badge_12 = "Ennek a játékosnak a rekordja 50 pálya/óra.",
		help_badge_13 = "Ennek a játékosnak a rekordja 55 pálya/óra.",
		help_badge_14 = "Ez a játékos hitelesítette a discord fiókját a Parkour hivatalos Discord szerverén (írd be <b>!discord</b>).",
		help_badge_15 = "Ez a játékos volt a leggyorsabb a pályán 1 alkalommal.",
		help_badge_16 = "Ez a játékos volt a leggyorsabb a pályán 5 alkalommal.",
		help_badge_17 = "Ez a játékos volt a leggyorsabb a pályán 10 alkalommal.",
		help_badge_18 = "Ez a játékos volt a leggyorsabb a pályán 15 alkalommal.",
		help_badge_19 = "Ez a játékos volt a leggyorsabb a pályán 20 alkalommal.",
		help_badge_20 = "Ez a játékos volt a leggyorsabb a pályán 25 alkalommal.",
		help_badge_21 = "Ez a játékos volt a leggyorsabb a pályán 30 alkalommal.",
		help_badge_22 = "Ez a játékos volt a leggyorsabb a pályán 35 alkalommal.",
		help_badge_23 = "Ez a játékos volt a leggyorsabb a pályán 40 alkalommal.",
		make_public = "nyilvános",
		make_private = "privát",
		moderators = "Moderátorok",
		mappers = "Pálya legénység",
		managers = "Csapatvezetők",
		administrators = "Rendszergazdák",
		close = "Bezár",
		cant_load_bot_profile = "<v>[#] <r>Nem láthatod ennek a BOT-nak a profilját, mivel valószínűleg a #parkour a belső működésekhez használja.",
		cant_load_profile = "<v>[#] <r><b>%s</b> felhasználó kijelentkezett állapotban van vagy nem létezik.",
		like_map = "Tetszik ez a pálya?",
		yes = "Igen",
		no = "Nem",
		idk = "Nem tudom",
		vote_map = "<font color='#ffffff' size='13'><b>Tetszik ez a pálya? <font size='14'><a href='event:mapPollYes'><PT>Igen</a> <a href='event:mapPollidk'><N>Nem tudom</a> <a href='event:mapPollNo'><R>Nem</a>",
		unknown = "Ismeretlen",
		powers = "Képességek",
		press = "<vp>Nyomd meg: %s",
		click = "<vp>Bal klikk",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Teljesített pályák: %s</B></p></BV>",
		leaderboard = "Ranglista",
		position = "<V><p align=\"center\">Pozíció",
		username = "<V><p align=\"center\">Felhasználónév",
		community = "<V><p align=\"center\">Közösség",
		completed = "<V><p align=\"center\">Teljesített pályák",
		overall_lb = "Teljes",
		weekly_lb = "Heti",
		new_lang = "<v>[#] <d>A játék nyelvét Magyarra változtattad",
		room = "Szoba",
		time = "Idő",
		buy = "Buy",
		equip = "Equip",
		equipped = "<font size = '10'>Equipped</font>",
		saving = "<p align='right'>Mentés...",
	
		-- Power names
		balloon = "Léggömb",
		masterBalloon = "Léggömb II",
		bubble = "Léggömb III",
		fly = "Repülés",
		snowball = "Hógolyó",
		speed = "Gyorsítás",
		teleport = "Teleport",
		smallbox = "Kis doboz",
		cloud = "Felhő",
		rip = "Sírkő",
		choco = "Csokoládé deszka",
		bigBox = "Nagy doboz",
		trampoline = "Trambulin",
		toilet = "Toalet",
		pig = "Malac",
		sink = "Mosdókagyló",
		bathtub = "Fürdőkád",
		campfire = "Tábortűz",
		chair = "Szék",
		link = "Lélektárs",
	}
	--[[ End of file translations/parkour/hu.lua ]]--
	--[[ File translations/parkour/id.lua ]]--
	translations.id = {
	    name = "id",
	    fullname = "Bahasa Indonesia",
	
	    -- Error messages
	    corrupt_map = "<r>Peta rusak. Sedang Memuat peta lainnya.",
	    corrupt_map_vanilla = "<r>[KESALAHAN] <n>Tidak bisa mendapatkan informasi dari peta ini.",
	    corrupt_map_mouse_start = "<r>[KESALAHAN] <n>Peta ini harus memiliki posisi awal (titik spawn tikus).",
	    corrupt_map_needing_chair = "<r>[KESALAHAN] <n>Peta harus memiliki kursi di akhir.",
	    corrupt_map_missing_checkpoints = "<r>[KESALAHAN] <n>Peta harus memiliki setidaknya satu cekpoin (paku kuning).",
	    corrupt_data = "<r>Sayangnya, data anda rusak dan telah disetel ulang.",
	    min_players = "<r>Untuk menyimpan data anda, setidaknya ada 4 pemain unik di ruangan ini. <bl>[%s/%s]",
	    tribe_house = "<r>Data tidak akan tersimpan di Rumah suku.",
	    invalid_syntax = "<r>Sintaks tidak valid.",
	    code_error = "<r>Terjadi kesalahan: <bl>%s-%s-%s %s",
	    emergency_mode = "<r>Penghentian darurat, tidak ada pemain baru diizinkan. Dimohon untuk pergi ke ruangan #parkour lain.",
	    leaderboard_not_loaded = "<r>Papan peringkat belum bisa dimuat. Mohon Tunggu sebentar.",
	    max_power_keys = "<v>[#] <r>Anda hanya bisa memiliki paling banyak %s kemampuan dengan kata kunci yang sama.",
	
	    -- Help window
	    help = "Bantuan",
	    staff = "Staff",
	    rules = "Peraturan",
	    contribute = "Kontribusi",
	    changelog = "Berita",
	    help_help = "<p align = 'center'><font size = '14'>Selamat datang di ruangan <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Tujuan anda adalah meraih semua cekpoin sebelum menyelesaikan peta</J></p>\n\n<N>• Tekan <O>O</O>, ketik <O>!op</O> atau klik pada <O>tombol konfigurasi</O> untuk membuka <T>menu Opsi</T>.\n• Tekan <O>P</O> atau klik <O>ikon kepalan tangan</O> pada kanan atas untuk membuka <T>menu Kemampuan</T>.\n• Tekan <O>L</O> atau ketik <O>!lb</O> untuk membuka <T>Papan Peringkat</T>.\n• Tekan <O>M</O> atau tombol <O>Delete</O> untuk <T>/mort</T>, anda bisa mengaktifkan tombol di menu <J>Opsi</J>.\n• Untuk mengetahui <O>staf</O> kami dan <O>aturan parkour</O>, klik pada tab <T>Staf</T> dan <T>Peraturan</T>.\n• Klik <a href='event:discord'><o>disini</o></a> untuk mendapatkan tautan discord dan <a href='event:map_submission'><o>disini</o></a> untuk mendapatkan tautan topik mengenai pengajuan peta.\n• Gunakan <o>atas</o> dan <o>bawah</o> tombol panah ketika anda ingin melakukan scroll.\n\n<p align = 'center'><font size = '13'><T>Kontribusi telah dibuka! Untuk info lebih lanjut, klik pada tab <O>Kontribusi</O>!</T></font></p>",
	    help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Staf Parkour BUKAN staf Transformice dan TIDAK memiliki wewenang apapun didalam game itu sendiri, hanya di dalam modul.</r>\nStaf parkour memastikan modul berjalan sempurna dengan masalah yang minim, dan akan selalu tersedia untuk membantu pemain kapan pun dibutuhkan.</font></p>\nanda bisa mengetik <D>!staff</D> di chat untuk melihat list staf.\n\n<font color = '#E7342A'>Admin:</font> Mereka bertanggung jawab dalam mengembangkan modul dengan menambahkan update baru ataupun memperbaiki bug.\n\n<font color = '#D0A9F0'>Manager Tim:</font> Mereka mengawasi tim dari moderator dan mappers untuk memastikan mereka mengerjakan perkerjaan mereka dengan baik. Mereka juga bertanggung jawab untuk merekrut anggota baru ke tim staf.\n\n<font color = '#FFAAAA'>Moderator:</font> Mereka bertanggung jawab untuk menegakkan aturan dari modul dan memberikan sanksi untuk individu yang tidak mengikutinya.\n\n<font color = '#25C059'>Mappers:</font> Mereka bertanggung jawab dalam meninjau, menambahkan, menghapus peta yang ada di modul untuk memastikan permainan yang menyenangkan.",
	    help_rules = "<font size='13'><B><J>Semua aturan dalam Syarat dan Ketentuan Transformice berlaku juga di #parkour</J></B></font>\n\nJika anda menemukan pemain yang melanggar aturan tersebut, bisik moderator di game. Jika tidak ada moderator yang online, dianjurkan untuk melaporkan melalui server discord. \nKetika melaporkan, mohon untuk melampirkan server, nama ruangan, dan nama pemain. \n• Contoh: en-#parkour10 Blank#3495 trolling\nBukti seperti tangkapan layar, video, atau gif sangat membantu dan dihargai, tetapi tidak perlu.\n\n<font size='11'>• Tidak ada <font color='#ef1111'>hacks, glitches or bugs</font> yang digunakan di ruangan #parkour.\n• <font color='#ef1111'>VPN farming</font> akan dianggap sebagai <B>mengeksploitasi</B> dan tidak diizinkan.<p align='center'><font color='#cc2222' size='12'><B>\nSiapapun yang ketahuan melanggar aturan ini akan segera diblokir.</B></font></p>\n\n<font size='12'>Transformice mengizinkan konsep trolling. Namun, <font color='#cc2222'><B>kami tidak mengizinkannya di parkour.</B></font></font>\n\n<p align='center'><J>Trolling adalah ketika seorang pemain dengan sengaja menggunakan kemampuan atau consumables untuk mencegah pemain lain dalam menyelesaikan peta.</j></p>\n• Trolling balas dendam<B> bukan sebuah alasan yang valid</B> untuk melakukan troll kepada seseorang dan anda akan tetap diberi hukuman.\n• Memaksa membantu pemain yang mencoba untuk menyelesaikan peta sendirian dan menolak untuk berhenti melakukannya jika diminta juga termasuk sebagai trolling\n• <J>Jika seorang pemain tidak ingin bantuan dan lebih memilih solo, lebih baik membantu pemain yang lain</J>. Namun jika ada pemain lain yang meminta bantuan di cekpoin yang sama dengan pemain solo, anda bisa membantu mereka [Keduanya].\n\nJika pemain tertangkap melakukan trolling, mereka akan mendapatkan hukuman berbasis waktu. Perlu diperhatikan bahwa trolling yang berulang akan mengakibatkan hukuman yang lebih lama dan lebih berat.",
	    help_contribute = "<font size='14'>\n<p align='center'>Tim managemen parkour menyukai kode sumber terbuka karena itu  <t>membantu komunitas</t>. anda bisa <o>melihat</o> dan <o>memodifikasi</o> kode sumber dari <o><u><a href='event:github'>GitHub</a></u></o>.\n\nMemelihara modul <t>sepenuhnya bersifat sukarela</t>, sehingga bantuan mengenai <t>kode</t>, <t>laporan bug</t>, <t>saran</t> dan <t>pembuatan peta</t> selalu <u>diterima dan dihargai</u>.\nanda bisa <vp>melaporkan bug</vp> dan <vp>memberikan saran</vp> pada <o><u><a href='event:discord'>Discord</a></u></o> dan/atau <o><u><a href='event:github'>GitHub</a></u></o>.\nanda bisa <vp>mengirimkan peta anda</vp> di <o><u><a href='event:map_submission'>Forum Thread</a></u></o> kami.\n\nMemelihara parkour memang tidak mahal, tapi juga tidak gratis. Kami akan senang jika anda bisa membantu kami dengan <t>berdonasi berapapun jumlahnya</t> <o><u><a href='event:donate'>disini</a></u></o>.\n<u>Semua donasi akan digunakan untuk meningkatkan modul.</u></p>",
	    help_changelog = "<font size='13'><p align='center'><o>Versi 2.14.0 - 24/10/2023</o></p>\n\n<font size='11'>• <font size='13'>Menambahkan sistem toko, memungkinkan pemain untuk mendapakan koin dengan menyelesaikan peta dan membeli skin kotak kecil, kotak besar, balon, trampolin dan  papan cokelat",
	
	    -- Congratulation messages
	    reached_level = "<d>Selamat! Kamu telah menyelesaikan level <vp>%s</vp>. (<t>%ss</t>)",
	    finished = "<d><o>%s</o> telah menyelesaikan parkour dalam <vp>%s</vp> detik, <fc>selamat!",
	    unlocked_power = "<ce><d>%s</d> telah membuka kemampuan <vp>%s</vp>.",
	
	    -- Information messages
	    mod_apps = "<j>Aplikasi untuk moderator parkour telah dibuka! Gunakan link ini: <rose>%s",
	    staff_power = "<p align='center'><font size='12'><r>Staf parkour <b>tidak memiliki</b> wewenang apapun di selain ruangan #parkour.",
	    donate = "<vp>Ketik <b>!donate</b> jika anda ingin berdonasi untuk modul ini!",
	    paused_events = "<cep><b>[Perhatian!]</b> <n>Modul mencapai batas kritis terpaksa dihentikan sementara.",
	    resumed_events = "<n2>Modul telah dimulai kembali.",
	    welcome = "<n>Selamat datang di <t>#parkour</t>!",
	    module_update = "<r><b>[Perhatian!]</b> <n>Modul akan diperbarui dalam waktu <d>%02d:%02d</d>.",
	    leaderboard_loaded = "<j>Papan peringkat sudah dimuat. Ketuk L untuk membukanya.",
	    kill_minutes = "<R>Kemampuan anda dimatikan paksa selama %s menit.",
	    permbanned = "<r>Anda telah diblokir selamanya di #parkour.",
	    tempbanned = "<r>Anda telah diblokir dari #parkour selama %s menit.",
	    forum_topic = "<rose>Untuk informasi lebih lanjut mengenai modul kunjungi tautan: %s",
	    report = "<j>Ingin melaporkan seorang pemain? <t><b>/c Parkour#8558 .report Username#0000</b></t>",
	    killed = "<v>[#] <r>Kamu dibatasi dalam menggunakan kekuatan selama %s menit karena melanggar aturan parkur. Pelanggaran yang berlanjut akan mendapatkan hukuman ban. Mohon menekan <b>H</b> untuk melihat aturan.",
	    mapper_event = "<CE><B>Kontes Pembuatan Peta Parkour 2024:</B>\n<n>Tunjukkan kreativitas kamu dalam pembuatan peta untuk kesempatan memenangkan <D>koin keju <n>dan <pt>koin parkour<n>!\n<R>Pengajuan dibuka sampai <B>31 Januari 2024</B>.\n<PS>Untuk informasi lebih lanjut, kunjungi: %s",
	
	    -- Easter Eggs
	    easter_egg_0  = "<ch>Jadi penghitung waktu mundur dimulai...",
	    easter_egg_1  = "<ch>Kurang dari 24 jam lagi!",
	    easter_egg_2  = "<ch>Woah, anda terlalu cepat! Apakah anda bersemangat?",
	    easter_egg_3  = "<ch>Sebuah kejutan sedang menunggu...",
	    easter_egg_4  = "<ch>Apakah anda mengetahui apa yang akan terjadi...?",
	    easter_egg_5  = "<ch>Jam terus berjalan...",
	    easter_egg_6  = "<ch>Kejutannya sudah dekat!",
	    easter_egg_7  = "<ch>Perayaannya akan segera dimulai...",
	    easter_egg_8  = "<ch>Cek jam anda, apakah sudah waktunya?",
	    easter_egg_9  = "<ch>Hati-hati, waktu terus berlalu...",
	    easter_egg_10 = "<ch>Cukup duduk dan rileks, itu akan terjadi besok!",
	    easter_egg_11 = "<ch>Ayo pergi tidur lebih cepat, itu akan membuat waktu lebih cepat!",
	    easter_egg_12 = "<ch>Kesabaran adalah sebuah kebajikan",
	    easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
	    double_maps = "<bv>Peta ganda pada hari Minggu (GMT+2) dan semua kekuatan  tersedia untuk minggu ulang tahun parkur!",
	    double_maps_start = "<rose>HARI INI ADALAH MINGGU ULANG TAHUN PARKUR! Peta ganda dan semua kekuatan telah diaktifkan. Terima kasih telah bermain dengan kami!",
	    double_maps_end = "<rose>Minggu ulang tahun parkur berakhir. Terima kasih telah bermain bersama kami!",
	
	    -- Records
	    records_enabled = "<v>[#] <d>Mode rekor diaktifkan di room ini. Statistik tidak dihitung dan kekuatan tidak diaktifkan!\nAnda bisa mencari informasi lebih lanjut mengenai rekor di <b>%s</b>",
	    records_admin = "<v>[#] <d>Anda adalah admin di ruangan rekor ini. Anda bisa menggunakan perintah <b>!map</b>, <b>!setcp</b>, <b>!pw</b> dan <b>!time</b>.",
	    records_completed = "<v>[#] <d>Anda telah menyelesaikan peta! Jika anda ingin mengulangi-nya lagi, ketik <b>!redo</b>.",
	    records_submit = "<v>[#] <d>Wow! Sepertinya anda memiliki waktu tercepat di ruangan. Jika anda ingin mengirimkan rekor anda, ketik <b>!submit</b>.",
	    records_invalid_map = "<v>[#] <r>Sepertinya ruangan ini tidak masuk dalam rotasi parkour... Anda tidak bisa mengirim rekor ini!",
	    records_not_fastest = "<v>[#] <r>Sepertinya anda bukan pemain tercepat di ruangan ini...",
	    records_already_submitted = "<v>[#] <r>Anda sudah mengirimkan rekor anda untuk peta ini!",
	    records_submitted = "<v>[#] <d>Rekor anda untuk peta <b>%s</b> telah dikirim.",
	
	    -- Quests
	    daily_q = "Harian",
	    weekly_q = "Mingguan",
	    daily_quests = "<p align='center'><font size='20'><B><D>Kegiatan Harian</D></B></font>",
	    weekly_quests = "<p align='center'><font size='20'><B><D>Kegiatan Mingguan</D></B></font>",
	    quest_1 = "Menyelesaikan <B><D>%s/%s</D></B> peta.",
	    quest_2 = "Kumpulkan <B><D>%s/%s</D></B> checkpoin.",
	    quest_3 = "Selesaikan peta apa saja di posisi pertama <B><D>%s/%s</D></B> kali.",
	    quest_4 = "Selesaikan peta di bawah <B><D>%s</D></B> detik.",
	    quest_5 = "Selesaikan peta <B><D>@%s</D></B>",
	    quest_6 = "Menggunakan kekuatan <PT><b>%s</b></PT> <B><D>%s/%s</D></B> kali.",
	    next_reset = "<b><D>Atur ulang:\n</b></D>%s",
	    quest_completed = "<b><D>Selamat!</D></b> \nKamu menyelesaikan kegiatan %s!",
	    quest_reset = "<V>[#]</V> <O>Kegiatan %s kamu sudah di atur ulang.</O>",
	
	    -- Miscellaneous
	    afk_popup = "\n<p align='center'><font size='30'><bv><b>ANDA DALAM MODE AFK</b></bv>\nPINDAH UNTUK RESPAWN</font>\n\n<font size='30'><u><t>Pengingat:</t></u></font>\n\n<font size='15'><r>Pemain dengan simbol merah tidak menginginkan bantuan!\nTrolling/pemblokiran pemain lain di parkur TIDAK dizinkan!<d>\nBergabung dengan <cep><a href='event:discord'>discord server</a> kami</cep>!\nIngin berkontribusi dengan kode? Lihat <cep><a href='event:github'>repository github</a> kami</cep>\nKamu memiliki peta bagus untuk diajukan? Posting di <cep><a href='event:map_submission'>topik pengajuan peta</a> kami</cep>\nCek <cep><a href='event:forum'>topik resmi</a></cep> kami untuk informasi lebih lanjut!\nDukung kami dengan <cep><a href='event:donate'>donasi!</a></cep>",
	    options = "<p align='center'><font size='20'>Opsi Parkour</font></p>\n\nGunakan keyboard <b>QWERTY</b> (nonaktifkan jika <b>AZERTY</b>)\n\nTekan <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> hotkey untuk <b>/mort</b> (jika dinonaktifkan menjadi <b>DEL</b>)\n\nPerlihatkan cooldown kemampuan anda\n\nPerlihatkan tombol kemampuan\n\nPerlihatkan tombol bantuan\n\nAktifkan pengumuman penyelesaian peta\n\nAktifkan simbol tidak memerlukan bantuan\n\nDisable all UI (leaderboard, help, shop etc.) hotkeys",
	    cooldown = "<v>[#] <r>Mohon Tunggu beberapa detik untuk melakukan-nya kembali.",
	    power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'>Keyboard <b>QWERTY</b>" ..
	                    "\n\n<b>Tutup</b> penghitung peta" ..
	                    "\n\nGunakan <b>kunci default</b>"),
	    unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Selesaikan <v>%s</v> peta" ..
	                    "<font size='5'>\n\n</font>untuk membuka" ..
	                    "<font size='5'>\n\n</font><v>%s</v>"),
	    upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Selesaikan <v>%s</v> peta" ..
	                    "<font size='5'>\n\n</font>untuk meningkatkan ke" ..
	                    "<font size='5'>\n\n</font><v>%s</v>"),
	    unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Peringkat <v>%s</v>" ..
	                    "<font size='5'>\n\n</font>untuk membuka" ..
	                    "<font size='5'>\n\n</font><v>%s</v>"),
	    upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Peringkat <v>%s</v>" ..
	                    "<font size='5'>\n\n</font>untuk meningkatkan ke" ..
	                    "<font size='5'>\n\n</font><v>%s</v>"),
	    maps_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
	                "<font size='5'>\n\n</font>Peta yang diselesaikan"),
	    overall_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
	                    "<font size='5'>\n\n</font>Papan Peringkat Keseluruhan"),
	    weekly_info = ("<p align='center'><font size='11' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
	                    "<font size='5'>\n\n</font>Papan Peringkat Mingguan"),
	    badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Lencana (%s): <a href='event:_help:badge'><j>[?]</j></a>",
	    private_maps = "<bl>Jumlah peta pada pemain ini bersifat Pribadi. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
	    profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
	                "Posisi papan peringkat keseluruhan: <b><v>%s</v></b>\n\n" ..
	                "Posisi papan peringkat mingguan: <b><v>%s</v></b>\n\n%s"),
	    map_count = "Jumlah peta: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
	    title_count = ("<b><j>«!»</j></b> Peta diselesaikan <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
	                "<b><j>«!»</j></b> Cekpoin diperoleh: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
	    help_badge = "Lencana adalah pencapaian yang bisa didapatkan pemain. Klik diatasnya untuk melihat deskripsi-nya.",
	    help_private_maps = "Pemain ini tidak mau memperlihatkan jumlah peta mereka ke publik! jika ingin, anda juga bisa menyembunyikan-nya di profil anda.",
	    help_yellow_maps = "Peta dengan warna kuning adalah peta yang sudah diselesaikan dalam minggu ini.",
	    help_red_maps = "Peta dengan warna merah adalah peta yang sudah diselelesaikan dalam satu jam terakhir.",
	    help_map_count_title = "Kamu bisa mendapatkan gelar <b>Transformice</b> dengan menyelesaikan peta parkour!",
	    help_checkpoint_count_title = "Kamu bisa mendapatkan gelar <b>Transformice</b> dengan memperoleh semua checkpoin di peta parkour!",
	    help_badge_1 = "Pemain ini pernah menjadi anggota staf parkour sebelumnya.",
	    help_badge_2 = "Pemain ini berada atau pernah di halaman 1 dari papan peringkat keseluruhan.",
	    help_badge_3 = "Pemain ini berada atau pernah di halaman 2 dari papan peringkat keseluruhan.",
	    help_badge_4 = "Pemain ini berada atau pernah di halaman 3 dari papan peringkat keseluruhan.",
	    help_badge_5 = "Pemain ini berada atau pernah di halaman 4 dari papan peringkat keseluruhan.",
	    help_badge_6 = "Pemain ini berada atau pernah di halaman 5 dari papan peringkat keseluruhan.",
	    help_badge_7 = "Pemain ini pernah berada di podium pada akhir papan peringkat mingguan.",
	    help_badge_8 = "Pemain ini memiliki rekor menyelesaikan 30 peta per jam.",
	    help_badge_9 = "Pemain ini memiliki rekor menyelesaikan 35 peta per jam.",
	    help_badge_10 = "Pemain ini memiliki rekor menyelesaikan 40 peta per jam.",
	    help_badge_11 = "Pemain ini memiliki rekor menyelesaikan 45 peta per jam.",
	    help_badge_12 = "Pemain ini memiliki rekor menyelesaikan 50 peta per jam.",
	    help_badge_13 = "Pemain ini memiliki rekor menyelesaikan 55 peta per jam.",
	    help_badge_14 = "Pemain ini telah memverifikasi akun mereka di server discord resmi parkour (ketik <b>!discord</b>).",
	    help_badge_15 = "Pemain ini menjadi yang tercepat pada 1 peta.",
	    help_badge_16 = "Pemain ini menjadi yang tercepat pada 5 peta.",
	    help_badge_17 = "Pemain ini menjadi yang tercepat pada 10 peta.",
	    help_badge_18 = "Pemain ini menjadi yang tercepat pada 15 peta.",
	    help_badge_19 = "Pemain ini menjadi yang tercepat pada 20 peta.",
	    help_badge_20 = "Pemain ini menjadi yang tercepat pada 25 peta.",
	    help_badge_21 = "Pemain ini menjadi yang tercepat pada 30 peta.",
	    help_badge_22 = "Pemain ini menjadi yang tercepat pada 35 peta.",
	    help_badge_23 = "Pemain ini menjadi yang tercepat pada 40 peta.",
	    make_public = "publikasikan",
	    make_private = "privasikan",
	    moderators = "Moderator",
	    mappers = "Mappers",
	    managers = "Manager",
	    administrators = "Admin",
	    close = "Tutup",
	    cant_load_bot_profile = "<v>[#] <r>Anda tidak bisa melihat profil bot ketika #parkour menggunakan-nya secara internal untuk bekerja lebih baik.",
	    cant_load_profile = "<v>[#] <r>Pemain <b>%s</b> sepertinya sedang offline atau nama pemain ini tidak tersedia.",
	    like_map = "Apakah anda menyukai peta ini?",
	    yes = "Ya",
	    no = "Tidak",
	    idk = "Tidak tahu",
	    vote_map = "<font color='#ffffff' size='13'><b>Apakah anda menyukai peta ini? <font size='14'><a href='event:mapPollYes'><PT>Ya</a> <a href='event:mapPollidk'><N>Tidak tahu</a> <a href='event:mapPollNo'><R>Tidak</a>",
	    unknown = "Tidak diketahui",
	    powers = "Kemampuan",
	    press = "<vp>Tekan %s",
	    click = "<vp>Klik kiri",
	    ranking_pos = "Peringkat #%s",
	    completed_maps = "<p align='center'><BV><B>Peta diselesaikan: %s</B></p></BV>",
	    leaderboard = "Papan Peringkat",
	    position = "Peringkat",
	    username = "Nama panggilan",
	    community = "Komunitas",
	    completed = "Peta diselesaikan",
	    overall_lb = "Keseluruhan",
	    weekly_lb = "Mingguan",
	    new_lang = "<v>[#] <d>Bahasa telah diubah ke Bahasa Indonesia",
	    room = "Ruangan",
	    time = "Waktu",
	    buy = "Beli",
	    equip = "Pakai",
	    equipped = "<font size = '10'>Dipakai</font>",
	
	    -- Power names
	    balloon = "Balon",
	    masterBalloon = "Balon II",
	    bubble = "Balon III",
	    fly = "Terbang",
	    snowball = "Bola Salju",
	    speed = "Speed",
	    teleport = "Teleportasi",
	    smallbox = "Kotak Kecil",
	    cloud = "Awan",
	    rip = "Batu Nisan",
	    choco = "Papan Cokelat",
	    bigBox = "Kotak besar",
	    trampoline = "Trampolin",
	    toilet = "Toilet",
	    pig = "Babi",
	    sink = "Wastafel",
	    bathtub = "Bak Mandi",
	    campfire = "Api Unggun",
	    chair = "Kursi",
	    link = "Jodoh",
	
	}
	--[[ End of file translations/parkour/id.lua ]]--
	--[[ File translations/parkour/jp.lua ]]--
	translations.jp = {
		name = "jp",
		fullname = "日本語",
	
		-- Error messages
		corrupt_map = "<r>マップに問題がありました。別のマップを読み込み中。",
		corrupt_map_vanilla = "<r>[エラー] <n>このマップの情報を読み込めませんでした。",
		corrupt_map_mouse_start = "<r>[エラー] <n>マップにスタートポイント（ねずみの初期位置）が必要です。",
		corrupt_map_needing_chair = "<r>[エラー] <n>マップに椅子が必要です。",
		corrupt_map_missing_checkpoints = "<r>[エラー] <n>マップには少なくとも1つのチェックポイント（黄ネイル）が必要です。",
		corrupt_data = "<r>残念ながら、あなたのデータに問題が発生したため、リセットされました。",
		min_players = "<r>ルームに4人以上のプレーヤーがいないと、データは保存されません。<bl>[%s/%s]",
		tribe_house = "<r>トライブハウスにいると、データは保存されません。",
		invalid_syntax = "<r>Invalid syntax.",
		code_error = "<r>問題が発生しました: <bl>%s-%s-%s %s",
		emergency_mode = "<r>緊急シャットダウンを実行中。他の#parkourルームへ移動してください。",
		leaderboard_not_loaded = "<r>リーダーボードはまだ読み込み中。 しばらくお待ちください。",
		max_power_keys = "<v>[#] <r>同じキーには最大%sつのパワーしか持つことができません。",
	
		-- Help window
		help = "ヘルプ",
		staff = "スタッフ",
		rules = "ルール",
		contribute = "ご協力",
		changelog = "ニュース",
		help_help = "<p align = 'center'><font size = '14'><T>#parkour</T>へようこそ！</font></p>\n<font size = '12'><p align='center'><J>椅子にたどり着くまで、すべてのチェックポイントを通過しましょう。</J></p>\n\n<N>• 「<O>O</O>」を押す、「<O>!op</O>」と入力する、または<O>設定ボタン</O>をクリックすることで<T>設定メニュー</T>を開くことができます。\n• 「<O>P</O>」を押す、または右上の<O>手のアイコン</O>をクリックすることで、<T>パワーメニュー</T>を開くことができます。\n• <T>リーダーボード</T>を開くには、「<O>L</O>」を押し、あるいは「<O>!lb</O>」と入力します。\n• <T>自殺する</T>には「<O>M</O>」か「<O>Delete</O>」を押します。<J>設定</J>メニューからキーをトッグルできます。\n• Parkourの<O>スタッフ</O>や<O>ルール</O>についてもっと知りたいと思った場合、 <T>スタッフ</T>タブか<T>ルール</T>タブをクリックしてみてください。\n• Discordサーバーの招待リンクは<a href='event:discord'><o>こちら</o></a>。 マップ提供のリンクは<a href='event:map_submission'><o>こちら</o></a>。\n• <o>上矢印キー</o>と<o>下矢印キー</o>でスクロールできます。\n\n<p align = 'center'><font size = '13'><T>協力を開始しました！ 詳しくは「<O>ご協力</O>」タブをクリックしてください。</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>免責事項：ParkourスタッフはTransformiceスタッフではなく、ゲーム自体では何の権限も持たず、モジュール内でのみ権限を持ちます。</r>\nParkourスタッフは、モジュールが最小限の問題でスムーズに動作することを保証し、必要に応じていつでもプレイヤーを手伝います。</font></p>\nチャットに「<D>!staff</D>」と入力すると、スタッフのリストが表示されます。\n\n<font color = '#E7342A'>管理者：</font> 更新を追加したりバグを修正したりして、モジュール自体を保守する責任があります。\n\n<font color = '#D0A9F0'>チーム・マネージャー：</font> モデレーターとマッパーたちを監督し、適切に仕事を遂行していることを確認します。 また、スタッフチームに新しいメンバーを採用する責任もあります。\n\n<font color = '#FFAAAA'>モデレーター：</font> モジュールのルールを施行し、守らなかったプレイヤーを罰する責任があります。\n\n<font color = '#25C059'>マッパー：</font> 楽しいゲームプレイを保証するために、モジュール内のマップをレビュー、追加、削除する責任があります。",
		help_rules = "<font size = '13'><B><J>Transformiceに適用されるすべての利用規約は#parkourにも適用されます。</J></B></font>\n\nルールを破っているプレイヤーを見た場合、ゲーム内でParkourモデレーターにささやきしてください。 オンラインのモデレーターがいない場合は、Discordサーバーに報告することをお勧めします。\n報告の際は、サーバー名、ルーム名、プレイヤー名を明記してください。.\n• 例： en-#parkour10 Blank#3495 trolling\nスクリーンショット、ビデオ、GIFなどの証拠は有用であり、ありがたいですが、必須ではありません。.\n\n<font size = '11'>• #parkourルームでは、<font color = '#ef1111'>ハック、グリッチ、バグ</font>を使ってはいけません。\n• <font color = '#ef1111'>VPNファーミング</font>は<B>悪用</B>とみなされ、禁止です。<p align = 'center'><font color = '#cc2222' size = '12'><B>\nルールに違反したプレイヤーは即刻BANされます。</B></font></p>\n\n<font size = '12'>Transformiceはトローリングを許しますが、<font color='#cc2222'><B>parkourでは禁止です。</B></font></font>\n\n<p align = 'center'><J>トローリングとは、パワーなどを使って、他のプレイヤーがマップクリアできないように邪魔をすることです。</j></p>\n• トローリングされたからと言って返しにトローリングをするのは<B>正当な言い訳にはならない</B>ので、懲戒対象となります。\n• マップをソロでやりたいプレイヤーに助けを強要し、言われてもやめないこともトローリングとみなされます。\n• <J>助けを求めないプレイヤー、またはソロでマップをやりたいプレイヤーがいたら、別の人を手伝ってみましょう</J>。 ただし、助けが必要なプレイヤーがいて、たまたまソロプレイヤーも同じチェックポイントにいる場合は、[二人]を手伝ってもいいです。\n\nプレイヤーがトローリングをしているのが見つかった場合は、時間に基づいて罰せられます。 破壊的な行為を繰り返すと、より長くて厳しい懲戒処分が科せられます。",
		help_contribute = "<font size='14'>\n<p align='center'>Parkour管理チームは、<t>コミュニティに役立つ</t>ため、オープンソースコードが大好きです。 <o><u><a href='event:github'>GitHub</a></u></o>でソースコードを<o>閲覧</o>や<o>変更</o>することができます。\n\nこのモジュールの保守は<t>自主的</t>なものであるため、<t>コード</t>、<t>バグの報告</t>、<t>提案</t>、<t>マップの作成</t>に関する協力は<u>大歓迎で、ありがたいです</u>。\n<o><u><a href='event:discord'>Discord</a></u></o>や<o><u><a href='event:github'>GitHub</a></u></o>で<vp>バグを報告したり</vp>、<vp>提案を行ったり</vp>できます。 \n<o><u><a href='event:map_submission'>フォーラムスレッド</a></u></o>に<vp>マップを送信</vp>できます。\n\nParkourの維持は高くないですが、無料でもありません。<t>金額に関わらず<o><u><a href='event:donate'>こちら</a></u></o>にご寄付いただけましたら</t>幸いです。\n<u>すべての寄付金はこのモジュールの改善に使用されます。</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>バージョン 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>新しいクエストシステムが追加されました。 (「<J><B>,</B></J>」を押すとクエストが表示されます)\n\n<font size='11'>• <font size='13'>リーダーボード、ヘルプ、ショップなどのすべてのインターフェイスのホットキーを無効にするオプションを追加しました。\n\n<font size='11'>• <font size='13'>プレイヤーのチェックポイントを今自分がいるチェックポイントとして設定する「<B><J>!cp [PlayerName#tag]</J></B>」コマンドを追加しました。",
		
		-- Congratulation messages
		reached_level = "<d>やった！レベル<vp>%s</vp>クリア！(<t>%ss</t>)",
		finished = "<d><o>%s</o>は<vp>%s</vp>秒でparkourをクリアしました。<fc>お疲れ様！",
		unlocked_power = "<ce><d>%s</d>は<vp>%s</vp>パワーをゲットしました。",
	
		-- Information messages
		mod_apps = "<j>Parkourモデレーターの募集が始まりました！こちらのリンクをご覧ください：<rose>%s",
		staff_power = "<p align='center'><font size='12'><r>Parkourスタッフは#parkourルーム以外では権限を<b>持ちません</b>。",
		donate = "<vp>寄付をご希望の方は「<b>!donate</b>」と入力してください！",
		paused_events = "<cep><b>[注意]</b> <n>このモジュールは限界に達し、一時停止しています。",
		resumed_events = "<n2>モジュールは再開されました。",
		welcome = "<n><t>#parkour</t>へようこそ！",
		module_update = "<r><b>[注意]</b> <n>モジュールがアップデートされるまで：<d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>リーダーボードがロードされました。表示するにはLキーを押してください。",
		kill_minutes = "<R>あなたのパワーは%s分間無効化されました。",
		permbanned = "<r>#parkourから永久BANされました。",
		tempbanned = "<r>#parkourから%s分間BANされました。",
		forum_topic = "<rose>このモジュールについて詳しくはこちら： %s",
		report = "<j>Parkourプレイヤーを通報したい場合： <t><b>/c Parkour#8558 .report Username#0000</b></t>",
		killed = "<v>[#] <r>Parkourのルールを守らなかったため、%s分間パワーを使うことできません。ルールを何回も無視し続けるとBANされます。「<b>H</b>」を押してルールを確認してください。",
		mapper_event = "<CE><B>Parkourマップ作成コンテスト2024年：</B>\n<n>あなたの創造力を見せて、<D>チーズコイン<n>や<pt>パルクールコイン<n>がもらえますよ！\n<R>マップの提出期限は<B>2024年1月31日</B>です。\n<PS>詳細：%s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>いよいよカウントダウンが始まった...",
		easter_egg_1  = "<ch>残り24時間を切った！",
		easter_egg_2  = "<ch>わあ、ずいぶん早いね！ワクワクしすぎじゃない？",
		easter_egg_3  = "<ch>サプライズが待っている...",
		easter_egg_4  = "<ch>これから何が起こるんだろうね…？",
		easter_egg_5  = "<ch>時間は刻々と過ぎていく...",
		easter_egg_6  = "<ch>もうすぐだよ！",
		easter_egg_7  = "<ch>パーティーは今にも始まるよ...",
		easter_egg_8  = "<ch>時間を確認して。まだか？",
		easter_egg_9  = "<ch>気をつけよう、時間は過ぎていく...",
		easter_egg_10 = "<ch>リラックスして。すぐに明日が来るよ。",
		easter_egg_11 = "<ch>早く寝よう！早く明日になってほしい！",
		easter_egg_12 = "<ch>忍耐は美徳",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>土曜日（GMT+2）parkourのバースデーウィークにはダブルマップと全てのパワーが使用可能になります！",
		double_maps_start = "<rose>Parkourのバースデーウィークがきた！ダブルマップと全てのパワーがオンになっています。応援ありがとうございます。",
		double_maps_end = "<rose>Parkourのバースデーウィークが終わりました。いつも応援してくれて、このモジュールをプレイしてくれてありがとうございます！",
	
		-- Records
		records_enabled = "<v>[#] <d>このルームではRecordsモードが有効です。パワーは無効で、statsも保存されません。\nRecordsについて詳しくはこちら：<b>%s</b>",
		records_admin = "<v>[#] <d>あなたはこのルームの管理者です。「<b>!map</b>」、 「<b>!setcp</b>」、「 <b>!pw</b>」、「<b>!time</b>」というコマンドを使うことができます。",
		records_completed = "<v>[#] <d>マップをクリアしました！やり直したい場合は、「<b>!redo</b>」と入力してください。",
		records_submit = "<v>[#] <d>すごい！このルームで最速タイムを出したようですね。記録を提出したい場合、「<b>!submit</b>」と入力してください。",
		records_invalid_map = "<v>[#] <r>このマップはParkourのローテーションに入っていないようです。記録は提出できません。",
		records_not_fastest = "<v>[#] <r>このルームの一番速いプレイヤーはあなたではないようです...。",
		records_already_submitted = "<v>[#] <r>このマップの記録はすでに提出されています！",
		records_submitted = "<v>[#] <d>マップ<b>%s</b>の記録が提出されました。",
	
		-- Quests
		daily_q = "デイリー",
		weekly_q = "ウィークリー",
		daily_quests = "<p align='center'><font size='20'><B><D>デイリー・クエスト</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>ウィークリー・クエスト</D></B></font>",
		quest_1 = "<B><D>%s/%s</D></B>マップをクリアする。",
		quest_2 = "<B><D>%s/%s</D></B>チェックポイントを通過する。",
		quest_3 = "1位でゴールに<B><D>%s/%s</D></B>回到達する。",
		quest_4 = "<B><D>%s</D></B>秒以内にマップをクリアする。",
		quest_5 = "マップ<B><D>@%s</D>をクリアする。</B>",
		quest_6 = "<PT><b>%s</b></PT>パワーを<B><D>%s/%s</D></B>回使う。",
		next_reset = "<b><D>リセット:\n</b></D>%s",
		quest_completed = "<b><D>おめでとう!</D></b> \n%sクエストを完了しました!",
		quest_reset = "<V>[#]</V> <O>%sクエストがリセットされました。</O>",
	
		-- Christmas
		find_gift1 = "<ch>サンタさんがやってきた！このマップにあるクリスマスプレゼントを探して開けてみよう。",
		find_gift2 = "<ch>ジングルベル！特別なクリスマスプレゼントが現れたよ。探しに行こう！",
		find_gift3 = "<ch>ホッホッホー! サンタさんのお手伝いをする小人はこのマップのどこかにプレゼントを置いて去っていった！",
		find_gift4 = "<ch>クリスマススピリットが漂っている！このマップに隠されたクリスマスプレゼントを見つけよう！",
		find_gift5 = "<ch>メリークリスマス！小人の妖精たちがあなたへのプレゼントを隠したようだ。見つけられるかな？",
		found_gift1 = "<ch>フレー！<J>%s</J>はプレゼントを開けてコインを%s枚ゲットした！",
		found_gift2 = "<ch>フレー、<J>%s</J>! サンタさんの魔法のプレゼントから、キラキラのコインを<J>%s</J>枚ゲットした！",
		found_gift3 = "<ch><J>%s</J>の勝ちだ！サンタさんのおかげで、コインが<J>%s</J>枚増えた！",
		found_gift4 = "<ch><J>%s</J>はコインを<J>%s</J>枚ゲットした！おめでとう。クリスマスを感じるね~",
		found_gift5 = "<ch>サンタさんのプレゼントは<J>%s</J>にキラキラのコインを<J>%s</J>枚授けた！",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>AFKモードです。</b></bv>\n復活するために動いてください。</font>\n\n<font size='30'><u><t>リマインダー：</t></u></font>\n\n<font size='15'><r>赤い線が引かれているプレイヤーは助けを求めていません。\nほかのプレイヤーの邪魔をしてはいけません。<d>\nParkourの<cep><a href='event:discord'>Discordサーバー</a></cep>に入ってみてください！\nコードで貢献したい場合、私たちの<cep><a href='event:github'>githubリポジトリ</a></cep>をご覧ください。\n提出したい良いマップはありますか。 Parkourの<cep><a href='event:map_submission'>マップ投稿トピック</a></cep>に投稿してください。 \n詳しくは私たちの<cep><a href='event:forum'>公式トピック</a></cep>をチェックしてみてください。\n<cep><a href='event:donate'>寄付</a></cep>して私たちを応援してください。",
		options = "<p align='center'><font size='20'>設定</font></p>\n\n <b>QWERTY</b>キーボードを使用する（<b>AZERTY</b>の場合は無効にする）\n\n<b>/mort</b>のホットキーを「<J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J>」にする(無効にすると「<b>DEL</b>」になる)\n\nパワーのクールダウンを表示する\n\nパワーボタンを表示する\n\nヘルプボタンを表示する\n\nマップクリアの発表を表示する\n\n「ヘルプなし」の印をつける\n\nすべてのインターフェースのホットキーを無効にする（リーダーボード、ヘルプ、ショップ、など。）",
		cooldown = "<v>[#] <r>もう一度実行する前に、数秒待ってください。",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b>キーボード" ..
						 "\n\nマップの数を<b>非表示</b>" ..
						 "\n\n<b>デフォルト・キー</b>を使用する"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'><v>%s</v>マップをクリアして" ..
						"<font size='5'>\n\n</font><v>%s</v>" ..
						"<font size='5'>\n\n</font>をゲット"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'><v>%s</v>マップをクリアして" ..
						"<font size='5'>\n\n</font><v>%s</v>" ..
						"<font size='5'>\n\n</font>にアップグレード"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>ランキング<v>%s</v>で" ..
						"<font size='5'>\n\n</font><v>%s</v>" ..
						"<font size='5'>\n\n</font>をゲット"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>ランキング<v>%s</v>で" ..
						"<font size='5'>\n\n</font><v>%s</v>" ..
						"<font size='5'>\n\n</font>にアップグレード"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>クリアしたマップ"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>総合リーダーボード"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>週間リーダーボード"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>バッジ (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>このプレイヤーのマップ数は非公開です。 <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"総合リーダーボードの順位： <b><v>%s</v></b>\n\n" ..
					"週間リーダーボードの順位： <b><v>%s</v></b>\n\n%s"),
		map_count = "マップ数： <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> クリアしたマップ：<b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> 通過したチェックポイント：<b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "バッジはプレイヤーが手に入れた実績です。 クリックすると説明が表示されます。",
		help_private_maps = "このプレイヤーは自分のマップ数を非公開にしています。 あなたもプロフィールで非表示にすることができます。",
		help_yellow_maps = "黄色いのは今週クリアしたマップの数です。",
		help_red_maps = "赤いのは過去一時間以内にクリアしたマップの数です。",
		help_map_count_title = "Parkourのマップをクリアすることで<b>Transformice</b>のタイトルがもらえますよ！",
		help_checkpoint_count_title = "Parkourマップのすべてのチェックポイントを通過すれば<b>Transformice</b>のタイトルがもらえますよ！",
		help_badge_1 = "このプレイヤーはかつてparkourスタッフでした。",
		help_badge_2 = "このプレイヤーは、総合リーダーボードの1ページ目にいる、またはいたことがあります。",
		help_badge_3 = "このプレイヤーは、総合リーダーボードの2ページ目にいる、またはいたことがあります。",
		help_badge_4 = "このプレイヤーは、総合リーダーボードの3ページ目にいる、またはいたことがあります。",
		help_badge_5 = "このプレイヤーは、総合リーダーボードの4ページ目にいる、またはいたことがあります。",
		help_badge_6 = "このプレイヤーは、総合リーダーボードの5ページ目にいる、またはいたことがあります。",
		help_badge_7 = "このプレイヤーは週間リーダーボードでトップ3に入ったことがあります。",
		help_badge_8 = "このプレイヤーは1時間あたり30マップの記録を持っている。",
		help_badge_9 = "このプレイヤーは1時間あたり35マップの記録を持っている。",
		help_badge_10 = "このプレイヤーは1時間あたり40マップの記録を持っている。",
		help_badge_11 = "このプレイヤーは1時間あたり45マップの記録を持っている。",
		help_badge_12 = "このプレイヤーは1時間あたり50マップの記録を持っている。",
		help_badge_13 = "このプレイヤーは1時間あたり55マップの記録を持っている。",
		help_badge_14 = "このプレイヤーは、Parkourの公式Discordサーバーでアカウントを確認しました（「<b>!discord</b>」と入力してください）。",
		help_badge_15 = "このプレイヤーは1マップで最速タイムを出している。",
		help_badge_16 = "このプレイヤーは5マップで最速タイムを出している。",
		help_badge_17 = "このプレイヤーは10マップで最速タイムを出している。",
		help_badge_18 = "このプレイヤーは15マップで最速タイムを出している。",
		help_badge_19 = "このプレイヤーは20マップで最速タイムを出している。",
		help_badge_20 = "このプレイヤーは25マップで最速タイムを出している。",
		help_badge_21 = "このプレイヤーは30マップで最速タイムを出している。",
		help_badge_22 = "このプレイヤーは35マップで最速タイムを出している。",
		help_badge_23 = "このプレイヤーは40マップで最速タイムを出している。",
		make_public = "公開する",
		make_private = "非公開にする",
		moderators = "モデレーター",
		mappers = "マッパー",
		managers = "マネージャー",
		administrators = "管理者",
		close = "閉じる",
		cant_load_bot_profile = "<v>[#] <r>#parkourは正しく動作するためにこのボットを使用しているため、このボットのプロフィールを見ることができません。",
		cant_load_profile = "<v>[#] <r>T<b>%s</b>というプレイヤーはオフラインか、または存在しません。",
		like_map = "このマップは気に入りましたか",
		yes = "はい",
		no = "いいえ",
		idk = "わからない",
		vote_map = "<font color='#ffffff' size='13'><b>このマップは気に入りましたか<font size='14'><a href='event:mapPollYes'><PT>はい</a> <a href='event:mapPollidk'><N>わからない</a> <a href='event:mapPollNo'><R>いいえ</a>",
		unknown = "不明",
		powers = "パワー",
		press = "<vp>%sを押す",
		click = "<vp>左クリック",
		ranking_pos = "ランキング #%s",
		completed_maps = "<p align='center'><BV><B>クリアしたマップ: %s</B></p></BV>",
		leaderboard = "リーダーボード",
		position = "<V><p align=\"center\">順位",
		username = "<V><p align=\"center\">名前",
		community = "<V><p align=\"center\">コミュニティ",
		completed = "<V><p align=\"center\">クリアしたマップ",
		overall_lb = "総合",
		weekly_lb = "週間",
		new_lang = "<v>[#] <d>言語を日本語に設定しました。",
		room = "ルーム",
		time = "時間",
		buy = "買う",
		equip = "装備する",
		equipped = "<font size = '10'>装備中</font>",
		saving = "<p align='right'>保存中...",
	
		-- Power names
		balloon = "風船",
		masterBalloon = "風船 II",
		bubble = "風船 III",
		fly = "飛行",
		snowball = "雪玉",
		speed = "ダッシュ",
		teleport = "テレポート",
		smallbox = "小さい箱",
		cloud = "雲",
		rip = "墓石",
		choco = "チョコ板",
		bigBox = "大きい箱",
		trampoline = "トランポリン",
		toilet = "便器",
		pig = "子豚",
		sink = "流し",
		bathtub = "風呂",
		campfire = "焚き火",
		chair = "椅子",
		link = "パートナー",
	}
	--[[ End of file translations/parkour/jp.lua ]]--
	--[[ File translations/parkour/pl.lua ]]--
	translations.pl = {
		name = "pl",
		fullname = "Polski",
	
		-- Error messages
		corrupt_map = "<r>Zepsuta mapa. Ładowanie innej.",
		corrupt_map_vanilla = "<r>[BŁĄD] <n>Nie można uzyskać informacji o tej mapie.",
		corrupt_map_mouse_start = "<r>[BŁĄD] <n>Ta mapa musi mieć pozycję początkową (punkt odradzania myszy).",
		corrupt_map_needing_chair = "<r>[BŁĄD] <n>Mapa musi mieć końcowy fotel.",
		corrupt_map_missing_checkpoints = "<r>[BŁĄD] <n>Mapa musi mieć co najmniej jeden punkt kontrolny (żółty gwóźdź).",
		corrupt_data = "<r>Niestety Twoje dane zostały uszkodzone i zostały zresetowane.",
		min_players = "<r>Aby zapisać dane, w pokoju musi być co najmniej 4 graczy. <bl>[%s/%s]",
		tribe_house = "<r>Dane nie będą zapisywane w chatce plemiennej.",
		invalid_syntax = "<r>Niepoprawna składnia.",
		code_error = "<r>Wystąpił błąd: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Inicjowanie wyłączenia awaryjnego, nowi gracze nie mogą dołączyć. Przejdź do innego pokoju #parkour.",
		leaderboard_not_loaded = "<r>Tabela liderów nie została jeszcze załadowana. Poczekaj minutę.",
		max_power_keys = "<v>[#] <r>Możesz mieć co najwyżej %s moce na tym samym klawiszu. ",
	
		-- Help window
		help = "Pomoc",
		staff = "Obsługa",
		rules = "Zasady",
		contribute = "Udział",
		changelog = "Aktualności",
		help_help = "<p align = 'center'><font size = '14'>Witamy w <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Twoim celem jest dotarcie do wszystkich punktów kontrolnych, dopóki nie ukończysz mapy.</J></p>\n\n<N>• Naciśnij <O>O</O>, napisz <O>!op</O> Lub kliknij <O>przycisk konfiguracji</O> aby otworzyć <T>menu opcji</T>.\n• Naciśnij <O>P</O> lub kliknij <O>ikonę dłoni</O> w prawym górnym rogu, aby otworzyć <T>menu mocy</T>.\n• Naciśnij <O>L</O> lub napisz <O>!lb</O> aby otworzyć <T>tabelę wyników</T>.\n• Naciśnij <O>M</O> lub <O>Delete</O> klawisz do <T>/mort</T>, możesz przełączać klawisze w <J>Options</J> menu.\n• Aby dowiedzieć się więcej o naszym <O>personelu</O> oraz <O>zasadach na parkourze</O>, kliknij na <T>obsługę</T> i <T>zasady</T> .\n• Kliknij <a href='event:discord'><o>tutaj</o></a> aby uzyskać link zapraszający zgodny i <a href='event:map_submission'><o>tutaj</o></a> aby uzyskać link do tematu przesyłania mapy.\n• Użyj strzałki w <o>góre</o> i w <o>dół</o>, kiedy musisz przewijać.\n\n<p align = 'center'><font size = '13'><T>Udziały są teraz otwarte! Aby uzyskać więcej informacji, kliknij <O>Udział</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>WYJAŚNIAMY: Personel Parkour NIE JEST personelem Transformice i NIE MA żadnej mocy w samej grze, tylko w module.</r>\nPersonel w Parkour zapewnnia, że moduł działa płynnie przy minimalnych problemach i są zawsze dostępni, aby pomóc graczom w razie potrzeby.</font></p>\nAby zobaczyć listę aktywnych osób z personelu napisz <D>!staff</D> na czacie.\n\n<font color = '#E7342A'>Administratorzy:</font> Są odpowiedzialni za utrzymanie samego modułu poprzez dodawanie nowych aktualizacji i naprawianie błędów.\n\n<font color = '#D0A9F0'>Kierownicy zespołów:</font> Nadzorują zespoły moderatorów i twórców map, upewniając się, że dobrze wykonują swoje zadania. Odpowiadają również za rekrutację nowych członków do zespołu pracowników.\n\n<font color = '#FFAAAA'>Moderatoratorzy:</font> Są odpowiedzialni za egzekwowanie zasad modułu i karanie osób, które ich nie przestrzegają.\n\n<font color = '#25C059'>Mapperzy:</font> Są odpowiedzialni za przeglądanie, dodawanie i usuwanie map w modułach, aby zapewnić przyjemną rozgrywkę.",
		help_rules = "<font size = '13'><B><J>Wszystkie zasady zawarte w Regulaminie Transformice dotyczą również #parkour</J></B></font>\n\nJeśli zauważysz, że jakiś gracz łamie te zasady, napisz do moderatorów parkour w grze. Jeżeli nie ma moderatorów w grze to możesz ich zgłosić na nayszm serwerze discord.\nPodczas zgłaszania prosimy o podanie serwera, nazwy pokoju i nazwy gracza.\n• Na przykład: en-#parkour10 Blank#3495 trolling\nDowody, takie jak zrzuty ekranu, filmy i gify, są pomocne i doceniane, ale nie są konieczne.\n\n<font size = '11'>• Zakazane jest używanie: <font color = '#ef1111'>hack, usterek oraz błędów.</font>\n• <font color = '#ef1111'>VPN farmowanie</font> będzie uważany za <B>wykorzystywanie</B> i nie jest dozwolone. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKażdy przyłapany na łamaniu tych zasad zostanie natychmiast zbanowany.</B></font></p>\n\n<font size = '12'>Transformice zezwala na trollowanie. Jednak, <font color='#cc2222'><B> zabronione jest to na parkourze.</B></font></font>\n\n<p align = 'center'><J>Trolling ma miejsce, gdy gracz celowo użył swoich mocy lub materiałów eksploatacyjnych, aby uniemożliwić innym graczom ukończenie mapy.</j></p>\n•Trolling w każdej formie jest zabroniony nie ważne czy w formie <B>zemsty czy zabawy</B>.\n• Za trollowanie uważa się również wymuszanie pomocy gdy gracz sam próbuje przejść mapę i prosi abyś przestał mu pomagać a ty odmawiasz.\n• <J>Jeśli gracz nie chce pomocy lub woli ukończyć sam mape, postaraj się pomóc innym graczom</J>. Jeśli jednak inny gracz potrzebuje pomocy w tym samym punkcie kontrolnym, co gracz solo, możesz im pomóc [obu].\n\nJeśli gracz zostanie przyłapany na trollowaniu, zostanie ukarany na czas. Pamiętaj, że wielokrotne trollowanie doprowadzi do dłuższych i surowszych kar.",
		help_contribute = "<font size='14'>\n<p align='center'>Zespół zarządzający w parkour uwielbia otwarte kody, ponieważ <t>pomagają społeczności</t>. Możesz <o>zobaczyć</o> i <o>modyfikować</o> kod źródłowy na <o><u><a href='event:github'>GitHub</a></u></o>.\n\nUtrzymanie modułu jest <t>dobrowolne</t>, więc wszelka pomoc dotycząca <t>kodów</t>, <t>zgłaszania błędów</t>, <t>propozycje</t> oraz <t>tworzenie map</t> jest zawsze <u>mile widziane i doceniane</u>.\nMożesz <vp>zgłaszać błędy</vp> oraz <vp>dać propozycje</vp> na <o><u><a href='event:discord'>Discord</a></u></o> lub <o><u><a href='event:github'>GitHub</a></u></o>.\n<vp>Swoje mapy możesz przesyłać</vp> w naszym <o><u><a href='event:map_submission'>wątku na forum</a></u></o>.\n\nUtrzymanie parkour nie jest drogie, ale też nie darmowe. Możesz nam pomóc <t>przekazując dowolną kwotę</t> <o><u><a href='event:donate'>tutaj</a></u></o>.\n<u>Wszystkie darowizny zostaną przeznaczone na ulepszenie modułu.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Wersja 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Dodano system zadań. (Naciśnij <J><B>,</B></J> aby otworzyć listę zadań.)\n\n<font size='11'>• <font size='13'>Dodano możliwość wyłączenia klawiszy dla całego interfejsu np tabela liderów, pomoc, sklep itd.\n\n<font size='11'>• <font size='13'>Dodano <B><J>!cp [NazwaGracza#tag]</J></B>Komendę która pozwala zmienić twój aktualny punkt kontrolny na puknt kontrolny danego gracza.",
	
		-- Congratulation messages
		reached_level = "<d>Gratulacje! Ukończyłeś poziom <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> skończyłeś parkour w <vp>%s</vp> sekundach, <fc>Gratulacje!",
		unlocked_power = "<ce><d>%s</d> odblokował <vp>%s</vp> moc.",
	
		-- Information messages
		mod_apps = "<j>Rekrutacja na  moderatora Parkour jest już otwarta! Użyj tego linku: <rose>%s",
		staff_power = "<r>Parkour staff <b>nie</b> mają jakiejkolwiek mocy poza #parkour .",
		donate = "<vp>Wpisz <b>!donate</b>, jeśli chcesz przekazać darowiznę na ten moduł!",
		paused_events = "<cep><b>[Uwaga!]</b> <n>Moduł osiągnął limit krytyczny i jest wstrzymywany.",
		resumed_events = "<n2>Moduł został wznowiony.",
		welcome = "<n>Witamy w <t>#parkour</t>!",
		module_update = "<r><b>[Uwaga!]</b> <n>Moduł zaktualizuje się za <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>Tablica wyników została załadowana. Naciśnij L, aby go otworzyć.",
		kill_minutes = "<R>Twoje moce zostały wyłączone na %s minut.",
		permbanned = "<r>Zostałeś trwale zbanowany na #parkour.",
		tempbanned = "<r>Zostałeś zbanowany na #parkour na %s minut.",
		forum_topic = "<rose>Więcej informacji o module znajdziesz pod tym linkiem: %s",
		report = "<j>Chcesz zgłosić gracza? <t><b>/c Parkour#8558 .report Username#0000</b></t>",
		killed = "<v>[#] <r>Zostałeś zawieszony w używaniu swoich mocy na %s minut z powodu naruszenia regulaminu parkour. Dalsze naruszanie zasada zakończy się banem. Naciśnij  <b>H</b> żeby zobaczyć zasady.",
		mapper_event = "<CE><B>Konkurs tworzenia map Parkour 2024:</B>\n<n>Pokaż nam swoją kreatywność podczas tworzenia mapy masz szansę wygrać <D>serków do ekwipunku <n>oraz <pt>monet parkour<n>!\n<R>Możesz wysłać swoją propozycję do<B>31 Stycznia, 2024</B>.\n<PS>Po więcej informacji odwiedź: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Więc, odliczanie się rozpoczęło...",
		easter_egg_1  = "<ch>Pozostało mniej niż 24 godziny czasu!",
		easter_egg_2  = "<ch>Jesteś zbyt wcześnie! Aż tak jesteś podekscytowany?",
		easter_egg_3  = "<ch>Niespodzianka czeka...",
		easter_egg_4  = "<ch>Czy wiesz co się stanie...?",
		easter_egg_5  = "<ch>Zegar wciąż tyka...",
		easter_egg_6  = "<ch>Niespodzianka jest blisko!",
		easter_egg_7  = "<ch>Impreza niedługo się zacznie...",
		easter_egg_8  = "<ch>Sprawdź swój zegarek, jest jeszcze czas?",
		easter_egg_9  = "<ch>Uważaj, czas płynie...",
		easter_egg_10 = "<ch>Usiądź i zrelaksuj się, to będzie jutro!",
		easter_egg_11 = "<ch>Idź do łóżka wcześniej to przyśpieszy czas!",
		easter_egg_12 = "<ch>Cierpliwość jest cnotą",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Podwójne mapy będą dostępne w Sobotę (GMT+2) Wszystkie moce są dostępne przez urodzinowy tydzień parkour!",
		double_maps_start = "<rose>Jest to urodzinowy tydzień Parkour! Podwójne mapy oraz wszystkie moce są dostępne. Dziękujemy że grasz z nami!",
		double_maps_end = "<rose>Urodzinowy tydzień Parkour został zakończony. Dziękujemy za wspólną zabawę!",
	
		-- Records
		records_enabled = "<v>[#] <d> W tym pokoju włączony jest tryb rekordów.  Statystyki się nie liczą, a uprawnienia nie są włączone!\nWięcej informacji na temat rekordów można znaleźć w <b>%s</b>",
		records_admin = "<v>[#] <d>Jesteś administratorem tego pokoju z rekordami.  Możesz użyć poleceń <b>!map</b>, <b>!setcp</b>, <b>!pw</b> and <b>!time</b>.",
		records_completed = "<v>[#] <d>Ukończyłeś mapę!  Jeśli chcesz to zrobić ponownie, wpisz <b>!redo</b>.",
		records_submit = "<v>[#] <d>Łał! Wygląda na to, że miałeś najszybszy czas w pokoju. Jeśli chcesz przesłać swój rekord, wpisz <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Wygląda na to, że na tej mapie nie ma rotacji parkour... Nie możesz przesłać jej rekordu!",
		records_not_fastest = "<v>[#] <r>Wygląda na to, że nie jesteś najszybszym graczem w pokoju...",
		records_already_submitted = "<v>[#] <r>Już przesłałeś swój rekord na tej mapie!",
		records_submitted = "<v>[#] <d>Twój rekord na mapie <b>%s</b> został przesłany.",
	
		-- Quests
		daily_q = "Codzienne",
		weekly_q = "Tygodniowe",
		daily_quests = "<p align='center'><font size='20'><B><D>Codzienne zadania</D></B></font>",
		weekly_quests= "<p align='center'><font size='20'><B><D>Tygodniowe zadania</D></B></font>",
		quest_1 = "Ukończone <B><D>%s/%s</D></B> maps.",
		quest_2 = "Zbierz <B><D>%s/%s</D></B> punkty kontrolne.",
		quest_3 = "Ukończ dowolną mapę jako pierwszy <B><D>%s/%s</D></B> Czasowe.",
		quest_4 = "Ukończ mapę poniżej <B><D>%s</D></B> sekund.",
		quest_5 = "Ukończ mapę<B><D>@%s</D></B>",
		quest_6 = "Użyj <PT><b>%s</b></PT>moc <B><D>%s/%s</D></B>razy.",
		next_reset = "<b><D>Reset:\n</b></D>%s",
		quest_completed = "<b><D>Gratulacje!</D></b>\nUkończyłeś %s zadanie!",
		quest_reset = "<V>[#]</V> <O>Twoje %s zadania zostały zresetowane.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Mikołaj właśnie wpadł! Poluj na prezenty które znajdują się na mapie żeby zdobyć niespodziankę!",
	    find_gift2 = "<ch>Święta na całego! Na mapie pojawiły się w magiczny sposób prezenty leć je znaleźć",
	    find_gift3 = "<ch>Ho, ho, ho! Pomocnik Mikołaja zostawił ci prezent leć go znaleźć na obecnej mapie!",
	    find_gift4 = "<ch>Duch świąt unosi się w powietrzu! Znajdź prezent świąteczny ukryty na tej mapie!",
	    find_gift5 = "<ch>Wesołych Świąt! Elfy ukryły dla ciebie prezent czy jesteś w stanie go znaleźć?",
	    found_gift1 = "<ch>Brawo! <J>%s</J>otworzył prezent i znalazł w nim %s monet!",
	    found_gift2 = "<ch>Brawo, <J>%s</J>! >Właśnie wygrałeś <J>%s</J> błyszczące monety z prezentu od Mikołaja!",
	    found_gift3 = "<ch>  Wygrał <J>%s</J>! <J>%s</J> złote monety, dzięki Mikołajowi!",
	    found_gift4 = "<ch> Gratulacje dla <J>%s</J> wygranej <J>%s</J> ,monet!  Duch Bożego narodzenia jaśnieje!",
	    found_gift5 = "<ch> Prezentem od świętego Mikołaja został obdarowany <J>%s</J> a w nim <J>%s</J> olśniewających monet!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>JESTEŚ W TRYBIE AFK</b></bv>\nPORUSZAJ SIĘ ABY, GRAĆ DALEJ</font>\n\n<font size='30'><u><t>Przypomnienie:</t></u></font>\n\n<font size='15'><r>Gracze z czerwoną linią nad nimi nie chcą pomocy!\nTrollowanie/blokowanie innych graczy w parkour jest zabronione!<d>\nDołącz na nasz <cep><a href='event:discord'>serwer discord</a></cep>!\nChcesz współtworzyć kod?  Zobacz nasz <cep><a href='event:github'>magazyn githuba </a></cep>\nCzy masz dobrą mapę do przesłania?  Opublikujją w naszym <cep><a href='event:map_submission'>temacie przesyłania map</a></cep>\nSprawdź nasz <cep><a href='event:forum'>watek na forum</a></cep> żeby dowiedzieć się więcej\nWesprzyj nas przez <cep><a href='event:donate'>darowizmy!</a></cep>",
		options = "<p align='center'><font size='20'>Parkour Opcje</font></p>\n\nUżyj <b>QWERTY</b> klawiatura (wyłącz jeśli <b>AZERTY</b>)\n\nUżyj klawisza<J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> zamiast <b>/mort</b> (wyłącz <b>DEL</b>)\n\nPokaż swoje czasy odnowienia mocy\n\nPokaż przycisk mocy\n\nPokaż przycisk pomocy\n\nPokaż ogłoszenia o ukończeniu mapy\n\nPokaż symbol bez pomocy\n\nWylączoną klawisze dla całego interfejsu (tabela liderów, pomoc, sklep, itd.)",
		cooldown = "<v>[#] <r>Poczekaj kilka sekund, zanim zrobisz to ponownie.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> klawiatura" ..
						 "\n\n<b>pokaż</b> liczbę map" ..
						 "\n\nUżyj <b>domyślnego klawisza</b> "),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ukończyć <v>%s</v> mapę" ..
						"<font size='5'>\n\n</font>odblokować" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ukończyć<v>%s</v> mapę" ..
						 "<font size='5'>\n\n</font>uaktualnić do" ..
						 "<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ranga<v>%s</v>" ..
							 "<font size='5'>\n\n</font>odblokować" ..
							 "<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ranga <v>%s</v>" ..
							 "<font size='5'>\n\n</font>uaktualnić do" ..
							 "<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Ukończone mapy"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Ogólny ranking"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Tygodniowa tablica wyników"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Odznaki (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>Liczba map tego gracza jest prywatna. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Ogólna pozycja w tabeli liderów: <b><v>%s</v></b>\n\n" ..
					"Tygodniowa pozycja w tabeli liderów: <b><v>%s</v></b>\n\n%s"),
		map_count = "Map count: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Ukończone Mapy:<b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b>Zebrane Punkty Kontrolne<b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Odznaki to osiągnięcie, które gracz może zdobyć. Kliknij je, aby zobaczyć ich opis.",
		help_private_maps = "Ten gracz nie lubi publicznie udostępniać liczby swoich map! Możesz je również ukryć w swoim profilu.",
		help_yellow_maps = "Ilość map w kolorze żółtym oznacza ilość ukończonych map w tym tygodniu.",
		help_red_maps = "Ilość map w kolorze czerwonym oznacza ilość ukończonych map w ciągu ostatniej godziny.",
		help_map_count_title = "Możesz otrzymać<b>Transformice</b>Tytuły przechodząc mapy parkour!",
		help_checkpoint_count_title = "Możesz otrzymać<b>Transformice</b>Tytuły zbierając wszystkie punkty kontrolne na mapach parkour!",
		help_badge_1 = "Ten gracz był w przeszłości członkiem zespołu parkour. ",
		help_badge_2 = "Ten gracz jest lub był na pierwszej stronie ogólnej tabeli wyników.",
		help_badge_3 = "Ten gracz jest lub był na stronie 2 ogólnej tabeli wyników.",
		help_badge_4 = "Ten gracz jest lub był na stronie 3 ogólnej tabeli wyników.",
		help_badge_5 = "Ten gracz jest lub był na stronie 4 ogólnej tabeli wyników.",
		help_badge_6 = "Ten gracz jest lub był na stronie 5 ogólnej tabeli wyników.",
		help_badge_7 = "Ten gracz był na podium na koniec tygodniowej tabeli liderów.",
		help_badge_8 = "Ten gracz ma rekord 30 map na godzinę.",
		help_badge_9 = "Ten gracz ma rekord 35 map na godzinę.",
		help_badge_10 = "Ten gracz ma rekord 40 map na godzinę.",
		help_badge_11 = "Ten gracz ma rekord 45 map na godzinę.",
		help_badge_12 = "Ten gracz ma rekord 50 map na godzinę.",
		help_badge_13 = "Ten gracz ma rekord 55 map na godzinę.",
		help_badge_14 = "Ten gracz zweryfikował swoje konto na naszym oficjalnym Discordzie (napisz <b>!discord</b>).",
		help_badge_15 = "Ten gracz uzyskał najszybszy czas na 1 mapie.",
		help_badge_16 = "Ten gracz uzyskał najszybszy czas na 5 mapch.",
		help_badge_17 = "Ten gracz uzyskał najszybszy czas na 10 mapch.",
		help_badge_18 = "Ten gracz uzyskał najszybszy czas na 15 mapch.",
		help_badge_19 = "Ten gracz uzyskał najszybszy czas na 20 mapch.",
		help_badge_20 = "Ten gracz uzyskał najszybszy czas na 25 mapch.",
		help_badge_21 = "Ten gracz uzyskał najszybszy czas na 30 mapch.",
		help_badge_22 = "Ten gracz uzyskał najszybszy czas na 35 mapch.",
		help_badge_23 = "Ten gracz uzyskał najszybszy czas na 40 mapch.",
		make_public = " pokaż",
		make_private = "ukryj",
		moderators = "Moderatorzy",
		mappers = "Maperzy",
		managers = "Menedżerowie",
		administrators = "Administratorzy",
		close = "Zamknij",
		cant_load_bot_profile = "<v>[#] <r>Nie możesz zobaczyć profilu tego bota, ponieważ #parkour używa go wewnętrznie do prawidłowego działania.",
		cant_load_profile = "<v>[#] <r>Gracz <b>%s</b> wydaje się być offline lub nie istnieje.",
		like_map = "Podoba ci się ta mapa?",
		yes = "Tak",
		no = "Nie",
		idk = "Nie wiem",
		vote_map = "<font color='#ffffff' size='13'><b>Podoba ci się ta mapa? <font size='14'><a href='event:mapPollYes'><PT>Tak</a> <a href='event:mapPollidk'><N>Nie wiem</a> <a href='event:mapPollNo'><R>Nie</a>",
		unknown = "Nieznany",
		powers = "Moce",
		press = "<vp>Naciśnij %s",
		click = "<vp>Lewy przycisk",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Ukończone mapy: %s</B></p></BV>",
		leaderboard = "Tabela liderów",
		position = "<V><p align=\"center\">Pozycja",
		username = "<V><p align=\"center\">Nazwa",
		community = "<V><p align=\"center\">Społeczność",
		completed = "<V><p align=\"center\">Ukończone mapy",
		overall_lb = "Ogólnie",
		weekly_lb = "Co tydzień",
		new_lang = "<v>[#] <d>Ustawiono język Polski",
		room = "Pokój",
		time = "Czas",
		buy = "Kup",
		equip = "Wyposaż",
		equipped = "<font size = '10'>Wyposażono</font>",
		saving = "<p align='right'> Zapisywanie...",
	
		-- Power names
		balloon = "Balon",
		masterBalloon = "Balon II",
		bubble = "Balon III",
		fly = "Latanie",
		snowball = "Śnieżka",
		speed = "Prędkość",
		teleport = "Teleport",
		smallbox = "Małe pudełko",
		cloud = "Chmurka",
		rip = "Grób",
		choco = "Deska czekoladowa",
		bigBox = "Duże pudło",
		trampoline = "Trampolina",
		toilet = "Toaleta",
		pig = "Świnka",
		sink = "Umywalka",
		bathtub = "Wanna",
		campfire = "Ognisko",
		chair = "Krzesło",
		link = "Partner/ka",
	
	}
	--[[ End of file translations/parkour/pl.lua ]]--
	--[[ File translations/parkour/ro.lua ]]--
	translations.ro = {
		name = "ro",
		fullname = "Română",
	
		-- Error messages
		corrupt_map = "<r>Hartă coruptă. Se încarcă alta.",
		corrupt_map_vanilla = "<r>[EROARE] <n>Nu pot primi informațiile acestei hărți.",
		corrupt_map_mouse_start = "<r>[EROARE] <n>Această hartă are nevoie de o poziție de start (punct de start pentru șoareci).",
		corrupt_map_needing_chair = "<r>[EROARE] <n>Această hartă are nevoie de un fotoliu de final.",
		corrupt_map_missing_checkpoints = "<r>[EROARE] <n>Harta are nevoie de măcar un checkpoint (cui galben).",
		corrupt_data = "<r>Din păcate, progresul tău era corupt și a fost resetat.",
		min_players = "<r>Pentru a-ți salva progresul, trebuie să fie măcar 4 jucători unici pe sală. <bl>[%s/%s]",
		tribe_house = "<r>Progresul nu va fi salvat în casele de trib.",
		invalid_syntax = "<r>Sintaxă invalidă.",
		code_error = "<r>O eroare a apărut: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Inițiând închidere de urgență, niciun jucător nou nu este permis. Te rugăm să te duci pe altă sală de #parkour.",
		leaderboard_not_loaded = "<r>Clasamentul nu a fost încă încărcat. Așteaptă un minut.",
		max_power_keys = "<v>[#] <r>Poți avea maximum %s puteri pe aceeași tastă.",
	
		-- Help window
		help = "Ajutor",
		staff = "Personal",
		rules = "Reguli",
		contribute = "Contribuie",
		changelog = "Noutăți",
		help_help = "<p align = 'center'><font size = '14'>Bine ai venit pe <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Scopul tău este să ajungi la toate checkpoint-urile până completezi harta.</J></p>\n\n<N>• Apasă <O>O</O>, scrie <O>!op</O> sau dă click pe <O>butonul de configurație</O> pentru a deschide <T>meniul de opțiuni</T>.\n• Apasă <O>P</O> sau dă click pe <O>iconița mână</O> din colțul din dreapta-sus pentru a deschide <T>meniul de puteri</T>.\n• Apasă <O>L</O> sau scrie <O>!lb</O> pentru a deschide <T>clasamentul</T>.\n• Apasă pe <O>M</O> sau <O>Delete</O> pentru a folosi <T>/mort</T>, poți schimba tastele în meniul de <J>Opțiuni</J>.\n• Pentru a afla mai multe despre <O>personalul nostru</O> sau despre <O>regulile parkourului</O>, dă click pe tab-urile <T>Personal</T> și respectiv <T>Reguli</T>.\n• Dă click <a href='event:discord'><o>aici</o></a> pentru a primi link-ul de invitație pentru serverul de discord și <a href='event:map_submission'><o>aici</o></a> pentru a putea trimite propriile hărți.\n• Folosește săgețile <o>sus</o> și <o>jos</o> când vrei să navighezi.\n\n<p align = 'center'><font size = '13'><T>Contribuțiile sunt acum deschide! Pentru mai multe detalii, dă click pe tab-ul <O>Contribuie</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Personalul parkour NU FAC PARTE din personalul Transformice și NU au nicio putere în joc ci doar în acest modul.</r>\nPersonalul parkour se asigură că modulul rulează bine cu probleme minime, și sunt mereu disponibili să ajute jucătorii când este nevoie.</font></p>\nPoți scrie <D>!staff</D> în chat pentru a vedea personalul.\n\n<font color = '#E7342A'>Administratorii:</font> Ei sunt responsabili cu întreținerea modulului, adăugând actualizări noi și rezolvând probleme.\n\n<font color = '#D0A9F0'>Managerii de echipă:</font> Ei au grijă ca Moderatorii și Mapperii își fac treaba cum trebuie.  Ei sunt de asemenea responsabili cu aducerea de personal nou în echipă.\n\n<font color = '#FFAAAA'>Moderatorii:</font> Ei sunt responsabili cu aplicarea regulilor modulului și pedepsirea celor care nu le respectă.\n\n<font color = '#25C059'>Mapperii:</font>Ei sunt responsabili cu verificarea, adăugarea, și eliminarea hărților din modul pentru a-ți asigura un experiență plăcută de joc.",
		help_rules = "<font size = '13'><B><J>Toate regulile din Termenii și Condițiile Transformice se aplică și la #parkour</J></B></font>\n\nDacă observi vreun player care încalcă aceste reguli, dă-le șoaptă moderatorilor din joc. Dacă nu este niciun moderator online, e recomandat să-l raportezi în server-ul de Discord.\nCand raportezi, te rugăm să incluzi server-ul, numele camerei și numele jucătorului.\n• Ex: ro-#parkour10 Blank#3495 trollează\nEvidența precum capturile de ecran, videourile și gif-urile sunt folositoare și apreciate, dar nu sunt necesare.\n\n<font size = '11'>• Niciun <font color = '#ef1111'>hack, bug sau eroare</font> nu este acceptată în sălile #parkour\n• <font color = '#ef1111'>VPN farming</font> va fi considerat un<B>abuz</B> și nu este admis. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nOricine va fi prins că încalcă aceste reguli va fi banat imediat.</B></font></p>\n\n<font size = '12'>Transformice acceptă conceptul de trolling. Cu toate acestea, <font color='#cc2222'><B>noi nu vom accepta acest lucru în parkour</B></font></font>\n\n<p align = 'center'><J>Troll-ul este atunci când un jucător oprește în mod intenționat ceilalți jucători din a termina hart folosindu-și puterile sau consumabilele.</j></p>\n• Trolling-ul ca revanșă <B>nu este un motiv valid</B>de a trolla pe cineva și nu te scutește de pedeapsă.\n• Ajutatul cu forța al celorlalți jucători care vor să termine harta singuri, fără a te opri când ți se cere, este considerat trolling.\n• <J>Dacă un jucător nu vrea ajutor și preferă să facă harta de unul singur, te rugăm să încerci să ajuți alți jucători.</J>. Cu toate acestea, dacă un alt jucător are nevoie de ajutor la același checkpoint ca jucătorul care vrea să joace singur,  îi poți ajuta [pe amândoi].\n\nDacă un jucător este prins că a făcut troll, va fi sancționat pe bază de timp.",
		help_contribute = "<font size='14'>\n<p align='center'>Echipa parkour adoră codul open source deoarece <t>ajută comunitatea</t>. Poți <o>vedea</o> și <o>modifica</o> codul sursă pe <o><u><a href='event:github'>GitHub</a></u></o>.\n\nÎntreținerea modulului este <t>strict voluntară</t>, așa că orice ajutor în legătură cu <t>codul</t>, <t>probleme ale jocului</t>, <t>sugestii</t> și <t>crearea de hărți</t> este mereu <u>primită și apreciată</u>.\nPoți <vp>raporta probleme</vp> și <vp>da sugestii</vp> pe <o><u><a href='event:discord'>Discord</a></u></o> și/sau <o><u><a href='event:github'>GitHub</a></u></o>.\nPoți să <vp>trimiți hărțile</vp> în discuția <o><u><a href='event:map_submission'>de pe forum</a></u></o>.\n\nÎntreținerea parkourului nu este scumpă, dar nici gratis. Am aprecia dacă ne-ai ajuta <t>donând orice sumă</t> <o><u><a href='event:donate'>aici</a></u></o>.\n<u>Toate donațiile vor duce la îmbunătățirea modulului.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.10.0 - 17/04/2021</o></p>\n\n<font size='11'>• <font size='13'><b><j>TREI</J></b> titluri Transformice noi care pot fi deblocate doar jucând <font color='#1A7EC9'><b>#parkour</b></font>!</font>\n• Două statusuri noi adăugate profilului.\n• Ajustări minore de text.",
	
		-- Congratulation messages
		reached_level = "<d>Felicitări! Ai atins nivelul <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> a terminat parkour în <vp>%s</vp> secunde, <fc>felicitări!",
		unlocked_power = "<ce><d>%s</d> a deblocat puterea <vp>%s</vp>.",
	
		-- Information messages
		mod_apps = "<j>Aplicațiile pentru moderator sunt deschide! Folosește acest link: <rose>%s",
		staff_power = "<r>Personalul parkour <b>nu are</b> nicio putere în afara sălilor de #parkour.",
		donate = "<vp>Scrie <b>!donate</b> dacă dorești să donezi pentru acest modul!",
		paused_events = "<cep><b>[Atenție!]</b> <n>Modulul a atins limita critcă și este pauzat.",
		resumed_events = "<n2>Modulul a fost eliberat.",
		welcome = "<n>Bine ai venit pe <t>#parkour</t>!",
		module_update = "<r><b>[Atenție!]</b> <n>Modulul se va actualiza în <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>Clasamentul a fost încărcat. Apasă L pentru a-l deschide.",
		kill_minutes = "<R>Puterile tale au fost oprite pentru %s minute.",
		permbanned = "<r>Ai fost banat permanent de la #parkour.",
		tempbanned = "<r>Ai fost banat de la #parkour pentru %s minute.",
		forum_topic = "<rose>Pentru mai multe informații despre modul vizitează link-ul: %s",
		report = "<j>Vrei să raportezi un jucător? <t><b>/c Parkour#8558 .report Username#0000</b></t>",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Numărătoarea a început...",
		easter_egg_1  = "<ch>Au mai rămas mai puțin de 24 de ore!",
		easter_egg_2  = "<ch>Wow, ai venit cam devreme! Ești prea nerăbdător?",
		easter_egg_3  = "<ch>O surpriză vă așteaptă...",
		easter_egg_4  = "<ch>Ai vreo idee de ce va avea loc...?",
		easter_egg_5  = "<ch>Ceasul continuă să ticăie...",
		easter_egg_6  = "<ch>Surpriza e aproape!",
		easter_egg_7  = "<ch>Petrecerea e pe cale să înceapă...",
		easter_egg_8  = "<ch>Verifică ceasul, e timpul?",
		easter_egg_9  = "<ch>Ai grijă, timpul trece...",
		easter_egg_10 = "<ch>Relaxează-te, va fi mâine în curând!",
		easter_egg_11 = "<ch>Hai să ne culcăm devreme, va face timpul să treacă mai repede!",
		easter_egg_12 = "<ch>Răbdarea e o virtute",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Hărți duble Sâmbătă (GMT+2) și toate puterile puterile deblocate în săptămâna aniversării parkour!",
		double_maps_start = "<rose>E SĂPTĂMÂNA ANIVERSĂRII PARKOUR! Hărți duble și toate puterile deblocate vă așteaptă. Mulțumim că joci parkour!",
		double_maps_end = "<rose>Săptămâna aniversării Parkour s-a sfârșit. Mulțumim că joci parkour!",
	
		-- Records
		records_enabled = "<v>[#] <d>Modul de record a fost pornit pe această sală. Statisticile nu vor conta iar puterile sunt dezactivate!\nPoți afla mai multe pe <b>%s</b>",
		records_admin = "<v>[#] <d>Ești un administrator pe această sală de recorduri. Poți folosi comenzile <b>!map</b>, <b>!setcp</b>, <b>!pw</b> și <b>!time</b>.",
		records_completed = "<v>[#] <d>Ai completat harta! Dacă vrei să încerci din nou, scrie <b>!redo</b>.",
		records_submit = "<v>[#] <d>Wow! Se pare că ai avut cel mai scurt timp de pe sală. Dacă vrei să îți trimiți recordul, scrie <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Se pare că această hartă nu este în rotația parkour... Nu poți trimite un record pentru ea!",
		records_not_fastest = "<v>[#] <r>Se pare că nu ești cel mai rapid jucător de pe sală...",
		records_already_submitted = "<v>[#] <r>Deja ai trimis un record pentru această hartă!",
		records_submitted = "<v>[#] <d>Recordul tău pentru harta <b>%s</b> a fost trimis.",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>EȘTI ÎN MODUL AFK</b></bv>\nMIȘCĂ-TE PENTRU A JUCA</font>\n\n<font size='30'><u><t>Reamintire:</t></u></font>\n\n<font size='15'><r>Jucătorii cu o linie roșie deasupra lor nu doresc ajutor!\nTrolling/blocarea altor jucători în parkour NU este permisă!<d>\nAlătură-te <cep><a href='event:discord'>serverului nostru de discord</a></cep>!\nVrei să contribui cu cod? Vizitează <cep><a href='event:github'>pagina noastră github</a></cep>\nAi o hartă bună? Posteaz-o în <cep><a href='event:map_submission'>firul pentru hărți parkour</a></cep>\nVerifică <cep><a href='event:forum'>firul oficial</a></cep> pentru mai multe informații!\nAjută-ne <cep><a href='event:donate'>donând!</a></cep>",
		options = "<p align='center'><font size='20'>Opțiuni Parkour</font></p>\n\nFolosește <b>QWERTY</b> (oprește dacă <b>AZERTY</b>)\n\nFolosește scurtătura <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> pentru <b>/mort</b> (oprește pentru <b>DEL</b>)\n\nArată-ți cooldown-urile pentru puteri\n\nArată butonul de puteri\n\nArată butonul de ajutor\n\nArată anunțurile de completare a hărților\n\nArată simbolul de „fără ajutor”\n\nDisable all UI (leaderboard, help, shop etc.) hotkeys",
		cooldown = "<v>[#] <r>Așteaptă câteva secunde pentru a face asta din nou.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'>tastatură <b>QWERTY</b>" ..
						 "\n\n<b>Ascunde</b> numărul hărților completate" ..
						 "\n\nPune <b>tasta obișnuită</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Completează <v>%s</v> hărți" ..
						"<font size='5'>\n\n</font>pentru a debloca" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Completează <v>%s</v> hărți" ..
						"<font size='5'>\n\n</font>pentru a îmbunătăți" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Fii pe locul <v>%s</v>" ..
						"<font size='5'>\n\n</font>pentru a debloca" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Fii pe locul <v>%s</v>" ..
						"<font size='5'>\n\n</font>pentru a îmbunătăți" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Hărți completate"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Clasamentul general"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Clasamentul săptămânal"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Insigne (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>Hărțile acestui jucător sunt private. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Poziția în clasamentul general: <b><v>%s</v></b>\n\n" ..
					"Poziția în clasamentul săptămânal<b><v>%s</v></b>\n\n%s"),
		map_count = "Hărți completate: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Hărți completate: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Checkpointuri colectate: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Insignele sunt realizări pe care jucătorii le pot debloca. Apasă pe ele pentru a afla mai multe.",
		help_private_maps = "Acest jucător nu vrea să-și arate numărul hărților! Le poți ascunde și tu pe profil.",
		help_yellow_maps = "Hărțile galbene sunt hărțile completate în această săptămână.",
		help_red_maps = "Hărțile roșii sunt hărțile completate în ultima oră.",
		help_map_count_title = "Poți primi titluri <b>Transformice</b> completând hărți parkour!",
		help_checkpoint_count_title = "Poți primi titluri <b>Transformice</b> colectând toate checkpointurile în hărți parkour!",
		help_badge_1 = "Acest jucător a fost parte din personalul parkour.",
		help_badge_2 = "Acest jucător este sau a fost în prima pagină a clasamentului general.",
		help_badge_3 = "Acest jucător este sau a fost în a doua pagină a clasamentului general.",
		help_badge_4 = "Acest jucător este sau a fost în a treia pagină a clasamentului general.",
		help_badge_5 = "Acest jucător este sau a fost în a patra pagină a clasamentului general.",
		help_badge_6 = "Acest jucător este sau a fost în a cincea pagină a clasamentului general.",
		help_badge_7 = "Acest jucător a fost pe podium la finalul clasamentului săptămânal.",
		help_badge_8 = "Acest jucător a reușit să termine 30 de hărți într-o oră.",
		help_badge_9 = "Acest jucător a reușit să termine 35 de hărți într-o oră.",
		help_badge_10 = "Acest jucător a reușit să termine 40 de hărți într-o oră.",
		help_badge_11 = "Acest jucător a reușit să termine 45 de hărți într-o oră.",
		help_badge_12 = "Acest jucător a reușit să termine 50 de hărți într-o oră.",
		help_badge_13 = "Acest jucător a reușit să termine 55 de hărți într-o oră.",
		help_badge_14 = "Acest jucător și-a verificat contul de discord pe serverul oficial parkour (scrie <b>!discord</b>).",
		help_badge_15 = "Acest jucător are record pe o hartă.",
		help_badge_16 = "Acest jucător are record pe 5 hărți.",
		help_badge_17 = "Acest jucător are record pe 10 hărți.",
		help_badge_18 = "Acest jucător are record pe 15 hărți.",
		help_badge_19 = "Acest jucător are record pe 20 hărți.",
		help_badge_20 = "Acest jucător are record pe 25 hărți.",
		help_badge_21 = "Acest jucător are record pe 30 hărți.",
		help_badge_22 = "Acest jucător are record pe 35 hărți.",
		help_badge_23 = "Acest jucător are record pe 40 hărți.",
		make_public = "fă public",
		make_private = "fă privat",
		moderators = "Moderatori",
		mappers = "Mappers",
		managers = "Manageri",
		administrators = "Administratori",
		close = "Închide",
		cant_load_bot_profile = "<v>[#] <r>Nu poți vedea profilul acestui bot întrucât #parkour îl folosește intern pentru a funcționa cum trebuie.",
		cant_load_profile = "<v>[#] <r>Jucătorul <b>%s</b> pare să fie offline sau nu există.",
		like_map = "Îți place această hartă?",
		yes = "Da",
		no = "Nu",
		idk = "Nu știu bro, nu-s de aici",
		vote_map = "<font color='#ffffff' size='13'><b>Îți place această hartă? <font size='14'><a href='event:mapPollYes'><PT>Da</a> <a href='event:mapPollidk'><N>Nu știu</a> <a href='event:mapPollNo'><R>Nu</a>",
		unknown = "Necunoscut",
		powers = "Puteri",
		press = "<vp>Apasă %s",
		click = "<vp>Click stânga",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Hărți completate: %s</B></p></BV>",
		leaderboard = "Clasament",
		position = "<V><p align=\"center\">Poziție",
		username = "<V><p align=\"center\">Nume",
		community = "<V><p align=\"center\">Comunitate",
		completed = "<V><p align=\"center\">Hărți completate",
		overall_lb = "În general",
		weekly_lb = "Săptămânal",
		new_lang = "<v>[#] <d>Limbă a fost setată în Română",
		room = "Room",
		time = "Time",
		buy = "Buy",
		equip = "Equip",
		equipped = "<font size = '10'>Equipped</font>",
	
		-- Power names
		balloon = "Balon",
		masterBalloon = "Balon II",
		bubble = "Balon III",
		fly = "Zboară",
		snowball = "Bulgăre",
		speed = "Viteză",
		teleport = "Teleportare",
		smallbox = "Cutie mică",
		cloud = "Nor",
		rip = "Sicriu",
		choco = "Ciocoscândură",
		bigBox = "Cutie mare",
		trampoline = "Trambulină",
		toilet = "Toaletă",
		pig = "Porc",
		sink = "Chiuvetă",
		bathtub = "Cadă",
		campfire = "Foc de tabără",
		chair = "Scaun",
		link = "Suflet pereche",
	
	}
	--[[ End of file translations/parkour/ro.lua ]]--
	--[[ File translations/parkour/ru.lua ]]--
	translations.ru = {
		name = "ru",
		fullname = "Русский",
	
		-- Сообщения об ошибках
		corrupt_map = "<r>Поврежденная карта. Загружаем другую.",
		corrupt_map_vanilla = "<r>[ОШИБКА] <n>Не удается получить информацию о карте.",
		corrupt_map_mouse_start = "<r>[ОШИБКА] <n>Карта должна иметь начальную позицию (точку появления мыши).",
		corrupt_map_needing_chair = "<r>[ОШИБКА] <n>На карте должно находиться кресло для окончания раунда.",
		corrupt_map_missing_checkpoints = "<r>[ОШИБКА] <n>Карта должна иметь хотя бы один чекпоинт (желтый гвоздь).",
		corrupt_data = "<r>К сожалению, Ваши данные повреждены и были сброшены.",
		min_players = "<r>Чтобы сохранить Ваши данные, в комнате должно быть как минимум 4 уникальных игрока. <bl>[%s/%s]",
		tribe_house = "<r>Данные не будут сохранены в комнате племени.",
		invalid_syntax = "<r>Неверный синтаксис.",
		code_error = "<r>Появилась ошибка: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Активировано аварийное отключение, новые игроки не смогут зайти. Пожалуйста, перейдите в другую комнату #parkour.",
		leaderboard_not_loaded = "<r>Таблица лидеров еще не загружена. Подождите минуту.",
		max_power_keys = "<v>[#] <r>У Вас может быть только максимум %s способностей для одной клавиши.",
	
		-- Help window
		help = "Помощь",
		staff = "Команда модераторов",
		rules = "Правила",
		contribute = "Содействие",
		changelog = "Изменения",
		help_help = "<p align = 'center'><font size = '14'>Добро пожаловать в <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Ваша цель - собрать все чекпоинты, чтобы завершить карту.</J></p>\n\n<N>• Нажмите <O>O</O>, введите <O>!op</O> или нажмите на <O> шестеренку</O> чтобы открыть <T>меню настроек</T>.\n• Нажмите <O>P</O> или нажмите на <O>руку</O> в правом верхнем углу, чтобы открыть <T>меню со способностями</T>.\n• Нажмите <O>L</O> или введите <O>!lb</O> чтобы открыть <T>Список лидеров</T>.\n• Нажмите <O>M</O> или <O>Delete</O> чтобы не прописывать <T>/mort</T>.\n• Чтобы узнать больше о нашей <O>команде</O> и о <O>правилах Паркура</O>, нажмите на <T>Команда</T> и <T>Правила</T>.\n• Нажмите <a href='event:discord'><o>здесь</o></a>, чтобы получить ссылку на приглашение в наш Дискорд канал. Нажмите <a href='event:map_submission'><o>здесь</o></a> чтобы получить ссылку на тему отправки карты.\n• Используйте клавиши <o>вверх</o> и <o>вниз</o> чтобы листать меню.\n\n<p align = 'center'><font size = '13'><T>Вкладки теперь открыты! Для получения более подробной информации, нажмите на вкладку <O>Содействие</O> !</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>ОБЯЗАННОСТИ: Команда Паркура НЕ команда Трансформайс и НЕ имеет никакой власти в самой игре, только внутри модуля.</r>\nКоманда Паркура обеспечивают исправную работу модуля с минимальными проблемами и всегда готова помочь игрокам в случае необходимости.</font></p>\nВы можете ввести <D>!staff</D> в чат, чтобы увидеть нашу команду.\n\n<font color = '#E7342A'>Администраторы:</font> Hесут ответственность за поддержку самого модуля, добавляя новые обновления и исправляя ошибки.\n\n<font color = '#D0A9F0'>Руководители команд:</font> Kонтролируют команды модераторов и картостроителей, следя за тем, чтобы они хорошо выполняли свою работу. Они также несут ответственность за набор новых членов в команду.\n\n<font color = '#FFAAAA'>Модераторы:</font> Hесут ответственность за соблюдение правил модуля и наказывают тех, кто не следует им.\n\n<font color = '#25C059'>Картостроители:</font> Oтвечают за просмотр, добавление и удаление карт в модуле, обеспечивая вам приятный игровой процесс.",
		help_rules = "<font size = '13'><B><J>Все правила пользователя и условия Трансформайс также применяются к #parkour </J></B></font>\n\nЕсли вы обнаружили, что кто-то нарушает эти правила, напишите нашим модераторам. Если модераторов нет в сети, вы можете сообщить об этом на на нашем сервере в Дискорде\nПри составлении репорта, пожалуйста, укажите сервер, имя комнаты и имя игрока.\n• Пример: en-#parkour10 Blank#3495 троллинг\nДоказательства, такие как скриншоты, видео и гифки, полезны и ценны, но не обязательны.\n\n<font size = '11'>• <font color = '#ef1111'>читы, глюки или баги</font> не должны использоваться в комнатах #parkour\n• <font color = '#ef1111'>Фарм через VPN</font> считается <B>нарушением</B> и не допускается. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nЛюбой, кто пойман за нарушение этих правил, будет немедленно забанен.</B></font></p>\n\n<font size = '12'>Трансформайс позволяет концепцию троллинга. Однако, <font color='#cc2222'><B>мы не допустим этого в Паркуре.</B></font></font>\n\n<p align = 'center'><J>Троллинг - это когда игрок намеренно использует свои силы или инвентарь, чтобы помешать другим игрокам пройти/закончить карту.</J></p>\n• Троллинг ради мести <B>не является веской причиной,</B> для троллинга кого-либо и вы все равно будете наказаны.\n• Принудительная помощь игрокам, которые пытаются пройти карту самостоятельно и отказываюся от помощи, когда их об этом просят, также считается троллингом. \n• <J>Если игрок не хочет помогать или предпочитает играть в одиночку на карте, постарайтесь помочь другим игрокам</J>. Однако, если другой игрок нуждается в помощи на том же чекпоинте, что и соло игрок, Вы можете помочь им [обоим].\n\nЕсли игрок пойман за троллингом, он будет наказан на временной основе. Обратите внимание, что повторный троллинг приведет к более длительным и суровым наказаниям.",
		help_contribute = "<font size='14'>\n<p align='center'>Команда управления Паркуром предпочитает открытый исходный код, потому что он <t>помогает сообществу</t>. Вы можете <o>посмотреть</o> и <o>улучшить</o> исходный код на <o><u><a href='event:github'>GitHub</a></u></o>.\nПоддержание модуля<t>строго добровольно</t>, так что любая помощь в отношении <t>кода</t>, <t>бага репортов</t>, <t>предложений</t> и <t>созданию карт</t> всегда <u>приветствуется и ценится</u>.\nВы можете <vp>оставлять жалобу</vp> и <vp>предлагать улучшения</vp> в нашем <o><u><a href='event:discord'>Дискорде</a></u></o> и/или в <o><u><a href='event:github'>GitHub</a></u></o>.\nВы можете <vp>отправить свои карты</vp> на нашем <o><u><a href='event:map_submission'>форуме</a></u></o>.\n\nПоддержание Паркура не дорогое, но и не бесплатное. Мы будем рады, если Вы поможете нам <t>любой суммой</t> <o><u><a href='event:donate'>здесь</a></u></o>.\n<u>Все пожертвования пойдут на улучшение модуля.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Версия 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Введение квест-системы. (Нажмите <J><B>,</B></J> чтобы открыть страницу квестов.)\n\n<font size='11'>• <font size='13'>Добавлена возможность отключения горячих клавиш для всех меню, таких как: таблица лидеров, помощь, магазин и т.д.\n\n<font size='11'>• <font size='13'>Добавлена <B><J>!cp [ИмяИгрока#tag]</J></B> команда, устанавливающая Ваш текущий чекпоинт в качестве чекпоинта указанного игрока.",
	
		-- Congratulation messages
		reached_level = "<d>Поздравляем! Вы достигли уровня <vp>%s</vp>. (<t>%ss</t>)",
		finished = "<d><o>%s</o> завершили Паркур за <vp>%s</vp> секунд, <fc>поздравляем!",
		unlocked_power = "<ce><d>%s</d> разблокировали способность <vp>%s</vp>.",
	
		-- Information messages
		mod_apps = "<j>Приложения Паркура модератора теперь открыты! Используйте эту ссылку: <rose>%s",
		staff_power = "<r>Команда Паркура <b>не</b> имеет власти вне #parkour комнат.",
		donate = "<vp>Введите <b>!donate</b>, если хотите пожертвовать на этот модуль!",
		paused_events = "<cep><b>[Предупреждение!]</b> <n> Модуль достиг критического предела и сейчас временно остановлен.",
		resumed_events = "<n2>Модуль был возобновлен.",
		welcome = "<n>Добро пожаловать в<t>#parkour</t>!",
		module_update = "<r><b>[Предупреждение!]</b> <n>Модуль будет обновлен в <d>%02d:%02d</d>.",
		leaderboard_loaded = "<j>Таблица лидеров была загружена. Нажмите L, чтобы открыть ее.",
		kill_minutes = "<R>Ваши способности отключены на %s минут.",
		permbanned = "<r>Вы были навсегда забанены в #parkour.",
		tempbanned = "<r>Вы были забанены в #parkour на %s минут.",
		forum_topic = "<rose>Для получения дополнительной информации о модуле, посетите эту ссылку: %s",
		report = "<j>Хотите пожаловаться на игрока? <t><b>/c Parkour#8558 .report Никнейм#0000</b></t>",
		killed = "<v>[#] <r>Вы не можете использовать свои способности %s минут из-за нарушения правил Паркура. Продолжительное нарушение правил ведет к бану. Пожалуйста, нажмите <b>H</b>, чтобы просмотреть правила.",
		mapper_event = "<CE><B>Конкурс карт для Паркура 2024:</B>\n<n>Покажите нам Вашу кративность в создании карт, чтобы выиграть <D>сыр <n>и <pt>монеты Паркура<n>!\n<R>Приём заявок открыт до <B>31 января 2024 года</B>.\n<PS>Для дополнительной информации, посетите: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Итак, наступает обратный отсчет...",
		easter_egg_1  = "<ch>Остается меньше, чем 24 часа!",
		easter_egg_2  = "<ch>Вау, Вы пришли очень рано! Вы слишком взволнованы?",
		easter_egg_3  = "<ch>Ожидается сюрприз...",
		easter_egg_4  = "<ch>Вы знаете о том, что должно произойти...?",
		easter_egg_5  = "<ch>Часы продолжают тикать...",
		easter_egg_6  = "<ch>Сюрприз близок!",
		easter_egg_7  = "<ch>Вечеринка скоро начнется...",
		easter_egg_8  = "<ch>Взгляните на часы, не пора ли?",
		easter_egg_9  = "<ch>Будьте осторожны, время идет...",
		easter_egg_10 = "<ch>Просто сядьте и расслабьтесь, это будет завтра в кратчайшие сроки!",
		easter_egg_11 = "<ch>Давайте ляжем спать пораньше, это сделает время быстрее!",
		easter_egg_12 = "<ch>Терпение - это добродетель",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Удвоенные карты и все силы доступы на неделе рождения Паркура!",
		double_maps_start = "<rose>ЭТО НЕДЕЛЯ РОЖДЕНИЯ ПАРКУРА! Удвоенные карты и все силы были активированы. Спасибо за то, что играете с нами!",
		double_maps_end = "<rose>Неделя рождения паркура закончилась. Спасибо за то, что играете с нами!",
	
		-- Records
		records_enabled = "<v>[#] <d>RВ этой комнате включен режим рекордов. Статистика не учитывается, а умения отключены!\nВы можете найти больше информации в <b>%s</b>",
		records_admin = "<v>[#] <d>Вы администратор этой комнаты. Вы можете использовать команды <b>!map</b>, <b>!setcp</b>, <b>!pw</b> и <b>!time</b>.",
		records_completed = "<v>[#] <d>Вы прошли карту! Если Вы хотите сделать это заново, введите <b>!redo</b>.",
		records_submit = "<v>[#] <d>Вот Это Да! Похоже, Вы быстрее всех прошли карту. Если хотите поделиться своим рекордом, введите  <b>!submit</b>.",
		records_invalid_map = "<v>[#] <r>Похоже, эта карта не в ротации паркура... Вы не можете сохранить рекорд для нее!",
		records_not_fastest = "<v>[#] <r>Кажется, Вы не самый быстрый игрок в комнате...",
		records_already_submitted = "<v>[#] <r>Вы уже отправили свой рекорд для этой карты!",
		records_submitted = "<v>[#] <d>Ваш рекорд на этой карте <b>%s</b> был сохранен.",
	
		-- Quests
		daily_q = "Ежедневные",
		weekly_q = "Недельные",
		daily_quests = "<p align='center'><font size='20'><B><D>Ежедневные задания</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Недельные задания</D></B></font>",
		quest_1 = "Пройдите <B><D>%s/%s</D></B> карт.",
		quest_2 = "Соберите <B><D>%s/%s</D></B> контрольных точек.",
		quest_3 = "Пройдите любую карту, заняв первое место <B><D>%s/%s</D></B> раз.",
		quest_4 = "Пройдите карту меньше, чем за <B><D>%s</D></B> секунд.",
		quest_5 = "Пройдите карту <B><D>@%s</D></B>",
		quest_6 = "Используйте <PT><b>%s</b></PT> способность <B><D>%s/%s</D></B> раз.",
		next_reset = "<b><D>Сброс:\n</b></D>%s",
		quest_completed = "<b><D>Поздравляем!</D></b> \nВы завершили %s задание!",
		quest_reset = "<V>[#]</V> <O>Ваши %s заданий были сброшены.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Санта только что заглянул в гости! Отыщите рождественский подарок на карте и разверните \"сюрприз\"!",
		find_gift2 = "<ch>Звените всю дорогу! На карте волшебным образом появился особый рождественскй подарок - найдите его!",
		find_gift3 = "<ch>Хо, хо, хо! Маленький помощник Санты оставил для Вас подарок, который нужно найти на данной карте!",
		find_gift4 = "<ch>Рождественское настроение витает в воздухе! Отыщите рождественский подарок, спрятанный на этой карте!",
		find_gift5 = "<ch>Веселого Паркурждества! Эльфы спрятали для Вас подарок. Сможете его найти?",
		found_gift1 = "<ch>Ура! <J>%s</J> развернули подарок и нашли %s монеты внутри!",
		found_gift2 = "<ch>Ура, <J>%s</J>! Вы только что выиграли <J>%s</J> сверкающих монет из волшебного подарка Санты!",
		found_gift3 = "<ch>Это победа для <J>%s</J>! На <J>%s</J> монет богаче, спасибо Санте!",
		found_gift4 = "<ch>Поздравляем <J>%s</J> с выигрышем <J>%s</J> монет! Дух Рождества сияет ярко!",
		found_gift5 = "<ch>Санта одарил <J>%s</J> <J>%s</J> ослепительными монетами!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>ВЫ В РЕЖИМЕ АФК</b></bv>\nНажмите клавишу передвижения, чтобы возродиться</font>\n\n<font size='30'><u><t>Напоминания:</t></u></font>\n\n<font size='15'><r>Игроки с красной линией над их именами не хотят помощи!\nТроллинг/блокировка пути другим игрокам запрещены!<d>\nПрисоединяйтесь к нашему дискорд серверу! <cep><a href='event:discord'>Дискорд сервер</a></cep>!\nХотите внести собственный вклад в код? Смотрите наш <cep><a href='event:github'>репозиторий github</a></cep>\nУ Вас есть хорошая карта, которую можно отправить? Разместите её в нашей <cep><a href='event:map_submission'>теме для публикации карт </a></cep>\nПроверьте наш <cep><a href='event:forum'>официальный пост</a></cep> для большей информации!\nПоддержите нас <cep><a href='event:donate'>здесь!</a></cep>",
		options = "<p align='center'><font size='20'>Параметры Паркура</font></p>\n\nИспользуйте <b>раскладку QWERTY</b> на клавиатуре\n(отключить если <b>AZERTY</b>)\nИспользуйте <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> горячую клавишу <b>/mort</b> (отключить <b>DEL</b>)\n\nПоказать Ваше время перезарядки\n\nПоказать кнопку способностей\n\nПоказать кнопку помощь\n\nПоказать объявление о завершении карты\n\nПоказать символ \"помощь не нужна\"\n\nОтключить все горячие клавиши пользовательского интерфейса\n(таблица лидеров, помощь, магазин и т.д.)",
		cooldown = "<v>[#] <r>Подождите несколько минут, чтобы повторить действие.",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> клавиатура" ..
						 "\n\n<b>Скрыть</b> Подсчет карт" ..
						 "\n\n<b>дефолт клавиша</b>"),
		unlock_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Пройденные <v>%s</v> карты" ..
						"<font size='5'>\n\n</font>разблокированы" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Пройденные <v>%s</v> карты" ..
						"<font size='5'>\n\n</font>обновлены" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ранг <v>%s</v>" ..
						"<font size='5'>\n\n</font>разблокирован" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>Ранг <v>%s</v>" ..
						"<font size='5'>\n\n</font>обновлен" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Пройденые карты"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Общая таблица лидеров"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					   "<font size='5'>\n\n</font>Еженедельная таблица лидеров"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Бейджи (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>Количество карт этого игрока является частным.<a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Общая таблица лидеров: <b><v>%s</v></b>\n\n" ..
					"Еженедельначя таблица лидеров: <b><v>%s</v></b>\n\n%s"),
		map_count = "Количество карт: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Пройденные карты: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Собранные чекпоинты: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Значки - это достижение, которое может получить игрок. Нажмите на них, чтобы увидеть их описание.",
		help_private_maps = "Этот игрок не любит открыто публиковать количество своих карт! Вы также можете скрыть их в своем профиле.",
		help_yellow_maps = "Желтым цветом обозначены карты, завершенные на этой неделе.",
		help_red_maps = "Карты красного цвета - это карты, завершенные за последний час.",
		help_map_count_title = "Вы можете получить титулы <b>Трансформайс</b>, завершая карты паркура!",
		help_checkpoint_count_title = "Вы можете получить титулы <b>Трансформайс</b>, собирая все чекпоинты на картах паркура!",
		help_badge_1 = "Этот игрок в прошлом был сотрудником паркура.",
		help_badge_2 = "Этот игрок находится или был на странице 1 общей таблицы лидеров.",
		help_badge_3 = "Этот игрок находится или был на странице 2 общей таблицы лидеров.",
		help_badge_4 = "Этот игрок находится или был на странице 3 общей таблицы лидеров.",
		help_badge_5 = "Этот игрок находится или был на странице 4 общей таблицы лидеров.",
		help_badge_6 = "Этот игрок находится или был на странице 5 общей таблицы лидеров.",
		help_badge_7 = "Этот игрок был в еженедельной таблицы лидеров.",
		help_badge_8 = "У этого игрока рекорд - 30 карт в час.",
		help_badge_9 = "У этого игрока рекорд - 35 карт в час.",
		help_badge_10 = "У этого игрока рекорд - 40 карт в час.",
		help_badge_11 = "У этого игрока рекорд - 45 карт в час.",
		help_badge_12 = "У этого игрока рекорд - 50 карт в час.",
		help_badge_13 = "У этого игрока рекорд - 55 карт в час.",
		help_badge_14 = "Этот пользователь подтвердил свою учетную запись на официальном канале сервера паркура (нажмите <b>!discord</b>).",
		help_badge_15 = "Этот игрок показал лучшее время на 1 карте.",
		help_badge_16 = "Этот игрок показал лучшее время на 5 картах.",
		help_badge_17 = "Этот игрок показал лучшее время на 10 картах.",
		help_badge_18 = "Этот игрок показал лучшее время на 15 картах.",
		help_badge_19 = "Этот игрок показал лучшее время на 20 картах.",
		help_badge_20 = "Этот игрок показал лучшее время на 25 картах.",
		help_badge_21 = "Этот игрок показал лучшее время на 30 картах.",
		help_badge_22 = "Этот игрок показал лучшее время на 35 картах.",
		help_badge_23 = "Этот игрок показал лучшее время на 40 картах.",
		make_public = "сделать публичным",
		make_private = "сделать приватым",
		moderators = "Модераторы",
		mappers = "Maпперы",
		managers = "Mенеджеры",
		administrators = "Администрация",
		close = "Закрыть",
		cant_load_bot_profile = "<v>[#] <r>Вы не можете просмотреть профиль этого бота, так как #parkour использует его для корректной работы модуля.",
		cant_load_profile = "<v>[#] <r>Игрок <b>%s</b>, похоже, не в сети или его не существует.",
		like_map = "Вам нравится эта карта?",
		yes = "Да",
		no = "Нет",
		idk = "Я не знаю",
		vote_map = "<font color='#ffffff' size='13'><b>Вам нравится эта карта? <font size='14'><a href='event:mapPollYes'><PT>Да</a> <a href='event:mapPollidk'><N>Я не знаю</a> <a href='event:mapPollNo'><R>Нет</a>",
		unknown = "Неизвестно",
		powers = "Способности",
		press = "<vp>Нажмите %s",
		click = "<vp>Щелчок левой кнопкой мыши",
		ranking_pos = "Рейтинг #%s",
		completed_maps = "<p align='center'><BV><B>Пройденные карты: %s</B></p></BV>",
		leaderboard = "Таблица лидеров",
		position = "<V><p align=\"center\">Должность",
		username = "<V><p align=\"center\">Имя пользователя",
		community = "<V><p align=\"center\">Сообщество",
		completed = "<V><p align=\"center\">Пройденные карты",
		overall_lb = "В целом",
		weekly_lb = "Еженедельно",
		new_lang = "<v>[#] <d>Язык установлен на Русский",
		room = "Комната",
		time = "Время",
		buy = "Купить",
		equip = "Надеть",
		equipped = "<font size = '10'>Надето</font>",
		saving = "<p align='right'>Сохраняется...",
	
		-- Power names
		balloon = "Шар",
		masterBalloon = "Шар II",
		bubble = "Пузырь",
		fly = "Полет",
		snowball = "Снежок",
		speed = "Скорость",
		teleport = "Телепорт",
		smallbox = "Маленький ящик",
		cloud = "Облако",
		rip = "Могила",
		choco = "Шоколадная палка",
		bigBox = "Большая коробка",
		trampoline = "Батут",
		toilet = "Туалет",
		pig = "Свинья",
		sink = "Тонуть",
		bathtub = "Ванна",
		campfire = "Костёр",
		chair = "Стул",
		link = "Партнер",
	}
	--[[ End of file translations/parkour/ru.lua ]]--
	--[[ File translations/parkour/tr.lua ]]--
	translations.tr = {
		name = "tr",
		fullname = "Türkçe",
	
		-- Error messages
		corrupt_map= "<r>Harita bozulmuş. Başka bir tane yükleniyor.",
		corrupt_map_vanilla = "<r>[HATA] <n>Bu harita hakkında bilgi alınamıyor.",
		corrupt_map_mouse_start= "<r>[HATA] <n>Bu haritanın bir başlangıç noktası olması gerekiyor (fare başlangıç noktası).",
		corrupt_map_needing_chair= "<r>[HATA] <n>Haritanın bitiş koltuğu olması gerekiyor.",
		corrupt_map_missing_checkpoints = "<r>[HATA] <n>Haritada en az bir kontrol noktası olması gerekiyor(sarı çivi).",
		corrupt_data = "<r>Maalesef, sizin verileriniz kayboldu ve sıfırlandı.",
		min_players = "<r>Verinizin kaydedilebilmesi için odada en az 4 farklı oyuncunun bulunması gerekmektedir. <bl>[%s/%s]",
		tribe_house = "<r>Veri kabile evlerinde işlenmeyecektir..",
		invalid_syntax = "<r>Geçersiz söz dizimi.",
		code_error = "<r>Bir sorun oluştu: <bl>%s-%s-%s %s",
		emergency_mode = "<r>Acil durum modu başlatılıyor, yeni oyunculara izin verilmemektedir. Lütfen başka bir #parkour odasına geçin.",
		leaderboard_not_loaded = "<r>Lider tablosu henüz yüklenemedi. Lütfen bekleyin.",
		max_power_keys = "<v>[#] <r>Aynı tuşta sadece %s güç bulundurabilirsin",
		room_name_length = "<ROSE><b>[HATA]</b> Oda adı, izin verilen <b>45</b karakter uzunluğunu aşıyor. Lütfen daha kısa bir oda adı seçin.",
	
	
		-- Help window
		help = "Yardım",
		staff = "Ekip",
		rules = "Kurallar",
		contribute = "Bağış",
		changelog = "Yenilikler",
		help_help = "<p align = 'center'><font size = '14'>Hoş geldiniz <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Amacınız haritayı tamamlayana kadar bütün kontrol noktalarına ulaşmak.</J></p>\n\n<font size='11'><N>•  Ayarlar menüsü açmak için klavyeden <O>O</O> tuşuna basabilir, <O>!op</O> yazabilir veya <O>çark</O> simgesine tıklayabilirsiniz.\n• Beceri menüsüne ulaşmak için klavyeden <O>P</O> tuşuna basabilir veya sağ üst köşedeki <O>El</O> simgesine tıklayabilirsiniz.\n• Lider tablosuna ulaşmak için <O>L</O> tuşuna basabilir veya <O>!lb</O> yazabilirsiniz.\n• Ölmek için <O>M</O> veya <O>Delete</O> tuşuna basabilirsiniz. <O>Delete</O> tuşunu kullanabilmek için <J>Ayarlar</J> kısımından <O>M</O> tuşu ile ölmeyi kapatmanız gerekmektedir.\n•  Ekip ve parkur kuralları hakkında daha fazla bilgi bilgi almak için, <O>Ekip</O> ve <O>Kurallar</O> sekmesine tıklayın.\n• <a href='event:discord'><o>Buraya Tıklayarak</o></a> discord davet bağlantımıza ulaşabilir ve <a href='event:map_submission'><o>Buraya Tıklayarak</o></a> da harita göndermek için konu bağlantısını alabilirsiniz.\n• Kaydırma yapmanız gerektiğinde <o>yukarı</o> ve <o>aşağı</o> ok tuşlarını kullanın.\n\n<p align = 'center'><font size = '13'><T>Artık bize bağışta bulunabilirsiniz! Daha fazla bilgi için, <O>Bağış</O> sekmesine tıklayın!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>Bildiri: Parkur ekibi Transformice'ın ekibi DEĞİLDİR, sadece parkur modülünde yetkililerdir.</r>\nParkur ekibi modülün akıcı bir şekilde kalmasını sağlar ve her zaman oyunculara yardımcı olurlar.</font></p>\nEkip listesini görebilmek için <D>!staff</D> yazabilirsiniz.\n\n<font color = '#E7342A'>Yöneticiler:</font> Modülü yönetir, yeni güncellemeler getirir ve hataları düzeltirler.\n\n<font color = '#D0A9F0'>Ekip Yöneticileri:</font> Moderatörleri ve Haritacıları kontrol eder ve işlerini iyi yaptıklarından emin olurlar. Ayrıca ekibe yeni moderatör almaktan da onlar sorumludur.\n\n<font color = '#FFAAAA'>Moderatörler:</font> Kuralları uygulamak ve uygulamayan oyuncuları cezalandırmaktan sorumludurlar.\n\n<font color = '#25C059'>Haritacılar:</font> Yeni yapılan haritaları inceler, harita listesine ekler ve siz oyuncularımızın eğlenceli bir oyun deneyimi geçirmenizi sağlarlar.",
		help_rules = "<font size = '13'><B><J>Transformice'ın bütün kural ve koşulları #parkour içinde geçerlidir</J></B></font>\n\nEğer kurallara uymayan bir oyuncu görürseniz, oyun içinde parkour ekibindeki moderatörlerden birine mesaj atabilirsiniz. Eğer hiçbir moderatör çevrimiçi değilse discord sunucumuzda bildirebilirsiniz.\nBildirirken lütfen sunucuyu, oda ismini ve oyuncu ismini belirtiniz.\n• Örnek: tr-#parkour10 Sperjump#6504 trolling\nEkran görüntüsü,video ve gifler işe yarayacaktır fakat gerekli değildir..\n\n<font size = '11'>•#parkour odalarında <font color = '#ef1111'>hile ve hata</font> kullanmak YASAKTIR!\n• <font color = '#ef1111'>VPN farming</font> yasaktır, <B>Haksız kazanç elde etmeyin</B> .. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKuralları çiğneyen herkes uzaklaştıralacaktır.</B></font></p>\n\n<font size = '12'>Transformice trolleme konseptine izin verir. Fakat, <font color='#cc2222'><B>biz buna parkur modülünde izin vermiyoruz.</B></font></font>\n\n<p align = 'center'><J>Trollemek, bir oyuncunun, başka bir oyuncuya haritayı bitirmesini engellemek amacıyla güçlerini veya malzemelerini kullanmasıdır.</j></p>\n• İntikam almak için trollemek <B>geçerli bir sebep değildir</B> ve cezalandırılacaktır.\n• Haritayı tek başına bitirmek isteyen bir oyuncuya zorla yardım etmeye çalışmak trollemek olarak kabul edilecek ve cezalandırılacaktır.\n• <J>Eğer bir oyuncu yardım istemiyorsa ve haritayı tek başına bitirmek istiyorsa lütfen diğer oyunculara yardım etmeyi deneyin.</J>. Ancak yardım isteyen diğer oyuncu haritayı tek başına yapmak isteyen bir oyuncunun yanındaysa ona yardım edebilirsiniz.\n\nEğer bir oyuncu trollerken (başka bir oyuncunun haritayı bitirmesini engellerken) yakalanırsa, zaman temel alınarak cezalandırılacaktır. Sürekli bir şekilde trollemekten dolayı ceza alan bir oyuncu eğer hala trollemeye devam ederse cezaları daha ağır olacaktır..",
		help_contribute = "<font size='14'>\n<p align='center'>Parkur yönetim ekibi açık kaynak kodunu seviyor çünkü <t>bu topluluğa yardım ediyor</t>. Kaynak kodunu <o>görüntüleyebilir</o> ve <o>değiştirebilirsiniz</o> <o><u><a href='event:github'>GitHub'a Git</a></u></o>.\n\nModülün bakımı <t>isteklere göredir</t>, bu yüzden yardımda bulunmak için <t>kodlara</t> göz atmanız, <t>hataları bildirmeniz</t>, <t>öneride bulunmanız</t> ve <t>harita oluşturmanız</t> her zaman <u>hoş karşılanır ve takdir edilir</u>.\n<o><u><a href='event:discord'>Discord</a></u></o> veya <o><u><a href='event:github'>GitHub</a></u></o> hakkında <vp>hataları bildirmeniz</vp> ve <vp>öneride bulunmanız</vp> çok işimize yarıyacaktır.\n<o><u><a href='event:map_submission'>Forumdaki Konumuza</a></u></o> <vp>Haritalarınızı</vp> gönderebilirsiniz.\n\nParkour bakımı pahalı değil ama ücretsiz de değil. Herhangi bir miktar bağışlayarak bize yardımcı olabilirseniz seviniriz.</t><o><u><a href='event:donate'>Bağış Yapmak İçin Tıkla</a></u></o>.\n<u>Tüm bağışlar modülün geliştirilmesine yönelik olacaktır.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.15.0 - 1/12/2023</o></p>\n\n<font size='11'>• <font size='13'>Görev sistemi eklendi. (Görevler sayfasını açmak için <B><J>,</J></B> tuşuna basın.)\n\n<font size='11'>• <font size='13'>Kısayol tuşlarını (lider tablosu, yardım, market vb.) devre dışı bırakmak için bir ayar eklendi. \n\n<font size='11'>• <font size='13'>Artık <B><J>!cp [kullanıcıadı#etiket]</J></B> yazarak belirttiğiniz oyuncunun bulunduğu seviyeye ışınlanabilirsiniz.",
		
		-- Congratulation messages
		reached_level = "<d>Tebrikler! <vp>%s</vp>. seviyeyi tamamladınız. (<t>%ss</t>)",
		finished = "<d><o>%s</o> parkuru <vp>%s</vp> saniyede bitirdi, <fc>Tebrikler!",
		unlocked_power = "<ce><d>%s</d>, <vp>%s</vp> becerisini açtı.",
	
		-- Information messages
		mod_apps = "<j>Parkour moderatör alımları şimdi açık! Bu bağlantıyı kullanın: <rose>%s",
		staff_power = "<r>Parkour personelinin #parkour odalarının dışında hiçbir gücü <b>yoktur</b>.",
		donate = "<vp>Bu modül için bağış yapmak istiyorsanız <b>!donate</b> yazın!",
		paused_events = "<cep><b>[Dikkat!]</b> <n>Modül kritik seviyeye ulaştı ve durduruluyor.",
		resumed_events = "<n2>Modül devam ettirildi.",
		welcome = "<n><t>#parkour</t>! Odasına hoş geldiniz.",
		module_update = "<r><b>[Dikkat!]</b> <n> Modül <d>%02d:%02d</d> içinde güncellenecektir.",
		leaderboard_loaded = "<j>Lider tablosu güncellendi. Görüntülemek için klavyeden L tuşuna basın.",
		kill_minutes = "<R>Becerilerin %s dakika boyunca devre dışı bırakılmıştır.",
		permbanned = "<r>#Parkour'dan kalıcı olarak yasaklandınız.",
		tempbanned = "<r>#Parkour'dan %s dakika boyunca yasaklandınız.",
		forum_topic = "<rose>Modül hakkında daha fazla bilgi edinmek için bağlantıya gidin: %s",
		report = "<j>Bir oyuncuyu bildirmek mi istiyorsun? <t><b>/c Parkour#8558 .report KullanıcıAdı#Kod</b></t>",
		killed = "<v>[#] <r>#Parkour kurallarını ihlal ettiğiniz için becerilerinizi %s dakika süreyle kullanamazsınız. Devam eden kural ihlalleri uzaklaştırma ile sonuçlanacaktır. Kuralları incelemek için lütfen <b>H</b> tuşuna basın.",
		mapper_event = "<CE><B>Parkour harita yapma yarışması 2024:</B>\n<n>Yaratıcı haritalar yaparak <D>peynir <n>ve <pt>parkour coin <n>kazanma şansı yakalayın!\n<R>Harita gönderimleri <B>31 Ocak 2024</B>'e kadar açık.\n<PS>Daha fazla bilgi için, şu adresi ziyaret edin: %s",
	
		-- Easter Eggs
		easter_egg_0  = "<ch>Ve geri sayım başlıyor...",
		easter_egg_1  = "<ch>24 saatten daha az kaldı!",
		easter_egg_2  = "<ch>Vay be, bayağı erkencisin! Çok mu heyecanlandın?",
		easter_egg_3  = "<ch>Bir sürprizim var...",
		easter_egg_4  = "<ch>Birazdan ne olacak biliyor musun...?",
		easter_egg_5  = "<ch>Saat işliyor...",
		easter_egg_6  = "<ch>Sürpriz yakın!",
		easter_egg_7  = "<ch>Parti başlamak üzere...",
		easter_egg_8  = "<ch>Saatini kontrol et, zamanı geldi mi?",
		easter_egg_9  = "<ch>Dikkatli ol, zaman geçiyor...",
		easter_egg_10 = "<ch>Arkana yaslan ve rahatla, yarın vaktinde devam edecek!",
		easter_egg_11 = "<ch>Hadi artık yat, böylece zaman daha hızlı geçecek!",
		easter_egg_12 = "<ch>Sabır erdemdir",
		easter_egg_13 = "<ch>https://youtu.be/9jK-NcRmVcw",
		double_maps = "<bv>Çifte haritalar cumartesi (GMT+2) açılıyor ve tüm güçler parkur'un doğum haftası için açık!",
		double_maps_start = "<rose>ŞU AN PARKUR'UN DOĞUM GÜNÜ HAFTASI! Çifte haritalar ve bütün güçler açıldı. Bizimle oynadığın için teşekkürler!",
		double_maps_end = "<rose>Parkur'un doğum günü haftası bitti. Bizimle oynadığın için teşekkürler!",
	
		-- Records
		records_enabled = "<v>[#] <d>Rekor modu bu odada açık. İstatistikleriniz bu odada sayılmaz ve güçlerinizi kullanamazsınız!\nRekorlar hakkında daha fazla bilgi edinmek için <b>%s</b>  .",
		records_admin = "<v>[#] <d>Bu rekor odasının yöneticisisiniz. <b>!map</b>, <b>!setcp</b>, <b>!pw</b> ve <b>!time</b> komutlarını kullanabilirsiniz.",
		records_completed = "<v>[#] <d>Haritayı tamamladınız! Eğer tekrar yapmak istiyorsanız <b>!redo</b> yazabilirsiniz.",
		records_submit = "<v>[#] <d>Harika! Görünüşe göre bu haritayı en kısa sürede siz tamamladınız. Rekorunuzu göndermek isterseniz <b>!submit</b> yazın.",
		records_invalid_map = "<v>[#] <r>Görünüşe göre bu harita parkur biçiminde değil... Bu harita için rekor gönderemezsiniz!",
		records_not_fastest = "<v>[#] <r>Görünüşe göre odada bu haritayı en kısa sürede bitiren siz değilsiniz...",
		records_already_submitted = "<v>[#] <r>Bu harita için zaten bir rekor gönderdin!",
		records_submitted = "<v>[#] <d>Rekorunuz bu harita için <b>%s</b> olarak gönderildi.",
	
		-- Quests
		daily_q = "Günlük",
		weekly_q = "Haftalık",
		daily_quests = "<p align='center'><font size='20'><B><D>Günlük Görevler</D></B></font>",
		weekly_quests = "<p align='center'><font size='20'><B><D>Haftalık Görevler</D></B></font>",
		quest_1 = "<B><D>%s/%s</D></B> harita tamamlayın.",
		quest_2 = "<B><D>%s/%s</D></B> kontrol noktası (CP) toplayın.",
		quest_3 = "Herhangi bir haritayı <B><D>%s/%s</D></B> defa ilk sırada tamamlayın.", 
		quest_4 = "Bir haritayı <B><D>%s</D></B> saniyenin altında tamamlayın.",
		quest_5 = "<B><D>@%s</D></B> haritasını tamamlayın.",
		quest_6 = "<PT><b>%s</b></PT> becerisini <B><D>%s/%s</D></B> kere kullanın.", 
		next_reset = "<b><D>Sıfırlama:\n</b></D>%s",
		quest_completed = "<b><D>Tebrikler!</D></b> \nBir %s görev tamamladınız!",
		quest_reset = "<V>[#]</V> <O>%s görevleriniz sıfırlandı.</O>",
	
		-- Christmas
		find_gift1 = "<ch>Noel Baba'nın parkur partisi başladı! Haritada saklı hediyeyi bul ve sürprizini aç!",
		find_gift2 = "<ch>Zil sesleri çalıyor! Haritada sihirli bir yılbaşı hediyesi belirdi – bulmak için hazır mısın?",
		find_gift3 = "<ch>Ho, ho, ho! Noel Baba'nın küçük yardımcısı, haritada bulmanız için bir hediye bıraktı!",
		find_gift4 = "<ch>Yılbaşı coşkusu her tarafa yayıldı! Bu haritada saklı yılbaşı hediyesini bulun!",
		find_gift5 = "<ch>Mutlu Parkurlar! Elf'ler senin için bir hediye sakladı. Onu bulabilir misin?",
		found_gift1 = "<ch>Yaşasın! <J>%s</J> hediye kutusunu açtı ve içinde <J>%s</J> coin buldu!",
		found_gift2 = "<ch>Tebrikler, <J>%s</J>! Noel Baba'nın sihirli hediyesinden <J>%s</J> coin kazandın!",
		found_gift3 = "<J>%s</J> <ch>şanslı gününde! Yılbaşı hediyesi sayesinde <J>%s</J> coin daha zengin!",
		found_gift4 = "<ch>Tebrikler, <J>%s</J>! <J>%s</J> coin kazandın!",
		found_gift5 = "<ch>Muazzam! <J>%s</J>, Noel Baba'nın sürpriz hediyesini açtın ve <J>%s</J> coin kaptın!",
	
		-- Miscellaneous
		afk_popup = "\n<p align='center'><font size='30'><bv><b>AFK MODDASIN</b></bv>\nYENİDEN DOĞMAK İÇİN HAREKET ET. </font>\n\n<font size='30'><u><t>Hatırlatıcılar:</t></u></font>\n\n<font size='15'><r>Üzerinde kırmızı çizgi olan oyuncular yardım istemiyordur!\nParkurdaki diğer oyuncuları trollemek/engellemek YASAKTIR!<d>\n<cep><a href='event:discord'>Discord</a></cep>'umuza katıl!\nKodumuza katkıda bulunmak mı istiyorsun? <cep><a href='event:github'>Github depomuza</a></cep> bir bak\nSunacak iyi bir haritanız mı var? <cep><a href='event:map_submission'>Harita öneri başlığımıza</a></cep> gönderin!\nDaha fazla bilgi için<cep><a href='event:forum'>resmi başlığımıza</a></cep> bakın!\nBizi desteklemek için <cep><a href='event:donate'>bağış yap!</a></cep>",
		options = "<p align='center'><font size='20'>Parkur ayarları</font></p>\n\n<b>QWERTY</b> klavye kullan (Kapatıldığında <b>AZERTY</b> klavye kullanılır).\n\n<b>/mort</b>'un kısayolu <J><a href='event:keyboardmort:'><u><b>%s</b></u></a></J> tuşudur (<b>DELETE</b> tuşu olması için kapat.).\n\nBeceri bekleme sürelerini göster.\n\nBeceriler simgesini göster.\n\nYardım butonunu göster.\n\nHarita bitirme duyurularını göster.\n\nYardım istemiyorum simgesini göster.\n\nTüm arayüzler (liderlik tablosu, yardım, market vb.) için kısayol tuşlarını devre dışı bırak.",	
		cooldown = "<v>[#] <r>Bunu tekrar yapmadan önce birkaç saniye bekleyin",
		power_options = ("<font size='13' face='Lucida Console,Liberation Mono,Courier New'><b>QWERTY</b> Klavye" ..
						 "\n\nTamamlanan harita sayısını <b>gizle</b>" ..
						 "\n\n<b>Varsayılan tuşu</b> kullan"),
		unlock_power = ("<font size='5'>\n\n</font>Kilidi açmak için" ..
						"<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'><v>%s</v> harita tamamlayınız" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power = ("<font size='5'>\n\n</font>Yükseltmek için" ..
						"<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'><v>%s</v> harita tamamlayınız" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		unlock_power_rank = ("<font size='5'>\n\n</font>Kilidi açmak için" ..
						"<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>sıralamanız <v>%s</v> olmalıdır" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		upgrade_power_rank = ("<font size='5'>\n\n</font>Yükseltmek için" ..
						"<font size='13' face='Lucida Console,Liberation Mono,Courier New'><p align='center'>sıralamanız <v>%s</v> olmalıdır" ..
						"<font size='5'>\n\n</font><v>%s</v>"),
		maps_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
					 "<font size='5'>\n\n</font>Tamamlanmış Harita"),
		overall_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Genel Sıralamanız"),
		weekly_info = ("<p align='center'><font size='13' face='Lucida Console,Liberation Mono,Courier New'><b><v>%s</v></b>" ..
						"<font size='5'>\n\n</font>Bu Haftaki Sıralamanız"),
		badges = "<font size='14' face='Lucida Console,Liberation Mono,Courier New,Verdana'>Rozetler (%s): <a href='event:_help:badge'><j>[?]</j></a>",
		private_maps = "<bl>Bu oyuncunun tamamladığı harita sayısı özeldir. <a href='event:_help:private_maps'><j>[?]</j></a></bl>\n",
		profile = ("<font size='12' face='Lucida Console,Liberation Mono,Courier New,Verdana'>%s%s %s\n\n" ..
					"Genel skor tablosu konumu: <b><v>%s</v></b>\n\n" ..
					"Haftalık liderlik sıralaması: <b><v>%s</v></b>\n\n%s"),
		map_count = "Tamamlanan harita sayısı: <b><v>%s</v> / <a href='event:_help:yellow_maps'><j>%s</j></a> / <a href='event:_help:red_maps'><r>%s</r></a></b>",
		title_count = ("<b><j>«!»</j></b> Bitirilen haritalar: <b><a href='event:_help:map_count_title'><v>%s</v></a></b>\n\n" ..
					"<b><j>«!»</j></b> Toplanan kontrol noktaları: <b><a href='event:_help:checkpoint_count_title'><v>%s</v></a></b>"),
		help_badge = "Rozetler, bir oyuncunun elde edebileceği başarıdır. Açıklamalarını görmek için üzerlerine tıklayın.",
		help_private_maps = "Bu oyuncu tamamladığı harita sayısını herkese açık olarak paylaşmaktan hoşlanmıyor! İstersen sen de kendi profilinde bu bilgileri gizleyebilirsin.",
		help_yellow_maps = "Sarı haritalar son bir hafta içinde bitirdiklerinizdir.",
		help_red_maps = "Kırmızı haritalar son bir saat içinde bitirdiklerinizdir.",
		help_map_count_title = "Parkur haritalarını tamamlayarak <b>Transformice</b> ünvanları kazanabilirsin!",
		help_checkpoint_count_title = "Parkur haritalarında bütün kontrol noktalarını toplayarak <b>Transformice</b> ünvanları kazanabilirsin!",
		help_badge_1 = "Bu oyuncu geçmişte parkur ekibindeydi.",
		help_badge_2 = "Bu oyuncu genel liderlik tablosunun 1. sayfasında yer alıyor.",
		help_badge_3 = "Bu oyuncu genel liderlik tablosunun 2. sayfasında yer alıyor.",
		help_badge_4 = "Bu oyuncu genel liderlik tablosunun 3. sayfasında yer alıyor.",
		help_badge_5 = "Bu oyuncu genel liderlik tablosunun 4. sayfasında yer alıyor.",
		help_badge_6 = "Bu oyuncu genel liderlik tablosunun 5. sayfasında yer alıyor.",
		help_badge_7 = "Bu oyuncu haftalık liderlik tablosunun sonunda podyuma çıktı.",
		help_badge_8 = "Bu oyuncu bir saatte 30 harita tamamlamış!",
		help_badge_9 = "Bu oyuncu bir saatte 35 harita tamamlamış!",
		help_badge_10 = "Bu oyuncu bir saatte 40 harita tamamlamış!",
		help_badge_11 = "Bu oyuncu bir saatte 45 harita tamamlamış!",
		help_badge_12 = "Bu oyuncu bir saatte 50 harita tamamlamış!",
		help_badge_13 = "Bu oyuncu bir saatte 55 harita tamamlamış!",
		help_badge_14 = "Bu oyuncu, resmi parkour discord sunucusunda discord hesabını doğruladı (<b>!discord</b> yazın).",
		help_badge_15 = "Bu oyuncu 1 haritayı en kısa sürede tamamladı.",
		help_badge_16 = "Bu oyuncu 5 haritayı en kısa sürede tamamladı.",
		help_badge_17 = "Bu oyuncu 10 haritayı en kısa sürede tamamladı.",
		help_badge_18 = "Bu oyuncu 15 haritayı en kısa sürede tamamladı.",
		help_badge_19 = "Bu oyuncu 20 haritayı en kısa sürede tamamladı.",
		help_badge_20 = "Bu oyuncu 25 haritayı en kısa sürede tamamladı.",
		help_badge_21 = "Bu oyuncu 30 haritayı en kısa sürede tamamladı.",
		help_badge_22 = "Bu oyuncu 35 haritayı en kısa sürede tamamladı.",
		help_badge_23 = "Bu oyuncu 40 haritayı en kısa sürede tamamladı.",
		make_public = "herkese açık",
		make_private = "kişiye özel",
		moderators = "Moderatörler",
		mappers = "Haritacılar",
		managers = "Ekip Yöneticileri",
		administrators = "Yöneticiler",
		close = "Kapat",
		cant_load_bot_profile = "<v>[#] <r>#Parkour'un düzgün çalışması için dahil edildiğinden bu botun profilini göremezsiniz.",
		cant_load_profile = "<v>[#] <r>Oyuncu <b>%s</b> çevrimdışı gözüküyor veya böyle bir kullanıcı yok.",
		like_map = "Bu haritayı beğendin mi?",
		yes = "Evet",
		no = "Hayır",
		idk = "Bilmiyorum",
		vote_map = "<font color='#ffffff' size='13'><b>Bu haritayı beğendin mi? <font size='14'><a href='event:mapPollYes'><PT>Evet</a> <a href='event:mapPollidk'><N>Bilmiyorum</a> <a href='event:mapPollNo'><R>Hayır</a>",
		unknown = "Bilinmiyor",
		powers = "Beceriler",
		press = "<vp>%s Tuşuna Bas",
		click = "<vp>Sol tık",
		ranking_pos = "Sıralama #%s",
		completed_maps = "<p align='center'><BV><B>Tamamlanan haritalar: %s</B></p></BV>",
		leaderboard = "Lider sıralaması",
		position = "<V><p align=\"center\">Sıralama",
		username = "<V><p align=\"center\">Kullanıcı adı",
		community = "<V><p align=\"center\">Topluluk",
		completed = "<V><p align=\"center\">Tamamlanan haritalar",
		overall_lb = "Genel",
		weekly_lb = "Haftalık",
		new_lang = "<v>[#] <d>Diliniz Türkçe olarak ayarlandı",
		room = "Oda",
		time = "Süre",
		buy = "Satın Al",
		equip = "Kullan",
		equipped = "<font size = '10'>Kullanıldı</font>",
		saving = "<p align='right'>Kaydediliyor...",
	
		-- Power names
		balloon = "Balon",
		masterBalloon = "Balon II",
		bubble = "Balon III",
		fly = "Uçma",
		snowball = "Kar Topu",
		speed = "Hız",
		teleport = "Işınlanma",
		smallbox = "Küçük Kutu",
		cloud = "Bulut",
		rip = "Mezar Taşı",
		choco = "Çikolata Tahta",
		bigBox = "Büyük Kutu",
		trampoline = "Trambolin",
		toilet = "Tuvalet",
		pig = "Domuzcuk",
		sink = "Lavabo",
		bathtub = "Küvet",
		campfire = "Kamp Ateşi",
		chair = "Sandalye",
		link = "Ruh ikizi",
	}
	--[[ End of file translations/parkour/tr.lua ]]--
	--[[ End of directory translations/parkour ]]--
	--[[ File modes/parkour/timers.lua ]]--
	local timers = {}
	local aliveTimers = false
	
	local function addNewTimer(delay, fnc, arg1, arg2, arg3, arg4, arg5)
		aliveTimers = true
		local list = timers[delay]
		if list then
			list._count = list._count + 1
			list[list._count] = {os.time() + delay, fnc, arg1, arg2, arg3, arg4, arg5}
		else
			timers[delay] = {
				_count = 1,
				_pointer = 1,
				[1] = {os.time() + delay, fnc, arg1, arg2, arg3, arg4, arg5}
			}
		end
	end
	
	onEvent("Loop", function()
		if aliveTimers then
			aliveTimers = false
			local now = os.time()
			local timer, newPointer
			for delay, list in next, timers do
				newPointer = list._pointer
				for index = newPointer, list._count do
					timer = list[index]
	
					if now >= timer[1] then
						timer[2](timer[3], timer[4], timer[5], timer[6], timer[7])
						newPointer = index + 1
					else
						break
					end
				end
				list._pointer = newPointer
				if newPointer <= list._count then
					aliveTimers = true
				end
			end
		end
	end)
	
	onEvent("NewGame", function()
		if aliveTimers then
			local timer, count
			for delay, list in next, timers do
				count = list._count
				for index = list._pointer, count do
					timer = list[index]
					timer[2](timer[3], timer[4], timer[5], timer[6], timer[7])
				end
	
				if list._count > count then
					for index = count + 1, list._count do
						timer = list[index]
						timer[2](timer[3], timer[4], timer[5], timer[6], timer[7])
					end
				end
			end
			timers = {}
			aliveTimers = false
		end
	end)
	--[[ End of file modes/parkour/timers.lua ]]--
	--[[ File modes/parkour/maps.lua ]]--
	--[[
		The map quantity is HUGE (over 300). We need a system that:
		- Picks a random map quickly
		- Does NOT repeat maps unless the whole rotation has played
		- Is able to switch the map list quickly (add/remove maps)
	
		This system uses sections:
		Every section is a pointer to the index of a map, depending
		on the maps per section quantity. If it is 10, section 0
		points to the maps 1-10, section 1 to the maps 11-20 and so
		on.
	
		The sections do NOT point to the map, but to the index.
		This way we can update the maps easily.
	
		We shuffle these sections when they're calculated, and keep
		a pointer to the next section, which we increase every time
		we want to select a map. Every section has an internal
		counter too, and it works the same way.
	
		When a section is selected, if the maps it contains weren't
		shuffled, they will be shuffled at that moment. When all
		the maps are played, the sections will reshuffle and their
		maps will be flagged as unshuffled.
		This way we can do small shuffles without the need of
		shuffling a big array with a lot of elements. Due to the
		runtime limitations in transformice lua, this is way better
	]]
	
	local global_poll = false
	local first_data_load = true
	local maps_per_section = math.random(10, 20)
	local maps = {
		polls = {_count = 0},
	
		sections_high = {
			_count = 0,
			_pointer = 0,
			_map_pointer = 1
		},
		sections_low = {
			_count = 0,
			_pointer = 0,
			_map_pointer = 1
		},
	
		list_high = {7171137},
		high_count = 1,
	
		list_low = {7171137},
		low_count = 1
	}
	local is_invalid = false
	local count_stats = true
	local map_change_cd = 0
	
	current_map = nil
	
	local levels
	local perms
	local review_mode
	local records_admins = string.find(room.lowerName, "records", 1, true) and {}
	if records_admins and submode == "smol" then
		records_admins = nil
	end
	
	if records_admins then
		tfm.exec.playerVictory = function(name)
			tfm.exec.removeCheese(name)
			eventPlayerWon(name)
		end
	end
	
	local function selectMap(sections, list, count)
		if sections._map_pointer > maps_per_section then
			-- All maps played, reset sections
			sections._map_pointer = 1
			sections._pointer = 0
			sections._count = 0
		end
	
		if sections._count == 0 then
			-- No sections, calculate them
			local quantity = math.ceil(count / maps_per_section)
	
			local section, start, limit
			for i = 1, quantity do
				start = maps_per_section * (i - 1)
				limit = math.min(maps_per_section * i, count)
	
				section = {}
				for j = 1, limit - start do
					section[j] = j + start
				end
	
				sections[i] = section
			end
	
			-- shuffle sections
			local current, swap
			for index = 1, quantity do
				swap = math.random(index, quantity)
	
				current = sections[index]
				sections[index] = sections[swap]
				sections[swap] = current
			end
	
			sections._count = quantity
		end
	
		-- make pointer go through 1 to _count
		-- 0 -> 1, _count -> 1, x -> x + 1
		sections._pointer = sections._pointer % sections._count + 1
	
		local section = sections[sections._pointer]
		if not section._count then -- the section has not been shuffled!
			section._count = #section
	
			local current, swap
			for index = 1, section._count do
				swap = math.random(index, section._count)
	
				current = section[index]
				section[index] = section[swap]
				section[swap] = current
			end
	
		elseif (section._pointer == sections._count -- is it the las section?
				and section._count < maps_per_section -- does it have less maps than a regular section?
				and sections._map_pointer > section._count) then -- have all the maps from this section been played?
			sections._map_pointer = sections._map_pointer + 1 -- increase map pointer
			return selectMap(sections, list, count) -- and select another map
		end
	
		local map = section[sections._map_pointer]
	
		if sections._pointer == sections._count then
			-- if it is the last section, the next map pointer has to be increased
			sections._map_pointer = sections._map_pointer + 1
		end
	
		return list[map]
	end
	
	local function newMap()
		count_stats = not review_mode
		map_change_cd = os.time() + 20000
	
		local map
		if math.random((maps.low_count + maps.high_count * 2) * 1000000) <= (maps.low_count * 1000000) then -- 1/3
			map = selectMap(maps.sections_low, maps.list_low, maps.low_count)
		else
			map = selectMap(maps.sections_high, maps.list_high, maps.high_count)
		end
		current_map = map
		tfm.exec.newGame(map, not records_admins and math.random(3000000) <= 1000000)
	end
	
	local function invalidMap(arg)
		levels = nil
		is_invalid = os.time() + 3000
		tfm.exec.chatMessage("<r>" .. room.currentMap)
		translatedChatMessage("corrupt_map")
		translatedChatMessage("corrupt_map_" .. arg)
	end
	
	local function getTagProperties(tag)
		local properties = {}
		for name, value in string.gmatch(tag, '(%S+)%s*=%s*"([^"]*)"') do
			properties[name] = tonumber(value) or value
		end
		return properties
	end
	
	onEvent("GameDataLoaded", function(data)
		if data.maps then
			maps.list_high = data.maps
			maps.high_count = #data.maps
	
			if maps.high_count == 0 then
				maps.list_high = {7171137}
				maps.high_count = 1
			end
	
			local sections = maps.sections_high
			if sections._count ~= 0 then
				if sections._count ~= math.ceil(maps.high_count / maps_per_section) then
					sections._map_pointer = maps_per_section + 1 -- reset everything
	
				elseif sections._count == needed then
					local section = sections[sections._count]
					local modulo = maps.high_count % maps_per_section
	
					if modulo == 0 then
						modulo = maps_per_section
					end
	
					if section._count ~= 0 and section._count ~= modulo then
						sections._map_pointer = maps_per_section + 1
					end
				end
			end
	
			if first_data_load then
				newMap()
				first_data_load = false
			end
		end
	
		if data.map_polls then
			maps.polls = data.map_polls
	
			-- even if we are modifying the file object, internally it's an array
			-- so _count will be ignored
			maps.polls._count = #data.map_polls
		end
	
		if data.lowmaps then
			maps.list_low = data.lowmaps
			maps.low_count = #data.lowmaps
	
			if maps.low_count == 0 then
				maps.list_low = {7171137}
				maps.low_count = 1
			end
	
			local sections = maps.sections_low
			if sections._count ~= 0 then
				if sections._count ~= math.ceil(maps.low_count / maps_per_section) then
					sections._map_pointer = maps_per_section + 1 -- reset everything
	
				elseif sections._count == needed then
					local section = sections[sections._count]
					local modulo = maps.low_count % maps_per_section
	
					if modulo == 0 then
						modulo = maps_per_section
					end
	
					if section._count ~= 0 and section._count ~= modulo then
						sections._map_pointer = maps_per_section + 1
					end
				end
			end
		end
	end)
	
	onEvent("NewGame", function()
		-- When a map is loaded, this function reads the XML to know where the
		-- checkpoints are
	
		levels = {}
		if not room.xmlMapInfo or tonumber(room.currentMap) or tonumber(room.xmlMapInfo.mapCode) ~= tonumber(tostring(room.currentMap):sub(2)) then
			if not room.xmlMapInfo then
				return
			end
			return invalidMap("vanilla")
		end
		local xml = room.xmlMapInfo.xml
	
		local hole = string.match(xml, '<T%s+.-/>')
		if hole then
			return invalidMap("hole")
		end
	
		local count = 1
		local mouse_start = string.match(xml, '<DS%s+(.-)%s+/>')
	
		if not mouse_start then
			return invalidMap("mouse_start")
		end
	
		local properties = getTagProperties(mouse_start)
		levels[count] = {
			x = properties.X, y = properties.Y,
			size = tonumber(properties.size) or 1
		}
	
		for tag in string.gmatch(xml, '<O%s+(.-)%s+/>') do
			properties = getTagProperties(tag)
	
			if properties.C == 22 then
				count = count + 1
				levels[count] = {
					x = properties.X, y = properties.Y,
					stop = properties.stop, size = tonumber(properties.size)
				}
			end
		end
	
		local chair = false
		for tag in string.gmatch(xml, '<P%s+(.-)%s+/>') do
			properties = getTagProperties(tag)
	
			if properties.T == 19 and properties.C == "329cd2" then
				chair = true
				count = count + 1
				levels[count] = {
					x = properties.X, y = properties.Y - 40,
					size = 1
				}
				break
			end
		end
	
		if submode == "smol" then
			local level
			for i = 1, count do
				level = levels[i]
				if level.size then
					level.size = level.size / 2
				else
					level.size = levels[i - 1].size
				end
			end
		else
			local level
			for i = 1, count do
				level = levels[i]
				if not level.size then
					level.size = levels[i - 1].size
				end
			end
		end
	
		if room.xmlMapInfo.author ~= "#Module" then
			if not chair or count < 3 then -- start, at least one nail and end chair
				return invalidMap(not chair and "needing_chair" or "missing_checkpoints")
			end
		end
	
		if room.mirroredMap then
			for index = 1, count do
				levels[index].x = 1600 - levels[index].x
			end
		end
	
		tfm.exec.setGameTime(1080)
	
		if (count_stats
			and not is_tribe
			and not records_admins
			and not review_mode
			and room.xmlMapInfo.permCode ~= 41
			and room.xmlMapInfo.author ~= "#Module") then
			invalidMap("no_perm")
			return
		end
		is_invalid = false
	
		global_poll = false
		local map = tonumber((string.gsub(room.currentMap, "@", "", 1)))
		for index = 1, maps.polls._count do
			if maps.polls[index] == map then
				global_poll = true
				-- poll starts in modes/parkour/ui.lua
				break
			end
		end
	end)
	
	onEvent("Loop", function(elapsed, remaining)
		if review_mode or records_admins then return end
	
		-- Changes the map when needed
		if (is_invalid and os.time() >= is_invalid) or remaining < 500 then
			newMap()
		end
	end)
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		if cmd == "map" then
			local records_cond = records_admins and records_admins[player]
			local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
			local normal_cond = perms[player] and perms[player].change_map
			if not records_cond and not tribe_cond and not normal_cond then return end
	
			if quantity > 0 then
				if not records_cond and not tribe_cond and not perms[player].load_custom_map then
					return tfm.exec.chatMessage("<v>[#] <r>You can't load a custom map.", player)
				end
	
				count_stats = false
				local map = tonumber(args[1]) or tonumber(string.sub(args[1], 2))
				if not map or map < 1000 then
					translatedChatMessage("invalid_syntax", player)
					return
				end
				current_map = args[1]
				tfm.exec.newGame(args[1], args[2] and string.lower(args[2]) == "flipped" and not records_admins)
			elseif os.time() < map_change_cd and not review_mode then
				tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", player)
			else
				newMap()
			end
	
			if not records_cond and not tribe_cond and normal_cond then
				-- logged when using staff powers
				if review_mode and perms[player].enable_review then
					-- legitimate review mode
					return
				end
				inGameLogCommand(player, "map", args)
				logCommand(player, "map", math.min(quantity, 2), args)
			end
		end
	end)
	
	onEvent("GameStart", function()
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disableAutoTimeLeft(true)
		tfm.exec.setAutoMapFlipMode(false)
	
		system.disableChatCommandDisplay("map")
	end)
	--[[ End of file modes/parkour/maps.lua ]]--
	--[[ File modes/parkour/join-system.lua ]]--
	local room_max_players = 12
	
	onEvent("PacketReceived", function(channel, id, packet)
		if channel ~= "bots" then return end
	
		if id == packets.bots.join then
			if packet == room.shortName then
				tfm.exec.setRoomMaxPlayers(room_max_players + 10)
				addNewTimer(15000, tfm.exec.setRoomMaxPlayers, room_max_players)
			end
		elseif id == packets.bots.change_lock then
			local roomName, limit = string.match(packet, "^([^\000]+)\000([^\000]+)$")
			if roomName == room.shortName then
				limit = tonumber(limit)
				if not limit then return end
				tfm.exec.setRoomMaxPlayers(limit)
			end
		end
	end)
	--[[ End of file modes/parkour/join-system.lua ]]--
	--[[ File modes/parkour/game.lua ]]--
	local min_save = 4
	
	local check_position = 6
	local player_count = 0
	local victory_count = 0
	local less_time = false
	local victory = {_last_level = {}}
	local bans = {}
	local in_room = {}
	local online = {}
	local hidden = {}
	local players_level = {}
	local times = {
		map_start = 0,
		generated = {},
		checkpoint = {},
		movement = {}
	}
	local spec_mode = {}
	local checkpoints = {}
	local players_file
	review_mode = false
	local cp_available = {}
	local map_name
	local map_gravity = 10
	
	local gifts = {}
	local gift_conditions = {_complete = math.random(4, 8), _completed = 0, _ts = os.time() + math.random(15, 30) * 60 * 1000}
	local save_queue = { __first = "", __last = ""}
	local saveQueueCounter = 0
	
	local checkpoint_info = {
		version = 1, -- 0 = old, 1 = new
		radius = 15 ^ 2, -- radius of 15px
		next_version = 1
	}
	local AfkInterface
	local checkCooldown
	local savePlayerData
	local ranks
	local bindKeyboard
	
	local lastOpenedMap
	local lastPlayerLeft
	
	-- anniversary on march 6
	local is_anniversary, is_before_anniversary, is_after_anniversary
	do
		local now = os.time()
		local date_current = os.date("*t", now / 1000)
	
		local function anniversaryTime(day)
			return os.time({ year=date_current.year, month=3, day=6+day })
		end
	
		local date_anniversary = os.date("*t", anniversaryTime(0) / 1000)
		local wday = date_anniversary.wday - 1
	
		if wday == 0 then
			wday = 7
		end
	
		local week_before = anniversaryTime(1 - wday - 7)
		local anniversary_week = anniversaryTime(1 - wday)
		local week_after = anniversaryTime(7 + 1 - wday)
		local week_after_end = anniversaryTime(7 + 1 - wday + 3)
	
		is_before_anniversary = now >= week_before and now < anniversary_week
		is_anniversary = now >= anniversary_week and now < week_after
		is_after_anniversary = now >= week_after and now < week_after_end
	end
	
	do
		local newGame = tfm.exec.newGame
		tfm.exec.newGame = function(code, reversed)
			code = tostring(code)
			lastOpenedMap = code:sub(1, 1) == '@' and code:sub(2) or code
			newGame(code, reversed)
		end
	end
	
	local changePlayerSize = function(name, size)
		size = tonumber(size)
		if name and size and victory[name] and size > 1 then
			size = 1
		end
		return tfm.exec.changePlayerSize(name, size)
	end
	
	local function addCheckpointImage(player, x, y)
		if not x then
			local level = levels[ players_level[player] + 1 ]
			if not level then return end
			x, y = level.x, level.y
		end
	
		local data = room.playerList[player]
		local img
		if data and data.spouseId then
			img = "17797d878fa.png" -- soulmate
		else
			img = "17797d860b6.png" -- no soulmate
		end
	
		checkpoints[player] = tfm.exec.addImage(img, "!1", x - 15, y - 15, player)
	end
	
	local function showStats()
		-- Shows if stats count or not
	
		if not map_name then return end
	
		local text = (count_stats and
			room.uniquePlayers >= min_save and
			player_count >= min_save and
			not records_admins and
			not is_tribe and
			not review_mode) and "<v>Stats count" or "<r>Stats don't count"
	
		ui.setMapName(string.format(
			"%s<g>   |   %s",
			map_name, text
		))
	end
	
	local function enableSpecMode(player, enable)
		if spec_mode[player] and enable then return end
		if not spec_mode[player] and not enable then return end
	
		if enable then
			spec_mode[player] = true
			tfm.exec.killPlayer(player)
	
			player_count = player_count - 1
			if victory[player] then
				victory_count = victory_count - 1
			elseif player_count == victory_count and not less_time then
				tfm.exec.setGameTime(5)
				less_time = true
			end
		else
			spec_mode[player] = nil
	
			if (not levels) or (not players_level[player]) then return end
	
			local level = levels[ players_level[player] ]
	
			tfm.exec.respawnPlayer(player)
			tfm.exec.movePlayer(player, level.x, level.y)
	
			player_count = player_count + 1
			if victory[player] then
				victory_count = victory_count + 1
			end
		end
	
		showStats()
	end
	
	local function queueForSave(player)
		if save_queue[player] then return end
	
		if save_queue.__first == "" then
			save_queue[player] = ""
			save_queue.__first = player
			save_queue.__last = player
		else
			save_queue[player] = ""
			save_queue[save_queue.__last] = player
			save_queue.__last = player
		end
	
		local savingMessage = translatedMessage("saving", player)
		ui.addTextArea(987, savingMessage, player, 670, 380, 120, 20, nil, 0, 0, true)
	end
	
	local function saveFromQueue()
		if not save_queue then return end
		if save_queue.__first == "" then return end
	
		savePlayerData(save_queue.__first)
		ui.removeTextArea(987, save_queue.__first)
	
		local oldfirst = save_queue.__first
	
		save_queue.__first = save_queue[save_queue.__first]
	
		save_queue[oldfirst] = nil
	end
	
	local function addRandomGift()
		local gift_x = math.random(50, 1580) 
		local gift_y = math.random(50, 700)
		local msg = math.random(1, 5)
	
		for player in next, in_room do
			gifts[player] = tfm.exec.addImage("18c73e40d6d.png", "!1", gift_x - 15 , gift_y - 20, player)
			tfm.exec.addBonus(0, gift_x, gift_y, 999, 0, false, player)
			translatedChatMessage("find_gift" .. msg, player)
		end
	
		gift_conditions = {_complete = math.random(4, 8), _completed = 0, _ts = os.time() + math.random(15, 30) * 60 * 1000}
	end
	
	local function giftCollected(player)
		if not players_file[player] then return end
		if not gifts[player] then return end
	
		local prizes = {10, 50, 100, 250, 500, 750, 1000}
		local chances = {8600, 1000, 200, 139, 50, 10, 1}
	
		local randomValue = math.random(0, 100 * 100)
	
		local totalChance = 0
		local prize = 0
	    for i, chance in ipairs(chances) do
	        totalChance = totalChance + chance
	        if randomValue <= totalChance then
	            prize = prizes[i]
				break
	        end
	    end
		
		local msg = math.random(1, 5)
		if prize > 50 then
			for p in next, in_room do
				translatedChatMessage("found_gift" .. msg, p, player, prize)
			end
		else
			translatedChatMessage("found_gift" .. msg, player, player, prize)
		end
	
		players_file[player].coins = players_file[player].coins + prize
		queueForSave(player)
	
		tfm.exec.removeBonus(999, player)
		tfm.exec.removeImage(gifts[player])
		gifts[player] = nil
	end
	
	local function checkBan(player, data, id)
		if not id then
			id = room.playerList[player]
			if not id or not in_room[player] then
				return
			end
			id = id.id
		end
	
		if data.banned and (data.banned == 2 or os.time() < data.banned) then
			bans[id] = data.lastsanction
	
			enableSpecMode(player, true)
	
			if data.banned == 2 then
				translatedChatMessage("permbanned", player)
			else
				local minutes = math.floor((data.banned - os.time()) / 1000 / 60)
				translatedChatMessage("tempbanned", player, minutes)
			end
		elseif bans[id] then
			if not data.lastsanction or bans[id] > data.lastsanction then
				enableSpecMode(player, true)
			else
				bans[id] = false
				enableSpecMode(player, false)
			end
		elseif id == 0 then
			enableSpecMode(player, true)
		end
	end
	
	local band, rshift = bit32.band, bit32.rshift
	local function checkTitleAndNextFieldValue(player, title, sumValue, _playerData, _playerID)
		local field = _playerData[title.field]
	
		if field < title.requirement then
			local newValue = field + sumValue
	
			if newValue >= title.requirement then
				system.giveEventGift(player, title.code)
	
				sendPacket("common", 9, _playerID .. "\000" .. player .. "\000" .. title.code)
			end
	
			return newValue
		else
			return field
		end
	end
	
	onEvent("NewPlayer", function(player)
		ui.removeTextArea(987, nil)
		spec_mode[player] = nil
		in_room[player] = true
	
		player_count = player_count + 1
	
		if player_count > room.moduleMaxPlayers then
			sendPacket(
				"common",
				packets.rooms.lock_fixed,
				room.shortName .. "\000" ..
				player_count .. "\000" ..
				room.moduleMaxPlayers .. "\000" ..
				(lastPlayerLeft or "-") .. "\000" ..
				player
			)
			tfm.exec.setRoomMaxPlayers(room.moduleMaxPlayers)
		end
	
		cp_available[player] = 0
		times.movement[player] = os.time()
	
		for key = 0, 3 do
			bindKeyboard(player, key, true, true)
			if key == 3 then
				bindKeyboard(player, key, false, true)
			end
		end
	
		if levels then
			tfm.exec.respawnPlayer(player)
	
			if victory[player] then
				victory_count = victory_count + 1
			end
	
			local level
			if players_level[player] then
				level = levels[ players_level[player] ]
				if level then
					tfm.exec.movePlayer(player, level.x, level.y)
				end
			else
				level = levels[1]
				players_level[player] = 1
				tfm.exec.movePlayer(player, levels[1].x, levels[1].y)
			end
	
			changePlayerSize(player, level.size)
			tfm.exec.setPlayerScore(player, players_level[player], false)
	
			local next_level = levels[ players_level[player] + 1 ]
	
			if next_level then
				addCheckpointImage(player, next_level.x, next_level.y)
				if checkpoint_info.version == 1 then
					tfm.exec.addBonus(0, next_level.x, next_level.y, players_level[player] + 1, 0, false, player)
				end
			end
		end
	
		if records_admins then
			bindKeyboard(player, 66, true, true) -- B key
		end
	
		showStats()
	end)
	
	onEvent("Keyboard", function(player, key)
		if key >= 0 and key <= 2 then
			local now = os.time()
			if players_level[player] == 1 and not times.generated[player] then
				times.generated[player] = now
				times.checkpoint[player] = now
				if records_admins then
					tfm.exec.freezePlayer(player, false)
				end
			end
			times.movement[player] = now
	
			if AfkInterface.open[player] then
				enableSpecMode(player, false)
				AfkInterface:remove(player)
			end
	
		elseif records_admins and key == 66 then
			if checkCooldown(player, "redo_key", 500) then
				eventParsedChatCommand(player, "redo")
			end
		end
	end)
	
	onEvent("PlayerLeft", function(player)
		players_file[player] = nil
		in_room[player] = nil
		times.movement[player] = nil
		lastPlayerLeft = player
	
		if spec_mode[player] then return end
	
		player_count = player_count - 1
	
		if victory[player] then
			victory_count = victory_count - 1
		elseif player_count == victory_count and not less_time then
			tfm.exec.setGameTime(5)
			less_time = true
		end
	
		if not AfkInterface.open[player] then
			local required = 4 - player_count
	
			if required > 0 then
				local to_remove = {}
	
				for name in next, AfkInterface.open do
					enableSpecMode(name, false)
					to_remove[required] = name
					required = required - 1
					if required == 0 then break end
				end
	
				for name = 1, #to_remove do
					AfkInterface:remove(name)
				end
			end
		end
		showStats()
	end)
	
	onEvent("PlayerDied", function(player)
		local info = room.playerList[player]
	
		if not info then return end
		if info.id == 0 or player:sub(1, 1) == "*" then return end
		if bans[info.id] then return end
		if (not levels) or (not players_level[player]) then return end
	
		local level = levels[ players_level[player] ]
		tfm.exec.linkMice(player, player, false)
	
		if not spec_mode[player] then
			tfm.exec.respawnPlayer(player)
			if level then
				tfm.exec.movePlayer(player, level.x, level.y)
			end
		end
	end)
	
	onEvent("PlayerWon", function(player)
		if not room.playerList[player] then return end
		if bans[ room.playerList[player].id ] then return end
		if victory[player] then return end
	
		victory_count = victory_count + 1
		victory._last_level[player] = false
		tfm.exec.linkMice(player, player, false)
	
		if victory_count == player_count and not less_time then
			tfm.exec.setGameTime(5)
			less_time = true
			return
		end
	end)
	
	onEvent("PlayerRespawn", function(player)
		cp_available[player] = os.time() + 750
	
		if not room.playerList[player] then return end
		if bans[room.playerList[player].id] then return tfm.exec.killPlayer(player) end
		if (not levels) or (not players_level[player]) then return end
	
		if (players_level[player] == 1
			and not times.generated[player]
			and records_admins) then
			tfm.exec.freezePlayer(player, true)
		end
		
		tfm.exec.linkMice(player, player, false)
	
		local level = levels[ players_level[player] ]
		if not level then return end
		tfm.exec.movePlayer(player, level.x, level.y)
	end)
	
	onEvent("NewGame", function()
		roomleaderboard = {}
		check_position = 6
		victory_count = 0
		victory = {_last_level = {}}
		players_level = {}
		times.generated = {}
		times.map_start = os.time()
		checkpoint_info.version = checkpoint_info.next_version
	
	  local info = room.xmlMapInfo
	  local xml = info and info.xml
	  local code = room.currentMap
	  local smolified = info and info.author == '#Module'
		local original_author = xml:match('%s+PKAUTHOR="(.-)"%s*')
	
		if original_author and original_author ~= '#Module' then
			info.author = original_author:gsub('<', ''):gsub('&', '')
		end
	
	  code = code:sub(1, 1) == '@' and code:sub(2) or code
	
	  -- xmlMapInfo doesn't reset if the map doesn't have an xml
	  if xml and tostring(info.mapCode) == code and not smolified then
			map_name = ("<J>%s <BL>- %s"):format(info.author, room.currentMap)
			map_gravity = tonumber(xml:match('G=".-,(.-)"')) or 10
		end
	
		-- prevent /np abuse
		if code ~= lastOpenedMap then
			count_stats = false
		end
	
		if submode == "smol" then
			count_stats = false
		end
	
		if records_admins then
			less_time = true
		else
			less_time = false
		end
	
		local start_x, start_y
		if levels then
			start_x, start_y = levels[2].x, levels[2].y
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, start_x, start_y, 2, 0, false)
			end
	
			for player in next, in_room do
				if checkpoints[player] then
					tfm.exec.removeImage(checkpoints[player])
				end
				addCheckpointImage(player, start_x, start_y)
			end
	
			local size = levels[1].size
			for player in next, in_room do
				players_level[player] = 1
				changePlayerSize(player, size)
				tfm.exec.setPlayerScore(player, 1, false)
				tfm.exec.linkMice(player, player, false)
			end
	
			if records_admins then
				for player in next, in_room do
					tfm.exec.freezePlayer(player, true)
				end
			end
		end
	
		for player in next, spec_mode do
			tfm.exec.killPlayer(player)
		end
		showStats()
	
		-- if (count_stats and
		-- 	room.uniquePlayers >= min_save and
		-- 	player_count >= min_save and
		-- 	not records_admins and
		-- 	not is_tribe and
		-- 	not review_mode) then
				
		-- 	gift_conditions._completed = gift_conditions._completed + 1
			
		-- 	if gift_conditions._completed >= gift_conditions._complete and os.time() > gift_conditions._ts then
		-- 		addRandomGift()
		-- 	end
		-- end
	
	end)
	
	onEvent("Loop", function()
		if save_queue.__first ~= "" then 
			saveQueueCounter = saveQueueCounter + 1
			if saveQueueCounter == 8 then
				saveFromQueue()
				saveQueueCounter = 0
			end
		end
	
		if not levels then return end
	
		if check_position > 0 then
			check_position = check_position - 1
		else
			for player, to_give in next, victory._last_level do
				if not victory[player] and to_give then
					eventPlayerWon(player)
				end
			end
	
			local now = os.time()
			local player
			for name in next, in_room do
				player = room.playerList[name]
				if player then
					if spec_mode[name] or player.id == 0 or name:sub(1, 1) == "*" or bans[player.id] then
						tfm.exec.killPlayer(name)
					elseif (player_count > 4
							and not records_admins
							and not review_mode
							and not victory[name]
							and now >= times.movement[name] + 120000) then -- 2 mins afk
						enableSpecMode(name, true)
						AfkInterface:show(name)
					end
				end
			end
	
			if checkpoint_info.version ~= 0 then return end
	
			local last_level = #levels
			local level_id, next_level, player
			local taken
			for name in next, in_room do
				player = room.playerList[name]
				if player and now >= cp_available[name] then
					level_id = (players_level[name] or 1) + 1
					next_level = levels[level_id]
	
					if next_level then
						if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_info.radius then
							taken = (now - (times.checkpoint[player] or times.map_start)) / 1000
							times.checkpoint[player] = now
							players_level[name] = level_id
	
							if next_level.size ~= levels[ level_id - 1 ].size then
								-- need to change the size
								changePlayerSize(name, next_level.size)
							end
	
							if not victory[name] then
								tfm.exec.setPlayerScore(name, level_id, false)
							end
							tfm.exec.removeImage(checkpoints[name])
							
							tfm.exec.linkMice(player, player, false)
	
							if level_id == last_level then
								translatedChatMessage("reached_level", name, level_id-1, taken)
								if not victory[name] then -- !cp
									victory._last_level[name] = true
									tfm.exec.giveCheese(name)
									tfm.exec.playerVictory(name)
									tfm.exec.respawnPlayer(name)
									tfm.exec.movePlayer(name, next_level.x, next_level.y)
								end
							else
								translatedChatMessage("reached_level", name, level_id-1, taken)
								addCheckpointImage(name, levels[level_id + 1].x, levels[level_id + 1].y)
							end
						end
					end
				end
			end
		end
	end)
	
	onEvent("PlayerBonusGrabbed", function(player, bonus)
		if checkpoint_info.version ~= 1 then return end
		if bonus == 999 then return giftCollected(player) end
		if not levels then return end
		local level = levels[bonus]
		if not level then return end
		if not players_level[player] then return end
		if bonus ~= players_level[player] + 1 then return end
		if os.time() < cp_available[player] then return tfm.exec.addBonus(0, level.x, level.y, bonus, 0, false, player) end
	
		local taken = (os.time() - (times.checkpoint[player] or times.map_start)) / 1000
		times.checkpoint[player] = os.time()
		players_level[player] = bonus
	
		if level.size ~= levels[ bonus - 1 ].size then
			-- need to change the size
			changePlayerSize(player, level.size)
		end
	
		if not victory[player] then
			tfm.exec.setPlayerScore(player, bonus, false)
		end
		tfm.exec.removeImage(checkpoints[player])
		tfm.exec.linkMice(player, player, false)
	
		if bonus == #levels then
			translatedChatMessage("reached_level", player, bonus-1, taken)
			if not victory[player] then -- !cp
				victory._last_level[player] = true
				tfm.exec.giveCheese(player)
				tfm.exec.playerVictory(player)
				tfm.exec.respawnPlayer(player)
				tfm.exec.movePlayer(player, level.x, level.y)
				return
			end
		else
			translatedChatMessage("reached_level", player, bonus-1, taken)
	
			local next_level = levels[bonus + 1]
			addCheckpointImage(player, next_level.x, next_level.y)
	
			tfm.exec.addBonus(0, next_level.x, next_level.y, bonus + 1, 0, false, player)
		end
	
		if level.stop then
			tfm.exec.movePlayer(player, 0, 0, true, 1, 1, false)
			tfm.exec.killPlayer(player)
		end
	end)
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		if cmd == "review" then
			local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
			local normal_cond = (perms[player] and
								perms[player].enable_review and
								not records_admins and
	
								(string.find(room.lowerName, "review") or
								ranks.admin[player]))
			if not tribe_cond and not normal_cond then
				return tfm.exec.chatMessage("<v>[#] <r>You can't toggle review mode in this room.", player)
			end
	
			if review_mode and disable_powers then
				disable_powers = false
				tfm.exec.chatMessage("<v>[#] <d>Powers enabled by " .. player .. ".")
			end
	
			count_stats = false
			review_mode = not review_mode
			if review_mode then
				tfm.exec.chatMessage("<v>[#] <d>Review mode enabled by " .. player .. ".")
			else
				tfm.exec.chatMessage("<v>[#] <d>Review mode disabled by " .. player .. ".")
			end
			showStats()
	
		elseif cmd == "cp" then
			if not levels then return end
			local checkpoint = tonumber(args[1])
			if not checkpoint then
				if players_level[args[1]] then
					checkpoint = players_level[args[1]]
				else
					return translatedChatMessage("invalid_syntax", player)
				end
			end
	
			if checkpoint == 0 then
				checkpoint = #levels
			end
			
			if checkpoint < 0 and checkpoint >= #levels*-1 then
				checkpoint = #levels + checkpoint 
			end
	
			if not levels[checkpoint] then return end
	
			if not review_mode then
				if not victory[player] then return end
				if not checkCooldown(player, "cp_command", 10000) then
					return translatedChatMessage("cooldown", player)
				end
			end
			if not players_level[player] then return end
	
			if checkpoint_info.version == 1 then
				tfm.exec.removeBonus(players_level[player] + 1, player)
			end
			players_level[player] = checkpoint
			changePlayerSize(player, levels[checkpoint].size)
			times.checkpoint[player] = os.time()
			tfm.exec.killPlayer(player)
			if not victory[player] then
				tfm.exec.setPlayerScore(player, checkpoint, false)
			end
	
			local next_level = levels[checkpoint + 1]
			if checkpoints[player] then
				tfm.exec.removeImage(checkpoints[player])
			end
			if next_level then
				addCheckpointImage(player, next_level.x, next_level.y)
				if checkpoint_info.version == 1 then
					tfm.exec.addBonus(0, next_level.x, next_level.y, checkpoint + 1, 0, false, player)
				end
			else
				if not records_admins then
					victory._last_level[player] = true
				end
			end
	
		elseif cmd == "spec" then
			if not players_file[player] then return end
			if not perms[player] or not perms[player].spectate then return end
	
			enableSpecMode(player, not spec_mode[player])
			players_file[player].spec = spec_mode[player]
			savePlayerData(player)
	
		elseif cmd == "time" then
			if not records_admins or not records_admins[player] then
				if not perms[player] then return end
				if not perms[player].set_map_time then
					if perms[player].set_map_time_review then
						if not review_mode then
							return tfm.exec.chatMessage("<v>[#] <r>You can only change the map time with review mode enabled.", player)
						end
					else return end
				end
			end
	
			local time = tonumber(args[1])
			if not time then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			tfm.exec.setGameTime(time)
			inGameLogCommand(player, "time", args)
	
		elseif cmd == "redo" then
			if not (records_admins or review_mode) then return end
			if not players_level[player] then return end
	
			if checkpoint_info.version == 1 then
				tfm.exec.removeBonus(players_level[player] + 1, player)
			end
	
			players_level[player] = 1
			changePlayerSize(player, levels[1].size)
			times.generated[player] = nil
			times.checkpoint[player] = nil
			victory[player] = nil
			victory_count = victory_count - 1
	
			tfm.exec.setPlayerScore(player, 1, false)
			tfm.exec.killPlayer(player)
			tfm.exec.respawnPlayer(player)
	
			local x, y = levels[2].x, levels[2].y
			if checkpoints[player] then
				tfm.exec.removeImage(checkpoints[player])
			end
			addCheckpointImage(player, x, y)
			if checkpoint_info.version == 1 then
				tfm.exec.addBonus(0, x, y, 2, 0, false, player)
			end
	
		elseif cmd == "setcp" then
			if not records_admins or not records_admins[player] then
				if not perms[player] or not perms[player].set_checkpoint_version then return end
			end
	
			local version = tonumber(args[1])
			if not version then
				return tfm.exec.chatMessage("<v>[#] <r>Usage: <b>!setcp 1</b> or <b>!setcp 2</b>.", player)
			end
			if version ~= 1 and version ~= 2 then
				return tfm.exec.chatMessage("<v>[#] <r>Checkpoint version can either be 1 or 2.", player)
			end
	
			checkpoint_info.next_version = version - 1
			tfm.exec.chatMessage("<v>[#] <d>Changes will be applied in the next round.", player)
		end
	end)
	
	onEvent("PlayerDataParsed", function(player, data)
		if players_file[player].spec then
			enableSpecMode(player, true)
			tfm.exec.chatMessage("<v>[#] <d>Your spec mode has been carried to this room since it's enabled.", player)
		end
	
		checkBan(player, data)
	end)
	
	onEvent("PlayerDataUpdated", function(player, data)
		checkBan(player, data)
	end)
	
	onEvent("GameDataLoaded", function(data)
		if data.sanction then
			local oldBans = bans
			bans = {}
			for pid, value in pairs(data.sanction) do
				if value and value.time then
					if value.time == 1 or value.time == 2 or os.time() < value.time then
						bans[tonumber(pid)] = value.timestamp
					end
				end
			end
	
			for player, data in next, room.playerList do
				if in_room[player] then
					if bans[data.id] then
						if AfkInterface.open[player] then
							AfkInterface:remove(player)
						end
						enableSpecMode(player, true)
					elseif oldBans[data.id] then
						enableSpecMode(player, false)
					end
				end
			end
		end
	end)
	
	onEvent("GameStart", function()
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.setRoomMaxPlayers(room_max_players)
		tfm.exec.setRoomPassword("")
		tfm.exec.disableAutoScore(true)
	
		system.disableChatCommandDisplay("review")
		system.disableChatCommandDisplay("cp")
		system.disableChatCommandDisplay("spec")
		system.disableChatCommandDisplay("time")
		system.disableChatCommandDisplay("redo")
		system.disableChatCommandDisplay("setcp")
	end)
	--[[ End of file modes/parkour/game.lua ]]--
	--[[ File modes/parkour/files.lua ]]--
	local next_file_load = os.time() + math.random(60500, 90500)
	local player_ranks
	local no_powers
	local unbind
	local bindNecessary
	local NewBadgeInterface
	local CompletedQuestsInterface
	local QuestsInterface
	local files = {
		--[[
			File values:
	
			- maps        (1)
			- ranks       (1)
			- chats       (1)
	
			- ranking     (2)
			- weekly      (2)
	
			- lowmaps     (3)
			- sanction    (3)
		]]
	
		[1] = 20, -- maps, ranks, chats
		[2] = 21, -- ranking, weekly
		[3] = 23, -- lowmaps, sanction
	}
	local total_files = 3
	local file_index = 1
	local settings_length = 9
	local file_id = files[file_index]
	local WEEKLY_RESET_INIT = 1722204000000
	local last_weekly_reset_ts
	local badges = { -- badge id, small image, big image
		[1] = { -- former staff
			{ 1, "1745f43783e.png", "1745f432e33.png"},
		},
		[2] = { -- leaderboard
			{ 2, "17435b0098c.png", "1745a88ffce.png"}, -- 1
			{ 3, "17435b03030.png", "1745a892d25.png"}, -- 2
			{ 4, "17435b06052.png", "1745a89eb17.png"}, -- 3
			{ 5, "17435af7df1.png", "1745a89bc52.png"}, -- 4
			{ 6, "17435afd7c2.png", "1745a899776.png"}, -- 5
		},
		[3] = { -- weekly podium
			{ 7, "1745a660504.png", "1745a6bfa2c.png"},
		},
		[4] = { -- hour records
			{ 8, "1745a5547a9.png", "1745afa8577.png"}, -- 30
			{ 9, "1745a53f4c9.png", "1745afac029.png"}, -- 35
			{10, "1745a5506b3.png", "1745afaf043.png"}, -- 40
			{11, "1745a54a1e3.png", "1745afb4333.png"}, -- 45
			{12, "1745a541bdd.png", "1745afc2c32.png"}, -- 50
			{13, "1745a54869e.png", "1745afc5c2e.png"}, -- 55
		},
		[5] = { -- discord
			-- filePriority = true, -- always takes the value from the file
	
			{14, "1746ef93af1.png", "1746ef8f813.png"},
		},
		[6] = { -- records
			-- filePriority = true,
	
			{15, "1755b8540b8.png", "1755b851704.png"}, -- 1
			{16, "1755b858a36.png", "1755b85628e.png"}, -- 5
			{17, "1755b85f345.png", "1755b85cc7e.png"}, -- 10
			{18, "1755b865284.png", "1755b861ef0.png"}, -- 15
			{19, "1755baac7c8.png", "1755baa9e31.png"}, -- 20
			{20, "1755bab889c.png", "1755bab5995.png"}, -- 25
			{21, "1755babf3c0.png", "1755babbd2d.png"}, -- 30
			{22, "1755bac4ab9.png", "1755bac1ed3.png"}, -- 35
			{23, "1755bacbdd6.png", "1755bac996d.png"}, -- 40
		},
	}
	local titles = {
		piglet = {
			code = "T_496",
			requirement = 6000,
			field = "tc" -- map count
		},
		checkpoint = {
			code = "T_497",
			requirement = 3000,
			field = "cc" -- checkpoint count
		},
		press_m = {
			code = "T_498",
			requirement = 1500,
			field = "tc"
		}
	}
	
	local quests
	local fillQuests
	local power_quest = {}
	local dont_parse_data = {}
	
	players_file = {}
	
	local data_migrations = {
		["0.0"] = function(player, data)
			data.parkour = data.modules.parkour
			data.drawbattle = data.modules.drawbattle
	
			data.modules = nil
	
			data.parkour.v = "0.1" -- version
			data.parkour.c = data.parkour.cm -- completed maps
	
			data.parkour.cm = nil
		end,
		["0.1"] = function(player, data)
			data.parkour.v = "0.2"
			data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
			data.parkour.mort = 1 -- /mort hotkey
			data.parkour.pcool = 1 -- power cooldowns
			data.parkour.pbut = 1 -- powers button
			data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> azerty
		end,
		["0.2"] = function(player, data)
			data.parkour.v = "0.3"
			data.parkour.killed = 0
		end,
		["0.3"] = function(player, data)
			data.parkour.v = "0.4"
			data.parkour.hbut = 1 -- help button
	
			data.parkour.congrats = 1 -- congratulations message
		end,
	
		["0.4"] = function(player, data)
	
	
			data.parkour.v = "0.5"
			data.parkour.troll = 0
		end,
		["0.5"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.week_c = 0 -- completed maps this week
			data.parkour.week_r = last_weekly_reset_ts -- last week reset
			data.parkour.hour_c = 0 -- completed maps this hour
			data.parkour.hour_r = os.time() + 60 * 60 * 1000 -- next hour reset
			data.parkour.help = 0 -- doesn't want help?
		end,
		["0.6"] = function(player, data)
			data.parkour.v = "0.7"
			data.parkour.keys = {}
			data.parkour.badges = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		end,
		["0.7"] = function(player, data)
			data.parkour.v = "0.8"
			data.parkour.badges[13] = 0
			data.parkour.badges[14] = 0
		end,
		["0.8"] = function(player, data)
			data.parkour.v = "0.9"
	
			local old_badges = data.parkour.badges
			local new_badges = {0, 0, 0, 0, 0, 0}
	
			local limit
			for i = 1, 5 do
				if i == 2 then
					limit = 5
				elseif i == 4 then
					limit = 6
				else
					limit = 1
				end
	
				for j = limit, 1, -1 do
					if old_badges[ badges[i][j][1] ] == 1 then
						new_badges[i] = j
						break
					end
				end
			end
	
			data.parkour.badges = new_badges
		end,
		["0.9"] = function(player, data)
			data.v = 0 -- better
	
			data.c = data.parkour.c -- completed maps
			data.killed = data.parkour.killed -- sanction end
			data.kill = data.parkour.troll -- last sanction duration
			data.keys = data.parkour.keys -- power keys
			data.week = {data.parkour.week_c, data.parkour.week_r} -- maps this week
			data.hour_r = os.time()
			data.hour = {} -- maps in the last hour
			data.badges = data.parkour.badges -- badges
			data.settings = {
				data.parkour.ckpart, -- particle checkpoints (1) or flags (0)
				data.parkour.mort, -- M (1) or DEL (0) or /mort
				data.parkour.pcool, -- show power cooldowns
				data.parkour.pbut, -- show powers button
				data.parkour.keyboard, -- qwerty (1) or azerty (0)
				data.parkour.hbut, -- show help button
				data.parkour.congrats, -- show congratulations messages
				data.parkour.help -- show no help line
			}
			-- data.commu = "en"
			-- data.room = "en-#parkour1"
			-- data.langue = "en"
			-- data.spec = nil
			-- data.banned = nil
			-- data.private_maps = nil
			-- data.hidden = nil
	
			data.parkour = nil
			data.drawbattle = nil
		end,
		[0] = function(player, data)
			data.v = 1
	
			data.report = true
			-- data.namecolor = nil
		end,
		[1] = function(player, data)
			data.v = 2
	
			for index = 1, 8 do
				if not data.settings[index] then
					if index == 5 then -- keyboard
						data.settings[index] = (room.playerList[player] or room).community == "fr" and 0 or 1
					elseif index >= 1 and index <= 7 then
						data.settings[index] = 1
					else
						data.settings[index] = 0
					end
				end
			end
		end,
		[2] = function(player, data)
			data.v = 3
	
			data.tc = 0 -- map counter for titles
			data.cc = 0 -- checkpoint counter for titles
		end,
		[3] = function(player, data)
			data.v = 4
	
			data.settings[2] = (data.settings[2] == 1 and 77 or 46)
		end,
		[4] = function(player, data)
			data.v = 5
	
			data.bancount = 0
			data.lastsanction = nil
			data.bannedby = nil
			--data.playerid = tfm.get.room.playerList[player].id
		end,
		[5] = function(player, data)
			data.v = 6
	
			data.coins = math.floor(data.c * 0.10)
			data.skins = { ["1"] = 1, ["2"] = 1, ["7"] = 1, ["28"] = 1, ["46"] = 1 }
			data.cskins = { 1, 2, 7, 28, 46 }
		end,
		[6] = function(player, data)
			data.v = 7
	
			local questList = {}
			local dailyQuests = fillQuests(data, questList, false)
			local allQuests = fillQuests(data, dailyQuests, true)
	
			data.quests = allQuests
			--data.killedby
		end
	}
	
	local function getQuestsResetTime()
		local currentTime = os.time() + 60 * 60 * 1000
		local currentDate = os.date("*t", os.time() / 1000)
		local day = 24 * 60 * 60 * 1000
	
		currentDate.wday = currentDate.wday - 2
	
		if currentDate.wday == -1 then
			currentDate.wday = 6
		end
	
		local last_daily_reset = math.floor(currentTime / day) * day
		local next_daily_reset = math.ceil(currentTime / day) * day
	
		local last_weekly_reset = last_daily_reset - currentDate.wday * day
		local next_weekly_reset = last_weekly_reset + 7 * day
	
		local reset_times = {last_daily_reset - 60 * 60 * 1000, last_weekly_reset - 60 * 60 * 1000, next_daily_reset, next_weekly_reset}
	
		return reset_times
	end
	
	function savePlayerData(player, delay)
		if not players_file[player] then return end
	
		if delay then
			queueForSave(player)
			return
		end
	
		system.savePlayerData(
			player,
			json.encode(players_file[player])
		)
		eventPlayerDataUpdated(player, players_file[player])
	end
	
	local function updateData(player, data)
		if not data.v and not data.parkour then
			if data.modules then
				data.parkour = {v = "0.0"}
			else
				data.parkour = {
					v = "0.1", -- version
					c = 0 -- completed maps
				}
			end
		end
	
		local migration = data_migrations[data.v or data.parkour.v or "0.0"]
		while migration do
			migration(player, data)
			migration = data_migrations[data.v or data.parkour.v]
		end
	end
	
	onEvent("PlayerDataLoaded", function(player, data)
		if channels[player] then return end
		if in_room[player] then return end
	
		if dont_parse_data[player] then
			dont_parse_data[player] = nil
			local isHidden = data:find('"hidden":true')
			local commu = data:match('"commu":"(.-)"') or "xx"
	
			if isHidden then
				hidden[player] = commu
			else
				online[player] = commu
			end
	
			return
		end
	
		if data == "" then
			data = {}
		else
			local done
			done, data = pcall(json.decode, data)
	
			if not done then
				data = {}
			end
		end
	
		if data.v ~= data_version then
			updateData(player, data)
		end
	
		local commu = data.commu or "xx"
		if not data.hidden then
			online[player] = commu
		else
			hidden[player] = commu
		end
	
		data.settings.__len = settings_length
		eventOutPlayerDataParsed(player, data)
	end)
	
	onEvent("PlayerDataLoaded", function(player, data)
		if channels[player] then return end
		if not in_room[player] then return end
	
		if dont_parse_data[player] then
			dont_parse_data[player] = nil
			local isHidden = data:find('"hidden":true')
			local commu = data:match('"commu":"(.-)"') or room.community
	
			if isHidden then
				hidden[player] = commu
			else
				online[player] = commu
			end
	
			return
		end
	
		if data == "" then
			data = {}
		else
			local done
			done, data = pcall(json.decode, data)
	
			if not done then
				data = {}
				translatedChatMessage("corrupt_data", player)
			end
		end
	
		if data.v ~= data_version then
			updateData(player, data)
		end
	
		if ranks.hidden[player] then
			data.hidden = true
		end
	
		local commu = data.commu or room.community
		if not data.hidden then
			online[player] = commu
		else
			hidden[player] = commu
		end
	
		if players_file[player] then
			return
		end
	
		players_file[player] = data
		players_file[player].room = room.name
		players_file[player].settings.__len = settings_length
		players_file[player].badges.__len = #badges
	
		if room.playerList[player] then
			players_file[player].commu = room.playerList[player].community
			players_file[player].playerid = room.playerList[player].id
		end
	
		if players_file[player].quests then
			local reset_time = getQuestsResetTime() -- reset_time = {last_daily_reset, last_weekly_reset, next_daily_reset, next_weekly_reset}
	
			local isDailyReset = false
			local isWeeklyReset = false
			local questTable = players_file[player].quests
	
			for i = 1, #questTable do
				local quest = questTable[i]
			
				if i <= 4 then
					if (quest.ts and quest.ts < reset_time[1]) or (quest.skp and quest.skp > 1 and quest.skp < reset_time[1]) then
						isDailyReset = true
					end
				else
					if (quest.ts and quest.ts < reset_time[2]) or (quest.skp and quest.skp > 1 and quest.skp < reset_time[2]) then
						isWeeklyReset = true
					end
				end
			end
	
			if isDailyReset or isWeeklyReset then
				if isDailyReset then
					local daily_text = translatedMessage("daily_q", player)
					daily_text = daily_text:lower()
					translatedChatMessage("quest_reset", player, daily_text)
	
					questTable = fillQuests(players_file[player], questTable, false)
				end
			
				if isWeeklyReset then
					local weekly_text = translatedMessage("weekly_q", player)
					weekly_text = weekly_text:lower()
	
					translatedChatMessage("quest_reset", player, weekly_text)
					questTable = fillQuests(players_file[player], questTable, true)
				end
			end
	
			for questID = 1, #questTable do
				if questTable[questID].id == 6 then
					if not power_quest[player] then
						power_quest[player] = {}
					end
	
					if questID <= 4 then
						power_quest[player].d = questTable[questID].pr
						power_quest[player].di = questID
					else
						power_quest[player].w = questTable[questID].pr
						power_quest[player].wi = questID
					end
				end
			end	
	
			players_file[player].quests = questTable
		end
	
		savePlayerData(player, true)
		eventPlayerDataParsed(player, data)
	end)
	
	onEvent("SavingFile", function(id, data)
		system.saveFile(filemanagers[id]:dump(data), id)
	end)
	
	onEvent("FileLoaded", function(id, data)
		data = filemanagers[id]:load(data)
		eventGameDataLoaded(data, id)
	end)
	
	onEvent("Loop", function()
		local now = os.time()
		if now >= next_file_load then
			system.loadFile(file_id)
			next_file_load = now + math.random(10500, 13000)
			file_index = file_index % total_files + 1
			file_id = files[file_index]
		end
	end)
	
	onEvent("GameStart", function()
		system.loadFile(file_id)
		local ts = os.time()
	
		next_file_load = ts + math.random(10500, 15500)
		file_index = file_index % total_files + 1
		file_id = files[file_index]
	
		-- os.date is weird in tfm, *t accepts seconds, %d/%m/%Y accepts ms
		-- so we just don't use it here
		local a_week = 7 * 24 * 60 * 60 * 1000
		last_weekly_reset_ts = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
	end)
	
	onEvent("NewPlayer", function(player)
		players_file[player] = nil -- don't cache lol
		system.loadPlayerData(player)
	end)
	
	onEvent("PlayerDataParsed", function(player, data)
		if data.week[2] ~= last_weekly_reset_ts then
			-- TODO can remove this after aug 5 
			if not tonumber(data.week[2]) and last_weekly_reset_ts == WEEKLY_RESET_INIT then
				return
			end
	
			data.week[1] = 0
			data.week[2] = last_weekly_reset_ts
			savePlayerData(player, true)
		end
	end)
	
	onEvent("PacketReceived", function(channel, id, packet)
		if channel ~= "bots" then return end
	
		if id == packets.bots.remote_command then
			local targetPlayer, targetRoom, command = string.match(packet, "([^\000]+)\000([^\000]+)\000([^\000]+)")
	
			if not in_room[targetPlayer] and targetRoom ~= room.name then
				return
			end
	
			eventChatCommand("Parkour#0568", command)
	
		elseif id == packets.bots.update_pdata then
			local player, fields = string.match(packet, "([^\000]+)\000([^\000]+)")
			local pdata = players_file[player]
			if not in_room[player] or not pdata then
				return
			end
	
			local key, value, done, parsed
			for fieldPair in fields:gmatch('([^\001]+)') do
				key, value = fieldPair:match('([^\002]+)\002([^\002]+)')
				done, parsed = pcall(json.decode, value)
				if not done then
					sendPacket(
						"common", packets.rooms.update_error,
						player .. "\000" .. key .. "\000" .. value
					)
					return
				end
	
				if key == "badges" then
					local p_badges = pdata.badges
					for index = 1, #parsed do
						if parsed[index] ~= p_badges[index] then
							NewBadgeInterface:show(
								player, index, math.max(parsed[index] or 1, 1)
							)
						end
					end
				end
	
				pdata[key] = parsed
	
				if key == "killed" then
					checkKill(player)
				end
			end
	
			savePlayerData(player)
		end
	end)
	--[[ End of file modes/parkour/files.lua ]]--
	--[[ File modes/parkour/ranks.lua ]]--
	local band = (bit or bit32).band
	local bxor = (bit or bit32).bxor
	
	ranks = {
		admin = {_count = 0},
		bot = {_count = 0},
		manager = {_count = 0},
		mod = {_count = 0},
		mapper = {_count = 0},
		trainee = {_count = 0},
		translator = {_count = 0},
		hidden = {_count = 0}
	}
	local ranks_id = {
		admin = 2 ^ 0,
		manager = 2 ^ 1,
		mod = 2 ^ 2,
		mapper = 2 ^ 3,
		trainee = 2 ^ 4,
		translator = 2 ^ 5,
		bot = 2 ^ 6,
		hidden = 2 ^ 7
	}
	local ranks_permissions = {
		admin = {
			set_checkpoint_version = true,
			set_name_color = true,
			give_command = true,
			view_creators = true,
		}, -- will get every permission
		bot = {
			set_checkpoint_version = true
		}, -- will get every permission
		manager = {
			force_stats = true,
			set_room_limit = true,
			set_map_time = true,
			hide = true,
			handle_map_polls = true,
			see_map_polls = true,
			change_roommod = true,
			see_hidden_staff = true,
		},
		mod = {
			ban = true,
			unban = true,
			spectate = true,
			get_player_room = true,
			change_map = true,
			load_custom_map = true,
			kill = true,
			see_private_maps = true,
			use_tracker = true,
			hide = true,
			change_roommod = true,
			see_hidden_staff = true,
			view_sanctions = true,
		},
		mapper = {
			change_map = true,
			load_custom_map = true,
			enable_review = true,
			hide = true,
			spectate = true,
			start_round_poll = true,
			see_map_polls = true,
			set_map_time_review = true,
			change_roommod = true,
			see_hidden_staff = true,
		},
		trainee = {
			ban = true,
			kill = true,
			spectate = true,
			change_map = true,
			get_player_room = true,
			see_private_maps = true,
			use_tracker = true,
			see_hidden_staff = true,
			view_sanctions = true,
		},
		translator = {
			hide = true
		},
		hidden = {}
	}
	player_ranks = {}
	perms = {}
	
	for rank, perms in next, ranks_permissions do
		if rank ~= "admin" and rank ~= "bot" then
			for perm_name, allowed in next, perms do
				ranks_permissions.admin[perm_name] = allowed
				ranks_permissions.bot[perm_name] = allowed
			end
		end
	end
	
	onEvent("GameDataLoaded", function(data)
		if data.ranks then
			ranks, perms, player_ranks = {
				admin = {_count = 0},
				bot = {_count = 0},
				manager = {_count = 0},
				mod = {_count = 0},
				mapper = {_count = 0},
				trainee = {_count = 0},
				translator = {_count = 0},
				hidden = {_count = 0}
			}, {}, {}
			local player_perms, _player_ranks
			for player, rank in next, data.ranks do
				player_perms, _player_ranks = {}, {}
				for name, id in next, ranks_id do
					if band(rank, id) > 0 then
						_player_ranks[name] = true
						ranks[name][player] = true
						ranks[name]._count = ranks[name]._count + 1
						ranks[name][ ranks[name]._count ] = player
						for perm, enabled in next, ranks_permissions[name] do
							player_perms[perm] = enabled
						end
					end
				end
				player_ranks[player] = _player_ranks
				perms[player] = player_perms
			end
		end
	end)
	--[[ End of file modes/parkour/ranks.lua ]]--
	--[[ File modes/parkour/powers.lua ]]--
	local max_leaderboard_rows
	local leaderboard
	local keyboard
	
	no_powers = {}
	local facing = {}
	local cooldowns = {}
	local obj_whitelist = {_count = 0, _index = 1}
	local keybindings = {}
	local used_powers = {_count = 0}
	disable_powers = false
	local first_player = nil
	
	
	local function capitalize(str)
		local first = string.sub(str, 1, 1)
		if first == "+" then
			return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
		else
			return string.upper(first) .. string.lower(string.sub(str, 2))
		end
	end
	
	-- Keep track of the times the key has been binded and wrap system.bindKeyboard
	function bindKeyboard(player, key, down, active)
		if not keybindings[player] then
			if not active then return end
	
			keybindings[player] = {
				[key] = {
					[down] = 0,
					[not down] = 0
				}
			}
		end
	
		local keyInfo = keybindings[player][key]
		if not keyInfo then
			if not active then return end
	
			keyInfo = {
				[down] = 1,
				[not down] = 0
			}
			keybindings[player][key] = keyInfo
		elseif active then
			keyInfo[down] = keyInfo[down] + 1
		else
			keyInfo[down] = keyInfo[down] - 1
		end
	
		if keyInfo[down] < 0 then
			keyInfo[down] = 0
			return
		end
	
		if keyInfo[down] == 1 then
			system.bindKeyboard(player, key, down, true)
		elseif keyInfo[down] == 0 then
			system.bindKeyboard(player, key, down, false)
		end
	end
	
	local function addShamanObject(id, x, y, ...)
		obj_whitelist._count = obj_whitelist._count + 1
		obj_whitelist[obj_whitelist._count] = {id, x, y}
		return tfm.exec.addShamanObject(id, x, y, ...)
	end
	
	function checkCooldown(player, name, long, img, x, y, show)
		if cooldowns[player] then
			if cooldowns[player][name] and os.time() < cooldowns[player][name] then
				return false
			end
			cooldowns[player][name] = os.time() + long
		else
			cooldowns[player] = {
				[name] = os.time() + long
			}
		end
	
		if show then
			addNewTimer(
				long, tfm.exec.removeImage,
				tfm.exec.addImage(img, ":1", x, y, player)
			)
		end
	
		return true
	end
	
	local function despawnableObject(when, ...)
		local obj = addShamanObject(...)
		addNewTimer(when, tfm.exec.removeObject, obj)
		return obj
	end
	
	local function fixHourCount(player, data)
		local reset = data.hour_r
		local hour = data.hour
		local count = #hour
		local save = false
	
		local now = os.time()
		if now - reset >= 3600000 then -- 1 hour
			save = true
	
			local index
			local absolute
			for i = 1, count do
				absolute = hour[i] * 10000 + reset
	
				if now - absolute >= 3600000 then
					hour[i] = nil
				else
					index = i + 1 -- avoid hour check as they're younger than 1 hour
					-- change offset
					hour[i] = math.floor((absolute - now) / 10000)
					break
				end
			end
	
			if index then
				for i = index, count do
					hour[i] = math.floor(
						(hour[i] * 10000 + reset - now) / 10000
					)
				end
			end
	
			data.hour_r = now
			reset = now
		else
			for i = 1, count do
				if now - (hour[i] * 10000 + reset) >= 3600000 then
					hour[i] = nil
				else
					break
				end
			end
		end
	
		-- Normalize indexes
		local offset = 0
		for i = 1, count do
			if hour[i] then
				if offset == 0 then
					break
				end
	
				hour[i - offset] = hour[i]
			else
				offset = offset + 1
			end
		end
	
		for i = count - offset + 1, count do
			hour[i] = nil
		end
	
		if player and (save or offset > 0) then
			queueForSave(player)
		end
	
		return save or offset > 0
	end
	
	-- in small x: positive -> towards the sides, negative -> towards the center
	local powers
	powers = {
		{
			name = "fly", maps = 5,
			id = 1,
			isVisual = true,
	
			small = "173db50edf6.png", big = "173db512e9c.png", -- icons
			lockedSmall = "173db51091f.png", lockedBig = "173db5151fd.png",
			smallX = 0, smallY = -10,
			bigX = 0, bigY = -10,
	
			cooldown = nil,
			default = {5, 4}, -- SPACE
	
			fnc = function(player, key, down, x, y)
				tfm.exec.movePlayer(player, 0, 0, true, nil, -50 * (map_gravity == 0 and 0 or (map_gravity > 0 and 1 or -1)), false)
			end
		},
		{
			name = "speed", maps = 10,
			id = 2,
			isVisual = true,
	
			small = "173db21af6a.png", big = "173db214773.png",
			lockedSmall = "173db21d270.png", lockedBig = "173db217990.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 8,
			cooldown_y = 373,
			cooldown_img = "17127e682ff.png",
	
			cooldown = 1000,
			default = {4, 1}, -- SHIFT
	
			fnc = function(player, key, down, x, y)
				tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
			end
		},
		{
			name = "snowball", maps = 15,
			id = 3,
	
			small = "173db1165c1.png", big = "173db111ba4.png",
			lockedSmall = "173db118b89.png", lockedBig = "173db114395.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 30,
			cooldown_y = 374,
			cooldown_img = "17127e6674c.png",
	
			cooldown = 12500,
			default = {2, 4}, -- E
	
			fnc = function(player, key, down, x, y)
				local right = facing[player]
				despawnableObject(5000, 34, x + (right and 20 or -20), y, 0, right and 10 or -10)
			end
		},
		{
			name = "balloon", maps = 20,
			id = 4,
	
			small = "173db033fb8.png", big = "173db02a545.png",
			lockedSmall = "173db039519.png", lockedBig = "173db035f01.png",
			smallX = 0, smallY = -10,
			bigX = 0, bigY = 0,
	
			cooldown_x = 52,
			cooldown_y = 372,
			cooldown_img = "17127e5b2d5.png",
	
			cooldown = 10000,
			default = {2, 2}, -- Q, A
	
			fnc = function(player, key, down, x, y)
				local skinID = players_file[player].cskins[4] or 28
	
				if shop_skins[tostring(skinID)] then
					local obj_id = despawnableObject(2000, skinID, x, y + 10)
					addNewTimer(
						2000,
						tfm.exec.removeImage,
						tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
					)
					return
				end
	
				despawnableObject(2000, skinID, x, y + 10)
			end,
	
			upgrades = {
				{
					name = "masterBalloon", maps = 200,
					id = 4,
	
					small = "173db167a26.png", big = "173db165783.png",
					smallX = 0, smallY = 10,
					bigX = 0, bigY = 10,
	
					cooldown_img = "17127e5b2d5.png",
	
					fnc = function(player, key, down, x, y)
						local skinID = players_file[player].cskins[4] or 28
	
						if shop_skins[tostring(skinID)] then
							local obj_id = despawnableObject(3000, skinID, x, y + 10)
							addNewTimer(
								4000,
								tfm.exec.removeImage,
								tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
							)
							return
						end
	
						despawnableObject(3000, skinID, x, y + 10)
					end
				},
				{
					name = "bubble", maps = 400,
					id = 4,
	
					small = "173db16a824.png", big = "173db175547.png",
					smallX = 0, smallY = 0,
					bigX = 0, bigY = 0,
	
					cooldown_img = "17127e5b2d5.png",
	
					fnc = function(player, key, down, x, y)
						local skinID = players_file[player].cskins[4] or 28
	
						if skinID == 28 then skinID = 59 end
	
						if shop_skins[tostring(skinID)] then
							local obj_id = despawnableObject(4000, skinID, x, y + 10)
							addNewTimer(
								4000,
								tfm.exec.removeImage,
								tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
							)
							return
						end
	
						despawnableObject(4000, skinID, x, y + 10)
					end
				},
			}
		},
		{
			name = "teleport", maps = 35,
			id = 5,
			isVisual = true,
	
			small = "173db226b7a.png", big = "173db21f2b7.png",
			lockedSmall = "173db22ee81.png", lockedBig = "173db223336.png",
			smallX = 10, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 74,
			cooldown_y = 373,
			cooldown_img = "17127e73965.png",
	
			cooldown = 10000,
			click = true,
	
			fnc = tfm.exec.movePlayer
		},
		{
			name = "smallbox", maps = 50,
			id = 6,
	
			small = "173db0ecb64.png", big = "173db0cd7fb.png",
			lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
			smallX = 10, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 96,
			cooldown_y = 373,
			cooldown_img = "17127e77dbe.jpg",
	
			cooldown = 10000,
			default = {4, 3}, -- Z, W
	
			fnc = function(player, key, down, x, y)
				local skinID = players_file[player].cskins[1] or 1
	
				if shop_skins[tostring(skinID)] then
					local obj_id = despawnableObject(3000, 1, x, y + 10)
					addNewTimer(
						3000,
						tfm.exec.removeImage,
						tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
					)
					return
				end
	
				despawnableObject(3000, skinID, x, y + 10)
			end
		},
		{
			name = "cloud", maps = 100,
			id = 7,
	
			small = "173db14a1d6.png", big = "173db145497.png",
			lockedSmall = "173db15baf3.png", lockedBig = "173db15868b.png",
			smallX = 0, smallY = 10,
			bigX = 0, bigY = 20,
	
			cooldown_x = 121,
			cooldown_y = 377,
			cooldown_img = "17127e5f927.png",
	
			cooldown = 10000,
			default = {4, 4}, -- X
	
			fnc = function(player, key, down, x, y)
				despawnableObject(2000, 57, x, y + 10)
			end
		},
		{
			name = "rip", maps = 700,
			id = 8,
	
			small = "173db33e169.png", big = "173db33602c.png",
			lockedSmall = "173db3407b0.png", lockedBig = "173db33ac9c.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 142,
			cooldown_y = 373,
			cooldown_img = "17127e69ea4.png",
	
			cooldown = 10000,
			default = {4, 6}, -- V
	
			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 90, x, y + 10)
			end
		},
		{
			name = "choco", maps = 1500,
			id = 9,
	
			small = "173db2812bc.png", big = "173db27b241.png",
			lockedSmall = "173db2853a0.png", lockedBig = "173db27dba6.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 164,
			cooldown_y = 374,
			cooldown_img = "17127fc6b27.png",
	
			cooldown = 25000,
			default = {5, 1}, -- CTRL
	
			fnc = function(player, key, down, x, y)
				local skinID = players_file[player].cskins[5] or 46
	
				if shop_skins[tostring(skinID)] then
					local angle = 90
					
					if skinID == 351 then angle = -90 end
	
					local obj_id = despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, angle)
					addNewTimer(
						4000,
						tfm.exec.removeImage,
						tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
					)
					return
				end
	
				despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, 90)
			end
		},
		{
			name = "bigBox", maps = 2500,
			id = 10,
	
			small = "173db0ecb64.png", big = "173db0cd7fb.png",
			lockedSmall = "173db0d3c0b.png", lockedBig = "173db0d172b.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 186,
			cooldown_y = 374,
			cooldown_img = "17127e77dbe.jpg",
	
			cooldown = 25000,
			default = {4, 7}, -- B
	
			fnc = function(player, key, down, x, y)
				local skinID = players_file[player].cskins[2] or 2
	
				if shop_skins[tostring(skinID)] then
					local obj_id = despawnableObject(4000, skinID, x, y + 10, 0)
					addNewTimer(
						4000,
						tfm.exec.removeImage,
						tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
					)
					return
				end
	
				despawnableObject(4000, skinID, x, y + 10, 0)
			end
		},
		{
			name = "trampoline", maps = 4000,
			id = 11,
	
			small = "173db3307ed.png", big = "173db3288d3.png",
			lockedSmall = "173db3335b7.png", lockedBig = "173db32e496.png",
			smallX = 0, smallY = 0,
			bigX = 0, bigY = 0,
	
			cooldown_x = 208,
			cooldown_y = 374,
			cooldown_img = "171cd9f5188.png",
	
			cooldown = 25000,
			default = {4, 8}, -- N
	
			fnc = function(player, key, down, x, y)
				local skinID = players_file[player].cskins[3] or 7
	
				if shop_skins[tostring(skinID)] then
					local obj_id = despawnableObject(4000, skinID, x, y + 10, 0)
					addNewTimer(
						4000,
						tfm.exec.removeImage,
						tfm.exec.addImage(shop_skins[tostring(skinID)].img, "#"..obj_id, 0, 0, nil, 1, 1, 0, 1, shop_skins[tostring(skinID)].x, shop_skins[tostring(skinID)].y)
					)
					return
				end
	
				despawnableObject(4000, skinID, x, y + 10, 0)
			end
		},
		{
			name = "pig", maps = 5000,
			id = 12,
	
			small = "173deea75bd.png", big = "173deea2cc0.png",
			lockedSmall = "173deea9a02.png", lockedBig = "173deea4edc.png",
			smallX = 0, smallY = 20,
			bigX = 0, bigY = 15,
	
			cooldown_x = 229,
			cooldown_y = 380,
			cooldown_img = "1741cfb9868.png",
	
			cooldown = 30000,
			default = {3, 9}, -- K
	
			piggies = {
				"17404198506.png", -- angry
				"174042180f2.png", -- crying
				"174042d5ba0.png", -- love
				"174042eda4f.png", -- blushed
				"174043b0085.png", -- clown
				"1740455e72a.png", -- glasses
				"1740455bd82.png", -- smoking
				"17404561700.png", -- glasses blushed
				"1745e9316ae.png", -- roasted
			},
	
			fnc = function(player, key, down, x, y)
				local id1 = bit32.bxor(room.playerList[player].id, 32768) -- unfortunately physicobjects only use 16 bits as id
				local id2 = bit32.bxor(room.playerList[player].id, 16384)
				local sprite = powers.pig.piggies[math.random(#powers.pig.piggies)]
				local img = tfm.exec.addImage(sprite, "_51", x - 24, y - 15)
	
				local circles = {
					type = 14,
					friction = 0.3
				}
				tfm.exec.addPhysicObject(id1, x + 13, y, circles)
				tfm.exec.addPhysicObject(id2, x - 5, y + 2, circles)
	
				addNewTimer(5000, powers.pig.explode, id1, id2, img, x, y)
				addNewTimer(
					5000,
					tfm.exec.removeImage,
					tfm.exec.addImage("17797e8de0d.png", "_52", x - 30, y - 28)
				)
			end,
	
			explode = function(id1, id2, img, x, y)
				tfm.exec.removePhysicObject(id1)
				tfm.exec.removePhysicObject(id2)
				tfm.exec.removeImage(img)
	
				for confetti = 1, 10 do
					tfm.exec.displayParticle(math.random(21, 24), x, y, math.random(-10, 10), math.random(-10, 10))
				end
				tfm.exec.explosion(x, y, 10, 100, true)
			end
		},
		{
			name = "link", maps = 6000,
			id = 13,
	
			small = "18a1f4da09f.png", big = "18a1f4d198c.png",
			lockedSmall = "18a1f563110.png", lockedBig = "18a1f4e3528.png",
			smallX = 0, smallY = 10,
			bigX = 0, bigY = 20,
	
			cooldown_x = 308,
			cooldown_y = 377,
			cooldown_img = "18a1f569408.png",
	
			cooldown = 60000,
			default = {2, 8}, -- U
	
			cond = function(player, key, down, x, y)
				local soulmate = tfm.get.room.playerList[player].spouseName
				soulmate = soulmate and capitalize(soulmate)
	
				if not soulmate or not in_room[soulmate] then return false end
	
				local soulmateInfo = tfm.get.room.playerList[soulmate]
				local distance = math.sqrt(math.pow(x - soulmateInfo.x, 2) + math.pow(y - soulmateInfo.y, 2))
	
				local soulmate_check = not soulmateInfo.isDead and distance < 200
	
				return soulmate_check
			end,
	
			fnc = function(player, key, down, x, y)
				local soulmate = tfm.get.room.playerList[player].spouseName
				tfm.exec.linkMice(player, soulmate, true)
			end
		},
		{
			name = "sink", ranking = 70,
			id = 14,
	
			small = "173deeb1e05.png", big = "173deeac174.png",
			lockedSmall = "173deeb3dac.png", lockedBig = "173deeaf781.png",
			smallX = 0, smallY = 10,
			bigX = 5, bigY = 10,
	
			cooldown_x = 252,
			cooldown_y = 374,
			cooldown_img = "1741cfd281e.png",
	
			cooldown = 30000,
			default = {4, 5}, -- C
	
			fnc = function(player, key, down, x, y)
				local id = room.playerList[player].id
				local img = tfm.exec.addImage("17426b19d76.png", "_51", x - 20, y - 10)
				tfm.exec.addPhysicObject(id, x, y + 13, {
					type = 14,
					friction = 0.3,
					width = 30
				})
	
				addNewTimer(5000, powers.sink.despawn, id, img)
			end,
	
			despawn = function(id, img)
				tfm.exec.removePhysicObject(id)
				tfm.exec.removeImage(img)
			end,
	
			upgrades = {
				{
					name = "toilet", ranking = 56,
					id = 14,
	
					small = "173db3f2c95.png", big = "173db3f0d81.png",
					smallX = 0, smallY = -10,
					bigX = 10, bigY = 0,
	
					cooldown_img = "171cd9e02d3.png",
	
					fnc = function(player, key, down, x, y)
						local id = room.playerList[player].id
						local img = tfm.exec.addImage("171cd3eddf1.png", "_51", x - 20, y - 20)
						tfm.exec.addPhysicObject(id, x, y + 13, {
							type = 14,
							friction = 0.3,
							width = 30
						})
	
						addNewTimer(5000, powers.toilet.water, img, id, x, y)
					end,
	
					water = function(img, id, x, y)
						tfm.exec.removeImage(img)
	
						local obj = addShamanObject(63, x, y)
						tfm.exec.addPhysicObject(id, x, y - 20, {
							type = 9,
							width = 30,
							height = 60,
							miceCollision = false,
							groundCollision = false,
							foreground = true
						})
	
						addNewTimer(5000, powers.toilet.despawn, id, obj)
					end,
	
					despawn = function(id, obj)
						tfm.exec.removePhysicObject(id)
						tfm.exec.removeObject(obj)
					end
				},
				{
					name = "bathtub", ranking = 42,
					id = 14,
	
					small = "173deeb8924.png", big = "173deeb6576.png",
					smallX = 0, smallY = 5,
					bigX = 5, bigY = 10,
	
					cooldown_img = "1741cfd8396.png",
	
					fnc = function(player, key, down, x, y)
						local id = room.playerList[player].id
						local img = tfm.exec.addImage("17426f98ce6.png", "!1", x - 48, y - 65)
						tfm.exec.addPhysicObject(id, x, y + 13, {
							type = 14,
							friction = 0.3,
							width = 80
						})
	
						addNewTimer(5000, powers.bathtub.water, img, id, x, y)
					end,
	
					water = function(img, id, x, y)
						tfm.exec.removeImage(img)
	
						tfm.exec.addPhysicObject(id, x, y - 40, {
							type = 9,
							width = 90,
							height = 80,
							miceCollision = false,
							groundCollision = false,
							foreground = true
						})
	
						addNewTimer(5000, powers.bathtub.despawn, id)
					end,
	
					despawn = function(id, obj)
						tfm.exec.removePhysicObject(id)
					end
				},
			}
		},
		{
			name = "campfire", ranking = 28,
			id = 15,
			isVisual = true,
	
			small = "173dee9c5d9.png", big = "173dee98c61.png",
			lockedSmall = "173dee9e873.png", lockedBig = "173dee9aaea.png",
			smallX = 0, smallY = 10,
			bigX = 0, bigY = 10,
	
			cooldown_x = 274,
			cooldown_y = 376,
			cooldown_img = "1741cfdadc9.png",
	
			cooldown = 15000,
			default = {3, 8}, -- J
	
			fnc = function(player, key, down, x, y)
				local id = room.playerList[player].id + 2147483648 -- makes 32nd bit 1 so it doesn't play around with the interface textareas
	
				local img = tfm.exec.addImage("17426539be5.png", "_51", x - 30, y - 26)
				ui.addTextArea(id, "<a href='event:emote:11'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", nil, x - 32, y - 26, 64, 56, 0, 0, 0)
				addNewTimer(powers.campfire.cooldown, powers.campfire.despawn, img, id)
			end,
	
			despawn = function(img, id)
				tfm.exec.removeImage(img)
				ui.removeTextArea(id)
			end
		},
		{
			name = "chair", ranking = 14,
			id = 16,
	
			small = "1745a769e88.png", big = "1745a765105.png",
			lockedSmall = "1745a76c506.png", lockedBig = "1745a7675e6.png",
			smallX = 0, smallY = 10,
			bigX = 10, bigY = 10,
	
			cooldown_x = 296,
			cooldown_y = 376,
			cooldown_img = "17459a21979.png",
	
			cooldown = 15000,
			default = {3, 6}, -- G
	
			fnc = function(player, key, down, x, y)
				local id = bit32.bxor(room.playerList[player].id, 49152)
				local img = tfm.exec.addImage("17459a230e9.png", "_51", x - 30, y - 20)
				tfm.exec.addPhysicObject(id, x - 5, y + 20, {
					type = 14,
					friction = 0.3,
					width = 32
				})
	
				addNewTimer(14000, powers.chair.despawn, id, img)
			end,
	
			despawn = function(id, img)
				tfm.exec.removePhysicObject(id)
				tfm.exec.removeImage(img)
			end
		},
	}
	
	local keys = {
		triggers = {}
	}
	
	local function getPowerUpgrade(completed, pos, power, strict, with_review)
		if with_review then
			if not power.upgrades then return power end
			return power.upgrades[#power.upgrades]
		end
	
		if strict then
			if power.ranking and power.ranking < pos then return end
			if not power.ranking and completed < power.maps then return end
		end
	
		if not power.upgrades then return power end
	
		local upgrade
		for index = #power.upgrades, 1, -1 do
			upgrade = power.upgrades[index]
			if upgrade.ranking then
				if upgrade.ranking >= pos then
					return upgrade
				end
			elseif (completed or 0) >= upgrade.maps then
				return upgrade
			end
		end
	
		return power
	end
	
	function bindNecessary(player)
		if not keys[player] or not players_file[player] or keys.triggers[player] then return end
	
		local triggers = {}
		local completed = players_file[player].c
		local pos = leaderboard[player] or max_leaderboard_rows + 1
		local variation_index = players_file[player].settings[5] + 1
	
		local player_keys = keys[player]
		local power, key
		for index = 1, #powers do
			power = getPowerUpgrade(completed, pos, powers[index], true, review_mode or is_anniversary)
	
			if (power and
				(power.isVisual or (not records_admins and submode ~= "smol"))) then
				if power.click then
					system.bindMouse(player, true)
				else
					if player_keys[index] then
						key = player_keys[index]
					elseif powers[index].key[1] then -- variation qwerty/azerty
						key = keyboard.bindings[ powers[index].key[variation_index] ]
					else
						key = keyboard.bindings[ powers[index].key ]
					end
	
					if triggers[key] then
						triggers[key]._count = triggers[key]._count + 1
						triggers[key][ triggers[key]._count ] = power
					else
						triggers[key] = {_count = 1, [1] = power}
						bindKeyboard(player, key, true, true)
					end
				end
			end
		end
	
		bindKeyboard(player, 0, true, true)
		bindKeyboard(player, 2, true, true)
	
		keys.triggers[player] = triggers
	end
	
	function unbind(player)
		if not keys.triggers[player] then return end
	
		bindKeyboard(player, 0, true, false)
		bindKeyboard(player, 2, true, false)
		for key in next, keys.triggers[player] do
			bindKeyboard(player, key, true, false)
		end
		system.bindMouse(player, false)
	
		keys.triggers[player] = nil
	end
	
	local function checkKill(player)
		local data = players_file[player]
		if not data then return end
	
		local had_powers = not no_powers[player]
		no_powers[player] = data.killed > os.time() or nil
		if no_powers[player] then
			translatedChatMessage("kill_minutes", player, math.ceil((data.killed - os.time()) / 1000 / 60))
		end
	
		if victory[player] then
			if had_powers then
				unbind(player)
			end
			if not no_powers[player] then
				bindNecessary(player)
			end
		end
	end
	
	onEvent("Keyboard", function(player, key, down, x, y)
		if not victory[player] or not players_file[player] or not keys.triggers[player] then return end
		if spec_mode[player] then return end
	
		if key == 0 or key == 2 then
			facing[player] = key == 2
			return
		end
	
		local power = keys.triggers[player][key]
		if power then
			for index = 1, power._count do
				if power[index] and (not power[index].cond or power[index].cond(player, key, down, x, y)) and (not power[index].cooldown or checkCooldown(
					player, power[index].name, power[index].cooldown,
	
					power[index].cooldown_img,
					power[index].cooldown_x, power[index].cooldown_y,
	
					players_file[player].settings[3] == 1
				)) and (power[index].isVisual or (not records_admins and submode ~= "smol" and not disable_powers)) then
					power[index].fnc(player, key, down, x, y)
	
					if (count_stats and
					room.uniquePlayers >= min_save and
					player_count >= min_save and
					not records_admins and
					not is_tribe and
					not review_mode) then
						if power_quest[player] and (power_quest[player].w or power_quest[player].d) then
							local save = false
							local file = players_file[player].quests
							if power_quest[player].w and power_quest[player].w == power[index].id then
								quests[6].updateProgress(player, file[power_quest[player].wi], true)
								save = true
							end
							if power_quest[player].d and power_quest[player].d == power[index].id then
								quests[6].updateProgress(player, file[power_quest[player].di], false)
								save = true
							end
	
							if save then
								queueForSave(player)
							end
						end
					end
	
					if not power[index].isVisual then
						used_powers._count = used_powers._count + 1
						used_powers[ used_powers._count ] = {player, power[index].name}
					end
				end
			end
		end
	end)
	
	onEvent("Mouse", function(player, x, y)
		if not victory[player] or not players_file[player] then return end
	
		local power = powers.teleport
		if players_file[player].c >= power.maps or review_mode then
			if (not power.cooldown or checkCooldown(
				player, power.name, power.cooldown,
	
				power.cooldown_img,
				power.cooldown_x, power.cooldown_y,
	
				players_file[player].settings[3] == 1
			)) and (power.isVisual or (not records_admins and submode ~= "smol" and not disable_powers)) then
				power.fnc(player, x, y)
	
				if not power.isVisual then
					used_powers._count = used_powers._count + 1
					used_powers[ used_powers._count ] = {player, power.name}
				end
			end
		end
	end)
	
	onEvent("GameStart", function()
		local upgrade
		for index = 1, #powers do
			powers[ powers[index].name ] = powers[index]
	
			if powers[index].upgrades then
				for _index = 1, #powers[index].upgrades do
					upgrade = powers[index].upgrades[_index]
					powers[ upgrade.name ] = upgrade
	
					upgrade.cooldown_x = powers[index].cooldown_x
					upgrade.cooldown_y = powers[index].cooldown_y
					upgrade.cooldown = powers[index].cooldown
				end
			end
		end
	end)
	
	onEvent("PlayerLeft", function(player)
		keys.triggers[player] = nil
		keybindings[player] = nil
	end)
	
	onEvent("PlayerDataParsed", function(player, data)
		keys[player] = {}
		for index = 1, #data.keys do
			if data.keys[index] > 0 then
				keys[player][index] = data.keys[index]
			end
		end
	
		checkKill(player)
	
		if fixHourCount(nil, data) then
			savePlayerData(player, true)
		end
	end)
	
	onEvent("PlayerDataUpdated", function(player, data)
		checkKill(player)
	
		if data.quests then
			for i = 1, #data.quests do
				if data.quests[i].id == 6 then
					if not power_quest[player] then
						power_quest[player] = {}
					end
	
					if i <= 4 then
						power_quest[player].d = data.quests[i].pr
						power_quest[player].di = i
					else
						power_quest[player].w = data.quests[i].pr
						power_quest[player].wi = i
					end
				end
			end
		end
	
		if fixHourCount(nil, data) then
			savePlayerData(player, true)
		end
	end)
	
	onEvent("PlayerWon", function(player)
		local id = room.playerList[player].id
		if bans[ id ] then return end
		if victory[player] then return end
		local file = players_file[player]
		if not file then return end
	
		if (count_stats and
			room.uniquePlayers >= min_save and
			player_count >= min_save and
			not records_admins and
			not is_tribe and
			not review_mode) then
	
			local earned_coins = is_anniversary and 2 or 1
	
			file.c = file.c + 1
			file.coins = file.coins + earned_coins
	
			file.tc = math.max(
				checkTitleAndNextFieldValue(player, titles.press_m, 1, file, id),
				checkTitleAndNextFieldValue(player, titles.piglet, 1, file, id)
			)
	
			file.cc = checkTitleAndNextFieldValue(player, titles.checkpoint, #levels - 1 --[[total checkpoints but spawn]], file, id)
	
			file.hour[#file.hour + 1] = math.floor((os.time() - file.hour_r) / 10000) -- convert to ms and count every 10s
			file.week[1] = file.week[1] + 1
	
			local hour_count = #file.hour
	
			if hour_count >= 30 and hour_count % 5 == 0 then
				if hour_count >= 35 then
					sendPacket("common", 3, room.shortName .. "\000" .. room.playerList[player].id .. "\000" .. player .. "\000" .. hour_count)
				end
	
				local badge = math.ceil((hour_count - 29) / 5)
				if badge <= #badges[4] then
					if file.badges[4] == 0 or file.badges[4] < badge then
						file.badges[4] = badge
						NewBadgeInterface:show(player, 4, badge)
					end
				end
			end
	
			if first_player == nil then
				first_player = player
			end
	
			if file.quests then
				for questIndex = 1, #file.quests do
					local questID = file.quests[questIndex].id
					local isWeekly = questIndex > 4
	
					if questID < 6 then
						quests[file.quests[questIndex].id].updateProgress(player, file.quests[questIndex], isWeekly)
					end
				end
			end
			
			savePlayerData(player)
		end
	
		if not no_powers[player] then
			bindNecessary(player)
		end
	end)
	
	onEvent("NewGame", function()
		local now = os.time()
		first_player = nil
	
		local to_remove, count = {}, 0
		for player in next, no_powers do
			if not players_file[player] or players_file[player].killed <= now then
				count = count + 1
				to_remove[count] = player
			end
		end
	
		for index = 1, count do
			no_powers[to_remove[index]] = nil
		end
	
		facing = {}
		cooldowns = {}
		obj_whitelist = {_count = 0, _index = 1}
	
		setmetatable(room.objectList, {
			__newindex = function(self, key, value)
				if self[key] == value then return end
	
				rawset(self, key, value)
	
				local obj
				for index = obj_whitelist._index, obj_whitelist._count do
					obj = obj_whitelist[index]
					if obj[1] ~= value.type or obj[2] ~= value.x or obj[3] ~= value.y then
						tfm.exec.removeObject(key)
					else
						obj_whitelist._index = index + 1
					end
					break
				end
			end
		})
	
		local file
		for player in next, in_room do
			file = players_file[player]
			if file then
				fixHourCount(player, file)
			end
			unbind(player)
		end
	end)
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		if not ranks.admin[player] and not ranks.mapper[player] and not ranks.manager[player] then
			return
		end
	
		if cmd == "disablepowers" then
			if not review_mode then
				return tfm.exec.chatMessage("<v>[#] <r>Enable review mode first.", player) 
			end
			disable_powers = true
			tfm.exec.chatMessage("<v>[#] <d>Powers disabled by " .. player .. ".")
		elseif cmd == "enablepowers" then
			if not review_mode then
				return tfm.exec.chatMessage("<r>[#] Enable review mode first.", player) 
			end
			disable_powers = false
			tfm.exec.chatMessage("<v>[#] <d>Powers enabled by " .. player .. ".")
		end
	end)
	--[[ End of file modes/parkour/powers.lua ]]--
	--[[ File modes/parkour/leaderboard.lua ]]--
	max_leaderboard_rows = 73
	local max_weekleaderboard_rows = 31
	local loaded_leaderboard = false
	leaderboard = {}
	weekleaderboard = {}
	-- {id, name, completed_maps, community}
	weeklyfile = {}
	roomleaderboard = {}
	local default_leaderboard_user = {0, nil, 0, "xx"}
	
	local function leaderboardSort(a, b)
		return a[3] > b[3]
	end
	
	local function roomLeaderboardSort(a, b)
		return a[3] < b[3]
	end
	
	local remove, sort = table.remove, table.sort
	
	local function checkPlayersPosition(lbtype) -- 1 = weekly 2 = overall 3 = room
		if lbtype == 3 then return end
		local max_lb_rows = lbtype == 1 and max_weekleaderboard_rows or lbtype == 2 and max_leaderboard_rows
		local lb = lbtype == 1 and weekleaderboard or lbtype == 2 and leaderboard
		local totalRankedPlayers = #lb or 0
		local cachedPlayers = {}
	
		local playerId, position
	
		local toRemove, counterRemoved = {}, 0
		for player = 1, totalRankedPlayers do
			position = lb[player]
			playerId = position[1]
	
			if bans[playerId] then
				counterRemoved = counterRemoved + 1
				toRemove[counterRemoved] = player
			else
				cachedPlayers[playerId] = position
			end
		end
	
		for index = counterRemoved, 1, -1 do
			remove(lb, toRemove[index])
		end
		toRemove = nil
	
		totalRankedPlayers = totalRankedPlayers - counterRemoved
	
		local cacheData
		local playerFile, playerData, completedMaps
	
		for player in next, in_room do
			playerFile = players_file[player]
	
			if playerFile then
				completedMaps = lbtype == 1 and playerFile.week[1] or lbtype == 2 and playerFile.c
				playerData = room.playerList[player]
				if playerData then
					playerId = playerData.id
	
					if not bans[playerId] then
						cacheData = cachedPlayers[playerId]
						if cacheData then
							cacheData[2] = player
							cacheData[3] = completedMaps
							cacheData[4] = playerData.community
						else
							totalRankedPlayers = totalRankedPlayers + 1
							lb[totalRankedPlayers] = {
								playerId,
								player,
								completedMaps,
								playerData.community
							}
						end
					end
				end
			end
		end
	
		sort(lb, leaderboardSort)
	
		for index = max_lb_rows + 1, totalRankedPlayers do
			lb[index] = nil
		end
	
		if lbtype == 2 then
			local name, badges, badge
			for pos = 1, #lb do
				name = lb[pos][2]
				lb[name] = pos
	
				if pos <= 70 and players_file[name] then
					badges = players_file[name].badges
					badge = math.ceil(pos / 14)
	
					if badges[2] == 0 or badges[2] > badge then
						badges[2] = badge
						NewBadgeInterface:show(name, 2, badge)
						savePlayerData(name)
					end
				end
			end
		else
			for index = 1, #lb do
				lb[lb[index][2]] = index
			end
		end
	end
	
	onEvent("GameDataLoaded", function(data)
		if data.ranking then
			if not loaded_leaderboard then
				loaded_leaderboard = true
	
				translatedChatMessage("leaderboard_loaded")
			end
	
			leaderboard = data.ranking
	
			checkPlayersPosition(2)
		end
	
		if data.weekly then
			local ts = os.time() --+ 60 * 60 * 1000
			local file_reset = tonumber(data.weekly.ts) or WEEKLY_RESET_INIT
			local a_day = 24 * 60 * 60 * 1000
			local a_week = 7 * a_day
	
			local new_reset = WEEKLY_RESET_INIT + a_week * math.floor((ts - WEEKLY_RESET_INIT) / a_week)
			if ts - file_reset >= a_week then
				if #weekleaderboard > 2 and weekleaderboard[1][3] > 30 then
					local unlocks_at = ts + a_day
					data.weekly.wl[tostring(weekleaderboard[1][1])] = unlocks_at
					data.weekly.wl[tostring(weekleaderboard[2][1])] = unlocks_at
					data.weekly.wl[tostring(weekleaderboard[3][1])] = unlocks_at
				end
	
				if #weekleaderboard > 2 then
					sendPacket(
						"common", 4,
						os.date("%d/%m/%Y", file_reset) .. "\000" .. os.date("%d/%m/%Y", ts - a_day) ..
						"\000" .. weekleaderboard[1][4] .. "\000" .. weekleaderboard[1][2] .. "\000" .. weekleaderboard[1][3] ..
						"\000" .. weekleaderboard[2][4] .. "\000" .. weekleaderboard[2][2] .. "\000" .. weekleaderboard[2][3] ..
						"\000" .. weekleaderboard[3][4] .. "\000" .. weekleaderboard[3][2] .. "\000" .. weekleaderboard[3][3]
					)
				end
	
				data.weekly.ts = tostring(new_reset)
				data.weekly.ranks = {}
			end
	
			if last_weekly_reset_ts ~= new_reset then
				last_weekly_reset_ts = new_reset
	
				for player, data in next, players_file do
					if data.week[2] ~= new_reset then
						data.week = {0, new_reset}
					end
				end
	
				tfm.exec.chatMessage("<j>The weekly leaderboard has been reset.")
			end
	
			weeklyfile = data.weekly
			weekleaderboard = data.weekly.ranks
	
			checkPlayersPosition(1)
		end
	end)
	
	onEvent("LeaderboardUpdate", function(player, time)
		local playerData = room.playerList[player]
		local completedTime = tonumber(time)
	
		if playerData then
			local playerId = playerData.id
			local playerCommunity = playerData.community
			local playerCount = not #roomleaderboard and 0 or #roomleaderboard
	
			roomleaderboard[playerCount + 1] = {
				playerId,
				player,
				completedTime,
				playerCommunity
			}
	
			sort(roomleaderboard, roomLeaderboardSort)
	
			if #roomleaderboard > 14 then
				roomleaderboard[15] = nil
			end
		end
	end)
	--[[ End of file modes/parkour/leaderboard.lua ]]--
	--[[ File modes/parkour/shop.lua ]]--
	local is_christmas_time
	
	do
		local day = tonumber(os.date("%d"))
		local month = tonumber(os.date("%m"))
	
		is_christmas_time = (month == 12 and day >= 15) or (month == 1 and day <= 15)
	end
	
	shop_items = {
		{ -- smallbox
			{
				price = 0,
				image = is_christmas_time and "18c72bd8ad1.png" or "18b59d0c458.png",
				id = 1,
			},
			{
				price = 140,
				image = "18b53eaa3f9.png",
				id = 158,
			},
			{
				price = 280,
				image = "18b53e880ff.png",
				id = 138,
			},
			{
				price = 420,
				image = "18b53e74af5.png",
				id = 116,
			},
			{
				price = 560,
				image = "18b53ebdc65.png",
				id = 165,
			},
			{
				price = 700,
				image = "18b53e797ee.png",
				id = 125,
			},
			{
				price = 840,
				image = "18b53ea55cf.png",
				id = 157,
			},
			{
				price = 980,
				image = "18b53e831e7.png",
				id = 128,
			},
			{
				price = 1120,
				image = "18b53e7e4e4.png",
				id = 126,
			},
			{
				price = 1260,
				image = "18b53eb403f.png",
				id = 162,
			},
			{
				price = 1400,
				image = "18b53eaf1f7.png",
				id = 161,
			},
			{
				price = 1540,
				image = "18b53e96b76.png",
				id = 147,
			},
			{
				price = 1680,
				image = "18b53e91d53.png",
				id = 142,
			},
			{
				price = 1820,
				image = "18b53e9b7d7.png",
				id = 150,
			},
			{
				price = 1960,
				image = "18b53ea04c8.png",
				id = 154,
			},
			{
				price = 2100,
				image = "18b53e8cf1c.png",
				id = 140,
			},
			{
				price = 2240,
				image = "18b53ec28e7.png",
				id = 109,
			},
			{
				price = 2500,
				image = "18b53eb8e68.png",
				id = 164,
			}
		},
		{ -- bigbox
			{
				price = 0,
				image = is_christmas_time and "18c72bd3975.png" or "18b59d0c458.png",
				id = 2,
			},
			{
				price = 140,
				image = "18b53e74af5.png",
				id = 219,
			},
			{
				price = 280,
				image = "18b53ea55cf.png",
				id = 256,
			},
			{
				price = 420,
				image = "18b53e96b76.png",
				id = 251,
			},
			{
				price = 560,
				image = "18b53e7e4e4.png",
				id = 230,
			},
			{
				price = 700,
				image = "18b53e880ff.png",
				id = 241,
			},
			{
				price = 840,
				image = "18b53ee41df.png",
				id = 261,
			},
			{
				price = 980,
				image = "18b53ed5760.png",
				id = 229,
			},
			{
				price = 1120,
				image = "18b53e831e7.png",
				id = 203,
			},
			{
				price = 1260,
				image = "18b53eaa3f9.png",
				id = 257,
			},
			{
				price = 1400,
				image = "18b53eda58d.png",
				id = 253,
			},
			{
				price = 1540,
				image = "18b53e91d53.png",
				id = 246,
			},
			{
				price = 1680,
				image = "18b53edf1d0.png",
				id = 260,
			},
			{
				price = 1820,
				image = "18b53ed0943.png",
				id = 228,
			},
			{
				price = 1960,
				image = "18b53ecbbf5.png",
				id = 222,
			},
			{
				price = 2100,
				image = "18b53ee8fda.png",
				id = 263,
			},
			{
				price = 2240,
				image = "18b53e8cf1c.png",
				id = 244,
			},
			{
				price = 2500,
				image = "18b53ec28e7.png",
				id = 212,
			},
		},
		{ -- trampoline
			{
				price = 0,
				image = is_christmas_time and "18c72bddd28.png" or "18b2b460ab3.png",
				id = 7,
			},
			{
				price = 140,
				image = "173db3307ed.png",
				id = 701,
			},
			{
				price = 280,
				image = "18b2b404911.png",
				id = 709,
			},
			{
				price = 420,
				image = "18b53f7cf22.png",
				id = 720,
			},
			{
				price = 560,
				image = "18b53f4c31b.png",
				id = 710,
			},
			{
				price = 700,
				image = "18b2b3ff965.png",
				id = 708,
			},
			{
				price = 840,
				image = "18b53f6e4cd.png",
				id = 717,
			},
			{
				price = 980,
				image = "18b53f55e23.png",
				id = 712,
			},
			{
				price = 1120,
				image = "18b53f732dd.png",
				id = 718,
			},
			{
				price = 1260,
				image = "18b2b3f54d8.png",
				id = 706,
			},
			{
				price = 1400,
				image = "18b2b3cb12a.png",
				id = 702,
			},
			{
				price = 1540,
				image = "18b53f86b71.png",
				id = 722,
			},
			{
				price = 1680,
				image = "18b2b3f017e.png",
				id = 705,
			},
			{
				price = 1820,
				image = "18b53f5ac35.png",
				id = 713,
			},
			{
				price = 1960,
				image = "18b2b3eafa5.png",
				id = 704,
			},
			{
				price = 2100,
				image = "18b53f69692.png",
				id = 716,
			},
			{
				price = 2240,
				image = "18b2b3fa678.png",
				id = 707,
			},
			{
				price = 2500,
				image = "18b2b3de757.png",
				id = 703,
			}
		},
		{ -- balloon
			{
				price = 0,
				image = is_christmas_time and  "18c72bb89a4.png" or "18b31269b0a.png",
				id = 28,
			},
			{
				price = 140,
				image = "18b53f0b3d7.png",
				id = 2838,
			},
			{
				price = 280,
				image = "18b53f01a7d.png",
				id = 2825,
			},
			{
				price = 420,
				image = "18b53f323ca.png",
				id = 2859,
			},
			{
				price = 560,
				image = "18b53f2d5a7.png",
				id = 2857,
			},
			{
				price = 700,
				image = "18b53ef7e24.png",
				id = 2823,
			},
			{
				price = 840,
				image = "18b53f19e40.png",
				id = 2842,
			},
			{
				price = 980,
				image = "18b53efcc53.png",
				id = 2824,
			},
			{
				price = 1120,
				image = "18b53f3c01d.png",
				id = 2807,
			},
			{
				price = 1260,
				image = "18b53f066f1.png",
				id = 2827,
			},
			{
				price = 1400,
				image = "18b53f23963.png",
				id = 2805,
			},
			{
				price = 1540,
				image = "18b53f3720d.png",
				id = 2806,
			},
			{
				price = 1680,
				image = "18b53f14dd2.png",
				id = 2841,
			},
			{
				price = 1820,
				image = "18b53f28793.png",
				id = 2855,
			},
			{
				price = 1960,
				image = "18b53f1eb4e.png",
				id = 2844,
			},
			{
				price = 2100,
				image = "18b53eee190.png",
				id = 2801,
			},
			{
				price = 2240,
				image = "18b53ef3008.png",
				id = 2820,
			},
			{
				price = 2500,
				image = "18b53f100e9.png",
				id = 2840,
			}
		},
		{ -- plank
			{
				price = 0,
				image = is_christmas_time and "18c72bfa272.png" or "173db2812bc.png",
				id = 46,
			},
			{
				price = 140,
				image = "18b53fae10e.png",
				id = 333,
			},
			{
				price = 280,
				image = "18b53f9f5ef.png",
				id = 324,
			},
			{
				price = 420,
				image = "18b53f8bc53.png",
				id = 313,
			},
			{
				price = 560,
				image = "18b53f908cb.png",
				id = 314,
			},
			{
				price = 700,
				image = "18b53f9a7d1.png",
				id = 319,
			},
			{
				price = 840,
				image = "18b53fb2e85.png",
				id = 336,
			},
			{
				price = 980,
				image = "18b53fbd2c8.png",
				id = 350,
			},
			{
				price = 1120,
				image = "18b53fa9234.png",
				id = 327,
			},
			{
				price = 1260,
				image = "18b53fd2286.png",
				id = 360,
			},
			{
				price = 1400,
				image = "18b53fd74a2.png",
				id = 361,
			},
			{
				price = 1540,
				image = "18b53fc35cd.png",
				id = 351,
			},
			{
				price = 1680,
				image = "18b53fa440f.png",
				id = 325,
			},
			{
				price = 1820,
				image = "18b53fcd4e9.png",
				id = 358,
			},
			{
				price = 1960,
				image = "18b53fb85b8.png",
				id = 347,
			},
			{
				price = 2100,
				image = "18b53f959a3.png",
				id = 317,
			},
			{
				price = 2240,
				image = "18b53fc863d.png",
				id = 355,
			},
			{
				price = 2500,
				image = "18b53fdc2c8.png",
				id = 309,
			}
		}
	}
	
	shop_skins = {
		["143"] = {img = "18b40057d3b.png", x = 0.5, y = 0.52},
		["144"] = {img = "18b4005cd84.png", x = 0.5, y = 0.52},
		["145"] = {img = "18b40061bab.png", x = 0.5, y = 0.52},
		["146"] = {img = "18b400669c6.png", x = 0.5, y = 0.52},
		["147"] = {img = "18b4006b7e6.png", x = 0.5, y = 0.60},
		["148"] = {img = "18b4007060c.png", x = 0.5, y = 0.52},
		["149"] = {img = "18b40075436.png", x = 0.5, y = 0.52},
		["150"] = {img = "18b4007a243.png", x = 0.5, y = 0.52},
		["151"] = {img = "18b4007f075.png", x = 0.5, y = 0.52},
		["152"] = {img = "18b40083e91.png", x = 0.5, y = 0.52},
		["153"] = {img = "18b40088cb4.png", x = 0.5, y = 0.52},
		["154"] = {img = "18b4008dacf.png", x = 0.5, y = 0.52},
		["155"] = {img = "18b400928fa.png", x = 0.5, y = 0.52},
		["156"] = {img = "18b40097712.png", x = 0.5, y = 0.52},
		["157"] = {img = "18b4009c9a6.png", x = 0.5, y = 0.52},
		["158"] = {img = "18b400a173a.png", x = 0.5, y = 0.52},
		["159"] = {img = "18b400a6558.png", x = 0.5, y = 0.52},
		["160"] = {img = "18b400ab37d.png", x = 0.5, y = 0.52},
		["161"] = {img = "18b400b019a.png", x = 0.5, y = 0.52},
		["162"] = {img = "18b400b4fb8.png", x = 0.5, y = 0.52},
		["163"] = {img = "18b400b9ccf.png", x = 0.5, y = 0.52},
		["164"] = {img = "18b400be9bc.png", x = 0.5, y = 0.52},
		["165"] = {img = "18b400c3a16.png", x = 0.5, y = 0.52},
		["166"] = {img = "18b400c8838.png", x = 0.5, y = 0.52},
	
		["247"] = {img = "18b4011d953.png", x = 0.5, y = 0.52},
		["248"] = {img = "18b401225c5.png", x = 0.5, y = 0.52},
		["249"] = {img = "18b401273e8.png", x = 0.5, y = 0.52},
		["250"] = {img = "18b4012c205.png", x = 0.5, y = 0.52},
		["251"] = {img = "18b40131024.png", x = 0.5, y = 0.65},
		["252"] = {img = "18b40135e54.png", x = 0.5, y = 0.52},
		["253"] = {img = "18b4013ac6c.png", x = 0.5, y = 0.52},
		["254"] = {img = "18b4013fa8f.png", x = 0.5, y = 0.52},
		["255"] = {img = "18b401448b8.png", x = 0.5, y = 0.52},
		["256"] = {img = "18b401496c6.png", x = 0.5, y = 0.52},
		["257"] = {img = "18b4014e4f2.png", x = 0.5, y = 0.52},
		["258"] = {img = "18b40153316.png", x = 0.5, y = 0.52},
		["259"] = {img = "18b40158130.png", x = 0.5, y = 0.52},
		["260"] = {img = "18b4015cf4e.png", x = 0.5, y = 0.52},
		["261"] = {img = "18b40161bc6.png", x = 0.5, y = 0.52},
		["262"] = {img = "18b401668cc.png", x = 0.5, y = 0.52},
		["263"] = {img = "18b4016b5c0.png", x = 0.5, y = 0.52},
		["264"] = {img = "18b401703ee.png", x = 0.5, y = 0.52},
		["265"] = {img = "18b40175208.png", x = 0.5, y = 0.52},
	
		["309"] = {img = "18b53784421.png", x = 0.5, y = 0.50},
		["355"] = {img = "18b537c3559.png", x = 0.5, y = 0.51},
		["317"] = {img = "18b53792ac2.png", x = 0.5, y = 0.50},
		["347"] = {img = "18b537b4cdb.png", x = 0.5, y = 0.55},
		["358"] = {img = "18b537c8378.png", x = 0.5, y = 0.55},
		["325"] = {img = "18b537a13cd.png", x = 0.5, y = 0.55},
		["351"] = {img = "18b537be737.png", x = 0.5, y = 0.55},
		["361"] = {img = "18b537d1fde.png", x = 0.5, y = 0.55},
		["360"] = {img = "18b537cd1ac.png", x = 0.5, y = 0.65},
		["327"] = {img = "18b537a649b.png", x = 0.5, y = 0.52},
		["350"] = {img = "18b537b99d5.png", x = 0.5, y = 0.52},
		["336"] = {img = "18b537affdb.png", x = 0.5, y = 0.70},
		["319"] = {img = "18b53797a1a.png", x = 0.5, y = 0.65},
		["314"] = {img = "18b5378dddb.png", x = 0.5, y = 0.53},
		["313"] = {img = "18b537890e5.png", x = 0.45, y = 0.68},
		["324"] = {img = "18b5379c6d5.png", x = 0.5, y = 0.40},
		["333"] = {img = "18b537ab2af.png", x = 0.48, y = 0.52},
	
		["710"] = {img = "18b400d1c43.png", x = 0.5, y = 0.70},
		["711"] = {img = "18b400d6acd.png", x = 0.5, y = 0.52},
		["712"] = {img = "18b400db8e9.png", x = 0.5, y = 0.52},
		["713"] = {img = "18b400e070f.png", x = 0.5, y = 0.52},
		["714"] = {img = "18b400e5535.png", x = 0.5, y = 0.52},
		["715"] = {img = "18b400ea34c.png", x = 0.5, y = 0.52},
		["716"] = {img = "18b400ef16c.png", x = 0.5, y = 0.52},
		["717"] = {img = "18b400f3f9a.png", x = 0.5, y = 0.52},
		["718"] = {img = "18b400f8dbd.png", x = 0.5, y = 0.52},
		["719"] = {img = "18b400fdcbc.png", x = 0.5, y = 0.52},
		["720"] = {img = "18b401029ff.png", x = 0.5, y = 0.52},
		["721"] = {img = "18b40107833.png", x = 0.5, y = 0.52},
		["722"] = {img = "18b4010c62f.png", x = 0.5, y = 0.52},
	
		["2845"] = {img = "18b40180a6f.png", x = 0.5, y = 0.52},
		["2846"] = {img = "18b40185865.png", x = 0.5, y = 0.52},
		["2847"] = {img = "18b4018a633.png", x = 0.5, y = 0.52},
		["2848"] = {img = "18b4018f402.png", x = 0.5, y = 0.52},
		["2849"] = {img = "18b40194226.png", x = 0.5, y = 0.52},
		["2850"] = {img = "18b40199045.png", x = 0.5, y = 0.52},
		["2851"] = {img = "18b4019de68.png", x = 0.5, y = 0.52},
		["2852"] = {img = "18b401a2c83.png", x = 0.5, y = 0.52},
		["2853"] = {img = "18b401a7ab1.png", x = 0.5, y = 0.52},
		["2854"] = {img = "18b401ac8c7.png", x = 0.5, y = 0.52},
		["2855"] = {img = "18b401b16f0.png", x = 0.5, y = 0.52},
		["2856"] = {img = "18b401b65eb.png", x = 0.5, y = 0.52},
		["2857"] = {img = "18b401bb336.png", x = 0.5, y = 0.52},
		["2858"] = {img = "18b401c0154.png", x = 0.5, y = 0.52},
		["2859"] = {img = "18b401c4f6e.png", x = 0.5, y = 0.52},
	}
	
	if is_christmas_time then
		shop_skins["1"] = {img = "18c72bad79e.png", x = 0.5, y = 0.50}
		shop_skins["2"] = {img = "18c72ba3321.png", x = 0.5, y = 0.50}
		shop_skins["7"] = {img = "18c72bb2589.png", x = 0.5, y = 0.52}
		shop_skins["28"] = {img = "18c72bccb7c.png", x = 0.5, y = 0.30}
		shop_skins["46"] = {img = "18c72ba881a.png", x = 0.5, y = 0.52}
	end
	--[[ End of file modes/parkour/shop.lua ]]--
	--[[ File modes/parkour/quests.lua ]]--
	local function getPlayerQuest(player, questID, isWeekly)
		if not players_file[player] or not players_file[player].quests then
			return false
		end
	
		local min = isWeekly and 5 or 1
		local max = isWeekly and 8 or 4
	
		local playerQuests = players_file[player].quests
	
		for i = min, max do
			if playerQuests[i] and playerQuests[i].id == questID then
				return playerQuests[i]
			end
		end
	end
	
	local function removeCompletedQuestUI(player)
		if CompletedQuestsInterface.open[player] then
			CompletedQuestsInterface:remove(player)
		end
	end
	
	local function completeQuest(player, questData, isWeekly, questID)
		if not questData then return end
		if not room.playerList[player] then return end
		if questData.ts then return end
	
		if QuestsInterface.open[player] then
			QuestsInterface:remove(player)
		end
	
		local file = players_file[player]
		local questPrize = quests[questID].prize(player, isWeekly)
	
		if not questPrize or not file then return end
	
		questData.ts = os.time()
		file.coins = file.coins + questPrize
	
		if not CompletedQuestsInterface.open[player] then
			CompletedQuestsInterface:show(player, isWeekly, questPrize) 
			addNewTimer(5000, removeCompletedQuestUI, player)
		end
	end
	
	quests = {
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 1, isWeekly)
				if not questData then return end
	
				return translatedMessage("quest_1", player, questData.pg, questData.tg)
		  	end,
	
			target = function(isWeekly)
				local questTarget = isWeekly and math.random(100, 250) or math.random(25, 50)
				questTarget = math.floor(questTarget / 5) * 5
	
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 1, isWeekly)
				if not questData then return end
	
				local prize = questData.tg * 0.75
				return math.floor(prize / 5) * 5 -- per map
			end,
	
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				questData.pg = questData.pg + 1
				
				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 1)
				end
	
			end,
		},
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 2, isWeekly)
				if not questData then return end
	
				return translatedMessage("quest_2", player, questData.pg, questData.tg)
		  	end,
	
			target = function(isWeekly)
				local questTarget = isWeekly and math.random(500, 900) or math.random(150, 300)
				questTarget = math.floor(questTarget / 5) * 5
	
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 2, isWeekly)
				if not questData then return end
	
				local prize = questData.tg * 0.1
				return math.floor(prize / 5 ) * 5 -- per cp
			end,
	
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				questData.pg = questData.pg + #levels - 1
	
				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 2)
				end
			end,
			
		},
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 3, isWeekly)
				if not questData then return end
	
				return translatedMessage("quest_3", player, questData.pg, questData.tg)
		  	end,
	
			target = function(isWeekly)
				local questTarget = isWeekly and math.random(25, 50) or math.random(5, 10)
	
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 3, isWeekly)
				if not questData then return end
	
				local prize = questData.tg * 3
				return math.floor(prize / 5 ) * 5 -- per map
			end,
	
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				
				if first_player == player then
					questData.pg = questData.pg + 1 
				end
	
				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 3)
				end
			end,
		},
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 4, isWeekly)
				if not questData then return end
	
				return translatedMessage("quest_4", player, questData.tg)
		  	end,
	
			target = function(isWeekly)
				local questTarget = isWeekly and 40 or 60
	
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 4, isWeekly)
				if not questData then return end
	
				if isWeekly then
					return 50
				else
					return 25
				end
			end,
	
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				local taken = (os.time() - (times.generated[player] or times.map_start)) / 1000
				if taken < questData.tg	then
					questData.pg = questData.tg
	
					if questData.pg >= questData.tg then
						completeQuest(player, questData, isWeekly, 4)
					end	
				end
			end,
		},
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 5, isWeekly)
				if not questData then return end
	
				local mapCode = maps.list_high[((questData.tg-1)%#maps.list_high) + 1 ] or "N/A"
	
				return translatedMessage("quest_5", player, mapCode)
		  	end,
	
			target = function(isWeekly)
				local mapIndex = math.random(1000)
				
				local questTarget = mapIndex
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 5, isWeekly)
				if not questData then return end
	
				return 50
			end,
			
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				if maps.list_high[((questData.tg - 1)%#maps.list_high) + 1 ] == tonumber(current_map) then
					questData.pg = questData.tg
	
					if questData.pg >= questData.tg then
						completeQuest(player, questData, isWeekly, 5)
					end	
				end
			end,
		},
		{
			description = function(player, isWeekly)
				local questData = getPlayerQuest(player, 6, isWeekly)
				if not questData then return end
				local powerName = translatedMessage(powers[questData.pr].name, player)
				
				return translatedMessage("quest_6", player, powerName, questData.pg, questData.tg )
		  	end,
	
			target = function(isWeekly)
				local questTarget = isWeekly and math.random(100, 150) or math.random(20, 50)
				questTarget = math.floor(questTarget / 5) * 5
	
	            return tonumber(questTarget)
			end,
	
			prize = function(player, isWeekly)
				local questData = getPlayerQuest(player, 6, isWeekly)
				if not questData then return end
	
				local prize = questData.tg * 0.5
				return math.floor(prize / 5) * 5 -- per use
			end,
	
			updateProgress = function(player, questData, isWeekly)
				if questData and questData.ts then return end
				
				questData.pg = questData.pg + 1
	
				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 6)
	
					if isWeekly then
						power_quest[player].w = nil
						power_quest[player].wi = nil
					else
						power_quest[player].d = nil
						power_quest[player].di = nil
					end
				end
			end,
		}
	}
	
	local function getPowerList(data)
		if not data then return end
		local availablePowers = {4,6,7,8,9,10,11,12,13}
		local playerPowers = {}
	
		for i = 1, #availablePowers do
			if data.c >= powers[availablePowers[i]].maps then
				table.insert(playerPowers, availablePowers[i])
			end
		end
	
		return playerPowers
	end
	
	function fillQuests(data, questList, isWeekly, skipQuest)
		local reset_times = getQuestsResetTime()
		local reset_time = isWeekly and reset_times[2] or reset_times[1]
	
		local min = isWeekly and 5 or 1
		local max = isWeekly and 8 or 4
	
		local availableQuests = {}
		for i = 1, #quests do
			availableQuests[i] = i
		end
	
		for i = min, max do
			if not questList[i] then break end
			if not questList[i].ts or (questList[i].ts > reset_time) or (skipQuest and questList[i].skp and questList[i].skp == 0) then
				availableQuests[questList[i].id] = -1
			end
		end
	
		local listOfPowers = getPowerList(data)
	
		if #listOfPowers < 1 then
			availableQuests[6] = -1
		end
	
		for i = #quests, 1, -1 do
			if availableQuests[i] == -1 then
				table.remove(availableQuests, i)
			end
		end
	
		for i = min, max do
			if (not skipQuest and questList[i] and questList[i].skp and questList[i].skp ~= 0 and questList[i].skp < reset_time) then
				if questList[i].skp then
					questList[i].skp = nil 
				end
			end
	
			if not questList[i] or (not skipQuest and (questList[i].ts and questList[i].ts < reset_time)) or (skipQuest and questList[i].skp and questList[i].skp == 0) then
	
				local randomIndex = math.random(#availableQuests)
				local randomQuest = availableQuests[randomIndex]
	
				if randomQuest == 6 then
					local randomIdx = math.random(#listOfPowers)
					local randomPower = listOfPowers[randomIdx]
	
					questList[i] = {
						id = randomQuest,
						tg = quests[randomQuest].target(isWeekly),
						pg = 0,
						pr = randomPower,
					}
				else
					questList[i] = {
						id = randomQuest,
						tg = quests[randomQuest].target(isWeekly),
						pg = 0,
					}
				end
	
				table.remove(availableQuests, randomIndex)
			end
		end
		return questList
	end
	--[[ End of file modes/parkour/quests.lua ]]--
	--[[ File modes/parkour/chat-ui.lua ]]--
	-- Stuff related to the chat (not keyboard nor interface)
	
	local fetching_player_room = {}
	local roompw = {}
	local roomcreators = {}
	local fastest = {}
	local next_easter_egg = os.time() + math.random(30, 60) * 60 * 1000
	
	local GameInterface
	local setNameColor
	
	local function capitalize(str)
		local first = string.sub(str, 1, 1)
		if first == "+" then
			return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
		else
			return string.upper(first) .. string.lower(string.sub(str, 2))
		end
	end
	
	local function checkRoomRequest(player, data)
		local fetch = fetching_player_room[player]
		if fetch then
			if data.commu then
				tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s community: <d>" .. data.commu, fetch[1])
			end
			if data.room then
				tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. data.room, fetch[1])
			end
			fetching_player_room[player] = nil
		end
	end
	
	onEvent("NewGame", function()
		fastest = {}
	
		if is_tribe then
			translatedChatMessage("tribe_house")
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", nil, room.uniquePlayers, min_save)
		end
	end)
	
	onEvent("NewPlayer", function(player)
		if levels then
			if is_tribe then
				translatedChatMessage("tribe_house", player)
			elseif room.uniquePlayers < min_save then
				translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
			end
		end
		
		do
			for name in next, room.playerList do
				roomcreators[1 + #roomcreators] = name
			end
		end
	end)
	
	onEvent("PlayerWon", function(player)
		local id = room.playerList[player].id
		if bans[id] then return end
		if victory[player] then return end
		local file = players_file[player]
		if not file then return end
		if not levels then return end
	
		victory[player] = true
		setNameColor(player) -- just in case PlayerRespawn triggers first
	
		if records_admins then
			translatedChatMessage("records_completed", player)
		end
	
		-- If the player joined the room after the map started,
		-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
		local taken = (os.time() - (times.generated[player] or times.map_start)) / 1000
	
		if not fastest.record or taken < fastest.record then
			local old = fastest.player
	
			fastest.record = taken
			fastest.player = player
			fastest.submitted = nil
	
			if old and in_room[old] then
				setNameColor(old)
			end
	
			if records_admins then
				translatedChatMessage("records_submit", player)
			end
		end
	
		if file.settings[7] == 0 then
			translatedChatMessage("finished", player, player, taken)
		end
	
		for _player in next, in_room do
			if players_file[_player] and players_file[_player].settings[7] == 1 then
				translatedChatMessage("finished", _player, player, taken)
			end
		end
	
		eventLeaderboardUpdate(player, taken)
	
		if records_admins then
			tfm.exec.chatMessage(
				"<v>[#] <d>" .. room.currentMap .. " - CP: " ..
				(checkpoint_info.version == 0 and "old" or "new")
				, player
			)
		end
	
		if is_tribe then
			translatedChatMessage("tribe_house", player)
	
		elseif room.uniquePlayers < min_save or player_count < min_save then
			translatedChatMessage(
				"min_players",
				player,
				math.min(room.uniquePlayers, player_count),
				min_save
			)
	
		elseif count_stats and not records_admins and not review_mode then
			local power
			for index = 1, #powers do
				power = powers[index]
	
				if file.c == power.maps then
					for _player in next, in_room do
						translatedChatMessage("unlocked_power", _player, player, translatedMessage(power.name, _player))
					end
					break
				end
			end
		end
	end)
	
	onEvent("ChatCommand", function(player, msg)
		local cmd, args, pointer = "", {}, -1
		for slice in string.gmatch(msg, "%S+") do
			pointer = pointer + 1
			if pointer == 0 then
				cmd = string.lower(slice)
			else
				args[pointer] = slice
			end
		end
	
		eventParsedChatCommand(player, cmd, pointer, args)
	end)
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		local max_args = quantity
	
		if cmd == "donate" then
			tfm.exec.chatMessage("<rose>" .. links.donation, player)
			return
	
		elseif cmd == "discord" then
			tfm.exec.chatMessage("<rose>" .. links.discord, player)
			return
	
		elseif cmd == "submit" then
			if not records_admins then return end
			local map = tonumber(string.sub(room.currentMap, 2))
	
			if fastest.player ~= player then
				return translatedChatMessage("records_not_fastest", player)
			end
			if fastest.submitted then
				return translatedChatMessage("records_already_submitted", player)
			end
			if not count_stats then
				local exists = false
	
				for index = 1, maps.high_count do
					if map == maps.list_high[index] then
						exists = true
						break
					end
				end
	
				if not exists then
					for index = 1, maps.low_count do
						if map == maps.list_low[index] then
							exists = true
							break
						end
					end
	
					if not exists then
						return translatedChatMessage("records_invalid_map", player)
					end
				end
			end
	
			fastest.submitted = true
			fastest.wait_send = true
			
			tfm.exec.chatMessage("<v>[#] <d>You can't send record with this way, check Records Discord server: https://discord.gg/zbjVYAxYzp", player)
	
		elseif cmd == "pause" then -- logged
			if not ranks.admin[player] then return end
	
			local total = tonumber(args[1]) or 31
	
			local finish = os.time() + (total - usedRuntime)
			while os.time() < finish do end
	
			tfm.exec.chatMessage("<v>[#] <d>used " .. (total - usedRuntime) .. "ms of runtime", player)
			max_args = 1
	
		elseif cmd == "give" then -- logged
			if not perms[player] or not perms[player].give_command then return end
	
			if quantity < 2 then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			local target = capitalize(args[1])
			if not string.find(target, "#", 1, true) then
				target = target .. "#0000"
			end
	
			local file = players_file[target]
			if not file or not room.playerList[target] then
				return tfm.exec.chatMessage("<v>[#] <r>wtf u doin <b>" .. target .. "</b> is not here??¿¿¿", player)
			end
	
			local thing = string.lower(args[2])
			if thing == "maps" then
				if quantity < 4 then
					return tfm.exec.chatMessage("<v>[#] <r>u gotta specify an action and a quantity noob", player)
				end
	
				local action, quantity = string.lower(args[3]), tonumber(args[4])
				if not quantity then
					return tfm.exec.chatMessage("<v>[#] <r>" .. args[4] .. " doesnt look like a number; did u fail math?", player)
				end
	
				if action == "add" then
					file.c = file.c + quantity
				elseif action == "sub" then
					file.c = file.c - quantity
				elseif action == "set" then
					file.c = quantity
				elseif action == "migrate" then
					file.c = file.c + quantity
					file.migrated = true
				else
					return tfm.exec.chatMessage("<v>[#] <r>" .. action .. " doesnt look like an action wtf", player)
				end
	
				tfm.exec.chatMessage("<v>[#] <d>" .. target .. "'s new map count: " .. file.c, player)
	
			elseif thing == "badge" then
				if quantity < 4 then
					return tfm.exec.chatMessage("<v>[#] <r>u gotta specify a badge group and badge id", player)
				end
	
				local group, badge = tonumber(args[3]), tonumber(args[4])
				if not group then
					return tfm.exec.chatMessage("<v>[#] <r>" .. args[3] .. " doesnt look like a badge group?", player)
				elseif not badge then
					return tfm.exec.chatMessage("<v>[#] <r>" .. args[4] .. " doesnt look like a badge id?", player)
				elseif group < 1 or group > #badges then
					return tfm.exec.chatMessage(
						"<v>[#] <r>there are " .. #badges .. " badge groups but u want to give the n° " .. badge .. "?", player
					)
				elseif badge < 0 or badge > #badges[group] then
					return tfm.exec.chatMessage(
						"<v>[#] <r>that group has ids 0-" .. #badges[group] .. " but u want " .. badge .. "?", player
					)
				elseif badges[group].filePriority then
					return tfm.exec.chatMessage("<v>[#] <r>that badge group can only be affected by bots", player)
				end
	
				file.badges[group] = badge
				if badge > 0 then
					NewBadgeInterface:show(target, group, badge)
				end
	
				tfm.exec.chatMessage("<v>[#] <d>badge group " .. group .. " affected on player " .. target, player)
	
			elseif thing == "migration" then
				file.migrated = true
				tfm.exec.chatMessage("<v>[#] <d>given migration flag to " .. target, player)
	
			elseif thing == "coins" then
				
				if quantity < 2 then
					return translatedChatMessage("invalid_syntax", player)
				end
	
				local coin_count = args[3]
				if not tonumber(coin_count) then
					tfm.exec.chatMessage("<v>[#] <d> doesnt look like a number", player)
					return
				end
	
				file.coins = file.coins + coin_count
				tfm.exec.chatMessage("<v>[#] <d>" .. target .. "'s new coin count: " .. file.coins, player)
	
			elseif thing == "namecolor" then
				if not perms[player].set_name_color then
					return tfm.exec.chatMessage("<v>[#] <r>u cant set a player's namecolor", player)
				end
	
				if quantity > 2 and string.lower(args[3]) == "nil" then
					tfm.exec.chatMessage("<v>[#] <d>removed custom namecolor from " .. target, player)
					file.namecolor = nil
					setNameColor(target)
	
				else
					ui.showColorPicker(room.playerList[target].id, player, file.namecolor, target .. "'s namecolor")
					return
				end
	
			else
				return tfm.exec.chatMessage("<v>[#] <r>idk wtf is <b>" .. thing .. "</b>", player)
			end
	
			savePlayerData(target)
	
		elseif cmd == "roommod" then
			local has_perm = perms[player] and perms[player].change_roommod
			local is_owner = records_admins and records_admins[player]
			if not has_perm and not is_owner then
				return
			end
	
			local target = args[1]
			if quantity < 1 or records_admins[target] or not room.playerList[target] then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			records_admins[target] = 1
			tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is a room mod now.")
	
			-- don't log room owner actions
			if is_owner then
				return
			end
	
		elseif cmd == "deroommod" then
			local has_perm = perms[player] and perms[player].change_roommod
			local is_owner = records_admins and records_admins[player]
			if not has_perm and not is_owner then
				return
			end
	
			local target = args[1]
			if quantity < 1 or records_admins[target] ~= 1 then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			records_admins[target] = nil
			tfm.exec.chatMessage("<v>[#] <d>" .. target .. " is not a room mod anymore.")
	
			-- don't log room owner actions
			if is_owner then
				return
			end
	
		elseif cmd == "creators" then
			if not perms[player] or not perms[player].view_creators then return end
	
			tfm.exec.chatMessage("<v>[#] <bl>People in the room when the module was loaded:", player)
			for i=1, #roomcreators, 10 do
				tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(roomcreators, ' ', i, math.min(i+9, #roomcreators)), player)
			end
	
		elseif cmd == "pw" then
			if not records_admins or not records_admins[player] then
				if not perms[player] or not perms[player].enable_review then return end
	
				if not review_mode and not ranks.admin[player] then
					return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of a room without review mode.", player)
				end
			end
	
			if roompw.owner and roompw.owner ~= player and not ranks.admin[player] then
				return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of this room. Ask " .. roompw.owner .. " to do so.", player)
			end
	
			local password = table.concat(args, " ")
			tfm.exec.setRoomPassword(password)
	
			if password == "" then
				roompw.owner = nil
				roompw.password = nil
				return tfm.exec.chatMessage("<v>[#] <d>Room password disabled by " .. player .. ".")
			end
			tfm.exec.chatMessage("<v>[#] <d>Room password changed by " .. player .. ".")
			tfm.exec.chatMessage("<v>[#] <d>You set the room password to: " .. password, player)
	
			if not roompw.owner then
				roompw.owner = player
			end
			roompw.password = password
			return
	
		elseif cmd == "roomlimit" then -- logged
			if not perms[player] or not perms[player].set_room_limit then return end
	
			local limit = tonumber(args[1])
			if not limit then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			tfm.exec.setRoomMaxPlayers(limit)
			tfm.exec.chatMessage("<v>[#] <d>Set room max players to " .. limit .. ".", player)
			max_args = 1
	
		elseif cmd == "langue" then
			if quantity == 0 then
				tfm.exec.chatMessage("<v>[#] <d>Available languages:", player)
				for name, data in next, translations do
					if name ~= "pt" then
						tfm.exec.chatMessage("<d>" .. name .. " - " .. data.fullname, player)
					end
				end
				tfm.exec.chatMessage("<d>Type <b>!langue ID</b> to switch your language.", player)
			elseif players_file[player] then
				local lang = string.lower(args[1])
				if translations[lang] then
					player_langs[player] = translations[lang]
					players_file[player].langue = lang
					translatedChatMessage("new_lang", player)
	
					savePlayerData(player)
				else
					tfm.exec.chatMessage("<v>[#] <r>Unknown language: <b>" .. lang .. "</b>", player)
				end
			end
			return
	
		elseif cmd == "forcestats" then -- logged
			if not perms[player] or not perms[player].force_stats then return end
	
			if records_admins then
				return tfm.exec.chatMessage("<v>[#] <r>you can't forcestats in a records room", player)
			end
	
			count_stats = true
			tfm.exec.chatMessage("<v>[#] <d>count_stats set to true", player)
			max_args = 0
	
		elseif cmd == "room" then -- logged
			if quantity == 0 or capitalize(args[1]) == player then
	            tfm.exec.chatMessage("<v>[#] <d>" .. room.name, player)
	            return
	        end
	
			if not perms[player] or not perms[player].get_player_room then return end
	
			local fetching = capitalize(args[1])
			if in_room[fetching] then
				tfm.exec.chatMessage("<v>[#] <d>" .. fetching .. " is here ._.", player)
				return
			end
	
			fetching_player_room[fetching] = { player, os.time() + 1000 }
			system.loadPlayerData(fetching)
			max_args = 1
	
		else
			return
		end
	
		logCommand(player, cmd, math.min(quantity, max_args), args)
	end)
	
	onEvent("ColorPicked", function(id, player, color)
		if not perms[player] or not perms[player].set_name_color then return end
		if color == -1 then return end
	
		for name, data in next, room.playerList do
			if data.id == id then
				local file = players_file[name]
				if not file then
					return tfm.exec.chatMessage("<v>[#] <r>" .. name .. " has left the room :(", player)
				end
				file.namecolor = color
	
				tfm.exec.chatMessage(
					string.format("<v>[#] <d>set name color of %s to <font color='#%06x'>#%06x</font>", name, color, color),
					player
				)
				setNameColor(name)
	
				savePlayerData(name)
	
				logCommand(player, string.format("give %s namecolor #%06x", name, color))
				return
			end
		end
	end)
	
	onEvent("RawTextAreaCallback", function(id, player, callback)
		if callback == "discord" then
			tfm.exec.chatMessage("<rose>" .. links.discord, player)
		elseif callback == "map_submission" then
			tfm.exec.chatMessage("<rose>" .. links.maps, player)
		elseif callback == "forum" then
			tfm.exec.chatMessage("<rose>" .. links.forum, player)
		elseif callback == "donate" then
			tfm.exec.chatMessage("<rose>" .. links.donation, player)
		elseif callback == "github" then
			tfm.exec.chatMessage("<rose>" .. links.github, player)
		end
	end)
	
	onEvent("ParsedTextAreaCallback", function(id, player, action, args)
		if action == "_help" then
			tfm.exec.chatMessage("<v>[#] <d>" .. translatedMessage("help_" .. args, player), player)
		elseif action == "msg" then
			tfm.exec.chatMessage("<j>" .. args, player)
		end
	end)
	
	onEvent("OutPlayerDataParsed", checkRoomRequest)
	
	onEvent("PlayerDataParsed", function(player, data)
		if data.langue and translations[data.langue] then
			player_langs[player] = translations[data.langue]
		end
	
		translatedChatMessage("welcome", player)
		tfm.exec.chatMessage("<rose>" .. links.discord, player)
		translatedChatMessage("forum_topic", player, links.forum)
		translatedChatMessage("donate", player)
	
		if is_before_anniversary then
			translatedChatMessage("anniversary", player)
		elseif is_anniversary then
			translatedChatMessage("anniversary_start", player)
		elseif is_after_anniversary then
			translatedChatMessage("anniversary_end", player)
		end
	
		checkRoomRequest(player, data)
	
		if records_admins then
			translatedChatMessage("records_enabled", player, links.records)
	
			if string.find(room.lowerName, string.lower(player), 1, true) then
				records_admins[player] = true
				translatedChatMessage("records_admin", player)
			end
		end
	end)
	
	onEvent("Loop", function()
		local now = os.time()
	
		local to_remove, count = {}, 0
		for player, data in next, fetching_player_room do
			if now >= data[2] then
				count = count + 1
				to_remove[count] = player
				tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n> is offline.", data[1])
			end
		end
	
		for idx = 1, count do
			fetching_player_room[to_remove[idx]] = nil
		end
	
		if now >= next_easter_egg then
			next_easter_egg = now + math.random(30, 60) * 60 * 1000
	
			if os.date("%d/%m/%Y", now + 60 * 60 * 1000) == "28/02/2021" then
				translatedChatMessage("easter_egg_" .. math.random(0, 13))
			end
		end
	end)
	
	onEvent("PacketReceived", function(channel, id, packet)
		if channel ~= "bots" then return end
	
		if id == 4 then -- !announce
			tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
		elseif id == 5 then -- !cannounce
			local commu, msg = string.match(packet, "^([^\000]+)\000(.+)$")
			if commu == room.community then
				tfm.exec.chatMessage("<vi>[" .. commu .. "] [#parkour] <d>" .. msg)
			end
		elseif id == 6 then -- pw request
			if packet == room.shortName then
				if roompw.password then
					sendPacket("common", 5, room.shortName .. "\000" .. roompw.password .. "\000" .. roompw.owner)
				else
					sendPacket("common", 5, room.shortName .. "\000")
				end
			end
		elseif id == 7 then -- remote room announcement
			local targetRoom, targetPlayer, msg = string.match(
				packet,
				"^([^\000]+)\000([^\000]+)\000(.+)$"
			)
			-- an announcement might target a room, a player or both
			if room.name == targetRoom then
				-- targets a room
				tfm.exec.chatMessage(msg)
	
			elseif players_file[targetPlayer] then
				-- targets a player (regardless of the room)
				tfm.exec.chatMessage(msg, targetPlayer)
			end
		end
	end)
	
	onEvent("GameStart", function()
		system.disableChatCommandDisplay("donate")
		system.disableChatCommandDisplay("discord")
		system.disableChatCommandDisplay("submit")
		system.disableChatCommandDisplay("pause")
		system.disableChatCommandDisplay("give")
		system.disableChatCommandDisplay("pw")
		system.disableChatCommandDisplay("roomlimit")
		system.disableChatCommandDisplay("langue")
		system.disableChatCommandDisplay("forcestats")
		system.disableChatCommandDisplay("room")
	end)
	
	if records_admins then
		onEvent("CantSendData", function(channel)
			if channel == "common" and fastest.wait_send then
				fastest.submitted = false
				fastest.wait_send = false
				tfm.exec.chatMessage(
					"<v>[#] <r>Your record couldn't be submitted. Type <b>!submit</b> again in a few minutes.",
					fastest.player
				)
			end
		end)
	
		onEvent("RetrySendData", function(channel)
			if channel == "common" and fastest.wait_send then
				tfm.exec.chatMessage(
					"<v>[#] <r>Failed to send your record. Retrying in a moment.",
					fastest.player
				)
			end
		end)
	
		onEvent("PacketSent", function(channel)
			if channel == "common" and fastest.wait_send then
				translatedChatMessage("records_submitted", fastest.player, room.currentMap)
				fastest.wait_send = false
			end
		end)
	end
	--[[ End of file modes/parkour/chat-ui.lua ]]--
	--[[ Directory modes/parkour/objects ]]--
	--[[ File modes/parkour/objects/Button.lua ]]--
	local Button
	do
		local callbacks = {}
		local lastId = -1
	
		Button = {}
		Button.__index = Button
	
		function Button.new()
			lastId = lastId + 1
			return setmetatable({
				callback = "component_button_" .. lastId
			}, Button)
		end
	
		function Button:setText(text)
			if type(text) == "function" then
				self.text_fnc = text
			else
				self.text_str = text .. "\n"
			end
			return self
		end
	
		function Button:setTranslation(translation)
			self.translation = translation
			return self
		end
	
		function Button:canUpdate(enabled)
			self.update = enabled
			return self
		end
	
		function Button:onClick(callback)
			self.clickCallback = callback
			return self
		end
	
		function Button:onUpdate(callback)
			self.updateCallback = callback
			return self
		end
	
		function Button:setPosition(x, y)
			self.x = x
			self.y = y
			return self
		end
	
		function Button:setSize(width, height)
			self.width = width
			self.height = height
			return self
		end
	
		function Button:asTemplate(interface)
			local enabled_prefix = "<a href='event:" .. self.callback .. "'><p align='center'>" 
			local disabled_prefix = "<p align='center'>"
			local textarea = {
				x = self.x, y = self.y,
				width = self.width, height = self.height,
	
				canUpdate = self.update,
				text = "",
				color = {0x314e57, 0x314e57, 1},
				onUpdate = self.updateCallback,
	
				enabled = {},
				disable = function(self, player)
					self.enabled[player] = false
					ui.addTextArea(
						self.id,
						self.text_str,
						player,
	
						self.x, self.y,
						self.width, self.height,
	
						0x2a424b, 0x2a424b, self.alpha,
						interface.fixed
					)
				end,
				enable = function(self, player)
					self.enabled[player] = true
					ui.addTextArea(
						self.id,
						self.text_str,
						player,
	
						self.x, self.y,
						self.width, self.height,
	
						self.background, self.border, self.alpha,
						interface.fixed
					)
				end
			}
			local text = {
				x = self.x, y = self.y,
				width = self.width, height = self.height + 2,
	
				canUpdate = self.update,
				text = function(txt, player, arg1, arg2, arg3, arg4)
					if textarea.enabled[player] == nil then
						textarea.enabled[player] = true
					end
	
					local prefix = textarea.enabled[player] and enabled_prefix or disabled_prefix
					if self.translation then
						return prefix .. translatedMessage(self.translation, player) .. "\n"
					elseif self.text_fnc then
						return prefix .. self.text_fnc(textarea, player, arg1, arg2, arg3, arg4) .. "\n"
					else
						return prefix .. self.text_str
					end
				end,
				alpha = 0,
	
				disable = function(self, player)
					return textarea:disable(player)
				end,
				enable = function(self, player)
					return textarea:enable(player)
				end
			}
			callbacks[self.callback] = {
				fnc = self.clickCallback,
				class = textarea
			}
	
			interface:addTextArea({
				x = self.x - 1, y = self.y - 1,
				width = self.width, height = self.height,
	
				canUpdate = self.update,
				color = {0x7a8d93, 0x7a8d93, 1}
			}):addTextArea({
				x = self.x + 1, y = self.y + 1,
				width = self.width, height = self.height,
	
				canUpdate = self.update,
				color = {0x0e1619, 0x0e1619, 1}
			}):addTextArea(textarea):addTextArea(text)
		end
	
		onEvent("TextAreaCallback", function(id, player, cb)
			local callback = callbacks[cb]
			if callback and callback.class.enabled and callback.class.parent.open[player] then
				callback.fnc(callback.class, player)
			end
		end)
	end
	--[[ End of file modes/parkour/objects/Button.lua ]]--
	--[[ File modes/parkour/objects/Interface.lua ]]--
	local Interface
	do
		local nextId = 0
		local all_interfaces = {}
	
		Interface = {}
		Interface.__index = Interface
	
		function Interface.new(x, y, width, height, fixed)
			local self = setmetatable({
				x = x, y = y,
				width = width, height = height,
				fixed = fixed,
	
				textarea_count = 0,
				textareas = {},
	
				image_count = 0,
				images = {},
	
				args = {},
				defaultArgs = {},
	
				open = {},
	
				elements = {},
	
				updateCallback = nil,
				removeCallback = nil,
				showCheck = nil,
	
				checkArguments = false
			}, Interface)
			all_interfaces[#all_interfaces + 1] = self
			return self
		end
	
		function Interface:setShowCheck(callback)
			self.showCheck = callback
			return self
		end
	
		function Interface:setDefaultArgs(...)
			self.defaultArgs = {...}
			return self
		end
	
		function Interface:avoidDoubleUpdates()
			self.checkArguments = true
			return self
		end
	
		function Interface:loadTemplate(template)
			template(self)
			return self
		end
	
		function Interface:loadComponent(component)
			component:asTemplate(self)
			return self
		end
	
		function Interface:onUpdate(callback)
			self.updateCallback = callback
			return self
		end
	
		function Interface:onRemove(callback)
			self.removeCallback = callback
			return self
		end
	
		function Interface:addTextArea(data)
			if data.name then
				self.elements[data.name] = data
			end
	
			data.id = nextId
			nextId = nextId + 1
	
			data.parent = self
			data.x = (data.x or 0) + self.x
			data.y = (data.y or 0) + self.y
			data.width = data.width or self.width
			data.height = data.height or self.height
	
			if not data.text then
				data.text_str = ""
			elseif type(data.text) == "function" then
				data.text_fnc = data.text
			else
				data.text_str = tostring(data.text)
			end
	
			if data.color then
				data.background = data.color[1]
				data.border = data.color[2]
				data.alpha = data.color[3]
			end
	
			self.textarea_count = self.textarea_count + 1
			self.textareas[self.textarea_count] = data
	
			return self
		end
	
		function Interface:addImage(data)
			if data.name then
				self.elements[data.name] = data
			end
	
			data.players = {}
	
			data.parent = self
			data.x = (data.x or 0) + self.x
			data.y = (data.y or 0) + self.y
	
			assert(data.image, "an image should have the image id")
			assert(data.target, "an image should have the image target")
	
			if type(data.image) == "function" then
				data.image_fnc = data.image
			else
				data.image_str = data.image
			end
			if type(data.target) == "function" then
				data.target_fnc = data.target
			else
				data.target_str = data.target
			end
	
			self.image_count = self.image_count + 1
			self.images[self.image_count] = data
	
			return self
		end
	
		function Interface:showDefault(player)
			return self:show(player, self.defaultArgs[1], self.defaultArgs[2], self.defaultArgs[3], self.defaultArgs[4])
		end
	
		function Interface:show(player, arg1, arg2, arg3, arg4)
			if self.showCheck and not self:showCheck(player, arg1, arg2, arg3, arg4) then return end
			if self.open[player] then return end
	
			local args
			if self.args[player] then
				args = self.args[player]
			else
				args = {}
				self.args[player] = args
			end
			args[1] = arg1
			args[2] = arg2
			args[3] = arg3
			args[4] = arg4
	
			local data
			for index = 1, self.textarea_count do
				data = self.textareas[index]
	
				ui.addTextArea(
					data.id,
	
					data.translation and translatedMessage(data.translation, player) or
					data.text_str and data.text_str or
					data:text_fnc(player, arg1, arg2, arg3, arg4),
	
					player,
	
					data.x, data.y,
					data.width, data.height,
	
					data.background, data.border, data.alpha,
	
					self.fixed
				)
	
				if data.onUpdate then
					data:onUpdate(player, arg1, arg2, arg3, arg4)
				end
			end
	
			for index = 1, self.image_count do
				data = self.images[index]
	
				if data.players[player] then
					tfm.exec.removeImage(data.players[player])
				end
	
				data.players[player] = tfm.exec.addImage(
					data.image_str and data.image_str or
					data:image_fnc(player, arg1, arg2, arg3, arg4),
	
					data.target_str and data.target_str or
					data:target_fnc(player, arg1, arg2, arg3, arg4),
	
					data.x, data.y,
					player
				)
	
				if data.onUpdate then
					data:onUpdate(player, arg1, arg2, arg3, arg4)
				end
			end
	
			if self.updateCallback then
				self:updateCallback(player, arg1, arg2, arg3, arg4)
			end
			self.open[player] = true
			-- it is at the end to let updateCallback know if it is an update or a show
		end
	
		function Interface:update(player, arg1, arg2, arg3, arg4)
			if not self.open[player] then return end
	
			local args = self.args[player]
			if self.checkArguments then
				if args[1] == arg1 and args[2] == arg2 and args[3] == arg3 and args[4] == arg4 then
					return
				end
			end
			args[1] = arg1
			args[2] = arg2
			args[3] = arg3
			args[4] = arg4
	
			local data
			for index = 1, self.textarea_count do
				data = self.textareas[index]
	
				if data.canUpdate then
					ui.updateTextArea(
						data.id,
	
						data.translation and translatedMessage(data.translation, player) or
						data.text_str and data.text_str or
						data:text_fnc(player, arg1, arg2, arg3, arg4),
	
						player
					)
	
					if data.onUpdate then
						data:onUpdate(player, arg1, arg2, arg3, arg4)
					end
				end
			end
	
			for index = 1, self.image_count do
				data = self.images[index]
	
				if data.canUpdate then
					if data.players[player] then
						tfm.exec.removeImage(data.players[player])
					end
	
					data.players[player] = tfm.exec.addImage(
						data.image_str and data.image_str or
						data:image_fnc(player, arg1, arg2, arg3, arg4),
	
						data.target_str and data.target_str or
						data:target_fnc(player, arg1, arg2, arg3, arg4),
	
						data.x, data.y,
						player
					)
	
					if data.onUpdate then
						data:onUpdate(player, arg1, arg2, arg3, arg4)
					end
				end
			end
	
			if self.updateCallback then
				self:updateCallback(player, arg1, arg2, arg3, arg4)
			end
		end
	
		function Interface:remove(player)
			self.open[player] = nil
	
			for index = 1, self.textarea_count do
				ui.removeTextArea(self.textareas[index].id, player)
			end
	
			local data
			for index = 1, self.image_count do
				data = self.images[index].players
	
				if data[player] then
					tfm.exec.removeImage(data[player])
					data[player] = nil
				end
			end
	
			if self.removeCallback then
				self:removeCallback(player)
			end
		end
	
		onEvent("PlayerLeft", function(player)
			for index = 1, #all_interfaces do
				all_interfaces[index].open[player] = nil
			end
		end)
	end
	--[[ End of file modes/parkour/objects/Interface.lua ]]--
	--[[ File modes/parkour/objects/Toggle.lua ]]--
	local Toggle
	do
		local callbacks = {}
		local lastId = -1
	
		Toggle = {}
		Toggle.__index = Toggle
	
		function Toggle.new(x, y, default, name)
			lastId = lastId + 1
			return setmetatable({
				x = x,
				y = y,
				default = default,
	
				name = name,
	
				toggleCallback = nil,
				updateCallback = nil,
				callback = "component_toggle_" .. lastId
			}, Toggle)
		end
	
		function Toggle:onToggle(callback)
			self.toggleCallback = callback
			return self
		end
	
		function Toggle:onUpdate(callback)
			self.updateCallback = callback
			return self
		end
	
		function Toggle:asTemplate(interface)
			local click = {
				x = self.x - 7, y = self.y - 7,
				width = 30, height = 20,
				text = "<a href='event:" .. self.callback .. "'>\n\n\n",
				alpha = 0
			}
			local switch = {
				name = self.name,
				default = self.default,
	
				y = self.y + 3,
				width = 1, height = 1,
	
				state = {},
				toggle = function(txt, player)
					local states = txt.state
					if states[player] == nil then
						states[player] = self.default
					end
					states[player] = not states[player]
	
					txt:checkState(player)
				end,
				onToggle = function(txt, player)
					txt:toggle(player)
	
					if self.toggleCallback then
						self.toggleCallback(txt, player, txt.state[player])
					end
				end,
				checkState = function(txt, player)
					local states = txt.state
	
					if states[player] then -- on
						ui.addTextArea(
							txt.id, "", player,
							interface.x + self.x + 16, txt.y,
							txt.width, txt.height,
							0x9bc346, 0x9bc346, 1,
							interface.fixed
						)
					else
						ui.addTextArea(
							txt.id, "", player,
							interface.x + self.x + 3, txt.y,
							txt.width, txt.height,
							0xb84c36, 0xb84c36, 1,
							interface.fixed
						)
					end
	
					ui.updateTextArea(click.id, click.text, player)
				end,
				onUpdate = function(txt, player)
					txt:checkState(player)
					if self.updateCallback then
						self.updateCallback(txt, player)
					end
				end
			}
			callbacks[self.callback] = {
				fnc = switch.onToggle,
				class = switch
			}
	
			if self.default then -- on
				switch.x = self.x + 16
				switch.color = {0x9bc346, 0x9bc346, 1}
			else -- off
				switch.x = self.x + 3
				switch.color = {0xb84c36, 0xb84c36, 1}
			end
	
			interface:addTextArea({
				x = self.x, y = self.y,
				width = 20, height = 7,
				color = {0x232a35, 0x232a35, 1}
			}):addTextArea(switch):addTextArea(click)
		end
	
		onEvent("TextAreaCallback", function(id, player, cb)
			local callback = callbacks[cb]
			if callback and callback.class.parent.open[player] then
				if not checkCooldown(player, "simpleToggle", 500) then return end
	
				callback.fnc(callback.class, player)
			end
		end)
	end
	--[[ End of file modes/parkour/objects/Toggle.lua ]]--
	--[[ File modes/parkour/objects/WindowBackground.lua ]]--
	local WindowBackground = function(self)
		self:addTextArea({
			color = {0x78462b, 0x78462b, 1}
		}):addTextArea({
			y = self.height / 4,
			height = self.height / 2,
			color = {0x9d7043, 0x9d7043, 1}
		}):addTextArea({
			x = self.width / 4,
			width = self.width / 2,
			color = {0x9d7043, 0x9d7043, 1}
		}):addTextArea({
			width = 20, height = 20,
			color = {0xbeb17d, 0xbeb17d, 1}
		}):addTextArea({
			x = self.width - 20,
			width = 20, height = 20,
			color = {0xbeb17d, 0xbeb17d, 1}
		}):addTextArea({
			y = self.height - 20,
			width = 20, height = 20,
			color = {0xbeb17d, 0xbeb17d, 1}
		}):addTextArea({
			x = self.width - 20,
			y = self.height - 20,
			width = 20, height = 20,
			color = {0xbeb17d, 0xbeb17d, 1}
		}):addTextArea({
			x = 3, y = 3,
			width = self.width - 6, height = self.height - 6,
			color = {0x1c3a3e, 0x232a35, 1}
		})
	end
	--[[ End of file modes/parkour/objects/WindowBackground.lua ]]--
	--[[ End of directory modes/parkour/objects ]]--
	--[[ Directory modes/parkour/interfaces/requirements ]]--
	--[[ File modes/parkour/interfaces/requirements/keyboard.lua ]]--
	keyboard = {}
	local Keyboard
	do
		local selection = {}
		keyboard.keys = {
			[1] = {
				"|", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BACKSPACE"
			},
	
			[2] = {
				"Tab",
				{"A", "Q"},
				{"Z", "W"},
				"E", "R", "T", "Y", "U", "I", "O", "P",
				{"^", "["},
				{"$", "]"}
			},
	
			[3] = {
				"Caps\nLock",
				{"Q", "A"},
				"S", "D", "F", "G", "H", "J", "K", "L",
				{"M", ";"},
				{"%", "'"},
				{"*", "\\"}
			},
	
			[4] = {
				"Shift", ">",
				{"W", "Z"},
				"X", "C", "V", "B", "N",
				{"?", "M"},
				{".", ","},
				{"/", "."},
				{"!", "/"},
				"RShift"
			},
	
			[5] = {
				"Ctrl", "LWin", "Alt", "SPACE", "Alt Gr", "RWin", "OPT", "RCtrl"
			}
		}
		keyboard.bindings = {
			BACKSPACE = 8, [8] = "BACKSPACE",
			Tab = 9, [9] = "Tab",
			Shift = 16, [16] = "Shift",
			Ctrl = 17, [17] = "Ctrl",
			Alt = 18, [18] = "Alt",
			["Caps\nLock"] = 20, [20] = "Caps\nLock",
			SPACE = 32, [32] = "SPACE",
			["0"] = 48, [48] = "0",
			["1"] = 49, [49] = "1",
			["2"] = 50, [50] = "2",
			["3"] = 51, [51] = "3",
			["4"] = 52, [52] = "4",
			["5"] = 53, [53] = "5",
			["6"] = 54, [54] = "6",
			["7"] = 55, [55] = "7",
			["8"] = 56, [56] = "8",
			["9"] = 57, [57] = "9",
			A = 65, [65] = "A",
			B = 66, [66] = "B",
			C = 67, [67] = "C",
			D = 68, [68] = "D",
			E = 69, [69] = "E",
			F = 70, [70] = "F",
			G = 71, [71] = "G",
			H = 72, [72] = "H",
			I = 73, [73] = "I",
			J = 74, [74] = "J",
			K = 75, [75] = "K",
			L = 76, [76] = "L",
			M = 77, [77] = "M",
			N = 78, [78] = "N",
			O = 79, [79] = "O",
			P = 80, [80] = "P",
			Q = 81, [81] = "Q",
			R = 82, [82] = "R",
			S = 83, [83] = "S",
			T = 84, [84] = "T",
			U = 85, [85] = "U",
			V = 86, [86] = "V",
			W = 87, [87] = "W",
			X = 88, [88] = "X",
			Y = 89, [89] = "Y",
			Z = 90, [90] = "Z",
			LWin = 91, [91] = "LWin",
			RWin = 92, [92] = "RWin",
			[";"] = 186, [186] = ";",
			[","] = 188, [188] = ",",
			["."] = 190, [190] = ".",
			["/"] = 191, [191] = "/",
			["["] = 219, [219] = "[",
			["\\"] = 220, [220] = "\\",
			["]"] = 221, [221] = "]",
			["'"] = 222, [222] = "'"
		}
	
		Keyboard = Interface.new(65, 170, 665, 215, true)
			:addTextArea({
				name = "enter_key",
	
				x = 610, y = 45,
				width = 55, height = 80,
	
				text = "<a href='event:keyboard:enter'>ENTER\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
	
				border = 0x1c3a3e
			})
			:addTextArea({
				x = 587, y = 88,
				width = 35, height = 37,
	
				color = {0x1c3a3e, 0x1c3a3e, 1}
			})
	
			-- Layer 1
			:addTextArea({
				x = 0, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 45, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 90, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 135, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 180, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 225, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 270, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 315, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 360, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 405, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 450, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 495, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 540, y = 0,
				width = 35, height = 35
			})
			:addTextArea({
				x = 585, y = 0,
				width = 80, height = 35
			})
	
			-- Layer 2
			:addTextArea({
				x = 0, y = 45,
				width = 60, height = 35
			})
			:addTextArea({
				x = 70, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 115, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 160, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 205, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 250, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 295, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 340, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 385, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 430, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 475, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 520, y = 45,
				width = 35, height = 35
			})
			:addTextArea({
				x = 565, y = 45,
				width = 35, height = 35
			})
	
			-- Layer 3
			:addTextArea({
				x = 0, y = 90,
				width = 80, height = 35
			})
			:addTextArea({
				x = 90, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 135, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 180, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 225, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 270, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 315, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 360, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 405, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 450, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 495, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 540, y = 90,
				width = 35, height = 35
			})
			:addTextArea({
				x = 585, y = 90,
				width = 35, height = 35
			})
	
			-- Layer 4
			:addTextArea({
				x = 0, y = 135,
				width = 45, height = 35
			})
			:addTextArea({
				x = 55, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 100, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 145, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 190, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 235, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 280, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 325, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 370, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 415, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 460, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 505, y = 135,
				width = 35, height = 35
			})
			:addTextArea({
				x = 550, y = 135,
				width = 115, height = 35
			})
	
			-- Layer 5
			:addTextArea({
				x = 0, y = 180,
				width = 65, height = 35
			})
			:addTextArea({
				x = 75, y = 180,
				width = 45, height = 35
			})
			:addTextArea({
				x = 130, y = 180,
				width = 45, height = 35
			})
			:addTextArea({
				x = 185, y = 180,
				width = 240, height = 35
			})
			:addTextArea({
				x = 435, y = 180,
				width = 45, height = 35
			})
			:addTextArea({
				x = 490, y = 180,
				width = 45, height = 35
			})
			:addTextArea({
				x = 545, y = 180,
				width = 45, height = 35
			})
			:addTextArea({
				x = 600, y = 180,
				width = 65, height = 35
			})
			:onUpdate(function(self, player, qwerty, numkey, keyname)
				local txt
				if selection[player] then
					txt = selection[player]
					ui.addTextArea(
						txt.id,
						txt.text_str and txt.text_str or
						txt:text_fnc(player, qwerty),
						player,
						txt.x, txt.y,
						txt.width, txt.height,
						txt.background, txt.border, txt.alpha,
						true
					)
					selection[player] = nil
				end
	
				if numkey then
					local text_id = self.elements.enter_key.id + numkey
	
					for index = 1, self.textarea_count do
						txt = self.textareas[index]
						if txt.id == text_id then
							selection[player] = txt
							break
						end
					end
				elseif keyname then
					for index = 1, self.textarea_count do
						txt = self.textareas[index]
						if txt.key == keyname then
							selection[player] = txt
							break
						end
					end
				end
	
				if not selection[player] then return end
	
				ui.addTextArea(
					txt.id,
					txt.text_str and txt.text_str or
					txt:text_fnc(player, qwerty),
					player,
					txt.x, txt.y,
					txt.width, txt.height,
					0x232a35, 0x1c3a3e, 1,
					true
				)
			end)
	
		local newlines = string.rep("\n", 10)
		local key = 2
		local txt
		for i = 1, #keyboard.keys do
			for j = 1, #keyboard.keys[i] do
				key = key + 1
				txt = Keyboard.textareas[key]
	
				txt.border = 0x1c3a3e
	
				if keyboard.keys[i][j][1] then -- variation
					txt.canUpdate = true
					txt.text_str = nil
	
					txt.text_fnc = function(self, player, qwerty)
						self.key = keyboard.keys[i][j][qwerty and 2 or 1]
						return "<a href=\"event:keyboard:" .. self.key .. "\">" .. self.key .. newlines
					end
				else
					txt.key = keyboard.keys[i][j]
					txt.text_str = "<a href=\"event:keyboard:" .. txt.key .. "\">" .. txt.key .. newlines
				end
			end
		end
	end
	--[[ End of file modes/parkour/interfaces/requirements/keyboard.lua ]]--
	--[[ End of directory modes/parkour/interfaces/requirements ]]--
	--[[ Directory modes/parkour/interfaces ]]--
	--[[ File modes/parkour/interfaces/afk.lua ]]--
	AfkInterface = Interface.new(100, 50, 600, 300, true)
		:loadTemplate(WindowBackground)
		:addTextArea({
			x = 0, y = 0,
			width = 600, height = 300,
			alpha = 0,
			translation = "afk_popup"
		})
	--[[ End of file modes/parkour/interfaces/afk.lua ]]--
	--[[ File modes/parkour/interfaces/completedquest.lua ]]--
	do
		CompletedQuestsInterface = Interface.new(480, 350, 300, 40, true)
			:loadTemplate(WindowBackground)
	        :setShowCheck(function(self, player, isWeekly, data)
				if not data then
					return false
				end
				return true
			end)
	
			:addImage({
	            image = "18b29f6977c.png",
				target = "~9",
				x = 10, y = 0
			})
	
	        :addTextArea({
	            x = 10, y = 26,
	            width = 30, height = 20,
	            alpha = 0,
	            canUpdate = true,
	            text = function(self, player, isWeekly, data)
	                return string.format("<p align='center'><b>%s</b></p>", data)
	            end
	        })
	
	        :addTextArea({
	            x = 50, y = 4,
	            width = 250, height = 40,
	            alpha = 0,
	            canUpdate = true,
	            text = function(self, player, isWeekly, data)
	                local text = isWeekly and translatedMessage("weekly_q", player) or translatedMessage("daily_q", player)
	                text = text:lower()
	
	                return translatedMessage("quest_completed", player, text)
	            end
	        })
	end
	--[[ End of file modes/parkour/interfaces/completedquest.lua ]]--
	--[[ File modes/parkour/interfaces/game.lua ]]--
	do
		local settings_img = "1713705576b.png"
		local powers_img = "17136ef539e.png"
		local help_img = "17136f9eefd.png"
		local shop_img = "18b597a932a.png"
		local quests_img = "18c3b94e9a4.png"
	
		GameInterface = Interface.new(0, 0, 800, 400, true)
			:addImage({
				image = settings_img,
				target = ":1",
				x = 772, y = 32
			})
			:addTextArea({
				text = "<a href='event:settings'><font size='50'>  </font></a>",
				x = 767, y = 32,
				height = 30, width = 32,
				alpha = 0
			})
	
			:addImage({
				image = shop_img,
				target = ":1",
				x = 744, y = 32
			})
	
			:addTextArea({
				text = "<a href='event:shop_button'><font size='50'>  </font></a>",
				x = 739, y = 32,
				height = 30, width = 32,
				alpha = 0
			})
	
			:addImage({
				image = quests_img,
				target = ":1",
				x = 714, y = 32
			})
	
			:addTextArea({
				text = "<a href='event:quests_button'><font size='50'>  </font></a>",
				x = 709, y = 32,
				height = 30, width = 32,
				alpha = 0
			})
	
			:addImage({
				canUpdate = true,
				image = function(self, player)
					local file = players_file[player]
					if file then
						if file.settings[4] == 1 then
							return powers_img
						end
						if file.settings[6] == 1 then
							return help_img
						end
					end
					return "a.png"
				end,
				target = ":1",
				x = 684, y = 32
			})
			:addTextArea({
				canUpdate = true,
				text = function(self, player)
					local file = players_file[player]
					if file then
						if file.settings[4] == 1 then
							return "<a href='event:powers'><font size='50'>  </font></a>"
						end
						if file.settings[6] == 1 then
							return "<a href='event:help_button'><font size='50'>  </font></a>"
						end
					end
					return ""
				end,
				x = 679, y = 32,
				height = 30, width = 32,
				alpha = 0
			})
	
			:addImage({
				canUpdate = true,
				image = function(self, player)
					local file = players_file[player]
					if file and file.settings[4] == 1 and file.settings[6] == 1 then
						return help_img
					else
						return "a.png"
					end
				end,
				target = ":1",
				x = 654, y = 32
			})
			:addTextArea({
				canUpdate = true,
				text = function(self, player)
					local file = players_file[player]
					if file.settings[4] == 1 and file.settings[6] == 1 then
						return "<a href='event:help_button'><font size='50'>  </font></a>"
					else
						return ""
					end
				end,
				x = 649, y = 32,
				height = 30, width = 32,
				alpha = 0
			})
	end
	--[[ End of file modes/parkour/interfaces/game.lua ]]--
	--[[ File modes/parkour/interfaces/help.lua ]]--
	local HelpInterface
	do
		local texts = { -- name, max chars
			{"help", nil},
			{"staff", 700},
			{"rules", 800},
			{"contribute", nil},
			{"changelog", nil}
		}
		local extra_chars = {
			ru = 250,
			he = 250
		}
		local page_info = {}
		local scroll_info = {}
		local images = {}
	
		for lang, translation in next, translations do
			page_info[ lang ] = {}
	
			for index = 1, #texts do
				local info = texts[index]
				local text = translation["help_" .. info[1]]
				local data = {}
	
				if #text > 1100 and info[2] then
					text = "\n" .. text
	
					local breakpoint = info[2] + (extra_chars[lang] or 0)
	
					for slice = 1, #text, breakpoint do
						local page = string.sub(text, slice, slice + 1999)
						local newline = string.find(page, "\n")
	
						if newline then
							repeat
								newline = newline + 1
							until string.find(page, "\n", newline) ~= 1
	
							page = string.sub(page, newline)
							data[(slice - 1) / breakpoint + 1] = page
						else
							break
						end
					end
	
					if not data[2] then
						data = data[1]
					end
				else
					data = text
				end
	
				if data[1] then
					data.scrollable = true
				end
				page_info[ lang ][ info[1] ] = data
			end
		end
	
		local closeButton = Button.new()
		HelpInterface = Interface.new(100, 50, 600, 330, true)
			:setDefaultArgs("help")
			:loadTemplate(WindowBackground)
	
			:onUpdate(function(self, player)
				if not self.open[player] then -- first update (show)
					bindKeyboard(player, 1, true, true)
					bindKeyboard(player, 3, true, true)
					scroll_info[player] = 1
				end
			end)
			:onRemove(function(self, player)
				bindKeyboard(player, 1, true, false)
				bindKeyboard(player, 3, true, false)
				scroll_info[player] = nil
	
				if images[player] then
					for i = 1, 2 do
						tfm.exec.removeImage(images[player][i])
					end
					images[player] = nil
				end
			end)
	
			-- Close button
			:loadComponent(
				closeButton:setText("")
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
				:setPosition(60, 312):setSize(480, 10)
			)
			:addTextArea({
				x = 60, y = 308,
				width = 480, height = 15,
				text = function(self, player)
					return ("<a href='event:" .. closeButton.callback ..
							"'><p align='center'>" .. translatedMessage("close", player) ..
							"\n")
				end,
				alpha = 0
			})
	
			-- Tabs
			:loadComponent( -- Help
				Button.new():setTranslation("help")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "helpbuttons", 1500) then return end
					scroll_info[player] = 1
					self.parent:update(player, "help")
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == "help" then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(60, 10):setSize(80, 18)
			)
			:loadComponent( -- Staff
				Button.new():setTranslation("staff")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "helpbuttons", 1500) then return end
					scroll_info[player] = 1
					self.parent:update(player, "staff")
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == "staff" then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(160, 10):setSize(80, 18)
			)
			:loadComponent( -- Rules
				Button.new():setTranslation("rules")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "helpbuttons", 1500) then return end
					scroll_info[player] = 1
					self.parent:update(player, "rules")
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == "rules" then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(260, 10):setSize(80, 18)
			)
			:loadComponent( -- Contribute
				Button.new():setTranslation("contribute")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "helpbuttons", 1500) then return end
					scroll_info[player] = 1
					self.parent:update(player, "contribute")
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == "contribute" then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(360, 10):setSize(80, 18)
			)
			:loadComponent( -- Changelog
				Button.new():setTranslation("changelog")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "helpbuttons", 1500) then return end
					scroll_info[player] = 1
					self.parent:update(player, "changelog")
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == "changelog" then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(460, 10):setSize(80, 18)
			)
	
			:addTextArea({
				x = 0, y = 35,
				width = 0, height = 270,
				canUpdate = true,
				text = function(self, player, page)
					local info = page_info[ player_langs[player].name ][ page ]
					local img = images[player]
					local parent = self.parent
	
					if info.scrollable then
						if not img then
							img = {
								[1] = tfm.exec.addImage(
									"1719e0e550a.png", "&1",
									HelpInterface.x + 585,
									HelpInterface.y + 40,
									player
								) -- scroll frame
							}
							images[player] = img
						end
	
						local scroll = scroll_info[player]
	
						if img[2] then
							tfm.exec.removeImage(img[2])
						end
						img[2] = tfm.exec.addImage(
							"1719e173ac6.png", "&1",
							HelpInterface.x + 585,
							HelpInterface.y + 40 + (125 / (#info - 1)) * (scroll - 1),
							player
						)
	
						local desiredWidth = 570
						if self.width ~= desiredWidth then
							self.width = desiredWidth
							ui.addTextArea(
								self.id, "", player,
								self.x, self.y, self.width, self.height,
								self.background, self.border, self.alpha,
								parent.fixed
							)
	
							local txt
							for index = 1, parent.textarea_count do
								txt = parent.textareas[index]
	
								if txt.isScrollArrow then
									txt.text_str = txt.text
								end
							end
						end
	
						return info[scroll]
					end
	
					if img then
						for i = 1, 2 do
							tfm.exec.removeImage(img[i])
						end
						images[player] = nil
					end
	
					local desiredWidth = 600
					if self.width ~= desiredWidth then
						self.width = desiredWidth
						ui.addTextArea(
							self.id, "", player,
							self.x, self.y, self.width, self.height,
							self.background, self.border, self.alpha,
							parent.fixed
						)
	
						local txt
						for index = 1, parent.textarea_count do
							txt = parent.textareas[index]
	
							if txt.isScrollArrow then
								txt.text_str = ""
							end
						end
					end
	
					return info
				end,
				alpha = 0
			})
	
			-- Scroll buttons
			:addTextArea({
				isScrollArrow = true,
	
				canUpdate = true,
				x = 580, y = 15,
				width = 20, height = 20,
				text = "<a href='event:help_scroll_up'>/\\",
				alpha = 0
			})
			:addTextArea({
				isScrollArrow = true,
	
				canUpdate = true,
				x = 580, y = 295,
				width = 20, height = 20,
				text = "<a href='event:help_scroll_down'>\\/\n",
				alpha = 0
			})
	
		onEvent("TextAreaCallback", function(id, player, cb)
			if not checkCooldown(player, "helpscroll", 4000) then return end
			if cb == "help_scroll_up" then
				eventKeyboard(player, 1, true, 0, 0)
			elseif cb == "help_scroll_down" then
				eventKeyboard(player, 3, true, 0, 0)
			end
		end)
	
		onEvent("Keyboard", function(player, key, down)
			if not checkCooldown(player, "helpscroll", 4000) then return end
			if key ~= 1 and key ~= 3 then return end
			if not down then return end
			if not HelpInterface.open[player] then return end
	
			local page = HelpInterface.args[player][1]
			local info = page_info[ player_langs[player].name ][ page ]
			if not info.scrollable then return end
	
			if key == 1 then -- up
				scroll_info[player] = math.max(scroll_info[player] - 1, 1)
			else -- down
				scroll_info[player] = math.min(scroll_info[player] + 1, #info)
			end
			HelpInterface:update(player, page)
		end)
	end
	--[[ End of file modes/parkour/interfaces/help.lua ]]--
	--[[ File modes/parkour/interfaces/leaderboard.lua ]]--
	local LeaderboardInterface
	do
		local community_images = {}
		local communities = {
			xx = "1651b327097.png",
			ar = "1651b32290a.png",
			bg = "1651b300203.png",
			br = "1651b3019c0.png",
			cn = "1651b3031bf.png",
			cz = "1651b304972.png",
			de = "1651b306152.png",
			ee = "1651b307973.png",
			en = "1723dc10ec2.png",
			e2 = "1723dc10ec2.png",
			es = "1651b309222.png",
			fi = "1651b30aa94.png",
			fr = "1651b30c284.png",
			gb = "1651b30da90.png",
			hr = "1651b30f25d.png",
			hu = "1651b310a3b.png",
			id = "1651b3121ec.png",
			he = "1651b3139ed.png",
			it = "1651b3151ac.png",
			jp = "1651b31696a.png",
			lt = "1651b31811c.png",
			lv = "1651b319906.png",
			nl = "1651b31b0dc.png",
			ph = "1651b31c891.png",
			pl = "1651b31e0cf.png",
			pt = "17459ce7e29.png",
			ro = "1651b31f950.png",
			ru = "1651b321113.png",
			tr = "1651b3240e8.png",
			vk = "1651b3258b3.png"
		}
		local separator = string.rep("¯", 50)
	
		LeaderboardInterface = Interface.new(168, 46, 465, 330, true)
			:avoidDoubleUpdates()
			:loadTemplate(WindowBackground)
			:setShowCheck(function(self, player, data, page, weekly)
				if not loaded_leaderboard then
					translatedChatMessage("leaderboard_not_loaded", player)
					return false
				end
				if not data then
					self:show(player, leaderboard, 0, 2)
					return false
				end
				return true
			end)
	
			-- Titles
			:addTextArea({
				text = function(self, player)
					return string.format(
						"<p align='center'><font size='28'><B><D>%s</D></B></font>\n<font color='#32585E'>%s</font></p>",
						translatedMessage("leaderboard", player),
						separator
					)
				end,
				alpha = 0
			}):addTextArea({
				x = 12, y = 54,
				width = 50, height = 20,
				translation = "position",
				alpha = 0
			}):addTextArea({
				x = 78, y = 54,
				width = 176, height = 20,
				translation = "username",
				alpha = 0
			}):addTextArea({
				x = 267, y = 54,
				width = 70, height = 20,
				translation = "community",
				alpha = 0
			}):addTextArea({
				x = 350, y = 54,
				width = 105, height = 20,
				canUpdate = true,
				text = function(self, player, data, page, weekly)
	
					if weekly == 3 then
						return translatedMessage("time", player)
					else
						return translatedMessage("completed", player)
					end
				end,
				alpha = 0
			})
	
			-- Position
			:addTextArea({
				x = 15, y = 84,
				width = 50, height = 200,
	
				canUpdate = true,
				text = function(self, player, data, page, weekly)
					local positions = {}
					for index = 1, 14 do
						positions[index] = 14 * page + index
					end
					return "<font size='12'><p align='center'><v>#" .. table.concat(positions, "\n#")
				end,
				color = {0x203F43, 0x193E46, 1}
			})
	
			-- Player names
			:addTextArea({
				x = 78, y = 84,
				width = 176, height = 200,
	
				canUpdate = true,
				text = function(self, player, data, page, weekly)
					local names = {}
					local row, name, unknown
					for index = 1, 14 do
						row = data[14 * page + index]
	
						if not row then
							if not unknown then
								unknown = translatedMessage("unknown", player)
							end
							names[index] = unknown
						else
							names[index] = row[2]
						end
					end
	
					if page == 0 then
						names[1] = "<cs>" .. names[1] .. "</cs>"
						names[2] = "<n>" .. names[2] .. "</n>"
						names[3] = "<ce>" .. names[3] .. "</ce>"
					end
	
					return "<font size='12'><p align='center'><t>" .. table.concat(names, "\n")
				end,
				color = {0x203F43, 0x193E46, 1}
			})
	
			-- Community
			:addTextArea({
				x = 267, y = 84,
				width = 70, height = 200,
				color = {0x203F43, 0x193E46, 1}
			}):onUpdate(function(self, player, data, page, weekly)
				if not community_images[player] then
					community_images[player] = {}
				else
					for index = 1, 14 do
						tfm.exec.removeImage(community_images[player][index])
					end
				end
	
				local x = self.x + 292
				local nextY = self.y + 88
				local row, image
				for index = 1, 14 do
					row = data[14 * page + index]
	
					if not row then
						image = communities.xx
					else
						image = communities[row[4]] or communities.xx
					end
	
					community_images[player][index] = tfm.exec.addImage(image, "&1", x, nextY, player)
					nextY = nextY + 14
				end
			end):onRemove(function(self, player)
				for index = 1, 14 do
					tfm.exec.removeImage(community_images[player][index])
				end
			end)
			
			-- Map count
			:addTextArea({
				x = 350, y = 84,
				width = 100, height = 200,
	
				canUpdate = true,
				text = function(self, player, data, page, weekly)
					local maps = {}
					for index = 1, 14 do
						row = data[14 * page + index]
	
						if not row then
							maps[index] = 0
						else
							maps[index] = row[3]
						end
					end
					return "<font size='12'><p align='center'><vp>" .. table.concat(maps, "\n")
				end,
				color = {0x203F43, 0x193E46, 1}
			})
	
			:addTextArea({
				text = "<a href='event:leaderboard_button'><font color='#b84c36' size='15'><b>X</b></font></a>",
				alpha = 0,
				x = 440, y = 5,
				width = 20, height = 20
			})
	
			-- Pagination buttons
			:loadComponent( -- Left arrow
				Button.new():setText("&lt;")
	
				:onClick(function(self, player)
					local args = self.parent.args[player]
					self.parent:update(player, args[1], math.max(args[2] - 1, 0), args[3])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, data, page)
					if page == 0 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(17, 300):setSize(40, 20)
			):loadComponent( -- Right arrow
				Button.new():setText("&gt;")
	
				:onClick(function(self, player, data, page, weekly)
					local args = self.parent.args[player]
					-- args[3] = weekly, args[2] = page, args[1] = data
					self.parent:update(player, args[1], math.min(args[2] + 1, args[3] == 1 and 1 or args[3] == 2 and 4 or args[3] == 3 and 0), args[3])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
					if (page == 1 and weekly == 1) or (page == 4 and weekly == 2) or (page == 0 and weekly == 3) then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(412, 300):setSize(40, 20)
			)
	
			-- Leaderboard type
			:loadComponent( -- Overall button
				Button.new():setTranslation("overall_lb")
	
				:onClick(function(self, player)
					local args = self.parent.args[player]
					self.parent:update(player, leaderboard, 0, 2)
				end):canUpdate(true)
				:onUpdate(function(self, player, data, page, weekly)
					if weekly == 2 then
						self:disable(player)
					else
						self:enable(player)
					end
				end):setPosition(85, 300):setSize(90, 20)
			):loadComponent( -- Weekly button
				Button.new():setTranslation("weekly_lb")
	
				:onClick(function(self, player)
					local args = self.parent.args[player]
					self.parent:update(player, weekleaderboard, 0, 1)
				end)
	
				:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
					if weekly == 1 then
						self:disable(player)
					else
						self:enable(player)
					end
				end) 
	
				:setPosition(190, 300):setSize(90, 20)
			):loadComponent( -- Room button
				Button.new():setTranslation("room")
	
				:onClick(function(self, player)
					local args = self.parent.args[player]
					self.parent:update(player, roomleaderboard, 0, 3)
				end)
	
				:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
					if weekly == 3 then
						self:disable(player)
					else
						self:enable(player)
					end
				end) 
	
				:setPosition(295, 300):setSize(90, 20)
			)
	end
	--[[ End of file modes/parkour/interfaces/leaderboard.lua ]]--
	--[[ File modes/parkour/interfaces/newbadge.lua ]]--
	do
		NewBadgeInterface = Interface.new(340, 130, 120, 140, true)
			:loadTemplate(WindowBackground)
	
			:setShowCheck(function(self, player, group, badge)
				if self.open[player] then
					self:update(player, group, badge)
					return false
				end
				return true
			end)
	
			:addImage({
				image = function(self, player, group, badge)
					return badges[group][badge][3]
				end,
				target = "&1",
				x = 10, y = 5
			})
	
			:loadComponent(
				Button.new():setTranslation("close")
	
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
	
				:setSize(100, 15):setPosition(10, 115)
			)
	end
	--[[ End of file modes/parkour/interfaces/newbadge.lua ]]--
	--[[ File modes/parkour/interfaces/options.lua ]]--
	local no_help
	local OptionsInterface = Interface.new(168, 46, 465, 330, true)
	OptionsInterface
		:loadTemplate(WindowBackground)
		:addTextArea({
			text = function(self, player)
				return translatedMessage("options", player)
					:format((keyboard.bindings[
						players_file[player].settings[2] == 46 and 77
						or players_file[player].settings[2]
					] or "?"):gsub('\n', ' '))
			end,
			alpha = 0
		})
		:loadComponent(
			Button.new():setTranslation("close")
			:onClick(function(self, player)
				self.parent:remove(player)
			end)
			:setPosition(10, 305):setSize(445, 15)
		)
		:onRemove(function(self, player)
			savePlayerData(player)
		end)
	
		:loadComponent(
			Toggle.new(435, 55, false)
			:onToggle(function(self, player, state) -- qwerty or azerty keyboard
				players_file[player].settings[5] = state and 1 or 0
	
				if victory[player] then
					unbind(player)
					if not no_powers[player] then
						bindNecessary(player)
					end
				end
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[5] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 81, false)
			:onToggle(function(self, player, state) -- Any or M or DEL for mort
				local previous_key = players_file[player].settings[2]
				local key = state and (previous_key ~= 46 and previous_key or 77) or 46
				players_file[player].settings[2] = key
	
				if state then
					bindKeyboard(player, key, true, true)
					bindKeyboard(player, 46, true, false)
				else
					bindKeyboard(player, previous_key, true, false)
					bindKeyboard(player, 46, true, true)
				end
	
				OptionsInterface:remove(player)
				OptionsInterface:show(player)
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[2] ~= 46
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 107, false)
			:onToggle(function(self, player, state) -- powers cooldown
				players_file[player].settings[3] = state and 1 or 0
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[3] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 133, false)
			:onToggle(function(self, player, state) -- powers button
				players_file[player].settings[4] = state and 1 or 0
	
				GameInterface:update(player)
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[4] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 159, false)
			:onToggle(function(self, player, state) -- help button
				players_file[player].settings[6] = state and 1 or 0
	
				GameInterface:update(player)
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[6] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 185, false)
			:onToggle(function(self, player, state) -- congrats messages
				players_file[player].settings[7] = state and 1 or 0
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[7] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 211, false)
			:onToggle(function(self, player, state) -- no help indicator
				players_file[player].settings[8] = state and 1 or 0
	
				if not state then
					if no_help[player] then
						tfm.exec.removeImage(no_help[player])
						no_help[player] = nil
					end
				else
					no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
				end
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[8] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(435, 237, false)
			:onToggle(function(self, player, state) -- disable ui hotkeys
				players_file[player].settings[9] = state and 1 or nil
			end)
			:onUpdate(function(self, player)
				local setting = players_file[player].settings[9] == 1
				if (self.state[player] and not setting) or (not self.state[player] and setting) then
					self:toggle(player)
				end
			end)
		)
	
	onEvent("ParsedTextAreaCallback", function(id, player, action, args)
		if not OptionsInterface.open[player] then return end
	
		if action == "keyboardmort" then
			if not checkCooldown(player, "changeKeys", 1000) then return end
	
			if Keyboard.open[player] then
				Keyboard:remove(player)
				return
			end
	
			local qwerty = players_file[player] and players_file[player].settings[5] == 1
	
			Keyboard:show(player, qwerty, numkey, keyname) -- numkey, keyname
		elseif Keyboard.open[player] and action == "keyboard" then
			if not checkCooldown(player, "changeKeys", 1000) then return end
	
			local binding = keyboard.bindings[args]
			if not binding then return end
			if not players_file[player] then return end
	
			local previous_key = players_file[player].settings[2]
			players_file[player].settings[2] = binding
	
			bindKeyboard(player, previous_key, true, false)
			bindKeyboard(player, binding, true, true)
	
			savePlayerData(player)
	
			Keyboard:remove(player)
	
			-- Update key
			OptionsInterface:remove(player)
			OptionsInterface:show(player)
		end
	end)
	--[[ End of file modes/parkour/interfaces/options.lua ]]--
	--[[ File modes/parkour/interfaces/poll.lua ]]--
	local polls
	do
		polls = {}
	
		local pollSizes = {
			tiny = {
				{200, 130, 400, 140, true},
				minOptions = 2,
				maxOptions = 2,
				optionY = 85
			},
	
			small = {
				{200, 100, 400, 200, true},
				minOptions = 2,
				maxOptions = 4,
				optionY = 85
			},
	
			medium = {
				{200, 80, 400, 260, true},
				minOptions = 2,
				maxOptions = 6,
				optionY = 85
			},
	
			big = {
				{200, 50, 400, 320, true},
				minOptions = 2,
				maxOptions = 8,
				optionY = 85
			}
		}
	
		local poll, offset
		for name, data in next, pollSizes do
			polls[name] = {}
	
			for options = data.minOptions, data.maxOptions do
				local text_fnc = function(self, player, translation, title)
					local text
					if translation then
						text = translatedMessage(title, player)
					else
						text = title
					end
					return "<font size='13'><v>[#parkour]</v> " .. text
				end
	
				result = Interface.new(table.unpack(data[1]))
				result.y = result.y - 15
	
				result.height = result.height + 30
				result:loadTemplate(WindowBackground)
					:addTextArea({
						alpha = 0, y = 0,
						text = text_fnc
					})
	
				poll = Interface.new(table.unpack(data[1]))
					:loadTemplate(WindowBackground)
					:addTextArea({
						alpha = 0, y = 0,
						text = text_fnc
					})
	
				offset = data.optionY + 30 * (data.maxOptions - options)
	
				for button = 1, options do
					local component = Button.new():setText(function(self, player, translation, title, buttons, results)
							local text
							if translation then
								text = translatedMessage(buttons[button], player)
							else
								text = buttons[button]
							end
	
							if results then
								local percentage = 100 * results[button] / results.total
								if percentage ~= percentage then -- NaN
									percentage = 0
								end
	
								return string.format(text .. " - %.2f%% (%s)", percentage, results[button])
							end
							return text
						end)
	
						:canUpdate(true):onUpdate(function(self, player, translation, title, buttons, results)
							if results then
								self:disable(player)
							else
								self:enable(player)
							end
						end)
	
						:onClick(function(self, player)
							if eventPollVote then
								eventPollVote(self.parent, player, button)
							end
						end)
	
						:setPosition(10, offset):setSize(poll.width - 20, 15)
	
					result:loadComponent(component)
					poll:loadComponent(component)
					offset = offset + 30
				end
	
				result:loadComponent(
					Button.new():setTranslation("close")
	
					:onClick(function(self, player)
						self.parent:remove(player)
					end)
	
					:setPosition(10, offset):setSize(poll.width - 20, 15)
				)
	
				poll.closer = result
				polls[name][options] = poll
			end
		end
	end
	--[[ End of file modes/parkour/interfaces/poll.lua ]]--
	--[[ File modes/parkour/interfaces/powers.lua ]]--
	local PowersInterface
	do
		local selection, power
		for index = 1, #powers do
			selection = 1
			power = powers[index]
			if power.default then
				power.key = keyboard.keys[ power.default[1] ][ power.default[2] ]
	
				for layer = 1, power.default[1] - 1 do
					selection = selection + #keyboard.keys[layer]
				end
	
				power.default = selection + power.default[2]
			end
		end
	
		local images = {}
	
		local function getPlayerPower(player, power)
			local upgrades = power.upgrades
			if upgrades then
				local completed = players_file[player].c
				local pos = leaderboard[player] or max_leaderboard_rows + 1
				for index = #upgrades, 1, -1 do
					if upgrades[index].ranking then
						if pos <= upgrades[index].ranking then
							return upgrades[index]
						end
					elseif upgrades[index].maps <= completed then
						return upgrades[index]
					end
				end
			end
			return power
		end
	
		local function rebindKeys(player, power, old, new)
			power = getPowerUpgrade(
				players_file[player].c,
				leaderboard[player] or max_leaderboard_rows + 1,
				powers[power], true
			)
			if not power then return end
	
			local triggers = keys.triggers[player]
			local oldPowers = triggers[old]
			if oldPowers then
				if oldPowers._count == 1 then
					triggers[old] = nil
					bindKeyboard(player, old, true, false)
				else
					for index = 1, oldPowers._count do
						if oldPowers[index] == power then
							oldPowers[index] = nil
							break
						end
					end
	
					local delete = true
					for index = 1, oldPowers._count do
						if oldPowers[index] then
							delete = false
							break
						end
					end
					if delete then
						triggers[old] = nil
						bindKeyboard(player, old, true, false)
					end
				end
			end
	
			if not triggers[new] then
				triggers[new] = {_count = 1, [1] = power}
				bindKeyboard(player, new, true, true)
			else
				triggers[new]._count = triggers[new]._count + 1
				triggers[new][ triggers[new]._count ] = power
			end
		end
	
		local defaultKeyToggle
		PowersInterface = Interface.new(55, 28, 685, 366, true)
			:setDefaultArgs(1)
	
			:addImage({
				image = "173d539e4a0.png",
				target = ":1",
				y = -5, x = -5
			})
	
			:addTextArea({
				text = function(self, player, power)
					return translatedMessage("maps_info", player, players_file[player].c)
				end,
				alpha = 0,
				x = 525, y = 5,
				width = 150, height = 50
			})
	
			:addTextArea({
				text = "<a href='event:powers'><font color='#b84c36' size='15'><b>X</b></font></a>",
				alpha = 0,
				x = 665, y = 0,
				width = 20, height = 20
			})
	
			:addTextArea({
				text = function(self, player, power)
					return translatedMessage("weekly_info", player, weekleaderboard[player] and ("#" .. weekleaderboard[player]) or "N/A")
				end,
				alpha = 0,
				x = 525, y = 45,
				width = 150, height = 50
			})
	
			:addTextArea({
				text = function(self, player, power)
					return translatedMessage("overall_info", player, leaderboard[player] and ("#" .. leaderboard[player]) or "N/A")
				end,
				alpha = 0,
				x = 520, y = 85,
				width = 160, height = 50
			})
	
			:addTextArea({
				canUpdate = true,
				text = function(self, player, power)
					local upgrades, completed = powers[power].upgrades, players_file[player].c
					local pos = leaderboard[player] or max_leaderboard_rows + 1
					local cond
					if powers[power].ranking then
						cond = pos <= powers[power].ranking
					else
						cond = completed >= powers[power].maps
					end
	
					if cond then
						if upgrades then
							for index = 1, #upgrades do
								if upgrades[index].ranking then
									if pos > upgrades[index].ranking then
										return translatedMessage(
											"upgrade_power_rank", player,
											"#" .. upgrades[index].ranking, translatedMessage(upgrades[index].name, player)
										)
									end
								elseif completed < upgrades[index].maps then
									return translatedMessage(
										"upgrade_power", player,
										upgrades[index].maps, translatedMessage(upgrades[index].name, player)
									)
								end
							end
						end
						return ""
					end
	
					if powers[power].ranking then
						return translatedMessage(
							"unlock_power_rank", player,
							"#" .. powers[power].ranking, translatedMessage(powers[power].name, player)
						)
					end
					return translatedMessage(
						"unlock_power", player,
						powers[power].maps, translatedMessage(powers[power].name, player)
					)
				end,
				alpha = 0,
				x = 5, y = 70,
				width = 185, height = 70
			})
	
			:addTextArea({
				canUpdate = true,
				text = function(self, player, power)
					local name = getPlayerPower(player, powers[power]).name
					return "<p align='center'><font size='20'><vp><b>" .. translatedMessage(name, player)
				end,
				alpha = 0,
				height = 50, width = 485,
				x = 100
			})
	
			:addTextArea({
				x = 37, y = 5,
				alpha = 0,
				width = 400,
				translation = "power_options",
				canUpdate = false
			})
			:loadComponent(
				Toggle.new(10, 10, false)
				:onToggle(function(self, player, state)
					if Keyboard.open[player] then
						local power = self.parent.args[player][1]
						if keys[player][power] then
							Keyboard:update(player, state, nil, keyboard.bindings[ keys[player][power] ])
						else
							Keyboard:update(player, state, powers[power].default)
						end
					elseif Keyboard.args[player] then
						Keyboard.args[player][1] = state
					end
	
					players_file[player].settings[5] = state and 1 or 0
	
					if victory[player] then
						unbind(player)
						if not no_powers[player] then
							bindNecessary(player)
						end
					end
	
					savePlayerData(player)
				end)
				:onUpdate(function(self, player)
					local state = not not self.state[player]
					local setting = players_file[player].settings[5] == 1
					if state ~= setting then
						self:toggle(player)
					end
				end)
			)
			:loadComponent(
				Toggle.new(10, 36, false)
				:onToggle(function(self, player, state)
					eventParsedTextAreaCallback(0, player, "prof_maps", state and "private" or "public")
				end)
				:onUpdate(function(self, player)
					local state = not not self.state[player]
					local setting = not not players_file[player].private_maps
					if state ~= setting then
						self:toggle(player)
					end
				end)
			)
			:loadComponent(
				Toggle.new(10, 62, false)
				:onToggle(function(self, player, state)
					if not state or not Keyboard.open[player] then
						self:toggle(player)
	
					else
						local power = PowersInterface.args[player][1]
						local pkeys = players_file[player].keys
	
						local key
						if powers[power].key[1] then -- variation qwerty/azerty
							local setting = players_file[player].settings[5] + 1
							key = powers[power].key[setting]
						else
							key = powers[power].key
						end
						local old = keys[player][power]
						local new = keyboard.bindings[key]
	
						keys[player][power] = new
						pkeys[power] = 0
	
						for index = 1, power do
							if not pkeys[index] then
								pkeys[index] = 0
							end
						end
	
						savePlayerData(player)
	
						Keyboard:update(player, Keyboard.args[player][1], nil, key)
	
						if not keys.triggers[player] then return end
						rebindKeys(player, power, old, new)
					end
				end)
				:onUpdate(function(self, player)
					if not self.canUpdate then
						defaultKeyToggle = self
	
						local textareas = self.parent.textareas
						local clickable = textareas[ self.id - textareas[1].id + 2 ]
	
						self.canUpdate = true
						clickable.canUpdate = true
					end
	
					local power = PowersInterface.args[player][1]
					local key = players_file[player].keys[power]
	
					local state = key == 0 or not key
	
					if (not not self.state[player]) ~= state then
						self:toggle(player)
					end
				end)
			)
	
			:onUpdate(function(self, player, power)
				if not images[player] then
					images[player] = {}
				else
					for idx = 1, 4 do
						if images[player][idx] then
							tfm.exec.removeImage(images[player][idx])
						end
					end
				end
	
				if powers[power].click then
					if Keyboard.open[player] then
						Keyboard:remove(player)
					end
					images[player][4] = tfm.exec.addImage(
						"173de7d5a5c.png", ":7",
						self.x + 250, self.y + 140, player
					)
	
				else
					local numkey = powers[power].default
					local keyname
					if keys[player][power] then
						numkey = nil
						keyname = keyboard.bindings[ keys[player][power] ]
					end
	
					if not Keyboard.open[player] then
						local qwerty = (self.open[player] and Keyboard.args[player][1] or
										players_file[player].settings[5] == 1)
	
						Keyboard:show(player, qwerty, numkey, keyname)
					else
						Keyboard:update(player, Keyboard.args[player][1], numkey, keyname)
					end
				end
	
				local completed = players_file[player].c
				local pos = leaderboard[player] or max_leaderboard_rows + 1
				local img, cond
				if power > 1 then
					if powers[power - 1].ranking then
						cond = pos <= powers[power - 1].ranking
					else
						cond = completed >= powers[power - 1].maps
					end
	
					if cond then
						img = getPlayerPower(player, powers[power - 1])
					else
						img = powers[power - 1]
					end
					images[player][1] = tfm.exec.addImage(
						img[(not cond) and "lockedSmall" or "small"],
						":2", self.x + 240 - img.smallX, self.y + 50 + img.smallY, player
					)
				end
	
				if powers[power].ranking then
					cond = pos <= powers[power].ranking
				else
					cond = completed >= powers[power].maps
				end
	
				if cond then
					img = getPlayerPower(player, powers[power])
				else
					img = powers[power]
				end
				images[player][2] = tfm.exec.addImage(
					img[(not cond) and "lockedBig" or "big"],
					":3", self.x + 300 + img.bigX, self.y + 30 + img.bigY, player
				)
	
				if power < #powers then
					if powers[power + 1].ranking then
						cond = pos <= powers[power + 1].ranking
					else
						cond = completed >= powers[power + 1].maps
					end
	
					if cond then
						img = getPlayerPower(player, powers[power + 1])
					else
						img = powers[power + 1]
					end
					images[player][3] = tfm.exec.addImage(
						img[(not cond) and "lockedSmall" or "small"],
						":4", self.x + 380 + img.smallX, self.y + 50 + img.smallY, player
					)
				end
			end)
			:onRemove(function(self, player)
				Keyboard:remove(player)
	
				for idx = 1, 4 do
					if images[player][idx] then
						tfm.exec.removeImage(images[player][idx])
					end
				end
			end)
	
			:addImage({
				image = "173d9bf80a1.png",
				target = ":5",
				x = 195, y = 50
			})
			:addTextArea({
				canUpdate = true,
				x = 193, y = 47,
				text = function(self, player, power)
					if power > 1 then
						return "<a href='event:power:" .. (power - 1) .. "'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
					end
					return ""
				end,
				width = 26, height = 55,
				alpha = 0
			})
	
			:addImage({
				image = "173d9bfa12a.png",
				target = ":6",
				x = 460, y = 50
			})
			:addTextArea({
				canUpdate = true,
				x = 458, y = 47,
				text = function(self, player, power)
					if power < #powers then
						return "<a href='event:power:" .. (power + 1) .. "'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
					end
					return ""
				end,
				width = 26, height = 55,
				alpha = 0
			})
	
		onEvent("ParsedTextAreaCallback", function(id, player, action, args)
			if not PowersInterface.open[player] then return end
	
			if action == "power" then
				if not checkCooldown(player, "showpowers", 1000) then return end
				page = tonumber(args)
	
				if page > 0 and page <= #powers then
					PowersInterface:update(player, page)
				end
			elseif Keyboard.open[player] and action == "keyboard" then
				if not checkCooldown(player, "changeKeys", 1000) then return end
				if not players_file[player] then return end
	
				local binding = keyboard.bindings[args]
				if binding then
					Keyboard:update(player, Keyboard.args[player][1], nil, args)
	
					if defaultKeyToggle and defaultKeyToggle.state[player] then
						defaultKeyToggle:toggle(player)
					end
	
					local power = PowersInterface.args[player][1]
					local old = keys[player][power]
					if old == binding then return end
	
					if not old then
						if powers[power].key[1] then -- variation qwerty/azerty
							old = keyboard.bindings[ powers[power].key[ players_file[player].settings[5] + 1 ] ]
						else
							old = keyboard.bindings[ powers[power].key ]
						end
					end
	
					local pkeys = players_file[player].keys
					local count = 0
					for index = 1, #pkeys do
						if pkeys[index] == binding then
							count = count + 1
						end
					end
	
					if count >= 2 then
						return translatedChatMessage("max_power_keys", player, 2)
					end
	
					pkeys[power] = binding
					for index = 1, power do
						if not pkeys[index] then
							pkeys[index] = 0
						end
					end
	
					keys[player][power] = binding
					savePlayerData(player)
	
					if not keys.triggers[player] then return end
					rebindKeys(player, power, old, binding)
				end
			end
		end)
	end
	--[[ End of file modes/parkour/interfaces/powers.lua ]]--
	--[[ File modes/parkour/interfaces/profile.lua ]]--
	local Profile
	do
		local nameCache = {}
		local function formatName(name)
			if nameCache[name] then
				return nameCache[name]
			end
	
			nameCache[name] = string.gsub(
				string.gsub(name, "(#%d%d%d%d)", "<font size='15'><g>%1</g></font>"),
				"([Hh]t)tp", "%1<->tp"
			)
			return nameCache[name]
		end
	
		local staff = {
			{"admin", "172e0cf7ce5.png"},
			{"bot", "172e0cf7ce5.png"},
			{"mod", "173eeb6cd94.png"},
			{"mapper", "17323cc35d1.png"},
			{"translator", "173f3263916.png"}
		}
		local images = {}
	
		Profile = Interface.new(200, 50, 400, 360, true)
			:setShowCheck(function(self, player, profile, data)
				local file = data or players_file[profile]
				return (file
						and file.v == data_version)
			end)
	
			:addImage({
				image = "178de11fd0c.png",
				target = ":1",
				x = -5, y = -5
			})
	
			:addTextArea({
				alpha = 0,
				x = 5, y = 5,
				height = 100,
				canUpdate = true,
				text = function(self, player, profile)
					return "<font size='20' face='Verdana'><v><b>" .. formatName(profile)
				end
			})
			:addTextArea({
				x = 10, y = 45, height = 1, width = 380,
				border = 0x9d7043
			})
			:addTextArea({
				x = 5, y = 47, height = 1, width = 390,
				color = {0x1c3a3e, 0x1c3a3e, 1}
			})
	
			:onUpdate(function(self, player, profile, data)
				local container = images[player]
				if not container then
					container = {_count = 0}
					images[player] = container
				else
					for index = 1, container._count do
						tfm.exec.removeImage(container[index])
					end
					container._count = 0
				end
	
				local x = self.x + 370
				if not (data or players_file[profile]).hidden then
					for index = 1, #staff do
						if ranks[ staff[index][1] ][profile] then
							container._count = container._count + 1
							container[ container._count ] = tfm.exec.addImage(staff[index][2], "&1", x, self.y + 10, player)
							x = x - 25
						end
					end
				end
	
				x = self.x + 15
				local limit = x + 40 * 9
				local y = self.y + 205
				local pbg = (data or players_file[profile]).badges
				if pbg then
					local badge
					for index = 1, #badges do
						if pbg[index] and pbg[index] > 0 then
							badge = badges[index][pbg[index]]
	
							container._count = container._count + 1
							container[ container._count ] = tfm.exec.addImage(badge[2], ":2", x, y, player)
							ui.addTextArea(
								-10000 - index,
								"<a href='event:_help:badge_" .. badge[1] .. "'>\n\n\n\n\n\n",
								player, x, y, 30, 30,
								0, 0, 0, true
							)
	
							x = x + 40
							if x >= limit then
								x = self.x + 15
								y = y + 40
							end
						else
							ui.removeTextArea(-10000 - index, player)
						end
					end
				end
			end)
			:onRemove(function(self, player, profile)
				for index = 1, images[player]._count do
					tfm.exec.removeImage(images[player][index])
				end
				for index = 1, #badges do
					ui.removeTextArea(-10000 - index, player)
				end
				images[player]._count = 0
			end)
	
			:addTextArea({
				x = 5, y = 50,
				canUpdate = true,
				text = function(self, player, profile, data)
					local file = (data or players_file[profile])
					local displayStats = (not file.private_maps or player == profile or (perms[player] and perms[player].see_private_maps))
	
					return translatedMessage(
						"profile", player,
						file.private_maps and translatedMessage("private_maps", player) or "",
	
						displayStats and translatedMessage("map_count", player, file.c, file.week[1], #file.hour) or "",
	
						profile == player and string.format(
							"<a href='event:prof_maps:%s'><j>[%s]</j></a>",
							file.private_maps and "public" or "private",
							translatedMessage(file.private_maps and "make_public" or "make_private", player)
						) or "",
	
						leaderboard[profile] and ("#" .. leaderboard[profile]) or "N/A",
	
						weekleaderboard[profile] and ("#" .. weekleaderboard[profile]) or "N/A",
	
						displayStats and translatedMessage("title_count", player, file.tc, file.cc) or ""
					)
				end,
				alpha = 0, height = 150
			})
	
			:addTextArea({
				x = 5, y = 175,
				canUpdate = true,
				text = function(self, player, profile, data)
					local count = 0
					local pbg = (data or players_file[profile]).badges
					if pbg then
						for index = 1, #badges do
							if pbg[index] and pbg[index] > 0 then
								count = count + 1
							end
						end
					end
					return translatedMessage("badges", player, count)
				end,
				height = 20,
				alpha = 0
			})
	
			:loadComponent(
				Button.new():setTranslation("close")
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
				:setPosition(10, 300):setSize(380, 15)
			)
	
		onEvent("ParsedTextAreaCallback", function(id, player, action, args)
			if action == "prof_maps" then
				if not checkCooldown(player, "mapsToggle", 500) then return end
				if not players_file[player] then return end
	
				if args == "public" then
					players_file[player].private_maps = nil
				else
					players_file[player].private_maps = true
				end
	
				savePlayerData(player)
	
				if Profile.open[player] then
					Profile:update(player, player)
				end
			end
		end)
	end
	--[[ End of file modes/parkour/interfaces/profile.lua ]]--
	--[[ File modes/parkour/interfaces/quests.lua ]]--
	do	
	
		local isQuestSkipped = {}
		local function checkQuestSkipped(player)
			if not players_file[player] then return end
			if not players_file[player].quests then return end
	
			isQuestSkipped[player] = {
				weekly = false,
				daily = false,
			}
	
			for i = 1, #players_file[player].quests do
				if players_file[player].quests[i].skp and players_file[player].quests[i].skp > 1 then
					if i <= 4 then
						isQuestSkipped[player].daily = true
					else
						isQuestSkipped[player].weekly = true
					end
				end
			end
	
		end
	
		local closeButton = Button.new()
		QuestsInterface = Interface.new(200, 35, 400, 350, true)
			:loadTemplate(WindowBackground)
			:setShowCheck(function(self, player, page, data)
				checkQuestSkipped(player)
				if not players_file[player].quests then
					tfm.exec.chatMessage("<c> No quest data.", player)
					return false
				end
				if not data then
					local getPage = page and page or 1
					self:show(player, getPage, players_file[player].quests)
					return false
				end
				return true
			end)
	
			:loadComponent( -- Close button
				closeButton:setText("")
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
				:setPosition(50, 330):setSize(300, 10)
			)
			:addTextArea({
				x = 50, y = 326,
				width = 300, height = 15,
				text = function(self, player)
					return ("<a href='event:" .. closeButton.callback ..
							"'><p align='center'>".. translatedMessage("close", player))
				end,
				alpha = 0
			})
	
			:loadComponent( -- Daily button
				Button.new():setTranslation("daily_q") 
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "daily_quest_button", 3000) then return end
					self.parent:update(player, 1)
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == 1 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(20, 15):setSize(170, 18)
			)
	
			:loadComponent( -- Weekly button
				Button.new():setTranslation("weekly_q")
	
				:onClick(function(self, player, page)
					if not checkCooldown(player, "weekly_quest_button", 3000) then return end
					self.parent:update(player, 2)
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page)
					if page == 2 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(210, 15):setSize(170, 18)
			)
	
			:addTextArea({ -- Reset Time
				x = 10, y = 42,
				width = 120, height = 40,
				canUpdate = true,
				text = function(self, player, page)
					local currentTime = os.time() + 60 * 60 * 1000
					local reset_time = getQuestsResetTime() -- reset_time = {last_daily_reset, last_weekly_reset, next_daily_reset, next_weekly_reset}
	
					local day = 24 * 60 * 60 * 1000
					local hour = 1 * 60 * 60 * 1000
					local minute = 1 * 60 * 1000
	
					local weekly_diff = reset_time[4] - currentTime
					local daily_diff = reset_time[3] - currentTime
	
					local weekly_days = math.floor(weekly_diff / day)
					local weekly_hours = math.floor((weekly_diff % day) / hour)
					local weekly_minutes = math.floor((weekly_diff % hour) / minute)
	
					local daily_hours = math.floor(daily_diff / hour)
					local daily_minutes = math.floor((daily_diff % hour) / minute)
	
					local daily_coming = string.format("%sh %sm", daily_hours, daily_minutes)
					local weekly_coming = string.format("%sd %sh %sm", weekly_days, weekly_hours, weekly_minutes)
	
					if page == 1 then
						return translatedMessage("next_reset", player, daily_coming)
					else
						return translatedMessage("next_reset", player, weekly_coming)
					end
				end,
				alpha = 0
			})
	
			:addTextArea({ -- Title
				x = 10, y = 40,
				width = 380, height = 30,
				canUpdate = true,
				text = function(self, player, page)
					if page == 1 then
						return translatedMessage("daily_quests", player)
					else
						return translatedMessage("weekly_quests", player)
					end
				end,
				alpha = 0
			})
	
			:addTextArea({ -- Quest 1
				x = 10, y = 85,
				width = 380, height = 40,
				alpha = 1,
				color = {0x314e57, 0x314e57}
			})
			:addImage({ -- Coin Image
				image = "18b29f6977c.png",
				target = "~8",
				x = 25, y = 82
			})
			:addTextArea({ -- Prize
				x = 15, y = 110,
				width = 50, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[1].id or players_file[player].quests[5].id
					local isWeekly = (page ~= 1)
	
					return string.format(
						"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
					)
				end
			})
			:addTextArea({ -- Quest 1 Description
				x = 80, y = 85,
				width = 270, height = 40,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[1].id or players_file[player].quests[5].id
					local isWeekly = (page ~= 1)
	
					return quests[questID].description(player, isWeekly)
				end
			})
			:addImage({
				canUpdate = true,
				image = function(self, player, page, data)
					local questCompleted = false
					if (page == 1 and players_file[player].quests[1].ts) or (page == 2 and players_file[player].quests[5].ts) then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questCompleted then
						return "18bdfe01bb3.png"
					elseif questSkipped then
						return "a.png"
					else
						return "18bab04d3a9.png"
					end
				end,
				
				target = "~10",
				x = 360, y = 95,
			})
			:addTextArea({ -- Change TA
				x = 360, y = 95,
				width = 20, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and 1 or 5
	
					local questCompleted = false
					if players_file[player].quests[questID].ts then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questSkipped or questCompleted then return "" end
					
					return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
				end
			})
	
	
			:addTextArea({ -- Quest 2
				x = 10, y = 145,
				width = 380, height = 40,
				alpha = 1,
				color = {0x314e57, 0x314e57}
			})
			:addImage({ -- Coin Image
				image = "18b29f6977c.png",
				target = "~8",
				x = 25, y = 142
			})
			:addTextArea({ -- Prize
				x = 15, y = 170,
				width = 50, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[2].id or players_file[player].quests[6].id
					local isWeekly = (page ~= 1)
	
					return string.format(
						"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
					)
				end
			})
			:addTextArea({ -- Quest 2 Description
				x = 80, y = 145,
				width = 270, height = 40,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[2].id or players_file[player].quests[6].id
					local isWeekly = (page ~= 1)
	
					return quests[questID].description(player, isWeekly)
				end
			})
			:addImage({
				canUpdate = true,
				image = function(self, player, page, data)
					local questCompleted = false
					if (page == 1 and players_file[player].quests[2].ts) or (page == 2 and players_file[player].quests[6].ts) then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questCompleted then
						return "18bdfe01bb3.png"
					elseif questSkipped then
						return "a.png"
					else
						return "18bab04d3a9.png"
					end
				end,
				
				target = "~20",
				x = 360, y = 155,
			})
			:addTextArea({ -- Change TA
				x = 360, y = 155,
				width = 20, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and 2 or 6
	
					local questCompleted = false
					if players_file[player].quests[questID].ts then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questSkipped or questCompleted then return "" end
	
					return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
				end
			})
	
	
			:addTextArea({ -- Quest 3
				x = 10, y = 205,
				width = 380, height = 40,
				alpha = 1,
				color = {0x314e57, 0x314e57}
			})
			:addImage({ -- Coin Image
				image = "18b29f6977c.png",
				target = "~8",
				x = 25, y = 202
			})
			:addTextArea({ -- Prize
				x = 15, y = 230,
				width = 50, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[3].id or players_file[player].quests[7].id
					local isWeekly = (page ~= 1)
	
					return string.format(
						"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
					)
				end
			})
			:addTextArea({ -- Quest 3 Description
				x = 80, y = 205,
				width = 270, height = 40,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[3].id or players_file[player].quests[7].id
					local isWeekly = (page ~= 1)
	
					return quests[questID].description(player, isWeekly)
				end
			})
			:addImage({
				canUpdate = true,
				image = function(self, player, page, data)
					local questCompleted = false
					if (page == 1 and players_file[player].quests[3].ts) or (page == 2 and players_file[player].quests[7].ts) then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questCompleted then
						return "18bdfe01bb3.png"
					elseif questSkipped then
						return "a.png"
					else
						return "18bab04d3a9.png"
					end
				end,
				
				target = "~30",
				x = 360, y = 215,
			})
			:addTextArea({ -- Change TA
				x = 360, y = 215,
				width = 20, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and 3 or 7
	
					local questCompleted = false
					if players_file[player].quests[questID].ts then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questSkipped or questCompleted then return "" end
	
					return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
				end
			})
	
	
			:addTextArea({ -- Quest 4
				x = 10, y = 265,
				width = 380, height = 40,
				alpha = 1,
				color = {0x314e57, 0x314e57}
			})
			:addImage({ -- Coin Image
				image = "18b29f6977c.png",
				target = "~8",
				x = 25, y = 262
			})
			:addTextArea({ -- Prize
				x = 15, y = 290,
				width = 50, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[4].id or players_file[player].quests[8].id
					local isWeekly = (page ~= 1)
	
					return string.format(
						"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
					)
				end
			})
			:addTextArea({ -- Quest 4 Description
				x = 80, y = 265,
				width = 270, height = 40,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and players_file[player].quests[4].id or players_file[player].quests[8].id
					local isWeekly = (page ~= 1)
	
					return quests[questID].description(player, isWeekly)
				end
			})
			:addImage({
				canUpdate = true,
				image = function(self, player, page, data)
					local questCompleted = false
					if (page == 1 and players_file[player].quests[4].ts) or (page == 2 and players_file[player].quests[8].ts) then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questCompleted then
						return "18bdfe01bb3.png"
					elseif questSkipped then
						return "a.png"
					else
						return "18bab04d3a9.png"
					end
				end,
				
				target = "~40",
				x = 360, y = 275,
			})
			:addTextArea({ -- Change TA
				x = 360, y = 275,
				width = 20, height = 20,
				alpha = 0,
				canUpdate = true,
				text = function(self, player, page, data)
					local questID = page == 1 and 4 or 8
	
					local questCompleted = false
					if players_file[player].quests[questID].ts then
						questCompleted = true
					end
	
					local questSkipped = false
					if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
						questSkipped = true
					end
	
					if questSkipped or questCompleted then return "" end
	
					return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
				end
			})
		
	end
	--[[ End of file modes/parkour/interfaces/quests.lua ]]--
	--[[ File modes/parkour/interfaces/shop.lua ]]--
	local ShopInterface
	do	
		local shop_images = {}
		local coin_images = {}
		local shopPage = {}
		local isSave = {}
		
		local closeButton = Button.new()
		ShopInterface = Interface.new(50, 35, 700, 350, true)
			:setDefaultArgs("shop")
			:loadTemplate(WindowBackground)
			:setShowCheck(function(self, player, page, data)
				if not data then
	
					if players_file[player].c >= 400 then
						shop_items[4][1].image = "173db16a824.png"
					end
	
					shopPage[player] = 1
					self:show(player, 1, shop_items[1])
					return false
				end
				return true
			end)
	
			-- Close button
			:loadComponent(
				closeButton:setText("")
				:onClick(function(self, player)
					if isSave[player] then
						savePlayerData(player)
						isSave[player] = nil
					end
	
					self.parent:remove(player)
				end)
				:setPosition(150, 330):setSize(400, 10)
			)
			
			:addTextArea({
				x = 150, y = 326,
				width = 400, height = 15,
				text = function(self, player)
					return ("<a href='event:" .. closeButton.callback ..
							"'><p align='center'>".. translatedMessage("close", player))
				end,
				alpha = 0
			})
	
			:addImage({
				image = "18b29f6977c.png",
				target = "&99",
				x = 25, y = 15
			})
	
			:addTextArea({ -- Parkour Coin
				x = 25, y = 15,
				width = 100, height = 30,
				canUpdate = true,
				text = function(self, player, page, data)
					return ("<font size='18'><p align='right'>"..players_file[player].coins)
				end,
				alpha = 1,
				color = {0x204347, 0x204347}
			})
	
			-- Item Images
			:addTextArea({
				x = 0, y = 50,
				width = 700, height = 250,
				alpha = 0,
			}):onUpdate(function(self, player, page, data)
				if not shop_images[player] then
					shop_images[player] = {}
				else
					for index = 1, 18 do
						tfm.exec.removeImage(shop_images[player][index])
					end
				end
	
				local x = 70
				local y = 120
	
				for index = 1, #data do
					shop_images[player][index] = tfm.exec.addImage(data[index].image, "&999", x, y, player)
					
	                x = x + 75
	
					if index == 9 then
						y = 250
						x = 70
					end
				end
			end)
	
			-- Item Prices
			:addTextArea({
				x = 0, y = 50,
				width = 700, height = 250,
				canUpdate = true,
				text = function(self, player, page, data)
					if not coin_images[player] then
						coin_images[player] = {}
					else
						for index = 1, 18 do
							tfm.exec.removeImage(coin_images[player][index])
						end
					end
	
					local x = self.x + 25
					local y = self.y + 15
					for index = 1, #data do
						local itemPrice = data[index].price or 0
	
						--[[
						if itemPrice >= 1000 then
							local numString = tostring(itemPrice)
							local numLength = string.len(numString)
							if numLength == 4 then
								itemPrice = numString:sub(1, 1) .. "K"
							elseif numLength == 5 then
								itemPrice = numString:sub(1, 2) .. "K"
							elseif numLength == 6 then
								itemPrice = numString:sub(1, 3) .. "K"
							else
								itemPrice = itemPrice
							end
						elseif itemPrice == -1 then
							itemPrice = "-"
						end
						]]--
	
						coin_images[player][index] = tfm.exec.addImage("18b2a0bc298.png", "&1000", x - 2, y + 2, player)
						ui.addTextArea(
							-10000 - index, "<b><p align='right'>"..itemPrice, player,
							x, y, 50, 15,
							0x14282b, 0x14282b, 1,
							true
						)
	
						x = x + 75 
	
						if index == 9 then
							y = self.y + 145
							x = self.x + 25
						end
					end
					return ""
				end,
				alpha = 0
			}):onRemove(function(self, player, page, data)
				for index = 1, 18 do
					ui.removeTextArea(-10000 - index, player)
					tfm.exec.removeImage(shop_images[player][index])
					tfm.exec.removeImage(coin_images[player][index])
				end
			end)
	
			-- Tabs
			:loadComponent( -- Small Box
				Button.new():setTranslation("smallbox")
	
				:onClick(function(self, player, page, data)
					if not checkCooldown(player, "shopbuttons", 1500) then return end
					local args = self.parent.args[player]
					shopPage[player] = 1
					self.parent:update(player, 1, shop_items[1])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page, data)
					if page == 1 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(200, 20):setSize(80, 18)
			)
			:loadComponent( -- Box
				Button.new():setTranslation("bigBox")
	
				:onClick(function(self, player, page, data)
					if not checkCooldown(player, "shopbuttons", 1500) then return end
					local args = self.parent.args[player]
					shopPage[player] = 2
					self.parent:update(player, 2, shop_items[2])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page, data)
					if page == 2 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(300, 20):setSize(80, 18)
			)
			:loadComponent( -- Trampoline
				Button.new():setTranslation("trampoline")
	
				:onClick(function(self, player, page, data)
					if not checkCooldown(player, "shopbuttons", 1500) then return end
					local args = self.parent.args[player]
					shopPage[player] = 3
					self.parent:update(player, 3, shop_items[3])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page, data)
					if page == 3 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(400, 20):setSize(80, 18)
			)
			:loadComponent( -- Baloon
				Button.new():setTranslation("balloon")
	
				:onClick(function(self, player, page, data)
					if not checkCooldown(player, "shopbuttons", 1500) then return end
					local args = self.parent.args[player]
					shopPage[player] = 4
					self.parent:update(player, 4, shop_items[4])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page, data)
					if page == 4 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(500, 20):setSize(80, 18)
			)
			:loadComponent( -- Choco
				Button.new():setTranslation("choco")
	
				:onClick(function(self, player, page, data)
					local args = self.parent.args[player]
					shopPage[player] = 5
					self.parent:update(player, 5, shop_items[5])
				end)
	
				:canUpdate(true):onUpdate(function(self, player, page, data)
					if page == 5 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(600, 20):setSize(80, 18)
			)
			
	
		local buttonx = 22
		local buttony = 155
	
		for buyButton = 1, #shop_items[1] do
			local component = Button.new()
	        
			:setText(
				function(self, player, page, data)				
					local itemID = shop_items[shopPage[player]][buyButton].id
					itemID = tostring(itemID)
	
					if players_file[player].cskins[shopPage[player]] == tonumber(itemID) then
						return translatedMessage("equipped", player)
					elseif players_file[player].skins[itemID] == 1 then
						return translatedMessage("equip", player)
					else
						return translatedMessage("buy", player)
					end
	
				end)
	
			:onClick(function(self, player, page, data)
				if not checkCooldown(player, "buybutton", 1000) then return end
	
				local item_price = shop_items[shopPage[player]][buyButton].price
				local player_coin = players_file[player].coins
				local itemID = shop_items[shopPage[player]][buyButton].id
				itemID = tostring(itemID)
				isSave[player] = true
	
				local args = self.parent.args[player]
	
				if players_file[player].skins[itemID] == 1 then
					players_file[player].cskins[shopPage[player]] = tonumber(itemID)
					self.parent:update(player, args[1], args[2], 3)
					return
				end
	
				if player_coin >= item_price then
					players_file[player].skins[itemID] = 1
					players_file[player].coins = player_coin - item_price
					self.parent:update(player, args[1], args[2], 1)
				else
					tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
				end
			end)
		
			:canUpdate(true):onUpdate(function(self, player, page, data)
				if players_file[player].cskins[page] == shop_items[page][buyButton].id or shop_items[page][buyButton].price == -1 then
					self:disable(player)
				else
					self:enable(player)
				end 
			end)
		
			:setPosition(buttonx, buttony):setSize(55, 18)
		
			ShopInterface:loadComponent(component)
			buttonx = buttonx + 75
	
			if buyButton == 9 then
				buttony = 285
				buttonx = 22
			end
		end
	end
	--[[ End of file modes/parkour/interfaces/shop.lua ]]--
	--[[ File modes/parkour/interfaces/staff.lua ]]--
	local Staff
	do
		local nameCache = {}
		local function formatName(name)
			if nameCache[name] then
				return nameCache[name]
			end
	
			nameCache[name] = "<a href='event:msg:/w " .. name .. "'>" .. string.gsub(
				string.gsub(name, "(#%d%d%d%d)", "<font size='11'><g>%1</g></font>"),
				"([Hh]t)tp", "%1<->tp"
			) .. "</a>"
			return nameCache[name]
		end
		local tab = {}
		local images = {
			{},
			{},
			{}
		}
		local communities = {
			xx = "1651b327097.png",
			ar = "1651b32290a.png",
			bg = "1651b300203.png",
			br = "1651b3019c0.png",
			cn = "1651b3031bf.png",
			cz = "1651b304972.png",
			de = "1651b306152.png",
			ee = "1651b307973.png",
			en = "1723dc10ec2.png",
			e2 = "1723dc10ec2.png",
			es = "1651b309222.png",
			fi = "1651b30aa94.png",
			fr = "1651b30c284.png",
			gb = "1651b30da90.png",
			hr = "1651b30f25d.png",
			hu = "1651b310a3b.png",
			id = "1651b3121ec.png",
			he = "1651b3139ed.png",
			it = "1651b3151ac.png",
			jp = "1651b31696a.png",
			lt = "1651b31811c.png",
			lv = "1651b319906.png",
			nl = "1651b31b0dc.png",
			ph = "1651b31c891.png",
			pl = "1651b31e0cf.png",
			pt = "17459ce7e29.png",
			ro = "1651b31f950.png",
			ru = "1651b321113.png",
			tr = "1651b3240e8.png",
			vk = "1651b3258b3.png"
		}
		local community_list = {
			"xx", "en", "e2", "ar", "bg", "br", "cn", "cz", "de", "ee", "es", "fi", "fr", "gb", "hr",
			"hu", "id", "he", "it", "jp", "lt", "lv", "nl", "ph", "pl", "ro", "ru", "tr", "vk"
		}
	
		local function names(container, x, start)
			return function(self, player)
				local image_x, image_y = self.parent.x + x, self.parent.y + 56
				local imgs = images[container][player]
				local show_hidden = perms[player] and perms[player].see_hidden_staff
	
				if not imgs then
					imgs = {_count = 0}
					images[container][player] = imgs
				else
					for index = 1, imgs._count do
						tfm.exec.removeImage(imgs[index])
					end
				end
	
				local rank = self.parent.sorted_members[
					tab[player] == 0 and "mod" or
					tab[player] == 1 and "mapper" or
					tab[player] == 2 and "manager" or
					"admin"
				]
				local names = {}
	
				local commu_list = {}
				local commu, member
				for index = 1 + start, math.min(17 + start, rank._count) do
					member = rank[index]
	
					if hidden[member] then -- hidden
						if not show_hidden then
							break
						end
						names[index - start] = "<r>" .. formatName(member) .. "</r>"
						commu = hidden[member]
					else
						names[index - start] = formatName(member)
						commu = online[member]
					end
	
					imgs[index - start] = tfm.exec.addImage(communities[ commu ], "&1", image_x, image_y, player)
					image_y = image_y + 12
					imgs._count = index - start
				end
	
				return "<font face='Lucida Console' size='12'><v>" .. table.concat(names, "\n")
			end
		end
	
		Staff = Interface.new(148, 50, 504, 300, true)
			:loadTemplate(WindowBackground)
	
			:loadComponent(
				Button.new():setTranslation("moderators")
	
				:onClick(function(self, player)
					tab[player] = 0
					self.parent:update(player)
				end)
	
				:canUpdate(true):onUpdate(function(self, player)
					if not tab[player] then tab[player] = 0 end
					if tab[player] == 0 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(10, 10):setSize(111, 15)
			)
			:loadComponent(
				Button.new():setTranslation("mappers")
	
				:onClick(function(self, player)
					tab[player] = 1
					self.parent:update(player)
				end)
	
				:canUpdate(true):onUpdate(function(self, player)
					if tab[player] == 1 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(134, 10):setSize(111, 15)
			)
			:loadComponent(
				Button.new():setTranslation("managers")
	
				:onClick(function(self, player)
					tab[player] = 2
					self.parent:update(player)
				end)
	
				:canUpdate(true):onUpdate(function(self, player)
					if tab[player] == 2 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(258, 10):setSize(111, 15)
			)
			:loadComponent(
				Button.new():setTranslation("administrators")
	
				:onClick(function(self, player)
					tab[player] = 3
					self.parent:update(player)
				end)
	
				:canUpdate(true):onUpdate(function(self, player)
					if tab[player] == 3 then
						self:disable(player)
					else
						self:enable(player)
					end
				end)
	
				:setPosition(382, 10):setSize(111, 15)
			)
	
			:addTextArea({
				y = 35, x = 5,
				height = 230, width = 449,
				translation = "staff_power",
				alpha = 0
			})
	
			:addTextArea({
				y = 55, x = 22,
				height = 210, width = 145,
				canUpdate = true,
				text = names(1, 5, 0),
				alpha = 0
			})
	
			:addTextArea({
				y = 55, x = 187,
				height = 210, width = 145,
				canUpdate = true,
				text = names(2, 160, 17),
				alpha = 0
			})
	
			:addTextArea({
				y = 55, x = 352,
				height = 210, width = 145,
				canUpdate = true,
				text = names(3, 315, 34),
				alpha = 0
			})
	
			:onRemove(function(self, player)
				local cont
				for container = 1, 3 do
					cont = images[container][player]
					if cont then
						for index = 1, cont._count do
							tfm.exec.removeImage(cont[index])
						end
					end
				end
			end)
	
			:loadComponent(
				Button.new():setTranslation("close")
	
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
	
				:setPosition(10, 275):setSize(484, 15)
			)
	
		Staff.sorted_members = {}
	end
	--[[ End of file modes/parkour/interfaces/staff.lua ]]--
	--[[ File modes/parkour/interfaces/tracker.lua ]]--
	local PowerTracker
	do
		local nameCache = {}
		local function formatName(name)
			if nameCache[name] then
				return nameCache[name]
			end
	
			nameCache[name] = string.gsub(
				string.gsub(name, "(#%d%d%d%d)", "<font size='10'><g>%1</g></font>"),
				"([Hh]t)tp", "%1<->tp"
			)
			return nameCache[name]
		end
	
		PowerTracker = Interface.new(200, 50, 400, 300, true)
			:loadTemplate(WindowBackground)
	
			:addTextArea({
				alpha = 0,
				text = "<p align='center'><font size='14'><cep><b>Power Tracker</b></cep></font></p>"
			})
	
			:addTextArea({
				canUpdate = true,
				y = 25, height = 240,
				alpha = 0,
	
				text = function(self, player, powers)
					local pieces, count = {}, 0
	
					local power
					for index = powers._count, math.max(powers._count - 18, 1), -1 do
						power = powers[index]
						count = count + 1
						pieces[count] = formatName(power[1]) .. "<n> -> </n>" .. power[2]
					end
	
					return "<v>" .. table.concat(pieces, "\n")
				end
			})
	
			:loadComponent(
				Button.new():setTranslation("close")
	
				:onClick(function(self, player)
					self.parent:remove(player)
				end)
	
				:setPosition(10, 275):setSize(380, 15)
			)
	end
	--[[ End of file modes/parkour/interfaces/tracker.lua ]]--
	--[[ End of directory modes/parkour/interfaces ]]--
	--[[ File modes/parkour/ui.lua ]]--
	-- Stuff related to the keyboard and game interface (not chat)
	
	local interfaces = {
		[72] = HelpInterface,
		[76] = LeaderboardInterface,
		[79] = OptionsInterface,
		[80] = PowersInterface,
		[190] = ShopInterface,
		[188] = QuestsInterface,
	}
	local interfaces_ordered = {_count = 0}
	local profile_request = {}
	local update_at = 0
	local previous_power_quantity = 0
	local reset_powers = false
	local online_staff = {
		next_request = 0,
		next_show = 0,
		requesters = {_count = 0}
	}
	local shown_ranks = {"trainee", "mod", "mapper", "manager", "admin"}
	no_help = {}
	local map_polls = {}
	local current_poll
	
	local function closeAllInterfaces(player)
		for index = 1, interfaces_ordered._count do
			if interfaces_ordered[index].open[player] then
				interfaces_ordered[index]:remove(player)
				break
			end
		end
	
		if Profile.open[player] then
			Profile:remove(player)
		end
		if PowerTracker.open[player] then
			PowerTracker:remove(player)
		end
		if Staff.open[player] then
			Staff:remove(player)
		end
		if ShopInterface.open[player] then
			ShopInterface:remove(player)
		end
		if QuestsInterface.open[player] then
			QuestsInterface:remove(player)
		end
	end
	
	local function checkProfileRequest(player, data)
		local fetch = profile_request[player]
		if fetch then
			local requester = fetch[1]
			if Profile.open[requester] then
				Profile:update(requester, player, data)
			else
				closeAllInterfaces(requester)
				Profile:show(requester, player, data)
			end
			profile_request[player] = nil
		end
	end
	
	local function toggleInterface(interface, player)
		if not players_file[player] then return end
		if not checkCooldown(player, "interfaceTrigger", 500) then return end
	
		if not interface.open[player] then
			closeAllInterfaces(player)
	
			interface:showDefault(player)
		else
			interface:remove(player)
		end
	end
	
	function setNameColor(player)
	    local file = players_file[player]
			if not file then return end
	
	    tfm.exec.setNameColor(
	        player,
	
	        fastest.player == player and 0xFFFFFF -- fastest
	        or victory[player] and 0xFFFF00 -- has won
	
	        or file and not file.hidden and (
	            file.namecolor -- custom
	            or (ranks.admin[player] or ranks.bot[player]) and 0xE7342A -- admin / bot
	            or ranks.manager[player] and 0xD0A9F0 -- manager
	            or (ranks.mod[player] or ranks.trainee[player]) and 0xFFAAAA -- moderator
	            or ranks.mapper[player] and 0x25C059 -- mapper
	            or ranks.translator[player] and 0xE0B856 -- translator
	        )
	        
	        or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
	        or 0x148DE6 -- default
	    )
	end
	
	local function showPoll(player)
		if not current_poll then return end
	
		local interface = current_poll.interface
		local results
		if perms[player] and perms[player].start_round_poll then
			results = current_poll.results
			interface = interface.closer
		elseif current_poll.with_close then
			interface = interface.closer
		end
	
		if current_poll.interface.open[player] then
			interface:update(player, current_poll.translation, current_poll.title, current_poll.buttons, results)
		else
			interface:show(player, current_poll.translation, current_poll.title, current_poll.buttons, results)
		end
	end
	
	onEvent("GameStart", function()
		for key, interface in next, interfaces do
			interfaces_ordered._count = interfaces_ordered._count + 1
			interfaces_ordered[ interfaces_ordered._count ] = interface
		end
	end)
	
	onEvent("Keyboard", function(player, key, down, x, y)
		local interface = interfaces[key]
		if interface then
			if not players_file[player] then return end
			if players_file[player].settings[9] == 1 then return end
			toggleInterface(interface, player)
	
		elseif key == (players_file[player] and players_file[player].settings[2]) or key == 46 then
			if not checkCooldown(player, "keyMort", 1000) then return end
	
			tfm.exec.killPlayer(player)
	
		elseif key == 70 then
			if not players_file[player] then return end
			if not checkCooldown(player, "keyHelp", 3000) then return end
	
			local file = players_file[player]
	
			if file.settings[8] == 1 then
				file.settings[8] = 0
	
				if no_help[player] then
					tfm.exec.removeImage(no_help[player])
					no_help[player] = nil
				end
			else
				file.settings[8] = 1
	
				no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
			end
	
			savePlayerData(player)
		end
	end)
	
	onEvent("TextAreaCallback", function(id, player, callback)
		if not checkCooldown(player, "tacallback", 1000) then return end
	
		if player == "Tocutoeltuco#5522" and callback == "room_state_check" then
			return ui.addTextArea(id, usedRuntime .. "\000" .. totalRuntime .. "\000" .. (cycleId - startCycle), player)
		end
	
		if not players_file[player] then return end
	
		local position = string.find(callback, ":", 1, true)
		local action, args
		if not position then
			eventRawTextAreaCallback(id, player, callback)
		else
			eventParsedTextAreaCallback(id, player, string.sub(callback, 1, position - 1), string.sub(callback, position + 1))
		end
	end)
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		if cmd == "lb" then
			toggleInterface(LeaderboardInterface, player)
	
		elseif cmd == "help" then
			toggleInterface(HelpInterface, player)
	
		elseif cmd == "op" then
			toggleInterface(OptionsInterface, player)
	
		elseif cmd == "poll" then
			if not perms[player] or not perms[player].start_round_poll then return end
	
			if quantity == 0 then
				return translatedChatMessage("invalid_syntax", player)
			end
	
			local action = string.lower(args[1])
			if action == "start" then
				if current_poll then
					return tfm.exec.chatMessage(
						"<v>[#] <r>There is already an ongoing poll on this map. Use <b>!poll see</b> to see the results.", player
					)
				end
	
				current_poll = {
					interface = polls.small[3],
					voters = {},
					with_close = false,
					with_results = false,
					translation = true,
					title = "like_map",
					buttons = {"yes", "no", "idk"},
					results = {total = 0, [1] = 0, [2] = 0, [3] = 0}
				}
				for player in next, in_room do
					if victory[player] or (perms[player] and perms[player].start_round_poll) then
						showPoll(player)
					end
				end
	
			elseif action == "see" then
				if not current_poll then
					return tfm.exec.chatMessage(
						"<v>[#] <r>There is not an active poll on this map. Use <b>!poll start</b> to start a quick one.", player
					)
				end
	
				showPoll(player)
	
			elseif action == "stop" then
				if not current_poll then
					return tfm.exec.chatMessage(
						"<v>[#] <r>There is not an active poll on this map. Use <b>!poll start</b> to start a quick one.", player
					)
				end
	
				if global_poll then
					return tfm.exec.chatMessage(
						"<v>[#] <r>The current poll is automated. You can't stop it.", player
					)
				end
	
				local to_remove, count = {}, 0
				for player in next, current_poll.interface.open do
					count = count + 1
					to_remove[count] = player
				end
	
				for index = 1, count do
					current_poll.interface:remove(to_remove[index])
				end
	
				current_poll = nil
	
			else
				return tfm.exec.chatMessage("<v>[#] <r>Unknown action: <b>" .. action .. "</b>.", player)
			end
	
		elseif cmd == "staff" then
			if Staff.open[player] then return end
	
			local now = os.time()
			if now >= online_staff.next_request then
				online_staff = {
					next_request = now + 60000,
					next_show = now + 1000,
					requesters = {_count = 1, [1] = player}
				}
				online = {}
				hidden = {}
	
				local requested = {}
				local member
				for _, rank in next, shown_ranks do
					for index = 1, ranks[rank]._count do
						member = ranks[rank][index]
	
						if not requested[member] then
							requested[member] = true
							dont_parse_data[member] = true
							system.loadPlayerData(member)
						end
					end
				end
	
			elseif online_staff.next_show ~= 0 then
				online_staff.requesters._count = online_staff.requesters._count + 1
				online_staff.requesters[ online_staff.requesters._count ] = player
	
			else
				closeAllInterfaces(player)
				Staff:show(player)
			end
	
		elseif cmd == "hide" then
			if not perms[player] or not perms[player].hide then return end
			if ranks.hidden[player] then
				return tfm.exec.chatMessage("<v>[#] <r>You're a hidden staff. You can't use this command.", player)
			end
	
			if not players_file[player] then return end
	
			players_file[player].hidden = not players_file[player].hidden
	
			if players_file[player].hidden then
				tfm.exec.chatMessage("<v>[#] <d>You're now hidden. Your nickname will be blue and you won't appear in staff list.", player)
			else
				tfm.exec.chatMessage("<v>[#] <d>You're now visible. Everything's back to normal.", player)
			end
			setNameColor(player)
	
			savePlayerData(player)
	
		elseif cmd == "track" then
			if not perms[player] or not perms[player].use_tracker then return end
	
			if PowerTracker.open[player] then return end
	
			closeAllInterfaces(player)
			PowerTracker:show(player, used_powers)
	
		elseif cmd == "profile" or cmd == "p" then
			if not checkCooldown(player, "interfaceTrigger", 500) then return end
	
			if quantity == 0 then
				if Profile.open[player] then
					Profile:update(player, player)
				else
					closeAllInterfaces(player)
					Profile:show(player, player)
				end
	
			else
				local request = capitalize(args[1])
				if not string.find(request, "#", 1, true) then
					request = request .. "#0000"
				end
	
				if request == "Parkour#0568" or request == "Holybot#0000" then
					return translatedChatMessage("cant_load_bot_profile", player)
				end
	
				if players_file[request] then
					if Profile.open[player] then
						Profile:update(player, request)
					else
						closeAllInterfaces(player)
						Profile:show(player, request)
					end
				else
					profile_request[request] = {player, os.time() + 1000}
					system.loadPlayerData(request)
				end
			end
		elseif cmd == "shop" then
			toggleInterface(ShopInterface, player)
		elseif cmd == "quests" then
			toggleInterface(QuestsInterface, player, 1)
		elseif cmd == "powers" then
			toggleInterface(PowersInterface, player)
		end
	end)
	
	onEvent("GameStart", function()
		tfm.exec.disableMinimalistMode(true)
	
		system.disableChatCommandDisplay("lb")
		system.disableChatCommandDisplay("help")
		system.disableChatCommandDisplay("op")
		system.disableChatCommandDisplay("staff")
		system.disableChatCommandDisplay("track")
		system.disableChatCommandDisplay("profile")
		system.disableChatCommandDisplay("p")
		system.disableChatCommandDisplay("hide")
		system.disableChatCommandDisplay("poll")
	end)
	
	onEvent("PollVote", function(poll, player, button)
		if not current_poll or current_poll.voters[player] then return end
	
		if global_poll then
			sendPacket("common", 8, tostring(button)) -- 1 = yes, 2 = no, 3 = idk
		end
	
		current_poll.voters[player] = true
		current_poll.results.total = current_poll.results.total + 1
		current_poll.results[button] = current_poll.results[button] + 1
	
		local closer = current_poll.interface.closer
		if current_poll.with_results then
			if not current_poll.with_close then
				current_poll.interface:remove(player)
				closer:show(player, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
			else
				closer:update(player, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
			end
	
			for voter in next, current_poll.voters do
				if voter ~= player and closer.open[voter] then
					closer:update(voter, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
				end
			end
	
		elseif current_poll.with_close then
			closer:remove(player)
		
		else
			current_poll.interface:remove(player)
		end
	
		for viewer in next, closer.open do
			if perms[viewer] and perms[viewer].start_round_poll then
				closer:update(viewer, current_poll.translation, current_poll.title, current_poll.buttons, current_poll.results)
			end
		end
	end)
	
	onEvent("RawTextAreaCallback", function(id, player, callback)
		if callback == "settings" then
			toggleInterface(OptionsInterface, player)
		elseif callback == "help_button" then
			toggleInterface(HelpInterface, player)
		elseif callback == "powers" then
			toggleInterface(PowersInterface, player)
		elseif callback == "shop_button" then
			toggleInterface(ShopInterface, player)
		elseif callback == "quests_button" then
			toggleInterface(QuestsInterface, player)
		elseif callback == "leaderboard_button" then
			toggleInterface(LeaderboardInterface, player)
		end
	end)
	
	onEvent("ParsedTextAreaCallback", function(id, player, action, args)
		if action == "emote" then
			local emote = tonumber(args)
			if not emote then return end
	
			tfm.exec.playEmote(player, emote)
		elseif action == "change_quest" then
			if not checkCooldown(player, "changequest", 5000) then return end
	
			local questID, questType = args:match("(%d+):(%d+)") -- questType (1: daily - 2: weekly) 
			questID = tonumber(questID)
	
			if not players_file[player] then return end
			if players_file[player].quests[questID].skp then return end
			
			local isWeekly = tonumber(questType) == 2 and true or false
	
			players_file[player].quests[questID].skp = 0
			local newQuests = fillQuests(players_file[player], players_file[player].quests, isWeekly, true)
			newQuests[questID].skp = os.time()
	
			players_file[player].quests = newQuests
	
			for i = 1, #newQuests do
				if newQuests[i].id == 6 then
					if not power_quest[player] then
						power_quest[player] = {}
					end
	
					if i <= 4 then
						power_quest[player].d = newQuests[i].pr
						power_quest[player].di = i
					else
						power_quest[player].w = newQuests[i].pr
						power_quest[player].wi = i
					end
				end
			end
	
			savePlayerData(player)
	
			closeAllInterfaces(player)
			QuestsInterface:show(player, tonumber(questType))
		end
	end)
	
	onEvent("NewPlayer", function(player)
		for key in next, interfaces do
			bindKeyboard(player, key, true, true)
		end
		bindKeyboard(player, 70, true, true) -- F key
	
		for _player, img in next, no_help do
			tfm.exec.addImage("1722eeef19f.png", "$" .. _player, -10, -35, player)
		end
	
		for _player in next, in_room do
			setNameColor(_player)
		end
	
		if (current_poll
			and not current_poll.voters[player]
			and (victory[player] or (perms[player] and perms[player].start_round_poll))) then
			showPoll(player)
		end
	end)
	
	onEvent("PlayerWon", function(player)
		if (current_poll
			and not current_poll.voters[player]) then
			showPoll(player)
		end
		
		if QuestsInterface.open[player] then
			QuestsInterface:remove(player)
		end
	end)
	
	onEvent("PlayerLeft", function(player)
		GameInterface.open[player] = nil
	end)
	
	onEvent("PlayerRespawn", function(player)
		if no_help[player] then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end
		setNameColor(player)
	end)
	
	onEvent("NewGame", function(player)
		reset_powers = false
		no_help = {}
	
		if current_poll then
			local to_remove, count = {}, 0
			for player in next, current_poll.interface.open do
				count = count + 1
				to_remove[count] = player
			end
	
			for index = 1, count do
				current_poll.interface:remove(to_remove[index])
			end
	
			current_poll = nil
		end
	
		if global_poll then
			-- execute as bot as it has all the permissions
			eventParsedChatCommand("Parkour#0568", "poll", 1, {"start"})
		end
	
		for player in next, in_room do
			if players_file[player] and players_file[player].settings[8] == 1 then
				no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
			end
			setNameColor(player)
		end
	end)
	
	onEvent("PlayerDataParsed", function(player, data)
		bindKeyboard(player, data.settings[2], true, true)
	
		if data.settings[8] == 1 then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end
	
		checkProfileRequest(player, data)
	
		setNameColor(player)
	
		GameInterface:show(player)
	end)
	
	onEvent("OutPlayerDataParsed", checkProfileRequest)
	
	onEvent("Loop", function(elapsed)
		local now = os.time()
	
		local to_remove, count = {}, 0
		for player, data in next, profile_request do
			if now >= data[2] then
				count = count + 1
				to_remove[count] = player
				translatedChatMessage("cant_load_profile", data[1], player)
			end
		end
	
		if not reset_powers and elapsed >= 27000 then
			used_powers = {_count = 0}
			reset_powers = true
		end
	
		if previous_power_quantity ~= used_powers._count then
			previous_power_quantity = used_powers._count
	
			for player in next, PowerTracker.open do
				PowerTracker:update(player, used_powers)
			end
		end
	
		for idx = 1, count do
			profile_request[to_remove[idx]] = nil
		end
	
		if update_at >= now then
			local minutes = math.floor((update_at - now) / 60000)
			local seconds = math.floor((update_at - now) / 1000) % 60
			for player in next, in_room do
				ui.addTextArea(-1, translatedMessage("module_update", player, minutes, seconds), player, 0, 380, 800, 20, 1, 1, 0.7, true)
			end
		end
	
		if online_staff.next_show ~= 0 and now >= online_staff.next_show then
			online_staff.next_show = 0
	
			local room_commu = room.community
			local rank_lists = {}
			local commu, players, list
			local rank_name, rank, info
			local player, tbl, hide
			dont_parse_data = {}
			
			for i = 1, #shown_ranks do
				rank_name = shown_ranks[i]
				rank = ranks[rank_name]
	
				if rank_name == "trainee" then
					rank_name = "mod"
				end
	
				info = rank_lists[rank_name]
				if info then
					players, list, hide = info.players, info.list, info.hide
				else
					players, list, hide = {_count = 0}, {_count = 0}, {_count = 0}
					rank_lists[rank_name] = {
						players = players,
						list = list,
						hide = hide
					}
				end
	
				for index = 1, rank._count do
					player = rank[index]
					commu = online[player]
	
					if commu then
						if commu == room_commu then
							tbl = list
						else
							tbl = players
						end
					elseif hidden[player] then
						tbl = hide
						commu = true
					end
	
					if commu then
						tbl._count = tbl._count + 1
						tbl[ tbl._count ] = player
					end
				end
			end
	
			local offset
			for rank_name, data in next, rank_lists do
				tbl = {_count = data.list._count + data.players._count + data.hide._count}
	
				for i = 1, data.list._count do
					tbl[i] = data.list[i]
				end
	
				offset = data.list._count
				for i = 1, data.players._count do
					tbl[i + offset] = data.players[i]
				end
	
				offset = offset + data.players._count
				for i = 1, data.hide._count do
					tbl[i + offset] = data.hide[i]
				end
	
				Staff.sorted_members[rank_name] = tbl
			end
	
			local player
			for index = 1, online_staff.requesters._count do
				player = online_staff.requesters[index]
				closeAllInterfaces(player)
				Staff:show(player)
			end
		end
	end)
	
	onEvent("PacketReceived", function(channel, id, packet)
		if channel ~= "bots" then return end
	
		if id == 1 then -- game update
			update_at = tonumber(packet)
		end
	end)
	--[[ End of file modes/parkour/ui.lua ]]--
	--[[ File modes/parkour/moderation.lua ]]--
	local files = {
		[1] = 20, -- maps, ranks, chats
		[2] = 21,  -- ranking, weekly
		[3] = 23 -- lowmaps, sanction
	}
	
	local to_do = {}
	local pdataRequest = {}
	local maps_loaded = false
	local cached_files = {
		[tostring(files[3])] = false,
	}
	local reported = {}
	
	-- if it doesn't require save, we can call callback right away using cache
	-- returns true if it hits the cache
	local function schedule(fileid, save, callback)
		if not save and cached_files[tostring(files[fileid])] then
			callback(cached_files[tostring(files[fileid])])
			return true
		end
	
		to_do[#to_do + 1] = { fileid, save, callback }
	end
	
	-- by principle the room player is in has the most up to date player data
	-- and changing player data outside of player's current room is not allowed
	-- so whether you want to save it or not we can return the cached pdata
	-- also returns true if data is from the cache
	local function schedule_player(name, save, callback, timeoutCallback)
		if players_file[name] then
			callback(players_file[name])
			if save then
				savePlayerData(name)
			end
			return true
		end
		pdataRequest[name] = { callback, os.time() + 1000, save, timeoutCallback }
		system.loadPlayerData(name)
	end
	
	local function updateMapList(mapList, map, add)
		for index = #mapList, 1, -1 do
			if mapList[index] == map then
				table.remove(mapList, index)
				break
			end
		end
	
		if add then
			mapList[#mapList + 1] = map
		end
	end
	
	local function in_table(value, tbl)
		for _, v in ipairs(tbl) do
			if v == value then
				return true
			end
		end
		return false
	end
	
	local function checkWeeklyWinners(player, data)
		if not room.playerList[player] then return end
		local id = tostring(room.playerList[player].id)
	
		if not weeklyfile or not weeklyfile.wl or not weeklyfile.wl[id] then 
			return
		end
	
		if os.time() < weeklyfile.wl[id] then
			return
		end
	
		if data.badges[3] ~= 1 then
			data.badges[3] = 1
			NewBadgeInterface:show(player, 3, 1)
			savePlayerData(player, true)
		end
	
		schedule(2, true, function(filedata)
			filedata.weekly.wl[id] = nil
		end)
	end
	
	local function sendBanLog(playerName, time, target, minutes)
	    if not time then
	        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned.", target)
	    elseif time > 2 then
	        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned for " .. minutes .. " minutes.", target)
	    elseif time == 2 then
	        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been banned permanently.", target)
	    else
	        tfm.exec.chatMessage("<v>[#] <j>" .. playerName .. " has been unbanned.", target)
	    end
	end
	
	onEvent("GameDataLoaded", function(data, fileid)
		local action
		local save
		local len = #to_do
	
		for index = 1, len do
			action = to_do[index]
			if files[action[1]] == tonumber(fileid) then
				action[3](data)
				save = action[2]
				to_do[index] = false
			end
		end
	
		for index = len, 1, -1 do
			if not to_do[index] then
				table.remove(to_do, index)
			end
		end
	
		if cached_files[fileid] ~= nil then
			cached_files[fileid] = data
		end
	
		if data.lowmaps then
			maps_loaded = true
		end
	
		if data.sanction then
			local now = os.time()
			local playerList = room.playerList
			local id, banInfo, banDays
	
			for player, pdata in next, players_file do
				if playerList[player] and in_room[player] then
					id = tostring(playerList[player].id)
					banInfo = id and data.sanction[id]
	
					if banInfo and banInfo.timestamp ~= pdata.lastsanction then
						pdata.bancount = banInfo.level
						pdata.lastsanction = banInfo.timestamp
						pdata.bannedby = banInfo.info
						pdata.banned = banInfo.time
	
						savePlayerData(player)
	
						local minutes = pdata.banned and math.floor((pdata.banned - os.time()) / 1000 / 60)
	                    if ranks.hidden[pdata.bannedby] then
	                        for moderator in pairs(room.playerList) do
	                            if ranks.admin[moderator] or ranks.mod[moderator] then
	                                sendBanLog(player, pdata.banned, moderator, minutes)
	                            end
	                        end
	                    else
	                        sendBanLog(player, pdata.banned, nil, minutes)
	                	end
					end
	
					if pdata.banned and (pdata.banned == 2 or os.time() < pdata.banned) then
						if not banInfo then
							local sanctionLevel = pdata.banned == 2 and 4 or 1
	                        data.sanction[tostring(id)] = {
	                            timestamp = 0,
	                            time = pdata.banned,
	                            info = "-",
								level = sanctionLevel,
	                        }
	                        save = true
	                    end
						
						if pdata.banned == 2 then
							translatedChatMessage("permbanned", player)
						else
							local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
							translatedChatMessage("tempbanned", player, minutes)
						end
					end
				end
			end
		end
	
		if save or (data.ranking or data.weekly) then
			eventSavingFile(fileid, data)
		end
	end)
	
	local function playerDataRequests(player, data)
		local fetchData = pdataRequest[player]
		if fetchData then
			fetchData[1](data)
	
			if fetchData[3] then
				system.savePlayerData(player, json.encode(data))
			end
	
			pdataRequest[player] = nil
		end
	end
	
	local function updateSanctions(playerID, playerName, time, moderator, minutes)
		schedule(3, true, function(data)
			local now = os.time()
	
			playerID = tostring(playerID)
			playerName = playerName or playerID
			time = time or (now + minutes * 60 * 1000)
	
			local baninfo = data.sanction[playerID]
			if time > 0 then
				if baninfo and (baninfo.time == 2 or baninfo.time > now) and not minutes then
					tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " is banned already.", moderator)
					return
				end
			else
				if not baninfo or baninfo.time < 1 then
					tfm.exec.chatMessage("<v>[#] <r>" .. playerName .. " doesn't seem to be banned.", moderator)
					return
				end
			end
	
			local sanctionLevel = baninfo and baninfo.level or 0
			if time == 1 then
				sanctionLevel = math.min(4, sanctionLevel + 1)
				if sanctionLevel == 1 then
					time = now + 86400000 -- 1 day
					minutes = 1440
				elseif sanctionLevel == 2 then
					time = now + 86400000 * 7
					minutes = 10080
				elseif sanctionLevel == 3 then
					time = now + 86400000 * 30
					minutes = 43200
				else
					time = 2 -- permanent ban
					minutes = 2
				end
			elseif time == -1 then
				sanctionLevel = math.max(0, sanctionLevel - 1)
				time = 0
				minutes = 0
			end
	
			data.sanction[playerID] = {
				timestamp = now,
				time = time,
				info = moderator,
				level = sanctionLevel
			}
	
			sendPacket(
				"common",
				packets.rooms.ban_logs,
				playerID .. "\000" ..
				playerName .. "\000" ..
				time .. "\000" ..
				moderator .. "\000" ..
				minutes .. "\000" ..
				-- prev sanction
				(baninfo and baninfo.timestamp or "-") .. "\000" ..
				(baninfo and baninfo.time or "-") .. "\000" ..
				(baninfo and baninfo.info or "-") .. "\000" ..
				(baninfo and baninfo.level or "-")
			)
			sendBanLog(playerName, time, moderator, minutes)
		end)
	end
	
	function inGameLogCommand(p, command, args)
		local commandtext = table.concat(args, " ")
		for playername, player in pairs(tfm.get.room.playerList) do
			if ranks.admin[playername] or ranks.mod[playername] then
				tfm.exec.chatMessage("<BL>Ξ [" .. p .. "]<N2> !" .. command .. " " .. commandtext, playername)
			end
		end
	end
	
	local function handleBan(player, cmd, quantity, args)
		if not ranks.admin[player] and (not perms[player] or not perms[player].ban) then
			return
		end
	
		if quantity < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		inGameLogCommand(player, cmd, args)
	
		local targetPlayer = args[1]
		local moderator = player
		local time = cmd == 'ban' and 1 or -1 -- ban time changes depending on players previous bans
	
		logCommand(player, cmd, math.min(quantity, 2), args)
	
		-- Ban by player id
		if tonumber(targetPlayer) then
			tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
			updateSanctions(targetPlayer, nil, time, moderator)
			return
		end
	
		targetPlayer = capitalize(targetPlayer)
		if not string.find(targetPlayer, "#", 1, true) then
			targetPlayer = targetPlayer .. "#0000"
		end
	
		tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
		-- Ban a player using their name (in the room)
		local roomPlayer = room.playerList[targetPlayer]
		if roomPlayer then
			updateSanctions(roomPlayer.id, targetPlayer, time, moderator)
			return
		end
	
		-- Ban a player using their name
		schedule_player(targetPlayer, false, function(pdata)
			if not pdata.playerid then
				tfm.exec.chatMessage("<v>[#] <r>The player cannot be (un)banned this way, try player id.", player)
				return
			end
	
			updateSanctions(pdata.playerid, targetPlayer, time, moderator)
		end, function()
			tfm.exec.chatMessage("<v>[#] <r>Player doesn't seem to be online, try player id.", player)
		end)
	end
	
	local function handleAdminBan(player, cmd, quantity, args)
		if not ranks.admin[player] then
			return
		end
	
		if cmd == "pban" and quantity < 2 then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		if cmd == "punban"  and quantity < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		local isPerma = args[2] == "perma"
		local minutes = tonumber(args[2])
		local targetPlayer = args[1]
		local playerID = tonumber(targetPlayer)
	
		if cmd == "pban" and (not minutes or minutes < 0) then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		inGameLogCommand(player, cmd, args)
	
		local sanctionTime
	
		if cmd == "pban" then
			if isPerma or minutes == 1 then
				sanctionTime = 2
			else
				sanctionTime = nil
			end
		else
			sanctionTime = 0
			minutes = 0
		end
	
		-- Ban using name (must be in the same room)
		tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
		if not playerID then
			local roomPlayer = room.playerList[targetPlayer]
	
			if not roomPlayer then
				tfm.exec.chatMessage("<v>[#] <r>You cannot ban a player with their player name if you don't share the same room. Please use their player ID instead.", player)
				return
			end
	
			updateSanctions(roomPlayer.id, targetPlayer, sanctionTime, player, minutes)
	
			return
		end
	
		-- Ban by player id
		updateSanctions(playerID, nil, sanctionTime, player, minutes)
	end
	
	local function handleMap(player, cmd, quantity, args)
		if not ranks.admin[player] and not ranks.mapper[player] and not ranks.manager[player] then
			return
		end
	
		local addmap = cmd == "addmap" and true or false
	
		inGameLogCommand(player, cmd, args)
	
		if addmap then
			logCommand(player, "addmap", math.min(quantity, 3), args)
		else
			logCommand(player, "removemap", math.min(quantity, 2), args)
		end
	
		if not maps_loaded then
			tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds.", player)
			return
		end
	
		if addmap and quantity < 2 then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		if not addmap and quantity < 1 then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		local mapcode = args[1]
		if not tonumber(mapcode) then
			mapcode = mapcode:gsub("^@", "")
			if not tonumber(mapcode) then
				return tfm.exec.chatMessage("<v>[#] <r>Invalid map code", player)
			end
		end
	
		for i = 1, #to_do do
			if to_do[i] and tonumber(to_do[i][2]) == tonumber(mapcode) then
				tfm.exec.chatMessage("<v>[#] <r>Please wait for a minute before taking any action with the same map.", player)
				return
			end
		end
	
		if addmap then
			mapcode = tonumber(mapcode)
			local rotation = args[2]
			if rotation ~= "low" and rotation ~= "high" then
				tfm.exec.chatMessage("<v>[#] <r>Select a priority: low, high", player)
				return
			end
	
			if in_table(mapcode, maps.list_low) or in_table(mapcode, maps.list_high) then
				tfm.exec.chatMessage("<v>[#] <r>Map @" .. mapcode .. " is already in rotation.", player)
				return
			end
	
			if rotation == "low" then
				schedule(3, true, function(data)
					updateMapList(data.lowmaps, mapcode, true)
					tfm.exec.chatMessage("<v>[#] <j>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
				end)
			else
				schedule(1, true, function(data)
					updateMapList(data.maps, mapcode, true)
					tfm.exec.chatMessage("<v>[#] <j>Map @" .. mapcode .. " added to the " .. rotation .. " priority list.", player)
				end)
			end
	
		else
			for i = 1, #args do
				mapcode = args[i]:gsub("^@", "")
				mapcode = mapcode and tonumber(mapcode) 
				if not mapcode then
					return tfm.exec.chatMessage("<v>[#] <r>Invalid map code: "..args[i], player)
				end
				args[i] = mapcode
			end
	
			local removeHigh = {}
			local removeLow = {}
			local notFound = {}
	
			for i = 1, #args do
				mapcode = args[i]
				if in_table(mapcode, maps.list_high) then
					removeHigh[1 + #removeHigh] = mapcode
				elseif in_table(mapcode, maps.list_low) then
					removeLow[1 + #removeLow] = mapcode
				else
					notFound[1 + #notFound] = mapcode
				end
			end
	
			if #notFound > 0 then
				tfm.exec.chatMessage("<v>[#] <r>Could not find following maps in any of the priority lists: " .. table.concat(notFound, ", "), player)
			end
			
			if #removeHigh > 0 or #removeLow > 0 then
				tfm.exec.chatMessage("<v>[#] <j>Scheduled remaining maps to be removed.", player)
			end
	
			if #removeHigh > 0 then
				schedule(1, true, function(data)
					for i = 1, #removeHigh do
						updateMapList(data.maps, removeHigh[i], false)
					end
					tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the high priority list: " .. table.concat(removeHigh, ", "), player)
				end)
			end
	
			if #removeLow > 0 then
				schedule(3, true, function(data)
					for i = 1, #removeLow do
						updateMapList(data.lowmaps, removeLow[i], false)
					end
					tfm.exec.chatMessage("<v>[#] <j>Following maps are removed from the low priority list: " .. table.concat(removeLow, ", "), player)
				end)
			end
		end
	end
	
	local function printSanctions(target, kind, name, pid, timestamp, time, level, mod, minutes)
		local banState = ""
	
		if not time then
			banState = "has never been banned before "
		elseif time == 0 then
			banState = "was unbanned "
		elseif time == 2 or time > os.time() then
			banState = "is <r>currently banned</r> "
		else
			banState = "was banned "
		end
	
		local byMod = mod and ("by <bv>" .. mod .. "</bv> ") or ""
		local forMinutes = ""
		local onDate = ""
		local minRemaining = ""
	
		if timestamp then
			if time then
				if time == 2 then
					forMinutes = "permanently "
				elseif time > 2 then
					local minutes = math.floor((time - timestamp) / 1000 / 60)
					forMinutes = "for <v>" .. minutes .. "</v> minutes "
				end
			end
	
			onDate = "on <bl>" .. os.date("%B %d %Y %H:%M.%S", timestamp) .. "</bl> (france time) "
		end
	
		if time and minutes then
			forMinutes = "for <v>" .. minutes .. "</v> minutes "
		end
	
		if time and time > 2 then
			local minutes = math.floor((time - os.time()) / 1000 / 60)
	
			if minutes >= 0 then
				minRemaining = "and has <v>" .. minutes .. "</v> minutes remaining "
			end
		end
	
		tfm.exec.chatMessage(
			("<v>[#] <n>(%s) <n2>%s</n2> %s%s%s%s%s<g>[level %s] [ts %s] [pid %s]"):format(
				kind,
				name,
				banState,
				byMod,
				forMinutes,
				onDate,
				minRemaining,
				level or 0,
				time or "-",
				pid or "-"
			),
			target
		)
	end
	
	local function handleSanctions(player, cmd, quantity, args)
		if not perms[player] or not perms[player].view_sanctions then
			return
		end
	
		if quantity < 1 then
			translatedChatMessage("invalid_syntax", player)
			return
		end
	
		local targetName = capitalize(args[1])
		local targetID = tonumber(targetName)
	
		if targetID then
			targetName = nil
		else
			if not string.find(targetName, "#", 1, true) then
				targetName = targetName .. "#0000"
			end
	
			if room.playerList[targetName] then
				targetID = room.playerList[targetName].id
			end
		end
	
		if targetID then
			targetID = tostring(targetID)
		end
	
		if ranks.admin[player] then
			if args[2] == "reset" then
				if not targetID then
					tfm.exec.chatMessage("<v>[#] <r>You must provide a player id.", player)
					return
				end
	
				inGameLogCommand(player, cmd, args)
	
				tfm.exec.chatMessage("<v>[#] <J>Scheduled the command.", player)
				schedule(3, true, function(data)
					local file = data.sanction and data.sanction[targetID]
					if not file or not file.level or file.level == 0 then
						tfm.exec.chatMessage(
							("<v>[#] <j>%s's sanction level is already at zero."):format(
								targetName or targetID
							),
							player
						)
						return
					end
	
					file.level = 0
					tfm.exec.chatMessage(
						("<v>[#] <j>%s's sanction level has been reset."):format(
							targetName or targetID
						),
						player
					)
				end)
				return
			end
		end
	
		if targetName then
			local is_cached = schedule_player(targetName, false, function(pdata)
				if pdata.kill or pdata.killed then
					printSanctions(
						player,
						'powerban',
						targetName,
						pdata.playerid,
						pdata.killed ~= 0 and pdata.kill ~= 0 and
						(pdata.killed - pdata.kill * 60 * 1000) or nil,
						pdata.killed ~= 0 and pdata.killed or nil,
						'-',
						pdata.killedby,
						pdata.kill
					)
				end
	
				printSanctions(
					player,
					'pdata',
					targetName,
					pdata.playerid,
					pdata.lastsanction,
					pdata.banned,
					pdata.bancount,
					pdata.bannedby
				)
	
				if not targetID and pdata.playerid then
					targetID = pdata.playerid
					local is_cached = schedule(3, false, function(data)
						local file = data and data.sanction and data.sanction[targetID]
						if not file then
							tfm.exec.chatMessage(
								("<v>[#] <r>%s not found in file data"):format(targetID),
								player
							)
							return
						end
						printSanctions(
							player,
							'file',
							targetName or targetID,
							targetID,
							file.timestamp,
							file.time,
							file.level,
							file.info
						)
					end)
					if not is_cached then
						tfm.exec.chatMessage(
							("<v>[#] <bl>Checking file data for %s's sanctions..."):format(targetName),
							player
						)
					end
				end
			end)
			if not is_cached then
				tfm.exec.chatMessage(
					("<v>[#] <bl>Checking player data for %s's sanctions..."):format(targetName),
					player
				)
			end
		end
	
		if targetID then
			local is_cached = schedule(3, false, function(data)
				local file = data and data.sanction and data.sanction[targetID]
				if not file then
					tfm.exec.chatMessage(
						("<v>[#] <r>%s not found in file data"):format(targetID),
						player
					)
					return
				end
				printSanctions(
					player,
					'file',
					targetName or targetID,
					targetID,
					file.timestamp,
					file.time,
					file.level,
					file.info
				)
			end)
			if not is_cached then
				tfm.exec.chatMessage(
					("<v>[#] <bl>Checking file data for %s's sanctions..."):format(targetName),
					player
				)
			end
		end
	end
	
	local function warnPlayer(player, cmd, quantity, args)
		if not ranks.admin[player] and (not perms[player] or not perms[player].kill) then
			return
		end
	
		inGameLogCommand(player, cmd, args)
	
		if quantity < 2 then
			translatedChatMessage("invalid_syntax", player)
			return
		end
	
		local requestplayer = capitalize(args[1])
		local killedTime = args[2]
	
		if not tonumber(killedTime) then
			tfm.exec.chatMessage("<v>[#] <r>" ..killedTime.. " doesn't seem like a number.", player)
			return
		end
		
		if not string.find(requestplayer, "#", 1, true) then
			requestplayer = requestplayer .. "#0000"
		end
	
		local roomPlayer = room.playerList[requestplayer]
		if not in_room[requestplayer] or not roomPlayer then
			tfm.exec.chatMessage("<v>[#] <r>" ..requestplayer.. " isn't here.", player)
			return
		end
	
		logCommand(player, "kill", math.min(quantity, 2), args)
		sendPacket(
			"common",
			packets.rooms.kill_logs,
			requestplayer .. "\000" ..
			killedTime .. "\000" ..
			player .. "\000" ..
			roomPlayer.id
		)
	
		schedule_player(requestplayer, true, function(pdata)
			sendPacket(
				"common",
				packets.rooms.prev_kill,
				requestplayer .. "\000" ..
				roomPlayer.id .. "\000" ..
				pdata.killed .. "\000" ..
				pdata.kill .. "\000" ..
				(pdata.killedby or '-')
			)
	
			pdata.killedby = player
			pdata.killed = os.time() + killedTime * 60 * 1000
			pdata.kill = killedTime
	
			tfm.exec.chatMessage("<v>[#] <V>"..requestplayer.. " <j>can't use their powers for <b>"..killedTime.."</b> minutes.", nil)
			translatedChatMessage("killed", requestplayer, killedTime)
			checkKill(requestplayer)
		end)
	end
	
	local function handleSetrank(player, cmd, quantity, args)
		if not ranks.admin[player] and not ranks.bot[player] then
			return
		end
	
		inGameLogCommand(player, cmd, args)
	
		if args[1] == player then
			tfm.exec.chatMessage("<v>[#] <r>You can't change your rank.", player)
			return
		end
	
		local targetPlayer = capitalize(args[1])
		local newRanks = {}
		local ID = 0
	
		if not string.find(targetPlayer, "#", 1, true) then
			targetPlayer = targetPlayer .. "#0000"
		end
	
		if quantity < 2 then
			translatedChatMessage("invalid_syntax", player)
			return
		end
	
		if args[2] ~= "none" then
			for i = 2, #args do
				if ranks_id[args[i]] then
					ID = ID + ranks_id[args[i]]
					newRanks[args[i]] = true
				else
					return tfm.exec.chatMessage("<v>[#] <r>Invalid rank: " .. args[i], player)
				end
			end
		end
	
		if ID == 0 then
			player_ranks[targetPlayer] = nil
			ID = nil
			tfm.exec.chatMessage("<v>[#] <r>All ranks removed from " .. targetPlayer, player)
		else
			player_ranks[targetPlayer] = newRanks
			tfm.exec.chatMessage("<v>[#] <r>Ranks has been set.", player)
		end
	
		schedule(1, true, function(data)
			data.ranks[targetPlayer] = ID
		end)
		logCommand(player, cmd, quantity, args)
	end
	
	local printSanctionList
	
	local function fileActions(player, cmd, quantity, args)
		if not ranks.admin[player] and not ranks.bot[player] then
			return
		end
	
		if quantity < 2 then
			translatedChatMessage("invalid_syntax", player)
			return
		end
	
		local fileName = args[1]
	
		if fileName == "weekly" then
			local fileAction = args[2]
			if fileAction == "view" then
				if weeklyfile and weeklyfile.ts and weeklyfile.wl then
					tfm.exec.chatMessage(('<v>[#] <j>Timestamp: %s <bl>(%s)'):format(
						tonumber(weeklyfile.ts) and os.date("%Y %B %d", weeklyfile.ts) or '???',
						tostring(weeklyfile.ts)
					), player)
					tfm.exec.chatMessage("<v>[#] <j>Unclaimed badge winners:", player)
	
					for name, ts in next, weeklyfile.wl do
						tfm.exec.chatMessage(('<v>%s<bl>: %s <g>(%s)'):format(
							name,
							tonumber(ts) and os.date("%Y %B %d", ts) or '???',
							tostring(ts)
						), player)
					end
				else
					tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
				end
	
			elseif fileAction == "last" then
				local date = "???"
				if last_weekly_reset_ts then
					date = os.date("%Y %B %d", last_weekly_reset_ts)
				end
				tfm.exec.chatMessage(
					("<v>[#] <j>Last weekly reset: <j>%s <bl>(%s)"):format(
						date,
						tostring(last_weekly_reset_ts)
					),
					player
				)
	
			elseif fileAction == "add" then
	
				if quantity < 3 then
					translatedChatMessage("invalid_syntax", player)
					return
				end
	
				inGameLogCommand(player, cmd, args)
	
				local count = tonumber(args[4]) or 100
	
				local requestplayer = capitalize(args[3])
				if not string.find(requestplayer, "#", 1, true) then
					requestplayer = requestplayer .. "#0000"
				end
	
				schedule_player(requestplayer, true, function(pdata)
					pdata.week[1] = pdata.week[1] + count
					tfm.exec.chatMessage("<v>[#] <j>"..requestplayer.."'s new weekly count: "..pdata.week[1], player)
				end)
			end
		elseif fileName == "maps" then
			local category = args[2]
			local len
			if category == "all" or category == "high" then
				len = #maps.list_high
				tfm.exec.chatMessage("<v>[#] <v>high maps: " .. tostring(len), player)
				for i=1, len, 20 do
					tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(maps.list_high, ' ', i, math.min(i+19, len)), player)
				end
			end
			if category == "all" or category == "low" then
				len = #maps.list_low
				tfm.exec.chatMessage("<v>[#] <v>low maps: " .. tostring(len), player)
				for i=1, len, 20 do
					tfm.exec.chatMessage("<v>[#] <bl>" .. table.concat(maps.list_low, ' ', i, math.min(i+19, len)), player)
				end
			end
		elseif fileName == "staff" then
			local rankName = args[2]
			if rankName == "all" then
				local list, count
				for staffName, hasRanks in next, player_ranks do
					list, count = {}, 0
					for rankName in next, hasRanks do
						count = count + 1
						list[count] = rankName
					end
					tfm.exec.chatMessage("<v>[#] <v>" .. staffName .. "<bl>: " .. table.concat(list, ' '), player)
				end
				return
			end
	
			local list = ranks[rankName]
			if not list then
				tfm.exec.chatMessage("<v>[#] <r>Invalid rank namme.", player)
				return
			end
	
			tfm.exec.chatMessage("<v>[#] <j>" .. rankName .. ":", player)
			for i=1, list._count, 10 do
				tfm.exec.chatMessage(table.concat(list, ' ', i, math.min(i+9, list._count)), player)
			end
	
		elseif fileName == "sanction" then
			local fileAction = args[2]
			if fileAction == "list" then
				local page = tonumber(args[3]) or 1
				printSanctionList(player, nil, page)
			else
				printSanctionList(player, fileAction)
			end
		end
	end
	
	printSanctionList = function(player, targetID, page)
		local is_cached = schedule(3, false, function(data)
			local sanctions_file = data.sanction
			if not targetID then
				local page_size = 180
	
				local playerIDs, len = {}, 0
				for playerID in next, sanctions_file do
					len = len + 1
					playerIDs[len] = playerID
				end
				table.sort(playerIDs)
	
				local totalPages = math.ceil(len / page_size)
	
				if not page or page < 1 or page > totalPages then
					tfm.exec.chatMessage("<v>[#] <j>Invalid page number. Available pages: 1 - " .. totalPages, player)
					return
				end
	
				local startIndex = (page - 1) * page_size + 1
				local endIndex = math.min(startIndex + page_size - 1, len)
				local message = table.concat(playerIDs, ', ', startIndex, endIndex)
	
				tfm.exec.chatMessage("<v>[#] <j>" ..message, player)
			else
				if not tonumber(targetID) then
					tfm.exec.chatMessage("<v>[#] <j>"..targetID.." doesn't seem like player id?", player)
					return
				end
	
				if not sanctions_file[targetID] then 
					tfm.exec.chatMessage("<v>[#] <j>The file has not been loaded yet or does not exist.", player)
					return
				end
	
				local playerFile = sanctions_file[targetID]
				tfm.exec.chatMessage("<v>[#] <j>Timestamp: "..playerFile.timestamp, player)
				tfm.exec.chatMessage("<v>[#] <j>Time: "..playerFile.time, player)
				tfm.exec.chatMessage("<v>[#] <j>Info: "..playerFile.info, player)
				tfm.exec.chatMessage("<v>[#] <j>Level: "..playerFile.level, player)
			end
		end)
	
		if not is_cached then
			tfm.exec.chatMessage("<v>[#] <j>Loading the sanctions file...", player)
		end
	end
	
	function roomAnnouncement(player, cmd, quantity, args)
		if not ranks.admin[player] and not ranks.manager[player] then
			return
		end
	
		inGameLogCommand(player, cmd, args)
	
		local announcementtext = table.concat(args, " ")
		tfm.exec.chatMessage("<ROSE>Ξ [Parkour] <N>"..announcementtext)
	end
	
	local function editCoins(player, cmd, quantity, args)
		if not ranks.admin[player] then
			return
		end
	
		if quantity < 2 then
			translatedChatMessage("invalid_syntax", player)
			return
		end
	
		local playerName = args[1]
		local action = args[2]
	
		if not in_room[playerName] or not players_file[playerName] then
			return tfm.exec.chatMessage(playerName.." is not here.", player)
		end
	
		if action == "show" then
			local result = ""
			for key, value in pairs(players_file[playerName].skins) do
				result = result .. key .. ", "
			end
			result = result:sub(1, -3)
			
			tfm.exec.chatMessage("Current coins: " ..players_file[playerName].coins, player)
			tfm.exec.chatMessage("Skins: " ..result, player)
			return
	
		elseif action == "default" then
			players_file[playerName].cskins = { 1, 2, 7, 28, 46 }
			savePlayerData(playerName)
			tfm.exec.chatMessage("<v>[#] <j>Current skins set default for " ..playerName, player)
	
		elseif action == "refund" then
			if quantity < 3 then
				translatedChatMessage("invalid_syntax", player)
				return
			end
	
			local skinType = tonumber(args[3])
			local skinNumber = tonumber(args[4])
	
			local selectedSkin = skinType and skinNumber and shop_items[skinType] and shop_items[skinType][skinNumber]
			if not selectedSkin then
				return tfm.exec.chatMessage("Invalid skin type or skin number.", player)
			end
	
			if not players_file[playerName].skins[tostring(selectedSkin.id)] then
				return tfm.exec.chatMessage("The player doesn't have this skin. ", player)
			end
			
			players_file[playerName].skins[tostring(selectedSkin.id)] = nil
			players_file[playerName].coins = players_file[playerName].coins + tonumber(selectedSkin.price)
	
			for i = #players_file[playerName].cskins, 1, -1 do
				if players_file[playerName].cskins[i] == tonumber(selectedSkin.id) then
					players_file[playerName].cskins[i] = shop_items[skinType][1].id
				end
			end
	
			savePlayerData(playerName)
			tfm.exec.chatMessage("<v>[#] <j>Refunded " ..selectedSkin.price.. " coins (" ..skinType.. "/" ..skinNumber..") to the "..playerName, player)
	
		end
	
		inGameLogCommand(player, cmd, args)
	end
	
	local function setChristmasMap(player, cmd, quantity, args)
		if not ranks.admin[player] then
			return
		end
	
		gift_conditions._completed = gift_conditions._complete - 1
		gift_conditions._ts = os.time()
	end
	
	local function disableSnow(player, cmd, quantity, args)
		tfm.exec.snow(0, 10)
	end
	
	local function linkMouse(player, cmd, quantity, args)
		if not ranks.admin[player] then
			return
		end
	
		if not args[1] then return end
		if not args[2] then 
			args[2] = player
		end
	
		local firstPlayer = args[1]
		local secondPlayer = args[2]
	
		tfm.exec.linkMice(firstPlayer, secondPlayer, true)
	end
	
	local function changeMouseSize(player, cmd, quantity, args)
		if not ranks.admin[player] then return end
	
		local target = args[1]
		local size = tonumber(args[2])
		if not room.playerList[target] or not size then
			return translatedChatMessage("invalid_syntax", player)
		end
	
		tfm.exec.changePlayerSize(target, size)
		return
	end
	
	local mouseImages = {}
	local function addMouseImage(player, cmd, quantity, args)
		if quantity == 0 then
			if mouseImages[player] then
				tfm.exec.removeImage(mouseImages[player][2], false)
				tfm.exec.killPlayer(player)
				mouseImages[player] = nil
			end
			return
		end
	
		if not ranks.admin[player] then return end
	
		local playerName = args[1]
		local imageURL = args[2]
		local scale = tonumber(args[3]) or 1
		local offsetX = tonumber(args[4]) or 0
		local offsetY = tonumber(args[5]) or 0
		local opacity = tonumber(args[6]) or 1
	
		if playerName == "*" then
			if imageURL == "remove" then
				for _, img in next, mouseImages do
					tfm.exec.removeImage(img[2], false)
				end
				mouseImages = {}
				return
			elseif imageURL then
				for name in next, tfm.get.room.playerList do	
					if mouseImages[name] then
						tfm.exec.removeImage(mouseImages[name][2], false)
					end
	
					local imageID = tfm.exec.addImage(imageURL, '%'..name, offsetX, offsetY, nil, scale, scale, 0, opacity, 0.5, 0.5, false)
					mouseImages[name] = {imageURL, imageID, 1, scale, offsetX, offsetY, opacity}
	
					translatedChatMessage("new_image", name)
				end
				return
			end
		end
	
		if not playerName or not imageURL or not room.playerList[playerName] then
			return translatedChatMessage("invalid_syntax", player)
		end
	
	
		if mouseImages[playerName] then
			tfm.exec.removeImage(mouseImages[playerName][2], false)
		end
	
		if imageURL == "remove" then
			mouseImages[playerName] = nil
			return
		elseif not mouseImages[playerName] or mouseImages[playerName][1] ~= imageURL then
			translatedChatMessage("new_image", playerName)
		end
	
		local imageID = tfm.exec.addImage(imageURL, '%'..playerName, offsetX, offsetY, nil, scale, scale, 0, opacity, 0.5, 0.5, false)
		mouseImages[playerName] = {imageURL, imageID, 1, scale, offsetX, offsetY, opacity}
	end
	
	onEvent("Keyboard", function(player, key, down)
		local img = mouseImages[player]
	
		if not img then return end
	
		if key == 2 then
			tfm.exec.removeImage(img[2], false)
			local imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[4], img[4], 0, img[7], 0.5, 0.5, false)
			img[2] = imageID
			img[3] = 1
		elseif key == 0 then
			tfm.exec.removeImage(img[2], false)
			local imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, -img[4], img[4], 0, img[7], -0.5, 0.5, false)
			img[2] = imageID
			img[3] = -1
		elseif key == 3 then
			tfm.exec.removeImage(img[2], false)
			local anchorX = img[3] == 1 and 0.5 or -0.5
			local imageID
	
			if down then
				imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[3] * img[4], img[4] / 2.0, 0, img[7], anchorX, 0.5, false)
			else
				imageID = tfm.exec.addImage(img[1], '%'..player, img[5], img[6], nil, img[3] * img[4], img[4], 0, img[7], anchorX, 0.5, false)
			end
	
			img[2] = imageID
		end
	end)
	
	local function handleReport(playerName, cmd, quantity, args)
		local pdata = players_file[playerName]
		local player = room.playerList[playerName]
		if not pdata or not player or not pdata.report or bans[player.id] then
			return
		end
	
		local timestamp = os.time()
		local regDate = player.registrationDate
		-- Accounts registered less than 1 week ago
		if not regDate or regDate > timestamp - 7 * 24 * 60 * 60 * 1000 then
			return
		end
	
		if quantity < 2 then
			return translatedChatMessage("cmd_usage_report", playerName)
		end
	
		local reportedName = args[1]:lower():gsub('^+?[a-z]', string.upper)
		local reportedPlayer = room.playerList[reportedName]
		if not reportedPlayer then
			return translatedChatMessage("reported_not_here", playerName)
		end
		if reportedPlayer.id == 0 or reportedName:sub(1, 1) == "*" or bans[reportedPlayer.id] or reportedName == playerName then
			return translatedChatMessage("reported_invalid", playerName)
		end
	
		local reason = table.concat(args, ' ', 2, quantity)
		if #reason < 5 then
			return translatedChatMessage("reason_too_short", playerName)
		end
	
		if reported[reportedName] then
			if reported[reportedName][playerName] then
				return translatedChatMessage("report_done", playerName)
			end
		else
			reported[reportedName] = {}
		end
	
		reported[reportedName][playerName] = true
	
		sendPacket(
			"common", packets.rooms.report,
			timestamp .. "\000" ..
			player.id .. "\000" ..
			playerName .. "\000" ..
			reportedPlayer.id .. "\000" ..
			reportedName .. "\000" ..
			room.shortName .. "\000" ..
			reason
		)
		translatedChatMessage("report_done", playerName)
	end
	
	local function handleKarma(playerName, cmd, quantity, args)
		if not ranks.admin[playerName] and not ranks.mod[playerName] then
			return
		end
	
		if quantity < 1 then
			return translatedChatMessage("invalid_syntax", playerName)
		end
	
		local target = args[1]:lower():gsub('^+?[a-z]', string.upper)
		local pdata = players_file[target]
		if not room.playerList[target] or not pdata then
			return translatedChatMessage("invalid_syntax", playerName)
		end
	
		if quantity == 1 then
			if pdata.report then
				tfm.exec.chatMessage('<v>[#] <vp>' .. target .. ' can use !report.', playerName)
			else
				tfm.exec.chatMessage('<v>[#] <r>' .. target .. ' cannot use !report.', playerName)
			end
			return
		end
	
		inGameLogCommand(playerName, cmd, args)
	
		local yes = args[2] == 'yes'
		if not yes and args[2] ~= 'no' then
			return translatedChatMessage("invalid_syntax", playerName)
		end
	
		if pdata.report == yes then
			tfm.exec.chatMessage('<v>[#] <bl>Nothing changed.', playerName)
			return
		end
	
		pdata.report = yes
		savePlayerData(target)
		tfm.exec.chatMessage('<v>[#] <n>Done.', playerName)
		logCommand(playerName, cmd, math.min(quantity, 2), args)
	end
	
	local commandDispatch = {
		["ban"] = handleBan,
		["unban"] = handleBan,
		["pban"] = handleAdminBan,
		["punban"] = handleAdminBan,
		["addmap"] = handleMap,
		["removemap"] = handleMap,
		["bancount"] = handleSanctions,
		["baninfo"] = handleSanctions,
		["sanctions"] = handleSanctions,
		["setrank"] = handleSetrank,
		["file"] = fileActions,
		["kill"] = warnPlayer,
		["announcement"] = roomAnnouncement,
		["coins"] = editCoins,
		["christmas"] = setChristmasMap,
		["snow"] = disableSnow,
		["link"] = linkMouse,
		["size"] = changeMouseSize,
		["image"] = addMouseImage,
		["report"] = handleReport,
		["karma"] = handleKarma,
	}
	
	onEvent("ParsedChatCommand", function(player, cmd, quantity, args)
		if not player or not cmd or not quantity or not args then
			return
		end
		
		local commandHandler = commandDispatch[cmd]
		if not commandHandler then
			return
		end
		
		commandHandler(player, cmd, quantity, args)
	end)
	
	onEvent("PlayerDataParsed", checkWeeklyWinners)
	onEvent("PlayerDataParsed", playerDataRequests)
	onEvent("OutPlayerDataParsed", playerDataRequests)
	
	onEvent("PlayerLeft", function(player)
		reported[player] = nil
	end)
	
	onEvent("Loop", function(elapsed)
		local now = os.time()
		
		local to_remove, count = {}, 0
		for player, data in next, pdataRequest do
			if now >= data[2] then
				count = count + 1
				to_remove[count] = player
			end
		end
		
		local name
		for idx = 1, count do
			name = to_remove[idx]
			if pdataRequest[name][4] then
				pdataRequest[name][4](name)
			end
			pdataRequest[name] = nil
		end
	end)
	
	onEvent("GameStart", function()
		system.disableChatCommandDisplay(nil)
	end)
	--[[ End of file modes/parkour/moderation.lua ]]--
	--[[ File modes/parkour/init.lua ]]--
	eventGameStart()
	--[[ End of file modes/parkour/init.lua ]]--
	--[[ End of package modes/parkour ]]--
end

if is_tribe then
	initialize_parkour()
else
	local pos
	if starting == "*#" then
		module_name = string.match(room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(room.name, "^[a-z][a-z]%-#([a-z]+)")
		pos = #module_name + 5
	end

	submode = string.match(room.name, "^[^a-zA-Z]-([a-z_]+)", pos)
	if submode then
		flags = string.sub(room.name, pos + #submode + 2)
	end

	local nameLength = string.len(room.name)
	if nameLength > 45 then 
		local password = generateRandomString(10)
		tfm.exec.setRoomPassword(password)
		tfm.exec.chatMessage("<ROSE><b>[WARNING]</b> The room name exceeds the allowed length of <b>45</b> characters. Please choose a shorter name.", nil)
		return 
	end

	if room.name == "*#parkour4bots" then
		--[[ Package modes/bots ]]--
		--[[ File modes/parkour/filemanagers.lua ]]--
		local filemanagers = {
			["20"] = FileManager.new({
				type = "dictionary",
				map = {
					{
						name = "maps",
						type = "array",
						objects = {
							type = "number"
						}
					},
					{
						name = "ranks",
						type = "dictionary",
						objects = {
							type = "number"
						}
					},
					-- commented because the file is missing migration
					-- {
					-- 	name = "map_polls",
					-- 	type = "array",
					-- 	objects = {
					-- 		type = "number"
					-- 	}
					-- },
					{
						name = "chats",
						type = "dictionary",
						map = {
							{
								name = "mod",
								type = "string",
								length = 10
							},
							{
								name = "mapper",
								type = "string",
								length = 10
							}
						}
					}
				}
			}):disableValidityChecks():prepare(),
		
			["21"] = FileManager.new({
				type = "dictionary",
				map = {
					{
						name = "ranking",
						type = "array",
						objects = {
							type = "array",
							map = {
								{
									type = "number"
								},
								{
									type = "string",
								},
								{
									type = "number"
								},
								{
									type = "string",
									length = 2
								}
							}
						}
					},
					{
						name = "weekly",
						type = "dictionary",
						map = {
							{
								name = "ranks",
								type = "array",
								objects = {
									type = "array",
									map = {
										{
											type = "number"
										},
										{
											type = "string",
										},
										{
											type = "number"
										},
										{
											type = "string",
											length = 2
										}
									}
								}
							},
							{
								name = "ts",
								type = "string"
							},
							{
								name = "wl",
								type = "dictionary",
								objects = {
									type= "number"
								}
							}
						}
					}
				}
			}):disableValidityChecks():prepare(),
		
			["23"] = SanctionFileManager,
		}
		--[[ End of file modes/parkour/filemanagers.lua ]]--
		--[[ File modes/parkour/ranks.lua ]]--
		local band = (bit or bit32).band
		local bxor = (bit or bit32).bxor
		
		ranks = {
			admin = {_count = 0},
			bot = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0},
			trainee = {_count = 0},
			translator = {_count = 0},
			hidden = {_count = 0}
		}
		local ranks_id = {
			admin = 2 ^ 0,
			manager = 2 ^ 1,
			mod = 2 ^ 2,
			mapper = 2 ^ 3,
			trainee = 2 ^ 4,
			translator = 2 ^ 5,
			bot = 2 ^ 6,
			hidden = 2 ^ 7
		}
		local ranks_permissions = {
			admin = {
				set_checkpoint_version = true,
				set_name_color = true,
				give_command = true,
				view_creators = true,
			}, -- will get every permission
			bot = {
				set_checkpoint_version = true
			}, -- will get every permission
			manager = {
				force_stats = true,
				set_room_limit = true,
				set_map_time = true,
				hide = true,
				handle_map_polls = true,
				see_map_polls = true,
				change_roommod = true,
				see_hidden_staff = true,
			},
			mod = {
				ban = true,
				unban = true,
				spectate = true,
				get_player_room = true,
				change_map = true,
				load_custom_map = true,
				kill = true,
				see_private_maps = true,
				use_tracker = true,
				hide = true,
				change_roommod = true,
				see_hidden_staff = true,
				view_sanctions = true,
			},
			mapper = {
				change_map = true,
				load_custom_map = true,
				enable_review = true,
				hide = true,
				spectate = true,
				start_round_poll = true,
				see_map_polls = true,
				set_map_time_review = true,
				change_roommod = true,
				see_hidden_staff = true,
			},
			trainee = {
				ban = true,
				kill = true,
				spectate = true,
				change_map = true,
				get_player_room = true,
				see_private_maps = true,
				use_tracker = true,
				see_hidden_staff = true,
				view_sanctions = true,
			},
			translator = {
				hide = true
			},
			hidden = {}
		}
		player_ranks = {}
		perms = {}
		
		for rank, perms in next, ranks_permissions do
			if rank ~= "admin" and rank ~= "bot" then
				for perm_name, allowed in next, perms do
					ranks_permissions.admin[perm_name] = allowed
					ranks_permissions.bot[perm_name] = allowed
				end
			end
		end
		
		onEvent("GameDataLoaded", function(data)
			if data.ranks then
				ranks, perms, player_ranks = {
					admin = {_count = 0},
					bot = {_count = 0},
					manager = {_count = 0},
					mod = {_count = 0},
					mapper = {_count = 0},
					trainee = {_count = 0},
					translator = {_count = 0},
					hidden = {_count = 0}
				}, {}, {}
				local player_perms, _player_ranks
				for player, rank in next, data.ranks do
					player_perms, _player_ranks = {}, {}
					for name, id in next, ranks_id do
						if band(rank, id) > 0 then
							_player_ranks[name] = true
							ranks[name][player] = true
							ranks[name]._count = ranks[name]._count + 1
							ranks[name][ ranks[name]._count ] = player
							for perm, enabled in next, ranks_permissions[name] do
								player_perms[perm] = enabled
							end
						end
					end
					player_ranks[player] = _player_ranks
					perms[player] = player_perms
				end
			end
		end)
		--[[ End of file modes/parkour/ranks.lua ]]--
		--[[ File modes/bots/init.lua ]]--
		local addTextArea
		do
			local add = ui.addTextArea
			local gsub = string.gsub
			function addTextArea(id, data, target)
				return add(id, gsub(data, "([Hh][Tt])([Tt][Pp])", "%1<%2"), target)
			end
		end
		
		local loading_file_time = os.time() + 11000
		local loading_file_id
		local pdata_requested = {}
		
		local bit = bit or bit32
		local callbacks = {
			send_room = bit.lshift(2, 8) + 255,
			load_map = bit.lshift(11, 8) + 255,
			load_file = bit.lshift(40, 8) + 255,
			load_pdata = bit.lshift(41, 8) + 255,
			send_update = bit.lshift(42, 8) + 255,
		}
		local textareas = {
			heartbeat = 1 + 255,
			action_error = 2 + 255,
		}
		
		local parkour_bot = "Parkour#0568"
		
		onEvent("TextAreaCallback", function(id, player, data)
			if player ~= parkour_bot then return end
		
			if id == callbacks.send_room then
				local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
				packet_id = tonumber(packet_id)
				if not packet_id then return end
		
				eventSendingPacket(packet_id, packet)
		
			elseif id == callbacks.send_update then
				local seconds = tonumber(data)
				if not seconds then return end
		
				eventSendingPacket(packets.bots.game_update, tostring(os.time() + seconds * 1000))
		
			elseif id == callbacks.load_map then
				tfm.exec.newGame(data)
		
			elseif id == callbacks.load_file then
				local file_id = tonumber(data)
		
				if not file_id or file_id < 0 or file_id > 100 then
					addTextArea(textareas.action_error, "invalid file id", parkour_bot)
					return
				end
		
				if loading_file_id then
					addTextArea(textareas.action_error, "already loading a file", parkour_bot)
					return
				end
		
				loading_file_id = file_id
		
			elseif id == callbacks.load_pdata then
				pdata_requested[data] = os.time() + 2000
				system.loadPlayerData(data)
			end
		end)
		
		onEvent("SendingPacket", function(id, packet)
			if id == packets.bots.announce then -- !announcement
				tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
			end
		
			sendPacket("bots", id, packet)
		end)
		
		onEvent("PacketReceived", function(channel, id, packet, map, time)
			if channel ~= "common" then return end
		
			if id <= 255 then -- see textareas
				addTextArea(id, packet, parkour_bot)
			end
		end)
		
		onEvent("Loop", function()
			addTextArea(textareas.heartbeat, "", parkour_bot)
		
			if loading_file_id and os.time() > loading_file_time then
				system.loadFile(loading_file_id)
		
				loading_file_time = os.time() + 11000
				loading_file_id = nil
			end
		
			local clear = {}
			local now = os.time()
			for name, ts in next, pdata_requested do
				if now > ts then
					clear[1+#clear] = name
				end
			end
			for i=1, #clear do
				pdata_requested[clear[i]] = nil
			end
		end)
		
		onEvent("FileLoaded", function(file, data)
			tfm.exec.playMusic(tostring(data), 'file:' .. tostring(file), 0, false, false, parkour_bot)
		end)
		
		onEvent("PlayerDataLoaded", function(player, file)
			if not pdata_requested[player] then return end
			pdata_requested[player] = nil
			tfm.exec.playMusic(tostring(file), 'pdata:' .. tostring(player), 0, false, false, parkour_bot)
		end)
		
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAutoTimeLeft(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.disableMortCommand(true)
		tfm.exec.newGame(0)
		tfm.exec.setRoomMaxPlayers(50)
		--[[ End of file modes/bots/init.lua ]]--
		--[[ End of package modes/bots ]]--
	elseif submode == "freezertag" then
		--[[ Package modes/freezertag ]]--
		--[[ File modes/freezertag/init.lua ]]--
		function eventNewPlayer()
			tfm.exec.chatMessage("<rose>/room #freezertag", player)
		end
		--[[ End of file modes/freezertag/init.lua ]]--
		--[[ End of package modes/freezertag ]]--
	elseif submode == "rocketlaunch" then
		--[[ Package modes/rocketlaunch ]]--
		--[[ File modes/rocketlaunch/init.lua ]]--
		function eventNewPlayer()
			tfm.exec.chatMessage("<rose>/room #freezertag0rocketlaunch", player)
		end
		--[[ End of file modes/rocketlaunch/init.lua ]]--
		--[[ End of package modes/rocketlaunch ]]--
	elseif submode == "smol" then
		initialize_parkour()
		--[[ Package modes/smol ]]--
		--[[ File modes/smol/tinyfier.lua ]]--
		local is_smol = true
		local in_room = {}
		local next_xml
		local next_load
		local map_code, map_author
		local chair_x, chair_y
		local chair_prop = {
			type = 14,
			width = 32,
			height = 11,
			friction = 0.3,
			restitution = 0.2
		}
		
		local function tinyfy(prop, val)
			return prop .. '="' .. (tonumber(val) / 2) .. '"'
		end
		
		local function tinyfyPoints(prop, x, y)
			return " " .. prop .. '="' .. (tonumber(x) / 2) .. "," .. (tonumber(y) / 2) .. '"'
		end
		
		local newGame = tfm.exec.newGame
		function tfm.exec.newGame(arg)
			is_smol = false
			return newGame(arg)
		end
		
		onEvent("NewPlayer", function(player)
			if chair_x and chair_y then
				tfm.exec.addImage(
					"176c51d7288.png", "_51",
					chair_x - 18, chair_y - 31,
					player
				)
				tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
			end
			if not string.find(room.name, "test", 1, true) then
				-- has to be disabled, because size is already handled by normal parkour
				tfm.exec.changePlayerSize(player, 0.5)
			end
			in_room[player] = true
		end)
		
		onEvent("PlayerLeft", function(player)
			in_room[player] = nil
		end)
		
		onEvent("NewGame", function()
			if not is_smol then
				map_author = room.xmlMapInfo.author
				map_core = room.currentMap
				next_load = os.time() + 3000
		
				next_xml = string.gsub(
					room.xmlMapInfo.xml, '([XYLH])%s*=%s*"([^"]+)"', tinyfy
				)
				next_xml = next_xml:gsub(' (P%d)%s*=%s*"(.-),(.-)"', tinyfyPoints) -- joints
		
				local chair = string.match(
					next_xml,
					'<P[^>]+T="19"[^>]+C="329cd2"[^>]+/>'
				)
				if not chair then
					chair = string.match(
						next_xml,
						'<P[^>]+C%s*=%s*"329cd2"[^>]+T%s*=%s*"19"[^>]+/>'
					)
				end
		
				chair_x, chair_y = nil, nil
				if not chair then return end
		
				for prop, val in string.gmatch(chair, '([XY])%s*=%s*"([^"]+)"') do
					if prop == "X" then
						chair_x = tonumber(val)
					else
						chair_y = tonumber(val)
					end
				end
		
				-- remove chair
				next_xml = string.gsub(next_xml, chair, "")
				-- replace with nail
				next_xml = string.gsub(
					next_xml,
					"</O>",
					'<O C="22" X="' .. chair_x .. '" P="0" Y="' .. (chair_y - 20) .. '" /></O>'
				)
		
			elseif chair_x and chair_y then
				tfm.exec.addImage(
					"176c51d7288.png", "_51",
					chair_x - 18, chair_y - 31
				)
				tfm.exec.addPhysicObject(0, chair_x, chair_y - 7, chair_prop)
			end
		end)
		
		onEvent("Loop", function()
			if next_load and os.time() >= next_load then
				next_load = nil
				is_smol = true
				newGame(next_xml, room.mirroredMap)
			end
		end)
		--[[ End of file modes/smol/tinyfier.lua ]]--
		--[[ End of package modes/smol ]]--
	else
		initialize_parkour()
	end
end

for player in next, room.playerList do
	eventNewPlayer(player)
end

initializingModule = false