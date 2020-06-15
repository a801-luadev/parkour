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


local room = tfm.get.room
local links = {
	donation = "https://a801-luadev.github.io/?redirect=parkour",
	github = "https://bit.ly/tfm-parkour",
	discord = "https://bit.ly/parkour-discord",
	maps = "https://bit.ly/submit-parkour-maps",
	modapps = "https://bit.ly/parkourmod"
}

local starting = string.sub(room.name, 1, 2)

local tribe, module_name, submode
local flags = ""

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
    for i = 1, #val do
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
--[[ File global/event-handler.lua ]]--
local translatedChatMessage
local packet_handler
local recv_channel, send_channel
local sendPacket
local add_packet_data, buffer

local webhooks = {_count = 0}
local runtime = 0
local onEvent
do
	local os_time = os.time
	local math_floor = math.floor
	local runtime_check = 0
	local events = {}
	local scheduled = {_count = 0, _pointer = 1}
	local paused = false
	local runtime_threshold = 30
	local _paused = false

	local function runScheduledEvents()
		local count, pointer = scheduled._count, scheduled._pointer

		local data
		while pointer <= count do
			data = scheduled[pointer]
			-- An event can have up to 5 arguments. In this case, this is faster than table.unpack.
			data[1](data[2], data[3], data[4], data[5], data[6])
			pointer = pointer + 1

			if runtime >= runtime_threshold then
				scheduled._count = count
				scheduled._pointer = pointer
				return false
			end
		end
		scheduled._pointer = pointer
		return true
	end

	local function emergencyShutdown(limit_players, keep_webhooks)
		if limit_players then
			translatedChatMessage("emergency_mode")
			tfm.exec.setRoomMaxPlayers(1)
		end
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.disableMortCommand(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.newGame(7685178)
		tfm.exec.setGameTime(99999)

		for _, event in next, events do
			event._count = 0
		end

		if keep_webhooks then
			if not is_tribe then
				system.loadPlayerData(send_channel)
				buffer = add_packet_data

				events.PlayerDataLoaded._count = 2
				events.PlayerDataLoaded[1] = packet_handler
				events.PlayerDataLoaded[2] = function(player)
					if player == send_channel then
						events.PlayerDataLoaded._count = 0
					end
				end
			end
		end
	end

	function onEvent(name, callback)
		local evt
		if events[name] then
			evt = events[name]
		else
			evt = {_count = 0}
			events[name] = evt

			-- An event can have up to 5 arguments. In this case, this is faster than `...`
			local function caller(when, a, b, c, d, e)
				for index = 1, evt._count do
					evt[index](a, b, c, d, e)

					if os_time() >= when then
						break
					end
				end
			end

			local schedule = name ~= "Loop" and name ~= "Keyboard" -- schedule everything but eventLoop and eventKeyboard
			local done, result
			local event_fnc
			event_fnc = function(a, b, c, d, e)
				local start = os_time()
				local this_check = math_floor(start / 4000)
				if runtime_check < this_check then
					runtime_check = this_check
					runtime = 0
					paused = false

					if not runScheduledEvents() then
						runtime_check = this_check + 1
						paused = true
						return
					end

					if _paused then
						translatedChatMessage("resumed_events")
						_paused = false
					end
				elseif paused then
					if schedule then
						scheduled._count = scheduled._count + 1
						scheduled[scheduled._count] = {event_fnc, a, b, c, d, e}
					end
					return
				end

				done, result = pcall(caller, start + runtime_threshold - runtime, a, b, c, d, e)
				if not done then
					if room.name == "*#parkour4bots" then
						ui.addTextArea(bit32.lshift(255, 8) + 255, name .. "\000" .. result) -- sent to everyone in the room
						return emergencyShutdown(false, false)
					else
						local args = json.encode({a, b, c, d, e})
						translatedChatMessage("code_error", nil, name, "", args, result)
						tfm.exec.chatMessage(result)

						sendPacket(0, room.name .. "\000" .. name .. "\000" .. result)

						return emergencyShutdown(true, true)
					end
				end

				runtime = runtime + (os_time() - start)

				if runtime >= runtime_threshold then
					if not _paused then
						translatedChatMessage("paused_events")
					end

					runtime_check = this_check + 1
					paused = true
					_paused = true
					scheduled._count = 0
					scheduled._pointer = 1
				end
			end

			_G["event" .. name] = event_fnc
		end

		evt._count = evt._count + 1
		evt[evt._count] = callback
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
		local text = lang and lang[what] or nil
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
--[[ End of file global/translation-handler.lua ]]--
--[[ End of package global ]]--

local function initialide_parkour() -- so it uses less space after building
	--[[ Package modes/parkour ]]--
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
					name = "weekranking",
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
				}
			}
		}):disableValidityChecks():prepare(),

		["22"] = FileManager.new({
			type = "dictionary",
			map = {
				{
					name = "lowmaps",
					type = "array",
					objects = {
						type = "number"
					}
				},
				{
					name = "banned",
					type = "dictionary",
					objects = {
						type = "number"
					}
				}
			}
		}):disableValidityChecks():prepare()
	}
	--[[ End of file modes/parkour/filemanagers.lua ]]--
	--[[ Directory translations/parkour ]]--
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
		user_not_in_room = "<r>Jucătorul <n2>%s</n2> nu este în sală.",
		arg_must_be_id = "<r>Argumentul trebuie să fie un id valid.",
		cant_update = "<r>Nu pot fi actualizate rangurile jucătorilor. Încearcă din nou mai târziu.",
		cant_edit = "<r>Nu poți edita rangurile lui <n2>%s</n2>.",
		invalid_rank = "<r>Rang invalid: <n2>%s",
		code_error = "<r>O eroare a apărut: <bl>%s-%s-%s %s",
		panic_mode = "<r>Modulul întră în modul de panică.",
		public_panic = "<r>Te rugăm să aștepți ca un bot să restarteze sala.",
		tribe_panic = "<r>Te rugăm să scrii <n2>/module parkour</n2> pentru a restarta modulul.",
		emergency_mode = "<r>Inițiând închidere de urgență, niciun jucător nou nu este permis. Te rugăm să te duci pe altă sală de #parkour.",
		bot_requested = "<r>Botul a fost chemat. Ar trebui să ajungă într-un moment.",
		stream_failure = "<r>Eșec canal de stream intern. Nu poate fi transmisă data.",
		maps_not_available = "<r>submodulul 'maps' pentru #parkour poate fi accesat pe <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Botul (<d>%s</d>) și versiunea lua (<d>%s</d>) nu se potrivesc. Sistemul nu poate fi pornit.",
		missing_bot = "<r>Botul lipește. Așteaptă până botul ajunge sau dă-i ping lui @Tocu#0018 pe discord: <d>%s</d>",
		invalid_length = "<r>Mesajul tău trebuia să fie între 10 și 100 caractere. Are <n2>%s</n2> caractere.",
		invalid_map = "<r>Hartă invalidă.",
		map_does_not_exist = "<r>Harta introdusă nu există sau nu poate fi încărcată. Încearcă din nou mai târziu.",
		invalid_map_perm = "<r>Harta introdusă nu este P22 sau P41.",
		invalid_map_perm_specific = "<r>Harta introdusă nu este în P%s.",
		cant_use_this_map = "<r>Harta introdusă are o eroare mică.",
		invalid_map_p41 = "<r>Harta introdusă este în P41, dar nu este în lista de hărți de modul.",
		invalid_map_p22 = "<r>Harta introdusă este în P22, dar este în lista de hărți de modul.",
		map_already_voting = "<r>Harta introdusă este deja în votare.",
		not_enough_permissions = "<r>Nu ai destule permisiuni să faci asta.",
		already_depermed = "<r>Harta introdusă este deja depermanentizată.",
		already_permed = "<r>Harta introdusă este deja permanentizată.",
		cant_perm_right_now = "<r>Nu pot schimba statusul de permanentizare a hărții acum. Încearcă din nou mai târziu.",
		already_killed = "<r>Jucătorul %s a fost deja omorât.",
		leaderboard_not_loaded = "<r>Clasamentul nu a fost încă încărcat. Așteaptă un minut.",

		-- Help window
		help = "Ajutor",
		staff = "Personal",
		rules = "Reguli",
		contribute = "Contribuie",
		changelog = "Noutăți",
		help_help = "<p align = 'center'><font size = '14'>Bine ai venit pe <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Scopul tău este să ajungi la toate checkpoint-urile până completezi harta.</J></p>\n\n<N>• Apasă <O>O</O>, scrie <O>!op</O> sau dă click pe <O>butonul de configurație</O> pentru a deschide <T>meniul de opțiuni</T>.\n• Apasă <O>P</O> sau dă click pe <O>iconița mână</O> din colțul din dreapta-sus pentru a deschide <T>meniul de puteri</T>.\n• Apasă <O>L</O> sau scrie <O>!lb</O> pentru a deschide <T>clasamentul</T>.\n• Apasă pe <O>M</O> sau <O>Delete</O> pentru a folosi <T>/mort</T>, poți schimba tastele în meniul de  <J>Opțiuni</J>.\n• Pentru a afla mai multe despre <O>personalul nostru</O> sau despre <O>regulile parkourului</O>, dă click pe tab-urile <T>Personal</T> și respectiv <T>Reguli</T>.\n• Dă click <a href='event:discord'><o>aici</o></a> pentru a primi link-ul de invitație pentru serverul de discord și <a href='event:map_submission'><o>aici</o></a> pentru a putea trimite propriile hărți.\n• Folosește săgețile <o>sus</o> și <o>jos</o> când vrei să navighezi.\n\n<p align = 'center'><font size = '13'><T>Contribuțiile sunt acum deschide! Pentru mai multe detalii, dă click pe tab-ul <O>Contribuie</O> tab!</T></font></p>",
	    help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Personalul parkour NU FAC PARTE din personalul Transformice și NU au nicio putere în joc ci doar în acest modul.</r>\nPersonalul parkour se asigură că modulul rulează bine cu probleme minime, și sunt mereu disponibili să ajute jucătorii când este nevoie.</font></p>\nPoți scrie <D>!staff</D> în chat pentru a vedea personalul.\n\n<font color = '#E7342A'>Administratorii:</font> Ei sunt responsabili cu întreținerea modulului, adăugând actualizări noi și rezolvând probleme.\n\n<font color = '#843DA4'>Managerii de echipă:</font> Ei au grijă ca Moderatorii și Mapperii își fac treaba cum trebuie.  Ei sunt de asemenea responsabili cu aducerea de personal nou în echipă.\n\n<font color = '#FFAAAA'>Moderatorii:</font> Ei sunt responsabili cu aplicarea regulilor modulului și pedepsirea celor care nu le respectă.\n\n<font color = '#25C059'>Mapperii:</font>Ei sunt responsabili cu verificarea, adăugarea, și eliminarea hărților din modul pentru a-ți asigura un experiență plăcută de joc.",
	    help_rules = "<font size = '13'><B><J>Toate regulile din Termenii și Condițiile Transformice se aplică și la #parkour</J></B></font>\n\nDacă observi vreun player care încalcă aceste reguli, dă-le șoaptă moderatorilor din joc. Dacă nu este niciun moderator online, e recomandat să-l raportezi în server-ul de Discord.\nCand raportezi, te rugăm să incluzi server-ul, numele camerei și numele jucătorului.\n• Ex: ro-#parkour10 Blank#3495 trollează\nEvidența precum capturile de ecran, videourile și gif-urile sunt folositoare și apreciate, dar nu sunt necesare.\n\n<font size = '11'>• Niciun <font color = '#ef1111'>hack, bug sau eroare</font> nu este acceptată în sălile #parkour\n• <font color = '#ef1111'>VPN farming</font> va fi considerat un<B>abuz</B> și nu este admis. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nOricine va fi prins că încalcă aceste reguli va fi banat imediat.</B></font></p>\n\n<font size = '12'>Transformice acceptă conceptul de trolling. Cu toate acestea, <font color='#cc2222'><B>noi nu vom accepta acest lucru în parkour</B></font></font>\n\n<p align = 'center'><J>Trolling se numește atunci când un jucător își folosește intenționat puterile pentru a-i încurca pe ceilalți jucători din a termina harta.</j></p>\n• Trolling-ul ca revanșă <B>nu este un motiv valid</B>de a trolla pe cineva și nu te scutește de pedeapsă.\n• Ajutatul cu forța al celorlalți jucători care vor să termine harta singuri, fără a te opri când ți se cere, este considerat trolling.\n• <J>Dacă un jucător nu vrea ajutor și preferă să facă harta de unul singur, te rugăm să încerci să ajuți alți jucători.</J>. Cu toate acestea, dacă un alt jucător are nevoie de ajutor la același checkpoint ca jucătorul care vrea să joace singur,  îi poți ajuta [pe amândoi].\n\nDacă un jucător este prins că trollează, va fi sancționat fie pentru un anumit timp, fie pentru o rundă.",
	    help_contribute = "<font size='14'>\n<p align='center'>Echipa parkour adoră codul open source deoarece <t>ajută comunitatea</t>. Poți <o>vedea</o> și <o>modifica</o> codul sursă pe <o><u><a href='event:github'>GitHub</a></u></o>.\n\nÎntreținerea modulului este <t>strict voluntară</t>, așa că orice ajutor în legătură cu <t>codul</t>, <t>probleme ale jocului</t>, <t>sugestii</t> și <t>crearea de hărți</t> este mereu <u>primită și apreciată</u>.\nPoți <vp>raporta probleme</vp> și <vp>da sugestii</vp> pe <o><u><a href='event:discord'>Discord</a></u></o> și/sau <o><u><a href='event:github'>GitHub</a></u></o>.\nPoți să <vp>trimiți hărțile</vp> în discuția <o><u><a href='event:map_submission'>de pe forum</a></u></o>.\n\nÎntreținerea parkourului nu este scumpă, dar nici gratis. Am aprecia dacă ne-ai ajuta <t>donând orice sumă</t> <o><u><a href='event:donate'>aici</a></u></o>.\n<u>Toate donațiile vor duce la îmbunătățirea modulului.</u></p>",
	    help_changelog = "<font size='13'><p align='center'><o>Versiunea 2.4.0 - 16/06/2020</o></p>\n\n• Sistem de stocare intern îmbunătățit. <vp>Așteaptă-te la mai puține crash-uri!</vp>\n• Un sistem vechi de comunicare cu boții a fost refăcut. <vp>E foarte rapid acum!</vp>\n• A fost adăugat un canal pentru <d>recordurile săptămânale</d> pe <a href='event:discord'><u>discord</u></a>. Primii 3 cei mai buni jucători vor apărea acolo!\n• Au fost reparate multe probleme interne.\n• Acum poate fi folosit modul de <vp>verificare</vp> în casa tribului. <b>!review</b> pentru a-l activa/dezactiva.\n• <vp>Poți să schimbi limba jocului acum!</vp> Folosește <b>!langue</b> pentru a afișa limbile posibile.",

		-- Congratulation messages
		reached_level = "<d>Felicitări! Ai atins nivelul <vp>%s</vp>.",
		finished = "<d><o>%s</o> a terminat parkour în <vp>%s</vp> secunde, <fc>felicitări!",
		unlocked_power = "<ce><d>%s</d> a deblocat puterea <vp>%s</vp>.",
		enjoy = "<d>Bucură-te de noile abilități!",

		-- Information messages
		paused_events = "<cep><b>[Atenție!]</b> <n>Modulul a atins limita critcă și este pauzat.",
		resumed_events = "<n2>Modulul a fost eliberat.",
		welcome = "<n>Bine ai venit pe <t>#parkour</t>!",
		mod_apps = "<j>Aplicațiile pentru moderator sunt deschide! Folosește acest link: <rose>%s",
		type_help = "<pt>Îți recomandăm să folosești <d>!help</d> pentru a vedea informații utile!",
		data_saved = "<vp>Progres salvat.",
		action_within_minute = "<vp>Această acțiune va fi aplicată într-un minut.",
		rank_save = "<n2>Scrie <d>!rank save</d> pentru a aplica schimbările.",
		module_update = "<r><b>[Atenție!]</b> <n>Modulul se va actualiza în <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>System de hărți <t>(v%s)</t> încărcat.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> s-a alăturat sălii.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a părăsit sala.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a încărcat o hartă.",
		starting_perm_change = "<j>[INFO] <n>Pornind schimbare de permanentizare...",
		got_map_info = "<j>[INFO] <n>Informațiile hărții au fost încărcate. Încercând să schimb statusul de permanentizare...",
		perm_changed = "<j>[INFO] <n>Statusul de permanentizare schimbat cu succes <ch>@%s</ch> de la <r>P%s</r> în <t>P%s</t>.",
		leaderboard_loaded = "<j>Clasamentul a fost încărcat. Apasă L pentru a-l deschide.",
		kill_minutes = "<R>Puterile tale au fost oprite pentru %s minute.",
		kill_map = "<R>Puterile tale au fost oprite până la următoarea hartă.",
		permbanned = "<r>Ai fost banat permanent de la #parkour.",
		tempbanned = "<r>Ai fost banat de la #parkour pentru %s minute.",
		staff_power = "<r>Personalul parkour <b>nu are</b> nicio putere în afara sălilor de #parkour.",
		no_help = "<r>Jucătorii cu o linie roșie deasupra numelui nu vor ajutor!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Opțiuni Parkour</font></p>\n\nFolosește particule pentru parkour\n\nFolosește <b>QWERTY</b> (oprește dacă <b>AZERTY</b>)\n\Folosește scurtătura <b>M</b> pentru <b>/mort</b> (oprește pentru <b>DEL</b>)\n\nArată-ți cooldown-urile pentru puteri\n\nArată butonul de puteri\n\nArată butonul de ajutor\n\nArată anunțurile de completare a hărților\n\nArată simbolul de „fără ajutor”",
	    unknown = "Necunoscut",
		powers = "Puteri",
		press = "<vp>Apasă %s",
		click = "<vp>Click stânga",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Hărți completate: %s</B></p></BV>",
		leaderboard = "Clasament",
		position = "Poziție",
		username = "Nume",
		community = "Comunitate",
		completed = "Hărți completate",
		not_permed = "nepermanentizat",
		permed = "permanentizat",
		points = "%d puncte",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Început de <d>%s</d>. Ultimul comentariu de <d>%s</d>. <d>%s</d> comentarii, <d>%s</d> necitite.",
		map_info = "<p align='center'>Codul mapei: <bl>@%s</bl> <g>|</g> Autorul mapei: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Puncte: <vp>%s</vp>",
		permed_maps = "Hărți permanentizate",
		ongoing_votations = "Votăre în curs",
		archived_votations = "Voturi arhivate",
		open = "Deschis",
		not_archived = "nearhivat",
		archived = "arhivat",
		delete = "<r><a href='event:%s'>[șterge]</a> ",
		see_restore = "<vp><a href='event:%s'>[vezi]</a> <a href='event:%s'>[recuperează]</a> ",
		no_comments = "Fără comentarii.",
		deleted_by = "<r>[Mesaj șters de %s]",
		dearchive = "dezarhviează", -- to dearchive
		archive = "arhivează", -- to archive
		deperm = "depermanentizează", -- to deperm
		perm = "permanentizează", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentariu</j></a> <g>|</g> Votul tău: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[încarcă]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentariu</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Încarcă hartă custom</a></p>",
		write_comment = "Scrie-ți comentariul aici",
		write_map = "Scrie-ți codul de hartă aici",
		overall_lb = "În general",
		weekly_lb = "Săptămânal",
		new_lang = "<v>[#] <d>Limbă a fost setată în Română",

		-- Power names
		balloon = "Balon",
		masterBalloon = "Balon Maestru",
		bubble = "Balonaș",
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
		toilet = "Toaletă"
	}
	--[[ End of file translations/parkour/ro.lua ]]--
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
		user_not_in_room = "<r>המשתמש <n2>%s</n2> לא נמצא בחדר.",
		arg_must_be_id = "<r>The argument must be a valid id.",
		cant_update = "<r>לא ניתן לעדכן דרגות שחקן כרגע. נסה שוב מאוחר יותר.",
		cant_edit = "<r>אתה לא יכול לערוך את דרגותיו של <n2>%s's</n2>.",
		invalid_rank = "<r>דרגה שגויה: <n2>%s",
		code_error = "<r>שגיאה התגלתה: <bl>%s-%s-%s %s",
		panic_mode = "<r>משחק זה נכנס למצב פאניקה.",
		public_panic = "<r>אנא המתן עד שבוט יגיע ויאתחל את המשחק.",
		tribe_panic = "<r>אנא כתוב <n2>/module parkour</n2> על מנת לאתחל את המשחק.",
		emergency_mode = "<r>מתחיל כיבוי חירום, אין כניסה לשחקנים חדשים. אנא לך לחדר #parkour אחר.",
		bot_requested = "<r>הבוט נתבקש להגיע. הוא צריך להגיע בעוד רגע.",
		stream_failure = "<r>שגיאה פנימית. לא ניתן לשדר נתונים.",
		maps_not_available = "<r>תת מצב 'מפות של #parkour' זמין רק ב <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>גרסאות הבוט (<d>%s</d>) וה-lua (<d>%s</d>) אינן תואמות. לא ניתן להתחיל את המערכת.",
		missing_bot = "<r>הבוט נעדר. המתן עד שהבוט יגיע או תייג @Tocu#0018 בדיסקורד: <d>%s</d>",
		invalid_length = "<r>הודעתך נדרשת להכיל בין 10 ל-100 אותיות. בהודעה זו יש <n2>%s</n2> אותיות.",
		invalid_map = "<r>מפה שגויה.",
		map_does_not_exist = "<r>המפה שניתנה אינה קיימת או לא ניתנת לטעינה. נסה מאוחר יותר.",
		invalid_map_perm = "<r>המפה שניתנה אינה P22 או P41.",
		invalid_map_perm_specific = "<r>המפה שניתנה אינה ב P%s.",
		cant_use_this_map = "<r>המפה שניתנה מכילה באג קטן ואינה יכולה להיות בשימוש.",
		invalid_map_p41 = "<r>המפה שניתנה נמצאת ב P41, אך לא נמצאת ברשימת המפות של המשחק.",
		invalid_map_p22 = "<r>המפה שניתנה נמצאת ב P22 ונמצאת ברשימת המפות של המשחק.",
		map_already_voting = "<r>המפה שניתנה כבר נתונה בהצבעה פתוחה.",
		not_enough_permissions = "<r>אין לך מספיק הרשאות בכדי לעשות זאת.",
		already_depermed = "<r>המפה שניתנה כבר הוסרה.",
		already_permed = "<r>המפה שניתנה כבר נוספה.",
		cant_perm_right_now = "<r>לא ניתן לשנות את מסלול מפה זו כרגע. נסה שוב מאוחר יותר.",
		already_killed = "<r>השחקן %s כבר נהרג.",
		leaderboard_not_loaded = "<r>הלוח תוצאות עדיין לא נטען, המתן דקה.",

		-- Help window
		help = "עזרה",
		staff = "צוות",
		rules = "חוקים",
		contribute = "תרומה",
		changelog = "חדש",
		help_help = "<p align = 'center'><font size = '14'>ברוך הבא ל-<T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>מטרתך להשיג את כל נקודות השמירה עד שאתה מסיים את המפה.</J></p>\n\n<N>• לחץ <O>ם</O>, כתוב <O>!op</O> או לחץ על <O>גלגל השיניים</O> בכדי לפתוח את <T>ההגדרות</T>.\n• לחץ <O>פ</O> או לחץ על <O>כפתור האגרוף</O> בצד ימין למעלה על מנת לפתוח את <T>תפריט הכוחות</T>.\n• לחץ <O>ך</O> או כתוב <O>!lb</O> בכדי לפתוח את <T>לוח התוצאות</T>.\n• לחץ על <O>צ</O> או כפתור ה-<O>Delete</O> כתחליף ל-<T>/mort</T>, אתה יכול להחליף בין המקשים <J>בהגדרות</J>.\n• על מנת לדעת עוד על <O>הצוות</O> שלנו ועל <O>החוקים של פארקור</O>, לחץ על הכרטיסיות <T>צוות</T> ו<T>חוקים</T> לפי הסדר.\n• לחץ <a href='event:discord'><o>כאן</o></a> בכדי לקבל הזמנה לשרת הדיסקורד ו<a href='event:map_submission'><o>כאן</o></a> בכדי לקבל קישור לנושא הגשת המפות.\n• לחץ על חיצי ה<o>למעלה</o> וה<o>למטה</o> כאשר אתה צריך לגלול.\n\n<p align = 'center'><font size = '13'><T>ניתן כעת לתרום! לפרטים נוספים לחצו על הכרטיסייה <O>תרומה</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>הערה: צוות הפארקור אינו צוות המשחק ואין לו שום כוח במשחק עצמו, אלא רק במודול</r>\nצוות הפארקור מוודא כי המודול רץ בצורה חלקה עם עניינים מינימליים והם תמיד זמינים לעזור לשחקנים מתי שצריך.</font></p>\nאתה יכול לכתוב <D>!staff</D> בצ'אט כדי לראות את רשימת הצוות.\n\n<font color = '#E7342A'>אדמינים:</font> הם אחראים לשמור על המודול עי הוספת עדכונים ותיקוני באגים.\n\n<font color = '#843DA4'>מנהלי צוות:</font> הם מפקחים על צוותי הניהול והמפות, מוודאים כי הם מבצעים את עבודתם כשורה. בנוסף, הם האחראים על גיוס חברים חדשים לצוות.\n\n<font color = '#FFAAAA'>מנהלים:</font> הם האחראים לאכוף את חוקי המודול והענשת משתמשים אשר לא שומרים עליהם.\n\n<font color = '#25C059'>צוות מפות:</font> הם האחראים על סקירה, הוספה והסרה של מפות במודול הפארקור בכדי להבטיח שיהיה לכם משחק מהנה.",
		help_rules = "<font size = '13'><B><J>כל החוקים, התנאים וההגבלות של הטראנספורמייס חלים גם על #parkour</J></B></font>\n\nאם אתם מוצאים שחקן אשר עובר על חוקים אלה, שלחו לחישה למנהלי פארקור במשחק. אם אין מנהלים מחוברים, מומלץ לדווח על כך בשרת הדיסקורד.\nכאשר מדווחים, בבקשה כללו את השרת, שם החדר, ושם המשתמש של השחקן.\n• דוגמא: en-#parkour10 Blank#3495 trolling\nהוכחות כגון צילומי מסך, וידאו או גיפס הם יעילים ומוערכים, אך לא חייב.\n\n<font size = '11'>• אין להשתמש ב<font color = '#ef1111'>האקים, גליצ'ים או באגים</font> בחדרי פארקור\n• <font color = '#ef1111'>פארם VPN </font> ייחשב כ<B>ניצול</B> והדבר אסור. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nכל אחד שיתפס עובר על חוקים אלה יורחק באופן מיידי.</B></font></p>\n\n<font size = '12'>טראנספורמייס מרשה לעשות טרולים. עם זאת, <font color='#cc2222'><B>אנו לא נאפשר זאת בפארקור.</B></font></font>\n\n<p align = 'center'><J>טרול זה כאשר שחקן משתמש בכוונה בכוחותיו כדי למנוע משחקנים אחרים לסיים את המפה</j></p>\n• טרול כנקמה הוא <B>אינו סיבה מוצדקת</B> להטריל מישהו ואתם עדיין תענשו.\n• כפיית עזרה על שחקנים שמנסים להשלים לבדם את המפה וסירוב להפסיק כאשר התבקשת לכך ייחשב כטרול.\n• <J>אם שחקן אינו מעוניין בעזרה או מעוניין להשלים לבדו את המפה, אנא נסו ככל יכולתכם לעזור לשחקנים אחרים</J>. עם זאת, אם שחקן אחר צריך עזרה באותה נקודה כמו השחקן השני שרוצה להשלים לבד, אתה יכול לעזור לשניהם.\n\nאם שחקן ייתפס עושה טרול, הוא יענש על בסיס הזמן או סבב הפארקור. חשוב לציין כי ביצוע טרול שוב ושוב יוביל לעונשים ארוכים יותר וחמורים יותר.",
		help_contribute = "<font size='14'>\n<p align='center'>צוות הניהול של פארקור אוהב לפתוח את קוד המקור מכיוון שזה <t>עוזר לקהילה</t>. אתה יכול <o>לראות</o> ו<o>לערוך</o> את קוד המקור ב-<o><u><a href='event:github'>GitHub</a></u></o>.\n\nשמירה על המודול היא <t>התנדבותית לחלוטין</t>. לכן, כל עזרה ב<t>קודים</t>, <t>דיווח על באגים</t>, <t>הצעות</t> ו<t>יצירת מפות</t> תמיד <u>מתקבלת בברכה ומוערכת</u>.\nאתה יכול <vp>לדווח אודות באגים</vp> ו<vp>להציע הצעות</vp> ב<o><u><a href='event:discord'>דיסקורד</a></u></o> ו/או ב-<o><u><a href='event:github'>GitHub</a></u></o>.\nאתה יכול <vp>להגיש את מפותיך</vp> ב<o><u><a href='event:map_submission'>נושא הפורום</a></u></o> שלנו.\n\nאחזקת פארקור איננה יקרה, אך גם איננה חינמית. אנו נשמח אם תוכלו לעזור לנו עי <t>תרומה בכל סכום</t> <o><u><a href='event:donate'>כאן</a></u></o>.\n<u>כל התרומות הולכות היישר לשיפור המודול.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>גרסא 2.4.0 - 16/06/2020</o></p>\n\n•מערכת איחסון הנתונים הפנימית שופרה. <vp>צפו לפחות קריסות!</vp>\n•חידשנו מערכת שנה שיועדה לתקשר עם הפארקור עם בוטים. <vp>זה מהיר ברמות עכשיו!</vp>\n•הוספנו ערוץ <d>שיאים שבועיים</d> ב<a href='event:discord'><u>דיסקורד</u></a>. שלושת המקומות הראשונים בכל שבוע יופיעו שם!\n•באגים פנימיים רבים תוקנו.\n•כעת בתי שבט יכולים להשתמש במצב <vp>סיקור</vp>. <b>!review</b> על מנת להפעיל/להשבית את זה.  \n•<vp>כעת ניתן לשנות את השפה!</vp> כתוב <b>!langue</b> בכדי לראות את כלל השפות הזמינות.",

		-- Congratulation messages
		reached_level = "<d>ברכות! עלית לרמה <vp>%s</vp>.",
		finished = "<d><o>%s</o> סיים את הפארקור תוך <vp>%s</vp> שניות, <fc>ברכות!",
		unlocked_power = "<ce><d>%s</d> השיג את הכח <vp>%s</vp>.",
		enjoy = "<d>תהנה מהמיומנות החדשה!",

		-- Information messages
		paused_events = "<cep><b>[אזהרה!]</b> <n>המשחק הגיע למגבלה קריטית ונעצר כעת.",
		resumed_events = "<n2>המשחק נמשך.",
		welcome = "<n>ברוכים הבאים ל<t>#parkour</t>!",
		mod_apps = "<j>הגשות מועמדות להיות מנהל/ת פארקור פתוחות כעת! השתמש בקישור זה: <rose>%s",
		type_help = "<pt>אנו ממליצים לך לכתוב <d>!help</d> בכדי לראות מידע שימושי!",
		data_saved = "<vp>הנתונים נשמרו.",
		action_within_minute = "<vp>הפעולה תייושם בתוך דקה.",
		rank_save = "<n2>כתוב <d>!rank save</d> בכדי לשמור את השינויים.",
		module_update = "<r><b>[אזהרה!]</b> <n>המשחק יעדוכן בעוד <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[מידע] <n>מערכת מיפוי <t>(v%s)</t> נטענה.",
		mapper_joined = "<j>[מידע] <n><ce>%s</ce> <n2>(%s)</n2> נכנס לחדר.",
		mapper_left = "<j>[מידע] <n><ce>%s</ce> <n2>(%s)</n2> עזב את החדר.",
		mapper_loaded = "<j>[מידע] <n><ce>%s</ce> טען מפה.",
		starting_perm_change = "<j>[מידע] <n>מתחיל שינוי מסלול...",
		got_map_info = "<j>[מידע] <n>שולף מידע על המפה. מנסה לשנות את המסלול...",
		perm_changed = "<j>[מידע] <n>שינוי מסלול המפה <ch>@%s</ch> מ-<r>P%s</r> ל-<t>P%s</t> בוצע בהצלחה.",
		leaderboard_loaded = "<j>לוח התוצאות נטען. לחץ L כדי לפתוח אותו.",
		kill_minutes = "<R>כוחותיך הושבתו ל-%s דקות.",
		kill_map = "<R>כוחותיך הושבתו עד המפה הבאה.",
		permbanned = "<r>הורחקת לצמיתות מ-#parkour.",
		tempbanned = "<r>הורחקת מ-#parkour למשך %s דקות.",
		staff_power = "<r>לצוות פארקור <b>אין</b> שום כוחות מחוץ לחדרי פארקור.",
		no_help = "<r>אנשים עם פס אדום מעל עכברם לא רוצים עזרה!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>אפשרויות פארקור</font></p>\n\nהשתמש בחלקים כנקודות שמירה\n\nהשתמש במקלדת <b>QWERTY</b> (כבה אם <b>AZERTY</b> בשימוש)\n\nהשתמש באות <b>צ</b> במקום <b>/mort</b> (משבית את <b>DEL</b>)\n\nהראה את זמן טעינת הכוחות\n\nהראה כפתור כוחות\n\nהראה כפתור עזרה\n\nהראה הכרזות השלמת מפות\n\nהצג סימן 'ללא עזרה'",
		unknown = "לא ידוע",
		powers = "כוחות",
		press = "<vp>לחץ %s",
		click = "<vp>לחיצה שמאלית",
		ranking_pos = "דרגה #%s",
		completed_maps = "<p align='center'><BV><B>מפות שהושלמו: %s</B></p></BV>",
		leaderboard = "לוח תוצאות",
		position = "דרגה",
		username = "שם משתמש",
		community = "קהילה",
		completed = "מפות שהושלמו",
		not_permed = "לא נוספו",
		permed = "נוספו",
		points = "%d נקודות",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. תגובה אחרונה על ידי <d>%s</d>. <d>%s</d> תגובות, <d>%s</d> לא נקראו.",
		map_info = "<p align='center'>קוד מפה: <bl>@%s</bl> <g>|</g> יוצר מפה: <j>%s</j> <g>|</g> סטטוס: <vp>%s, %s</vp> <g>|</g> נקודות: <vp>%s</vp>",
		permed_maps = "Permed maps",
		ongoing_votations = "Ongoing votes",
		archived_votations = "Archived votes",
		open = "Open",
		not_archived = "not archived",
		archived = "archived",
		delete = "<r><a href='event:%s'>[delete]</a> ",
		see_restore = "<vp><a href='event:%s'>[see]</a> <a href='event:%s'>[restore]</a> ",
		no_comments = "No comments.",
		deleted_by = "<r>[Message deleted by %s]",
		dearchive = "unarchive", -- to dearchive
		archive = "archive", -- to archive
		deperm = "deperm", -- to deperm
		perm = "perm", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a> <g>|</g> Your vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[load]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Load custom map</a></p>",
		write_comment = "Write your comment down here",
		write_map = "Write the mapcode down here",
		overall_lb = "כללי",
		weekly_lb = "שבועי",
		new_lang = "<v>[#] <d>השפה הוגדרה ל-עברית",

		-- Power names
		balloon = "בלון",
		masterBalloon = "מאסטר בלון",
		bubble = "בועה",
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
		toilet = "אסלה"
	}
	--[[ End of file translations/parkour/he.lua ]]--
	--[[ File translations/parkour/cn.lua ]]--
	translations.cn = {
		name = "cn",
		fullname = "English",

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
		user_not_in_room = "<r>玩家 <n2>%s</n2> 不在房間裡。",
		arg_must_be_id = "<r>參數需要是一個有效的 id。",
		cant_update = "<r>現在無法更新玩家階級。請稍後再嘗試。",
		cant_edit = "<r>你不能修改 <n2>%s</n2> 的階級",
		invalid_rank = "<r>無效的階級: <n2>%s",
		code_error = "<r>發生了錯誤: <bl>%s-%s-%s %s",
		panic_mode = "<r>小遊戲進入了混亂模式。",
		public_panic = "<r>請等待直到機械人來重啟小遊戲。",
		tribe_panic = "<r>請輸入 <n2>/module parkour</n2> 來重啟小遊戲。",
		emergency_mode = "<r>正在啟動緊急終止模式, 新玩家無法加入遊戲。請前往另一個　#parkour 房間。",
		bot_requested = "<r>已收到請求機械人。它將會馬上到達。",
		stream_failure = "<r>內部串流渠道錯誤。資料不能被傳送。",
		maps_not_available = "<r>#parkour 的 'maps' 附屬模式只在 <n2>*#parkour0maps</n2> 房間提供。",
		version_mismatch = "<r>機械人 (<d>%s</d>) 跟 lua (<d>%s</d>) 版本不相乎。不能啟動系統。",
		missing_bot = "<r>遺失機械人。請等待機械人到達或在 discord 上私聊 @Tocu#0018: <d>%s</d>",
		invalid_length = "<r>你的訊息長度需在 10 到 100 字元。 它現在有 <n2>%s</n2> 個字元。",
		invalid_map = "<r>無效的地圖。",
		map_does_not_exist = "<r>你提交的地圖不存在或是不能加載。請稍後再嘗試。",
		invalid_map_perm = "<r>你提交的地圖不是 P22 或 P41。",
		invalid_map_perm_specific = "<r>你提交的地圖不是在 P%s。",
		cant_use_this_map = "<r>你提交的地圖有漏洞而不能被使用。",
		invalid_map_p41 = "<r>你提交的地圖是 P41, 但不在小遊戲地圖列表裡。",
		invalid_map_p22 = "<r>你提交的地圖是 P22, 但不在小遊戲地圖列表裡。",
		map_already_voting = "<r>你提交的地圖已經在其他公開的循環裡了。",
		not_enough_permissions = "<r>你沒有足夠的權限來操作。",
		already_depermed = "<r>你提交的地圖已經從地圖庫中被除去。",
		already_permed = "<r>你提交的地圖已經是在循環裡。",
		cant_perm_right_now = "<r>現在不能改變這地圖的類別。請稍後再嘗試。",
		already_killed = "<r>玩家 %s 已經被殺。",
		leaderboard_not_loaded = "<r>排行榜沒被加載。請稍後片刻。",

		-- Help window
		help = "幫助",
		staff = "職員",
		rules = "規則",
		contribute = "貢獻",
		changelog = "新聞",
		help_help = "<p align = 'center'><font size = '14'>歡迎來到 <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>你的目標是到達所有重生點直到完成地圖。</J></p>\n\n<N>• 按 <O>O</O>鍵, 輸入 <O>!op</O> 或是點擊右上方的 <O>齒輪</O> 來開啟 <T>選項目錄</T>。\n• 按 <O>P</O> 鍵或是點擊右上方的 <O>拳頭標誌</O> 來開啟 <T>能力目錄</T>。\n• 按 <O>L</O> 鍵或是輸入 <O>!lb</O> 來開啟 <T>排行榜</T>。\n• 按 <O>M</O> 鍵或是 <O>刪除</O> 鍵來 <T>自殺</T>, 你可以在 <J>選項</J> 目錄中激活按鍵。\n• 要知道更多關於我們 <O>職員</O> 的資訊以及 <O>parkour 的規則</O>, 可點擊 <T>職員</T> 及 <T>規則</T> 的分頁查看。\n• 點擊 <a href='event:discord'><o>這裡</o></a> 來取得 discord 邀請連結及 <a href='event:map_submission'><o>這裡</o></a> 來得到提交地圖的論壇連結。\n• 當你想滾動頁面可使用 <o>上</o> 鍵及 <o>下</o> 鍵。\n\n<p align = 'center'><font size = '13'><T>貢獻現在是開放的! 點擊 <O>貢獻</O> 分頁來了解更多!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>免責聲明: Parkour 的職員並不是 Transformice 職員而且在遊戲裡沒有任何權力, 只負責這小遊戲的規管。</r>\nParkour 職員確保小遊戲減少錯誤而運作順暢, 而且可以在有需要時協助玩家。</font></p>\n你可以在聊天框輸入 <D>!staff</D> 來查看職員列表。\n\n<font color = '#E7342A'>管理員:</font> 他們負責透過更新及修復滴漏洞來維護小遊戲。\n\n<font color = '#843DA4'>小隊主管:</font> 他們會觀察管理團隊及地圖團隊, 確保他們在工作上的表現。他們也負責招募新成員加入職員團隊中。\n\n<font color = '#FFAAAA'>管理員:</font> 他們負責執行小遊戲裡的規則以及處分違反規則的玩家。\n\n<font color = '#25C059'>地圖管理員:</font> 他們負責審核, 新增, 以及移除小遊戲裡的地圖來確保你可以享受遊戲過程。",
		help_rules = "<font size = '13'><B><J>所有適用於 Transformice 的條款及細則也適用於 #parkour</J></B></font>\n\n如果你發現任何玩家違反這些規則, 可以在遊戲中私聊 parkour 的管理員。如果沒有管理員在線, 你可以在 discord 伺服器中舉報事件。\n當你舉報的時候, 請提供你所在的伺服器, 房間名稱, 以及玩家名稱。\n• 例如: en-#parkour10 Blank#3495 trolling\n證明, 例如是截圖, 錄象以及gif圖能有效協助舉報, 但不是一定需要的。\n\n<font size = '11'>• 任何 <font color = '#ef1111'>外掛, 瑕疵或漏洞</font> 是不能在 #parkour 房間中使用\n• <font color = '#ef1111'>VPN 刷數據</font> 會被當作 <B>利用漏洞</B> 而不被允許的。 <p align = 'center'><font color = '#cc2222' size = '12'><B>\n任何人被抓到違反規則會被即時封禁。</B></font></p>\n\n<font size = '12'>Transformice 允許搗蛋行為。但是, <font color='#cc2222'><B>我們不允許在 parkour 的搗蛋行為。</B></font></font>\n\n<p align = 'center'><J>搗蛋行為是指當一個玩家有意圖利用他的能力來阻止其他玩家完成地圖。</j></p>\n• 復仇性的搗蛋行為 <B>並不是一個合理解釋</B> 來搗亂別人而因此你也會被處分。\n• 強迫想自理的玩家接受協助而當他說不用之後仍舊沒有停止此行為也會被視作搗蛋。\n• <J>如果一個玩家不想被協助或是想自理通關, 請你盡力協助其他玩家。</J> 但是如果有另外的玩家需要協助而剛好跟自理玩家在同一個重生點, 你可以協助他們 [兩人]。\n\n如果玩家的搗蛋行為被抓到, 他們會被處分基於時間或是 parkour 回合數的遊玩限制。重覆的搗蛋行為會引至更長及更嚴重的處分。",
		help_contribute = "<font size='14'>\n<p align='center'>Parkour 管理團隊喜愛開放原始碼是因為它能夠<t>協助社群</t>。 你可以在 <o><u><a href='event:github'>GitHub</a></u></o> <o>查看</o> 以及 <o>修改</o> 原始碼。\n\n維護這個小遊戲是 <t>義務性質</t>, 所以任何在 <t>編程</t>, <t>漏洞回饋</t>, <t>建議</t> 及 <t>地圖創作</t> 上提供的幫助將會是十分 <u>歡迎而且非常感激</u>。\n你可以在 <o><u><a href='event:discord'>Discord</a></u></o> 及/或 <o><u><a href='event:github'>GitHub</a></u></o> <vp>匯報漏洞</vp> 和 <vp>提供意見</vp>。\n你可以在我們的 <o><u><a href='event:map_submission'>論壇帖子</a></u></o> 中 <vp>提交你的地圖</vp>。\n\n維護 Parkour 不是很花費, 但也不完全是免費。我們希望你能夠在 <o><u><a href='event:donate'>這裡</a></u></o> <t>捐贈任何金額</t> 來支持我們。\n<u>所有捐款會用來改善這個小遊戲。</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Improved internal data storage system. <vp>Expect less crashes!</vp>\n• Refactored an old system used to communicate parkour with bots. <vp>It is blazing fast now!</vp>\n• Added a <d>weekly records</d> channel on <a href='event:discord'><u>discord</u></a>. Top 3 players every week will appear there!\n• Fixed many internal bugs.\n• Tribe houses can use <vp>review</vp> mode now. <b>!review</b> to enable/disable it.\n• <vp>You can switch your language now!</vp> Use <b>!langue</b> to list all the available languages.",

		-- Congratulation messages
		reached_level = "<d>恭喜! 你到達了第 <vp>%s</vp> 個重生點。",
		finished = "<d><o>%s</o> 在 <vp>%s</vp> 秒內完成了地圖, <fc>恭喜!",
		unlocked_power = "<ce><d>%s</d> 解鎖了 <vp>%s</vp> 能力。",
		enjoy = "<d>享受你的新能力吧!",

		-- Information messages
		paused_events = "<cep><b>[警告!]</b> <n>小遊戲已達到最高流量限制而被暫停了。",
		resumed_events = "<n2>小遊戲已繼續啟用。",
		welcome = "<n>歡迎來到 <t>#parkour</t>!",
		mod_apps = "<j>Parkour 管理員申請現正開放! 請查看這連結: <rose>%s",
		type_help = "<pt>我們建議你輸入 <d>!help</d> 查看有用的資訊!",
		data_saved = "<vp>資料已儲存。",
		action_within_minute = "<vp>你的指示將會馬上執行。",
		rank_save = "<n2>輸入 <d>!rank save</d> 來確認改變。",
		module_update = "<r><b>[警告!]</b> <n>小遊戲將會在 <d>%02d:%02d</d> 後更新。",
		mapping_loaded = "<j>[資訊] <n>地圖系統 <t>(v%s)</t> 已加載。",
		mapper_joined = "<j>[資訊] <n><ce>%s</ce> <n2>(%s)</n2> 加入了房間。",
		mapper_left = "<j>[資訊] <n><ce>%s</ce> <n2>(%s)</n2> 離開了房間。",
		mapper_loaded = "<j>[資訊] <n><ce>%s</ce> 加載了地圖。",
		starting_perm_change = "<j>[資訊] <n>正在更改地圖類別...",
		got_map_info = "<j>[資訊] <n>已收集地圖資訊。正嘗試改變類別...",
		perm_changed = "<j>[資訊] <n>已成功更改地圖 <ch>@%s</ch> 的類別 <r>P%s</r> 到 <t>P%s</t>。",
		leaderboard_loaded = "<j>排行榜已載入。請按 L 鍵打開它。",
		kill_minutes = "<R>你的能力已經在 %s 分鐘內暫時取消了。",
		kill_map = "<R>你的能力已被取消直到下一回合。",
		permbanned = "<r>你已經在 #parkour 被永久封禁。",
		tempbanned = "<r>你已經在 #parkour 被封禁了 %s 分鐘。",
		staff_power = "<r>Parkour 職員 <b>不會</b> 擁有任何在 #parkour 房間以外的權力。",
		no_help = "<r>玩家名字上帶有紅線代表他們不想被協助!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkour 選項</font></p>\n\n在重生點使用粒子效果\n\n使用 <b>QWERTY</b> 鍵盤 (使用<b>AZERTY</b>請關閉此項)\n\n使用快捷鍵 <b>M</b> 來 <b>自殺</b> (使用<b>DEL</b>請關閉此項)\n\n顯示你的能力緩衝時間\n\n顯示能力選項按鈕\n\n顯示幫助按鈕\n\n顯示完成地圖的公告\n\n顯示不用被幫助的標示",
		unknown = "不明物",
		powers = "能力",
		press = "<vp>按 %s",
		click = "<vp>左鍵點擊",
		ranking_pos = "排名 #%s",
		completed_maps = "<p align='center'><BV><B>完成的地圖數: %s</B></p></BV>",
		leaderboard = "排行榜",
		position = "位置",
		username = "用戶名",
		community = "社區",
		completed = "完成地圖數",
		not_permed = "沒被分類",
		permed = "已分類",
		points = "%d 分數",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>發起人 <d>%s</d>。最後回覆者 <d>%s</d>。 <d>%s</d> 個回應, <d>%s</d> 個未讀。",
		map_info = "<p align='center'>地圖編號: <bl>@%s</bl> <g>|</g> 地圖作者: <j>%s</j> <g>|</g> 狀態: <vp>%s, %s</vp> <g>|</g> 分數: <vp>%s</vp>",
		permed_maps = "已分類地圖",
		ongoing_votations = "投票進行中",
		archived_votations = "投票已結束",
		open = "開",
		not_archived = "未完成",
		archived = "已完成",
		delete = "<r><a href='event:%s'>[刪除]</a> ",
		see_restore = "<vp><a href='event:%s'>[查看]</a> <a href='event:%s'>[回復]</a> ",
		no_comments = "沒有回應。",
		deleted_by = "<r>[訊息被 %s 刪除]",
		dearchive = "刪除", -- to dearchive
		archive = "達成", -- to archive
		deperm = "刪除分類", -- to deperm
		perm = "分類", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>評價</j></a> <g>|</g> 你的投票: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[加載]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>評價</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>加載玩家創作地圖</a></p>",
		write_comment = "在這裡寫下評價",
		write_map = "在這裡寫下地圖編號",
		overall_lb = "主要排名",
		weekly_lb = "每周排名",
		new_lang = "<v>[#] <d>Language set to English",

		-- Power names
		balloon = "氣球",
		masterBalloon = "進階氣球",
		bubble = "泡泡",
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
		toilet = "馬桶"
	}
	--[[ End of file translations/parkour/cn.lua ]]--
	--[[ File translations/parkour/br.lua ]]--
	translations.br = {
		name = "br",
		fullname = "English",

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
		user_not_in_room = "<r>O usuário <n2>%s</n2> não está na sala.",
		arg_must_be_id = "<r>O argumento deve ser um ID válido.",
		cant_update = "<r>Não foi possível atualizar o cargo do jogador. Tente novamente mais tarde.",
		cant_edit = "<r>Você não pode editar o cargo do jogador <n2>%s</n2>.",
		invalid_rank = "<r>Cargo inválido: <n2>%s",
		code_error = "<r>Um erro aconteceu: <bl>%s-%s-%s %s",
		panic_mode = "<r>Módulo entrando em Modo Pânico.",
		public_panic = "<r>Espere um momento enquanto um bot entra na sala e reinicia o módulo.",
		tribe_panic = "<r>Por favor, digite <n2>/module parkour</n2> para reiniciar o módulo.",
		emergency_mode = "<r>Começando desativação de emergência, novos jogadores não serão mais permitidos. Por favor, vá para outra sala #parkour.",
		bot_requested = "<r>O bot foi requisitado. Ele virá em poucos segundos.",
		stream_failure = "<r>Erro interno entre canais. Não foi possível transmitir dados.",
		maps_not_available = "<r>Submodo #parkour 'maps' só está disponível na sala <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Versões do Bot (<d>%s</d>) e lua (<d>%s</d>) não são equivalentes. Não foi possível iniciar o sistema.",
		missing_bot = "<r>O bot sumiu. Aguarde um minuto ou mencione @Tocu#0018 no discord: <d>%s</d>",
		invalid_length = "<r>Sua mensagem deve ter algo entre 10 e 100 caracteres. Agora tem <n2>%s</n2> caracteres.",
		invalid_map = "<r>Mapa inválido.",
		map_does_not_exist = "<r>O mapa não existe ou não pôde ser carregado. Tente novamente mais tarde.",
		invalid_map_perm = "<r>O mapa não é nem P22, nem P41.",
		invalid_map_perm_specific = "<r>O mapa não é P%s.",
		cant_use_this_map = "<r>O mapa tem um pequeno bug e não pode ser usado.",
		invalid_map_p41 = "<r>O mapa é P41, mas não está na lista de mapas do módulo.",
		invalid_map_p22 = "<r>O mapa é P22, mas está na lista de mapas do módulo.",
		map_already_voting = "<r>o mapa já tem uma votação em aberto.",
		not_enough_permissions = "<r>Você não tem permissões suficientes para fazer isso.",
		already_depermed = "<r>O mapa já foi <i>deperm</i>.",
		already_permed = "<r>O mapa já está <i>perm</i>.",
		cant_perm_right_now = "<r>Não foi possível alterar a categoria deste mapa no momento. Tente novamente mais tarde.",
		already_killed = "<r>O jogador %s já está morto.",
		leaderboard_not_loaded = "<r>O ranking ainda não foi carregado. Aguarde um minuto.",

		-- Help window
		help = "Ajuda",
		staff = "Staff",
		rules = "Regras",
		contribute = "Contribuir",
		changelog = "Novidades",
		help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></p>\n\n<N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.\n• Clique <a href='event:discord'><o>aqui</o></a> para obter um link de convide para o nosso servidor no Discord e <a href='event:map_submission'><o>aqui</o></a> para obter o link do tópico de avaliação de mapas.\n• Use as setas <o>para cima</o> ou <o>para baixo</o> quando você precisar rolar a página.\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#843DA4'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
		help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador usa seus poderes de forma intencional para fazer com que os outros jogadores não terminem o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador for pego trollando, serão punidos por um tempo determinado ou por algumas partidas. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
		help_contribute = "<font size='14'>\n<p align='center'>A equipe do parkour adora ter um código aberto, pois isso <t>ajuda a comunidade</t>. Você pode <o>ver</o> ou <o>contribuir</o> com o código no <o><u><a href='event:github'>GitHub</a></u></o>.\n\nManter o módulo é parte de um trabalho <t>voluntário</t>, então qualquer contribuição é <u>bem vinda</u>, seja com a <t>programação</t>, <t>reporte de erros</t>, <t>sugestões</t> e <t>criação de mapas</t>.\nVocê pode <vp>reportar erros</vp> ou <vp>dar sugestões</vp> no nosso <o><u><a href='event:discord'>Discord</a></u></o> e/ou no <o><u><a href='event:github'>GitHub</a></u></o>.\nVocê pode <vp>enviar seus mapas</vp> no nosso <o><u><a href='event:map_submission'>Tópico no Fórum</a></u></o>.\n\nManter o jogo não é caro, mas também não é grátis. Nós adoraríamos se você pudesse incentivar o desenvolvimento do jogo <t>doando qualquer valor</t> <o><u><a href='event:donate'>aqui</a></u></o>.\n<u>Todos os fundos arrecadados serão direcionados para o desenvolvimento do módulo.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Improved internal data storage system. <vp>Expect less crashes!</vp>\n• Refactored an old system used to communicate parkour with bots. <vp>It is blazing fast now!</vp>\n• Added a <d>weekly records</d> channel on <a href='event:discord'><u>discord</u></a>. Top 3 players every week will appear there!\n• Fixed many internal bugs.\n• Tribe houses can use <vp>review</vp> mode now. <b>!review</b> to enable/disable it.\n• <vp>You can switch your language now!</vp> Use <b>!langue</b> to list all the available languages.",

		-- Congratulation messages
		reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>.",
		finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
		unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
		enjoy = "<d>Aproveite suas novas habilidades!",

		-- Information messages
		paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
		resumed_events = "<n2>O módulo está se normalizando.",
		welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
		mod_apps = "<j>As inscrições para moderador do parkour estão abertas! Use esse link: <rose>%s",
		type_help = "<pt>Recomendamos que você digite <d>!help</d> para informações úteis!",
		data_saved = "<vp>Dados salvos.",
		action_within_minute = "<vp>A ação será aplicada dentre um minuto.",
		rank_save = "<n2>Digite <d>!rank save</d> para salvar as mudanças.",
		module_update = "<r><b>[Atenção!]</b> <n>O módulo irá atualizar em <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Sistema de mapas <t>(v%s)</t> carregado.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> entrou na sala.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> saiu da sala.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> carregou este mapa.",
		starting_perm_change = "<j>[INFO] <n>Iniciando mudança de categoria...",
		got_map_info = "<j>[INFO] <n>Todas as informações do mapa foram coletadas. Tentando alterar categoria...",
		perm_changed = "<j>[INFO] <n>Categoria do mapa <ch>@%s</ch> alterada com sucesso, de <r>P%s</r> para <t>P%s</t>.",
		leaderboard_loaded = "<j>O ranking foi carregado. Aperte L para abri-lo.",
		kill_minutes = "<R>Seus poderes foram desativados por %s minutos.",
		kill_map = "<R>Seus poderes foram desativados até o próximo mapa.",
		permbanned = "<r>Você foi banido permanentemente do #parkour.",
		tempbanned = "<r>Você foi banido do #parkour por %s minutos.",
		staff_power = "<r>A Staff do Parkour <b>não</b> tem nenhum poder fora das salas #parkour.",
		no_help = "<r>Pessoas com uma linha acima de seus ratos não querem ajuda!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar partículas para os checkpoints\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <b>M</b> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado\n\nNão mostrar símbolo de ajuda",
		unknown = "Desconhecido",
		powers = "Poderes",
		press = "<vp>Aperte %s",
		click = "<vp>Use click",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Mapas completados: %s</B></p></BV>",
		leaderboard = "Ranking",
		position = "Posição",
		username = "Nome",
		community = "Comunidade",
		completed = "Mapas completados",
		not_permed = "não tem categoria",
		permed = "permed",
		points = "%d pontos",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Iniciado por <d>%s</d>. Último comentário por <d>%s</d>. <d>%s</d> comentários, <d>%s</d> não lidos.",
		map_info = "<p align='center'>Código do mapa: <bl>@%s</bl> <g>|</g> Autor do mapa: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Pontos: <vp>%s</vp>",
		permed_maps = "Mapas <i>permed</i>",
		ongoing_votations = "Votações em andamento",
		archived_votations = "Votações arquivadas",
		open = "Abrir",
		not_archived = "não arquivado",
		archived = "arquivado",
		delete = "<r><a href='event:%s'>[deletar]</a> ",
		see_restore = "<vp><a href='event:%s'>[ver]</a> <a href='event:%s'>[restaurar]</a> ",
		no_comments = "Sem comentários.",
		deleted_by = "<r>[Mensagem deletada por %s]",
		dearchive = "desarquivar", -- to dearchive
		archive = "arquivar", -- to archive
		deperm = "deperm", -- to deperm
		perm = "perm", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a> <g>|</g> Seu voto: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[carregar]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Carregar mapa</a></p>",
		write_comment = "Escreva seu comentário abaixo",
		write_map = "Escreva o código do mapa abaixo",
		overall_lb = "Geral",
		weekly_lb = "Semanal",
		new_lang = "<v>[#] <d>Language set to English",

		-- Power names
		balloon = "Balão",
		masterBalloon = "Balão Mestre",
		bubble = "Bolha",
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
		toilet = "Vaso Sanitário"
	}
	translations.pt = translations.br
	--[[ End of file translations/parkour/br.lua ]]--
	--[[ File translations/parkour/tr.lua ]]--
	translations.tr = {
		name = "tr",
		fullname = "English",

		-- Error messages
		corrupt_map= "<r>Harita bozulmuş.Başka bir tane yükleniyor.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Bu harita hakkında bilgi alınamıyor.",
		corrupt_map_mouse_start= "<r>[ERROR] <n>Bu haritanın bir başlangıç noktası olması gerekiyor (fare başlangıç noktası).",
		corrupt_map_needing_chair= "<r>[ERROR] <n>Haritanın bitiş koltuğu olması gerekiyor.",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>Haritada en az bir kontrol noktası olması gerekiyor(sarı çivi).",
		corrupt_data = "<r>Malesef, sizin verileriniz kayboldu ve sıfırlandı.",
		min_players = "<r>Verinizin kaydedilebilmesi için odada en az 4 farklı oyuncunun bulunması gerekmektedir. <bl>[%s/%s]",
		tribe_house = "<r>Veri kabile evlerinde işlenmeyecektir..",
		invalid_syntax = "<r>geçersiz söz dizimi.",
		user_not_in_room = "<r>Kullanıcı <n2>%s</n2> odada değil.",
		arg_must_be_id = "<r>The argument must be a valid id.",
		cant_update = "<r>Oyuncu sıralamaları şuan yüklenemiyor. Daha sonra tekrar deneyiniz.",
		cant_edit = "<r>You can't edit <n2>%s's</n2> ranks.",
		invalid_rank = "<r>Geçersiz sıralama: <n2>%s",
		code_error = "<r>Bir sorun oluştu: <bl>%s-%s-%s %s",
		panic_mode = "<r>Modul şuanda panik moduna geçiyor.",
		public_panic = "<r>Lütfen modülün tekrar başlatılmasını bekleyin.",
		tribe_panic = "<r>Modülü tekrar başlatmak için <n2>/module parkour</n2> yazın lütfen.",
		emergency_mode = "<r>Acildurum modu başlatılıyor, yeni oyunculara izin verilmemektedir. Lütfen başka bir #parkour odasına geçin.",
		bot_requested= "<r>Bir bot talep edildi. Birazdan burada olacaktır.",
		stream_failure = "<r>Dahili akış kanalı arızası. Veri iletilemedi.",
		maps_not_available = "<r>#parkour haritaları altmodu sadece <n2>*#parkour0maps</n2> haritalarında geçerlidir.",
		version_mismatch = "<r>Bot (<d>%s</d>) ve lua (<d>%s</d>) sürümleri uyuşmuyor. Sistem başlatılamıyor.",
		missing_bot = "<r>Bot kayıp. Lütfen botun gelmesini bekleyin yada discordtan @Tocu#0018 'yu pingleyin : <d>%s</d>",
		invalid_length = "<r>Mesajınız 10 ve 100 karakter sayısı arasında olmalıdır. Mesajınız <n2>%s</n2> karakterdir.",
		invalid_map = "<r>geçersiz harita.",
		map_does_not_exist = "<r>İstenilen harita yok veya yüklenemiyor. Daha sonra tekrar deneyiniz.",
		invalid_map_perm = "<r>Verilen harita P22 yada P41 değil.",
		invalid_map_perm_specific = "<r>Verilen harita P%s değil.",
		cant_use_this_map = "<r>Seçilen haritada bir hata var ve kullanılamıyor.",
		invalid_map_p41 = "<r>Seçilen harita P41'in içinde, fakat modül haritaları listesinde değil.",
		invalid_map_p22 = "<r>Seçilen harita P22'in içinde, ama modül haritaları listesinde.",
		map_already_voting = "<r>Seçilen harita zaten açık bir oylamada.",
		not_enough_permissions = "<r>Bunu yapmaya yeterli yetkiniz yok.",
		already_depermed = "<r>Seçilen.",
		already_permed = "<r>Seçilen harita.",
		cant_perm_right_now = "<r>Şu anda bu haritanın izni değiştirilemiyor. Daha sonra tekrar deneyiniz.",
		already_killed = "<r>Oyuncu %s zaten öldürüldü.",
		leaderboard_not_loaded = "<r>Lider tablosu heünz yüklenemedi. Lütfen bekleyin.",

		-- Help window
		help = "Yardım",
		staff = "Ekip",
		rules = "Kurallar",
		contribute = "Bağış",
		changelog = "Yenilikler",
		help_help = "<p align = 'center'><font size = '14'>Hoş geldiniz <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Amacınız haritayı tamamlayana kadar bütün kontrol noktalarına ulaşmak.</J></p>\n\n<font size='11'><N>•  Ayarlar menüsü açmak için klavyeden <O>O</O> tuşuna basabilir, <O>!op</O> yazabilir veya <O>çark</O> simgesine tıklayabilirsiniz.\n• Beceri menüsüne ulaşmak için klavyeden <O>P</O> tuşuna basabilir veya sağ üst köşedeki <O>El</O> simgesine tıklayabilirsiniz.\n• Lider tablosuna ulaşmak için <O>L</O> tuşuna basabilir veya <O>!lb</O> yazabilirsiniz.\n• Ölmek için <O>M</O> veya <O>Delete</O> tuşuna basabilirsiniz. <O>Delete</O> tuşunu kullanabilmek için <J>Ayarlar</J>ksımından <O>M</O> tuşu ile ölmeyi kapatmanız gerekmektedir.\n•  Ekip ve parkur kuralları hakkında daha fazla bilgi bilgi almak için, <O>Ekip</O> ve <O>Kurallar</O> sekmesine tıklayın.\n• <a href='event:discord'><o>Buraya Tıklayarak</o></a> discord davet linkimize ulaşabilir ve <a href='event:map_submission'><o>Buraya Tıklayarak</o></a> da harita göndermek için konu bağlantısını alabilirsiniz.\n• Kaydırma yapmanız gerektiğinde <o>yukarı</o> ve <o>aşağı</o> ok tuşlarını kullanın.\n\n<p align = 'center'><font size = '13'><T>Artık bize bağışta bulunabilirsiniz! Daha fazla bilgi için, <O>Bağış</O> sekmesine tıklayın!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>Bildiri: Parkour ekibi Transformice'ın ekibi DEĞİLDİR, sadece parkour modülünde yetkililerdir.</r>\nParkur ekibi modülün akıcı bir şekilde kalmasını sağlar ve her zaman oyunculara yardımcı olurlar.</font></p>\nEkip listesini görebilmek için <D>!staff</D> yazabilirsiniz.\n\n<font color = '#E7342A'>Administrators:</font> Modülü yönetmek, yeni güncellemeler getirmek ve hataları/bugları düzeltirler.\n\n<font color = '#843DA4'>Team Managers:</font> Modları ve Mapperları kontrol eder ve işlerini iyi yaptıklarından emin olurlar. Ayrıca ekibe yeni modlar almaktan da onlar sorumludur.\n\n<font color = '#FFAAAA'>Moderators:</font> Kuralları uygulamak ve uygulamayan oyuncuları cezalandırmaktan sorumludurlar.\n\n<font color = '#25C059'>Mappers:</font> Yeni yapılan haritaları inceler, harita listesine ekler ve siz oyuncularımızın eğlenceli bir oyun deneyimi geçirmenizi sağlarlar.",
		help_rules = "<font size = '13'><B><J>Transformice bütün kural ve koşulları #parkour içinde geçerlidir</J></B></font>\n\nEğer kurallara uymayan bir oyuncu görürseniz,oyun içinde parkour ekibindeki modlardan birine mesaj atabilirsiniz. Eğer hiçbir mod çevrim içi değilse discord serverimizde rapor edebilirsiniz.\nRapor ederken lütfen serveri, oda ismini ve oyuncu ismini belirtiniz.\n• Örnek: tr-#parkour10 Sperjump#6504 trolling\nEkran görüntüsü,video ve gifler işe yarayacaktır fakat gerekli değildir..\n\n<font size = '11'>•#parkour odalarında <font color = '#ef1111'>hack ve bug</font>kullanmak YASAKTIR!\n• <font color = '#ef1111'>VPN farming</font> yasaktır, <B>Haksız kazanç elde etmeyin</B> .. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKuralları çiğneyen herkes banlanacaktır.</B></font></p>\n\n<font size = '12'>Transformice trolleme konseptine izin verir. Fakat, <font color='#cc2222'><B>biz buna parkur modülünde izin vermeyeceğiz.</B></font></font>\n\n<p align = 'center'><J>Trollemek becerilerini diğer oyuncuların haritayı bitirmesini engellemek için kullanmak demektir..</j></p>\n• İntikam almak için trollemek <B>geçerli bir sebep değildir</B> ve cezalandırılacaktır.\n• Haritayı tek başına bitirmek isteyen bir oyuncuya zorla yardım etmeye çalışmak trollemek olarak kabul edilecek ve cezalandırılacaktır.\n• <J>Eğer bir oyuncu yardım istemiyorsa ve haritayı tek başına bitirmek istiyorsa, lütfen diğer oyunculara yardım etmeyi deneyin.</J>. Ancak yardım isteyen diğer oyuncu haritayı tek başına yapmak isteyen bir oyuncunun yanındaysa ona yardım edebilirsiniz.\n\nEğer bir oyuncu trollerken yakalanırsa, zaman ve ya parkur roundları bazında cezalandırılacaktır.. Sürekli bir şekilde trollemekten dolayı ceza alan bir oyuncu eğer hala trollemeye devam ederse cezaları daha ağır olacaktır..",
		help_contribute = "<font size='14'>\n<p align='center'>Parkour yönetim ekibi açık kaynak kodunu seviyor çünkü <t>bu topluluğa yardım ediyor</t>. Kaynak kodunu <o>görüntüleyebilir</o> ve <o>değiştirebilirsiniz</o> <o><u><a href='event:github'>GitHub'a Git</a></u></o>.\n\nModülün bakımı <t>isteklere göredir</t>, bu yüzden yardımda bulunmak için <t>kodlara</t> göz atmanız, <t>hataları bildirmeniz</t>, <t>öneride bulunmanız</t> ve <t>harita oluşturmanız</t> her zaman <u>hoş karşılanır ve takdir edilir</u>.\n<o><u><a href='event:discord'>Discord</a></u></o> veya <o><u><a href='event:github'>GitHub</a></u></o> hakkında <vp>hataları bildirmeniz</vp> ve <vp>öneride bulunmanız</vp> çok işimize yarıyacaktır.\n<o><u><a href='event:map_submission'>Forumdaki Konumuza</a></u></o> <vp>Haritalarınızı</vp> gönderebilirsiniz.\n\nParkour bakımı pahalı değil, ama ücretsiz de değil. Herhangi bir miktar bağışlayarak bize yardımcı olabilirseniz seviniriz.</t><o><u><a href='event:donate'>Bağış Yapmak İçin Tıkla</a></u></o>.\n<u>Tüm bağışlar modülün geliştirilmesine yönelik olacaktır.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Improved internal data storage system. <vp>Expect less crashes!</vp>\n• Refactored an old system used to communicate parkour with bots. <vp>It is blazing fast now!</vp>\n• Added a <d>weekly records</d> channel on <a href='event:discord'><u>discord</u></a>. Top 3 players every week will appear there!\n• Fixed many internal bugs.\n• Tribe houses can use <vp>review</vp> mode now. <b>!review</b> to enable/disable it.\n• <vp>You can switch your language now!</vp> Use <b>!langue</b> to list all the available languages.",

		-- Congratulation messages
		reached_level = "<d>Tebrikler! <vp>%s</vp>. Seviyeye ulaştınız.",
		finished = "<d><o>%s</o> parkuru <vp>%s</vp> saniyede bitirdi, <fc>Tebrikler!",
		unlocked_power = "<ce><d>%s</d>, <vp>%s</vp> becerisini açtı.",
		enjoy = "<d>Yeni becerilerinin keyfini çıkar!",

		-- Information messages
		paused_events = "<cep><b>[Dikkat!]</b> <n>Modül kritik seviyeye ulaştı ve durduruluyor.",
		resumed_events = "<n2>Modül devam ettirildi.",
		welcome = "<n><t>#parkour</t>! Odasına hoş geldiniz.",
		mod_apps = "<j>Parkour moderatör alımları şimdi açık! Bu bağlantıyı kullanın: <rose>%s",
		type_help = "<pt>İşinize yarayacak bilgileri bulmak için <d>!help</d> yazabilirsiniz!",
		data_saved = "<vp>Veri kaydedildi.",
		action_within_minute = "<vp>Eylem bir dakika içinde uygulanacak.",
		rank_save = "<n2>Değişiklikleri kaydetmek için <d>!rank save</d> yazın.",
		module_update = "<r><b>[Dikkat!]</b> <n> Modül <d>%02d:%02d</d> içinde güncellenecektir.",
		mapping_loaded = "<j>[BİLGİ] <n>Harita sistemi <t>(v%s)</t> yüklendi.",
		mapper_joined = "<j>[BİLGİ] <n><ce>%s</ce> <n2>(%s)</n2> Odaya katıldı.",
		mapper_left = "<j>[BİLGİ] <n><ce>%s</ce> <n2>(%s)</n2> Odadan ayrıldı.",
		mapper_loaded = "<j>[BİLGİ] <n><ce>%s</ce> Bir harita yükledi.",
		starting_perm_change = "<j>[BİLGİ] <n>Starting perm change...",
		got_map_info = "<j>[BİLGİ] <n>Harita bilgisi alındı. Trying to change the perm...",
		perm_changed = "<j>[BİLGİ] <n>Successfully changed the perm of map <ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
		leaderboard_loaded = "<j>Lider tablosu güncellendi. Görüntülemek için klavyeden L tuşuna basın.",
		kill_minutes = "<R>Becerilerin %s dakika boyunca devre dışı bırakılmıştır.",
		kill_map = "<R>Yeni haritaya geçene kadar becerileriniz devre dışı bırakdı.",
		permbanned = "<r>#Parkour'dan kalıcı olarak yasaklandınız.",
		tempbanned = "<r>#Parkour'dan %s dakika boyunca yasaklandınız.",
		staff_power = "<r>Parkour personelinin #parkour odalarının dışında hiçbir gücü <b>yoktur</b>.",
		no_help = "<r>Farelerinin üzerinde kırmızı çizgi olan insanlar yardım istemez!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkur ayarları</font></p>\n\nKontrol noktaları için parçacıkları kullan\n\n<b>QWERTY</b> klavye kullan (Kapatıldığnda <b>AZERTY</b> klavye kullanılır)\n\nÖlmek için klavyeden <b>M</b> tuşuna bas veya <b>/mort</b> komutunu kullan. (Kapattığında <b>DELETE</b> tuşuna basarak ölebilirsin.)\n\nBeceri bekleme sürelerini göster\n\nBeceriler simgesini göster\n\nYardım butonunu göster\n\nHarita bitirme duyurularını göster\n\nYardım istemiyorum simgesini göster",
		unknown = "Bilinmiyor",
		powers = "Beceriler",
		press = "<vp>%s Tuşuna Bas",
		click = "<vp>Sol tık",
		ranking_pos = "Sıralama #%s",
		completed_maps = "<p align='center'><BV><B>Tamamlanan haritalar: %s</B></p></BV>",
		leaderboard = "Lider sıralaması",
		position = "Sıralama",
		username = "Kullanıcı adı",
		community = "Topluluk",
		completed = "Tamamlanan haritalar",
		not_permed = "not permed",
		permed = "permed",
		points = "%d Puanlar",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'> <d>%s</d>Tarafından başlatıldı. Son yorumlar<d>%s</d>. <d>%s</d> yorumlar, <d>%s</d> okunmamış.",
		map_info = "<p align='center'>Map code: <bl>@%s</bl> <g>|</g> Map author: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
		permed_maps = "Permed maps",
		ongoing_votations = "Devam eden oylamalar",
		archived_votations = "Arşivlenmiş oylamalar",
		open = "Açık",
		not_archived = "Arşivlenmemiş",
		archived = "Arşivlenmiş",
		delete = "<r><a href='event:%s'>[delete]</a> ",
		see_restore = "<vp><a href='event:%s'>[see]</a> <a href='event:%s'>[restore]</a> ",
		no_comments = "Yorum yok.",
		deleted_by = "<r>[Mesaj  %s tarafından silindi]",
		dearchive = "unarchive", -- to dearchive
		archive = "arşiv", -- to archive
		deperm = "deperm", -- to deperm
		perm = "perm", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a> <g>|</g> Your vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[load]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Rastgele map yükleniyor</a></p>",
		write_comment = "Yorumunuzu buraya yazın",
		write_map = "Harita kodunu buraya yazın",
		overall_lb = "Genel",
		weekly_lb = "Haftalık",
		new_lang = "<v>[#] <d>Language set to English",

		-- Power names
		balloon = "Balon",
		masterBalloon = "Usta İşi Balon",
		bubble = "Baloncuk",
		fly = "Uçma",
		snowball = "Kar topu",
		speed = "Hız",
		teleport = "Işınlanma",
		smallbox = "Küçük kutu",
		cloud = "Bulut",
		rip = "Mezar taşı",
		choco = "Çukulata Tahta",
		bigBox = "Büyük Kutu",
		trampoline = "Trambolin",
		toilet = "Tuvalet"
	}
	--[[ End of file translations/parkour/tr.lua ]]--
	--[[ File translations/parkour/pl.lua ]]--
	translations.pl = {
		name = "pl",
		fullname = "Polski",

		-- Error messages
		corrupt_map = "<r>Zepsuta mapa. Ładowanie inną.",
		corrupt_map_vanilla = "<r>[BŁĄD] <n>Nie można uzyskać informacji o tej mapie.",
		corrupt_map_mouse_start = "<r>[BŁĄD] <n>Ta mapa musi mieć pozycję początkową (punkt odradzania myszy).",
		corrupt_map_needing_chair = "<r>[BŁĄD] <n>Mapa musi mieć końcowy fotel.",
		corrupt_map_missing_checkpoints = "<r>[BŁĄD] <n>Mapa musi mieć co najmniej jeden punkt kontrolny (żółty gwóźdź).",
		corrupt_data = "<r>Niestety Twoje dane zostały uszkodzone i zostały zresetowane.",
		min_players = "<r>Aby zapisać dane, w pokoju musi być co najmniej 4 graczy. <bl>[%s/%s]",
		tribe_house = "<r>Dane nie będą zapisywane w plemionach.",
		invalid_syntax = "<r>Niepoprawna składnia.",
		user_not_in_room = "<r>Gracz <n2>%s</n2> nie jest w pokoju.",
		arg_must_be_id = "<r>Argument musi być prawidłowym identyfikatorem.",
		cant_update = "<r>Nie można teraz zaktualizować rang graczy. Spróbuj ponownie później.",
		cant_edit = "<r>Nie możesz edytować <n2>%s's</n2> rang.",
		invalid_rank = "<r>Nieprawidłowa ranga: <n2>%s",
		code_error = "<r>Wystąpił błąd: <bl>%s-%s-%s %s",
		panic_mode = "<r>Moduł wchodzi teraz w Tryb paniki.",
		public_panic = "<r>Poczekaj, aż pojawi się bot i ponownie uruchomi moduł.",
		tribe_panic = "<r>Proszę wpisać <n2>/module parkour</n2> aby zrestartować moduł.",
		emergency_mode = "<r>Inicjowanie wyłączenia awaryjnego, nowi gracze nie są dozwoleni. Przejdź do innego pokoju #parkour.",
		bot_requested = "<r>Bot został poproszony. Powinien przybyć za chwilę.",
		stream_failure = "<r>Błąd wewnętrznego kanału strumienia. Nie można przesyłać danych.",
		maps_not_available = "<r>#parkour Podtryb map jest dostępny tylko w <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Bot (<d>%s</d>) i kod lua (<d>%s</d>) wersje nie pasują. Nie można uruchomić systemu.",
		missing_bot = "<r>Brakuje bota. Poczekaj na pojawienie się bota lub zapinguj @Tocu#0018 na discordzie: <d>%s</d>",
		invalid_length = "<r>Twoja wiadomość musi mieć od 10 do 100 znaków. Ma <n2>%s</n2> postacie.",
		invalid_map = "<r>Niepoprawna mapa.",
		map_does_not_exist = "<r>Podana mapa nie istnieje lub nie można jej załadować. Spróbuj ponownie później.",
		invalid_map_perm = "<r>Podana mapa nie jest P22 ani P41.",
		invalid_map_perm_specific = "<r>Podanej mapy nie ma w P%s.",
		cant_use_this_map = "<r>Podana mapa ma mały błąd i nie można jej użyć.",
		invalid_map_p41 = "<r>Podana mapa znajduje się w P41, ale nie ma jej na liście map modułów.",
		invalid_map_p22 = "<r>Podana mapa znajduje się w P22, ale znajduje się na liście map modułów.",
		map_already_voting = "<r>Podana mapa ma już otwarte głosowanie.",
		not_enough_permissions = "<r>Nie masz wystarczających uprawnień, aby to zrobić.",
		already_depermed = "<r>Podana mapa jest już zdeprawowany.",
		already_permed = "<r>Podana mapa jest już trwała.",
		cant_perm_right_now = "<r>Nie można teraz zmienić trwałość tej mapy. Spróbuj ponownie później.",
		already_killed = "<r>Gracz %s został już zabity.",
		leaderboard_not_loaded = "<r>Tabela liderów nie została jeszcze załadowana. Poczekaj minutę.",

		-- Help window
		help = "Pomoc",
		staff = "Obsługa",
		rules = "Zasady",
		contribute = "Udział",
		changelog = "Aktualności",
		help_help = "<p align = 'center'><font size = '14'>Witamy w <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Twoim celem jest dotarcie do wszystkich punktów kontrolnych, dopóki nie ukończysz mapy.</J></p>\n\n<N>• Naciśnij <O>O</O>, napisz <O>!op</O> Lub kliknij <O>przycisk konfiguracji</O> aby otworzyć <T>menu opcji</T>.\n• Naciśnij <O>P</O> lub kliknij <O>ikonę dłoni</O> w prawym górnym rogu, aby otworzyć <T>menu mocy</T>.\n• Naciśnij <O>L</O> lub napisz <O>!lb</O> aby otworzyć <T>tabelę wyników</T>.\n• Naciśnij <O>M</O> lub <O>Delete</O> klawisz do <T>/mort</T>, możesz przełączać klawisze w <J>Options</J> menu.\n• Aby dowiedzieć się więcej o naszym <O>personelu</O> oraz <O>zasadach na parkourze</O>, kliknij na <T>obsługę</T> i <T>zasady</T> .\n• Kliknij <a href='event:discord'><o>tutaj</o></a> aby uzyskać link zapraszający zgodny i <a href='event:map_submission'><o>tutaj</o></a> aby uzyskać link do tematu przesyłania mapy.\n• Użyj strzałki w <o>góre</o> i w <o>dół</o>, kiedy musisz przewijać.\n\n<p align = 'center'><font size = '13'><T>Udziały są teraz otwarte! Aby uzyskać więcej informacji, kliknij <O>Udział</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>WYJAŚNIAMY: Personel Parkour NIE JEST personelem Transformice i NIE MA żadnej mocy w samej grze, tylko w module.</r>\nPersonel w Parkour zapewnnia, że moduł działa płynnie przy minimalnych problemach i są zawsze dostępni, aby pomóc graczom w razie potrzeby.</font></p>\nAby zobaczyć listę aktywnych osób z personelu napisz <D>!staff</D> na czacie.\n\n<font color = '#E7342A'>Administratorzy:</font> Są odpowiedzialni za utrzymanie samego modułu poprzez dodawanie nowych aktualizacji i naprawianie błędów.\n\n<font color = '#843DA4'>Kierownicy zespołów:</font> Nadzorują zespoły moderatorów i twórców map, upewniając się, że dobrze wykonują swoje zadania. Odpowiadają również za rekrutację nowych członków do zespołu pracowników.\n\n<font color = '#FFAAAA'>Moderatoratorzy:</font> Są odpowiedzialni za egzekwowanie zasad modułu i karanie osób, które ich nie przestrzegają.\n\n<font color = '#25C059'>Mapperzy:</font> Są odpowiedzialni za przeglądanie, dodawanie i usuwanie map w modułach, aby zapewnić przyjemną rozgrywkę.",
		help_rules = "<font size = '13'><B><J>Wszystkie zasady zawarte w Regulaminie Transformice dotyczą również #parkour</J></B></font>\n\nJeśli zauważysz, że jakiś gracz łamie te zasady, napisz do moderatorów parkour w grze. Jeżeli nie ma moderatorów w grze to zaleca się zgłosić na serwerze w discordzie.\nPodczas zgłaszania prosimy o podanie serwera, nazwy pokoju i nazwy gracza.\n• Na przykład: en-#parkour10 Blank#3495 trolling\nDowody, takie jak zrzuty ekranu, filmy i gify, są pomocne i doceniane, ale nie są konieczne.\n\n<font size = '11'>• Zakazane jest używanie: <font color = '#ef1111'>hack, usterek oraz błędów.</font>\n• <font color = '#ef1111'>VPN farmowanie</font> będzie uważany za <B>wykorzystywanie</B> i nie jest dozwolone. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKażdy przyłapany na łamaniu tych zasad zostanie natychmiast zbanowany.</B></font></p>\n\n<font size = '12'>Transformice zezwala na trollowanie. Jednak, <font color='#cc2222'><B> zabronione jest to na  w parkourze.</B></font></font>\n\n<p align = 'center'><J>Trollowanie ma miejsce, gdy gracz celowo wykorzystuje swoje moce, aby uniemożliwić innym graczom ukończenie mapy.</j></p>\n•Trolling w każdej formie jest zabroniony nie ważne czy w formie <B>zemsty czy zabawy</B>.\n• Za trollowanie uważa się również wymuszanie pomocy gdy gracz sam próbuje przejść mapę i prosi abyś przestał mu pomagać a ty odmawiasz.\n• <J>Jeśli gracz nie chce pomocy lub woli ukończyć sam mape, postaraj się pomóc innym graczom</J>. Jeśli jednak inny gracz potrzebuje pomocy w tym samym punkcie kontrolnym, co gracz solo, możesz im pomóc [obu].\n\nJeśli gracz zostanie przyłapany na trollowaniu, zostanie ukarany odebraniem mocy na dany okres czasu. Pamiętaj, że wielokrotne trollowanie doprowadzi do dłuższych i surowszych kar.",
		help_contribute = "<font size='14'>\n<p align='center'>Zespół zarządzający w parkour uwielbia otwarte kody, ponieważ <t>pomagają społeczności</t>. Możesz <o>zobaczyć</o> i <o>modyfikować</o> kod źródłowy na <o><u><a href='event:github'>GitHub</a></u></o>.\n\nUtrzymanie modułu jest <t>dobrowolne</t>, więc wszelka pomoc dotycząca <t>kodów</t>, <t>zgłaszania błędów</t>, <t>propozycje</t> oraz <t>tworzenie map</t> jest zawsze <u>mile widziane i doceniane</u>.\nMożesz <vp>zgłaszać błędy</vp> oraz <vp>dać propozycje</vp> na <o><u><a href='event:discord'>Discord</a></u></o> lub <o><u><a href='event:github'>GitHub</a></u></o>.\n<vp>Swoje mapy możesz przesyłać</vp> w naszym <o><u><a href='event:map_submission'>wątku na forum</a></u></o>.\n\nUtrzymanie parkour nie jest drogie, ale też nie darmowe. Możesz nam pomóc <t>przekazując dowolną kwotę</t> <o><u><a href='event:donate'>tutaj</a></u></o>.\n<u>Wszystkie darowizny zostaną przeznaczone na ulepszenie modułu.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Wersja 2.4.0 - 16/06/2020</o></p>\n\n• Ulepszony wewnętrzny system przechowywania danych. <vp>Expect less crashes!</vp>\n• Przebudowano stary system komunikacji parkour z botami. <vp>Teraz płonie szybko!</vp>\n• Dodany <d>cotygodniowy rekord</d> w kanae na<a href='event:discord'><u>discord</u></a>. Pojawią się tam 3 najlepszych graczy każdego tygodnia!\n• Naprawiono wiele wewnętrznych błędów.\n• Plemienia mogą korzystać <vp>review</vp> modułu teraz <b>!review</b> aby włączyć / wyłączyć go\n• <vp>Możesz zmienić język teraz!</vp> Użyj <b>!langue</b> aby wyświetlić listę wszystkich dostępnych innych języków",

		-- Congratulation messages
		reached_level = "<d>Gratulacje! Osiągnąłeś poziom <vp>%s</vp>.",
		finished = "<d><o>%s</o> skończyłeś parkour w <vp>%s</vp> sekundach, <fc>Gratulacje!",
		unlocked_power = "<ce><d>%s</d> odblokował <vp>%s</vp> moc.",
		enjoy = "<d>Ciesz się nowymi umiejętnościami!",

		-- Information messages
		paused_events = "<cep><b>[Uwaga!]</b> <n>Moduł osiągnął limit krytyczny i jest wstrzymywany.",
		resumed_events = "<n2>Moduł został wznowiony.",
		welcome = "<n>Witamy w <t>#parkour</t>!",
		mod_apps = "<j>Aplikacje moderatora Parkour są już otwarte! Użyj tego linku: <rose>%s",
		type_help = "<pt>Wpisz <d>!help</d> aby zobaczyć przydatne informacje!",
		data_saved = "<vp>Dane zapisane.",
		action_within_minute = "<vp>Akcja zostanie zastosowana za minutę.",
		rank_save = "<n2>Napisz <d>!rank save</d> aby zastosować zmiany.",
		module_update = "<r><b>[Uwaga!]</b> <n>Moduł zaktualizuje się za <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFORMACJA] <n>System mapowania <t>(v%s)</t> loaded.",
		mapper_joined = "<j>[INFORMACJA] <n><ce>%s</ce> <n2>(%s)</n2> dołączył do pokoju.",
		mapper_left = "<j>[INFORMACJA] <n><ce>%s</ce> <n2>(%s)</n2> opuścił pokój",
		mapper_loaded = "<j>[INFORMACJA] <n><ce>%s</ce> załadował mapę.",
		starting_perm_change = "<j>[INFORMACJA] <n>Rozpoczęcie zmiany trwałość...",
		got_map_info = "<j>[INFORMACJA] <n>Odzyskano informacje o mapie. Próbuję zmienić trwałość...",
		perm_changed = "<j>[INFORMACJA] <n>Pomyślnie zmieniono trwałość mapy <ch>@%s</ch> od <r>P%s</r> do <t>P%s</t>.",
		leaderboard_loaded = "<j>Tablica wyników została załadowana. Naciśnij L, aby go otworzyć.",
		kill_minutes = "<R>Twoje moce zostały wyłączone w %s minut.",
		kill_map = "<R>Twoje moce zostały wyłączone do następnej mapy.",
		permbanned = "<r>Zostałeś trwale zbanowany #parkour.",
		tempbanned = "<r>Zostałeś zbanowany z #parkour na %s minut.",
		staff_power = "<r>Parkour staff <b>nie</b> mają jakąkolwiek moc poza #parkour pokojów.",
		no_help = "<r>Ludzie z czerwoną linią nad myszą nie chcą pomocy!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkour Opcje</font></p>\n\nUżyj cząstek jako punktów kontrolnych\n\nUżyj <b>QWERTY</b> klawiatura (wyłącz jeśli <b>AZERTY</b>)\n\nUżyj klawisza<b>M</b> zamiast <b>/mort</b> (wyłącz <b>DEL</b>)\n\nPokaż swoje czasy odnowienia mocy\n\nPokaż przycisk mocy\n\nPokaż przycisk pomocy\n\nPokaż ogłoszenia o ukończeniu mapy\n\nPokaż symbol bez pomocy",
		unknown = "Nieznany",
		powers = "Moce",
		press = "<vp>Naciśnij %s",
		click = "<vp>Lewy przycisk",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Ukończone mapy: %s</B></p></BV>",
		leaderboard = "Tabela liderów",
		position = "Pozycja",
		username = "Nazwa",
		community = "Społeczność",
		completed = "Ukończone mapy",
		not_permed = "nie trwały",
		permed = "trwały",
		points = "%d punkty",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Rozpoczęty przez <d>%s</d>. Ostatni komentarz autorstwa <d>%s</d>. <d>%s</d> komentarze, <d>%s</d> nieprzeczytane.",
		map_info = "<p align='center'>Mapa kod: <bl>@%s</bl> <g>|</g> Mapa autora: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Punkty: <vp>%s</vp>",
		permed_maps = "Trwałe mapy",
		ongoing_votations = "Głosy w toku",
		archived_votations = "Zarchiwizowane głosy",
		open = "Otwarte",
		not_archived = "nie zarchiwizowane",
		archived = "zarchiwizowane",
		delete = "<r><a href='event:%s'>[delete]</a> ",
		see_restore = "<vp><a href='event:%s'>[see]</a> <a href='event:%s'>[restore]</a> ",
		no_comments = "Bez komentarza.",
		deleted_by = "<r>[Wiadomość usunięta przez %s]",
		dearchive = "brak archiwizacji", -- to dearchive
		archive = "archiwum", -- to archive
		deperm = "deperm", -- to deperm
		perm = "trwały", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a> <g>|</g> Your vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[load]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Load custom map</a></p>",
		write_comment = "Napisz swój komentarz tutaj",
		write_map = "Zapisz tutaj kod mapy",
		overall_lb = "Ogólnie",
		weekly_lb = "Co tydzień",
		new_lang = "<v>[#] <d>Zestaw językowy do Polski",

		-- Power names
		balloon = "Balon",
		masterBalloon = "Master Balon",
		bubble = "Bańka",
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
		toilet = "Toaleta"
	}
	--[[ End of file translations/parkour/pl.lua ]]--
	--[[ File translations/parkour/fr.lua ]]--
	translations.fr = {
		name = "fr",
		fullname = "Français",

		-- Error messages
		corrupt_map = "<r>Carte non opérationnelle. Chargement d'une autre.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les informations de cette carte.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise d'arrivée (point final).",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte à besoin d'au moins un point de sauvegarde (étoiles jaunes).",
		corrupt_data = "<r>Malheureusement, vos données ont été corrompues et ont été effacées.",
		min_players = "<r>Pour sauvegarder vos données, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
		tribe_house = "<r>Les données ne sont pas sauvegardées dans les maisons de tribus.",
		invalid_syntax = "<r>Syntaxe invalide.",
		user_not_in_room = "<r>Le joueur <n2>%s</n2> n'est pas dans le salon.",
		arg_must_be_id = "<r>L'argument doit être un ID valide.",
		cant_update = "<r>Impossible de mettre à jour les rangs des joueurs pour l'instant. Réessayez plus tard.",
		cant_edit = "<r>Vous ne pouvez pas modifier le rang de <n2>%s</n2>.",
		invalid_rank = "<r>Rang invalide: <n2>%s",
		code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
		panic_mode = "<r>Le module est maintenant en mode panique.",
		public_panic = "<r>Merci d'attendre jusqu'à ce que le bot arrive et redémarre le serveur.",
		tribe_panic = "<r>Veuillez écrire <n2>/module parkour</n2> pour redémarrer le module.",
		emergency_mode = "<r>Mise en place du blocage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon #parkour.",
		bot_requested = "<r>Le bot a été sollicité, il devrait arrivé dans un moment.",
		stream_failure = "<r>Échec du canal de transmission interne. Impossible de transmettre les données.",
		maps_not_available = "<r>Le mode 'maps' de #parkour est seulement autorisé dans<n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>La version du bot (<d>%s</d>) et du Lua(<d>%s</d>) ne sont pas compatible ensemble. Impossible de démarrer le système.",
		missing_bot = "<r>Le bot est absent. Attendez jusqu'à ce que le bot arrive ou mentionnez @Tocu#0018 sur Discord: <d>%s</d>",
		invalid_length = "<r>Votre message doit obligatoirement être compris entre 10 et 100 caractères. Il contient <n2>%s</n2> caractères.",
		invalid_map = "<r>Carte invalide.",
		map_does_not_exist = "<r>Cette carte n'existe pas ou ne peut pas être chargée. Réessayez plus tard.",
		invalid_map_perm = "<r>Cette carte n'est pas P22 ou P41.",
		invalid_map_perm_specific = "<r>La carte n'est pas P%s.",
		cant_use_this_map = "<r>Cette carte a un bug et ne peut pas être utilisée.",
		invalid_map_p41 = "<r>Cette carte est en P41, mais n'est pas dans la liste des cartes de ce module.",
		invalid_map_p22 = "<r>Cette carte est en P22, mais n'est pas dans la liste des cartes de ce module.",
		map_already_voting = "<r>Cette map a déjà un vote en cours.",
		not_enough_permissions = "<r>Vous n'avez pas assez de permissions pour faire ça.",
		already_depermed = "<r>Cette carte est déjà non-permanente.",
		already_permed = "<r>Cette carte est déjà permanente.",
		cant_perm_right_now = "<r>Impossible de changer les permissions de cette carte maintenant. Réessayez plus tard.",
		already_killed = "<r>Le joueur %s a déjà été tué.",
		leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été encore chargé. Attendez une minute.",

		-- Help window
		help = "Aide",
		staff = "Staff",
		rules = "Règles",
		contribute = "Contribuer",
		changelog = "Changements",
		help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font>\n\n<font size = '12'><J>Votre but est d'atteindre tous les points de sauvegarde pour finir la carte.</J></font></p>\n\n<font size = '11'><N>• Appuyez sur <O>O</O>, écrivez <O>!op</O> ou cliquez le <O>bouton de configuration</O> pour ouvrir le <T>menu des options</T>.\n• Appuyez sur <O>P</O> ou cliquez l'<O>icône de main</O> en haut à droite pour ouvrir le <T>menu des pouvoirs</T>.\n• Appuyez sur <O>L</O> ou écrivez <O>!lb</O> pour ouvrir le <T>tableau des scores</T>.\n• Utilisez la touche <O>M</O> ou la touche <O>Suppr.</O> comme un raccourci de <T>/mort</T>, vous pouvez personnaliser les touches dans le menu des <J>Options</J>.\n• Pour en savoir plus à propos de notre <O>staff</O> et des <O>règles de parkour</O>, cliquez sur les pages respectives du <T>Staff</T> et des <T>Règles</T>.\n• Cliquez <a href='event:discord'><o>ici</o></a> pour avoir le lien d'invitation pour le discord et <a href='event:map_submission'><o>ici</o></a> pour avoir le lien de soumission de cartes.\n• Utilisez les flèches d'<o>en haut</o> et d'<o>en bas</o> quand vous avez besoin de scroller.\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! pour plus d'informations, cliquez sur la page <O>Contribuer</O> </T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour n'est pas le Staff de Transformice, ils n'ont aucun pouvoir sur le jeu en lui-même, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien, avec le moins de problèmes possible et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff en ligne.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module lui-même en ajoutant des mises à jour et en réparant les bugs.\n\n<font color = '#843DA4'>Managers des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement des nouveaux membres du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsable de vérifier, ajouter et de supprimer des cartes dans le module pour rendre vos parties plus agréables.",
		help_rules = "<font size = '13'><B><J>Toutes Les Règles des Termes et des Conditions de Transformice s'appliquent aussi dans #parkour.</J></B></font>\n\nSi vous surprenez un joueur en train d'enfreindre les règles, chuchotez à un modérateur du module #parkour connecté. Si aucun modérateur n'est en ligne, rapportez-le dans le serveur Discord.\nPour tous reports, veuillez inclure : le serveur, le nom du salon, et le nom du joueur.\n• Ex: fr-#parkour10 Blank#3495 troll\nDes preuves, comme des captures d'écran, des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>• Aucun <font color = '#ef1111'> hack, aucune glitch ou bugs</font> utilisés/abusés ne sont autorisés dans les salons #parkour\n• <font color = '#ef1111'>Le farm VPN</font> est considéré comme <B>une violation</B> et n'est pas autorisé. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Mais, <font color='#cc2222'><B>nous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Quelqu'un troll si il empêche, grâce à ses pouvoirs, de laisser les autres joueurs finir la carte.</j></p>\n• Le troll en revanche d'un autre troll<B>n'est pas une raison valable</B> et vous serez quand même puni.\n• Aider un joueur disant vouloir faire la carte seule est aussi considéré comme du troll.\n• <J>Si un joueur veut réaliser la carte sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au même point de sauvegarde que celui-ci, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera punis par soit un certain temps ou attendre un certain nombre de cartes parkour sans pouvoir les jouer. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
		help_contribute = "<font size='14'>\n<p align='center'>L'équipe de management de parkour aime l'open-source car <t>cela aide la communauté</t>. Vous pouvez <o>voir</o> et <o>modifier</o> le code source sur <o><u><a href='event:github'>GitHub</a></u></o>.\n\nEntretenir le module est <t>strictement volontaire</t>, donc toute aide à propos du <t>code</t>, <t>des rapports de bugs</t>, <t>des suggestions</t> et <t>la création de cartes</t> est toujours <u>la bienvenue et apprécié</u>.\nVous pouvez <vp>rapporter des bugs</vp> et <vp>faire des suggestions</vp> dans <o><u><a href='event:discord'>Discord</a></u></o> et/ou <o><u><a href='event:github'>GitHub</a></u></o>.\nVous pouvez <vp>proposer des cartes</vp> sur le <o><u><a href='event:map_submission'>Forum</a></u></o>.\n\nEntretenir le parkour n'est pas cher, mais ce n'est pas non plus gratuit. Nous apprécierons si vous nous aidez en <t>faisant un don</t> <o><u><a href='event:donate'>ici</a></u></o>.\n<u>Toutes les donations iront directement dans l'amélioration du module.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Amélioration de stockage de données internes. <vp>Espérez moins de crashs</vp>\n• Réfactorisation d'un ancien système pour communiquer avec les robots. <vp>Ca va vite maintenant !</vp>\n• Ajout d'un chat de <d>classement hebdomadaire</d> sur <a href='event:discord'><u>discord</u></a>. Les 3 meilleures joueurs de chaque semaines apparaîtront ici !\n• Réparation de beaucoup de bugs internes.\n• Les maisons de tribus peuvent maintenant utiliser le mode <vp>vérification</vp>. <b>!review</b> pour l'activer/le désactiver.\n• <vp>Vous pouvez changer de langue maintenant !</vp> Utilisez <b>!langue</b> pour voir la liste des langues disponibles.",

		-- Congratulation messages
		reached_level = "<d>Bravo! Vous avez atteint le niveau <vp>%s</vp>.",
		finished = "<d><o>%s</o> a fini le parkour en <vp>%s</vp> secondes, <fc>félicitations !",
		unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir <vp>%s</vp>.",
		enjoy = "<d>Profite de tes nouvelles compétences!",

		-- Information messages
		paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
		resumed_events = "<n2>Le module n'est plus en pause.",
		welcome = "<n>Bienvenue à<t>#parkour</t>!",
		type_help = "<pt>Nous vous recommandons d'utiliser la commande <d>!help</d> pour voir des informations utiles !",
		data_saved = "<vp>Données sauvegardées.",
		action_within_minute = "<vp>Cette action sera réalisée dans quelques minutes.",
		rank_save = "<n2>Écrivez <d>!rank save</d> pour appliquer les changements.",
		module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans<d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Système de carte<t>(v%s)</t> chargé.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a rejoint le salon.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a quitté le salon.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a chargé la carte.",
		starting_perm_change = "<j>[INFO] <n>Commencement du changement de permissions...",
		got_map_info = "<j>[INFO] <n>Informations de la carte récupérées. Essaie de changement de permissions...",
		perm_changed = "<j>[INFO] <n>Réussite du changement de permission de la carte<ch>@%s</ch> de <r>P%s</r> vers <t>P%s</t>.",
		data_migration = "Toutes les données ont besoin d'être migrées. Cela veut dire que vous n'avez actuellement aucune carte complétée. Pour récupérer vos données, allez sur le salon: <a href='event:migration'><b>*#drawbattle0migration</b></a>.",
		leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
		kill_minutes = "<R>Vos pouvoirs ont été désactivés pour %s minutes.",
		kill_map = "<R>Vos pouvoirs ont été désactivés jusqu'à la prochaine carte.",
		permbanned = "<r>Vous avez été banni de #parkour définitevement.",
		tempbanned = "<r>Vous avez été banni de parkour pendant %s minutes.",
		staff_power = "<r>Le staff de parkour <b>n'a pas</b> de pouvoir en dehors du module.",
		no_help = "<r>Les personnes avec une ligne rouge au-dessus d'eux ne veulent pas d'aide !",

		-- Miscellaneous

		options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtiliser les particules comme points de sauvegarde\n\nUtiliser le clavier <b>QWERTY</b> (désactiver si votre clavier est en <b>AZERTY</b>)\n\nUtiliser <b>M</b> comme raccourci pour <b>/mort</b> (désactiver pour <b>DEL</b>)\n\nAffiche le temps de recharge de vos compétences\n\nAffiche les boutons pour utiliser les compétences\n\nAffiche le bouton d'aide\n\nAffiche les annonces des cartes achevées\n\nAffichage d'un indicateur pour ne pas être aidé.",
		unknown = "Inconnu",
		powers = "Pouvoirs",
		press = "<vp>Appuyer sur %s",
		click = "<vp>Clic gauche",
		ranking_pos = "Classement #%s",
		completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
		leaderboard = "Tableau des scores",
		position = "Position",
		username = "Pseudo",
		community = "Communauté",
		completed = "Cartes complétées",
		not_permed = "sans permissions",
		permed = "avec des permissions",
		points = "%d points",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Commencée par <d>%s</d>. Dernier commentaire par <d>%s</d>. <d>%s</d> commentaire(s), <d>%s</d> non-lu(s).",
		map_info = "<p align='center'>Code de la carte: <bl>@%s</bl> <g>|</g> Auteur de la carte: <j>%s</j> <g>|</g> Statut: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
		permed_maps = "Carte ayant des permissions",
		ongoing_votations = "Votes en cours",
		archived_votations = "Votes archivés",
		open = "Ouvrir",
		not_archived = "non-archivé",
		archived = "archivé",
		delete = "<r><a href='event:%s'>[supprimer]</a> ",
		see_restore = "<vp><a href='event:%s'>[voir]</a> <a href='event:%s'>[restaurer]</a> ",
		no_comments = "Pas de commentaires.",
		deleted_by = "<r>[Message supprimé par %s]",
		dearchive = "dé-archiver", -- pour ne plus archiver
		archive = "archiver", -- pour archiver
		deperm = "enlever les permissions", -- pour enlever les permissions
		perm = "permissions", -- pour ajouter des permissions
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a> <g>|</g> Votre  vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[chargement]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Charger une carte personnalisée</a></p>",
		write_comment = "Écrivez votre commentaire en-dessous",
		write_map = "Écrivez les codes de la carte en-dessous",
		overall_lb = "Permanent",
		weekly_lb = "Hebdomadaire",
		new_lang = "<v>[#] <d>Langue changée vers Français",

		-- Power names
		balloon = "Ballon",
		masterBalloon = "Ballon Maître",
		bubble = "Bulle",
		fly = "Voler",
		snowball = "Boule de neige",
		speed = "Vitesse",
		teleport = "Téléportation",
		smallbox = "Petite boite",
		cloud = "Nuage",
		rip = "Tombe",
		choco = "Planche de chocolat",
		bigBox = "Grande boîte",
		trampoline = "Trampoline",
		toilet = "Toilettes"
	}
	--[[ End of file translations/parkour/fr.lua ]]--
	--[[ File translations/parkour/hu.lua ]]--
	translations.hu = {
		name = "hu",
		fullname = "Hungarian",

		-- Error messages
		corrupt_map = "<r>Sérült pálya. Egy másik betöltése.",
		corrupt_map_vanilla = "<r>[HIBA] <n>Nem található információ a pályáról.",
		corrupt_map_mouse_start = "<r>[HIBA] <n>Ennek a pályának rendelkeznie kell egy kezdőponttal (egér spawnpontja).",
		corrupt_map_needing_chair = "<r>[HIBA] <n>A pályának rendelkeznie kell egy székkel.",
		corrupt_map_missing_checkpoints = "<r>[HIBA] <n>A pályának rendelkeznie kell legalább egy checkpointtal (sárga szög).",
		corrupt_data = "<r>Sajnos az adataid megsérültek, így újra lettek állítva.",
		min_players = "<r>Az adatok mentéséhez legalább 4 egérnek tartózkodnia kell a szobában. <bl>[%s/%s]",
		tribe_house = "<r>Az adatok nem kerülnek megntésre a törzsházakban.",
		invalid_syntax = "<r>Érvénytelen szintakszis.",
		user_not_in_room = "<r><n2>%s</n2> felhasználó nincs a szobában.",
		arg_must_be_id = "<r>Az argumentumnak érvényes azonosítónak kell lennie.",
		cant_update = "<r>Jelenleg nem lehet frissítenia  játékosok rangsorát. Próbáld újra később.",
		cant_edit = "<r>Nem szerkesztheted <n2>%s</n2> rangsorát.",
		invalid_rank = "<r>Érvénytelen rang: <n2>%s",
		code_error = "<r>Hiba jelent meg: <bl>%s-%s-%s %s",
		panic_mode = "<r>A modul pánik üzemmódba kapcsol.",
		public_panic = "<r>Várj, amíg egy bot újraindítja a modult.",
		tribe_panic = "<r>A modul újraindításához írd be a <n2>/module parkour</n2> parancsot.",
		emergency_mode = "<r>Vészleállítás kezdeményezése, új játékosok nem engedélyezettek. Kérjük, menj egy másik #parkour szobába.",
		bot_requested = "<r>A botot meghívták. Egy pillanat alatt meg kell érkeznie.",
		stream_failure = "<r>Belső stream-csatorna hiba. Az adatokat nem lehet továbbítani.",
		maps_not_available = "<r>#parkour 'maps' almód csak angol nyelven érhető el <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>A bot (<d>%s</d>) és a lua (<d>%s</d>) verziók nem egyeznek. A rendszer nem indítható.",
		missing_bot = "<r>A bot hiányzik. Várd meg, amíg a bot megérkezik, vagy pingeld @Tocu#0018 -t; discordon: <d>%s</d>",
		invalid_length = "<r>Az üzenetben 10 és 100 között kell lennie. Ez <n2>%s</n2> karakterrel rendelkezik.",
		invalid_map = "<r>Érvénytelen pálya.",
		map_does_not_exist = "<r>A megadott pálya nem létezik vagy nem lehet betölteni. Próbáld újra később.",
		invalid_map_perm = "<r>A megadott pálya nem P22 vagy P41.",
		invalid_map_perm_specific = "<r>A megadott pálya nem P%s.",
		cant_use_this_map = "<r>A megadott pálya egy kis hibával rendelkezik, így nem használható.",
		invalid_map_p41 = "<r>A megadott pálya P41, de nem található a modul pályáinak listájában.",
		invalid_map_p22 = "<r>>A megadott pálya P22, de nem található a modul pályáinak listájában.",
		map_already_voting = "<r>A megadott pálya már rendelkezik nyílt szavazással..",
		not_enough_permissions = "<r>Nincs elég engedélyed ehhez.",
		already_depermed = "<r>A megadott pálya már elavult.",
		already_permed = "<r>A megadott pálya már át van alakítva.",
		cant_perm_right_now = "<r>Jelenleg nem lehet megváltoztatni a pálya engedélyét. Próbáld újra később.",
		already_killed = "<r>%s játékost már megölték.",
		leaderboard_not_loaded = "<r>A ranglista még nem töltött be. Várj egy percet.",

		-- Help window
		help = "Segítség",
		staff = "Személyzet",
		rules = "Szabályzat",
		contribute = "Hozzájárulás",
		changelog = "Hírek",
		help_help = "<p align = 'center'><font size = '14'>Üdvözlünk a <T>#parkour</T>-on!</font></p>\n<font size = '11'><p align='center'><J>A célod, hogy elérd az összes checkpointot, miközben teljesíted a pályát.</J></p>\n\n<N>• Nyomd meg az <O>O</O> gombot, írd be a <O>!op</O> parancsot vagy kattints a  <O>konfigurációs gombra</O> a <T>beállítások menüjéhez</T> való megnyitáshoz.\n• Nyomd meg a <O>P</O> gombot vagy kattints a <O>kéz ikonra</O> a jobb felső sarokban az <T>erők menüjéhez</T> való megnyitáshoz.\n• Nyomd meg az <O>L</O> gombot vagy írd be a <O>!lb</O> parancsot a <T>randlista</T> megnyitásához.\n• Nyomd meg az <O>M</O> gombot vagy a <O>Delete</O> gombot <T>/mort</T> parancshoz, megváltoztathatod a gombokat az <J>Beállítások</J> menüben.\n• Ha szeretnél többet tudni a <O>személyzetről</O> és a <O>parkour szabályairól</O>, akkor kattints a <T>Személyzet</T> és <T>Szabályzat</T> fülre.\n• Kattints <a href='event:discord'><o>ide</o></a> a Discord meghívó linkért és <a href='event:map_submission'><o>ide</o></a> kattintva megkaphatod a pályabenyújtási téma linkjét.\n• Használd a <o>fel</o> és <o>le</o> nyilakat, amikor görgetned kell a menüben.\n\n<p align = 'center'><font size = '13'><T>A hozzájárulások már nyitva vannak! További részletekért kattints a <O>Hozzájárulás</O> fülre!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>FELHÍVÁS: A Parkour személyzet NEM Transformice személyzet és NEM rendelkeznek hatalommal a játékban, csak a modulon belül.</r>\nA Parkour személyzete gondoskodik arról, hogy a modul zökkenőmentesen működjön minimális problémákkal. Ők mindig rendelkezésre állnak, hogy szükség esetén segítsék a játékosokat.</font></p>\nÍrd be a <D>!staff</D> parancsot a chatbe, hogy lásd a személyzet listáját.\n\n<font color = '#E7342A'>Rendszergazdák:</font> Ők felelnek a modul karbantartásáért az új frissítések és hibák kijavításával.\n\n<font color = '#843DA4'>Csapatvezetők:</font> Ők ügyelik a Moderátorok és Pálya legénység csapatát ügyelve arra, hogy megfelelően végezzék a munkájukat. Továbbá ők felelősek az új tagok toborzásáért a személyzet csapatába.\n\n<font color = '#FFAAAA'>Moderátorok:</font> Ők felelnek a modul szabályzatának betartásáért és a rájuk nem hallgató személyek büntetéséért.\n\n<font color = '#25C059'>Pálya legénység:</font> Ők felelnek a pályák felülvizsgálatáért, hozzáadásáért és eltávolításáért a modulon belül annak érdekében, hogy a játékmenet élvezetes legyen.",
		help_rules = "<font size = '13'><B><J>A Transformice Általános Szerződési feltételeinek minden szabálya vonatkozik a #parkour-ra</J></B></font>\n\nHa olyan játékost találsz, aki megsérti a szabályokat, akkor suttogásban szólj a moderátoroknak. Ha nem érhető el moderátor, akkor jelentsd a játékost a Discord felületen.\nJelentéskor kérjük, add meg a szerver-, a szoba- és a játékos nevét.\n• Például: hu-#parkour10 Blank#3495 trollkodás\nA bizonyítékok, mint például képernyőfotók, videók és gifek hasznosak és értékeljük, de nem szükségesek.\n\n<font size = '11'>• A #parkour szobákban nem lehet <font color = '#ef1111'>hacket, glitcheket vagy bugokat</font> használni\n• A <font color = '#ef1111'>VPN farmolást</font> <B>kizsákmányolásnak</B> tekintjük, és nem engedélyezettek. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nBárkit, akit szabálysértésen kapunk, azonnal bannoljuk.</B></font></p>\n\n<font size = '12'>A Transformice engedélyezi a trollkodást. Ettől függetlenül <font color='#cc2222'><B>a parkour-ban nem engedélyezzük ezt.</B></font></font>\n\n<p align = 'center'><J>Trollkodásnak számít, ha egy játékos szándékosan arra használja az erőit, hogy megakadályozza máss játékosoknak a pálya végigjátszását.</j></p>\n• Bosszúból trollkodni nem megfelelő ok, és még mindig büntetjük.\n• Trollkodásnak tekintjük azt is, amikor egy játékos a kérés ellenére is megpróbálja segíteni azt a játékost, aki egyedül akarja végigjátszani a pályát.\n• <J>Ha egy játékos nem akar segítséget vagy egy pályát jobban szeretné egyedül végigjátszani, kérjük, segíts más játékosnak</J>. Ettől függetlenül, ha egy másik játékosnak segítségre van szüksége ugyan abban a checkpointban, akkor segíthetsz nekik [mindkettőnek].\n\nHa egy játékos trollkodásba kerül, akkor büntetjük bármikor, vagy az aktuális parkour körben. Vedd figyelembe, hogy az ismétlődő trollkodás hosszabb és súlyosabb büntetésekkel jár.",
		help_contribute = "<font size='14'>\n<p align='center'>A parkour menedzsment csapata szereti a nyílt forráskódot, mert ez <t>segít a közösségnek</t>. <o>Megtekintheted</o> és <o>módosíthatod</o> a nyílt forráskódot a <o><u><a href='event:github'>GitHub</a></u></o>-on.\n\nA modul karbantartása <t>szigorúan önkéntes</t>, ezért a <t>kód</t> olvasásával, <t>hibajelentésekkel</t>, <t>javaslatokkal</t> és <t>pályakészítéssel</t> kapcsolatos bármilyen segítséget <u>mindig örömmel fogadunk és értékeljük</u>.\nTehetsz <vp>hibajelentéseket</vp> és <vp>javaslatokat</vp> a <o><u><a href='event:discord'>Discord</a></u></o>-on és/vagy <o><u><a href='event:github'>GitHub</a></u></o>-on.\nA <vp>pályádat beküldheted</vp> a mi <o><u><a href='event:map_submission'>Fórum témánkba</a></u></o>.\n\nA parkour fenntartása nem drága, de nem is ingyenes. Szeretnénk, ha <t>bármekkora összeggel</t> támogatnál minket <o><u><a href='event:donate'>ide</a></u></o> kattintva.\n<u>Minden támogatás a modul fejlesztésére irányul.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Verzió 2.4.0 - 2020/06/16</o></p>\n\n• Javított belső adattárolási rendszer. <vp>Kevesebb az összeomlás!</vp>\n• Egy felújított régi rendszer, mely a robotokkal való kommunikálást teszi lehetővé. <vp>Most már nagyon gyors!</vp>\n• Hozzáadva egy <d>heti rekordok</d> csatorna a <a href='event:discord'><u>discordon</u></a>. Minden héten a 3 legjobb játékos jelenik meg!\n• Sok belső hiba javítva.\n• A törzsházak használhatják az <vp>áttekintés</vp> módot. <b>!review</b> az engedélyezéshez/letiltáshoz.\n• <vp>Most már megváltoztathatod a nyelved!</vp> Használd a <b>!langue</b> parancsot az összes elérhető nyelv megjelenítéséhez.",

		-- Congratulation messages
		reached_level = "<d>Gratulálunk! Elérted a(z) <vp>%s</vp>. szintet.",
		finished = "<d><o>%s</o> a parkourt <vp>%s</vp> másodperc alatt fejezte be. <fc>Gratulálunk!",
		unlocked_power = "<ce><d>%s</d> feloldotta a(z) <vp>%s</vp> erőt.",
		enjoy = "<d>Élvezd az új képességeid!",

		-- Information messages
		paused_events = "<cep><b>[Figyelem!]</b> <n>A modul elérte a kritikus határát, így szüneteltetés alatt áll.",
		resumed_events = "<n2>A modul folytatódik.",
		welcome = "<n>Üdvözlünk a <t>#parkour</t>-on!",
		mod_apps = "<j>A Parkour Moderátor jelentkezések nyitva vannak! Használd ezt a linket: <rose>%s",
		type_help = "<pt>Ajánljuk, hogy írd be a <d>!help</d> parancsot hasznos információkért.",
		data_saved = "<vp>Adatok elmentve.",
		action_within_minute = "<vp>A művelet egy perc alatt megtörténik.",
		rank_save = "<n2>A változtatások alkalmazásához írd be a <d>!rank save</d> parancsot.",
		module_update = "<r><b>[Figyelem!]</b> <n>A modul frissül <d>%02d:%02d</d> percen belül.",
		mapping_loaded = "<j>[INFÓ] <n><t>(v%s)</t> pályarendszer betöltve.",
		mapper_joined = "<j>[INFÓ] <n><ce>%s</ce> <n2>(%s)</n2> csatlakozott a szobához.",
		mapper_left = "<j>[INFÓ] <n><ce>%s</ce> <n2>(%s)</n2> elhagyta a szobát.",
		mapper_loaded = "<j>[INFÓ] <n><ce>%s</ce> pálya be lett töltve.",
		starting_perm_change = "<j>[INFÓ] <n>Végleges változtatás elkezdése...",
		got_map_info = "<j>[INFÓ] <n>Pálya információ megszerezve. Kísérlet a végleges változtatására...",
		perm_changed = "<j>[INFÓ] <n>Sikeresen megváltozott a végleges pálya <ch>@%s</ch> <r>P%s</r>-ről <t>P%s</t>-re.",
		leaderboard_loaded = "<j>A ranglista be lett töltve. Nyomd meg az L gombot a megnyitásához.",
		kill_minutes = "<R>Az erőidet %s percre letiltottuk.",
		kill_map = "<R>Az erőidet letiltottuk a következő pályáig.",
		permbanned = "<r>Véglegesen ki lettél tiltva a #parkour -ból.",
		tempbanned = "<r>Ki lettél tiltva %s másodpercre a #parkour -ból.",
		staff_power = "<r>A parkour személyzetének  <b>nincs</b> hatalma a #parkour pályákon kívül.",
		no_help = "<r>Azok az emberek, akiknek vörös vonal van az egerük felett, nem akarnak segítséget!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkour Beállítások</font></p>\n\nHasználj partikülöket a checkpointokhoz\n\nHasználd a <b>QWERTY</b> billentyűzetet (tiltsd le, ha <b>AZERTY</b>-d van)\n\nHasználd az <b>M</b> gyorsbillentyűt a <b>/mort</b> parancshoz (tiltsd le a <b>DEL</b>-t)\n\nMutassa az erők újratöltési idejét\n\nMutassa az erők gombot\n\nMutassa a segítség gombot\n\nMutassa a teljesített pálya jelentéseket\n\nJelenítse meg a nincs segítség szimbólumot",
		unknown = "Ismeretlen",
		powers = "Erők",
		press = "<vp>Nyomd meg: %s",
		click = "<vp>Bal klikk",
		ranking_pos = "Rang #%s",
		completed_maps = "<p align='center'><BV><B>Teljesített pályák: %s</B></p></BV>",
		leaderboard = "Ranglista",
		position = "Pozíció",
		username = "Felhasználónév",
		community = "Közösség",
		completed = "Teljesített pályák",
		not_permed = "nem véglegesített",
		permed = "véglegesített",
		points = "%d pont",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Elindította: <d>%s</d>. Utolsó hozzászólás: <d>%s</d>. <d>%s</d> hozzászólás, <d>%s</d> olvasatlan.",
		map_info = "<p align='center'>Pályakód: <bl>@%s</bl> <g>|</g> Pályakészítő: <j>%s</j> <g>|</g> Állapot: <vp>%s, %s</vp> <g>|</g> Pontok: <vp>%s</vp>",
		permed_maps = "Véglegesített pályák",
		ongoing_votations = "Folyamatban lévő szavazások",
		archived_votations = "Archivált szavazatok",
		open = "Nyit",
		not_archived = "nem archivált",
		archived = "archivált",
		delete = "<r><a href='event:%s'>[töröl]</a> ",
		see_restore = "<vp><a href='event:%s'>[lásd]</a> <a href='event:%s'>[visszaállítás]</a> ",
		no_comments = "Nincs hozzászólás.",
		deleted_by = "<r>[Az üzenetet %s törölte]",
		dearchive = "dearchiválás", -- to dearchive
		archive = "archiválás", -- to archive
		deperm = "deperm", -- to deperm
		perm = "végleges", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Hozzászólás</j></a> <g>|</g> A te szavazatod: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[betöltés]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Hozzászólás</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Töltsd be az egyedi pályád</a></p>",
		write_comment = "Hozzászólásodat írd le ide",
		write_map = "Írd le a pályakódot ide",
		overall_lb = "Teljes",
		weekly_lb = "Heti",
		new_lang = "<v>[#] <d>Nyelv beállítása Hungarian Magyar",

		-- Power names
		balloon = "Léggömb",
		masterBalloon = "Mester Léggömb",
		bubble = "Buborék",
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
		toilet = "Toalet"
	}
	--[[ End of file translations/parkour/hu.lua ]]--
	--[[ File translations/parkour/ru.lua ]]--
	translations.ru = {
		name = "ru",
		fullname = "English",

		-- Сообщения об ошибках
		corrupt_map = "<r>Поврежденная карта. загрузите другую.",
		corrupt_map_vanilla = "<r>[ОШИБКА] <n>Не удается получить информацию о карте.",
		corrupt_map_mouse_start = "<r>[ОШИБКА] <n>Карта должна иметь начальную позицию (точку появления мыши).",
		corrupt_map_needing_chair = "<r>[ОШИБКА] <n>На карте должно находиться кресло для окончания раунда.",
		corrupt_map_missing_checkpoints = "<r>[ОШИБКА] <n>Карта должна иметь хотя бы один чекпоинт (желтый гвоздь).",
		corrupt_data = "<r>К сожалению, ваши данные повреждены и были сброшены.",
		min_players = "<r>Чтобы сохранить ваши данные, в комнате должно быть как минимум 4 уникальных игрока. <bl>[%s/%s]",
		tribe_house = "<r>Данные не будут сохранены в комнате племени.",
		invalid_syntax = "<r>Неверный синтаксис.",
		user_not_in_room = "<r>Пользователь <n2>%s</n2> не находится в комнате.",
		arg_must_be_id = "<r>Аргумент должен быть действительным идентификатором.",
		cant_update = "<r>Невозможно обновить рейтинг и. Попробуйте позже.",
		cant_edit = "<r>Вы не можете редактировать <n2>%s's</n2> ранги.",
		invalid_rank = "<r>Неверный ранг: <n2>%s",
		code_error = "<r>Появилась ошибка: <bl>%s-%s-%s %s",
		panic_mode = "<r>Модуль находится в критическом состоянии.",
		public_panic = "<r>Пожалуйста, дождитесь прибытия бота и перезапустите модуль..",
		tribe_panic = "<r>Пожалуйста, введите <n2>/модуль паркура</n2> чтобы перезапустить модуль.",
		emergency_mode = "<r>Активировано аварийное отключение, новые игроки не смогут зайти. Пожалуйста, перейдите в другую комнату #pourour.",
		bot_requested = "<r>Запрос к боту был отправлен. Он должен появиться в скором времени.",
		stream_failure = "<r>Внутренний канал передачи завершился с ошибкой. Невозможно передать данные.",
		maps_not_available = "<r>#parkour's 'map' подрежим доступен только в <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Бот (<d>%s</d>) и lua (<d>%s</d>) версии не совпадают. Невозможно запустить систему.",
		missing_bot = "<r>Bot отсутствует. Подождите, пока бот не появится или напишите @Tocu#0018 в discord: <d>%s</d>",
		invalid_length = "<r>Ваше сообщение должно содержать от 10 до 100 символов. Оно имеет <n2>%s</n2> символов.",
		invalid_map = "<r>Неверная карта.",
		map_does_not_exist = "<r>Карта не существует или не загружена. Попробуйте позже.",
		invalid_map_perm = "<r>Карта не P22 или P41.",
		invalid_map_perm_specific = "<r>Карта не находится в P%s.",
		cant_use_this_map = "<r>Карта имеет небольшой баг (ошибку) и не может быть использована.",
		invalid_map_p41 = "<r>Карта находится в P41, но отсутствует в списке карт модуля.",
		invalid_map_p22 = "<r>Карта находится в P22, но находится в списке карт модуля.",
		map_already_voting = "<r>Голосование за эту карту уже открыто.",
		not_enough_permissions = "<r>У вас недостаточно прав, чтобы сделать это.",
		already_depermed = "<r>Данная карта уже отклонена.",
		already_permed = "<r>Данная карта уже принята.",
		cant_perm_right_now = "<r>Не могу изменить статус этой карты прямо сейчас. Попробуйте позже.",
		already_killed = "<r>Игрок %s уже убит.",
		leaderboard_not_loaded = "<r>Таблица лидеров еще не загружена. Подождите минуту.",

		-- Help window
		help = "Помощь",
		staff = "Команда модераторов",
		rules = "Правила",
		contribute = "Содействие",
		changelog = "Изменения",
		help_help = "<p align = 'center'><font size = '14'>Добро пожаловать в <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Ваша цель - собрать все чекпоинты, чтобы завершить карту.</J></p>\n\n<N>• Нажмите <O>O</O>, введите <O>!op</O> или нажмите на <O> шестеренку</O> чтобы открыть <T>меню настроек</T>.\n• Нажмите <O>P</O> или нажмите на <O>руку</O> в правом верхнем углу, чтобы открыть <T>меню со способностями</T>.\n• Нажмите <O>L</O> или введите <O>!lb</O> чтобы открыть <T>Список лидеров</T>.\n• Нажмите <O>M</O> или <O>Delete</O> чтобы не прописывать <T>/mort</T>.\n• Чтобы узнать больше о нашей <O>команде</O> и о <O>правилах паркура</O>, нажми на <T>Команда</T> и <T>Правила</T>.\n• Нажмите <a href='event:discord'><o>here</o></a> чтобы получить ссылку на приглашение в наш Дискорд канал. Нажмите <a href='event:map_submission'><o>here</o></a> чтобы получить ссылку на тему отправки карты.\n• Используйте клавиши <o>вверх</o> и <o>вниз</o> чтобы листать меню.\n\n<p align = 'center'><font size = '13'><T>Вкладки теперь открыты! Для получения более подробной информации, нажмите на вкладку <O>Содействие</O> !</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>ОБЯЗАННОСТИ: Команда Паркура НЕ команда Transformice и НЕ имеет никакой власти в самой игре, только внутри модуля.</r>\nКоманда Parkour обеспечивают исправную работу модуля с минимальными проблемами и всегда готова помочь игрокам в случае необходимости.</font></p>\nВы можете ввести <D>!staff</D> в чат, чтобы увидеть нашу команду.\n\n<font color = '#E7342A'>Администраторы:</font> Hесут ответственность за поддержку самого модуля, добавляя новые обновления и исправляя ошибки.\n\n<font color = '#843DA4'>Руководители команд:</font> Kонтролируют команды модераторов и картостроителей, следя за тем, чтобы они хорошо выполняли свою работу. Они также несут ответственность за набор новых членов в команду.\n\n<font color = '#FFAAAA'>Модераторы:</font> Hесут ответственность за соблюдение правил модуля и наказывают тех, кто не следует им.\n\n<font color = '#25C059'>Картостроители:</font> Oтвечают за просмотр, добавление и удаление карт в модуле, обеспечивая вам приятный игровой процесс.",
		help_rules = "<font size = '13'><B><J>Все правила пользователя и условия Transformice также применяются к #parkour </J></B></font>\n\nЕсли вы обнаружили, что кто-то нарушает эти правила, напишите нашим модераторам. Если модераторов нет в сети, вы можете сообщить об этом на на нашем сервере в Discord\nПри составлении репорта, пожалуйста, укажите сервер, имя комнаты и имя игрока.\n• Пример: en-#parkour10 Blank#3495 троллинг\nДоказательства, такие как скриншоты, видео и гифки, полезны и ценны, но не обязательны.\n\n<font size = '11'>• <font color = '#ef1111'>читы, глюки или баги</font> не должны использоваться в комнатах #parkour\n• <font color = '#ef1111'>Фарм через VPN</font> считается <B>нарушением</B> и не допускается. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nЛюбой, кто пойман за нарушение этих правил, будет немедленно забанен.</B></font></p>\n\n<font size = '12'>Transformice позволяет концепцию троллинга. Однако, <font color='#cc2222'><B>мы не допустим этого в паркуре.</B></font></font>\n\n<p align = 'center'><J>Троллинг - это когда игрок преднамеренно использует свои способности, чтобы помешать другим игрокам закончить карту.</J></p>\n• Троллинг ради мести <B>не является веской причиной,</B> для троллинга кого-либо и вы все равно будете наказаны.\n• Принудительная помощь игрокам, которые пытаются пройти карту самостоятельно и отказываюся от помощи, когда их об этом просят, также считается троллингом. \n• <J>Если игрок не хочет помогать или предпочитает играть в одиночку на карте, постарайтесь помочь другим игрокам</J>. Однако, если другой игрок нуждается в помощи на том же чекпоинте, что и соло игрок, вы можете помочь им [обоим].\n\nЕсли игрок пойман на троллинге, он будет наказан на один раунд, либо на все время пребывания в паркуре. Обратите внимание, что повторный троллинг приведет к более длительным и суровым наказаниям.",
		help_contribute = "<font size='14'>\n<p align='center'>Команда управления паркуром предпочитает открытый исходный код, потому что он <t>помогает сообществу</t>. Вы можете <o>посмотреть</o> и <o>улучшить</o> исходный код на <o><u><a href='event:github'>GitHub</a></u></o>.\nПоддержание модуля<t>строго добровольно</t>, так что любая помощь в отношении <t>code</t>, <t>баг репортов</t>, <t>предложений</t> and <t>созданию карт</t> is always <u>приветствуется и ценится</u>.\nВы можете <vp>оставлять жалобу</vp> и <vp>предлагать улучшения</vp> в нашем <o><u><a href='event:discord'>Дискорде</a></u></o> и/или в <o><u><a href='event:github'>GitHub</a></u></o>.\nВы можете <vp>отправить свои карты</vp> на нашем <o><u><a href='event:map_submission'>форуме</a></u></o>.\n\nПоддержание паркура не дорогое, но и не бесплатное. Мы будем рады, если вы поможете нам <t>любой суммой</t> <o><u><a href='event:donate'>here</a></u></o>.\n<u>Все пожертвования пойдут на улучшение модуля.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Improved internal data storage system. <vp>Expect less crashes!</vp>\n• Refactored an old system used to communicate parkour with bots. <vp>It is blazing fast now!</vp>\n• Added a <d>weekly records</d> channel on <a href='event:discord'><u>discord</u></a>. Top 3 players every week will appear there!\n• Fixed many internal bugs.\n• Tribe houses can use <vp>review</vp> mode now. <b>!review</b> to enable/disable it.\n• <vp>You can switch your language now!</vp> Use <b>!langue</b> to list all the available languages.",

		-- Congratulation messages
		reached_level = "<d>Поздравляем! Вы достигли уровня <vp>%s</vp>.",
		finished = "<d><o>%s</o> завершил паркур за <vp>%s</vp> секунд, <fc>поздравляем!",
		unlocked_power = "<ce><d>%s</d> разблокировал способность <vp>%s</vp>.",
		enjoy = "<d>Наслаждайтесь своими новыми навыками!",

		-- Information messages
		paused_events = "<cep><b>[Предупреждение!]</b> <n> Модуль достиг критического предела и сейчас временно остановлен.",
		resumed_events = "<n2>Модуль был возобновлен.",
		welcome = "<n>Добро пожаловать в<t>#parkour</t>!",
		mod_apps = "<j>Приложения паркура модератора теперь открыты! Используйте эту ссылку: <rose>%s",
		type_help = "<pt>Вы можете написать в чате <d>!help</d> чтобы увидеть полезную информацию!",
		data_saved = "<vp>Данные сохранены.",
		action_within_minute = "<vp>Действие будет применено через минуту.",
		rank_save = "<n2>Введите <d>!rank save</d> чтобы применить изменения",
		module_update = "<r><b>[Предупреждение!]</b> <n>Модуль будет обновлен в <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Система картостроения<t>(v%s)</t> загружена.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> присоеденился к комнате.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> покинул комнату.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> загрузил карту.",
		starting_perm_change = "<j>[INFO] <n>Начинаются изменения перманента...",
		got_map_info = "<j>[INFO] <n>Получена информация о карте. Попытка изменить перманент...",
		perm_changed = "<j>[INFO] <n>Успешно изменили перманент карты <ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
		leaderboard_loaded = "<j>Таблица лидеров была загружена. Нажмите L, чтобы открыть ее.",
		kill_minutes = "<R>Ваши способности отключены на %s минут.",
		kill_map = "<R>Ваши способности отключены до следующей карты.",
		permbanned = "<r>Вы были навсегда забанены в #parkour.",
		tempbanned = "<r>Вы были забанены в #parkour на %s минут.",
		staff_power = "<r>Команда паркура <b>не</b> имеет власти вне #parkour комнат.",
		no_help = "<r>Люди с красной линией над мышью не нуждаются в помощи!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Параметры Паркура</font></p>\n\nИспользуйте желтые крепления для чекпоинтов\n\nИспользуйте <b>QWERTY</b> на клавиатуре (отключить if <b>AZERTY</b>)\n\nИспользуйте <b>M</b> горячую клавишу <b>/mort</b> (отключить <b>DEL</b>)\n\nПоказать ваше время перезарядки\n\nПоказать кнопку способностей\n\nПоказать кнопку помощь\n\nПоказать объявление о завершении карты\n\nПоказать символ помощь не нужна",
		unknown = "Неизвестно",
		powers = "Способности",
		press = "<vp>Нажмите %s",
		click = "<vp>Щелчок левой кнопкой мыши",
		ranking_pos = "Рейтинг #%s",
		completed_maps = "<p align='center'><BV><B>Пройденные карты: %s</B></p></BV>",
		leaderboard = "Таблица лидеров",
		position = "Должность",
		username = "Имя пользователя",
		community = "Сообщество",
		completed = "Пройденные карты",
		not_permed = "Отклонено",
		permed = "Одобрено",
		points = "%d точки",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Автор <d>%s</d>. Последний комментарий от <d>%s</d>. <d>%s</d> комментариев, <d>%s</d> непрочитанных.",
		map_info = "<p align='center'>Код карты: <bl>@%s</bl> <g>|</g> Автор карты: <j>%s</j> <g>|</g> Статус: <vp>%s, %s</vp> <g>|</g> Точки: <vp>%s</vp>",
		permed_maps = "Одобренные карты",
		ongoing_votations = "Текущие голоса",
		archived_votations = "Архивированные голоса",
		open = "Открыто",
		not_archived = "не архивировано",
		archived = "архивировано",
		delete = "<r><a href='event:%s'>[delete]</a> ",
		see_restore = "<vp><a href='event:%s'>[see]</a> <a href='event:%s'>[restore]</a> ",
		no_comments = "Нет комментариев.",
		deleted_by = "<r>[Сообщение удалено %s]",
		dearchive = "разархивировать", -- to dearchive
		archive = "архивировать", -- to archive
		deperm = "Отклонить", -- to deperm
		perm = "Обобрить", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a> <g>|</g> Your vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[load]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Load custom map</a></p>",
		write_comment = "Напишите свой комментарий здесь",
		write_map = "Запишите код карты здесь",
		overall_lb = "В целом",
		weekly_lb = "Еженедельно",
		new_lang = "<v>[#] <d>Language set to English",

		-- Power names
		balloon = "Шар",
		masterBalloon = "Мастер шар",
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
		toilet = "Туалет"
	}
	--[[ End of file translations/parkour/ru.lua ]]--
	--[[ File translations/parkour/en.lua ]]--
	translations.en = {
		name = "en",
		fullname = "English",

		-- Error messages
		corrupt_map = "<r>Corrupt map. Loading another.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Can not get information of this map.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>This map needs to have a start position (mouse spawn point).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>The map needs to have the end chair.",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>The map needs to have at least one checkpoint (yellow nail).",
		corrupt_data = "<r>Unfortunately, your data was corrupt and has been reset.",
		min_players = "<r>To save your data, there must be at least 4 unique players in the room. <bl>[%s/%s]",
		tribe_house = "<r>Data will not be saved in tribehouses.",
		invalid_syntax = "<r>Invalid syntax.",
		user_not_in_room = "<r>The user <n2>%s</n2> is not in the room.",
		arg_must_be_id = "<r>The argument must be a valid id.",
		cant_update = "<r>Can't update player ranks right now. Try again later.",
		cant_edit = "<r>You can't edit <n2>%s's</n2> ranks.",
		invalid_rank = "<r>Invalid rank: <n2>%s",
		code_error = "<r>An error appeared: <bl>%s-%s-%s %s",
		panic_mode = "<r>Module is now entering panic mode.",
		public_panic = "<r>Please wait until a bot arrives and restarts the module.",
		tribe_panic = "<r>Please type <n2>/module parkour</n2> to restart the module.",
		emergency_mode = "<r>Initiating emergency shutdown, no new players allowed. Please go to another #parkour room.",
		bot_requested = "<r>The bot has been requested. It should be arriving in a moment.",
		stream_failure = "<r>Internal stream channel failure. Can not transmit data.",
		maps_not_available = "<r>#parkour's 'maps' submode is only available in <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Bot (<d>%s</d>) and lua (<d>%s</d>) versions do not match. Can't start the system.",
		missing_bot = "<r>Bot missing. Wait until the bot arrives or ping @Tocu#0018 on discord: <d>%s</d>",
		invalid_length = "<r>Your message must have between 10 and 100 characters. It has <n2>%s</n2> characters.",
		invalid_map = "<r>Invalid map.",
		map_does_not_exist = "<r>The given map does not exist or can't be loaded. Try again later.",
		invalid_map_perm = "<r>The given map is not P22 or P41.",
		invalid_map_perm_specific = "<r>The given map is not in P%s.",
		cant_use_this_map = "<r>The given map has a small bug and can't be used.",
		invalid_map_p41 = "<r>The given map is in P41, but is not in the module map list.",
		invalid_map_p22 = "<r>The given map is in P22, but is in the module map list.",
		map_already_voting = "<r>The given map already has an open votation.",
		not_enough_permissions = "<r>You don't have enough permissions to do this.",
		already_depermed = "<r>The given map is already depermed.",
		already_permed = "<r>The given map is already permed.",
		cant_perm_right_now = "<r>Can't change the perm of this map right now. Try again later.",
		already_killed = "<r>The player %s has been already killed.",
		leaderboard_not_loaded = "<r>The leaderboard has not been loaded yet. Wait a minute.",

		-- Help window
		help = "Help",
		staff = "Staff",
		rules = "Rules",
		contribute = "Contribute",
		changelog = "News",
		help_help = "<p align = 'center'><font size = '14'>Welcome to <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Your goal is to reach all the checkpoints until you complete the map.</J></p>\n\n<N>• Press <O>O</O>, type <O>!op</O> or click the <O>configuration button</O> to open the <T>options menu</T>.\n• Press <O>P</O> or click the <O>hand icon</O> at the top-right to open the <T>powers menu</T>.\n• Press <O>L</O> or type <O>!lb</O> to open the <T>leaderboard</T>.\n• Press the <O>M</O> or <O>Delete</O> key to <T>/mort</T>, you can toggle the keys in the <J>Options</J> menu.\n• To know more about our <O>staff</O> and the <O>rules of parkour</O>, click on the <T>Staff</T> and <T>Rules</T> tab respectively.\n• Click <a href='event:discord'><o>here</o></a> to get the discord invite link and <a href='event:map_submission'><o>here</o></a> to get the map submission topic link.\n• Use <o>up</o> and <o>down</o> arrow keys when you need to scroll.\n\n<p align = 'center'><font size = '13'><T>Contributions are now open! For further details, click on the <O>Contribute</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Parkour staff ARE NOT Transformice staff and DO NOT have any power in the game itself, only within the module.</r>\nParkour staff ensure that the module runs smoothly with minimal issues, and are always available to assist players whenever necessary.</font></p>\nYou can type <D>!staff</D> in the chat to see the staff list.\n\n<font color = '#E7342A'>Administrators:</font> They are responsible for maintaining the module itself by adding new updates and fixing bugs.\n\n<font color = '#843DA4'>Team Managers:</font> They oversee the Moderator and Mapper teams, making sure they are performing their jobs well. They are also responsible for recruiting new members to the staff team.\n\n<font color = '#FFAAAA'>Moderators:</font> They are responsible for enforcing the rules of the module and punishing individuals who do not follow them.\n\n<font color = '#25C059'>Mappers:</font> They are responsible for reviewing, adding, and removing maps within the module to ensure that you have an enjoyable gameplay.",
		help_rules = "<font size = '13'><B><J>All rules in the Transformice Terms and Conditions also apply to #parkour</J></B></font>\n\nIf you find any player breaking these rules, whisper the parkour mods in-game. If no mods are online, then it is recommended to report it in the discord server.\nWhen reporting, please include the server, room name, and player name.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidence, such as screenshots, videos and gifs are helpful and appreciated, but not necessary.\n\n<font size = '11'>• No <font color = '#ef1111'>hacks, glitches or bugs</font> are to be used in #parkour rooms\n• <font color = '#ef1111'>VPN farming</font> will be considered an <B>exploit</B> and is not allowed. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nAnyone caught breaking these rules will be immediately banned.</B></font></p>\n\n<font size = '12'>Transformice allows the concept of trolling. However, <font color='#cc2222'><B>we will not allow it in parkour.</B></font></font>\n\n<p align = 'center'><J>Trolling is when a player intentionally uses their powers to prevent other players from finishing the map.</j></p>\n• Revenge trolling is <B>not a valid reason</B> to troll someone and you will still be punished.\n• Forcing help onto players trying to solo the map and refusing to stop when asked is also considered trolling.\n• <J>If a player does not want help or prefers to solo a map, please try your best to help other players</J>. However if another player needs help in the same checkpoint as the solo player, you can help them [both].\n\nIf a player is caught trolling, they will be punished on either a time or parkour round basis. Note that repeated trolling will lead to longer and more severe punishments.",
		help_contribute = "<font size='14'>\n<p align='center'>The parkour management team loves open source code because it <t>helps the community</t>. You can <o>view</o> and <o>modify</o> the source code on <o><u><a href='event:github'>GitHub</a></u></o>.\n\nMaintaining the module is <t>strictly voluntary</t>, so any help regarding <t>code</t>, <t>bug reports</t>, <t>suggestions</t> and <t>creating maps</t> is always <u>welcome and appreciated</u>.\nYou can <vp>report bugs</vp> and <vp>give suggestions</vp> on <o><u><a href='event:discord'>Discord</a></u></o> and/or <o><u><a href='event:github'>GitHub</a></u></o>.\nYou can <vp>submit your maps</vp> in our <o><u><a href='event:map_submission'>Forum Thread</a></u></o>.\n\nMaintaining parkour is not expensive, but it is not free either. We'd love if you could help us by <t>donating any amount</t> <o><u><a href='event:donate'>here</a></u></o>.\n<u>All donations will go towards improving the module.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Version 2.4.0 - 16/06/2020</o></p>\n\n• Improved internal data storage system. <vp>Expect less crashes!</vp>\n• Refactored an old system used to communicate parkour with bots. <vp>It is blazing fast now!</vp>\n• Added a <d>weekly records</d> channel on <a href='event:discord'><u>discord</u></a>. Top 3 players every week will appear there!\n• Fixed many internal bugs.\n• Tribe houses can use <vp>review</vp> mode now. <b>!review</b> to enable/disable it.\n• <vp>You can switch your language now!</vp> Use <b>!langue</b> to list all the available languages.",

		-- Congratulation messages
		reached_level = "<d>Congratulations! You've reached level <vp>%s</vp>.",
		finished = "<d><o>%s</o> finished the parkour in <vp>%s</vp> seconds, <fc>congratulations!",
		unlocked_power = "<ce><d>%s</d> unlocked the <vp>%s</vp> power.",
		enjoy = "<d>Enjoy your new skills!",

		-- Information messages
		paused_events = "<cep><b>[Warning!]</b> <n>The module has reached it's critical limit and is being paused.",
		resumed_events = "<n2>The module has been resumed.",
		welcome = "<n>Welcome to <t>#parkour</t>!",
		mod_apps = "<j>Parkour moderator applications are now open! Use this link: <rose>%s",
		type_help = "<pt>We recommend you to type <d>!help</d> to see useful information!",
		data_saved = "<vp>Data saved.",
		action_within_minute = "<vp>The action will be applied in a minute.",
		rank_save = "<n2>Type <d>!rank save</d> to apply the changes.",
		module_update = "<r><b>[Warning!]</b> <n>The module will update in <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Mapping system <t>(v%s)</t> loaded.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> has joined the room.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> has left the room.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> has loaded a map.",
		starting_perm_change = "<j>[INFO] <n>Starting perm change...",
		got_map_info = "<j>[INFO] <n>Retrieved map information. Trying to change the perm...",
		perm_changed = "<j>[INFO] <n>Successfully changed the perm of map <ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
		leaderboard_loaded = "<j>The leaderboard has been loaded. Press L to open it.",
		kill_minutes = "<R>Your powers have been disabled for %s minutes.",
		kill_map = "<R>Your powers have been disabled until next map.",
		permbanned = "<r>You have been permanently banned from #parkour.",
		tempbanned = "<r>You have been banned from #parkour for %s minutes.",
		staff_power = "<r>Parkour staff <b>does not</b> have any power outside of #parkour rooms.",
		no_help = "<r>People with a red line above their mouse don't want help!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkour Options</font></p>\n\nUse particles for checkpoints\n\nUse <b>QWERTY</b> keyboard (disable if <b>AZERTY</b>)\n\nUse <b>M</b> hotkey for <b>/mort</b> (disable for <b>DEL</b>)\n\nShow your power cooldowns\n\nShow powers button\n\nShow help button\n\nShow map completion announcements\n\nShow no help symbol",
		unknown = "Unknown",
		powers = "Powers",
		press = "<vp>Press %s",
		click = "<vp>Left click",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Completed maps: %s</B></p></BV>",
		leaderboard = "Leaderboard",
		position = "Position",
		username = "Username",
		community = "Community",
		completed = "Completed maps",
		not_permed = "not permed",
		permed = "permed",
		points = "%d points",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. Last comment by <d>%s</d>. <d>%s</d> comments, <d>%s</d> unread.",
		map_info = "<p align='center'>Map code: <bl>@%s</bl> <g>|</g> Map author: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
		permed_maps = "Permed maps",
		ongoing_votations = "Ongoing votes",
		archived_votations = "Archived votes",
		open = "Open",
		not_archived = "not archived",
		archived = "archived",
		delete = "<r><a href='event:%s'>[delete]</a> ",
		see_restore = "<vp><a href='event:%s'>[see]</a> <a href='event:%s'>[restore]</a> ",
		no_comments = "No comments.",
		deleted_by = "<r>[Message deleted by %s]",
		dearchive = "unarchive", -- to dearchive
		archive = "archive", -- to archive
		deperm = "deperm", -- to deperm
		perm = "perm", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a> <g>|</g> Your vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[load]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comment</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Load custom map</a></p>",
		write_comment = "Write your comment down here",
		write_map = "Write the mapcode down here",
		overall_lb = "Overall",
		weekly_lb = "Weekly",
		new_lang = "<v>[#] <d>Language set to English",

		-- Power names
		balloon = "Balloon",
		masterBalloon = "Master Ballon",
		bubble = "Bubble",
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
		toilet = "Toilet"
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
		user_not_in_room = "<r>El usario <n2>%s</n2> no está en la sala.",
		arg_must_be_id = "<r>El argumento debe ser una id válida.",
		cant_update = "<r>No se pueden actualizar los rangos del jugador. Inténtalo más tarde.",
		cant_edit = "<r>No puedes editar los rangos del jugador <n2>%s</n2>.",
		invalid_rank = "<r>Rango inválido: <n2>%s",
		code_error = "<r>Apareció un error: <bl>%s-%s-%s %s",
		panic_mode = "<r>El módulo entró en modo pánico.",
		public_panic = "<r>Espera un minuto mientras viene un bot y reinicia el módulo.",
		tribe_panic = "<r>Por favor, escribe <n2>/module parkour</n2> para reiniciar el módulo.",
		emergency_mode = "<r>Empezando apagado de emergencia, no se admiten más jugadores. Por favor ve a otra sala #parkour.",
		bot_requested = "<r>El bot ha sido alertado. Debería venir en unos segundos.",
		stream_failure = "<r>Fallo interno del canal de transmisión. No se pueden transmitir datos.",
		maps_not_available = "<r>El submodo 'maps' de #parkour solo está disponible en la sala <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Las versiones del bot (<d>%s</d>) y de lua (<d>%s</d>) no coinciden. No se puede iniciar el sistema.",
		missing_bot = "<r>Falta el bot. Espera un minuto o menciona a @Tocu#0018 en discord: <d>%s</d>",
		invalid_length = "<r>Tu mensaje debe tener entre 10 y 100 caracteres. Tiene <n2>%s</n2>.",
		invalid_map = "<r>Mapa inválido.",
		map_does_not_exist = "<r>El mapa no existe o no puede ser cargado. Inténtalo más tarde.",
		invalid_map_perm = "<r>El mapa no está en P22 ni en P41.",
		invalid_map_perm_specific = "<r>El mapa no está en P%s.",
		cant_use_this_map = "<r>El mapa tiene un pequeño bug y no puede ser usado.",
		invalid_map_p41 = "<r>El mapa está en P41, pero no está en la lista de mapas del módulo.",
		invalid_map_p22 = "<r>El mapa está en P22, pero está en la lista de mapas del módulo.",
		map_already_voting = "<r>El mapa ya tiene una discusión abierta.",
		not_enough_permissions = "<r>No tienes permisos suficientes para hacer eso.",
		already_depermed = "<r>El mapa ya está descategorizado.",
		already_permed = "<r>El mapa ya está categorizado.",
		cant_perm_right_now = "<r>No se puede cambiar la categoría de este mapa ahora mismo. Inténtalo más tarde.",
		already_killed = "<r>El jugador %s ya fue asesinado.",
		leaderboard_not_loaded = "<r>La tabla de clasificación aun no ha sido cargada. Espera un minuto.",

		-- Help window
		help = "Ayuda",
		staff = "Staff",
		rules = "Reglas",
		contribute = "Contribuir",
		changelog = "Novedades",
		help_help = "<p align = 'center'><font size = '14'>¡Bienvenido a <T>#parkour!</T></font></p>\n<font size = '12'><p align='center'><J>Tu objetivo es alcanzar todos los puntos de control hasta que completes el mapa.</J></p>\n\n<N>• Presiona la tecla <O>O</O>, escribe <O>!op</O> o clickea el <O>botón de configuración</O> para abrir el <T>menú de opciones</T>.\n• Presiona la tecla <O>P</O> o clickea el <O>ícono de la mano</O> arriba a la derecha para abrir el <T>menú de poderes</T>.\n• Presiona la tecla <O>L</O> o escribe <O>!lb</O> para abrir el <T>ranking</T>.\n• Presiona la tecla <O>M</O> o <O>Delete</O> como atajo para <T>/mort</T>, podes alternarlas en el menú de <J>Opciones</J>.\n• Para conocer más acerca de nuestro <O>staff</O> y las <O>reglas de parkour</O>, clickea en las pestañas de <T>Staff</T> y <T>Reglas</T>.\n• Click <a href='event:discord'><o>here</o></a> to get the discord invite link and <a href='event:map_submission'><o>here</o></a> to get the map submission topic link.\n• Use <o>up</o> and <o>down</o> arrow keys when you need to scroll.\n\n<p align = 'center'><font size = '13'><T>¡Las contribuciones están abiertas! Para más detalles, ¡clickea en la pestaña <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>NOTA: El staff de Parkour NO ES staff de Transformice y NO TIENEN ningún poder en el juego, sólamente dentro del módulo.</r>\nEl staff de Parkour se asegura de que el módulo corra bien con la menor cantidad de problemas, y siempre están disponibles para ayudar a los jugadores cuando sea necesario.</font></p>\nPuedes escribir <D>!staff</D> en el chat para ver la lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> Son los responsables de mantener el módulo añadiendo nuevas actualizaciones y arreglando bugs.\n\n<font color = '#843DA4'>Lideres de Equipos:</font> Ellos supervisan los equipos de Moderadores y Mappers, asegurándose de que hagan un buen trabajo. También son los responsables de reclutar nuevos miembros al staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> Son los responsables de ejercer las reglas del módulo y sancionar a quienes no las sigan.\n\n<font color = '#25C059'>Mappers:</font> Son los responsables de revisar, añadir y quitar mapas en el módulo para asegurarse de que tengas un buen gameplay.",
		help_rules = "<font size = '13'><B><J>Todas las reglas en los Terminos y Condiciones de Transformice también aplican a #parkour</J></B></font>\n\nSi encuentras algún jugador rompiendo estas reglas, susurra a los moderadores de parkour en el juego. Si no hay moderadores online, es recomendable reportarlo en discord.\nCuando reportes, por favor agrega el servidor, el nombre de la sala, y el nombre del jugador.\n• Ej: en-#parkour10 Blank#3495 trollear\nEvidencia, como fotos, videos y gifs ayudan y son apreciados, pero no son necesarios.\n\n<font size = '11'>• No se permite el uso de <font color = '#ef1111'>hacks, glitches o bugs</font>\n• <font color = '#ef1111'>Farmear con VPN</font> será considerado un <B>abuso</B> y no está permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nCualquier persona rompiendo estas reglas será automáticamente baneado.</B></font></p>\n\n<font size = '12'>Transformice acepta el concepto de trollear. Pero <font color='#cc2222'><B>no está permitido en #parkour.</B></font></font>\n\n<p align = 'center'><J>Trollear es cuando un jugador intencionalmente usa sus poderes para hacer que otros jugadores no completen el mapa.</j></p>\n• Trollear como revancha <B>no es una razón válida</B> para trollear a alguien y aún así seras sancionado.\n• Ayudar a jugadores que no quieren completar el mapa con ayuda y no parar cuando te lo piden también es considerado trollear.\n• <J>Si un jugador no quiere ayuda, por favor ayuda a otros jugadores</J>. Sin embargo, si otro jugador necesita ayuda en el mismo punto, puedes ayudarlos [a los dos].\n\nSi un jugador es atrapado trolleando, será sancionado ya sea en base de tiempo o de rondas. Trollear repetidas veces llevará a sanciones más largas y severas.",
		help_contribute = "<font size='14'>\n<p align='center'>El equipo de administración de parkour ama el codigo abierto porque <t>ayuda a la comunidad</t>. Podés <o>ver</o> y <o>modificar</o> el código de parkour en <o><u><a href='event:github'>GitHub</a></u></o>.\n\nMantener el módulo es <t>estrictamente voluntario</t>, por lo que cualquier ayuda con respecto al <t>código</t>, <t>reportes de bugs</t>, <t>sugerencias</t> y <t>creación de mapas</t> siempre será <u>bienvenida y apreciada</u>.\nPodés <vp>reportar bugs</vp> y <vp>dar sugerencias</vp> en <o><u><a href='event:discord'>Discord</a></u></o> y/o <o><u><a href='event:github'>GitHub</a></u></o>.\nPodés <vp>enviar tus mapas</vp> en nuestro <o><u><a href='event:map_submission'>Hilo del Foro</a></u></o>.\n\nMantener parkour no es caro, pero tampoco es gratis. Realmente apreciaríamos si pudieras ayudarnos <t>donando cualquier cantidad</t> <o><u><a href='event:donate'>aquí</a></u></o>.\n<u>Todas las donaciones serán destinadas a mejorar el módulo.</u></p>",
		help_changelog = "<font size='13'><p align='center'><o>Versión 2.4.0 - 16/06/2020</o></p>\n\n• Se mejoró el sistema de guardado de datos interno. <vp>¡Las salas crashearán menos!</vp>\n• Se mejoró un sistema viejo usado para comunicar parkour con bots. <vp>¡Es mucho más rápido ahora!</vp>\n• Se añadió un canal de <d>records semanales</d> en <a href='event:discord'><u>discord</u></a>. ¡Los mejores 3 jugadores de cada semana aparecerán aquí!\n• Se arreglaron varios bugs internos.\n• Las casas de tribu ahora pueden usar modo <vp>review</vp>. <b>!review</b> para activarlo/desactivarlo.\n• <vp>¡Ahora puedes seleccionar el lenguaje del módulo!</vp> Usa <b>!langue</b> para ver todos los lenguajes disponibles.",

		-- Congratulation messages
		reached_level = "<d>¡Felicitaciones! Alcanzaste el nivel <vp>%s</vp>.",
		finished = "<d><o>%s</o> completó el parkour en <vp>%s</vp> segundos, <fc>¡felicitaciones!",
		unlocked_power = "<ce><d>%s</d> desbloqueó el poder <vp>%s<ce>.",
		enjoy = "<d>¡Disfruta tus nuevas habilidades!",

		-- Information messages
		paused_events = "<cep><b>[¡Advertencia!]</b> <n>El módulo está entrando en estado crítico y está siendo pausado.",
		resumed_events = "<n2>El módulo ha sido reanudado.",
		welcome = "<n>¡Bienvenido a <t>#parkour</t>!",
		mod_apps = "<j>¡Las aplicaciones para moderador de parkour están abiertas! Usa este link: <rose>%s",
		type_help = "<pt>¡Te recomendamos que escribas <d>!help</d> para ver información util!",
		data_saved = "<vp>Datos guardados.",
		action_within_minute = "<vp>La acción se aplicará dentro de un minuto.",
		rank_save = "<n2>Escribe <d>!rank save</d> para aplicar los cambios.",
		module_update = "<r><b>[¡Advertencia!]</b> <n>El módulo se actualizará en <d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Sistema de mapas <t>(v%s)</t> cargado.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> entró a la sala.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> salió de la sala.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> cargó este mapa.",
		starting_perm_change = "<j>[INFO] <n>Empezando cambio de categoría...",
		got_map_info = "<j>[INFO] <n>Se obtuvo toda la información del mapa. Intentando cambiar la categoría...",
		perm_changed = "<j>[INFO] <n>Se cambió la categoría del mapa <ch>@%s</ch> desde <r>P%s</r> hacia <t>P%s</t> exitosamente.",
		leaderboard_loaded = "<j>La tabla de clasificación ha sido cargada. Presiona L para abrirla.",
		kill_minutes = "<R>Tus poderes fueron desactivados por %s minutos.",
		kill_map = "<R>Tus poderes fueron desactivados hasta el siguiente mapa.",
		permbanned = "<r>Has sido baneado permanentemente de #parkour.",
		tempbanned = "<r>Has sido baneado de #parkour por %s minutos.",
		staff_power = "<r>El staff de Parkour <b>no tiene</b> ningún poder afuera de las salas de #parkour.",
		no_help = "<r>¡Las personas con una linea roja sobre su ratón no quieren ayuda!",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Opciones de Parkour</font></p>\n\nUsar partículas para los checkpoints\n\nUsar teclado <b>QWERTY</b> (desactivar si usas <b>AZERTY</b>)\n\nUsar la tecla <b>M</b> como atajo para <b>/mort</b> (desactivar si usas <b>DEL</b>)\n\nMostrar tiempos de espera de tus poderes\n\nMostrar el botón de poderes\n\nMostrar el botón de ayuda\n\nMostrar mensajes al completar un mapa\n\nMostrar indicador para no recibir ayuda",
		unknown = "Desconocido",
		powers = "Poderes",
		press = "<vp>Presiona %s",
		click = "<vp>Haz clic",
		ranking_pos = "Rank #%s",
		completed_maps = "<p align='center'><BV><B>Mapas completados: %s</B></p></BV>",
		leaderboard = "Tabla de clasificación",
		position = "Posición",
		username = "Jugador",
		community = "Comunidad",
		completed = "Mapas completados",
		not_permed = "sin categoría",
		permed = "categorizado",
		points = "%d puntos",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Empezado por <d>%s</d>. Último comentaro por <d>%s</d>. <d>%s</d> comentarios, <d>%s</d> sin leer.",
		map_info = "<p align='center'>Código: <bl>@%s</bl> <g>|</g> Autor: <j>%s</j> <g>|</g> Estado: <vp>%s, %s</vp> <g>|</g> Puntos: <vp>%s</vp>",
		permed_maps = "Mapas categorizados",
		ongoing_votations = "Discusiones abiertas",
		archived_votations = "Discusiones archivadas",
		open = "Abrir",
		not_archived = "no archivado",
		archived = "archivado",
		delete = "<r><a href='event:%s'>[eliminar]</a> ",
		see_restore = "<vp><a href='event:%s'>[ver]</a> <a href='event:%s'>[restaurar]</a> ",
		no_comments = "Sin comentarios.",
		deleted_by = "<r>[Mensaje eliminado por %s]",
		dearchive = "desarchivar", -- to dearchive
		archive = "archivar", -- to archive
		deperm = "descategorizar", -- to deperm
		perm = "categorizar", -- to perm
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a> <g>|</g> Tu voto: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[cargar]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Comentar</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Cargar mapa</a></p>",
		write_comment = "Escribe tu comentario aquí abajo",
		write_map = "Escribe el código de mapa aquí abajo",
		overall_lb = "General",
		weekly_lb = "Semanal",
		new_lang = "<v>[#] <d>Lenguaje cambiado a Español",

		-- Power names
		balloon = "Globo",
		masterBalloon = "Globo Maestro",
		bubble = "Burbuja",
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
		toilet = "Inodoro"
	}
	--[[ End of file translations/parkour/es.lua ]]--
	--[[ End of directory translations/parkour ]]--
	--[[ File modes/parkour/timers.lua ]]--
	local timers = {}
	local aliveTimers = false

	local function addNewTimer(delay, fnc, arg1, arg2, arg3, arg4)
		aliveTimers = true
		local list = timers[delay]
		if list then
			list._count = list._count + 1
			list[list._count] = {os.time() + delay, fnc, arg1, arg2, arg3, arg4}
		else
			timers[delay] = {
				_count = 1,
				_pointer = 1,
				[1] = {os.time() + delay, fnc, arg1, arg2, arg3, arg4}
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
						timer[2](timer[3], timer[4], timer[5], timer[6])
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
					timer[2](timer[3], timer[4], timer[5], timer[6])
				end

				if list._count > count then
					for index = count + 1, list._count do
						timer = list[index]
						timer[2](timer[3], timer[4], timer[5], timer[6])
					end
				end
			end
			timers = {}
			aliveTimers = false
		end
	end)
	--[[ End of file modes/parkour/timers.lua ]]--
	--[[ File modes/parkour/communication.lua ]]--
	if room.name == "*#parkour4bots" then
		recv_channel, send_channel = "Holybot#0000", "Parkour#8558"
	else
		recv_channel, send_channel = "Parkour#8558", "Holybot#0000"
	end

	function sendPacket(packet_id, packet) end
	if not is_tribe then
		--[[
			Packets from 4bots:
				0 - join request
				1 - game update
				2 - !kill
				3 - !ban
				4 - !announce
				5 - !cannounce
				6 - pw request

			Packets to 4bots:
				0 - room crash
				1 - suspect
				2 - ban field set to playerdata
				3 - farm/hack suspect
				4 - weekly lb reset
				5 - pw info
		]]

		local last_id = os.time() - 10000
		local next_channel_load = 0

		local common_decoder = {
			["&0"] = "&",
			["&1"] = ";",
			["&2"] = ","
		}
		local common_encoder = {
			["&"] = "&0",
			[";"] = "&1",
			[","] = "&2"
		}

		function sendPacket(packet_id, packet)
			if not add_packet_data then
				add_packet_data = ""
			end

			add_packet_data = add_packet_data .. ";" .. packet_id .. "," .. string.gsub(packet, "[&;,]", common_encoder)
		end

		packet_handler = function(player, data)
			if player == send_channel then
				if not buffer then return end
				local send_id
				send_id, data = string.match(data, "^(%d+)(.*)$")
				if not send_id then
					send_id, data = 0, ""
				else
					send_id = tonumber(send_id)
				end

				local now = os.time()
				if now < send_id + 10000 then
					buffer = data .. buffer
				end

				system.savePlayerData(player, now .. buffer)
				buffer = nil
				if eventPacketSent then
					eventPacketSent()
				end
			elseif player == recv_channel then
				if data == "" then
					data = "0"
				end

				local send_id
				send_id, data = string.match(data, "^(%d+)(.*)$")
				send_id = tonumber(send_id)
				if send_id <= last_id then return end
				last_id = send_id

				if eventPacketReceived then
					for packet_id, packet in string.gmatch(data, ";(%d+),([^;]*)") do
						packet = string.gsub(packet, "&[012]", common_decoder)

						eventPacketReceived(tonumber(packet_id), packet)
					end
				end
			end
		end
		onEvent("PlayerDataLoaded", packet_handler)

		onEvent("Loop", function()
			local now = os.time()
			if now >= next_channel_load then
				next_channel_load = now + 10000

				if eventChannelLoad then
					eventChannelLoad()
				end
				if add_packet_data then
					buffer = add_packet_data
					add_packet_data = nil
					system.loadPlayerData(send_channel)
				end
				system.loadPlayerData(recv_channel)
			end
		end)
	end
	--[[ End of file modes/parkour/communication.lua ]]--
	--[[ File modes/parkour/maps.lua ]]--
	local first_data_load = true
	local repeated = {_count = 0, low = {_count = 0}}
	local maps = {_count = 1, [1] = 7171137, low = {_count = 1, [1] = 7171137}}
	local is_invalid = false
	local count_stats = true
	local map_change_cd = 0
	local levels

	local function newMap()
		count_stats = true
		map_change_cd = os.time() + 20000

		local rep, _maps
		-- Maps with low priority get played with a half the probabilities of normal maps.
		if math.random(1000 * (maps._count * 2 / maps.low._count + 0.5)) <= 1000 then
			rep, _maps = repeated.low, maps.low
		else
			rep, _maps = repeated, maps
		end

		if rep._count == _maps._count then
			if rep == repeated then
				repeated = {_count = 0, low = repeated.low}
				rep = repeated
			else
				repeated.low = {_count = 0}
				rep = repeated.low
			end
		end

		local map
		repeat
			map = _maps[math.random(_maps._count)]
		until map and not rep[map]
		rep[map] = true
		rep._count = rep._count + 1

		tfm.exec.newGame(map)
	end

	local function invalidMap(arg)
		levels = nil
		is_invalid = os.time() + 3000
		translatedChatMessage("corrupt_map")
		translatedChatMessage("corrupt_map_" .. arg)
	end

	local function getTagProperties(tag)
		local properties = {}
		for name, value in string.gmatch(tag, '(%S+)%s*=%s*"([^"]+)"') do
			properties[name] = tonumber(value) or value
		end
		return properties
	end

	onEvent("GameDataLoaded", function(data)
		if data.maps then
			if #data.maps > 0 then
				maps._count = #data.maps
				for index = 1, maps._count do
					maps[index] = data.maps[index]
				end
			else
				maps = {_count = 1, [1] = 7171137, low = maps.low}
			end
			if first_data_load then
				newMap()
				first_data_load = false
			end
		elseif data.lowmaps then
			if #data.lowmaps > 0 then
				maps.low._count = #data.lowmaps
				for index = 1, maps.low._count do
					maps.low[index] = data.lowmaps[index]
				end
			else
				maps.low = {_count = 1, [1] = 7171137}
			end
		end
	end)

	onEvent("NewGame", function()
		levels = {}
		if not room.xmlMapInfo then return invalidMap("vanilla") end
		local xml = room.xmlMapInfo.xml

		local count = 1
		local mouse_start = string.match(xml, '<DS%s+(.-)%s+/>')

		if not mouse_start then
			return invalidMap("mouse_start")
		end

		local properties = getTagProperties(mouse_start)
		levels[count] = {x = properties.X, y = properties.Y}

		for tag in string.gmatch(xml, '<O%s+(.-)%s+/>') do
			properties = getTagProperties(tag)

			if properties.C == 22 then
				count = count + 1
				levels[count] = {x = properties.X, y = properties.Y}
			end
		end

		local chair = false
		for tag in string.gmatch(xml, '<P%s+(.-)%s+/>') do
			properties = getTagProperties(tag)

			if properties.T == 19 and properties.C == "329cd2" then
				chair = true
				count = count + 1
				levels[count] = {x = properties.X, y = properties.Y - 25}
				break
			end
		end

		if not chair or count < 3 then -- start, at least one nail and end chair
			return invalidMap(not chair and "needing_chair" or "missing_checkpoints")
		end

		tfm.exec.setGameTime(1080)
	end)

	onEvent("Loop", function(elapsed, remaining)
		if (is_invalid and os.time() >= is_invalid) or remaining < 500 then
			newMap()
			is_invalid = false
		end
	end)

	onEvent("GameStart", function()
		tfm.exec.disableAutoNewGame(true)
		tfm.exec.disableAutoShaman(true)
		tfm.exec.disableAfkDeath(true)
		tfm.exec.disableAutoTimeLeft(true)
		tfm.exec.setAutoMapFlipMode(false)
	end)
	--[[ End of file modes/parkour/maps.lua ]]--
	--[[ File modes/parkour/join-system.lua ]]--
	local room_max_players = 12

	onEvent("PacketReceived", function(packet_id, packet)
		if packet_id == 0 then
			if packet == room.name then
				tfm.exec.setRoomMaxPlayers(room_max_players + 10)
				addNewTimer(15000, tfm.exec.setRoomMaxPlayers, room_max_players)
			end
		end
	end)
	--[[ End of file modes/parkour/join-system.lua ]]--
	--[[ File modes/parkour/game.lua ]]--
	local checkpoint_range = 15 ^ 2 -- radius of 15px
	local min_save = 4

	local check_position = 6
	local player_count = 0
	local victory_count = 0
	local map_start = 0
	local less_time = false
	local victory = {_last_level = {}}
	local bans = {[0] = true} -- souris banned
	local in_room = {}
	local online = {}
	local players_level = {}
	local generated_at = {}
	local spec_mode = {}
	local ck = {
		particles = {},
		images = {}
	}
	local players_file
	local review_mode = false

	local function generatePlayer(player, when)
		players_level[player] = 1
		generated_at[player] = when
	end

	local function addCheckpointImage(player, x, y)
		if not x then
			local level = levels[ players_level[player] + 1 ]
			if not level then return end
			x, y = level.x, level.y
		end

		ck.images[player] = tfm.exec.addImage("150da4a0616.png", "_51", x - 20, y - 30, player)
	end

	onEvent("NewPlayer", function(player)
		spec_mode[player] = nil
		in_room[player] = true
		player_count = player_count + 1

		if levels then
			tfm.exec.respawnPlayer(player)

			if victory[player] then
				victory_count = victory_count + 1
			end

			if players_level[player] then
				local level = levels[ players_level[player] ]
				if level then
					tfm.exec.movePlayer(player, level.x, level.y)
				end
			else
				generatePlayer(player, os.time())
			end

			tfm.exec.setPlayerScore(player, players_level[player], false)
		end
	end)

	onEvent("PlayerLeft", function(player)
		players_file[player] = nil
		in_room[player] = nil

		if spec_mode[player] then return end

		player_count = player_count - 1

		if victory[player] then
			victory_count = victory_count - 1
		elseif player_count == victory_count and not less_time then
			tfm.exec.setGameTime(20)
			less_time = true
		end
	end)

	onEvent("PlayerDied", function(player)
		if not room.playerList[player] then return end
		if bans[room.playerList[player].id] then return end
		if (not levels) or (not players_level[player]) then return end

		local level = levels[ players_level[player] ]

		if not spec_mode[player] then
			tfm.exec.respawnPlayer(player)
			tfm.exec.movePlayer(player, level.x, level.y)
		end
	end)

	onEvent("PlayerWon", function(player)
		victory_count = victory_count + 1
		victory[player] = true
		victory._last_level[player] = false

		if victory_count == player_count then
			tfm.exec.setGameTime(20)
			less_time = true
		end
	end)

	onEvent("NewGame", function()
		check_position = 6
		victory_count = 0
		less_time = false
		victory = {_last_level = {}}
		players_level = {}
		generated_at = {}
		map_start = os.time()

		local start_x, start_y
		if levels then
			start_x, start_y = levels[2].x, levels[2].y

			for player, particles in next, ck.particles do
				if not particles then
					if ck.images[player] then
						tfm.exec.removeImage(ck.images[player])
					end
					addCheckpointImage(player, start_x, start_y)
				end
			end
		end

		for player in next, in_room do
			players_level[player] = 1
			tfm.exec.setPlayerScore(player, 1, false)
		end

		for player in next, spec_mode do
			tfm.exec.killPlayer(player)
		end
	end)

	onEvent("Loop", function()
		if not levels then return end

		if check_position > 0 then
			check_position = check_position - 1
		else
			for player, to_give in next, victory._last_level do
				if not victory[player] and to_give then
					eventPlayerWon(player)
				end
			end

			local last_level = #levels
			local level_id, next_level, player
			local particle = 29--math.random(21, 23)
			local x, y = math.random(-10, 10), math.random(-10, 10)

			for name in next, in_room do
				player = room.playerList[name]
				if spec_mode[name] then
					tfm.exec.killPlayer(name)
				else
					level_id = players_level[name] + 1
					next_level = levels[level_id]

					if next_level then
						if ((player.x - next_level.x) ^ 2 + (player.y - next_level.y) ^ 2) <= checkpoint_range then
							players_level[name] = level_id
							tfm.exec.setPlayerScore(name, level_id, false)
							if ck.particles[name] == false then
								tfm.exec.removeImage(ck.images[name])
							end

							if level_id == last_level then
								victory._last_level[name] = true
								tfm.exec.giveCheese(name)
								tfm.exec.playerVictory(name)
								tfm.exec.respawnPlayer(name)
								tfm.exec.movePlayer(name, next_level.x, next_level.y)
							else
								translatedChatMessage("reached_level", name, level_id)

								if ck.particles[name] == false then
									addCheckpointImage(name, levels[level_id + 1].x, levels[level_id + 1].y)
								end
							end
						elseif ck.particles[name] then
							tfm.exec.displayParticle(
								particle,
								next_level.x + x,
								next_level.y + y,
								0, 0, 0, 0,
								name
							)
						end
					end
				end
			end
		end
	end)

	onEvent("PlayerDataParsed", function(player, data)
		ck.particles[player] = data.parkour.ckpart == 1

		if levels and not ck.particles[player] then
			local next_level = levels[players_level[player] + 1]
			if next_level then
				if ck.images[player] then
					tfm.exec.removeImage(ck.images[player])
				end
				addCheckpointImage(player, next_level.x, next_level.y)
			end
		end
	end)

	onEvent("GameStart", function()
		tfm.exec.disablePhysicalConsumables(true)
		tfm.exec.setRoomMaxPlayers(room_max_players)
		tfm.exec.setRoomPassword("")
		tfm.exec.disableAutoScore(true)
	end)
	--[[ End of file modes/parkour/game.lua ]]--
	--[[ File modes/parkour/files.lua ]]--
	local next_file_load = os.time() + math.random(60500, 90500)
	local player_ranks
	local no_powers
	local unbind
	local bindNecessary
	local killing = {}
	local to_save = {}
	local files = {
		--[[
			File values:

			- maps        (1)
			- ranks       (1)
			- chats       (1)

			- ranking     (2)
			- weekranking (2)

			- lowmaps     (3)
			- banned      (3)
		]]

		[1] = 20, -- maps, ranks, chats
		[2] = 21, -- ranking, weekranking
		[3] = 22, -- lowmaps, banned
	}
	local total_files = 3
	local file_index = 1
	local fetching_player_room = {}
	local file_id = files[file_index]
	local timed_maps = {
		week = {},
		hour = {}
	}
	players_file = {}

	local data_migrations = {
		["0.0"] = function(player, data)
			data.parkour = data.modules.parkour
			data.drawbattle = data.modules.drawbattle

			data.modules = nil

			data.parkour.v = "0.6" -- version
			data.parkour.c = data.parkour.cm -- completed maps
			data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
			data.parkour.mort = 1 -- /mort hotkey
			data.parkour.pcool = 1 -- power cooldowns
			data.parkour.pbut = 1 -- powers button
			data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
			data.parkour.killed = 0
			data.parkour.hbut = 1 -- help button
			data.parkour.congrats = 1 -- contratulations message
			data.parkour.troll = 0
			data.parkour.week_c = 0 -- completed maps this week
			data.parkour.week_r = timed_maps.week.last_reset -- last week reset
			data.parkour.hour_c = 0 -- completed maps this hour
			data.parkour.hour_r = os.time() + 60 * 60 * 1000 -- next hour reset
			data.parkour.help = 0 -- doesn't want help?

			data.parkour.cm = nil
		end,
		["0.1"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.ckpart = 1
			data.parkour.mort = 1
			data.parkour.pcool = 1
			data.parkour.pbut = 1
			data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
			data.parkour.killed = 0
			data.parkour.congrats = 1
			data.parkour.troll = 0
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
			data.parkour.hour_c = 0
			data.parkour.hour_r = os.time() + 60 * 60 * 1000
			data.parkour.help = 0
		end,
		["0.2"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.killed = 0
			data.parkour.hbut = 1
			data.parkour.congrats = 1
			data.parkour.troll = 0
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
			data.parkour.hour_c = 0
			data.parkour.hour_r = os.time() + 60 * 60 * 1000
			data.parkour.help = 0
		end,
		["0.3"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.hbut = 1
			data.parkour.congrats = 1
			data.parkour.troll = 0
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
			data.parkour.hour_c = 0
			data.parkour.hour_r = os.time() + 60 * 60 * 1000
			data.parkour.help = 0
		end,
		["0.4"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.troll = 0
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
			data.parkour.hour_c = 0
			data.parkour.hour_r = os.time() + 60 * 60 * 1000
			data.parkour.help = 0
		end,
		["0.5"] = function(player, data)
			data.parkour.v = "0.6"
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
			data.parkour.hour_c = 0
			data.parkour.hour_r = os.time() + 60 * 60 * 1000
			data.parkour.help = 0
		end
	}

	local function savePlayerData(player)
		if not players_file[player] then return end

		if not to_save[player] then
			to_save[player] = true
			system.loadPlayerData(player)
		end
	end

	onEvent("PlayerDataLoaded", function(player, data)
		if player == send_channel or player == recv_channel then return end
		if in_room[player] then return end
		online[player] = true

		if data == "" then
			data = {}
		else
			local done
			done, data = pcall(json.decode, data)

			if not done then
				data = {}
			end
		end

		local fetch = fetching_player_room[player]
		if fetch then
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. (data.room or "unknown"), fetch[1])
			fetching_player_room[player] = nil
		end

		if killing[player] and data.parkour then
			data.parkour.killed = os.time() + killing[player] * 60 * 1000
			system.savePlayerData(player, json.encode(data))
		end
	end)

	onEvent("PlayerDataLoaded", function(player, data)
		if player == send_channel or player == recv_channel then return end
		if not in_room[player] then return end
		online[player] = true

		local corrupt
		if data == "" then
			data = {}
		else
			local done
			done, data = pcall(json.decode, data)

			if not done then
				data = {}
				translatedChatMessage("corrupt_data", player)
				corrupt = true
			end
		end

		if not data.parkour then
			if data.modules then
				data.parkour = {v = "0.0"}
			else
				data.parkour = {
					v = "0.1", -- version
					c = 0 -- completed maps
				}
			end
		end

		local migration = data_migrations[data.parkour.v or "0.0"]
		while migration do
			corrupt = true -- just so this process is made only once
			migration(player, data)
			migration = data_migrations[data.parkour.v]
		end

		local fetch = fetching_player_room[player]
		if fetch then
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. room.name, fetch[1])
			fetching_player_room[player] = nil
		end

		if players_file[player] then
			local old = players_file[player]
			if old.parkour.killed < data.parkour.killed then
				old.parkour.killed = data.parkour.killed
				translatedChatMessage("kill_minutes", player, math.ceil((data.parkour.killed - os.time()) / 1000 / 60))
				if os.time() < data.parkour.killed then
					no_powers[player] = true
					unbind(player)
				else
					no_powers[player] = false
					if victory[player] then
						bindNecessary(player)
					end
				end
			end

			if to_save[player] then
				to_save[player] = false
				system.savePlayerData(player, json.encode(old))
			end
			return
		end

		players_file[player] = data
		players_file[player].room = room.name

		system.savePlayerData(
			player,
			json.encode(players_file[player])
		)

		eventPlayerDataParsed(player, data)
	end)

	onEvent("SavingFile", function(id, data)
		system.saveFile(filemanagers[id]:dump(data), id)
	end)

	onEvent("FileLoaded", function(id, data)
		data = filemanagers[id]:load(data)
		eventGameDataLoaded(data)
		if data.ranking or data.weekranking then -- the only file that can get written by rooms
			eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
		end
	end)

	onEvent("Loop", function()
		local now = os.time()
		if now >= next_file_load then
			system.loadFile(file_id)
			next_file_load = now + math.random(60500, 63000)
			file_index = file_index % total_files + 1
			file_id = files[file_index]
		end

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
	end)

	onEvent("GameStart", function()
		system.loadFile(file_id)
		local ts = os.time()

		next_file_load = ts + math.random(60500, 90500)
		file_index = file_index % total_files + 1
		file_id = files[file_index]

		local now = os.date("*t", ts / 1000) -- os.date is weird in tfm, *t accepts seconds, %d/%m/%Y accepts ms
		now.wday = now.wday - 1
		if now.wday == 0 then
			now.wday = 7
		end
		timed_maps.week.last_reset = os.date("%d/%m/%Y", ts - (now.wday - 1) * 24 * 60 * 60 * 1000)
		timed_maps.week.next_reset = os.date("%d/%m/%Y", ts + (8 - now.wday) * 24 * 60 * 60 * 1000)
	end)

	onEvent("NewPlayer", function(player)
		players_file[player] = nil -- don't cache lol
		system.loadPlayerData(player)
	end)

	onEvent("PlayerDataParsed", function(player, data)
		local now = os.time()
		if data.parkour.hour_r <= now then
			data.parkour.hour_c = 0
			data.parkour.hour_r = now + 60 * 60 * 1000
		end

		if data.parkour.week_r ~= timed_maps.week.last_reset then
			data.parkour.week_c = 0
			data.parkour.week_r = timed_maps.week.last_reset
		end
	end)
	--[[ End of file modes/parkour/files.lua ]]--
	--[[ File modes/parkour/ranks.lua ]]--
	local band = (bit or bit32).band
	local bxor = (bit or bit32).bxor

	local ranks = {
		admin = {_count = 0},
		manager = {_count = 0},
		mod = {_count = 0},
		mapper = {_count = 0},
		trainee = {_count = 0}
	}
	local ranks_id = {
		admin = 2 ^ 0,
		manager = 2 ^ 1,
		mod = 2 ^ 2,
		mapper = 2 ^ 3,
		trainee = 2 ^ 4
	}
	local ranks_permissions = {
		admin = {
			show_update = true,
			announce = true
		},
		manager = {
			set_player_rank = true,
			perm_map = true
		},
		mod = {
			ban = true,
			unban = true,
			delete_comments = true,
			spectate = true,
			get_player_room = true,
			change_map = true,
			kill = true,
			overkill = true
		},
		mapper = {
			vote_map = true,
			change_map = true,
			enable_review = true
		},
		trainee = {
			kill = true,
			spectate = true,
			get_player_room = true
		}
	}
	player_ranks = {}
	local perms = {}
	local ranks_order = {"admin", "manager", "mod", "mapper", "trainee"}

	for rank, perms in next, ranks_permissions do
		if rank ~= "admin" then
			for perm_name, allowed in next, perms do
				ranks_permissions.admin[perm_name] = allowed
			end
		end
	end

	onEvent("GameDataLoaded", function(data)
		if data.ranks then
			ranks, perms, player_ranks = {
				admin = {_count = 0},
				manager = {_count = 0},
				mod = {_count = 0},
				mapper = {_count = 0},
				trainee = {_count = 0}
			}, {}, {}
			local player_perms, _player_ranks
			for player, rank in next, data.ranks do
				player_perms, _player_ranks = {}, {}
				for name, id in next, ranks_id do
					if band(rank, id) > 0 then
						_player_ranks[name] = true
						ranks[name][player] = true
						ranks[name]._count = ranks[name]._count + 1
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
	local is_tribe = string.sub(room.name, 2, 2) == "\3"

	no_powers = {}
	local facing = {}
	local cooldowns = {}
	local max_leaderboard_rows
	local leaderboard
	local obj_whitelist = {_count = 0, _index = 1}

	local function addShamanObject(id, x, y, ...)
		obj_whitelist._count = obj_whitelist._count + 1
		obj_whitelist[obj_whitelist._count] = {id, x, y}
		return tfm.exec.addShamanObject(id, x, y, ...)
	end

	local function checkCooldown(player, name, long, img, x, y, show)
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
	end

	local toilet
	toilet = {
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

			addNewTimer(5000, toilet.despawn, id, obj)
		end,
		despawn = function(id, obj)
			tfm.exec.removePhysicObject(id)
			tfm.exec.removeObject(obj)
		end
	}

	local powers = {
		{
			name = 'fly',
			maps = 5,
			cooldown = nil,
			image = {url = '16896d06614.png', x = 47, y = 33},

			qwerty = {key = "SPACE", keyCode = 32},

			fnc = function(player, key, down, x, y)
				tfm.exec.movePlayer(player, 0, 0, true, 0, -50, false)
			end
		},
		{
			name = 'speed',
			maps = 10,
			cooldown = 1000,
			cooldown_icon = {img = "17127e682ff.png", x = 30, y = 373},
			image = {url = '16896ed356d.png', x = 35, y = 25},

			qwerty = {key = "SHIFT", keyCode = 16},

			fnc = function(player, key, down, x, y)
				tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
			end
		},
		{
			name = 'snowball',
			maps = 15,
			cooldown = 5000,
			cooldown_icon = {img = "17127e6674c.png", x = 8, y = 374},
			image = {url = '16896d045f9.png', x = 50, y = 40},

			qwerty = {key = "E", keyCode = 69},

			fnc = function(player, key, down, x, y)
				local right = facing[player]
				despawnableObject(5000, 34, x + (right and 20 or -20), y, 0, right and 10 or -10)
			end
		},
		{
			name = 'balloon',
			maps = 20,
			cooldown = 10000,
			cooldown_icon = {img = "17127e5b2d5.png", x = 52, y = 372},
			image = {url = '16896d0252b.png', x = 35, y = 20},

			qwerty = {key = "Q", keyCode = 81},
			azerty = {key = "A", keyCode = 65},

			fnc = function(player, key, down, x, y)
				if players_file[player].parkour.c < 200 then
					despawnableObject(2000, 28, x, y + 10)
				end
			end
		},
		{
			name = 'teleport',
			maps = 35,
			cooldown = 10000,
			cooldown_icon = {img = "17127e73965.png", x = 74, y = 373},
			image = {url = '16896d00614.png', x = 30, y = 20},

			click = true,

			fnc = tfm.exec.movePlayer
		},
		{
			name = 'smallbox',
			maps = 50,
			cooldown = 10000,
			cooldown_icon = {img ="17127e77dbe.jpg", x = 98, y = 373},
			image = {url = '1689fd4ffc4.jpg', x = 50, y = 40},

			qwerty = {key = "Z", keyCode = 90},
			azerty = {key = "W", keyCode = 87},

			fnc = function(player, key, down, x, y)
				despawnableObject(3000, 1, x, y + 10)
			end
		},
		{
			name = 'cloud',
			maps = 100,
			cooldown = 10000,
			cooldown_icon = {img= "17127e5f927.png", x = 121, y = 377},
			image = {url = '1689fe8325e.png', x = 15, y = 25},

			qwerty = {key = "X", keyCode = 88},

			fnc = function(player, key, down, x, y)
				despawnableObject(2000, 57, x, y + 10)
			end
		},
		{
			name = 'masterBalloon',
			maps = 200,
			cooldown = 10000,
			cooldown_icon = {img = "17127e62809.png", x = 142, y = 376},
			image = {url = '168ab7be931.png', x = 15, y = 20},

			qwerty = {key = "Q", keyCode = 81},
			azerty = {key = "A", keyCode = 65},

			fnc = function(player, key, down, x, y)
				if players_file[player].parkour.c < 400 then
					despawnableObject(3000, 2804, x, y + 10)
				end
			end
		},
		{
			name = 'bubble',
			maps = 400,
			cooldown = 10000,
			cooldown_icon = {img= "17127e5ca47.png", x = 161, y = 373},
			image = {url = '168ab822a4b.png', x = 30, y = 20},

			qwerty = {key = "Q", keyCode = 81},
			azerty = {key = "A", keyCode = 65},

			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 59, x, y + 12)
			end
		},
		{
			name = 'rip',
			maps = 700,
			cooldown = 10000,
			cooldown_icon = { img = "17127e69ea4.png", x = 181, y = 373},
			image = {url = '169495313ad.png', x = 38, y = 23},

			qwerty = {key = "V", keyCode = 86},

			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 90, x, y + 10)
			end
		},
		{
			name = 'choco',
			maps = 1500,
			cooldown = 25000,
			cooldown_icon = {img= "17127fc6b27.png", x = 201, y = 374},
			image = {url = '16d2ce46c57.png', x = 20, y = 56},

			qwerty = {key = "CTRL", keyCode = 17},

			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, 90)
			end
		},
		{
			name = 'bigBox',
			maps = 2500,
			cooldown = 25000,
			cooldown_icon = {img= "17127e77dbe.jpg", x = 221, y = 374},
			image = {url = '1689fd4ffc4.jpg', x = 50, y = 40},

			qwerty = {key = "B", keyCode = 66},

			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 2, x, y + 10, 0)
			end
		},
		{
			name = 'trampoline',
			maps = 4000,
			cooldown = 25000,
			cooldown_icon = {img= "171cd9f5188.png", x = 241, y = 374},
			image = {url = '171cd98ed22.png', x = 20, y = 56},

			qwerty = {key = "N", keyCode = 78},

			fnc = function(player, key, down, x, y)
				despawnableObject(4000, 701, x, y + 10, 0)
			end
		},
		{
			name = 'toilet',
			ranking = 70,
			cooldown = 30000,
			cooldown_icon = {img= "171cd9e02d3.png", x = 261, y = 374},
			image = {url = "171cd3eddf1.png", x = 50, y = 40},

			qwerty = {key = "C", keyCode = 67},

			fnc = function(player, key, down, x, y)
				local id = room.playerList[player].id
				local img = tfm.exec.addImage("171cd3eddf1.png", "_51", x - 20, y - 20)
				tfm.exec.addPhysicObject(id, x, y + 13, {
					type = 14,
					friction = 0.3,
					width = 30
				})

				addNewTimer(5000, toilet.water, img, id, x, y)
			end
		},
	}

	local keyPowers, clickPowers = {
		qwerty = {},
		azerty = {}
	}, {}
	local player_keys = {}

	function bindNecessary(player)
		local player_pos = leaderboard[player] or max_leaderboard_rows + 1
		local maps = players_file[player].parkour.c
		local power, cond
		for key, powers in next, player_keys[player] do
			if powers._count then
				for index = 1, powers._count do
					power = powers[index]
					if power.ranking then
						cond = player_pos <= power.ranking
					else
						cond = maps >= power.maps
					end
					if cond then
						system.bindKeyboard(player, key, true, true)
					end
				end
			end
		end

		for index = 1, #clickPowers do
			power = clickPowers[index]
			if power.ranking then
				cond = player_pos <= power.ranking
			else
				cond = maps >= power.maps
			end
			if cond then
				system.bindMouse(player, true)
				break
			end
		end
	end

	function unbind(player)
		local keys = player_keys[player]
		if not keys then return end

		for key, power in next, keys do
			if type(key) == "number" then
				system.bindKeyboard(player, key, true, false)
			end
		end

		system.bindMouse(player, false)
	end

	onEvent("Keyboard", function(player, key, down, x, y)
		if not room.playerList[player] or bans[ room.playerList[player].id ] then return end

		if key == 0 then
			facing[player] = false
			return
		elseif key == 2 then
			facing[player] = true
			return
		end

		if not players_file[player] or not player_keys[player] or not victory[player] then return end
		local powers = player_keys[player][key]
		if not powers then return end

		local player_pos = leaderboard[player] or max_leaderboard_rows + 1
		local file = players_file[player].parkour
		local maps, show_cooldowns = file.c, file.pcool == 1
		local power, cond
		for index = powers._count, 1, -1 do
			power = powers[index]
			if power.ranking then
				cond = player_pos <= power.ranking
			else
				cond = maps >= power.maps
			end
			if cond then
				if (not power.cooldown) or checkCooldown(player, power.name, power.cooldown, power.cooldown_icon.img, power.cooldown_icon.x, power.cooldown_icon.y, show_cooldowns) then
					power.fnc(player, key, down, x, y)
				end
				break
			end
		end
	end)

	onEvent("Mouse", function(player, x, y)
		if not room.playerList[player] or bans[ room.playerList[player].id ] then return end

		if not players_file[player] or not victory[player] then return end

		local player_pos = leaderboard[player] or max_leaderboard_rows + 1
		local file = players_file[player].parkour
		local maps, show_cooldowns = file.c, file.pcool == 1
		local power, cond
		for index = 1, #clickPowers do
			power = clickPowers[index]
			if power.ranking then
				cond = player_pos <= power.ranking
			else
				cond = maps >= power.maps
			end
			if cond then
				if (not power.cooldown) or checkCooldown(player, power.name, power.cooldown, power.cooldown_icon.img, power.cooldown_icon.x, power.cooldown_icon.y, show_cooldowns) then
					power.fnc(player, x, y)
				end
			end
		end
	end)

	onEvent("NewPlayer", function(player)
		system.bindKeyboard(player, 0, true, true)
		system.bindKeyboard(player, 2, true, true)
	end)

	onEvent("PlayerDataParsed", function(player, data)
		local keyboard = data.parkour.keyboard == 1 and "qwerty" or "azerty"
		player_keys[player] = keyPowers[keyboard]

		if data.parkour.killed > os.time() then
			no_powers[player] = true
			translatedChatMessage("kill_minutes", player, math.ceil((data.parkour.killed - os.time()) / 1000 / 60))
		else
			no_powers[player] = nil
		end

		if victory[player] then
			if not no_powers[player] then
				bindNecessary(player)
			end
		else
			unbind(player)
		end
	end)

	onEvent("PlayerWon", function(player)
		if bans[ room.playerList[player].id ] then return end

		if count_stats and room.uniquePlayers >= min_save and player_count >= min_save and not is_tribe and not review_mode then
			local file = players_file[player].parkour
			file.c = file.c + 1
			file.hour_c = file.hour_c + 1
			file.week_c = file.week_c + 1

			if file.hour_c >= 35 and file.hour_c % 5 == 0 then
				sendPacket(3, room.name .. "\000" .. room.playerList[player].id .. "\000" .. player .. "\000" .. file.hour_c)
			end

			savePlayerData(player)
		end

		if not no_powers[player] then
			bindNecessary(player)
		end
	end)

	onEvent("NewGame", function()
		local now = os.time()

		local to_remove, count = {}, 0
		for player in next, no_powers do
			if not players_file[player] or players_file[player].parkour.killed <= now then
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
			if file and file.parkour.hour_r <= now then
				file.parkour.hour_c = 0
				file.parkour.hour_r = now + 60 * 60 * 1000
				savePlayerData(player)
			end

			unbind(player)
		end
	end)

	onEvent("GameStart", function()
		local clickPointer = 0
		local qwerty_keys = keyPowers.qwerty
		local azerty_keys = keyPowers.azerty
		local qwerty_keyCode, azerty_keyCode

		local power
		for index = 1, #powers do
			power = powers[index]
			power.index = index
			if power.click then
				clickPointer = clickPointer + 1
				clickPowers[clickPointer] = power
			else
				if not power.azerty then
					power.azerty = power.qwerty
				end

				qwerty_keyCode = power.qwerty.keyCode
				azerty_keyCode = power.azerty.keyCode

				if qwerty_keys[qwerty_keyCode] then
					qwerty_keys[qwerty_keyCode]._count = qwerty_keys[qwerty_keyCode]._count + 1
					qwerty_keys[qwerty_keyCode][qwerty_keys[qwerty_keyCode]._count] = power
				else
					qwerty_keys[qwerty_keyCode] = {_count = 1, [1] = power}
				end

				if azerty_keys[azerty_keyCode] then
					azerty_keys[azerty_keyCode]._count = azerty_keys[azerty_keyCode]._count + 1
					azerty_keys[azerty_keyCode][azerty_keys[azerty_keyCode]._count] = power
				else
					azerty_keys[azerty_keyCode] = {_count = 1, [1] = power}
				end

				qwerty_keys[power] = power.qwerty.key
				azerty_keys[power] = power.azerty.key
			end
		end
	end)
	--[[ End of file modes/parkour/powers.lua ]]--
	--[[ File modes/parkour/leaderboard.lua ]]--
	max_leaderboard_rows = 70
	max_weekleaderboard_rows = 28
	local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
	local max_weekleaderboard_pages = math.ceil(max_weekleaderboard_rows / 14) - 1
	local loaded_leaderboard = false
	leaderboard = {}
	weekleaderboard = {}
	-- {id, name, completed_maps, community}
	local default_leaderboard_user = {0, nil, 0, "xx"}

	local function leaderboardSort(a, b)
		return a[3] > b[3]
	end

	local remove, sort = table.remove, table.sort

	local function checkPlayersPosition(week)
		local max_lb_rows = week and max_weekleaderboard_rows or max_leaderboard_rows
		local lb = week and weekleaderboard or leaderboard
		local totalRankedPlayers = #lb
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
				completedMaps = week and playerFile.parkour.week_c or playerFile.parkour.c
				playerData = room.playerList[player]
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

		sort(lb, leaderboardSort)

		for index = max_lb_rows + 1, totalRankedPlayers do
			lb[index] = nil
		end

		for index = 1, #lb do
			lb[lb[index][2]] = index
		end
	end

	onEvent("GameDataLoaded", function(data)
		if data.ranking then
			if not loaded_leaderboard then
				loaded_leaderboard = true

				translatedChatMessage("leaderboard_loaded")
			end

			leaderboard = data.ranking

			checkPlayersPosition(false)
		end
		if data.weekranking then
			local ts = os.time()
			local now = os.date("*t", ts / 1000)
			now.wday = now.wday - 1
			if now.wday == 0 then
				now.wday = 7
			end

			local new_reset = os.date("%d/%m/%Y", ts - (now.wday - 1) * 24 * 60 * 60 * 1000)
			if new_reset ~= timed_maps.week.last_reset then
				if #data.weekranking > 2 and data.weekranking[1][3] > 30 then
					sendPacket(
						4,
						timed_maps.week.last_reset .. "\000" .. os.date("%d/%m/%Y", ts - 24 * 60 * 60 * 1000) ..
						"\000" .. data.weekranking[1][4] .. "\000" .. data.weekranking[1][2] .. "\000" .. data.weekranking[1][3] ..
						"\000" .. data.weekranking[2][4] .. "\000" .. data.weekranking[2][2] .. "\000" .. data.weekranking[2][3] ..
						"\000" .. data.weekranking[3][4] .. "\000" .. data.weekranking[3][2] .. "\000" .. data.weekranking[3][3]
					)
				end

				timed_maps.week.last_reset = new_reset
				timed_maps.week.next_reset = os.date("%d/%m/%Y", ts + (8 - now.wday) * 24 * 60 * 60 * 1000)

				for player, data in next, players_file do
					data.parkour.week_c = 0
					data.parkour.week_r = new_reset
				end

				data.weekranking = {}
			end

			weekleaderboard = data.weekranking

			checkPlayersPosition(true)
		end
	end)
	--[[ End of file modes/parkour/leaderboard.lua ]]--
	--[[ File modes/parkour/interface.lua ]]--
	local roompw = {
		owner = nil,
		password = nil
	}
	local kill_cooldown = {}
	local update_at = 0
	local staff_people = {next_check = 0, texts = {}, to_send = {}, timeout = 0}
	local open = {}
	local powers_img = {}
	local help_img = {}
	local no_help = {}
	local scrolldata = {
		players = {},
		texts = {}
	}
	local toggle_positions = {
		[1] = 107,
		[2] = 132,
		[3] = 157,
		[4] = 183,
		[5] = 209,
		[6] = 236,
		[7] = 262,
		[8] = 289
	}
	local community_images = {
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
		il = "1651b3139ed.png",
		it = "1651b3151ac.png",
		jp = "1651b31696a.png",
		lt = "1651b31811c.png",
		lv = "1651b319906.png",
		nl = "1651b31b0dc.png",
		ph = "1651b31c891.png",
		pl = "1651b31e0cf.png",
		ro = "1651b31f950.png",
		ru = "1651b321113.png",
		tr = "1651b3240e8.png",
		vk = "1651b3258b3.png"
	}

	local function addButton(id, text, action, player, x, y, width, height, disabled, left)
		id = 2000 + id * 3
		if not disabled then
			text = "<a href='event:" .. action .. "'>" .. text .. "</a>"
		end
		if not left then
			text = "<p align='center'>" .. text .. "</p>"
		end
		local color = disabled and 0x2a424b or 0x314e57

		ui.addTextArea(id    , ""  , player, x-1, y-1, width, height, 0x7a8d93, 0x7a8d93, 1, true)
		ui.addTextArea(id + 1, ""  , player, x+1, y+1, width, height, 0x0e1619, 0x0e1619, 1, true)
		ui.addTextArea(id + 2, text, player, x  , y  , width, height, color   , color   , 1, true)
	end

	local function removeButton(id, player)
		for i = 2000 + id * 3, 2000 + id * 3 + 2 do
			ui.removeTextArea(i, player)
		end
	end

	local function scrollWindow(id, player, up, force)
		local data = scrolldata.players[player]
		if not data then return end

		local old = data[2]
		data[2] = up and math.max(data[2] - 1, 1) or math.min(data[2] + 1, data[3])
		if data[2] == old and not force then return end

		ui.addTextArea(1008 + id * 9, data[1][data[2]], player, data[4], data[5], data[6], data[7], 0, 0, 0, true)

		if not data.behind_img then
			data.behind_img = tfm.exec.addImage("1719e0e550a.png", "&1", data[8], data[9], player)
		end
		if data.img then
			tfm.exec.removeImage(data.img)
		end
		data.img = tfm.exec.addImage("1719e173ac6.png", "&2", data[8], data[9] + (125 / (data[3] - 1)) * (data[2] - 1), player)
	end

	local function addWindow(id, text, player, x, y, width, height, isHelp)
		if width < 0 or height and height < 0 then
			return
		elseif not height then
			height = width/2
		end
		local _id = id
		id = 1000 + id * 9

		ui.addTextArea(id    , "", player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
		ui.addTextArea(id + 1, "", player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
		ui.addTextArea(id + 2, "", player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
		ui.addTextArea(id + 3, "", player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 4, "", player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 5, "", player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 6, "", player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)

		if text[1] then -- it is a table
			if scrolldata.players[player] and scrolldata.players[player].img then
				tfm.exec.removeImage(scrolldata.players[player].img)
				tfm.exec.removeImage(scrolldata.players[player].behind_img)
			end
			scrolldata.players[player] = {text, 1, #text, x+3, y+40, width+70, height, x+width+85, y+40, _id}
			ui.addTextArea(id + 7, "", player, x+3, y+3, width+94, height+64, 0x1c3a3e, 0x232a35, 1, true)
			scrollWindow(_id, player, true, true)
		else
			ui.addTextArea(id + 7, (isHelp and "\n\n\n" or "") .. text, player, x+3, y+3, width+94, height+64, 0x1c3a3e, 0x232a35, 1, true)
		end
	end

	local function removeWindow(id, player)
		if scrolldata.players[player] and scrolldata.players[player].img then
			tfm.exec.removeImage(scrolldata.players[player].img)
			tfm.exec.removeImage(scrolldata.players[player].behind_img)
		end
		scrolldata.players[player] = nil
		for i = 1000 + id * 9, 1000 + id * 9 + 8 do
			ui.removeTextArea(i, player)
		end
	end

	local function addToggle(id, player, state)
		local x, y = 603, toggle_positions[id]
		local _id = id
		id = 6000 + id * 3

		ui.addTextArea(id, "", player, x, y, 20, 7, 0x232a35, 0x232a35, 1, true)
		if not state then
			ui.addTextArea(id + 1, "", player, x + 3, y + 3, 1, 1, 0x78462b, 0x78462b, 1, true)
		else
			ui.addTextArea(id + 1, "", player, x + 16, y + 3, 1, 1, 0xbeb17d, 0xbeb17d, 1, true)
		end
		ui.addTextArea(id + 2, "<a href='event:toggle:" .. _id .. ":" .. (state and "0" or "1") .. "'>\n\n\n", player, x - 7, y - 7, 30, 20, 1, 1, 0, true)
	end

	local function removeToggle(id, player)
		for i = 6000 + id * 3, 6000 + id * 3 + 2 do
			ui.removeTextArea(i, player)
		end
	end

	local function sendStaffList(player)
		text = "<v>[#]<n> <d>Online parkour staff:</d>"

		local sent = {}
		local any_online = false
		for i = 1, #ranks_order do
			for player in next, ranks[ranks_order[i]] do
				if staff_people.texts[player] and online[player] and not sent[player] then
					text = text .. staff_people.texts[player]
					sent[player] = true
					any_online = true
				end
			end
		end

		if any_online then
			tfm.exec.chatMessage(text, player)
		else
			tfm.exec.chatMessage("<v>[#] <r>No parkour staff is online right now.", player)
		end
	end

	local function closeLeaderboard(player)
		if not open[player].leaderboard then return end

		removeWindow(1, player)
		removeButton(1, player)
		removeButton(2, player)
		removeButton(3, player)
		removeButton(4, player)
		for id = 1, 8 do
			ui.removeTextArea(id, player)
		end

		local images = open[player].images
		for index = 1, images._count do
			tfm.exec.removeImage(images[index])
		end
		images._count = 0

		open[player].leaderboard = false
	end

	local function closePowers(player)
		if not open[player].powers then return end

		removeWindow(1, player)
		removeButton(1, player)
		removeButton(2, player)
		ui.removeTextArea(1, player)
		ui.removeTextArea(2, player)

		local images = open[player].images
		for index = 1, images._count do
			tfm.exec.removeImage(images[index])
		end
		images._count = 0

		for index = 3000, 2999 + #powers do
			ui.removeTextArea(index, player)
		end

		open[player].powers = false
	end

	local function removeOptionsMenu(player)
		if not open[player].options then return end

		removeWindow(6, player)
		removeButton(6, player)

		for toggle = 1, 8 do
			removeToggle(toggle, player)
		end

		savePlayerData(player)

		open[player].options = nil
	end

	local function removeHelpMenu(player)
		if not open[player].help then return end

		removeWindow(7, player)

		for index = 10000, 10002 do
			ui.removeTextArea(index, player)
		end

		for button = 7, 12 do
			removeButton(button, player)
		end

		open[player].help = nil
	end

	local function showOptionsMenu(player)
		if open[player].leaderboard then
			closeLeaderboard(player)
		elseif open[player].powers then
			closePowers(player)
		elseif open[player].help then
			removeHelpMenu(player)
		end
		open[player].options = true

		addWindow(6, translatedMessage("options", player), player, 168, 46, 365, 260)
		addButton(6, "Close", "close_options", player, 185, 346, 426, 20, false)

		addToggle(1, player, players_file[player].parkour.ckpart == 1) -- particles for checkpoints
		addToggle(2, player, players_file[player].parkour.keyboard == 1) -- qwerty keyboard
		addToggle(3, player, players_file[player].parkour.mort == 1) -- M or DEL hotkey
		addToggle(4, player, players_file[player].parkour.pcool == 1) -- power cooldowns
		addToggle(5, player, players_file[player].parkour.pbut == 1) -- powers button
		addToggle(6, player, players_file[player].parkour.hbut == 1) -- help button
		addToggle(7, player, players_file[player].parkour.congrats == 1) -- congratulations message
		addToggle(8, player, players_file[player].parkour.help == 1) -- no help indicator
	end

	local function showHelpMenu(player, tab)
		if open[player].leaderboard then
			closeLeaderboard(player)
		elseif open[player].powers then
			closePowers(player)
		elseif open[player].options then
			removeOptionsMenu(player)
		end
		open[player].help = true

		if scrolldata.players[player] and scrolldata.players[player].img then
			tfm.exec.removeImage(scrolldata.players[player].img)
			tfm.exec.removeImage(scrolldata.players[player].behind_img)
		end
		scrolldata.players[player] = nil

		addWindow(7, scrolldata.texts[player_langs[player].name .. "_help_" .. tab], player, 100, 50, 500, 260, true)

		ui.addTextArea(10000, "", player, 155, 55, 490, 30, 0x1c3a3e, 0x1c3a3e, 1, true)
		ui.addTextArea(10001, "", player, 155, 358, 490, 17, 0x1c3a3e, 0x1c3a3e, 1, true)

		addButton(7, translatedMessage("help", player), "help:help", player, 160, 60, 80, 18, tab == "help")
		addButton(8, translatedMessage("staff", player), "help:staff", player, 260, 60, 80, 18, tab == "staff")
		addButton(9, translatedMessage("rules", player), "help:rules", player, 360, 60, 80, 18, tab == "rules")
		addButton(10, translatedMessage("contribute", player), "help:contribute", player, 460, 60, 80, 18, tab == "contribute")
		addButton(11, translatedMessage("changelog", player), "help:changelog", player, 560, 60, 80, 18, tab == "changelog")

		addButton(12, "", "close_help", player, 160, 362, 480, 10, false)
		ui.addTextArea(10002, "<a href='event:close_help'><p align='center'>Close\n", player, 160, 358, 480, 15, 0, 0, 0, true)
	end

	local function capitalize(str)
		local first = string.sub(str, 1, 1)
		if first == "+" then
			return "+" .. string.upper(string.sub(str, 2, 2)) .. string.lower(string.sub(str, 3))
		else
			return string.upper(first) .. string.lower(string.sub(str, 2))
		end
	end

	local function setNameColor(player)
		tfm.exec.setNameColor(
			player,

			victory[player] and 0xFEFF00 -- has won
			or ranks.admin[player] and 0xE7342A -- admin
			or ranks.manager[player] and 0x843DA4 -- manager
			or (ranks.mod[player] or ranks.trainee[player]) and 0xFFAAAA -- moderator
			or ranks.mapper[player] and 0x25C059 -- mapper
			or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
			or 0x148DE6 -- default
		)
	end

	local function showLeaderboard(player, page, week)
		if open[player].powers then
			closePowers(player)
		elseif open[player].options then
			removeOptionsMenu(player)
		elseif open[player].help then
			removeHelpMenu(player)
		end
		open[player].leaderboard = true

		local images = open[player].images
		for index = 1, images._count do
			tfm.exec.removeImage(images[index])
		end
		images._count = 0

		local max_pages = week and max_weekleaderboard_pages or max_leaderboard_pages
		if not page or page < 0 then
			page = 0
		elseif page > max_pages then
			page = max_pages
		end

		addWindow(
			1,
			string.format(
				"<p align='center'><font size='28'><B><D>%s</D></B></font>\n<font color='#32585E'>%s</font></p>",
				translatedMessage("leaderboard", player),
				string.rep("¯", 50)
			),
			player,
			168, 46, 365, 260
		)
		ui.addTextArea(1, '<V><p align="center">' .. translatedMessage("position", player), player, 180, 100, 50, 20, 1, 1, 0, true)
		ui.addTextArea(2, '<V><p align="center">' .. translatedMessage("username", player), player, 246, 100, 176, 20, 1, 1, 0, true)
		ui.addTextArea(3, '<V><p align="center">' .. translatedMessage("community", player), player, 435, 100, 70, 20, 1, 1, 0, true)
		ui.addTextArea(4, '<V><p align="center">' .. translatedMessage("completed", player), player, 518, 100, 105, 20, 1, 1, 0, true)

		ui.addTextArea(7, "", player, 435, 130, 70, 235, 0x203F43, 0x193E46, 1, true)
		default_leaderboard_user[2] = translatedMessage("unknown", player)
		local positions, names, completed = "", "", ""
		local position, row
		for index = page * 14, page * 14 + 13 do
			position = index + 1
			if position > (week and max_weekleaderboard_rows or max_leaderboard_rows) then break end
			positions = positions .. "#" .. position .. "\n"
			row = (week and weekleaderboard or leaderboard)[position] or default_leaderboard_user

			if position == 1 then
				names = names .. "<cs>" .. row[2] .. "</cs>\n"
			elseif position == 2 then
				names = names .. "<n>" .. row[2] .. "</n>\n"
			elseif position == 3 then
				names = names .. "<ce>" .. row[2] .. "</ce>\n"
			else
				names = names .. row[2] .. "\n"
			end

			completed = completed .. row[3] .. "\n"

			images._count = images._count + 1
			images[images._count] = tfm.exec.addImage(
				community_images[row[4]] or community_images["xx"],
				"&1",
				460,
				134 + 14 * (index - page * 14),
				player
			)
		end
		ui.addTextArea(5, "<font size='12'><p align='center'><v>" .. positions , player, 183, 130, 50 , 235, 0x203F43, 0x193E46, 1, true)
		ui.addTextArea(6, "<font size='12'><p align='center'><t>" .. names     , player, 246, 130, 176, 235, 0x203F43, 0x193E46, 1, true)
		ui.addTextArea(8, "<font size='12'><p align='center'><vp>" .. completed, player, 518, 130, 100, 235, 0x203F43, 0x193E46, 1, true)

		local lb_type = week and 2 or 1
		addButton(1, "&lt;\n", "leaderboard_p:".. lb_type .. ":" .. page - 1, player, 185, 346, 40, 20, not (page > 0)        )
		addButton(2, "&gt;\n", "leaderboard_p:".. lb_type .. ":" .. page + 1, player, 580, 346, 40, 20, not (page < max_pages))

		addButton(3, translatedMessage("overall_lb", player) .. "\n", "leaderboard_t:1", player, 240, 346, 155, 20, not week)
		addButton(4, translatedMessage("weekly_lb" , player) .. "\n", "leaderboard_t:2", player, 410, 346, 155, 20, week    )
	end

	local function showPowers(player, page)
		if not players_file[player] then return end

		if open[player].leaderboard then
			closeLeaderboard(player)
		elseif open[player].options then
			removeOptionsMenu(player)
		elseif open[player].help then
			removeHelpMenu(player)
		end
		open[player].powers = true

		local images = open[player].images
		for index = 1, images._count do
			tfm.exec.removeImage(images[index])
		end
		images._count = 0

		addWindow(1, "<p align='center'><font size='40'><b>" .. translatedMessage("powers", player), player, 150, 76, 400, 200)
		ui.addTextArea(1, "", player, 160, 140, 480, 195, 0x1D464F, 0x193E46, 1, true)

		local completed = players_file[player].parkour.c
		local player_pos = leaderboard[player] or max_leaderboard_rows + 1
		local power, canUse
		for index = page * 3, page * 3 + 2 do
			power = powers[index + 1]
			if power then
				if power.ranking then
					canUse = player_pos <= power.ranking
				else
					canUse = completed >= power.maps
				end
				ui.addTextArea(
					3000 + index,
					string.format(
						"<p align='center'><b><d>%s\n\n\n\n\n\n\n\n<n>%s",
						power.name and translatedMessage(power.name, player) or "undefined",
						canUse and (
							power.click and
							translatedMessage("click", player) or
							translatedMessage("press", player, player_keys[player][power])
						) or (
							power.ranking and
							translatedMessage("ranking_pos", player, power.ranking) or
							completed .. "/" .. power.maps
						)
					),
					player,
					170 + (index - page * 3) * 160,
					150,
					140,
					125,
					0x1c3a3e,
					0x193e46,
					1,
					true
				)
				images._count = images._count + 1
				images[images._count] = tfm.exec.addImage(
					power.image.url,
					"&1",
					power.image.x + 170 + (index - page * 3) * 160,
					power.image.y + 150,
					player
				)
			else
				ui.removeTextArea(3000 + index, player)
			end
		end

		ui.addTextArea(2, translatedMessage("completed_maps", player, completed), player, 230, 300, 340, 20, 0x1c3a3e, 0x193E46, 1, true)

		addButton(1, "&lt;   ", "power:" .. page - 1, player, 170, 300, 40, 20, not (page > 0)          )
		addButton(2, "&gt;   ", "power:" .. page + 1, player, 590, 300, 40, 20, not powers[page * 3 + 3])
	end

	local function toggleLeaderboard(player)
		if open[player].leaderboard then
			closeLeaderboard(player)
		else
			showLeaderboard(player, 0)
		end
	end

	local function showPowersButton(player)
		powers_img[player] = tfm.exec.addImage("17136ef539e.png", ":1", 744, 32, player)
		ui.addTextArea(0, "<a href='event:powers'><font size='50'>  </font></a>", player, 739, 32, 30, 32, 0, 0, 0, true)
	end

	local function showHelpButton(player, x)
		help_img[player] = tfm.exec.addImage("17136f9eefd.png", ":1", x, 32, player)
		ui.addTextArea(-2, "<a href='event:help_button'><font size='50'>  </font></a>", player, x - 5, 32, 30, 32, 0, 0, 0, true)
	end

	local function removePowersButton(player)
		tfm.exec.removeImage(powers_img[player])
		ui.removeTextArea(0, player)
	end

	local function removeHelpButton(player)
		tfm.exec.removeImage(help_img[player])
		ui.removeTextArea(-2, player)
	end

	onEvent("TextAreaCallback", function(id, player, callback)
		local position = string.find(callback, ":", 1, true)
		local action, args
		if not position then
			action = callback
		else
			action = string.sub(callback, 1, position - 1)
			args = string.sub(callback, position + 1)
		end

		if action == "powers" then
			if open[player].powers then
				closePowers(player)
			else
				showPowers(player, 0)
			end
		elseif action == "help_button" then
			if open[player].help then
				removeHelpMenu(player)
			else
				showHelpMenu(player, "help")
			end
		elseif action == "leaderboard" then
			if open[player].leaderboard then
				closeLeaderboard(player)
			else
				showLeaderboard(player, 0)
			end
		elseif action == "power" then
			showPowers(player, tonumber(args) or 0)
		elseif action == "leaderboard_p" then
			local lb_type, page = string.match(args, "([12]):(%d+)")
			showLeaderboard(player, tonumber(page) or 0, lb_type == "2")
		elseif action == "leaderboard_t" then
			showLeaderboard(player, 0, args == "2")
		elseif action == "settings" then
			if open[player].options then
				removeOptionsMenu(player)
			else
				showOptionsMenu(player)
			end
		elseif action == "close_options" then
			removeOptionsMenu(player)
		elseif action == "close_help" then
			removeHelpMenu(player)
		elseif action == "help" then
			if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" and args ~= "changelog" then return end
			showHelpMenu(player, args)
		elseif action == "discord" then
			tfm.exec.chatMessage("<rose>" .. links.discord, player)
		elseif action == "map_submission" then
			tfm.exec.chatMessage("<rose>" .. links.maps, player)
		elseif action == "donate" then
			tfm.exec.chatMessage("<rose>" .. links.donation, player)
		elseif action == "github" then
			tfm.exec.chatMessage("<rose>" .. links.github, player)
		elseif action == "toggle" then
			local t_id, state = string.match(args, "^(%d+):([01])$")
			if not t_id then return end
			state = state == "1"

			if t_id == "1" then -- particles for checkpoints
				players_file[player].parkour.ckpart = state and 1 or 0
				ck.particles[player] = state

				if state then
					if ck.images[player] then
						tfm.exec.removeImage(ck.images[player])
					end
				else
					addCheckpointImage(player)
				end

			elseif t_id == "2" then -- qwerty keyboard
				players_file[player].parkour.keyboard = state and 1 or 0

				if victory[player] then
					unbind(player)
				end
				player_keys[player] = state and keyPowers.qwerty or keyPowers.azerty
				if victory[player] and not no_powers[player] then
					bindNecessary(player)
				end

			elseif t_id == "3" then -- M or DEL hotkey
				players_file[player].parkour.mort = state and 1 or 0

				if state then
					system.bindKeyboard(player, 77, true, true)
					system.bindKeyboard(player, 46, true, false)
				else
					system.bindKeyboard(player, 77, true, false)
					system.bindKeyboard(player, 46, true, true)
				end
			elseif t_id == "4" then -- power cooldowns
				players_file[player].parkour.pcool = state and 1 or 0

			elseif t_id == "5" then -- powers button
				players_file[player].parkour.pbut = state and 1 or 0

				if state then
					showPowersButton(player)
					if players_file[player].parkour.hbut == 1 then
						removeHelpButton(player)
						showHelpButton(player, 714)
					end
				else
					removePowersButton(player)
					if players_file[player].parkour.hbut == 1 then
						removeHelpButton(player)
						showHelpButton(player, 744)
					end
				end

			elseif t_id == "6" then -- help button
				players_file[player].parkour.hbut = state and 1 or 0

				if state then
					showHelpButton(player, players_file[player].parkour.pbut == 1 and 714 or 744)
				else
					removeHelpButton(player)
				end

			elseif t_id == "7" then -- congratulations message
				players_file[player].parkour.congrats = state and 1 or 0

			elseif t_id == "8" then -- no help indicator
				players_file[player].parkour.help = state and 1 or 0

				if not state then
					if no_help[player] then
						tfm.exec.removeImage(no_help[player])
						no_help[player] = nil
					end
				else
					no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
				end
			end

			addToggle(tonumber(t_id), player, state)
		end
	end)

	onEvent("GameDataLoaded", function(data)
		if data.banned then
			bans = {[0] = true}
			for id, value in next, data.banned do
				if value == 1 or os.time() < value then
					bans[tonumber(id)] = true
				end
			end

			local id, ban
			for player, pdata in next, players_file do
				if room.playerList[player] and in_room[player] then
					id = room.playerList[player].id
					ban = data.banned[tostring(id)]

					if ban then
						if ban == 1 then
							pdata.banned = 2
						else
							pdata.banned = ban
						end
						savePlayerData(player)
						sendPacket(2, id .. "\000" .. ban)
					end

					if pdata.banned and (pdata.banned == 2 or os.time() < pdata.banned) then
						bans[id] = true

						if pdata.banned == 2 then
							translatedChatMessage("permbanned", player)
						else
							local minutes = math.floor((pdata.banned - os.time()) / 1000 / 60)
							translatedChatMessage("tempbanned", player, minutes)
						end
					end
				end
			end

			for player, data in next, room.playerList do
				if in_room[player] and bans[data.id] and not spec_mode[player] then
					spec_mode[player] = true
					tfm.exec.killPlayer(player)

					player_count = player_count - 1
					if victory[player] then
						victory_count = victory_count - 1
					elseif player_count == victory_count and not less_time then
						tfm.exec.setGameTime(20)
						less_time = true
					end
				end
			end
		end
	end)

	onEvent("PlayerRespawn", function(player)
		setNameColor(player)
		if no_help[player] then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end
	end)

	onEvent("NewGame", function()
		no_help = {}

		for player in next, in_room do
			if players_file[player] and players_file[player].parkour.help == 1 then
				no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
			end
			setNameColor(player)
		end

		if is_tribe then
			translatedChatMessage("tribe_house")
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", nil, room.uniquePlayers, min_save)
		end
	end)

	onEvent("NewPlayer", function(player)
		tfm.exec.lowerSyncDelay(player)

		translatedChatMessage("welcome", player)
		translatedChatMessage("staff_power", player)
		translatedChatMessage("no_help", player)

		system.bindKeyboard(player, 38, true, true)
		system.bindKeyboard(player, 40, true, true)
		system.bindKeyboard(player, 76, true, true)
		system.bindKeyboard(player, 79, true, true)
		system.bindKeyboard(player, 72, true, true)
		system.bindKeyboard(player, 80, true, true)

		tfm.exec.addImage("1713705576b.png", ":1", 772, 32, player)
		ui.addTextArea(-1, "<a href='event:settings'><font size='50'>  </font></a>", player, 767, 32, 30, 32, 0, 0, 0, true)

		for _player, img in next, no_help do
			tfm.exec.removeImage(img)
			no_help[_player] = tfm.exec.addImage("1722eeef19f.png", "$" .. _player, -10, -35)
		end

		if levels then
			if is_tribe then
				translatedChatMessage("tribe_house", player)
			elseif room.uniquePlayers < min_save then
				translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
			end
		end

		open[player] = {
			images = {_count = 0}
		}
		kill_cooldown[player] = 0

		for _player in next, in_room do
			setNameColor(_player)
		end
	end)

	onEvent("PlayerDataParsed", function(player, data)
		system.bindKeyboard(player, data.parkour.mort == 1 and 77 or 46, true, true)
		if data.parkour.pbut == 1 then
			showPowersButton(player)
		end
		if data.parkour.hbut == 1 then
			showHelpButton(player, data.parkour.pbut == 1 and 714 or 744)
		end
		if data.parkour.help == 1 then
			no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
		end

		if data.banned and (data.banned == 2 or os.time() < data.banned) then
			bans[room.playerList[player].id] = true

			if not spec_mode[player] then
				spec_mode[player] = true
				tfm.exec.killPlayer(player)

				player_count = player_count - 1
				if victory[player] then
					victory_count = victory_count - 1
				elseif player_count == victory_count and not less_time then
					tfm.exec.setGameTime(20)
					less_time = true
				end
			end

			if data.banned == 2 then
				translatedChatMessage("permbanned", player)
			else
				local minutes = math.floor((data.banned - os.time()) / 1000 / 60)
				translatedChatMessage("tempbanned", player, minutes)
			end
		end
	end)

	onEvent("PlayerWon", function(player)
		local id = room.playerList[player].id
		if bans[id] then return end

		-- If the player joined the room after the map started,
		-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
		local taken = (os.time() - (generated_at[player] or map_start)) / 1000

		if count_stats and taken <= 45 and not review_mode and not is_tribe then
			sendPacket(1, room.name .. "\000" .. player .. "\000" .. id .. "\000" .. room.currentMap .. "\000" .. taken)
		end

		if players_file[player].parkour.congrats == 0 then
			translatedChatMessage("finished", player, player, taken)
		end

		for _player in next, in_room do
			if players_file[_player] and players_file[_player].parkour.congrats == 1 then
				translatedChatMessage("finished", _player, player, taken)
			end
		end

		if is_tribe then
			translatedChatMessage("tribe_house", player)
		elseif room.uniquePlayers < min_save then
			translatedChatMessage("min_players", player, room.uniquePlayers, min_save)
		else
			local power
			for index = 1, #powers do
				power = powers[index]

				if players_file[player].parkour.c == power.maps then
					for _player in next, in_room do
						translatedChatMessage("unlocked_power", _player, player, translatedMessage(power.name, _player))
					end
					break
				end
			end
		end
	end)

	onEvent("Loop", function()
		local now = os.time()
		if update_at >= now then
			local minutes = math.floor((update_at - now) / 60000)
			local seconds = math.floor((update_at - now) / 1000) % 60
			for player in next, in_room do
				ui.addTextArea(100000, translatedMessage("module_update", player, minutes, seconds), player, 0, 380, 800, 20, 1, 1, 0.7, true)
			end
		end
		if staff_people.timeout > 0 and now >= staff_people.timeout then
			for index = 1, #staff_people.to_send do
				sendStaffList(staff_people.to_send[index])
			end
			staff_people.timeout = 0
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

		if cmd == "lb" then
			toggleLeaderboard(player)

		elseif cmd == "donate" then
			tfm.exec.chatMessage("<rose>" .. links.donation, player)

		elseif cmd == "help" then
			showHelpMenu(player, "help")

		elseif cmd == "review" then
			local tribe_cond = is_tribe and room.playerList[player].tribeName == string.sub(room.name, 3)
			local normal_cond = perms[player] and perms[player].enable_review and (string.find(room.name, "review") or ranks.admin[player])
			if not tribe_cond and not normal_cond then
				return tfm.exec.chatMessage("<v>[#] <r>You can't toggle review mode in this room.", player)
			end

			review_mode = not review_mode
			if review_mode then
				tfm.exec.chatMessage("<v>[#] <d>Review mode enabled by " .. player .. ".")
			else
				tfm.exec.chatMessage("<v>[#] <d>Review mode disabled by " .. player .. ".")
			end

		elseif cmd == "pw" then
			if not perms[player] or not perms[player].enable_review then return end

			if not review_mode and not ranks.admin[player] then
				return tfm.exec.chatMessage("<v>[#] <r>You can't set the password of a room without review mode.", player)
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

		elseif cmd == "roomlimit" then
			if not ranks.admin[player] then return end

			local limit = tonumber(args[1])
			if not limit then
				return translatedChatMessage("invalid_syntax", player)
			end

			tfm.exec.setRoomMaxPlayers(limit)
			tfm.exec.chatMessage("<v>[#] <d>Set room max players to " .. limit .. ".", player)

		elseif cmd == "langue" then
			if pointer == 0 then
				tfm.exec.chatMessage("<v>[#] <d>Available languages:", player)
				for name, data in next, translations do
					if name ~= "pt" then
						tfm.exec.chatMessage("<d>" .. name .. " - " .. data.fullname, player)
					end
				end
				tfm.exec.chatMessage("<d>Type <b>!langue ID</b> to switch your language.", player)
			else
				local lang = string.lower(args[1])
				if translations[lang] then
					player_langs[player] = translations[lang]
					translatedChatMessage("new_lang", player)
				else
					tfm.exec.chatMessage("<v>[#] <r>Unknown language: <b>" .. lang .. "</b>", player)
				end
			end

		elseif cmd == "cp" then
			if not review_mode then return end

			local checkpoint = tonumber(args[1])
			if not checkpoint then
				return translatedChatMessage("invalid_syntax", player)
			end

			if not levels[checkpoint] then return end

			players_level[player] = checkpoint
			tfm.exec.setPlayerScore(player, checkpoint, false)
			tfm.exec.killPlayer(player)

			if ck.particles[player] == false then
				tfm.exec.removeImage(ck.images[player])
				local next_level = levels[checkpoint + 1]
				if next_level then
					addCheckpointImage(player, next_level.x, next_level.y)
				end
			end

		elseif cmd == "staff" then
			local now = os.time()
			if now >= staff_people.next_check then
				staff_people.timeout = now + 1000
				staff_people.next_check = now + 61000
				staff_people.to_send = {player}
				staff_people.texts = {}

				local texts = staff_people.texts
				local text, first
				for player, ranks in next, player_ranks do
					if player ~= "Tocutoeltuco#5522" then
						text = "\n- <v>" .. player .. "</v> ("
						first = true
						for rank in next, ranks do
							rank = rank == "trainee" and "mod trainee" or rank
							if first then
								text = text .. rank
								first = false
							else
								text = text .. ", " .. rank
							end
						end
						if not first then
							texts[player] = text .. ")"
						end
					end
				end

				online = {}
				for player in next, texts do
					if in_room[player] then
						online[player] = true
					else
						system.loadPlayerData(player)
					end
				end
			elseif now < staff_people.timeout then
				staff_people.to_send[#staff_people.to_send + 1] = player
			else
				sendStaffList(player)
			end

		elseif cmd == "map" then
			if not perms[player] or not perms[player].change_map then return end

			if pointer > 0 then
				count_stats = false
				tfm.exec.newGame(args[1])
			elseif os.time() < map_change_cd and not review_mode then
				tfm.exec.chatMessage("<v>[#] <r>You need to wait a few seconds before changing the map.", player)
			else
				newMap()
			end

		elseif cmd == "forcestats" then
			if not ranks.admin[player] then return end

			count_stats = true
			tfm.exec.chatMessage("<v>[#] <d>count_stats set to true", player)

		elseif cmd == "spec" then
			if not perms[player] or not perms[player].spectate then return end

			if not spec_mode[player] then
				spec_mode[player] = true
				tfm.exec.killPlayer(player)

				player_count = player_count - 1
				if victory[player] then
					victory_count = victory_count - 1
				elseif player_count == victory_count and not less_time then
					tfm.exec.setGameTime(20)
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

		elseif cmd == "room" then
			if not perms[player] or not perms[player].get_player_room then return end

			if pointer == 0 then
				return translatedChatMessage("invalid_syntax", player)
			end

			local fetching = capitalize(args[1])
			fetching_player_room[fetching] = {player, os.time() + 1000}
			system.loadPlayerData(fetching)

		elseif cmd == "op" then
			showOptionsMenu(player)
		end
	end)

	onEvent("Keyboard", function(player, key)
		if key == 38 or key == 40 then
			if open[player].help then
				scrollWindow(7, player, key == 38)
			end
		elseif key == 76 then
			if loaded_leaderboard then
				toggleLeaderboard(player)
			else
				return translatedChatMessage("leaderboard_not_loaded", player)
			end
		elseif key == 77 or key == 46 then
			local now = os.time()
			if now >= (kill_cooldown[player] or os.time()) then
				tfm.exec.killPlayer(player)
				kill_cooldown[player] = now + 1000
			end
		elseif key == 79 then
			if open[player].options then
				removeOptionsMenu(player)
			else
				showOptionsMenu(player)
			end
		elseif key == 72 then
			if open[player].help then
				removeHelpMenu(player)
			else
				showHelpMenu(player, "help")
			end
		elseif key == 80 then
			if open[player].powers then
				closePowers(player)
			else
				showPowers(player, 0)
			end
		end
	end)

	onEvent("GameStart", function()
		local help_texts = {"help_help", "help_staff", "help_rules", "help_contribute", "help_changelog"}

		local count, page, newline, key, text
		for name, translation in next, translations do
			for index = 1, #help_texts do
				key = name .. "_" .. help_texts[index]
				text = translation[help_texts[index]]
				count = 0
				scrolldata.texts[key] = {}
				text = "\n" .. text
				for slice = 1, #text, (help_texts[index] == "help_staff" and 700 or 800) + (name == "ru" and 250 or 0) do
					page = string.sub(text, slice)
					newline = string.find(page, "\n")
					if newline then
						page = string.sub(page, newline)
						while string.sub(page, 1, 1) == "\n" do
							page = string.sub(page, 2)
						end
						count = count + 1
						scrolldata.texts[key][count] = page
					else
						break
					end
				end
				if #text < 1100 or help_texts[index] == "help_help" or help_texts[index] == "help_contribute" then
					scrolldata.texts[key] = string.sub(text, 2)
				end
			end
		end

		tfm.exec.disableMinimalistMode(true)
		system.disableChatCommandDisplay("lb", true)
		system.disableChatCommandDisplay("map", true)
		system.disableChatCommandDisplay("spec", true)
		system.disableChatCommandDisplay("op", true)
		system.disableChatCommandDisplay("donate", true)
		system.disableChatCommandDisplay("help", true)
		system.disableChatCommandDisplay("staff", true)
		system.disableChatCommandDisplay("room", true)
		system.disableChatCommandDisplay("review", true)
		system.disableChatCommandDisplay("pw", true)
		system.disableChatCommandDisplay("cp", true)
		system.disableChatCommandDisplay("forcestats", true)
		system.disableChatCommandDisplay("roomlimit", true)
		system.disableChatCommandDisplay("langue", true)
	end)

	onEvent("PacketReceived", function(packet_id, packet)
		if packet_id == 1 then -- game update
			update_at = os.time() + 60000
		elseif packet_id == 2 then -- !kill
			local player = string.match(packet, "^([^\000]+)\000[^\000]+$")
			if in_room[player] then
				system.loadPlayerData(player)
			end
		elseif packet_id == 3 then -- !ban
			local player, val = string.match(packet, "^([^\000]+)\000[^\000]+\000([^\000]+)$")
			local file, data = players_file[player], room.playerList[player]
			if in_room[player] and data and file then
				file.banned = val == "1" and 2 or tonumber(val)
				bans[data.id] = file.banned == 2 or os.time() < file.banned

				if bans[data.id] then
					if not spec_mode[player] then
						spec_mode[player] = true
						tfm.exec.killPlayer(player)

						player_count = player_count - 1
						if victory[player] then
							victory_count = victory_count - 1
						elseif player_count == victory_count and not less_time then
							tfm.exec.setGameTime(20)
							less_time = true
						end
					end

					if file.banned == 2 then
						translatedChatMessage("permbanned", player)
					else
						local minutes = math.floor((file.banned - os.time()) / 1000 / 60)
						translatedChatMessage("tempbanned", player, minutes)
					end

				else
					if spec_mode[player] then
						spec_mode[player] = nil

						if levels and players_level[player] then
							local level = levels[ players_level[player] ]

							tfm.exec.respawnPlayer(player)
							tfm.exec.movePlayer(player, level.x, level.y)

							player_count = player_count + 1
							if victory[player] then
								victory_count = victory_count + 1
							end
						end
					end
				end

				savePlayerData(player)
				sendPacket(2, data.id .. "\000" .. val)
			end
		elseif packet_id == 4 then -- !announce
			tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
		elseif packet_id == 5 then -- !cannounce
			local commu, msg = string.match(packet, "^([^\000]+)\000(.+)$")
			if commu == room.community then
				tfm.exec.chatMessage("<vi>[" .. commu .. "] [#parkour] <d>" .. msg)
			end
		elseif packet_id == 6 then -- pw request
			if packet == room.name then
				if roompw.password then
					sendPacket(5, room.name .. "\000" .. roompw.password .. "\000" .. roompw.owner)
				else
					sendPacket(5, room.name .. "\000")
				end
			end
		end
	end)
	--[[ End of file modes/parkour/interface.lua ]]--
	--[[ File modes/parkour/webhooks.lua ]]--
	webhooks = {_count = 0}

	onEvent("ChannelLoad", function()
		for index = 1, webhooks._count do
			sendPacket(1, webhooks[index])
		end
	end)
	--[[ End of file modes/parkour/webhooks.lua ]]--
	--[[ File modes/parkour/init.lua ]]--
	eventGameStart()
	--[[ End of file modes/parkour/init.lua ]]--
	--[[ End of package modes/parkour ]]--
end

if starting == "*\003" then
	tribe = string.sub(room.name, 3)

	initialide_parkour()
else
	local pos
	if starting == "*#" then
		module_name = string.match(room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(room.name, "^[a-z][a-z2]%-#([a-z]+)")
		pos = #module_name + 5
	end

	local numbers
	numbers, submode = string.match(room.name, "^(%d+)([a-z_]+)", pos)
	if numbers then
		flags = string.sub(room.name, pos + #numbers + #submode + 1)
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
						name = "weekranking",
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
					}
				}
			}):disableValidityChecks():prepare(),

			["22"] = FileManager.new({
				type = "dictionary",
				map = {
					{
						name = "lowmaps",
						type = "array",
						objects = {
							type = "number"
						}
					},
					{
						name = "banned",
						type = "dictionary",
						objects = {
							type = "number"
						}
					}
				}
			}):disableValidityChecks():prepare()
		}
		--[[ End of file modes/parkour/filemanagers.lua ]]--
		--[[ File modes/parkour/communication.lua ]]--
		if room.name == "*#parkour4bots" then
			recv_channel, send_channel = "Holybot#0000", "Parkour#8558"
		else
			recv_channel, send_channel = "Parkour#8558", "Holybot#0000"
		end

		function sendPacket(packet_id, packet) end
		if not is_tribe then
			--[[
				Packets from 4bots:
					0 - join request
					1 - game update
					2 - !kill
					3 - !ban
					4 - !announce
					5 - !cannounce
					6 - pw request

				Packets to 4bots:
					0 - room crash
					1 - suspect
					2 - ban field set to playerdata
					3 - farm/hack suspect
					4 - weekly lb reset
					5 - pw info
			]]

			local last_id = os.time() - 10000
			local next_channel_load = 0

			local common_decoder = {
				["&0"] = "&",
				["&1"] = ";",
				["&2"] = ","
			}
			local common_encoder = {
				["&"] = "&0",
				[";"] = "&1",
				[","] = "&2"
			}

			function sendPacket(packet_id, packet)
				if not add_packet_data then
					add_packet_data = ""
				end

				add_packet_data = add_packet_data .. ";" .. packet_id .. "," .. string.gsub(packet, "[&;,]", common_encoder)
			end

			packet_handler = function(player, data)
				if player == send_channel then
					if not buffer then return end
					local send_id
					send_id, data = string.match(data, "^(%d+)(.*)$")
					if not send_id then
						send_id, data = 0, ""
					else
						send_id = tonumber(send_id)
					end

					local now = os.time()
					if now < send_id + 10000 then
						buffer = data .. buffer
					end

					system.savePlayerData(player, now .. buffer)
					buffer = nil
					if eventPacketSent then
						eventPacketSent()
					end
				elseif player == recv_channel then
					if data == "" then
						data = "0"
					end

					local send_id
					send_id, data = string.match(data, "^(%d+)(.*)$")
					send_id = tonumber(send_id)
					if send_id <= last_id then return end
					last_id = send_id

					if eventPacketReceived then
						for packet_id, packet in string.gmatch(data, ";(%d+),([^;]*)") do
							packet = string.gsub(packet, "&[012]", common_decoder)

							eventPacketReceived(tonumber(packet_id), packet)
						end
					end
				end
			end
			onEvent("PlayerDataLoaded", packet_handler)

			onEvent("Loop", function()
				local now = os.time()
				if now >= next_channel_load then
					next_channel_load = now + 10000

					if eventChannelLoad then
						eventChannelLoad()
					end
					if add_packet_data then
						buffer = add_packet_data
						add_packet_data = nil
						system.loadPlayerData(send_channel)
					end
					system.loadPlayerData(recv_channel)
				end
			end)
		end
		--[[ End of file modes/parkour/communication.lua ]]--
		--[[ File modes/parkour/ranks.lua ]]--
		local band = (bit or bit32).band
		local bxor = (bit or bit32).bxor

		local ranks = {
			admin = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0},
			trainee = {_count = 0}
		}
		local ranks_id = {
			admin = 2 ^ 0,
			manager = 2 ^ 1,
			mod = 2 ^ 2,
			mapper = 2 ^ 3,
			trainee = 2 ^ 4
		}
		local ranks_permissions = {
			admin = {
				show_update = true,
				announce = true
			},
			manager = {
				set_player_rank = true,
				perm_map = true
			},
			mod = {
				ban = true,
				unban = true,
				delete_comments = true,
				spectate = true,
				get_player_room = true,
				change_map = true,
				kill = true,
				overkill = true
			},
			mapper = {
				vote_map = true,
				change_map = true,
				enable_review = true
			},
			trainee = {
				kill = true,
				spectate = true,
				get_player_room = true
			}
		}
		player_ranks = {}
		local perms = {}
		local ranks_order = {"admin", "manager", "mod", "mapper", "trainee"}

		for rank, perms in next, ranks_permissions do
			if rank ~= "admin" then
				for perm_name, allowed in next, perms do
					ranks_permissions.admin[perm_name] = allowed
				end
			end
		end

		onEvent("GameDataLoaded", function(data)
			if data.ranks then
				ranks, perms, player_ranks = {
					admin = {_count = 0},
					manager = {_count = 0},
					mod = {_count = 0},
					mapper = {_count = 0},
					trainee = {_count = 0}
				}, {}, {}
				local player_perms, _player_ranks
				for player, rank in next, data.ranks do
					player_perms, _player_ranks = {}, {}
					for name, id in next, ranks_id do
						if band(rank, id) > 0 then
							_player_ranks[name] = true
							ranks[name][player] = true
							ranks[name]._count = ranks[name]._count + 1
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
		local files = {
			[1] = 20, -- maps, ranks, chats
			[2] = 22 -- lowmaps, banned
		}
		local next_file_load = os.time() + 61000
		local next_file_check = 0

		local bit = bit or bit32
		local packets = {
			send_other = bit.lshift(1, 8) + 255,
			send_room = bit.lshift(2, 8) + 255,
			send_webhook = bit.lshift(3, 8) + 255,
			modify_rank = bit.lshift(4, 8) + 255,
			synchronize = bit.lshift(5, 8) + 255,
			heartbeat = bit.lshift(6, 8) + 255,
			change_map = bit.lshift(7, 8) + 255,
			file_loaded = bit.lshift(8, 8) + 255,
			current_chat = bit.lshift(9, 8) + 255,
			new_chat = bit.lshift(10, 8) + 255,
			load_map = bit.lshift(11, 8) + 255,
			weekly_reset = bit.lshift(12, 8) + 255,
			room_password = bit.lshift(13, 8) + 255,

			module_crash = bit.lshift(255, 8) + 255
		}

		local hidden_bot = "Tocutoeltuco#5522"
		local parkour_bot = "Parkour#8558"
		local loaded = false
		local chats = {loading = true}
		local killing = {}
		local to_do = {}
		local in_room = {}

		local file_actions = {
			high_map_change = {1, true, function(data, map, add)
				for index = #data.maps, 1, -1 do
					if data.maps[index] == map then
						if add then
							return
						else
							table.remove(data.maps, index)
						end
					end
				end

				if add then
					data.maps[#data.maps + 1] = map
				end
			end},

			low_map_change = {2, true, function(data, map, add)
				for index = 1, #data.lowmaps do
					if data.lowmaps[index] == map then
						if add then
							return
						else
							table.remove(data.lowmaps, index)
						end
					end
				end

				if add then
					data.lowmaps[#data.lowmaps + 1] = map
				end
			end},

			new_chat = {1, true, function(data, name, chat)
				data.chats[name] = chat
				chats[name] = chat
				ui.addTextArea(packets.current_chat, name .. "\000" .. chat, parkour_bot)
			end},

			ban_change = {2, true, function(data, id, value)
				data.banned[tostring(id)] = value
			end},

			modify_rank = {1, true, function(data, player, newrank)
				data.ranks[player] = newrank
			end}
		}

		local function schedule(action, arg1, arg2)
			to_do[#to_do + 1] = {file_actions[action], arg1, arg2}
			next_file_check = os.time() + 4000
		end

		local function sendSynchronization()
			local packet
			for rank in next, ranks_id do
				if not packet then
					packet = rank
				else
					packet = packet .. "\001" .. rank
				end
			end

			for player, _ranks in next, player_ranks do
				packet = packet .. "\000" .. player
				for rank in next, _ranks do
					packet = packet .. "\001" .. rank
				end
			end

			ui.addTextArea(packets.synchronize, os.time() .. "\000" .. packet, parkour_bot)
			ui.addTextArea(packets.current_chat, "mod\000" .. chats.mod, parkour_bot)
			ui.addTextArea(packets.current_chat, "mapper\000" .. chats.mapper, parkour_bot)
		end

		onEvent("SavingFile", function(file, data)
			system.saveFile(filemanagers[tostring(file)]:dump(data), file)
		end)

		onEvent("FileLoaded", function(file, data)
			ui.addTextArea(packets.file_loaded, file, hidden_bot)

			data = filemanagers[file]:load(data)
			file = tonumber(file)
			local save = false

			local action
			for index = 1, #to_do do
				action = to_do[index][1]
				if files[action[1]] == file then
					if action[2] then
						save = true
					end

					action[3](data, to_do[index][2], to_do[index][3])
					to_do[index] = nil
				end
			end
			for index = #to_do, 1, -1 do
				if not to_do[index] then
					table.remove(to_do, index)
				end
			end

			eventGameDataLoaded(data)
			if data.chats then
				if chats.loading then
					chats = data.chats
				end
			end

			if not loaded and in_room[parkour_bot] then
				sendSynchronization()
			end
			loaded = true

			if save then
				eventSavingFile(file, data)
			end
		end)

		onEvent("TextAreaCallback", function(id, player, data)
			if player ~= hidden_bot and player ~= parkour_bot then return end

			if id == packets.send_other then
				ui.addTextArea(packets.send_other, data, player == hidden_bot and parkour_bot or hidden_bot)

			elseif id == packets.send_room then
				local packet_id, packet = string.match(data, "^(%d+)\000(.*)$")
				packet_id = tonumber(packet_id)
				if not packet_id then return end

				eventSendingPacket(packet_id, packet)

			elseif id == packets.new_chat then
				local name, chat = string.match(data, "^([^\000]+)\000([^\000]+)$")
				schedule("new_chat", name, chat)
				ui.addTextArea(packets.current_chat, name .. "\000" .. chat, parkour_bot)

			elseif id == packets.modify_rank then
				local player, action, rank = string.match(data, "^([^\000]+)\000([01])\000(.*)$")
				if not player_ranks[player] then
					player_ranks[player] = {
						[rank] = action == "1"
					}
				else
					player_ranks[player][rank] = action == "1"
				end

				local id = 0
				for rank, has in next, player_ranks[player] do
					if has then
						id = id + ranks_id[rank]
					end
				end

				if id == 0 then
					player_ranks[player] = nil
					id = nil
				end

				schedule("modify_rank", player, id)

			elseif id == packets.change_map then
				local rotation, map, add = string.match(data, "^([^\000]+)\000(%d+)\000([01])$")

				schedule(rotation .. "_map_change", tonumber(map), add == "1")

			elseif id == packets.load_map then
				tfm.exec.newGame(data)
			end
		end)

		onEvent("PlayerDataLoaded", function(player, data)
			if player == recv_channel or player == send_channel or data == "" then return end

			data = json.decode(data)
			if data.parkour.v ~= "0.6" then return end

			if killing[player] then
				data.parkour.killed = os.time() + killing[player] * 60 * 1000
				system.savePlayerData(player, json.encode(data))
			end
		end)

		onEvent("SendingPacket", function(id, packet)
			if id == 2 then -- !kill
				local player, minutes = string.match(packet, "^([^\000]+)\000([^\000]+)$")
				killing[player] = tonumber(minutes)
				system.loadPlayerData(player)

			elseif id == 3 then -- !ban
				local id, ban_time = string.match(packet, "^[^\000]+\000([^\000]+)\000([^\000]+)$")
				schedule("ban_change", id, tonumber(ban_time))

			elseif id == 4 then -- !announcement
				tfm.exec.chatMessage("<vi>[#parkour] <d>" .. packet)
			end

			sendPacket(id, packet)
		end)

		onEvent("PacketReceived", function(id, packet)
			local args, count = {}, 0
			for slice in string.gmatch(packet, "[^\000]+") do
				count = count + 1
				args[count] = slice
			end

			if id == 0 then
				local _room, event, errormsg = table.unpack(args)
				ui.addTextArea(
					packets.send_webhook,
					"**`[CRASH]:`** `" .. _room .. "` has crashed. <@212634414021214209>: `" .. event .. "`, `" .. errormsg .. "`",
					parkour_bot
				)

			elseif id == 1 then
				local _room, player, id, map, taken = table.unpack(args)
				ui.addTextArea(
					packets.send_webhook,
					"**`[SUS]:`** `" .. player .. "` (`" .. id .. "`) completed the map `" ..
					map .. "` in the room `" .. _room .. "` in `" .. taken .. "` seconds.",
					parkour_bot
				)
				if tonumber(taken) <= 27 then -- autoban!
					schedule("ban_change", id, 1)
					sendPacket(3, player .. "\000" .. id .. "\0001")
					ui.addTextArea(
						packets.send_webhook,
						"**`[BANS]:`** `AntiCheatSystem` has permbanned the player `" .. player .. "` (`" .. id .. "`)",
						parkour_bot
					)
				end

			elseif id == 2 then
				local player, ban = table.unpack(args)
				schedule("ban_change", player, nil)

			elseif id == 3 then
				local _room, id, player, maps = table.unpack(args)
				ui.addTextArea(
					packets.send_webhook,
					"**`[SUS2]:`** `" .. player .. "` (`" .. id .. "`) has got `" .. maps .. "` maps in the last hour.",
					parkour_bot
				)

			elseif id == 4 then
				ui.addTextArea(packets.weekly_reset, packet, parkour_bot)

			elseif id == 5 then
				ui.addTextArea(packets.room_password, packet, parkour_bot)
			end
		end)

		onEvent("Loop", function()
			ui.addTextArea(packets.heartbeat, "", hidden_bot)

			local now = os.time()
			if #to_do > 0 and now >= next_file_check and now >= next_file_load then
				next_file_load = os.time() + 61000

				system.loadFile(files[to_do[1][1][1]]) -- first action, data, file
			end
		end)

		onEvent("NewPlayer", function(player)
			in_room[player] = true

			if player == parkour_bot and loaded then -- Start sync process
				sendSynchronization()
			end
		end)

		onEvent("PlayerLeft", function(player)
			in_room[player] = nil
		end)

		system.loadFile(files[1])
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
	else
		initialide_parkour()
	end
end

for player in next, room.playerList do
	eventNewPlayer(player)
end