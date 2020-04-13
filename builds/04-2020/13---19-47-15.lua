--
-- Parkour v2.0
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
	github = "https://github.com/a801-luadev/parkour",
	discord = "https://discord.gg/RXaCyWz",
	maps = "https://atelier801.com/topic?f=6&t=880520"
}

local starting = string.sub(tfm.get.room.name, 1, 2)

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
--[[ File global/event-handler.lua ]]--
local translatedChatMessage
local next_file_load
local send_bot_room_crash
local file_id

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

		if keep_webhooks and next_file_load then
			if room.name == "*#parkour0maps" then
				send_bot_room_crash()
			else
				events.Loop._count = 1
				events.Loop[1] = function()
					if os.time() >= next_file_load then
						system.loadFile(file_id)
						next_file_load = os.time() + math.random(60500, 63000)
					end
				end

				events.FileLoaded._count = 1 -- There's already a decode/encode.
				events.SavingFile._count = 2
				events.SavingFile[2] = function()
					events.Loop._count = 0
					events.FileLoaded._count = 0
					events.SavingFile._count = 0
					events.GameDataLoaded._count = 0
				end

				events.GameDataLoaded._count = 1
				events.GameDataLoaded[1] = function(data)
					local now = os.time()
					if not data.webhooks or os.time() >= data.webhooks[1] then
						data.webhooks = {math.floor(os.time()) + 300000} -- 5 minutes
					end

					local last = #data.webhooks
					for index = 1, webhooks._count do
						data.webhooks[last + index] = webhooks[index]
					end
					webhooks._count = 0
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

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[CODE]:`** `" .. tfm.get.room.name .. "` is now resumed."
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
					local args = json.encode({a, b, c, d, e})
					translatedChatMessage("code_error", nil, name, "", args, result)
					tfm.exec.chatMessage(result)

					webhooks._count = webhooks._count + 1
					webhooks[webhooks._count] = "**`[CRASH]:`** `" .. tfm.get.room.name .. "` has crashed. <@212634414021214209>: `" .. name .. "`, `" .. result .. "`"

					return emergencyShutdown(true, true)
				end

				runtime = runtime + (os_time() - start)

				if runtime >= runtime_threshold then
					if not _paused then
						translatedChatMessage("paused_events")

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[CODE]:`** `" .. tfm.get.room.name .. "` has been paused."
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

if starting == "*\003" then
	tribe = string.sub(tfm.get.room.name, 3)

	--[[ Package modes/parkour ]]--
	--[[ Directory translations/parkour ]]--
	--[[ File translations/parkour/ru.lua ]]--
	translations.ru = {
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
		help_help = "<p align = 'center'><font size = '14'>Добро пожаловать в <T>#parkour!</T></font>\n\n<font size = '12'><J>Ваша цель - собрать все чекпоинты, чтобы завершить карту.</J></font></p>\n\n<font size = '11'><N>• Нажмите <O>O</O>, введите <O>!op</O> или нажмите на <O> шестеренку</O> чтобы открыть <T>меню настроек</T>.\n• Нажмите <O>P</O> или нажмите на <O>руку</O> в правом верхнем углу, чтобы открыть <T>меню со способностями</T>.\n• Нажмите <O>L</O> или введите <O>!lb</O> чтобы открыть <T>Список лидеров</T>.\n• Нажмите <O>M</O> или <O>Delete</O> чтобы не прописывать <T>/mort</T>.\n• Чтобы узнать больше о нашей <O>команде</O> и о <O>правилах паркура</O>, нажми на <T>Команда</T> и <T>Правила</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Вкладки теперь открыты! Для получения более подробной информации, нажмите на вкладку <O>Содействие</O> !</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>ОБЯЗАННОСТИ: Команда Паркура НЕ команда Transformice и НЕ имеет никакой власти в самой игре, только внутри модуля.</r>\nКоманда Parkour обеспечивают исправную работу модуля с минимальными проблемами и всегда готова помочь игрокам в случае необходимости.</font></p>\nВы можете ввести <D>!staff</D> в чат, чтобы увидеть нашу команду.\n\n<font color = '#E7342A'>Администраторы:</font> Hесут ответственность за поддержку самого модуля, добавляя новые обновления и исправляя ошибки.\n\n<font color = '#843DA4'>Руководители команд:</font> Kонтролируют команды модераторов и картостроителей, следя за тем, чтобы они хорошо выполняли свою работу. Они также несут ответственность за набор новых членов в команду.\n\n<font color = '#FFAAAA'>Модераторы:</font> Hесут ответственность за соблюдение правил модуля и наказывают тех, кто не следует им.\n\n<font color = '#25C059'>Картостроители:</font> Oтвечают за просмотр, добавление и удаление карт в модуле, обеспечивая вам приятный игровой процесс.",
		help_rules = "<font size = '13'><B><J>Все правила пользователя и условия Transformice также применяются к #parkour </J></B></font>\n\nЕсли вы обнаружили, что кто-то нарушает эти правила, напишите нашим модераторам. Если модераторов нет в сети, вы можете сообщить об этом на на нашем сервере в Discord\nПри составлении репорта, пожалуйста, укажите сервер, имя комнаты и имя игрока.\n• Пример: en-#parkour10 Blank#3495 троллинг\nДоказательства, такие как скриншоты, видео и гифки, полезны и ценны, но не обязательны.\n\n<font size = '11'>• <font color = '#ef1111'>читы, глюки или баги</font> не должны использоваться в комнатах #parkour\n• <font color = '#ef1111'>Фарм через VPN</font> считается <B>нарушением</B> и не допускается. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nЛюбой, кто пойман за нарушение этих правил, будет немедленно забанен.</B></font></p>\n\n<font size = '12'>Transformice позволяет концепцию троллинга. Однако, <font color='#cc2222'><B>мы не допустим этого в паркуре.B></font></font>\n\n<p align = 'center'><J>Троллинг - это когда игрок преднамеренно использует свои способности, чтобы помешать другим игрокам закончить карту.</j></p>\n• Троллинг ради мести <Bне является веской причиной,</B> для троллинга кого-либо и вы все равно будете наказаны.\n• Принудительная помощь игрокам, которые пытаются пройти карту самостоятельно и отказываюся от помощи, когда их об этом просят, также считается троллингом. \n• <J>Если игрок не хочет помогать или предпочитает играть в одиночку на карте, постарайтесь помочь другим игрокам</J>. Однако, если другой игрок нуждается в помощи на том же чекпоинте, что и соло игрок, вы можете помочь им [обоим].\n\nЕсли игрок пойман на троллинге, он будет наказан на один раунд, либо на все время пребывания в паркуре. Обратите внимание, что повторный троллинг приведет к более длительным и суровым наказаниям.",
		help_contribute = "<font size='14'>Команда управления паркуром дает доступ к исходному коду, потому что это помогает нашему комьюнити. Вы можете увидеть и изменить исходный код #parkour на GitHub <a href='event:github'><u>(нажми сюда)</u></a>.\n\nОбратите внимание, что мы поддерживаем модуль бесплатно, поэтому любая помощь (в отношении кода, сообщений об ошибках, предложений) приветствуется. Мы также поддерживаем пожертвования, которые можно сделать <a href='event:donate'><u>clicking here</u></a>. Любая пожертвованная сумма ценится и идет на улучшение #parkour.",

		-- Congratulation messages
		reached_level = "<d>Поздравляем! Вы достигли уровня <vp>%s</vp>.",
		finished = "<d><o>%s</o> завершил паркур за <vp>%s</vp> секунд, <fc>поздравляем!",
		unlocked_power = "<ce><d>%s</d> разблокировал способность <vp>%s</vp>.",
		enjoy = "<d>Наслаждайтесь своими новыми навыками!",

		-- Information messages
		paused_events = "<cep><b>[Предупреждение!]</b> <n> Модуль достиг критического предела и сейчас временно остановлен.",
		resumed_events = "<n2>Модуль был возобновлен.",
		welcome = "<n>Добро пожаловать в<t>#parkour</t>!",
		discord = "<cs>Хотите сообщить об ошибках, предложить идеи для улучшения паркура или просто пообщаться с другими игроками? Присоединяйтесь к нам на discord: <pt>%s</pt>",
		map_submissions = "<bv>Хотите увидеть свою карту в модуле? Пишите тут: <j>%s</j>",
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

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Параметры Паркура</font></p>\n\nИспользуйте желтые крепления для чекпоинтов\n\nИспользуйте <b>QWERTY</b> на клавиатуре (отключить if <b>AZERTY</b>)\n\nИспользуйте <b>M</b> горячую клавишу <b>/mort</b> (отключить <b>DEL</b>)\n\nПоказать ваше время перезарядки\n\nПоказать кнопку способностей\n\nПоказать кнопку помощь\n\nПоказать объявление о завершении карты",
		unknown = "Неизвестно",
		powers = "Способности",
		press = "<vp>Нажмите %s",
		click = "<vp>Щелчок левой кнопкой мыши",
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
	}
	--[[ End of file translations/parkour/ru.lua ]]--
	--[[ File translations/parkour/en.lua ]]--
	translations.en = {
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
		help_help = "<p align = 'center'><font size = '14'>Welcome to <T>#parkour!</T></font>\n\n<font size = '12'><J>Your goal is to reach all the checkpoints until you complete the map.</J></font></p>\n\n<font size = '11'><N>• Press <O>O</O>, type <O>!op</O> or click the <O>configuration button</O> to open the <T>options menu</T>.\n• Press <O>P</O> or click the <O>hand icon</O> at the top-right to open the <T>powers menu</T>.\n• Press <O>L</O> or type <O>!lb</O> to open the <T>leaderboard</T>.\n• Press the <O>M</O> or <O>Delete</O> key to <T>/mort</T>, you can toggle the keys in the <J>Options</J> menu.\n• To know more about our <O>staff</O> and the <O>rules of parkour</O>, click on the <T>Staff</T> and <T>Rules</T> tab respectively.</font>\n\n<p align = 'center'><font size = '13'><T>Contributions are now open! For further details, click on the <O>Contribute</O> tab!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Parkour staff ARE NOT Transformice staff and DO NOT have any power in the game itself, only within the module.</r>\nParkour staff ensure that the module runs smoothly with minimal issues, and are always available to assist players whenever necessary.</font></p>\nYou can type <D>!staff</D> in the chat to see the staff list.\n\n<font color = '#E7342A'>Administrators:</font> They are responsible for maintaining the module itself by adding new updates and fixing bugs.\n\n<font color = '#843DA4'>Team Managers:</font> They oversee the Moderator and Mapper teams, making sure they are performing their jobs well. They are also responsible for recruiting new members to the staff team.\n\n<font color = '#FFAAAA'>Moderators:</font> They are responsible for enforcing the rules of the module and punishing individuals who do not follow them.\n\n<font color = '#25C059'>Mappers:</font> They are responsible for reviewing, adding, and removing maps within the module to ensure that you have an enjoyable gameplay.",
		help_rules = "<font size = '13'><B><J>All rules in the Transformice Terms and Conditions also apply to #parkour</J></B></font>\n\nIf you find any player breaking these rules, whisper the parkour mods in-game. If no mods are online, then it is recommended to report it in the discord server.\nWhen reporting, please include the server, room name, and player name.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidence, such as screenshots, videos and gifs are helpful and appreciated, but not necessary.\n\n<font size = '11'>• No <font color = '#ef1111'>hacks, glitches or bugs</font> are to be used in #parkour rooms\n• <font color = '#ef1111'>VPN farming</font> will be considered an <B>exploit</B> and is not allowed. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nAnyone caught breaking these rules will be immediately banned.</B></font></p>\n\n<font size = '12'>Transformice allows the concept of trolling. However, <font color='#cc2222'><B>we will not allow it in parkour.</B></font></font>\n\n<p align = 'center'><J>Trolling is when a player intentionally uses their powers to prevent other players from finishing the map.</j></p>\n• Revenge trolling is <B>not a valid reason</B> to troll someone and you will still be punished.\n• Forcing help onto players trying to solo the map and refusing to stop when asked is also considered trolling.\n• <J>If a player does not want help or prefers to solo a map, please try your best to help other players</J>. However if another player needs help in the same checkpoint as the solo player, you can help them [both].\n\nIf a player is caught trolling, they will be punished on either a time or parkour round basis. Note that repeated trolling will lead to longer and more severe punishments.",
		help_contribute = "<font size='14'>The parkour management team loves open source code, because it helps the community. You can see and modify #parkour's source code on github <a href='event:github'><u>(click here)</u></a>.\n\nNote that we are maintaining the module for free, so any help (regarding code, bug reports, suggestions) is welcomed. We also support donations, which can be done by <a href='event:donate'><u>clicking here</u></a>. Any amount donated is appreciated and will go towards improving #parkour.",

		-- Congratulation messages
		reached_level = "<d>Congratulations! You've reached level <vp>%s</vp>.",
		finished = "<d><o>%s</o> finished the parkour in <vp>%s</vp> seconds, <fc>congratulations!",
		unlocked_power = "<ce><d>%s</d> unlocked the <vp>%s</vp> power.",
		enjoy = "<d>Enjoy your new skills!",

		-- Information messages
		paused_events = "<cep><b>[Warning!]</b> <n>The module has reached it's critical limit and is being paused.",
		resumed_events = "<n2>The module has been resumed.",
		welcome = "<n>Welcome to <t>#parkour</t>!",
		discord = "<cs>Do you want to report bugs, make suggestions or just want to chat with other players? Join us on discord: <pt>%s</pt>",
		map_submissions = "<bv>Do you want to see your map in the module? Submit them here: <j>%s</j>",
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

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkour Options</font></p>\n\nUse particles for checkpoints\n\nUse <b>QWERTY</b> keyboard (disable if <b>AZERTY</b>)\n\nUse <b>M</b> hotkey for <b>/mort</b> (disable for <b>DEL</b>)\n\nShow your power cooldowns\n\nShow powers button\n\nShow help button\n\nShow map completion announcements",
		unknown = "Unknown",
		powers = "Powers",
		press = "<vp>Press %s",
		click = "<vp>Left click",
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
	}
	--[[ End of file translations/parkour/en.lua ]]--
	--[[ File translations/parkour/es.lua ]]--
	translations.es = {
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
		help_help = "<p align = 'center'><font size = '14'>¡Bienvenido a <T>#parkour!</T></font>\n\n<font size = '12'><J>Tu objetivo es alcanzar todos los puntos de control hasta que completes el mapa.</J></font></p>\n\n<font size = '11'><N>• Presiona la tecla <O>O</O>, escribe <O>!op</O> o clickea el <O>botón de configuración</O> para abrir el <T>menú de opciones</T>.\n• Presiona la tecla <O>P</O> o clickea el <O>ícono de la mano</O> arriba a la derecha para abrir el <T>menú de poderes</T>.\n• Presiona la tecla <O>L</O> o escribe <O>!lb</O> para abrir el <T>ranking</T>.\n• Presiona la tecla <O>M</O> o <O>Delete</O> como atajo para <T>/mort</T>, podes alternarlas en el menú de <J>Opciones</J>.\n• Para conocer más acerca de nuestro <O>staff</O> y las <O>reglas de parkour</O>, clickea en las pestañas de <T>Staff</T> y <T>Reglas</T>.</font>\n\n<p align = 'center'><font size = '13'><T>¡Las contribuciones están abiertas! Para más detalles, ¡clickea en la pestaña <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>NOTA: El staff de Parkour NO ES staff de Transformice y NO TIENEN ningún poder en el juego, sólamente dentro del módulo.</r>\nEl staff de Parkour se asegura de que el módulo corra bien con la menor cantidad de problemas, y siempre están disponibles para ayudar a los jugadores cuando sea necesario.</font></p>\nPuedes escribir <D>!staff</D> en el chat para ver la lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> Son los responsables de mantener el módulo añadiendo nuevas actualizaciones y arreglando bugs.\n\n<font color = '#843DA4'>Lideres de Equipos:</font> Ellos supervisan los equipos de Moderadores y Mappers, asegurándose de que hagan un buen trabajo. También son los responsables de reclutar nuevos miembros al staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> Son los responsables de ejercer las reglas del módulo y sancionar a quienes no las sigan.\n\n<font color = '#25C059'>Mappers:</font> Son los responsables de revisar, añadir y quitar mapas en el módulo para asegurarse de que tengas un buen gameplay.",
		help_rules = "<font size = '13'><B><J>Todas las reglas en los Terminos y Condiciones de Transformice también aplican a #parkour</J></B></font>\n\nSi encuentras algún jugador rompiendo estas reglas, susurra a los moderadores de parkour en el juego. Si no hay moderadores online, es recomendable reportarlo en discord.\nCuando reportes, por favor agrega el servidor, el nombre de la sala, y el nombre del jugador.\n• Ej: en-#parkour10 Blank#3495 trollear\nEvidencia, como fotos, videos y gifs ayudan y son apreciados, pero no son necesarios.\n\n<font size = '11'>• No se permite el uso de <font color = '#ef1111'>hacks, glitches o bugs</font>\n• <font color = '#ef1111'>Farmear con VPN</font> será considerado un <B>abuso</B> y no está permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nCualquier persona rompiendo estas reglas será automáticamente baneado.</B></font></p>\n\n<font size = '12'>Transformice acepta el concepto de trollear. Pero <font color='#cc2222'><B>no está permitido en #parkour.</B></font></font>\n\n<p align = 'center'><J>Trollear es cuando un jugador intencionalmente usa sus poderes para hacer que otros jugadores no completen el mapa.</j></p>\n• Trollear como revancha <B>no es una razón válida</B> para trollear a alguien y aún así seras sancionado.\n• Ayudar a jugadores que no quieren completar el mapa con ayuda y no parar cuando te lo piden también es considerado trollear.\n• <J>Si un jugador no quiere ayuda, por favor ayuda a otros jugadores</J>. Sin embargo, si otro jugador necesita ayuda en el mismo punto, puedes ayudarlos [a los dos].\n\nSi un jugador es atrapado trolleando, será sancionado ya sea en base de tiempo o de rondas. Trollear repetidas veces llevará a sanciones más largas y severas.",
		help_contribute = "<font size='14'>El equipo de mantenimiento de parkour ama el código abierto, porque ayuda a la comunidad. Puedes ver y modificar el código fuente de #parkour en github <a href='event:github'><u>(click aquí)</u></a>.\n\nNosotros mantenemos el módulo de manera gratuita, por lo que cualquier ayuda (ya sea en el código, reportes de bugs, sugerencias) es bienvenida. También aceptamos donaciones, las cuales pueden ser hechas <a href='event:donate'><u>clickeando aquí</u></a>. Cualquier cantidad donada es apreciada y será destinada a mejorar #parkour.",

		-- Congratulation messages
		reached_level = "<d>¡Felicitaciones! Alcanzaste el nivel <vp>%s</vp>.",
		finished = "<d><o>%s</o> completó el parkour en <vp>%s</vp> segundos, <fc>¡felicitaciones!",
		unlocked_power = "<ce><d>%s</d> desbloqueó el poder <vp>%s<ce>.",
		enjoy = "<d>¡Disfruta tus nuevas habilidades!",

		-- Information messages
		paused_events = "<cep><b>[¡Advertencia!]</b> <n>El módulo está entrando en estado crítico y está siendo pausado.",
		resumed_events = "<n2>El módulo ha sido reanudado.",
		welcome = "<n>¡Bienvenido a <t>#parkour</t>!",
		discord = "<cs>¿Tienes alguna buena idea, reporte de bug o simplemente quieres hablar con otros jugadores? Entra a nuestro servidor de discord: <pt>%s</pt>",
		map_submissions = "<bv>¿Quieres ver tu mapa en el módulo? Publicalo aquí: <j>%s</j>",
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

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Opciones de Parkour</font></p>\n\nUsar partículas para los checkpoints\n\nUsar teclado <b>QWERTY</b> (desactivar si usas <b>AZERTY</b>)\n\nUsar la tecla <b>M</b> como atajo para <b>/mort</b> (desactivar si usas <b>DEL</b>)\n\nMostrar tiempos de espera de tus poderes\n\nMostrar el botón de poderes\n\nMostrar el botón de ayuda\n\nMostrar mensajes al completar un mapa",
		unknown = "Desconocido",
		powers = "Poderes",
		press = "<vp>Presiona %s",
		click = "<vp>Haz clic",
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
	}
	--[[ End of file translations/parkour/es.lua ]]--
	--[[ File translations/parkour/fr.lua ]]--
	translations.fr = {
		-- Error messages
		corrupt_map = "<r>Carte non opérationelle. Chargement d'une autre.",
		corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les information de cette carte.",
		corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
		corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise de fin (point final).",
		corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte a besoin d'au moins d'un point de sauvegarde (étoiles jaunes).",
		corrupt_data = "<r>Malheureusment, vos donnés ont été corrompues et ont été effacé.",
		min_players = "<r>Pour sauvegarder vos donnés, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
		tribe_house = "<r>Les données ne sont pas sauvées dans les maisons de tribus..",
		invalid_syntax = "<r>Syntaxe invalide.",
		user_not_in_room = "<r>Le joueur <n2>%s</n2> n'est pas dans le salon.",
		arg_must_be_id = "<r>L'argument doit Être un ID valide.",
		cant_update = "<r>Impossible de mettre à jour les rangs des joueurs pour l'instant. Essayer plus tard.",
		cant_edit = "<r>Vous ne pouvez pas modifier le rang de <n2>%s's</n2>.",
		invalid_rank = "<r>Rang invalide: <n2>%s",
		code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
		panic_mode = "<r>Module est maintenant en mode panique.",
		public_panic = "<r>Merci d'attendre jusqu'à ce que le robot arrive et redémarre le serveur.",
		tribe_panic = "<r>Veuillez ecrire <n2>/module parkour</n2> pour redémarrer le module.",
		emergency_mode = "<r>Mise en place du bloquage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon de #parkour.",
		bot_requested = "<r>Le robot à été solicité, il devrait arrivé dans un moment.",
		stream_failure = "<r>Echec de la chaine de stream interne. Impossible de transmettre les données.",
		maps_not_available = "<r>#parkour's 'maps' est seulement disponible dans <n2>*#parkour0maps</n2>.",
		version_mismatch = "<r>Le robot (<d>%s</d>) et Lua(<d>%s</d>) ne marche pas ensemble. Impossible de démarrer le système.",
		missing_bot = "<r>Robot absent. Attendez jusqu'à ce que le robot arrive ou mentionnez @Tocu#0018 sur Discord: <d>%s</d>",
		invalid_length = "<r>Votre message doit obligatoirement avoir entre 10 et 100 caractères. Il a seulement <n2>%s</n2> characters.",
		invalid_map = "<r>Carte invalide.",
		map_does_not_exist = "<r>Cette carte n'existe pas ou ne peut pas Être chargé. Essayez plus tard.",
		invalid_map_perm = "<r>Cette carte n'est pas P22 ou P41.",
		invalid_map_perm_specific = "<r>La carte n'est pas P%s.",
		cant_use_this_map = "<r>Cette carte a un bug et ne peut pas Être utilisée.",
		invalid_map_p41 = "<r>Cette carte est en P41, mais n'est pas dans la liste des cartes de ce module.",
		invalid_map_p22 = "<r>Cette carte est en P22, mais n'est pas dans la liste des cartes de ce module.",
		map_already_voting = "<r>Cette garde a déjà un vote en cours.",
		not_enough_permissions = "<r>Vous n'avez pas assez de permissions pour faire ça.",
		already_depermed = "<r>Cette carte est déjà non-permanente.",
		already_permed = "<r>Cette carte est déjà permanente.",
		cant_perm_right_now = "<r>Impossible de changer les permissions de cette carte maintenant. Essayez plus tard.",
		already_killed = "<r>Le joueur %s a déjà été tué.",
		leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été cahrgé encore. Attendez une minute.",

		-- Help window
		help = "Aide",
		staff = "Staff",
		rules = "Règles",
		contribute = "Contribuer",
		help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font>\n\n<font size = '12'><J>Votre but est de parcourir tous les points de sauvegarde pour finir la carte.</J></font></p>\n\n<font size = '11'><N>â€¢ Press <O>O</O>, type <O>!op</O> ou cliquez le <O>configuration button</O> pour ouvrir le <T>options menu</T>.\nâ€¢ Press <O>P</O> ou cliquez le <O>hand icon</O> en haut à droite pour ouvrir <T>powers menu</T>.\nâ€¢ Press <O>L</O> ou écrivez <O>!lb</O> pour ouvrir le <T>leaderboard</T>.\nâ€¢ Appuyez sur <O>M</O> ou la touche <O>Delete</O> pour <T>/mort</T>, vous pouvez personnalisez les touches dans <J>Options</J> menu.\nâ€¢ Pour savoir plus à propos de notre <O>staff</O> et des <O>rules of parkour</O>, cliquez sur les pages respectives du <T>Staff</T> et des <T>Rules</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! pour plus d'informations, cliquez sur la page <O>Contribute</O> </T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour ne sont pas Staff de Transformice, ils n'ont aucun pouvoir sur le jeu soit-meme, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien avec des issues minimales et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module soit-meme en ajoutant des mise à jours et en réparant les bugs.\n\n<font color = '#843DA4'>Manageurs des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement de nouveau membre du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsable de vérifier, ajotuer et de supprimer des cartes dans le module pour rendre vos parties meilleurs.",
		help_rules = "<font size = '13'><B><J>All Les Regles de Termes et de Conditions de Transformice s'appliquent aussi dans #parkou.r</J></B></font>\n\nSi vous surprenez un joueur enfreignant les règles, chuchotez à un modérateur du module #parkour connecté. Si aucun modérateur n'est en ligne, reportez le dans le serveur Discord.\nPour tous reports, inclusez : le serveur, le nom du salon, et le nom du joueur.\nâ€¢ Ex: en-#parkour10 Blank#3495 trolling\nDes preuves, comme des captures d'écran, des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>â€¢ Aucun <font color = '#ef1111'> piratage, aucune corruption ou bugs</font> utilisés/abusés dans les salons #parkour\nâ€¢ <font color = '#ef1111'>VPN farming</font> seront considérés comme <B>une violation</B> et ne sont pas autorisés. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Mais, <font color='#cc2222'><B>wenous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Quelqu'un troll si il empeche, grace à ses pouvoirs, de laisser les autres joueurs finir la carte.</j></p>\nâ€¢ Le troll en revanche d'un autre troll<B>n'est pas une raison valable</B> et vous serez quand meme puni.\nâ€¢ Aider un joueur qui a dit qu'il voulait faire la carte seule est aussi considéré comme du trolling.\nâ€¢ <J>Si un joueur veut réaliser la carte sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au meme point de sauvegarde que celui-ci, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera punis par sois un certains temps ou attendre un certain temps de cartes parkour sans pouvoir les jouer. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
		help_contribute = "<font size='14'>L'équipe du staff de gérement de la communauté adore donner des sources de codes, car cela aide la communauté. vous povuez voir les sources et codes de #parkour et les modifier dans github<a href='event:github'><u>(cliquez ici)</u></a>.\n\nNotez que nous entretenons le module gratuitement, donc n'importe quel aide (que ça soit code, bugs, suggestions) est la bienvenue. Nous proposons aussi des dons, qui peuvent etre réalisés sur<a href='event:donate'><u>cliquez ici</u></a>. N'importe quel somme de don est la bienvenue et sera utilisée dans l'amélioration de #parkour.",

		-- Congratulation messages
		reached_level = "<d>Bravo! Vous avez atteint le niveau <vp>%s</vp>.",
		finished = "<d><o>%s</o> a finis le parcour en <vp>%s</vp> secondes, <fc>congratulations!",
		unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir<vp>%s</vp>.",
		enjoy = "<d>Profite de tes nouvelles compétences!",

		-- Information messages
		paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
		resumed_events = "<n2>Le module n'est plus en pause.",
		welcome = "<n>Bienvenue à<t>#parkour</t>!",
		discord = "<cs>Voulez-vous reporter des bugs ? Proposer des suggestions ou simplement parler avec d'autres joueurs ? Rejoignez notre serveur discord : <pt>%s</pt>",
		map_submissions = "<bv>Voulez-vous voir votre carte dans le module ? Soumettez-les ici : <j>%s</j>",
		type_help = "<pt>Nous vous recommandons d'utiliser la commande <d>!help</d> pour voir des informtion utiles !",
		data_saved = "<vp>Données enregistrées.",
		action_within_minute = "<vp>Cette action sera réalisée dans quelque minutes.",
		rank_save = "<n2>Ecrivez <d>!rank save</d> pour appliquer les changements.",
		module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans<d>%02d:%02d</d>.",
		mapping_loaded = "<j>[INFO] <n>Système de carte<t>(v%s)</t> chargé.",
		mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a rejoinds le salon.",
		mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a quitté le salon.",
		mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a chargé la carte.",
		starting_perm_change = "<j>[INFO] <n>Commencement du changement de permissions...",
		got_map_info = "<j>[INFO] <n>Informations de la carte récupérées. Essaie de changement de permissions...",
		perm_changed = "<j>[INFO] <n>Réussite du changement de permission de la carte<ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
		leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
		kill_minutes = "<R>Vos pouvoirs ont été désactivés pour %s minutes.",
		kill_map = "<R>Vos pouvoirs ont été désactivés jusqu'à la prochaine carte.",

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtilisez les particules comme points de sauvegarde\n\nUtilisez le clavier <b>QWERTY</b> (désactivez si votre clavier et en <b>AZERTY</b>)\n\nUtilisez <b>M</b> touche chaude pour <b>/mort</b> (désactivez pour <b>DEL</b>)\n\nMontre le cooldown de vos compétences\n\nMontre les boutons pour utiiser les compétences\n\nMontre le bouton d'aide\n\nMontre les annonces des cartes achevées",
		unknown = "Inconnu",
		powers = "Pouvoirs",
		press = "<vp>Appuyer sur %s",
		click = "<vp>Clique gauche",
		completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
		leaderboard = "Tableau des scores",
		position = "Position",
		username = "Pseudo",
		community = "Communauté",
		completed = "Cartes complétées",
		not_permed = "sans permissions",
		permed = "avec des permissions",
		points = "%d points",
		conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. Dernier commentaire par <d>%s</d>. <d>%s</d> commentaire(s), <d>%s</d> non-lu(s).",
		map_info = "<p align='center'>Code de la carte: <bl>@%s</bl> <g>|</g> Auteur de la carte: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
		permed_maps = "Maps ayant des permissions",
		ongoing_votations = "Votes en cours",
		archived_votations = "Votes archivés",
		open = "Ouvrir",
		not_archived = "non-archivée",
		archived = "archivée",
		delete = "<r><a href='event:%s'>[supprimer]</a> ",
		see_restore = "<vp><a href='event:%s'>[voir]</a> <a href='event:%s'>[restaurer]</a> ",
		no_comments = "Pas de commentaires.",
		deleted_by = "<r>[Message supprimé par %s]",
		dearchive = "inarchiver", -- pour ne plus l'archiver
		archive = "archive", -- pour archiver
		deperm = "enlever les permissions", -- pour enlever les permissions
		perm = "permissions", -- pour ajouter des permissions
		map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a> <g>|</g> Votre  vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[chargement]</a></p>",
		map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a></p>",
		load_from_thread = "<p align='center'><a href='event:load_custom'>Charger une carte personalisée</a></p>",
		write_comment = "Ecrivez votre commentaire en-dessous",
		write_map = "Ecrivez les codes de la carte en-dessous",

		-- Power names
		balloon = "Ballon",
		masterBalloon = "Maitre Ballon",
		bubble = "Bulle",
		fly = "Voler",
		snowball = "Boule de neige",
		speed = "Vitesse",
		teleport = "Teleportation",
		smallbox = "Petite boite",
		cloud = "Nuage",
		rip = "Tombe",
		choco = "Planche de chocolat",
	}
	--[[ End of file translations/parkour/fr.lua ]]--
	--[[ File translations/parkour/br.lua ]]--
	translations.br = {
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
		help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font>\n\n<font size = '12'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></font></p>\n\n<font size = '11'><N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.</font>\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#843DA4'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
		help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador usa seus poderes de forma intencional para fazer com que os outros jogadores não terminem o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador for pego trollando, serão punidos por um tempo determinado ou por algumas partidas. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
		help_contribute = "<font size='14'>A equipe de gerenciamento do parkour ama código-fonte aberto, porque isso ajuda a comunidade. Você pode ver e modificar o código do módulo no github <a href='event:github'><u>(clicando aqui)</u></a>.\n\nNote que estamos mantendo o módulo de graça, então qualquer ajuda (seja código, report de bugs, sugestões) é bem-vinda. Também podemos receber doações, que podem ser feitas <a href='event:donate'><u>clicando aqui</u></a>. Qualquer valor é apreciado e será usado para melhorar o #parkour.",

		-- Congratulation messages
		reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>.",
		finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
		unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
		enjoy = "<d>Aproveite suas novas habilidades!",

		-- Information messages
		paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
		resumed_events = "<n2>O módulo está se normalizando.",
		welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
		discord = "<cs>Tendo alguma boa ideia, report de bug ou apenas querendo conversar com outros jogadores? Entre em nosso servidor no Discord: <pt>%s</pt>",
		map_submissions = "<bv>Quer ver seu mapa no módulo? Poste-o aqui: <j>%s</j>",
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

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar partículas para os checkpoints\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <b>M</b> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado",
		unknown = "Desconhecido",
		powers = "Poderes",
		press = "<vp>Aperte %s",
		click = "<vp>Use click",
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
	}
	--[[ End of file translations/parkour/br.lua ]]--
	--[[ File translations/parkour/tr.lua ]]--
		translations.tr = {
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
		help_help = "<p align = 'center'><font size = '14'>Hoşgeldiniz. <T>#parkour!</T></font>\n\n<font size = '12'><J>Amacınız haritayı tamamlayana kadar bütün kontrol noktalarına ulaşmak.</J></font></p>\n\n<font size = '11'><N>•  Ayarlar menüsü açmak için klavyeden<O>O</O>tuşuna basabilir, <O>!op</O> yazabilir veya <O>çark</O>simgesine tıklayabilirsiniz.\n• Beceri menüsüne ulaşmak için klavyeden <O>P</O> tuşuna basabilir veya sağ üst köşedeki <O>El</O> simgesine tıklayabilirsiniz.\n• Lider tablosuna ulaşmak için <O>L</O> tuşuna basabilir veya <O>!lb</O> yazabilirsiniz.\n• Ölmek için <O>M</O> veya <O>Delete</O> tuşuna basabilirsiniz. <O>Delete</O> tuşunu kullanabilmek için <J>Ayarlar</J>ksımından <O>M</O> tuşu ile ölmeyi kapatmanız gerekmektedir.\n•  Ekip ve parkur kuralları hakkında daha fazla bilgi bilgi almak için, <O>Ekip</O> ve <O>Kurallar</O> sekmesine tıklayın.</font>\n\n<p align = 'center'><font size = '13'><T>Artık bize bağışta bulunabilirsiniz! Daha fazla bilgi için, <O>Bağış</O> sekmesine tıklayın!</T></font></p>",
		help_staff = "<p align = 'center'><font size = '13'><r>Bildiri: Parkour ekibi Transformice'ın ekibi DEĞİLDİR, sadece parkour modülünde yetkililerdir.</r>\nParkur ekibi modülün akıcı bir şekilde kalmasını sağlar ve her zaman oyunculara yardımcı olurlar.</font></p>\nEkip listesini görebilmek için <D>!staff</D> yazabilirsiniz.\n\n<font color = '#E7342A'>Administrators:</font> Modülü yönetmek, yeni güncellemeler getirmek ve hataları/bugları düzeltirler.\n\n<font color = '#843DA4'>Team Managers:</font> Modları ve Mapperları kontrol eder ve işlerini iyi yaptıklarından emin olurlar. Ayrıca ekibe yeni modlar almaktan da onlar sorumludur.\n\n<font color = '#FFAAAA'>Moderators:</font> Kuralları uygulamak ve uygulamayan oyuncuları cezalandırmaktan sorumludurlar.\n\n<font color = '#25C059'>Mappers:</font> Yeni yapılan haritaları inceler, harita listesine ekler ve siz oyuncularımızın eğlenceli bir oyun deneyimi geçirmenizi sağlarlar.",
		help_rules = "<font size = '13'><B><J>Transformice bütün kural ve koşulları #parkour içinde geçerlidir</J></B></font>\n\nEğer kurallara uymayan bir oyuncu görürseniz,oyun içinde parkour ekibindeki modlardan birine mesaj atabilirsiniz. Eğer hiçbir mod çevrim içi değilse discord serverimizde rapor edebilirsiniz.\nRapor ederken lütfen serveri, oda ismini ve oyuncu ismini belirtiniz.\n• Örnek: tr-#parkour10 Sperjump#6504 trolling\nEkran görüntüsü,video ve gifler işe yarayacaktır fakat gerekli değildir..\n\n<font size = '11'>•#parkour odalarında <font color = '#ef1111'>hack ve bug</font>kullanmak YASAKTIR!\n• <font color = '#ef1111'>VPN farming</font> yasaktır, <B>Haksız kazanç elde etmeyin</B> .. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKuralları çiğneyen herkes banlanacaktır.</B></font></p>\n\n<font size = '12'>Transformice trolleme konseptine izin verir. Fakat, <font color='#cc2222'><B>biz buna parkur modülünde izin vermeyeceğiz.</B></font></font>\n\n<p align = 'center'><J>Trollemek becerilerini diğer oyuncuların haritayı bitirmesini engellemek için kullanmak demektir..</j></p>\n• İntikam almak için trollemek <B>geçerli bir sebep değildir</B> ve cezalandırılacaktır.\n• Haritayı tek başına bitirmek isteyen bir oyuncuya zorla yardım etmeye çalışmak trollemek olarak kabul edilecek ve cezalandırılacaktır.\n• <J>Eğer bir oyuncu yardım istemiyorsa ve haritayı tek başına bitirmek istiyorsa, lütfen diğer oyunculara yardım etmeyi deneyin.</J>. Ancak yardım isteyen diğer oyuncu haritayı tek başına yapmak isteyen bir oyuncunun yanındaysa ona yardım edebilirsiniz.[both].\n\nEğer bir oyuncu trollerken yakalanırsa, zaman ve ya parkur roundları bazında cezalandırılacaktır.. Sürekli bir şekilde trollemekten dolayı ceza alan bir oyuncu eğer hala trollemeye devam ederse cezaları daha ağır olacaktır..",
		help_contribute = "<font size='14'>Parkur yönetimi açık kaynak kodlarına bayılır, çünkü topluluğumuza yardımcı oluyor. #parkour'un kaynak kodunu github'da görebilir ve ekleme yapabilirsiniz <a href='event:github'><u>(göz atmak için tıkla)</u></a>.\n\nModülü gönüllü olarak yönetiyoruz, yani her türlü (kod,bug ve hata bildirimi tavsiyeleriniz bizim için yararlı olacaktır. Ayrıca bize destek de olabilirsiniz, <a href='event:donate'><u>(destek olamk için tıkla)</u></a>. Her desteğiniz değerlidir ve #parkour'u daha da geliştirmek için kullanılacaktır.",

		-- Congratulation messages
		reached_level = "<d>Tebrikler! <vp>%s</vp>. Seviyeye ulaştınız.",
		finished = "<d><o>%s</o> parkuru <vp>%s</vp> saniyede bitirdi, <fc>Tebrikler!",
		unlocked_power = "<ce><d>%s</d>, <vp>%s</vp> becerisini açtı.",
		enjoy = "<d>Yeni becerilerinin keyfini çıkar!",

		-- Information messages
		paused_events = "<cep><b>[Dikkat!]</b> <n>Modül kritik seviyeye ulaştı ve durduruluyor.",
		resumed_events = "<n2>Modül devam ettirildi.",
		welcome = "<n><t>#parkour</t>! Odasına hoşgeldiniz.",
		discord = "<cs>Hataları bildirmek, tavsiyelerde bulunmak veya trolleyen bir oyuncuyu rapor etmek mi istiyorsunuz? Discord sunucumuza katılın: <pt>%s</pt>",
		map_submissions = "<bv>Modülde kendi yaptığınız haritanızı görmek ister misiniz? Buraya gönderin: <j>%s</j>",
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

		-- Miscellaneous
		options = "<p align='center'><font size='20'>Parkur ayarları</font></p>\n\nKontrol noktaları için parçacıkları kullan\n\n<b>QWERTY</b> klavye kullan (Kapatıldığnda <b>AZERTY</b> klavye kullanılır)\n\nÖlmek için klavyeden <b>M</b> tuşuna bas veya <b>/mort</b> komutunu kullan. (Kapattığında <b>DELETE</b> tuşuna basarak ölebilirsin.)\n\nBeceri bekleme sürelerini göster\n\nBeceriler simgesini göster\n\nYardım butonunu göster\n\nHarita bitirme duyurularını göster",
		unknown = "Bilinmiyor",
		powers = "Beceriler",
		press = "<vp>%s Tuşuna Bas",
		click = "<vp>Sol tık",
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
	}
	--[[ End of file translations/parkour/tr.lua ]]--
	--[[ End of directory translations/parkour ]]--
	--[[ File modes/parkour/timers.lua ]]--
	local timers = {}
	local aliveTimers = false

	local function addNewTimer(delay, fnc, argument)
		aliveTimers = true
		local list = timers[delay]
		if list then
			list._count = list._count + 1
			list[list._count] = {os.time() + delay, fnc, argument}
		else
			timers[delay] = {
				_count = 1,
				_pointer = 1,
				[1] = {os.time() + delay, fnc, argument}
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
						timer[2](timer[3])
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
			local timer
			for delay, list in next, timers do
				for index = list._pointer, list._count do
					timer = list[index]
					timer[2](timer[3])
				end
			end
		end
	end)
	--[[ End of file modes/parkour/timers.lua ]]--
	--[[ File modes/parkour/maps.lua ]]--
	local first_data_load = true
	local repeated = {_count = 0}
	local maps = {_count = 0}
	local is_invalid = false
	local levels

	local function newMap()
		if repeated._count == maps._count then
			repeated = {_count = 0}
		end

		local map
		repeat
			map = maps[math.random(1, maps._count)]
		until map and not repeated[map]
		repeated[map] = true
		repeated._count = repeated._count + 1

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
				maps = {_count = 1, [1] = 7171137}
			end
			if first_data_load then
				newMap()
				first_data_load = false
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
	local join_bot = "Tocutoeltuco#6919"
	local join_epoch = os.time({year=2020, month=1, day=1, hour=0})
	local join_to_delete = {_count = 0}
	local waiting_mod = false
	local next_join_check = os.time() + 15000
	local waiting_mod_timeout = 0

	onEvent("PlayerDataLoaded", function(player, data)
		if player ~= join_bot then return end

		data = json.decode(data)

		if room.name == "*#parkour0maps" then
			eventJoinSystemDataLoaded(join_bot, data)
		else
			local now = os.time() - join_epoch
			join_to_delete._count = 0

			for room_name, expire in next, data do
				if not expire[1] then
					if now >= expire[2] then
						join_to_delete._count = join_to_delete._count + 1
						join_to_delete[join_to_delete._count] = room_name

					elseif room_name == room.name then
						waiting_mod = true
						waiting_mod_timeout = now + 45000
						data[room_name] = {true, waiting_mod_timeout}

						tfm.exec.setRoomMaxPlayers(20)
					end
				end
			end

			for idx = 1, join_to_delete._count do
				data[join_to_delete[idx]] = nil
			end

			system.savePlayerData(join_bot, json.encode(data))
		end
	end)

	onEvent("Loop", function()
		local now = os.time()
		if now >= next_join_check then
			system.loadPlayerData(join_bot)
			next_join_check = now + 15000
		end
		if waiting_mod then
			tfm.exec.setRoomMaxPlayers(20)
			if now >= waiting_mod_timeout then
				waiting_mod = false
			end
		else
			tfm.exec.setRoomMaxPlayers(12)
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
	local victory = {}
	local bans = {}
	local in_room = {}
	local players_level = {}
	local generated_at = {}
	local spec_mode = {}
	local ck = {
		particles = {},
		images = {}
	}

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

	onEvent("PlayerWon", function(player, elapsed)
		victory_count = victory_count + 1
		victory[player] = true

		if victory_count == player_count then
			tfm.exec.setGameTime(20)
			less_time = true
		end
	end)

	onEvent("NewGame", function()
		check_position = 6
		victory_count = 0
		less_time = false
		victory = {}
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
			local last_level = #levels
			local level_id, next_level, player
			local particle = 29--math.random(21, 23)
			local x, y = math.random(-10, 10), math.random(-10, 10)

			for name in next, in_room do
				player = room.playerList[name]
				if bans[player.id] then
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
		tfm.exec.setRoomMaxPlayers(12)
		tfm.exec.disableAutoScore(true)
	end)
	--[[ End of file modes/parkour/game.lua ]]--
	--[[ File modes/parkour/files.lua ]]--
	next_file_load = os.time() + math.random(60500, 90500)
	local files = {
		--[[
			File values:

			- maps     (1)
			- webhooks (1 and 2)
			- update   (1)
			- ranks    (1)

			- banned   (2)
			- ranking  (2)
			- suspects (2)
		]]

		[1] = 1, -- maps, update, ranks
		[2] = 2  -- ranking, banned, suspects
	}
	local total_files = 2
	local players_file = {}
	local file_index = 1
	local fetching_player_room = {}
	file_id = files[file_index]

	local data_migrations = {
		["0.0"] = function(player, data)
			data.parkour = data.modules.parkour
			data.drawbattle = data.modules.drawbattle

			data.modules = nil

			data.parkour.v = "0.4" -- version
			data.parkour.c = data.parkour.cm -- completed maps
			data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
			data.parkour.mort = 1 -- /mort hotkey
			data.parkour.pcool = 1 -- power cooldowns
			data.parkour.pbut = 1 -- powers button
			data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
			data.parkour.killed = 0
			data.parkour.hbut = 1 -- help button
			data.parkour.congrats = 1 -- contratulations message

			data.parkour.cm = nil
		end,
		["0.1"] = function(player, data)
			data.parkour.v = "0.4"
			data.parkour.ckpart = 1
			data.parkour.mort = 1
			data.parkour.pcool = 1
			data.parkour.pbut = 1
			data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
			data.parkour.killed = 0
			data.parkour.congrats = 1
		end,
		["0.2"] = function(player, data)
			data.parkour.v = "0.4"
			data.parkour.killed = 0
			data.parkour.hbut = 1
			data.parkour.congrats = 1
		end,
		["0.3"] = function(player, data)
			data.parkour.v = "0.4"
			data.parkour.hbut = 1
			data.parkour.congrats = 1
		end
	}

	local function savePlayerData(player)
		if not players_file[player] then return end

		system.savePlayerData(
			player,
			json.encode(players_file[player])
		)
	end

	onEvent("PlayerDataLoaded", function(player, data)
		if in_room[player] then return end

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
	end)

	onEvent("PlayerDataLoaded", function(player, data)
		if not in_room[player] then return end
		if player == stream_bot or player == join_bot then return end

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
			tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. (data.room or "unknown"), fetch[1])
			fetching_player_room[player] = nil
		end

		if players_file[player] then return end

		players_file[player] = data

		players_file[player].room = room.name
		savePlayerData(player)

		eventPlayerDataParsed(player, data)
	end)

	onEvent("SavingFile", function(id, data)
		system.saveFile(json.encode(data), id)
	end)

	onEvent("FileLoaded", function(id, data)
		data = json.decode(data)
		eventGameDataLoaded(data)
		eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
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
			end
		end

		for idx = 1, count do
			fetching_player_room[to_remove[idx]] = nil
		end
	end)

	onEvent("GameStart", function()
		system.loadFile(file_id)
		next_file_load = os.time() + math.random(60500, 90500)
	end)

	onEvent("NewPlayer", function(player)
		system.loadPlayerData(player)
	end)
	--[[ End of file modes/parkour/files.lua ]]--
	--[[ File modes/parkour/ranks.lua ]]--
	local band = (bit or bit32).band
	local bxor = (bit or bit32).bxor

	local ranks = {
		admin = {_count = 0},
		manager = {_count = 0},
		mod = {_count = 0},
		mapper = {_count = 0}
	}
	local ranks_id = {
		admin = 2 ^ 0,
		manager = 2 ^ 1,
		mod = 2 ^ 2,
		mapper = 2 ^ 3
	}
	local ranks_permissions = {
		admin = {
			show_update = true
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
			change_map = true
		},
		mapper = {
			vote_map = true,
			change_map = true
		}
	}
	local player_ranks = {}
	local perms = {}
	local saving_ranks = false
	local ranks_update
	local updater
	local ranks_order = {"admin", "manager", "mod", "mapper"}

	for rank, perms in next, ranks_permissions do
		if rank ~= "admin" then
			for perm_name, allowed in next, perms do
				ranks_permissions.admin[perm_name] = allowed
			end
		end
	end

	onEvent("GameDataLoaded", function(data)
		if data.ranks then
			if saving_ranks then
				local added, removed, not_changed
				for player, rank in next, ranks_update do
					if data.ranks[player] then
						not_changed = band(data.ranks[player], rank)
						removed = bxor(not_changed, data.ranks[player])
						added = bxor(not_changed, rank)
					else
						removed = 0
						added = rank
					end

					if added > 0 then
						local new
						for rank, id in next, ranks_id do
							if band(id, added) > 0 then
								if new then
									new = new .. "*, *parkour-" .. rank
								else
									new = "parkour-" .. rank
								end
							end
						end

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is now a **" .. new .. "**."
					end
					if removed > 0 then
						local old
						for rank, id in next, ranks_id do
							if band(id, removed) > 0 then
								if old then
									old = old .. "*, *parkour-" .. rank
								else
									old = "parkour-" .. rank
								end
							end
						end

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is no longer a **" .. old .. "**."
					end

					if rank == 0 then
						data.ranks[player] = nil
					else
						data.ranks[player] = rank
					end
				end

				translatedChatMessage("data_saved", updater)
				ranks_update = nil
				updater = nil
				saving_ranks = false
			end

			ranks, perms, player_ranks = {
				admin = {_count = 0},
				manager = {_count = 0},
				mod = {_count = 0},
				mapper = {_count = 0}
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

	local no_powers = {}
	local facing = {}
	local cooldowns = {}

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
		local obj = tfm.exec.addShamanObject(...)
		addNewTimer(when, tfm.exec.removeObject, obj)
	end

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
		}
	}

	local keyPowers, clickPowers = {
		qwerty = {},
		azerty = {}
	}, {}
	local player_keys = {}

	local function bindNecessary(player)
		local maps = players_file[player].parkour.c
		for key, powers in next, player_keys[player] do
			if powers._count then
				for index = 1, powers._count do
					if maps >= powers[index].maps then
						system.bindKeyboard(player, key, true, true)
					end
				end
			end
		end

		for index = 1, #clickPowers do
			if maps >= clickPowers[index].maps then
				system.bindMouse(player, true)
				break
			end
		end
	end

	local function unbind(player)
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

		if not player_keys[player] or not victory[player] then return end
		local powers = player_keys[player][key]
		if not powers then return end

		local file = players_file[player].parkour
		local maps, show_cooldowns = file.c, file.pcool == 1
		local power
		for index = powers._count, 1, -1 do
			power = powers[index]
			if maps >= power.maps or room.name == "*#parkour0maps" then
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

		local file = players_file[player].parkour
		local maps, show_cooldowns = file.c, file.pcool == 1
		local power, cooldown
		for index = 1, #clickPowers do
			power = clickPowers[index]
			if maps >= power.maps or room.name == "*#parkour0maps" then
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

		if room.name ~= "*#parkour0maps" and room.uniquePlayers >= min_save and not is_tribe then
			completed = players_file[player].parkour.c + 1
			players_file[player].parkour.c = completed
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

		for player in next, in_room do
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
	local max_leaderboard_rows = 70
	local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
	local loaded_leaderboard = false
	local leaderboard = {}
	-- {id, name, completed_maps, community}
	local default_leaderboard_user = {0, nil, 0, "xx"}

	local function leaderboardSort(a, b)
		return a[3] > b[3]
	end

	local remove, sort = table.remove, table.sort

	local function checkPlayersPosition()
		local totalRankedPlayers = #leaderboard
		local cachedPlayers = {}

		local playerId, position

		local toRemove, counterRemoved = {}, 0
		for player = 1, totalRankedPlayers do
			position = leaderboard[player]
			playerId = position[1]

			if bans[playerId] then
				counterRemoved = counterRemoved + 1
				toRemove[counterRemoved] = player
			else
				cachedPlayers[playerId] = position
			end
		end

		for index = counterRemoved, 1, -1 do
			remove(leaderboard, toRemove[index])
		end
		toRemove = nil

		totalRankedPlayers = totalRankedPlayers - counterRemoved

		local cacheData
		local playerFile, playerData, completedMaps

		for player in next, in_room do
			playerFile = players_file[player]

			if playerFile then
				completedMaps = playerFile.parkour.c
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
						leaderboard[totalRankedPlayers] = {
							playerId,
							player,
							completedMaps,
							playerData.community
						}
					end
				end
			end
		end

		sort(leaderboard, leaderboardSort)

		for index = max_leaderboard_rows + 1, totalRankedPlayers do
			leaderboard[index] = nil
		end
	end

	onEvent("GameDataLoaded", function(data)
		if data.ranking then
			if not loaded_leaderboard then
				loaded_leaderboard = true

				translatedChatMessage("leaderboard_loaded")
			end

			leaderboard = data.ranking

			checkPlayersPosition()
		end
	end)
	--[[ End of file modes/parkour/leaderboard.lua ]]--
	--[[ File modes/parkour/interface.lua ]]--
	local kill_cooldown = {}
	local save_update = false
	local update_at = 0
	local ban_actions = {_count = 0}
	local open = {}
	local powers_img = {}
	local help_img = {}
	local toggle_positions = {
		[1] = 107,
		[2] = 132,
		[3] = 157,
		[4] = 183,
		[5] = 209,
		[6] = 236,
		[7] = 262
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

	local function addWindow(id, text, player, x, y, width, height)
		if width < 0 or height and height < 0 then
			return
		elseif not height then
			height = width/2
		end
		id = 1000 + id * 8

		ui.addTextArea(id    , ""  , player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
		ui.addTextArea(id + 1, ""  , player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
		ui.addTextArea(id + 2, ""  , player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
		ui.addTextArea(id + 3, ""  , player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 4, ""  , player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 5, ""  , player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 6, ""  , player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
		ui.addTextArea(id + 7, text, player, x+3            , y+3             , width+94    , height+64, 0x1c3a3e, 0x232a35, 1, true)
	end

	local function removeWindow(id, player)
		for i = 1000 + id * 8, 1000 + id * 8 + 7 do
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

	local function closeLeaderboard(player)
		if not open[player].leaderboard then return end

		removeWindow(1, player)
		removeButton(1, player)
		removeButton(2, player)
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

		for toggle = 1, 7 do
			removeToggle(toggle, player)
		end

		savePlayerData(player)

		open[player].options = nil
	end

	local function removeHelpMenu(player)
		if not open[player].help then return end

		removeWindow(7, player)

		ui.removeTextArea(10000, player)

		for button = 7, 11 do
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

		addWindow(7, "\n\n\n" .. translatedMessage("help_" .. tab, player) .. "\n\n\n", player, 200, 50, 300, 260)

		ui.addTextArea(10000, "", player, 210, 60, 390, 30, 0x1c3a3e, 0x1c3a3e, 1, true)

		addButton(7, translatedMessage("help", player), "help:help", player, 210, 60, 80, 18, tab == "help")
		addButton(8, translatedMessage("staff", player), "help:staff", player, 310, 60, 80, 18, tab == "staff")
		addButton(9, translatedMessage("rules", player), "help:rules", player, 410, 60, 80, 18, tab == "rules")
		addButton(10, translatedMessage("contribute", player), "help:contribute", player, 510, 60, 80, 18, tab == "contribute")

		addButton(11, "Close", "close_help", player, 210, 352, 380, 18, false)
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
			or ranks.mod[player] and 0xFFAAAA -- moderator
			or ranks.mapper[player] and 0x25C059 -- mapper
			or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
			or 0x148DE6 -- default
		)
	end

	local function showLeaderboard(player, page)
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

		if not page or page < 0 then
			page = 0
		elseif page > max_leaderboard_pages then
			page = max_leaderboard_pages
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
			if position > max_leaderboard_rows then break end
			positions = positions .. "#" .. position .. "\n"
			row = leaderboard[position] or default_leaderboard_user

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

		addButton(1, "&lt;                       ", "leaderboard_p:" .. page - 1, player, 185, 346, 210, 20, not (page > 0)                    )
		addButton(2, "&gt;                       ", "leaderboard_p:" .. page + 1, player, 410, 346, 210, 20, not (page < max_leaderboard_pages))
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
		local power, canUse
		for index = page * 3, page * 3 + 2 do
			power = powers[index + 1]
			if power then
				canUse = completed >= power.maps
				ui.addTextArea(
					3000 + index,
					string.format(
						"<p align='center'><b><d>%s\n\n\n\n\n\n\n\n<n>%s",
						power.name and translatedMessage(power.name, player) or "undefined",
						canUse and (
							power.click and
							translatedMessage("click", player) or
							translatedMessage("press", player, player_keys[player][power])
						) or completed .. "/" .. power.maps
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
			showLeaderboard(player, tonumber(args) or 0)
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
			if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" then return end
			showHelpMenu(player, args)
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
			end

			addToggle(tonumber(t_id), player, state)
		end
	end)

	onEvent("GameDataLoaded", function(data)
		if data.banned then
			bans = {}
			for player in next, data.banned do
				bans[tonumber(player)] = true
			end

			if ban_actions._count > 0 then
				local send_saved = {}
				local to_respawn = {}
				local action
				for index = 1, ban_actions._count do
					action = ban_actions[index]

					if not send_saved[action[3]] then
						send_saved[action[3]] = true
						translatedChatMessage("data_saved", action[3])
					end

					if action[1] == "ban" then
						bans[action[2]] = true
						data.banned[tostring(action[2])] = 1 -- 1 so it uses less space
						to_respawn[action[2]] = nil
					else
						bans[action[2]] = nil
						data.banned[tostring(action[2])] = nil
						to_respawn[action[2]] = true
					end

					webhooks._count = webhooks._count + 1
					webhooks[webhooks._count] = "**`[BANS]:`** **" .. action[3] .. "** has " .. action[1] .. "ned a player. (ID: **" .. action[2] .. "**)"
				end
				ban_actions = {_count = 0}

				for id in next, to_respawn do
					for player, data in next, room.playerList do
						if data.id == id then
							tfm.exec.respawnPlayer(player)
						end
					end
				end
			end
		end

		if data.update then
			if save_update then
				data.update = save_update
				save_update = nil
			end

			update_at = data.update or 0
		end
	end)

	onEvent("PlayerRespawn", setNameColor)

	onEvent("NewGame", function()
		for player in next, in_room do
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
		translatedChatMessage("discord", player, links.discord)
		translatedChatMessage("map_submissions", player, links.maps)
		translatedChatMessage("type_help", player)

		system.bindKeyboard(player, 76, true, true)
		system.bindKeyboard(player, 79, true, true)
		system.bindKeyboard(player, 72, true, true)
		system.bindKeyboard(player, 80, true, true)

		tfm.exec.addImage("1713705576b.png", ":1", 772, 32, player)
		ui.addTextArea(-1, "<a href='event:settings'><font size='50'>  </font></a>", player, 767, 32, 30, 32, 0, 0, 0, true)

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
	end)

	onEvent("PlayerWon", function(player)
		if bans[ room.playerList[player].id ] then return end

		-- If the player joined the room after the map started,
		-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
		local taken = (os.time() - (generated_at[player] or map_start)) / 1000

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
					translatedChatMessage("unlocked_power", nil, player, power.name)
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

		elseif cmd == "ban" then
			if not perms[player] or not perms[player].ban then return end

			if pointer < 1 then
				return translatedChatMessage("invalid_syntax", player)
			end

			local affected = capitalize(args[1])
			if not in_room[affected] then
				return translatedChatMessage("user_not_in_room", player, affected)
			end

			local id = room.playerList[affected].id
			ban_actions._count = ban_actions._count + 1
			ban_actions[ban_actions._count] = {"ban", id, player}
			bans[id] = true
			translatedChatMessage("action_within_minute", player)

		elseif cmd == "unban" then
			if not perms[player] or not perms[player].unban then return end

			if pointer < 1 then
				return translatedChatMessage("invalid_syntax", player)
			end

			local id = tonumber(args[1])
			if (not id) or (not bans[id]) then
				return translatedChatMessage("arg_must_be_id", player)
			end

			ban_actions._count = ban_actions._count + 1
			ban_actions[ban_actions._count] = {"unban", id, player}
			bans[id] = nil
			translatedChatMessage("action_within_minute", player)

		elseif cmd == "kill" then
			if not perms[player] or not perms[player].ban then return end

			if pointer < 1 then
				return translatedChatMessage("invalid_syntax", player)
			end

			local affected = capitalize(args[1])
			if not in_room[affected] then
				return translatedChatMessage("user_not_in_room", player, affected)
			end
			if no_powers[affected] then
				return translatedChatMessage("already_killed", player, affected)
			end

			local minutes = "-"
			if pointer > 1 then
				minutes = tonumber(args[2])

				if not minutes then
					return translatedChatMessage("invalid_syntax", player)
				end

				translatedChatMessage("kill_minutes", affected, minutes)
				players_file[affected].parkour.killed = os.time() + minutes * 60 * 1000
				savePlayerData(affected)
			else
				translatedChatMessage("kill_map", affected)
			end

			webhooks._count = webhooks._count + 1
			webhooks[webhooks._count] = "**`[BANS]:`** `" .. room.name .. "` `" .. player .. "`: `!kill " .. affected .. " " .. minutes .. "`"

			no_powers[affected] = true
			unbind(affected)

		elseif cmd == "rank" then
			if not perms[player] or not perms[player].set_player_rank then return end

			if pointer < 1 then
				return translatedChatMessage("invalid_syntax", player)
			end
			args[1] = string.lower(args[1])

			if args[1] == "add" or args[1] == "rem" then
				if pointer < 2 then
					return translatedChatMessage("invalid_syntax", player)
				end
				if updater and updater ~= player then
					return translatedChatMessage("cant_update", player)
				end

				local rank_name = string.lower(args[3])
				if not ranks[rank_name] then
					return translatedChatMessage("invalid_rank", player, rank_name)
				end

				if not ranks_update then
					ranks_update = {}
					updater = player
				end

				local affected = capitalize(args[2])
				if not ranks.admin[player] then
					if ranks.admin[affected] or ranks.manager[affected] then
						return translatedChatMessage("cant_edit", player)
					end
				end

				if args[1] == "add" and ranks[rank_name][affected] then
					return translatedChatMessage("has_rank", player, affected, rank_name)
				elseif args[1] == "rem" and not ranks[rank_name][affected] then
					return translatedChatMessage("doesnt_have_rank", player, affected, rank_name)
				end

				if not ranks_update[affected] then
					rank_id = 0
					for rank, id in next, ranks_id do
						if ranks[rank][affected] then
							rank_id = rank_id + id
						end
					end
					ranks_update[affected] = rank_id
				end

				if args[1] == "add" then
					ranks_update[affected] = ranks_update[affected] + ranks_id[rank_name]
				else
					ranks_update[affected] = ranks_update[affected] - ranks_id[rank_name]
				end

				translatedChatMessage("rank_save", player)

			elseif args[1] == "save" then
				saving_ranks = true
				translatedChatMessage("action_within_minute", player)

			elseif args[1] == "list" then
				local msg
				for rank, players in next, ranks do
					msg = "Users with the rank " .. rank .. ":"
					for player in next, players do
						msg = msg .. "\n - " .. player
					end
					tfm.exec.chatMessage(msg, player)
				end

			else
				return translatedChatMessage("invalid_syntax", player)
			end

		elseif cmd == "staff" then
			local texts = {}
			local text, _first
			for player, ranks in next, player_ranks do
				if player ~= "Tocutoeltuco#5522" then
					text = "\n- <v>" .. player .. "</v> ("
					_first = true
					for rank in next, ranks do
						if _first then
							text = text .. rank
							_first = false
						else
							text = text .. ", " .. rank
						end
					end
					texts[player] = text .. ")"
				end
			end

			text = "<v>[#]<n> <d>Parkour staff:</d>"

			for i = 1, #ranks_order do
				for player in next, ranks[ranks_order[i]] do
					if texts[player] then
						text = text .. texts[player]
						texts[player] = nil
					end
				end
			end

			tfm.exec.chatMessage(text, player)

		elseif cmd == "update" then
			if not perms[player] or not perms[player].show_update then return end

			save_update = os.time() + 60000 * 3 -- 3 minutes
			translatedChatMessage("action_within_minute", player)

		elseif cmd == "map" then
			if not perms[player] or not perms[player].change_map then return end

			if pointer > 0 then
				tfm.exec.newGame(args[1])
			else
				newMap()
			end

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
		if key == 76 then
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
		tfm.exec.disableMinimalistMode(true)
		system.disableChatCommandDisplay("lb", true)
		system.disableChatCommandDisplay("ban", true)
		system.disableChatCommandDisplay("unban", true)
		system.disableChatCommandDisplay("kill", true)
		system.disableChatCommandDisplay("rank", true)
		system.disableChatCommandDisplay("update", true)
		system.disableChatCommandDisplay("map", true)
		system.disableChatCommandDisplay("spec", true)
		system.disableChatCommandDisplay("op", true)
		system.disableChatCommandDisplay("donate", true)
		system.disableChatCommandDisplay("help", true)
		system.disableChatCommandDisplay("staff", true)
		system.disableChatCommandDisplay("room", true)
	end)
	--[[ End of file modes/parkour/interface.lua ]]--
	--[[ File modes/parkour/webhooks.lua ]]--
	webhooks = {_count = 0}

	onEvent("GameDataLoaded", function(data)
		local now = os.time()
		if not data.webhooks or os.time() >= data.webhooks[1] then
			data.webhooks = {math.floor(os.time()) + 300000} -- 5 minutes
		end

		local last = #data.webhooks
		for index = 1, webhooks._count do
			data.webhooks[last + index] = webhooks[index]
		end
		webhooks._count = 0
	end)
	--[[ End of file modes/parkour/webhooks.lua ]]--
	--[[ File modes/parkour/init.lua ]]--
	if submode ~= "maps" then
		eventGameStart()
	end
	--[[ End of file modes/parkour/init.lua ]]--
	--[[ End of package modes/parkour ]]--
else
	local pos
	if starting == "*#" then
		module_name = string.match(tfm.get.room.name, "^%*#([a-z]+)")
		pos = #module_name + 3
	else
		module_name = string.match(tfm.get.room.name, "^[a-z][a-z2]%-#([a-z]+)")
		pos = #module_name + 5
	end

	local numbers
	numbers, submode = string.match(tfm.get.room.name, "^(%d+)([a-z_]+)", pos)
	if numbers then
		flags = string.sub(tfm.get.room.name, pos + #numbers + #submode + 1)
	end

	if submode == "freezertag" then
		--[[ Package modes/freezertag ]]--
		--[[ Directory translations/freezertag ]]--
		--[[ File translations/freezertag/en.lua ]]--
		translations.en = {
			welcome = "<VP>Welcome to #FreezerTag!</VP>";
			freezed = "<BV>Wooww, so cold... You are freezed!</BV>";
			unfreezed = "<BV>Yep! %s unfreezed you!</BV>";
			freezedLife = "If you are unfreezed, you will only have more <R>%d life</R>!";
			unfreezedsomeone = "<BV>You unfreezed %s!</BV>";
			noLife = "You have lost all your health and can't be unfreezed again!";
			freezerswon = "<D>Alive freezers won!</D>";
			unfreezerswon = "<D>Alive players life!</D>";
			are_freezer = "You are a <R>freezer</R>! Press <R>SPACE</R> on players to freeze them.";
			are_unfreezer = "Escape from the mice with the color of the name <BV>blue</BV>! Press <BV>SPACE</BV> on the players to unfreeze them. You can only be unfreezed %d times!<br>Unfreeze mice to get more health!";
			playerWithoutLife = "<VP>I think this player has already became a popsicle</VP>";
			gotHp = "<VP>You were lucky to gain <R>+1 health</R> by unfreeze %s!</VP>";
			nowPopsicle = "<VP>%s became popscicle!</VP>";
			chance = "<font color='#E9E654'>Chance to be freezer: <B><R>%s</font>";
			player_banned = "<R>The player <VP>%s</VP> has been banned from playing in the room.</R>";
			player_unbanned = "<R>Now, <VP>%s</VP> can play again.</R>";
		}
		--[[ End of file translations/freezertag/en.lua ]]--
		--[[ File translations/freezertag/br.lua ]]--
		translations.br = {
			welcome = "<VP>Seja bem-vindo(a) ao #FreezerTag!</VP>";
			freezed = "<BV>Uuuii, que frio... Parece que você foi congelado!</BV>";
			unfreezed = "<BV>Oba! %s descongelou você!</BV>";
			freezedLife = "Caso seja descongelado, você só terá mais <R>%d vida(s)</R>!";
			unfreezedsomeone = "<BV>Você descongelou %s!</BV>";
			noLife = "Você perdeu todas as suas vidas e portanto não pode mais ser descongelado.";
			freezerswon = "<D>Os congeladores vivos venceram!</D>";
			unfreezerswon = "<D>Os jogadores vivos venceram!</D>";
			are_freezer = "Você é um <R>congelador</R>! Pressione <R>ESPAÇO</R> nos jogadores para congela-los.";
			are_unfreezer = "Fuja do(s) ratinho(s) com a cor do nome <BV>azul</BV>! Pressione <BV>ESPAÇO</BV> nos jogadores para descongela-los. Você só pode ser descongelado <B>%d vezes</B>!<br>Descongele ratinhos para conseguir mais vidas!";
			playerWithoutLife = "<VP>Me parece que esse jogador já virou picolé...</VP>";
			gotHp = "<VP>Você teve a sorte de ganhar <R>+1 vida</R> por ter descongelado %s!</VP>";
			nowPopsicle = "<VP>%s virou picolé!</VP>";
			chance = "<font color='#E9E654'>Chance de ser congelador(a): <B><R>%s</font>";
			player_banned = "<R>O(a) jogador(a) <VP>%s</VP> foi proibido(a) de jogar na sala.</R>";
			player_unbanned = "<R>Agora <VP>%s</VP> pode jogar novamente.</R>";
		}
		--[[ End of file translations/freezertag/br.lua ]]--
		--[[ End of directory translations/freezertag ]]--
		--[[ Package tech/require-lib ]]--
		--[[ File tech/require-lib/init.lua ]]--
		--[[
			Author(s): Nettoork#0000
		]]--

		do
			--- VariĂˇveis de bibliotecas ---
			local coroutines	= {}
			local textAreas		= {}
			local db			= {}
			local wait			= {}
			local libs
			--------------------------------
			libs = {
				['perfomance'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['create'] = function (average, loops, func)
						local times = 0
						for v = 1, average do
							local ms = os.time()
							for i = 1, loops do
								func(loops)
							end
							times = times + os.time() - ms
						end
						return('Estimated Time: '..times/average..' ms.')
					end
				},
				['button'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['create'] = function(...)
						local arg = {...}
						local id = -543212345+arg[1]*3
						local color = arg[9] and '0x2A424B' or '0x314e57'
						ui.addTextArea(id, '', arg[4], arg[5]-1, arg[6]-1, arg[7], arg[8], 0x7a8d93, 0x7a8d93, 1, true)
						ui.addTextArea(id-1, '', arg[4], arg[5]+1, arg[6]+1, arg[7], arg[8], 0x0e1619, 0x0e1619, 1, true)
						ui.addTextArea(id-2, '<p align="center"><a href="event:'..arg[3]..'">'..arg[2]..'</a></p>', arg[4], arg[5], arg[6] , arg[7], arg[8], color, color, 1, true)
					end,
					['remove'] = function(id, name)
						for i = 0, 2 do
							ui.removeTextArea(-543212345+id*3-i, name)
						end
					end
				},
				['ui-design'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['create'] = function(...)
						local arg = {...}
						if arg[6] < 0 or arg[7] and arg[7] < 0 then
							return
						elseif not arg[7] then
							arg[7] = arg[6]/2
						end
						local id = 543212345+arg[1]*8
						ui.addTextArea(id, '', arg[3], arg[4], arg[5], arg[6]+100, arg[7]+70, 0x78462b, 0x78462b, 1, true)
						ui.addTextArea(id+1, '', arg[3], arg[4], arg[5]+(arg[7]+140)/4, arg[6]+100, arg[7]/2, 0x9d7043, 0x9d7043, 1, true)
						ui.addTextArea(id+2, '', arg[3], arg[4]+(arg[6]+180)/4, arg[5], (arg[6]+10)/2, arg[7]+70, 0x9d7043, 0x9d7043, 1, true)
						ui.addTextArea(id+3, '', arg[3], arg[4], arg[5], 20, 20, 0xbeb17d, 0xbeb17d, 1, true)
						ui.addTextArea(id+4, '', arg[3], arg[4]+arg[6]+80, arg[5], 20, 20, 0xbeb17d, 0xbeb17d, 1, true)
						ui.addTextArea(id+5, '', arg[3], arg[4], arg[5]+arg[7]+50, 20, 20, 0xbeb17d, 0xbeb17d, 1, true)
						ui.addTextArea(id+6, '', arg[3], arg[4]+arg[6]+80, arg[5]+arg[7]+50, 20, 20, 0xbeb17d, 0xbeb17d, 1, true)
						ui.addTextArea(id+7, arg[2], arg[3], arg[4]+3, arg[5]+3, arg[6]+94, arg[7]+64, 0x1c3a3e, 0x232a35, 1, true)
					end,
					['remove'] = function(id, name)
						for i = 0, 7 do
							ui.removeTextArea(543212345+id*8+i, name)
						end
					end
				},
				['text-area-custom'] = { AUTHOR = 'Nettoork#0000', _VERSION = '2.0', dependencies = {},
					['add'] = function(...)
						local info = {...}
						if type(info[1]) == 'table' then
							for i, v in next, info do
								if type(v) == 'table' then
									if not v[3] then
										v[3] = 'nil'
									end
									addTextArea(table.unpack(v))
								end
							end
						else
							if not info[3] then
								info[3] = 'nil'
							end
							textAreas[info[3]..'_'..info[1]] = {...}
							ui.addTextArea(...)
						end
					end,
					['update'] = function(id, mod, name)
						if not name then
							name = 'nil'
						end
						if not textAreas[name..'_'..id] then
							return
						elseif type(mod) == 'string' then
							ui.updateTextArea(id, mod, name)
							textAreas[name..'_'..id][2] = mod
							return
						end
						local names = {text = 2, x = 4, y = 5, w = 6, h = 7, background = 8, border = 9, alpha = 10, fixed = 11}
						for i, v in next, mod do
							if names[i] then
								textAreas[name..'_'..id][names[i]] = v
							end
						end
						local m = textAreas[name..'_'..id]
						ui.addTextArea(m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11])
					end,
					['remove'] = function(id, name)
						if not name then
							name = 'nil'
						end
						if textAreas[name..'_'..id] then
							textAreas[name..'_'..id] = nil
						end
						ui.removeTextArea(id, name)
					end
				},
				['string-to-boolean'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['parse'] = function(tableC)
						local finalTable = {}
						for i, v in next, tableC do
							finalTable[v] = true
						end
						return finalTable
					end
				},
				['database'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.1', dependencies = {},
					['create'] = function(username, tab)
						if not db[username] then
							db[username] = tab
						end
					end,
					['delete'] = function(username)
						db[username] = nil
					end,
					['get'] = function(username, ...)
						local ret, args = {}, {...}
						if not args[1] then
							return db[username]
						else
							for i, v in next, args do
								if db[username][v] then
									ret[#ret + 1] = db[username][v]
								end
							end
							return table.unpack(ret)
						end
					end,
					['set'] = function(username, ...)
						local add = v
						for i, v in next, {...} do
							if not add then
								add = v
							else
								db[username][add] = v
								add = false
							end
						end
					end
				},
				['encryption'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['encrypt'] = function(tableC, password, password2)
						if not tableC or not password or not password2 or type(tableC) ~= 'table' or password == '' or password2 == '' then return end
						local initSeed, finalString, newMessage, key = '', '', '', ''
						for i in password:gmatch('.') do
							initSeed = initSeed..i:byte()
						end
						for i in password2:gmatch('.') do
							key = key..i:byte()
						end
						math.randomseed(initSeed)
						otherSeed = math.random(1000000)
						local action = pcall(function()
							for i, v in next, tableC do
								if type(v) == 'string' or type(v) == 'number' then
									if type(v) == 'string' then
										v = "'"..v.."'"
									end
									newMessage = newMessage..' '..v..' '..i:upper()
								else
									return
								end
							end
							newMessage = newMessage..' '..key
							for i in newMessage:gmatch('.') do
								local newByte = i:byte() + 68 + math.random(5)
								otherSeed = otherSeed + i:byte()
								math.randomseed(otherSeed)
								if (newByte >= 65 and newByte <= 122) and not (newByte >= 91 and newByte <= 96) then
									newByte = string.char(newByte)
								end
								finalString = finalString..newByte
							end
						end)
						math.randomseed(os.time())
						if not action then
							return
						else
							return finalString
						end
					end,
					['decrypt'] = function(stringC, password, password2)
						if not stringC or not password or not password2 or type(stringC) ~= 'string' or password == '' or password2 == '' then return end
						local initSeed, finalString, aByte, key = '', '', '', ''
						for i in password:gmatch('.') do
							initSeed = initSeed..i:byte()
						end
						for i in password2:gmatch('.') do
							key = key..i:byte()
						end
						math.randomseed(initSeed)
						otherSeed = math.random(1000000)
						local action = pcall(function()
							for i in stringC:gmatch('.') do
								if i:byte() >= 65 and i:byte() <= 122 then
									local newByte = i:byte() - 68 - math.random(5)
									otherSeed = otherSeed + newByte
									math.randomseed(otherSeed)
									finalString = finalString..string.char(newByte)
								else
									aByte = aByte..i
									if aByte:len() >= 3 then
										local newByte = tonumber(aByte) - 68 - math.random(5)
										otherSeed = otherSeed + newByte
										math.randomseed(otherSeed)
										finalString = finalString..string.char(newByte)
										aByte = ''
									end
								end
							end
						end)
						math.randomseed(os.time())
						if not action then
							return
						else
							local finalTable, stage, fsLength, aString, aNumber = {}, 0, 0
							for i, v in string.gmatch(finalString, '[^%s]+') do
								fsLength = fsLength + 1
							end
							for i, v in string.gmatch(finalString, '[^%s]+') do
								stage = stage + 1
								if stage == fsLength and i ~= key then
									return
								elseif aString then
									if aString:sub(-1) == "'" then
										finalTable[i:lower()] = aString:gsub("'", '')
										aString = nil
									else
										aString = aString..' '..i
									end
								elseif aNumber then
									finalTable[i:lower()] = aNumber
									aNumber = nil
								elseif i:sub(1, 1) == "'" then
									aString = i
								else
									aNumber = i
								end
							end
							return finalTable
						end
					end
				},
				['sleep'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.1', dependencies = {},
					['loop'] = function()
						local toRemove = {}
						for i, v in next, coroutines do
							if not v[2] or v[2] < os.time() then
								if (coroutine.status(v[1]) == 'dead') then
									toRemove[#toRemove+1] = i
								else
									local s, timerV = coroutine.resume(v[1])
									v[2] = timerV
								end
							end
						end
						if (toRemove[1]) then
							for i, v in next, toRemove do
								coroutines[v] = nil
							end
						end
					end,
					['run'] = function(f, checkTimer)
						if not checkTimer then checkTimer = 500 end
						coroutines[#coroutines + 1] = {coroutine.create(function()
							local pause = function(n)
								coroutine.yield(os.time() + math.floor(n/checkTimer)*checkTimer)
							end
							f(pause)
						end), timeValue = nil}
					end
				},
				['wait-time'] = { AUTHOR = 'Nettoork#0000', _VERSION = '1.0', dependencies = {},
					['check'] = function(section, subsection, delay, start)
						if section and subsection then
							if not wait[section] then wait[section] = {} end
							if not wait[section][subsection] then start = 0 wait[section][subsection] = os.time() + (delay or 1000) end
							if wait[section][subsection] <= os.time() or start and start == 0 then
								wait[section][subsection] = os.time() + (delay or 1000)
								return true
							else
								return false
							end
						end

					end
				},
				['json'] = { AUTHOR = 'https://github.com/rxi', _VERSION = '0.1.1', dependencies = {},
					['encode'] = function(val)
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
						for k, v in pairs(escape_char_map) do
							escape_char_map_inv[v] = k
						end
						local function escape_char(c)
							return escape_char_map[c] or string.format("\\u%04x", c:byte())
						end
						local function encode_nil(val)
							return "null"
						end
						local function encode_table(val, stack)
						local res = {}
						stack = stack or {}
						if stack[val] then error("circular reference") end
						stack[val] = true
						if val[1] ~= nil or next(val) == nil then
							local n = 0
							for k in pairs(val) do
								if type(k) ~= "number" then
									error("invalid table: mixed or invalid key types")
								end
								n = n + 1
							end
							if n ~= #val then
								error("invalid table: sparse array")
							end
							for i, v in ipairs(val) do
								table.insert(res, encode(v, stack))
							end
							stack[val] = nil
							return "[" .. table.concat(res, ",") .. "]"
						else
							for k, v in pairs(val) do
								if type(k) ~= "string" then
									error("invalid table: mixed or invalid key types")
								end
									table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
								end
								stack[val] = nil
								return "{" .. table.concat(res, ",") .. "}"
							end
						end
						local function encode_string(val)
							return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
						end
						local function encode_number(val)
							if val ~= val or val <= -math.huge or val >= math.huge then
								error("unexpected number value '" .. tostring(val) .. "'")
							end
							return val
						end
						local type_func_map = {
						[ "nil"     ] = encode_nil,
						[ "table"   ] = encode_table,
						[ "string"  ] = encode_string,
						[ "number"  ] = encode_number,
						[ "boolean" ] = tostring,
						}
						encode = function(val, stack)
							local t = type(val)
							local f = type_func_map[t]
							if f then
								return f(val, stack)
							end
							error("unexpected type '" .. t .. "'")
						end
						return encode(val)
					end,
					['decode'] = function(str)
						local parse
						local escape_char_map_inv = { [ "\\/" ] = "/" }
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
							if set[str:sub(i, i)] ~= negate then
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
							if str:sub(i, i) == "\n" then
							  line_count = line_count + 1
							  col_count = 1
							end
						  end
						  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
						end
						local function codepoint_to_utf8(n)
						  local f = math.floor
						  if n <= 0x7f then
							return string.char(n)
						  elseif n <= 0x7ff then
							return string.char(f(n / 64) + 192, n % 64 + 128)
						  elseif n <= 0xffff then
							return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
						  elseif n <= 0x10ffff then
							return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
											   f(n % 4096 / 64) + 128, n % 64 + 128)
						  end
						  error( string.format("invalid unicode codepoint '%x'", n) )
						end
						local function parse_unicode_escape(s)
						  local n1 = tonumber( s:sub(3, 6),  16 )
						  local n2 = tonumber( s:sub(9, 12), 16 )
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
							local x = str:byte(j)
							if x < 32 then
							  decode_error(str, j, "control character in string")
							end
							if last == 92 then
							  if x == 117 then
								local hex = str:sub(j + 1, j + 5)
								if not hex:find("%x%x%x%x") then
								  decode_error(str, j, "invalid unicode escape in string")
								end
								if hex:find("^[dD][89aAbB]") then
								  has_surrogate_escape = true
								else
								  has_unicode_escape = true
								end
							  else
								local c = string.char(x)
								if not escape_chars[c] then
								  decode_error(str, j, "invalid escape char '" .. c .. "' in string")
								end
								has_escape = true
							  end
							  last = nil
							elseif x == 34 then
							  local s = str:sub(i + 1, j - 1)
							  if has_surrogate_escape then
								s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
							  end
							  if has_unicode_escape then
								s = s:gsub("\\u....", parse_unicode_escape)
							  end
							  if has_escape then
								s = s:gsub("\\.", escape_char_map_inv)
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
						  local s = str:sub(i, x - 1)
						  local n = tonumber(s)
						  if not n then
							decode_error(str, i, "invalid number '" .. s .. "'")
						  end
						  return n, x
						end
						local function parse_literal(str, i)
						  local x = next_char(str, i, delim_chars)
						  local word = str:sub(i, x - 1)
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
							if str:sub(i, i) == "]" then
							  i = i + 1
							  break
							end
							x, i = parse(str, i)
							res[n] = x
							n = n + 1
							i = next_char(str, i, space_chars, true)
							local chr = str:sub(i, i)
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
							if str:sub(i, i) == "}" then
							  i = i + 1
							  break
							end
							if str:sub(i, i) ~= '"' then
							  decode_error(str, i, "expected string for key")
							end
							key, i = parse(str, i)
							i = next_char(str, i, space_chars, true)
							if str:sub(i, i) ~= ":" then
							  decode_error(str, i, "expected ':' after key")
							end
							i = next_char(str, i + 1, space_chars, true)
							val, i = parse(str, i)
							res[key] = val
							i = next_char(str, i, space_chars, true)
							local chr = str:sub(i, i)
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
						  local chr = str:sub(idx, idx)
						  local f = char_func_map[chr]
						  if f then
							return f(str, idx)
						  end
						  decode_error(str, idx, "unexpected character '" .. chr .. "'")
						end
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
				}

			}
			local lastUpdate =  1547917483395 + 2628*10^6 -- 15:05 | 19/01/2019
			require = function(libName)
				if libName == 'hide-warning' then
					lastUpdate = false
				else
					if lastUpdate and os.time() > lastUpdate then
						lastUpdate = false
						print("<R>Warning! You may be using an outdated version of require, check in <i>atelier801.com/topic?f=6&t=880333</i> if this has a better version, otherwise you can disable this warning with require('hide-warning').</R>")
					end
					if libs[libName] then
						if libs[libName]['INIT_SCRIPT'] and type(libs[libName]['INIT_SCRIPT']) == 'function' then
							libs[libName]['INIT_SCRIPT']()
							libs[libName]['INIT_SCRIPT'] = nil
						end
						return libs[libName]
					elseif libName == 'libs' then
						return libs
					else
						print('Library "'..libName..'" not found! <i>Require Version: 1.2.2 | Author: Nettoork#0000</i>')
						return false
					end
				end
			end
		end
		--[[ End of file tech/require-lib/init.lua ]]--
		--[[ End of package tech/require-lib ]]--
		--[[ File modes/freezertag/init.lua ]]--
		require("hide-warning")

		local stable = require("string-to-boolean").parse
		local wait = require("wait-time").check
		local sleep = require("sleep")

		local admins = {"Nettoork#0000", "Tocutoeltuco#0000"}
		admins = stable(admins)

		local config = {
			freezer_radius = 50;
			unfreezer_radius = 70;
			start_hp = 3;
			hp_chance = 30;
			players_per_freezers = 10;
			freezer_delay = 2000;
			unfreezer_delay = 15000;
			game_time = 170;
			max_players = 25;
			object_start_id = 100000;
			select_freezers_time = 10000;
			end_game_time = 30000;
			min_moving_players = 5;
		}


		local maps = {4675995, 4391574, 6166453, 2241886, 4412155, 4440887, 4737903, 4716310, 3704277, 4447699, 4650301, 5208188, 4137198, 4404369, 4388705, 4565774, 4738138, 5377664, 4789606, 4412126, 4830225, 4547683, 4360147, 3683632, 7243771, 7159670, 7647688, 7134009, 3322416, 2434771, 6923268, 6865350, 6808085, 6202454, 6109514, 3367828, 2064173, 5020313, 4081307, 4787601, 4743573, 7647551, 4529713, 7647472, 7647541, 7647493, 7647497, 7647498, 7647514, 7647519, 7647524, 7647591, 7647557, 7647594, 7647598, 7647601, 7647604, 7647611, 7647776, 7647826, 7659231, 7659238, 7659239, 7659241, 7659320, 7659325, 7659444, 7659327, 7659328, 7659329, 7659330, 7659334, 7659336, 7659447, 7659340, 7659341, 7659345, 7659429, 7659433, 7659441}

		local cache = {}
		local db = {}
		local game = {}
		local banned_players = {}

		tfm.exec.setRoomMaxPlayers(config.max_players)

		local function reset_game()
			game = {
				players = {};
				freezers = {};
				freezed = {};
				unfreezer_alive = 0;
				freezer_alive = 0;
				ending = false;
				started = false;
				potencial_players = {};
				give_cheese = false;
				set_freezers = false;
			}
		end

		local split = function(t, s)
			local a={}
			for i in string.gmatch(t, "[^" .. (s or "%s") .. "]+") do
				a[#a + 1] = i
			end
			return a
		end

		local function translate(message)
			return translations[config.room_language] and translations[config.room_language][message] or translations[config.room_language][message]
		end

		local function freeze(freezer_name)
			for name, data in next, tfm.get.room.playerList do
				local freezer = tfm.get.room.playerList[freezer_name]

				if math.abs(data.x - freezer.x) <= config.freezer_radius and math.abs(data.y - freezer.y) <= config.freezer_radius then
					if not game.freezers[name] and not data.isDead then
						if wait("player_freeze", freezer_name, config.freezer_delay, false) then
							tfm.exec.killPlayer(name)
							game.freezed[name] = tfm.exec.addShamanObject(54, data.x, data.y, 0, 0, 0, false)

							translatedChatMessage("freezed", name)

							if game.players[name].hp > 0 then
								updateLife(name, -1)
							end

							if game.players[name].hp < 1 then
								translatedChatMessage("noLife", name)
								translatedChatMessage("nowPopsicle", nil, name)
							else
								translatedChatMessage("freezedLife", name, game.players[name].hp)
							end
							tfm.exec.setNameColor(freezer_name, 0x009DFF)
						end
						break
					end
				end
			end
		end

		local function unfreeze(unfreezer_name)
			local noLife

			for name, id in next, game.freezed do
				local object = tfm.get.room.objectList[id]
				local unfreezer = tfm.get.room.playerList[unfreezer_name]

				if math.abs(object.x - unfreezer.x) <= config.unfreezer_radius and math.abs(object.y - unfreezer.y) <= config.unfreezer_radius then
					if game.players[name].hp > 0 then
						if wait("player_freeze", unfreezer_name, config.unfreezer_delay, false) then
							game.players[name].x = object.x
							game.players[name].y = object.y

							tfm.exec.removeObject(id)
							ui.removeTextArea(config.object_start_id + id)

							tfm.exec.respawnPlayer(name)
							translatedChatMessage("unfreezed", name, unfreezer_name)
							db[name].chance = db[name].chance + 1

							local lucky = math.random(100)
							if lucky <= 15 then
								translatedChatMessage("gotHp", unfreezer_name, name)
								updateLife(unfreezer_name, 1)
							else
								translatedChatMessage("unfreezedsomeone", unfreezer_name, name)
							end

							game.freezed[name] = nil
						end
					else
						noLife = true
					end
					break
				end
			end

			if noLife then
				translatedChatMessage("playerWithoutLife", unfreezer_name)
			end
		end

		function change_map()
			if #cache == 0 then
				for index, map in next, maps do
					cache[#cache + 1] = map
				end
			end
			tfm.exec.newGame(table.remove(cache, math.random(#cache)), math.random(1, 5) == 1 and true or false)
		end

		function updateLife(name, to_inc)
			if to_inc then
				game.players[name].hp = game.players[name].hp + to_inc
			end

			local hp = game.players[name].hp
			tfm.exec.setPlayerScore(name, hp, false)

			for i, v in next, game.players[name].lifes do
				tfm.exec.removeImage(v)
			end

			if hp > 0 then
				for i = 1, hp do
					game.players[name].lifes[#game.players[name].lifes + 1] = tfm.exec.addImage('1674802a592.png', ':1', 5 + (28 * (i - 1)), 23, name)
				end
			end
		end

		onEvent("NewGame", function()
			tfm.exec.setGameTime(config.game_time)

			if game and game.freezed then
				for i, id in next, game.freezed do
					ui.removeTextArea(config.object_start_id + id)
				end
			end

			reset_game()
			ui.removeTextArea(1)

			for name, data in next, tfm.get.room.playerList do
				game.players[name] = {
					hp = 3;
					lifes = {};
				}

				tfm.exec.setPlayerScore(name, game.players[name].hp, false)
				tfm.exec.setNameColor(name, 0xB5B5B5)
				game.unfreezer_alive = game.unfreezer_alive + 1

				if banned_players[name] then
					tfm.exec.killPlayer(name)
					updateLife(name, game.players[name] * -1)
				else
					updateLife(name)
				end
			end
		end)

		function updateChance(name, chance)
			local c = ("%.2d"):format(chance)
			c = tonumber(c:find("0") == 1 and c:sub(2) or c)

			if c < 0 then
				c = 0
			end

			ui.addTextArea(1, translatedMessage("chance", name, tostring(c)).."%", name, 10, 380, 0, 0, 1, 1, 0, true)
		end

		onEvent("Loop", function(s, r)
			if not game.set_freezers and s >= config.select_freezers_time and s <= config.select_freezers_time+2000 then
				game.set_freezers = true
				local total_chance, total_data = 0, 0

				local pont = 0

				for name, data in next, game.potencial_players do
					pont = pont + 1
				end

				local isdead = {}

				for name, data in next, tfm.get.room.playerList do
					if pont >= config.min_moving_players and  not game.potencial_players[name] and not data.isDead then
						tfm.exec.killPlayer(name)
						isdead[name] = true
					else
						total_data = total_data + 1
						total_chance = total_chance + db[name].chance
					end
				end

				local players = {}

				for name, data in next, tfm.get.room.playerList do
					if not data.isDead and not isdead[name] then
						players[#players + 1] = name
					end
				end

				local p = math.floor(#players/config.players_per_freezers) + 1
				for i = 1, p do
					local rand = math.random() * total_chance

					local found = false

					while not found do
						for id, name in next, players do
							if rand < db[name].chance then
								total_chance = total_chance - db[name].chance
								game.freezers[#game.freezers + 1] = table.remove(players, id)
								game.unfreezer_alive = game.unfreezer_alive - 1
								game.freezer_alive = game.freezer_alive + 1
								db[name].chance = 1
								ui.removeTextArea(1, name)
								found = true
								break
							else
								rand = rand - db[name].chance
							end
						end
					end
				end

				if #game.freezers <= 0 then
					return change_map()
				end

				game.freezers = stable(game.freezers)

				for name, data in next, tfm.get.room.playerList do
					if not data.isDead then
						if game.freezers[name] then
							translatedChatMessage("are_freezer", name)
							tfm.exec.setNameColor(name, 0x009DFF)
							updateLife(name, game.players[name].hp * -1)
						else
							db[name].chance = db[name].chance + 1
							total_chance = total_chance + 1
							translatedChatMessage("are_unfreezer", name, config.start_hp)
						end
					end
				end

				for name, data in next, db do
					if not game.freezers[name] then
						updateChance(name, data.chance*100/total_chance)
					end
				end

				game.started = true
			elseif not game.give_cheese and r >= config.end_game_time and r <= config.end_game_time+2000 and game.unfreezer_alive > 0 then
				game.give_cheese = true
				end_game(false)
			elseif game.freezer_alive and (r <= 0 or (game.freezer_alive <= 0 and game.unfreezer_alive <= 0)) then
				change_map()
			end

			if game.ending then
				for name in next, admins do
					local p = tfm.get.room.playerList[name]
					if p and not p.isDead and not game.freezers[name] then
						tfm.exec.setNameColor(name, math.random(0x000000, 0xFFFFFF))
					end
				end
			elseif not game.started then
				for name, data in next, tfm.get.room.playerList do
					if not data.isDead and (data.movingLeft or data.movingRight or data.isJumping) then
						game.potencial_players[name] = data
					end
				end
			end

			if game.freezed then
				for name, id in next, game.freezed do
					local object = tfm.get.room.objectList[id]

					if object and game.players[name].hp > 0 then
						ui.addTextArea(config.object_start_id + id, "<B><font color='#000000'>" .. name .. "</font></B>\n<p align='center'><B><R>"..game.players[name].hp.." hp</R></B>", nil, object.x - (string.len(name) * 4), object.y - 10, 0, 0, 1, 1, 0, false)
					else
						game.freezed[name] = nil
						ui.removeTextArea(config.object_start_id + id)
						break
					end
				end
			end
		end)

		function end_game(freezers_won)
			if not game.ending then
				game.ending = true

				if freezers_won then
					for name, data in next, tfm.get.room.playerList do
						if not data.isDead and game.freezers[name] then
							tfm.exec.giveCheese(name)
						end
					end
				else
					for name, data in next, tfm.get.room.playerList do
						if not data.isDead and not game.freezers[name] then
							tfm.exec.giveCheese(name)
						end
					end
				end

				for name in next, game.players do
					updateLife(name, game.players[name].hp * -1)
				end

				local ids = {}

				for i, v in next, tfm.get.room.objectList do
					ids[#ids + 1] = v.id
				end
				for i, v in next, ids do
					tfm.exec.removeObject(v)
				end

				for i, id in next, game.freezed do
					ui.removeTextArea(config.object_start_id + id)
				end

				game.freezed = {}
				tfm.exec.setGameTime(30)
			end
		end

		function check_players(name, died)
			if not game.freezers[name] then
				game.unfreezer_alive = game.unfreezer_alive + (died and -1 or 1)

				if game.unfreezer_alive <= 0 then
					return end_game(true)
				end
			else
				game.freezer_alive = game.freezer_alive + (died and -1 or 1)
				game.freezers[name] = nil

				for _ in next, game.freezers do
					return
				end

				return end_game()
			end

			if game.freezer_alive <= 0 and game.unfreezer_alive <= 0 then
				return change_map()
			end
		end

		onEvent("Keyboard", function(name, key, down, x, y)
			if key == 32 then
				if not tfm.get.room.playerList[name].isDead and not game.ending then
					if wait("wait_keyboard", name, 1000, false) then
						if game and game.freezers and game.freezers[name] then
							freeze(name)
						else
							unfreeze(name)
						end
					end
				end
			end
		end)

		onEvent("PlayerDied", function(name)
			check_players(name, true)
		end)

		onEvent("PlayerLeft", function(name)
			if game.players[name] then
				game.players[name].hp = 0
			end
		end)

		onEvent("PlayerWon", function(name)
			check_players(name, true)
			db[name].chance = db[name].chance + 5
		end)

		onEvent("PlayerRespawn", function(name)
			check_players(name)

			if game.players[name].x then
				tfm.exec.movePlayer(name, game.players[name].x, game.players[name].y)
			end
		end)

		onEvent("NewPlayer", function(name)
			tfm.exec.bindKeyboard(name, 32, true, true)
			tfm.exec.lowerSyncDelay(name)

			db[name] = {
				chance = 1;
			}

			translatedChatMessage("welcome", name)
		end)

		onEvent("ChatCommand", function(name, command)
			local arg = split(command, " ")

			if admins[name] then
				if arg[1] == 'ban' and arg[2] then
					if banned_players[arg[2]] then
						tfm.exec.chatMessage('ERROR', name)
					else
						translatedChatMessage("player_banned", nil, arg[2])
						banned_players[arg[2]] = true
						tfm.exec.killPlayer(arg[2])
					end
				elseif arg[1] == 'unban' and arg[2] then
					if banned_players[arg[2]] then
						translatedChatMessage("player_unbanned", nil, arg[2])
						banned_players[arg[2]] = nil
					else
						tfm.exec.chatMessage('ERROR', name)
					end
				end
			end

		end)

		for index, value in next, {'AutoShaman', 'AutoNewGame', 'AutoTimeLeft', 'AutoScore', 'PhysicalConsumables', 'DebugCommand', 'MinimalistMode'} do
			tfm.exec['disable' .. value]()
		end

		change_map()
		--[[ End of file modes/freezertag/init.lua ]]--
		--[[ End of package modes/freezertag ]]--
	elseif submode == "rocketlaunch" then
		--[[ Package modes/rocketlaunch ]]--
		--[[ Directory translations/rocketlaunch ]]--
		--[[ File translations/rocketlaunch/en.lua ]]--
		translations.en = {
			you_are_shaman = "<VP>You are the shaman! Build a rocket to reach the space and save the crew members!</VP>",
			you_are_crew_member = "<VP>You are a crewman! Wait for the Shaman to build his rocket to reach the space!</VP>",
			welcome = "<D>Welcome to #rocketlaunch. The goal is to reach the space, so the shaman must build a ROCKET!</D>\n<CE>Credits for the original idea: Kralizmox#0000.</CE>",
			remvove_floor = "<p align='center'><font size='20'><R>Removing the floor in %d seconds</R></font></p>"
		}
		--[[ End of file translations/rocketlaunch/en.lua ]]--
		--[[ File translations/rocketlaunch/br.lua ]]--
		translations.br = {
			you_are_shaman = "<VP>Você é o shaman! Construa um foguete para alcançar o espaço e salvar a tripulação!</VP>",
			you_are_crew_member = "<VP>Você é um tripulante! Aguarde o shaman construir seu foguete para chegar ao espaço!</VP>",
			welcome = "<D>Seja bem-vindo(a) ao #rocketlaunch. Seu objetivo é chegar ao espaço, para isso, o shaman deverá construir um FOGUETE!</D>\n<CE>Créditos pela ideia original: Kralizmox#0000.</CE>",
			remvove_floor = "<p align='center'><font size='20'><R>Removendo o chão em %d segundos</R></font></p>"
		}
		--[[ End of file translations/rocketlaunch/br.lua ]]--
		--[[ End of directory translations/rocketlaunch ]]--
		--[[ File modes/rocketlaunch/init.lua ]]--
		function parseTable(tb)
			local finalTable = {}
			for i, v in next, tb do
				finalTable[v] = true
			end
			return finalTable
		end

		local game = {
			items = {
				{1, 3},
				{1, 2, 3, 4},
				{2, 2, 4, 4, 10},
				{2, 4, 10, 10, 40}
			},
			config = {
				map = '<C><P H="2000" /><Z><S><S P="0,0,0.3,0.2,0,0,0,0" L="300" o="324650" X="1000" c="2" Y="700" T="12" H="2600" /><S H="2600" L="300" o="324650" X="-200" c="2" Y="700" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S H="400" L="3000" o="2a40" X="400" c="4" Y="200" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S H="400" L="3000" o="56b8ea" X="400" c="4" Y="1800" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="3db0eb" X="400" c="4" Y="1400" T="12" H="400" /><S P="0,0,0.3,0.2,720,0,0,0" L="3000" lua="-1" H="40" c="3" Y="1980" T="6" X="400" /><S H="400" L="3000" o="1fa2e6" X="400" c="4" Y="1000" T="12" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="16395" X="400" c="4" Y="600" T="12" H="400" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="99" c="4" Y="1187" T="13" H="10" /><S H="10" L="40" o="ffffff" X="127" c="4" Y="1168" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="170" c="4" Y="1169" T="13" H="10" /><S H="10" L="40" o="ffffff" X="214" c="4" Y="1178" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="188" c="4" Y="1208" T="13" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="140" c="4" Y="1208" T="13" H="10" /><S H="10" L="40" o="ffffff" X="229" c="4" Y="1192" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="686" c="4" Y="981" T="13" H="10" /><S H="10" L="40" o="ffffff" X="662" c="4" Y="1028" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="706" c="4" Y="1018" T="13" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="40" o="ffffff" X="635" c="4" Y="990" T="13" H="10" /><S H="10" L="40" o="ffffff" X="607" c="4" Y="1018" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S H="10" L="30" o="ffffff" X="618" c="4" Y="1354" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="30" o="ffffff" X="600" c="4" Y="1338" T="13" H="10" /><S H="10" L="30" o="ffffff" X="593" c="4" Y="1365" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="30" o="ffffff" X="566" c="4" Y="1343" T="13" H="10" /><S H="10" L="30" o="ffffff" X="559" c="4" Y="1362" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,0,0,0,0" L="42" o="1c1c1c" X="240" c="4" Y="341" T="13" H="10" /><S P="0,0,0.3,0.2,140,0,0,0" L="244" o="1f1f1f" X="241" c="4" Y="343" T="12" H="32" /><S H="17" L="230" o="979797" X="241" c="4" Y="343" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="219" c="4" Y="361" T="12" H="12" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="263" c="4" Y="325" T="12" H="12" /><S H="10" L="36" o="323232" X="241" c="4" Y="342" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S H="10" L="10" o="969696" X="249" c="4" Y="323" T="13" P="0,0,0.3,0.2,0,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="167" c="4" Y="405" T="12" H="12" /><S H="12" L="30" o="c0c0c0" X="193" c="4" Y="383" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S P="0,0,0.3,0.2,140,0,0,0" L="30" o="c0c0c0" X="315" c="4" Y="281" T="12" H="12" /><S H="12" L="30" o="c0c0c0" X="289" c="4" Y="303" T="12" P="0,0,0.3,0.2,140,0,0,0" /><S H="10" L="10" o="ffffff" X="73" c="4" Y="-95" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="395" c="4" Y="-183" T="12" H="10" /><S H="10" L="10" o="ffffff" X="738" c="4" Y="-269" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="637" c="4" Y="-89" T="12" H="10" /><S H="10" L="10" o="ffffff" X="221" c="4" Y="-298" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="496" c="4" Y="-366" T="12" H="10" /><S H="10" L="10" o="ffffff" X="100" c="4" Y="-410" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="563" c="4" Y="319" T="12" H="10" /><S H="10" L="10" o="ffffff" X="451" c="4" Y="192" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="65" c="4" Y="250" T="12" H="10" /><S H="10" L="10" o="ffffff" X="206" c="4" Y="136" T="12" P="0,0,0.3,0.2,45,0,0,0" /><S P="0,0,0.3,0.2,45,0,0,0" L="10" o="ffffff" X="701" c="4" Y="124" T="12" H="10" /><S P="0,0,0.3,0.2,0,0,0,0" L="3000" o="1018" X="400" c="3" Y="-400" T="12" H="800" /><S X="400" L="3000" lua="-2" H="40" c="2" Y="1980" T="6" P="0,0,10,0,720,0,0,0" /></S><D><T Y="32" D="" X="399" /><T Y="32" D="" X="27" /><T Y="32" D="" X="778" /><T Y="32" D="" X="589" /><T Y="32" D="" X="204" /><F Y="30" D="" X="203" /><F Y="30" D="" X="26" /><F Y="30" D="" X="399" /><F Y="30" D="" X="588" /><F Y="30" D="" X="776" /><DS Y="1947" X="400" /></D><O /></Z></C>',
				max_players = 25,
				game_time = 300,
				forbidden_items = parseTable({17, 32, 1700, 1701, 1702, 1703, 1704})
			},
			objects = {},
			current_shaman = nil,
			change_map = false,
			remove_object = true
		}

		tfm.exec.setRoomMaxPlayers(game.config.max_players)

		onEvent("Loop", function(start_time, remaining)
			local has_player_alive = false
			local most_long_Y = 0

			for name, data in next, tfm.get.room.playerList do
				local y = math.abs(data.y - 1947)

				if data.isShaman and start_time >= 15000  then
					if data.isDead then
						if not game.change_map then
							game.change_map = true

							if y <= 400 then
								tfm.exec.setGameTime(20)
								ui.removeTextArea(1)
							end
						end
					elseif not game.change_map then
						if y >= 600 then
							tfm.exec.setShaman(name, false)
							game.change_map = true
						end
					end
				end

				if not data.isDead then
					has_player_alive = true
					tfm.exec.changePlayerSize(name, 1)

					if most_long_Y < y then
						most_long_Y = y
					end
				end
			end

			if not has_player_alive or remaining <= 0 then
				tfm.exec.newGame(game.config.map)
				return
			end

			if remaining >= 183000 then
				ui.addTextArea(1, translatedMessage("remvove_floor", nil, math.floor(remaining/1000) - 180), nil, 5, 1760, 800, 40, 1, 1, 0, false)
			elseif remaining >= 181000 then
				for name, data in next, tfm.get.room.playerList do
					if not data.isDead and data.isShaman then
						tfm.exec.setShaman(name, false)
					end
				end

				ui.removeTextArea(1)
				tfm.exec.removePhysicObject(-1)
				tfm.exec.removePhysicObject(-2)
			end

			if most_long_Y >= 500 and start_time >= 15000 then
				local itemId = math.floor(most_long_Y/400)
				local item = game.items[itemId]

				if item then
					if game.remove_object then
						tfm.exec.removePhysicObject(-2)
						game.remove_object = false
					end

					for i = 1, 2 do
						game.objects[#game.objects + 1] = {time = os.time() + 15000, id = tfm.exec.addShamanObject(item[math.random(#item)], math.random(-100, 900), -200)}
					end
				end

				local objects = game.objects
				for id, data in next, objects do
					if os.time() > data.time then
						table.remove(game.objects, id)
						tfm.exec.removeObject(data.id)
					end
				end
			end
		end)

		onEvent("NewGame", function()
			tfm.exec.setGameTime(game.config.game_time)
			game.change_map = false
			game.remove_object = true
			game.objects = {}

			for name, data in next, tfm.get.room.playerList do
				if data.isShaman then
					tfm.exec.setShamanMode(name, 1)
					translatedChatMessage("you_are_shaman", name)
				else
					translatedChatMessage("you_are_crew_member", name)
				end
			end
		end)

		onEvent("SummoningStart", function(name, itemType)
			if game.config.forbidden_items[itemType] then
				tfm.exec.setShamanMode(name, 1)
			end
		end)

		onEvent("SummoningEnd", function(name, itemType, x, y, ang, data)
			if game.config.forbidden_items[itemType] then
				tfm.exec.removeObject(data.id)
			end
		end)

		onEvent("NewPlayer", function(name)
			translatedChatMessage("welcome", name)
		end)

		for index, value in next, {'AutoNewGame', 'AutoTimeLeft', 'PhysicalConsumables', 'DebugCommand', 'MinimalistMode', 'AllShamanSkills'} do
			tfm.exec['disable' .. value]()
		end

		tfm.exec.newGame(game.config.map)
		--[[ End of file modes/rocketlaunch/init.lua ]]--
		--[[ End of package modes/rocketlaunch ]]--
	elseif submode == "maps" then
		--[[ Package modes/maps ]]--
		--[[ Package modes/parkour ]]--
		--[[ Directory translations/parkour ]]--
		--[[ File translations/parkour/ru.lua ]]--
		translations.ru = {
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
			help_help = "<p align = 'center'><font size = '14'>Добро пожаловать в <T>#parkour!</T></font>\n\n<font size = '12'><J>Ваша цель - собрать все чекпоинты, чтобы завершить карту.</J></font></p>\n\n<font size = '11'><N>• Нажмите <O>O</O>, введите <O>!op</O> или нажмите на <O> шестеренку</O> чтобы открыть <T>меню настроек</T>.\n• Нажмите <O>P</O> или нажмите на <O>руку</O> в правом верхнем углу, чтобы открыть <T>меню со способностями</T>.\n• Нажмите <O>L</O> или введите <O>!lb</O> чтобы открыть <T>Список лидеров</T>.\n• Нажмите <O>M</O> или <O>Delete</O> чтобы не прописывать <T>/mort</T>.\n• Чтобы узнать больше о нашей <O>команде</O> и о <O>правилах паркура</O>, нажми на <T>Команда</T> и <T>Правила</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Вкладки теперь открыты! Для получения более подробной информации, нажмите на вкладку <O>Содействие</O> !</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>ОБЯЗАННОСТИ: Команда Паркура НЕ команда Transformice и НЕ имеет никакой власти в самой игре, только внутри модуля.</r>\nКоманда Parkour обеспечивают исправную работу модуля с минимальными проблемами и всегда готова помочь игрокам в случае необходимости.</font></p>\nВы можете ввести <D>!staff</D> в чат, чтобы увидеть нашу команду.\n\n<font color = '#E7342A'>Администраторы:</font> Hесут ответственность за поддержку самого модуля, добавляя новые обновления и исправляя ошибки.\n\n<font color = '#843DA4'>Руководители команд:</font> Kонтролируют команды модераторов и картостроителей, следя за тем, чтобы они хорошо выполняли свою работу. Они также несут ответственность за набор новых членов в команду.\n\n<font color = '#FFAAAA'>Модераторы:</font> Hесут ответственность за соблюдение правил модуля и наказывают тех, кто не следует им.\n\n<font color = '#25C059'>Картостроители:</font> Oтвечают за просмотр, добавление и удаление карт в модуле, обеспечивая вам приятный игровой процесс.",
			help_rules = "<font size = '13'><B><J>Все правила пользователя и условия Transformice также применяются к #parkour </J></B></font>\n\nЕсли вы обнаружили, что кто-то нарушает эти правила, напишите нашим модераторам. Если модераторов нет в сети, вы можете сообщить об этом на на нашем сервере в Discord\nПри составлении репорта, пожалуйста, укажите сервер, имя комнаты и имя игрока.\n• Пример: en-#parkour10 Blank#3495 троллинг\nДоказательства, такие как скриншоты, видео и гифки, полезны и ценны, но не обязательны.\n\n<font size = '11'>• <font color = '#ef1111'>читы, глюки или баги</font> не должны использоваться в комнатах #parkour\n• <font color = '#ef1111'>Фарм через VPN</font> считается <B>нарушением</B> и не допускается. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nЛюбой, кто пойман за нарушение этих правил, будет немедленно забанен.</B></font></p>\n\n<font size = '12'>Transformice позволяет концепцию троллинга. Однако, <font color='#cc2222'><B>мы не допустим этого в паркуре.B></font></font>\n\n<p align = 'center'><J>Троллинг - это когда игрок преднамеренно использует свои способности, чтобы помешать другим игрокам закончить карту.</j></p>\n• Троллинг ради мести <Bне является веской причиной,</B> для троллинга кого-либо и вы все равно будете наказаны.\n• Принудительная помощь игрокам, которые пытаются пройти карту самостоятельно и отказываюся от помощи, когда их об этом просят, также считается троллингом. \n• <J>Если игрок не хочет помогать или предпочитает играть в одиночку на карте, постарайтесь помочь другим игрокам</J>. Однако, если другой игрок нуждается в помощи на том же чекпоинте, что и соло игрок, вы можете помочь им [обоим].\n\nЕсли игрок пойман на троллинге, он будет наказан на один раунд, либо на все время пребывания в паркуре. Обратите внимание, что повторный троллинг приведет к более длительным и суровым наказаниям.",
			help_contribute = "<font size='14'>Команда управления паркуром дает доступ к исходному коду, потому что это помогает нашему комьюнити. Вы можете увидеть и изменить исходный код #parkour на GitHub <a href='event:github'><u>(нажми сюда)</u></a>.\n\nОбратите внимание, что мы поддерживаем модуль бесплатно, поэтому любая помощь (в отношении кода, сообщений об ошибках, предложений) приветствуется. Мы также поддерживаем пожертвования, которые можно сделать <a href='event:donate'><u>clicking here</u></a>. Любая пожертвованная сумма ценится и идет на улучшение #parkour.",

			-- Congratulation messages
			reached_level = "<d>Поздравляем! Вы достигли уровня <vp>%s</vp>.",
			finished = "<d><o>%s</o> завершил паркур за <vp>%s</vp> секунд, <fc>поздравляем!",
			unlocked_power = "<ce><d>%s</d> разблокировал способность <vp>%s</vp>.",
			enjoy = "<d>Наслаждайтесь своими новыми навыками!",

			-- Information messages
			paused_events = "<cep><b>[Предупреждение!]</b> <n> Модуль достиг критического предела и сейчас временно остановлен.",
			resumed_events = "<n2>Модуль был возобновлен.",
			welcome = "<n>Добро пожаловать в<t>#parkour</t>!",
			discord = "<cs>Хотите сообщить об ошибках, предложить идеи для улучшения паркура или просто пообщаться с другими игроками? Присоединяйтесь к нам на discord: <pt>%s</pt>",
			map_submissions = "<bv>Хотите увидеть свою карту в модуле? Пишите тут: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Параметры Паркура</font></p>\n\nИспользуйте желтые крепления для чекпоинтов\n\nИспользуйте <b>QWERTY</b> на клавиатуре (отключить if <b>AZERTY</b>)\n\nИспользуйте <b>M</b> горячую клавишу <b>/mort</b> (отключить <b>DEL</b>)\n\nПоказать ваше время перезарядки\n\nПоказать кнопку способностей\n\nПоказать кнопку помощь\n\nПоказать объявление о завершении карты",
			unknown = "Неизвестно",
			powers = "Способности",
			press = "<vp>Нажмите %s",
			click = "<vp>Щелчок левой кнопкой мыши",
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
		}
		--[[ End of file translations/parkour/ru.lua ]]--
		--[[ File translations/parkour/en.lua ]]--
		translations.en = {
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
			help_help = "<p align = 'center'><font size = '14'>Welcome to <T>#parkour!</T></font>\n\n<font size = '12'><J>Your goal is to reach all the checkpoints until you complete the map.</J></font></p>\n\n<font size = '11'><N>• Press <O>O</O>, type <O>!op</O> or click the <O>configuration button</O> to open the <T>options menu</T>.\n• Press <O>P</O> or click the <O>hand icon</O> at the top-right to open the <T>powers menu</T>.\n• Press <O>L</O> or type <O>!lb</O> to open the <T>leaderboard</T>.\n• Press the <O>M</O> or <O>Delete</O> key to <T>/mort</T>, you can toggle the keys in the <J>Options</J> menu.\n• To know more about our <O>staff</O> and the <O>rules of parkour</O>, click on the <T>Staff</T> and <T>Rules</T> tab respectively.</font>\n\n<p align = 'center'><font size = '13'><T>Contributions are now open! For further details, click on the <O>Contribute</O> tab!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Parkour staff ARE NOT Transformice staff and DO NOT have any power in the game itself, only within the module.</r>\nParkour staff ensure that the module runs smoothly with minimal issues, and are always available to assist players whenever necessary.</font></p>\nYou can type <D>!staff</D> in the chat to see the staff list.\n\n<font color = '#E7342A'>Administrators:</font> They are responsible for maintaining the module itself by adding new updates and fixing bugs.\n\n<font color = '#843DA4'>Team Managers:</font> They oversee the Moderator and Mapper teams, making sure they are performing their jobs well. They are also responsible for recruiting new members to the staff team.\n\n<font color = '#FFAAAA'>Moderators:</font> They are responsible for enforcing the rules of the module and punishing individuals who do not follow them.\n\n<font color = '#25C059'>Mappers:</font> They are responsible for reviewing, adding, and removing maps within the module to ensure that you have an enjoyable gameplay.",
			help_rules = "<font size = '13'><B><J>All rules in the Transformice Terms and Conditions also apply to #parkour</J></B></font>\n\nIf you find any player breaking these rules, whisper the parkour mods in-game. If no mods are online, then it is recommended to report it in the discord server.\nWhen reporting, please include the server, room name, and player name.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidence, such as screenshots, videos and gifs are helpful and appreciated, but not necessary.\n\n<font size = '11'>• No <font color = '#ef1111'>hacks, glitches or bugs</font> are to be used in #parkour rooms\n• <font color = '#ef1111'>VPN farming</font> will be considered an <B>exploit</B> and is not allowed. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nAnyone caught breaking these rules will be immediately banned.</B></font></p>\n\n<font size = '12'>Transformice allows the concept of trolling. However, <font color='#cc2222'><B>we will not allow it in parkour.</B></font></font>\n\n<p align = 'center'><J>Trolling is when a player intentionally uses their powers to prevent other players from finishing the map.</j></p>\n• Revenge trolling is <B>not a valid reason</B> to troll someone and you will still be punished.\n• Forcing help onto players trying to solo the map and refusing to stop when asked is also considered trolling.\n• <J>If a player does not want help or prefers to solo a map, please try your best to help other players</J>. However if another player needs help in the same checkpoint as the solo player, you can help them [both].\n\nIf a player is caught trolling, they will be punished on either a time or parkour round basis. Note that repeated trolling will lead to longer and more severe punishments.",
			help_contribute = "<font size='14'>The parkour management team loves open source code, because it helps the community. You can see and modify #parkour's source code on github <a href='event:github'><u>(click here)</u></a>.\n\nNote that we are maintaining the module for free, so any help (regarding code, bug reports, suggestions) is welcomed. We also support donations, which can be done by <a href='event:donate'><u>clicking here</u></a>. Any amount donated is appreciated and will go towards improving #parkour.",

			-- Congratulation messages
			reached_level = "<d>Congratulations! You've reached level <vp>%s</vp>.",
			finished = "<d><o>%s</o> finished the parkour in <vp>%s</vp> seconds, <fc>congratulations!",
			unlocked_power = "<ce><d>%s</d> unlocked the <vp>%s</vp> power.",
			enjoy = "<d>Enjoy your new skills!",

			-- Information messages
			paused_events = "<cep><b>[Warning!]</b> <n>The module has reached it's critical limit and is being paused.",
			resumed_events = "<n2>The module has been resumed.",
			welcome = "<n>Welcome to <t>#parkour</t>!",
			discord = "<cs>Do you want to report bugs, make suggestions or just want to chat with other players? Join us on discord: <pt>%s</pt>",
			map_submissions = "<bv>Do you want to see your map in the module? Submit them here: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Parkour Options</font></p>\n\nUse particles for checkpoints\n\nUse <b>QWERTY</b> keyboard (disable if <b>AZERTY</b>)\n\nUse <b>M</b> hotkey for <b>/mort</b> (disable for <b>DEL</b>)\n\nShow your power cooldowns\n\nShow powers button\n\nShow help button\n\nShow map completion announcements",
			unknown = "Unknown",
			powers = "Powers",
			press = "<vp>Press %s",
			click = "<vp>Left click",
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
		}
		--[[ End of file translations/parkour/en.lua ]]--
		--[[ File translations/parkour/es.lua ]]--
		translations.es = {
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
			help_help = "<p align = 'center'><font size = '14'>¡Bienvenido a <T>#parkour!</T></font>\n\n<font size = '12'><J>Tu objetivo es alcanzar todos los puntos de control hasta que completes el mapa.</J></font></p>\n\n<font size = '11'><N>• Presiona la tecla <O>O</O>, escribe <O>!op</O> o clickea el <O>botón de configuración</O> para abrir el <T>menú de opciones</T>.\n• Presiona la tecla <O>P</O> o clickea el <O>ícono de la mano</O> arriba a la derecha para abrir el <T>menú de poderes</T>.\n• Presiona la tecla <O>L</O> o escribe <O>!lb</O> para abrir el <T>ranking</T>.\n• Presiona la tecla <O>M</O> o <O>Delete</O> como atajo para <T>/mort</T>, podes alternarlas en el menú de <J>Opciones</J>.\n• Para conocer más acerca de nuestro <O>staff</O> y las <O>reglas de parkour</O>, clickea en las pestañas de <T>Staff</T> y <T>Reglas</T>.</font>\n\n<p align = 'center'><font size = '13'><T>¡Las contribuciones están abiertas! Para más detalles, ¡clickea en la pestaña <O>Contribuir</O>!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>NOTA: El staff de Parkour NO ES staff de Transformice y NO TIENEN ningún poder en el juego, sólamente dentro del módulo.</r>\nEl staff de Parkour se asegura de que el módulo corra bien con la menor cantidad de problemas, y siempre están disponibles para ayudar a los jugadores cuando sea necesario.</font></p>\nPuedes escribir <D>!staff</D> en el chat para ver la lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> Son los responsables de mantener el módulo añadiendo nuevas actualizaciones y arreglando bugs.\n\n<font color = '#843DA4'>Lideres de Equipos:</font> Ellos supervisan los equipos de Moderadores y Mappers, asegurándose de que hagan un buen trabajo. También son los responsables de reclutar nuevos miembros al staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> Son los responsables de ejercer las reglas del módulo y sancionar a quienes no las sigan.\n\n<font color = '#25C059'>Mappers:</font> Son los responsables de revisar, añadir y quitar mapas en el módulo para asegurarse de que tengas un buen gameplay.",
			help_rules = "<font size = '13'><B><J>Todas las reglas en los Terminos y Condiciones de Transformice también aplican a #parkour</J></B></font>\n\nSi encuentras algún jugador rompiendo estas reglas, susurra a los moderadores de parkour en el juego. Si no hay moderadores online, es recomendable reportarlo en discord.\nCuando reportes, por favor agrega el servidor, el nombre de la sala, y el nombre del jugador.\n• Ej: en-#parkour10 Blank#3495 trollear\nEvidencia, como fotos, videos y gifs ayudan y son apreciados, pero no son necesarios.\n\n<font size = '11'>• No se permite el uso de <font color = '#ef1111'>hacks, glitches o bugs</font>\n• <font color = '#ef1111'>Farmear con VPN</font> será considerado un <B>abuso</B> y no está permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nCualquier persona rompiendo estas reglas será automáticamente baneado.</B></font></p>\n\n<font size = '12'>Transformice acepta el concepto de trollear. Pero <font color='#cc2222'><B>no está permitido en #parkour.</B></font></font>\n\n<p align = 'center'><J>Trollear es cuando un jugador intencionalmente usa sus poderes para hacer que otros jugadores no completen el mapa.</j></p>\n• Trollear como revancha <B>no es una razón válida</B> para trollear a alguien y aún así seras sancionado.\n• Ayudar a jugadores que no quieren completar el mapa con ayuda y no parar cuando te lo piden también es considerado trollear.\n• <J>Si un jugador no quiere ayuda, por favor ayuda a otros jugadores</J>. Sin embargo, si otro jugador necesita ayuda en el mismo punto, puedes ayudarlos [a los dos].\n\nSi un jugador es atrapado trolleando, será sancionado ya sea en base de tiempo o de rondas. Trollear repetidas veces llevará a sanciones más largas y severas.",
			help_contribute = "<font size='14'>El equipo de mantenimiento de parkour ama el código abierto, porque ayuda a la comunidad. Puedes ver y modificar el código fuente de #parkour en github <a href='event:github'><u>(click aquí)</u></a>.\n\nNosotros mantenemos el módulo de manera gratuita, por lo que cualquier ayuda (ya sea en el código, reportes de bugs, sugerencias) es bienvenida. También aceptamos donaciones, las cuales pueden ser hechas <a href='event:donate'><u>clickeando aquí</u></a>. Cualquier cantidad donada es apreciada y será destinada a mejorar #parkour.",

			-- Congratulation messages
			reached_level = "<d>¡Felicitaciones! Alcanzaste el nivel <vp>%s</vp>.",
			finished = "<d><o>%s</o> completó el parkour en <vp>%s</vp> segundos, <fc>¡felicitaciones!",
			unlocked_power = "<ce><d>%s</d> desbloqueó el poder <vp>%s<ce>.",
			enjoy = "<d>¡Disfruta tus nuevas habilidades!",

			-- Information messages
			paused_events = "<cep><b>[¡Advertencia!]</b> <n>El módulo está entrando en estado crítico y está siendo pausado.",
			resumed_events = "<n2>El módulo ha sido reanudado.",
			welcome = "<n>¡Bienvenido a <t>#parkour</t>!",
			discord = "<cs>¿Tienes alguna buena idea, reporte de bug o simplemente quieres hablar con otros jugadores? Entra a nuestro servidor de discord: <pt>%s</pt>",
			map_submissions = "<bv>¿Quieres ver tu mapa en el módulo? Publicalo aquí: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Opciones de Parkour</font></p>\n\nUsar partículas para los checkpoints\n\nUsar teclado <b>QWERTY</b> (desactivar si usas <b>AZERTY</b>)\n\nUsar la tecla <b>M</b> como atajo para <b>/mort</b> (desactivar si usas <b>DEL</b>)\n\nMostrar tiempos de espera de tus poderes\n\nMostrar el botón de poderes\n\nMostrar el botón de ayuda\n\nMostrar mensajes al completar un mapa",
			unknown = "Desconocido",
			powers = "Poderes",
			press = "<vp>Presiona %s",
			click = "<vp>Haz clic",
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
		}
		--[[ End of file translations/parkour/es.lua ]]--
		--[[ File translations/parkour/fr.lua ]]--
		translations.fr = {
			-- Error messages
			corrupt_map = "<r>Carte non opérationelle. Chargement d'une autre.",
			corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les information de cette carte.",
			corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
			corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise de fin (point final).",
			corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte a besoin d'au moins d'un point de sauvegarde (étoiles jaunes).",
			corrupt_data = "<r>Malheureusment, vos donnés ont été corrompues et ont été effacé.",
			min_players = "<r>Pour sauvegarder vos donnés, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
			tribe_house = "<r>Les données ne sont pas sauvées dans les maisons de tribus..",
			invalid_syntax = "<r>Syntaxe invalide.",
			user_not_in_room = "<r>Le joueur <n2>%s</n2> n'est pas dans le salon.",
			arg_must_be_id = "<r>L'argument doit Être un ID valide.",
			cant_update = "<r>Impossible de mettre à jour les rangs des joueurs pour l'instant. Essayer plus tard.",
			cant_edit = "<r>Vous ne pouvez pas modifier le rang de <n2>%s's</n2>.",
			invalid_rank = "<r>Rang invalide: <n2>%s",
			code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
			panic_mode = "<r>Module est maintenant en mode panique.",
			public_panic = "<r>Merci d'attendre jusqu'à ce que le robot arrive et redémarre le serveur.",
			tribe_panic = "<r>Veuillez ecrire <n2>/module parkour</n2> pour redémarrer le module.",
			emergency_mode = "<r>Mise en place du bloquage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon de #parkour.",
			bot_requested = "<r>Le robot à été solicité, il devrait arrivé dans un moment.",
			stream_failure = "<r>Echec de la chaine de stream interne. Impossible de transmettre les données.",
			maps_not_available = "<r>#parkour's 'maps' est seulement disponible dans <n2>*#parkour0maps</n2>.",
			version_mismatch = "<r>Le robot (<d>%s</d>) et Lua(<d>%s</d>) ne marche pas ensemble. Impossible de démarrer le système.",
			missing_bot = "<r>Robot absent. Attendez jusqu'à ce que le robot arrive ou mentionnez @Tocu#0018 sur Discord: <d>%s</d>",
			invalid_length = "<r>Votre message doit obligatoirement avoir entre 10 et 100 caractères. Il a seulement <n2>%s</n2> characters.",
			invalid_map = "<r>Carte invalide.",
			map_does_not_exist = "<r>Cette carte n'existe pas ou ne peut pas Être chargé. Essayez plus tard.",
			invalid_map_perm = "<r>Cette carte n'est pas P22 ou P41.",
			invalid_map_perm_specific = "<r>La carte n'est pas P%s.",
			cant_use_this_map = "<r>Cette carte a un bug et ne peut pas Être utilisée.",
			invalid_map_p41 = "<r>Cette carte est en P41, mais n'est pas dans la liste des cartes de ce module.",
			invalid_map_p22 = "<r>Cette carte est en P22, mais n'est pas dans la liste des cartes de ce module.",
			map_already_voting = "<r>Cette garde a déjà un vote en cours.",
			not_enough_permissions = "<r>Vous n'avez pas assez de permissions pour faire ça.",
			already_depermed = "<r>Cette carte est déjà non-permanente.",
			already_permed = "<r>Cette carte est déjà permanente.",
			cant_perm_right_now = "<r>Impossible de changer les permissions de cette carte maintenant. Essayez plus tard.",
			already_killed = "<r>Le joueur %s a déjà été tué.",
			leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été cahrgé encore. Attendez une minute.",

			-- Help window
			help = "Aide",
			staff = "Staff",
			rules = "Règles",
			contribute = "Contribuer",
			help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font>\n\n<font size = '12'><J>Votre but est de parcourir tous les points de sauvegarde pour finir la carte.</J></font></p>\n\n<font size = '11'><N>â€¢ Press <O>O</O>, type <O>!op</O> ou cliquez le <O>configuration button</O> pour ouvrir le <T>options menu</T>.\nâ€¢ Press <O>P</O> ou cliquez le <O>hand icon</O> en haut à droite pour ouvrir <T>powers menu</T>.\nâ€¢ Press <O>L</O> ou écrivez <O>!lb</O> pour ouvrir le <T>leaderboard</T>.\nâ€¢ Appuyez sur <O>M</O> ou la touche <O>Delete</O> pour <T>/mort</T>, vous pouvez personnalisez les touches dans <J>Options</J> menu.\nâ€¢ Pour savoir plus à propos de notre <O>staff</O> et des <O>rules of parkour</O>, cliquez sur les pages respectives du <T>Staff</T> et des <T>Rules</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! pour plus d'informations, cliquez sur la page <O>Contribute</O> </T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour ne sont pas Staff de Transformice, ils n'ont aucun pouvoir sur le jeu soit-meme, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien avec des issues minimales et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module soit-meme en ajoutant des mise à jours et en réparant les bugs.\n\n<font color = '#843DA4'>Manageurs des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement de nouveau membre du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsable de vérifier, ajotuer et de supprimer des cartes dans le module pour rendre vos parties meilleurs.",
			help_rules = "<font size = '13'><B><J>All Les Regles de Termes et de Conditions de Transformice s'appliquent aussi dans #parkou.r</J></B></font>\n\nSi vous surprenez un joueur enfreignant les règles, chuchotez à un modérateur du module #parkour connecté. Si aucun modérateur n'est en ligne, reportez le dans le serveur Discord.\nPour tous reports, inclusez : le serveur, le nom du salon, et le nom du joueur.\nâ€¢ Ex: en-#parkour10 Blank#3495 trolling\nDes preuves, comme des captures d'écran, des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>â€¢ Aucun <font color = '#ef1111'> piratage, aucune corruption ou bugs</font> utilisés/abusés dans les salons #parkour\nâ€¢ <font color = '#ef1111'>VPN farming</font> seront considérés comme <B>une violation</B> et ne sont pas autorisés. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Mais, <font color='#cc2222'><B>wenous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Quelqu'un troll si il empeche, grace à ses pouvoirs, de laisser les autres joueurs finir la carte.</j></p>\nâ€¢ Le troll en revanche d'un autre troll<B>n'est pas une raison valable</B> et vous serez quand meme puni.\nâ€¢ Aider un joueur qui a dit qu'il voulait faire la carte seule est aussi considéré comme du trolling.\nâ€¢ <J>Si un joueur veut réaliser la carte sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au meme point de sauvegarde que celui-ci, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera punis par sois un certains temps ou attendre un certain temps de cartes parkour sans pouvoir les jouer. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
			help_contribute = "<font size='14'>L'équipe du staff de gérement de la communauté adore donner des sources de codes, car cela aide la communauté. vous povuez voir les sources et codes de #parkour et les modifier dans github<a href='event:github'><u>(cliquez ici)</u></a>.\n\nNotez que nous entretenons le module gratuitement, donc n'importe quel aide (que ça soit code, bugs, suggestions) est la bienvenue. Nous proposons aussi des dons, qui peuvent etre réalisés sur<a href='event:donate'><u>cliquez ici</u></a>. N'importe quel somme de don est la bienvenue et sera utilisée dans l'amélioration de #parkour.",

			-- Congratulation messages
			reached_level = "<d>Bravo! Vous avez atteint le niveau <vp>%s</vp>.",
			finished = "<d><o>%s</o> a finis le parcour en <vp>%s</vp> secondes, <fc>congratulations!",
			unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir<vp>%s</vp>.",
			enjoy = "<d>Profite de tes nouvelles compétences!",

			-- Information messages
			paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
			resumed_events = "<n2>Le module n'est plus en pause.",
			welcome = "<n>Bienvenue à<t>#parkour</t>!",
			discord = "<cs>Voulez-vous reporter des bugs ? Proposer des suggestions ou simplement parler avec d'autres joueurs ? Rejoignez notre serveur discord : <pt>%s</pt>",
			map_submissions = "<bv>Voulez-vous voir votre carte dans le module ? Soumettez-les ici : <j>%s</j>",
			type_help = "<pt>Nous vous recommandons d'utiliser la commande <d>!help</d> pour voir des informtion utiles !",
			data_saved = "<vp>Données enregistrées.",
			action_within_minute = "<vp>Cette action sera réalisée dans quelque minutes.",
			rank_save = "<n2>Ecrivez <d>!rank save</d> pour appliquer les changements.",
			module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans<d>%02d:%02d</d>.",
			mapping_loaded = "<j>[INFO] <n>Système de carte<t>(v%s)</t> chargé.",
			mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a rejoinds le salon.",
			mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a quitté le salon.",
			mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a chargé la carte.",
			starting_perm_change = "<j>[INFO] <n>Commencement du changement de permissions...",
			got_map_info = "<j>[INFO] <n>Informations de la carte récupérées. Essaie de changement de permissions...",
			perm_changed = "<j>[INFO] <n>Réussite du changement de permission de la carte<ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
			leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
			kill_minutes = "<R>Vos pouvoirs ont été désactivés pour %s minutes.",
			kill_map = "<R>Vos pouvoirs ont été désactivés jusqu'à la prochaine carte.",

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtilisez les particules comme points de sauvegarde\n\nUtilisez le clavier <b>QWERTY</b> (désactivez si votre clavier et en <b>AZERTY</b>)\n\nUtilisez <b>M</b> touche chaude pour <b>/mort</b> (désactivez pour <b>DEL</b>)\n\nMontre le cooldown de vos compétences\n\nMontre les boutons pour utiiser les compétences\n\nMontre le bouton d'aide\n\nMontre les annonces des cartes achevées",
			unknown = "Inconnu",
			powers = "Pouvoirs",
			press = "<vp>Appuyer sur %s",
			click = "<vp>Clique gauche",
			completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
			leaderboard = "Tableau des scores",
			position = "Position",
			username = "Pseudo",
			community = "Communauté",
			completed = "Cartes complétées",
			not_permed = "sans permissions",
			permed = "avec des permissions",
			points = "%d points",
			conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. Dernier commentaire par <d>%s</d>. <d>%s</d> commentaire(s), <d>%s</d> non-lu(s).",
			map_info = "<p align='center'>Code de la carte: <bl>@%s</bl> <g>|</g> Auteur de la carte: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
			permed_maps = "Maps ayant des permissions",
			ongoing_votations = "Votes en cours",
			archived_votations = "Votes archivés",
			open = "Ouvrir",
			not_archived = "non-archivée",
			archived = "archivée",
			delete = "<r><a href='event:%s'>[supprimer]</a> ",
			see_restore = "<vp><a href='event:%s'>[voir]</a> <a href='event:%s'>[restaurer]</a> ",
			no_comments = "Pas de commentaires.",
			deleted_by = "<r>[Message supprimé par %s]",
			dearchive = "inarchiver", -- pour ne plus l'archiver
			archive = "archive", -- pour archiver
			deperm = "enlever les permissions", -- pour enlever les permissions
			perm = "permissions", -- pour ajouter des permissions
			map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a> <g>|</g> Votre  vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[chargement]</a></p>",
			map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a></p>",
			load_from_thread = "<p align='center'><a href='event:load_custom'>Charger une carte personalisée</a></p>",
			write_comment = "Ecrivez votre commentaire en-dessous",
			write_map = "Ecrivez les codes de la carte en-dessous",

			-- Power names
			balloon = "Ballon",
			masterBalloon = "Maitre Ballon",
			bubble = "Bulle",
			fly = "Voler",
			snowball = "Boule de neige",
			speed = "Vitesse",
			teleport = "Teleportation",
			smallbox = "Petite boite",
			cloud = "Nuage",
			rip = "Tombe",
			choco = "Planche de chocolat",
		}
		--[[ End of file translations/parkour/fr.lua ]]--
		--[[ File translations/parkour/br.lua ]]--
		translations.br = {
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
			help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font>\n\n<font size = '12'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></font></p>\n\n<font size = '11'><N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.</font>\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#843DA4'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
			help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador usa seus poderes de forma intencional para fazer com que os outros jogadores não terminem o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador for pego trollando, serão punidos por um tempo determinado ou por algumas partidas. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
			help_contribute = "<font size='14'>A equipe de gerenciamento do parkour ama código-fonte aberto, porque isso ajuda a comunidade. Você pode ver e modificar o código do módulo no github <a href='event:github'><u>(clicando aqui)</u></a>.\n\nNote que estamos mantendo o módulo de graça, então qualquer ajuda (seja código, report de bugs, sugestões) é bem-vinda. Também podemos receber doações, que podem ser feitas <a href='event:donate'><u>clicando aqui</u></a>. Qualquer valor é apreciado e será usado para melhorar o #parkour.",

			-- Congratulation messages
			reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>.",
			finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
			unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
			enjoy = "<d>Aproveite suas novas habilidades!",

			-- Information messages
			paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
			resumed_events = "<n2>O módulo está se normalizando.",
			welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
			discord = "<cs>Tendo alguma boa ideia, report de bug ou apenas querendo conversar com outros jogadores? Entre em nosso servidor no Discord: <pt>%s</pt>",
			map_submissions = "<bv>Quer ver seu mapa no módulo? Poste-o aqui: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar partículas para os checkpoints\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <b>M</b> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado",
			unknown = "Desconhecido",
			powers = "Poderes",
			press = "<vp>Aperte %s",
			click = "<vp>Use click",
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
		}
		--[[ End of file translations/parkour/br.lua ]]--
		--[[ File translations/parkour/tr.lua ]]--
			translations.tr = {
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
			help_help = "<p align = 'center'><font size = '14'>Hoşgeldiniz. <T>#parkour!</T></font>\n\n<font size = '12'><J>Amacınız haritayı tamamlayana kadar bütün kontrol noktalarına ulaşmak.</J></font></p>\n\n<font size = '11'><N>•  Ayarlar menüsü açmak için klavyeden<O>O</O>tuşuna basabilir, <O>!op</O> yazabilir veya <O>çark</O>simgesine tıklayabilirsiniz.\n• Beceri menüsüne ulaşmak için klavyeden <O>P</O> tuşuna basabilir veya sağ üst köşedeki <O>El</O> simgesine tıklayabilirsiniz.\n• Lider tablosuna ulaşmak için <O>L</O> tuşuna basabilir veya <O>!lb</O> yazabilirsiniz.\n• Ölmek için <O>M</O> veya <O>Delete</O> tuşuna basabilirsiniz. <O>Delete</O> tuşunu kullanabilmek için <J>Ayarlar</J>ksımından <O>M</O> tuşu ile ölmeyi kapatmanız gerekmektedir.\n•  Ekip ve parkur kuralları hakkında daha fazla bilgi bilgi almak için, <O>Ekip</O> ve <O>Kurallar</O> sekmesine tıklayın.</font>\n\n<p align = 'center'><font size = '13'><T>Artık bize bağışta bulunabilirsiniz! Daha fazla bilgi için, <O>Bağış</O> sekmesine tıklayın!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>Bildiri: Parkour ekibi Transformice'ın ekibi DEĞİLDİR, sadece parkour modülünde yetkililerdir.</r>\nParkur ekibi modülün akıcı bir şekilde kalmasını sağlar ve her zaman oyunculara yardımcı olurlar.</font></p>\nEkip listesini görebilmek için <D>!staff</D> yazabilirsiniz.\n\n<font color = '#E7342A'>Administrators:</font> Modülü yönetmek, yeni güncellemeler getirmek ve hataları/bugları düzeltirler.\n\n<font color = '#843DA4'>Team Managers:</font> Modları ve Mapperları kontrol eder ve işlerini iyi yaptıklarından emin olurlar. Ayrıca ekibe yeni modlar almaktan da onlar sorumludur.\n\n<font color = '#FFAAAA'>Moderators:</font> Kuralları uygulamak ve uygulamayan oyuncuları cezalandırmaktan sorumludurlar.\n\n<font color = '#25C059'>Mappers:</font> Yeni yapılan haritaları inceler, harita listesine ekler ve siz oyuncularımızın eğlenceli bir oyun deneyimi geçirmenizi sağlarlar.",
			help_rules = "<font size = '13'><B><J>Transformice bütün kural ve koşulları #parkour içinde geçerlidir</J></B></font>\n\nEğer kurallara uymayan bir oyuncu görürseniz,oyun içinde parkour ekibindeki modlardan birine mesaj atabilirsiniz. Eğer hiçbir mod çevrim içi değilse discord serverimizde rapor edebilirsiniz.\nRapor ederken lütfen serveri, oda ismini ve oyuncu ismini belirtiniz.\n• Örnek: tr-#parkour10 Sperjump#6504 trolling\nEkran görüntüsü,video ve gifler işe yarayacaktır fakat gerekli değildir..\n\n<font size = '11'>•#parkour odalarında <font color = '#ef1111'>hack ve bug</font>kullanmak YASAKTIR!\n• <font color = '#ef1111'>VPN farming</font> yasaktır, <B>Haksız kazanç elde etmeyin</B> .. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKuralları çiğneyen herkes banlanacaktır.</B></font></p>\n\n<font size = '12'>Transformice trolleme konseptine izin verir. Fakat, <font color='#cc2222'><B>biz buna parkur modülünde izin vermeyeceğiz.</B></font></font>\n\n<p align = 'center'><J>Trollemek becerilerini diğer oyuncuların haritayı bitirmesini engellemek için kullanmak demektir..</j></p>\n• İntikam almak için trollemek <B>geçerli bir sebep değildir</B> ve cezalandırılacaktır.\n• Haritayı tek başına bitirmek isteyen bir oyuncuya zorla yardım etmeye çalışmak trollemek olarak kabul edilecek ve cezalandırılacaktır.\n• <J>Eğer bir oyuncu yardım istemiyorsa ve haritayı tek başına bitirmek istiyorsa, lütfen diğer oyunculara yardım etmeyi deneyin.</J>. Ancak yardım isteyen diğer oyuncu haritayı tek başına yapmak isteyen bir oyuncunun yanındaysa ona yardım edebilirsiniz.[both].\n\nEğer bir oyuncu trollerken yakalanırsa, zaman ve ya parkur roundları bazında cezalandırılacaktır.. Sürekli bir şekilde trollemekten dolayı ceza alan bir oyuncu eğer hala trollemeye devam ederse cezaları daha ağır olacaktır..",
			help_contribute = "<font size='14'>Parkur yönetimi açık kaynak kodlarına bayılır, çünkü topluluğumuza yardımcı oluyor. #parkour'un kaynak kodunu github'da görebilir ve ekleme yapabilirsiniz <a href='event:github'><u>(göz atmak için tıkla)</u></a>.\n\nModülü gönüllü olarak yönetiyoruz, yani her türlü (kod,bug ve hata bildirimi tavsiyeleriniz bizim için yararlı olacaktır. Ayrıca bize destek de olabilirsiniz, <a href='event:donate'><u>(destek olamk için tıkla)</u></a>. Her desteğiniz değerlidir ve #parkour'u daha da geliştirmek için kullanılacaktır.",

			-- Congratulation messages
			reached_level = "<d>Tebrikler! <vp>%s</vp>. Seviyeye ulaştınız.",
			finished = "<d><o>%s</o> parkuru <vp>%s</vp> saniyede bitirdi, <fc>Tebrikler!",
			unlocked_power = "<ce><d>%s</d>, <vp>%s</vp> becerisini açtı.",
			enjoy = "<d>Yeni becerilerinin keyfini çıkar!",

			-- Information messages
			paused_events = "<cep><b>[Dikkat!]</b> <n>Modül kritik seviyeye ulaştı ve durduruluyor.",
			resumed_events = "<n2>Modül devam ettirildi.",
			welcome = "<n><t>#parkour</t>! Odasına hoşgeldiniz.",
			discord = "<cs>Hataları bildirmek, tavsiyelerde bulunmak veya trolleyen bir oyuncuyu rapor etmek mi istiyorsunuz? Discord sunucumuza katılın: <pt>%s</pt>",
			map_submissions = "<bv>Modülde kendi yaptığınız haritanızı görmek ister misiniz? Buraya gönderin: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Parkur ayarları</font></p>\n\nKontrol noktaları için parçacıkları kullan\n\n<b>QWERTY</b> klavye kullan (Kapatıldığnda <b>AZERTY</b> klavye kullanılır)\n\nÖlmek için klavyeden <b>M</b> tuşuna bas veya <b>/mort</b> komutunu kullan. (Kapattığında <b>DELETE</b> tuşuna basarak ölebilirsin.)\n\nBeceri bekleme sürelerini göster\n\nBeceriler simgesini göster\n\nYardım butonunu göster\n\nHarita bitirme duyurularını göster",
			unknown = "Bilinmiyor",
			powers = "Beceriler",
			press = "<vp>%s Tuşuna Bas",
			click = "<vp>Sol tık",
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
		}
		--[[ End of file translations/parkour/tr.lua ]]--
		--[[ End of directory translations/parkour ]]--
		--[[ File modes/parkour/timers.lua ]]--
		local timers = {}
		local aliveTimers = false

		local function addNewTimer(delay, fnc, argument)
			aliveTimers = true
			local list = timers[delay]
			if list then
				list._count = list._count + 1
				list[list._count] = {os.time() + delay, fnc, argument}
			else
				timers[delay] = {
					_count = 1,
					_pointer = 1,
					[1] = {os.time() + delay, fnc, argument}
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
							timer[2](timer[3])
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
				local timer
				for delay, list in next, timers do
					for index = list._pointer, list._count do
						timer = list[index]
						timer[2](timer[3])
					end
				end
			end
		end)
		--[[ End of file modes/parkour/timers.lua ]]--
		--[[ File modes/parkour/maps.lua ]]--
		local first_data_load = true
		local repeated = {_count = 0}
		local maps = {_count = 0}
		local is_invalid = false
		local levels

		local function newMap()
			if repeated._count == maps._count then
				repeated = {_count = 0}
			end

			local map
			repeat
				map = maps[math.random(1, maps._count)]
			until map and not repeated[map]
			repeated[map] = true
			repeated._count = repeated._count + 1

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
					maps = {_count = 1, [1] = 7171137}
				end
				if first_data_load then
					newMap()
					first_data_load = false
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
		local join_bot = "Tocutoeltuco#6919"
		local join_epoch = os.time({year=2020, month=1, day=1, hour=0})
		local join_to_delete = {_count = 0}
		local waiting_mod = false
		local next_join_check = os.time() + 15000
		local waiting_mod_timeout = 0

		onEvent("PlayerDataLoaded", function(player, data)
			if player ~= join_bot then return end

			data = json.decode(data)

			if room.name == "*#parkour0maps" then
				eventJoinSystemDataLoaded(join_bot, data)
			else
				local now = os.time() - join_epoch
				join_to_delete._count = 0

				for room_name, expire in next, data do
					if not expire[1] then
						if now >= expire[2] then
							join_to_delete._count = join_to_delete._count + 1
							join_to_delete[join_to_delete._count] = room_name

						elseif room_name == room.name then
							waiting_mod = true
							waiting_mod_timeout = now + 45000
							data[room_name] = {true, waiting_mod_timeout}

							tfm.exec.setRoomMaxPlayers(20)
						end
					end
				end

				for idx = 1, join_to_delete._count do
					data[join_to_delete[idx]] = nil
				end

				system.savePlayerData(join_bot, json.encode(data))
			end
		end)

		onEvent("Loop", function()
			local now = os.time()
			if now >= next_join_check then
				system.loadPlayerData(join_bot)
				next_join_check = now + 15000
			end
			if waiting_mod then
				tfm.exec.setRoomMaxPlayers(20)
				if now >= waiting_mod_timeout then
					waiting_mod = false
				end
			else
				tfm.exec.setRoomMaxPlayers(12)
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
		local victory = {}
		local bans = {}
		local in_room = {}
		local players_level = {}
		local generated_at = {}
		local spec_mode = {}
		local ck = {
			particles = {},
			images = {}
		}

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

		onEvent("PlayerWon", function(player, elapsed)
			victory_count = victory_count + 1
			victory[player] = true

			if victory_count == player_count then
				tfm.exec.setGameTime(20)
				less_time = true
			end
		end)

		onEvent("NewGame", function()
			check_position = 6
			victory_count = 0
			less_time = false
			victory = {}
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
				local last_level = #levels
				local level_id, next_level, player
				local particle = 29--math.random(21, 23)
				local x, y = math.random(-10, 10), math.random(-10, 10)

				for name in next, in_room do
					player = room.playerList[name]
					if bans[player.id] then
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
			tfm.exec.setRoomMaxPlayers(12)
			tfm.exec.disableAutoScore(true)
		end)
		--[[ End of file modes/parkour/game.lua ]]--
		--[[ File modes/parkour/files.lua ]]--
		next_file_load = os.time() + math.random(60500, 90500)
		local files = {
			--[[
				File values:

				- maps     (1)
				- webhooks (1 and 2)
				- update   (1)
				- ranks    (1)

				- banned   (2)
				- ranking  (2)
				- suspects (2)
			]]

			[1] = 1, -- maps, update, ranks
			[2] = 2  -- ranking, banned, suspects
		}
		local total_files = 2
		local players_file = {}
		local file_index = 1
		local fetching_player_room = {}
		file_id = files[file_index]

		local data_migrations = {
			["0.0"] = function(player, data)
				data.parkour = data.modules.parkour
				data.drawbattle = data.modules.drawbattle

				data.modules = nil

				data.parkour.v = "0.4" -- version
				data.parkour.c = data.parkour.cm -- completed maps
				data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
				data.parkour.mort = 1 -- /mort hotkey
				data.parkour.pcool = 1 -- power cooldowns
				data.parkour.pbut = 1 -- powers button
				data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
				data.parkour.killed = 0
				data.parkour.hbut = 1 -- help button
				data.parkour.congrats = 1 -- contratulations message

				data.parkour.cm = nil
			end,
			["0.1"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.ckpart = 1
				data.parkour.mort = 1
				data.parkour.pcool = 1
				data.parkour.pbut = 1
				data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
				data.parkour.killed = 0
				data.parkour.congrats = 1
			end,
			["0.2"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.killed = 0
				data.parkour.hbut = 1
				data.parkour.congrats = 1
			end,
			["0.3"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.hbut = 1
				data.parkour.congrats = 1
			end
		}

		local function savePlayerData(player)
			if not players_file[player] then return end

			system.savePlayerData(
				player,
				json.encode(players_file[player])
			)
		end

		onEvent("PlayerDataLoaded", function(player, data)
			if in_room[player] then return end

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
		end)

		onEvent("PlayerDataLoaded", function(player, data)
			if not in_room[player] then return end
			if player == stream_bot or player == join_bot then return end

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
				tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. (data.room or "unknown"), fetch[1])
				fetching_player_room[player] = nil
			end

			if players_file[player] then return end

			players_file[player] = data

			players_file[player].room = room.name
			savePlayerData(player)

			eventPlayerDataParsed(player, data)
		end)

		onEvent("SavingFile", function(id, data)
			system.saveFile(json.encode(data), id)
		end)

		onEvent("FileLoaded", function(id, data)
			data = json.decode(data)
			eventGameDataLoaded(data)
			eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
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
				end
			end

			for idx = 1, count do
				fetching_player_room[to_remove[idx]] = nil
			end
		end)

		onEvent("GameStart", function()
			system.loadFile(file_id)
			next_file_load = os.time() + math.random(60500, 90500)
		end)

		onEvent("NewPlayer", function(player)
			system.loadPlayerData(player)
		end)
		--[[ End of file modes/parkour/files.lua ]]--
		--[[ File modes/parkour/ranks.lua ]]--
		local band = (bit or bit32).band
		local bxor = (bit or bit32).bxor

		local ranks = {
			admin = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0}
		}
		local ranks_id = {
			admin = 2 ^ 0,
			manager = 2 ^ 1,
			mod = 2 ^ 2,
			mapper = 2 ^ 3
		}
		local ranks_permissions = {
			admin = {
				show_update = true
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
				change_map = true
			},
			mapper = {
				vote_map = true,
				change_map = true
			}
		}
		local player_ranks = {}
		local perms = {}
		local saving_ranks = false
		local ranks_update
		local updater
		local ranks_order = {"admin", "manager", "mod", "mapper"}

		for rank, perms in next, ranks_permissions do
			if rank ~= "admin" then
				for perm_name, allowed in next, perms do
					ranks_permissions.admin[perm_name] = allowed
				end
			end
		end

		onEvent("GameDataLoaded", function(data)
			if data.ranks then
				if saving_ranks then
					local added, removed, not_changed
					for player, rank in next, ranks_update do
						if data.ranks[player] then
							not_changed = band(data.ranks[player], rank)
							removed = bxor(not_changed, data.ranks[player])
							added = bxor(not_changed, rank)
						else
							removed = 0
							added = rank
						end

						if added > 0 then
							local new
							for rank, id in next, ranks_id do
								if band(id, added) > 0 then
									if new then
										new = new .. "*, *parkour-" .. rank
									else
										new = "parkour-" .. rank
									end
								end
							end

							webhooks._count = webhooks._count + 1
							webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is now a **" .. new .. "**."
						end
						if removed > 0 then
							local old
							for rank, id in next, ranks_id do
								if band(id, removed) > 0 then
									if old then
										old = old .. "*, *parkour-" .. rank
									else
										old = "parkour-" .. rank
									end
								end
							end

							webhooks._count = webhooks._count + 1
							webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is no longer a **" .. old .. "**."
						end

						if rank == 0 then
							data.ranks[player] = nil
						else
							data.ranks[player] = rank
						end
					end

					translatedChatMessage("data_saved", updater)
					ranks_update = nil
					updater = nil
					saving_ranks = false
				end

				ranks, perms, player_ranks = {
					admin = {_count = 0},
					manager = {_count = 0},
					mod = {_count = 0},
					mapper = {_count = 0}
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

		local no_powers = {}
		local facing = {}
		local cooldowns = {}

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
			local obj = tfm.exec.addShamanObject(...)
			addNewTimer(when, tfm.exec.removeObject, obj)
		end

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
			}
		}

		local keyPowers, clickPowers = {
			qwerty = {},
			azerty = {}
		}, {}
		local player_keys = {}

		local function bindNecessary(player)
			local maps = players_file[player].parkour.c
			for key, powers in next, player_keys[player] do
				if powers._count then
					for index = 1, powers._count do
						if maps >= powers[index].maps then
							system.bindKeyboard(player, key, true, true)
						end
					end
				end
			end

			for index = 1, #clickPowers do
				if maps >= clickPowers[index].maps then
					system.bindMouse(player, true)
					break
				end
			end
		end

		local function unbind(player)
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

			if not player_keys[player] or not victory[player] then return end
			local powers = player_keys[player][key]
			if not powers then return end

			local file = players_file[player].parkour
			local maps, show_cooldowns = file.c, file.pcool == 1
			local power
			for index = powers._count, 1, -1 do
				power = powers[index]
				if maps >= power.maps or room.name == "*#parkour0maps" then
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

			local file = players_file[player].parkour
			local maps, show_cooldowns = file.c, file.pcool == 1
			local power, cooldown
			for index = 1, #clickPowers do
				power = clickPowers[index]
				if maps >= power.maps or room.name == "*#parkour0maps" then
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

			if room.name ~= "*#parkour0maps" and room.uniquePlayers >= min_save and not is_tribe then
				completed = players_file[player].parkour.c + 1
				players_file[player].parkour.c = completed
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

			for player in next, in_room do
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
		local max_leaderboard_rows = 70
		local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
		local loaded_leaderboard = false
		local leaderboard = {}
		-- {id, name, completed_maps, community}
		local default_leaderboard_user = {0, nil, 0, "xx"}

		local function leaderboardSort(a, b)
			return a[3] > b[3]
		end

		local remove, sort = table.remove, table.sort

		local function checkPlayersPosition()
			local totalRankedPlayers = #leaderboard
			local cachedPlayers = {}

			local playerId, position

			local toRemove, counterRemoved = {}, 0
			for player = 1, totalRankedPlayers do
				position = leaderboard[player]
				playerId = position[1]

				if bans[playerId] then
					counterRemoved = counterRemoved + 1
					toRemove[counterRemoved] = player
				else
					cachedPlayers[playerId] = position
				end
			end

			for index = counterRemoved, 1, -1 do
				remove(leaderboard, toRemove[index])
			end
			toRemove = nil

			totalRankedPlayers = totalRankedPlayers - counterRemoved

			local cacheData
			local playerFile, playerData, completedMaps

			for player in next, in_room do
				playerFile = players_file[player]

				if playerFile then
					completedMaps = playerFile.parkour.c
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
							leaderboard[totalRankedPlayers] = {
								playerId,
								player,
								completedMaps,
								playerData.community
							}
						end
					end
				end
			end

			sort(leaderboard, leaderboardSort)

			for index = max_leaderboard_rows + 1, totalRankedPlayers do
				leaderboard[index] = nil
			end
		end

		onEvent("GameDataLoaded", function(data)
			if data.ranking then
				if not loaded_leaderboard then
					loaded_leaderboard = true

					translatedChatMessage("leaderboard_loaded")
				end

				leaderboard = data.ranking

				checkPlayersPosition()
			end
		end)
		--[[ End of file modes/parkour/leaderboard.lua ]]--
		--[[ File modes/parkour/interface.lua ]]--
		local kill_cooldown = {}
		local save_update = false
		local update_at = 0
		local ban_actions = {_count = 0}
		local open = {}
		local powers_img = {}
		local help_img = {}
		local toggle_positions = {
			[1] = 107,
			[2] = 132,
			[3] = 157,
			[4] = 183,
			[5] = 209,
			[6] = 236,
			[7] = 262
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

		local function addWindow(id, text, player, x, y, width, height)
			if width < 0 or height and height < 0 then
				return
			elseif not height then
				height = width/2
			end
			id = 1000 + id * 8

			ui.addTextArea(id    , ""  , player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
			ui.addTextArea(id + 1, ""  , player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
			ui.addTextArea(id + 2, ""  , player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
			ui.addTextArea(id + 3, ""  , player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 4, ""  , player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 5, ""  , player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 6, ""  , player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 7, text, player, x+3            , y+3             , width+94    , height+64, 0x1c3a3e, 0x232a35, 1, true)
		end

		local function removeWindow(id, player)
			for i = 1000 + id * 8, 1000 + id * 8 + 7 do
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

		local function closeLeaderboard(player)
			if not open[player].leaderboard then return end

			removeWindow(1, player)
			removeButton(1, player)
			removeButton(2, player)
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

			for toggle = 1, 7 do
				removeToggle(toggle, player)
			end

			savePlayerData(player)

			open[player].options = nil
		end

		local function removeHelpMenu(player)
			if not open[player].help then return end

			removeWindow(7, player)

			ui.removeTextArea(10000, player)

			for button = 7, 11 do
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

			addWindow(7, "\n\n\n" .. translatedMessage("help_" .. tab, player) .. "\n\n\n", player, 200, 50, 300, 260)

			ui.addTextArea(10000, "", player, 210, 60, 390, 30, 0x1c3a3e, 0x1c3a3e, 1, true)

			addButton(7, translatedMessage("help", player), "help:help", player, 210, 60, 80, 18, tab == "help")
			addButton(8, translatedMessage("staff", player), "help:staff", player, 310, 60, 80, 18, tab == "staff")
			addButton(9, translatedMessage("rules", player), "help:rules", player, 410, 60, 80, 18, tab == "rules")
			addButton(10, translatedMessage("contribute", player), "help:contribute", player, 510, 60, 80, 18, tab == "contribute")

			addButton(11, "Close", "close_help", player, 210, 352, 380, 18, false)
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
				or ranks.mod[player] and 0xFFAAAA -- moderator
				or ranks.mapper[player] and 0x25C059 -- mapper
				or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
				or 0x148DE6 -- default
			)
		end

		local function showLeaderboard(player, page)
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

			if not page or page < 0 then
				page = 0
			elseif page > max_leaderboard_pages then
				page = max_leaderboard_pages
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
				if position > max_leaderboard_rows then break end
				positions = positions .. "#" .. position .. "\n"
				row = leaderboard[position] or default_leaderboard_user

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

			addButton(1, "&lt;                       ", "leaderboard_p:" .. page - 1, player, 185, 346, 210, 20, not (page > 0)                    )
			addButton(2, "&gt;                       ", "leaderboard_p:" .. page + 1, player, 410, 346, 210, 20, not (page < max_leaderboard_pages))
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
			local power, canUse
			for index = page * 3, page * 3 + 2 do
				power = powers[index + 1]
				if power then
					canUse = completed >= power.maps
					ui.addTextArea(
						3000 + index,
						string.format(
							"<p align='center'><b><d>%s\n\n\n\n\n\n\n\n<n>%s",
							power.name and translatedMessage(power.name, player) or "undefined",
							canUse and (
								power.click and
								translatedMessage("click", player) or
								translatedMessage("press", player, player_keys[player][power])
							) or completed .. "/" .. power.maps
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
				showLeaderboard(player, tonumber(args) or 0)
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
				if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" then return end
				showHelpMenu(player, args)
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
				end

				addToggle(tonumber(t_id), player, state)
			end
		end)

		onEvent("GameDataLoaded", function(data)
			if data.banned then
				bans = {}
				for player in next, data.banned do
					bans[tonumber(player)] = true
				end

				if ban_actions._count > 0 then
					local send_saved = {}
					local to_respawn = {}
					local action
					for index = 1, ban_actions._count do
						action = ban_actions[index]

						if not send_saved[action[3]] then
							send_saved[action[3]] = true
							translatedChatMessage("data_saved", action[3])
						end

						if action[1] == "ban" then
							bans[action[2]] = true
							data.banned[tostring(action[2])] = 1 -- 1 so it uses less space
							to_respawn[action[2]] = nil
						else
							bans[action[2]] = nil
							data.banned[tostring(action[2])] = nil
							to_respawn[action[2]] = true
						end

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[BANS]:`** **" .. action[3] .. "** has " .. action[1] .. "ned a player. (ID: **" .. action[2] .. "**)"
					end
					ban_actions = {_count = 0}

					for id in next, to_respawn do
						for player, data in next, room.playerList do
							if data.id == id then
								tfm.exec.respawnPlayer(player)
							end
						end
					end
				end
			end

			if data.update then
				if save_update then
					data.update = save_update
					save_update = nil
				end

				update_at = data.update or 0
			end
		end)

		onEvent("PlayerRespawn", setNameColor)

		onEvent("NewGame", function()
			for player in next, in_room do
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
			translatedChatMessage("discord", player, links.discord)
			translatedChatMessage("map_submissions", player, links.maps)
			translatedChatMessage("type_help", player)

			system.bindKeyboard(player, 76, true, true)
			system.bindKeyboard(player, 79, true, true)
			system.bindKeyboard(player, 72, true, true)
			system.bindKeyboard(player, 80, true, true)

			tfm.exec.addImage("1713705576b.png", ":1", 772, 32, player)
			ui.addTextArea(-1, "<a href='event:settings'><font size='50'>  </font></a>", player, 767, 32, 30, 32, 0, 0, 0, true)

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
		end)

		onEvent("PlayerWon", function(player)
			if bans[ room.playerList[player].id ] then return end

			-- If the player joined the room after the map started,
			-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
			local taken = (os.time() - (generated_at[player] or map_start)) / 1000

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
						translatedChatMessage("unlocked_power", nil, player, power.name)
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

			elseif cmd == "ban" then
				if not perms[player] or not perms[player].ban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local affected = capitalize(args[1])
				if not in_room[affected] then
					return translatedChatMessage("user_not_in_room", player, affected)
				end

				local id = room.playerList[affected].id
				ban_actions._count = ban_actions._count + 1
				ban_actions[ban_actions._count] = {"ban", id, player}
				bans[id] = true
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "unban" then
				if not perms[player] or not perms[player].unban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local id = tonumber(args[1])
				if (not id) or (not bans[id]) then
					return translatedChatMessage("arg_must_be_id", player)
				end

				ban_actions._count = ban_actions._count + 1
				ban_actions[ban_actions._count] = {"unban", id, player}
				bans[id] = nil
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "kill" then
				if not perms[player] or not perms[player].ban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local affected = capitalize(args[1])
				if not in_room[affected] then
					return translatedChatMessage("user_not_in_room", player, affected)
				end
				if no_powers[affected] then
					return translatedChatMessage("already_killed", player, affected)
				end

				local minutes = "-"
				if pointer > 1 then
					minutes = tonumber(args[2])

					if not minutes then
						return translatedChatMessage("invalid_syntax", player)
					end

					translatedChatMessage("kill_minutes", affected, minutes)
					players_file[affected].parkour.killed = os.time() + minutes * 60 * 1000
					savePlayerData(affected)
				else
					translatedChatMessage("kill_map", affected)
				end

				webhooks._count = webhooks._count + 1
				webhooks[webhooks._count] = "**`[BANS]:`** `" .. room.name .. "` `" .. player .. "`: `!kill " .. affected .. " " .. minutes .. "`"

				no_powers[affected] = true
				unbind(affected)

			elseif cmd == "rank" then
				if not perms[player] or not perms[player].set_player_rank then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end
				args[1] = string.lower(args[1])

				if args[1] == "add" or args[1] == "rem" then
					if pointer < 2 then
						return translatedChatMessage("invalid_syntax", player)
					end
					if updater and updater ~= player then
						return translatedChatMessage("cant_update", player)
					end

					local rank_name = string.lower(args[3])
					if not ranks[rank_name] then
						return translatedChatMessage("invalid_rank", player, rank_name)
					end

					if not ranks_update then
						ranks_update = {}
						updater = player
					end

					local affected = capitalize(args[2])
					if not ranks.admin[player] then
						if ranks.admin[affected] or ranks.manager[affected] then
							return translatedChatMessage("cant_edit", player)
						end
					end

					if args[1] == "add" and ranks[rank_name][affected] then
						return translatedChatMessage("has_rank", player, affected, rank_name)
					elseif args[1] == "rem" and not ranks[rank_name][affected] then
						return translatedChatMessage("doesnt_have_rank", player, affected, rank_name)
					end

					if not ranks_update[affected] then
						rank_id = 0
						for rank, id in next, ranks_id do
							if ranks[rank][affected] then
								rank_id = rank_id + id
							end
						end
						ranks_update[affected] = rank_id
					end

					if args[1] == "add" then
						ranks_update[affected] = ranks_update[affected] + ranks_id[rank_name]
					else
						ranks_update[affected] = ranks_update[affected] - ranks_id[rank_name]
					end

					translatedChatMessage("rank_save", player)

				elseif args[1] == "save" then
					saving_ranks = true
					translatedChatMessage("action_within_minute", player)

				elseif args[1] == "list" then
					local msg
					for rank, players in next, ranks do
						msg = "Users with the rank " .. rank .. ":"
						for player in next, players do
							msg = msg .. "\n - " .. player
						end
						tfm.exec.chatMessage(msg, player)
					end

				else
					return translatedChatMessage("invalid_syntax", player)
				end

			elseif cmd == "staff" then
				local texts = {}
				local text, _first
				for player, ranks in next, player_ranks do
					if player ~= "Tocutoeltuco#5522" then
						text = "\n- <v>" .. player .. "</v> ("
						_first = true
						for rank in next, ranks do
							if _first then
								text = text .. rank
								_first = false
							else
								text = text .. ", " .. rank
							end
						end
						texts[player] = text .. ")"
					end
				end

				text = "<v>[#]<n> <d>Parkour staff:</d>"

				for i = 1, #ranks_order do
					for player in next, ranks[ranks_order[i]] do
						if texts[player] then
							text = text .. texts[player]
							texts[player] = nil
						end
					end
				end

				tfm.exec.chatMessage(text, player)

			elseif cmd == "update" then
				if not perms[player] or not perms[player].show_update then return end

				save_update = os.time() + 60000 * 3 -- 3 minutes
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "map" then
				if not perms[player] or not perms[player].change_map then return end

				if pointer > 0 then
					tfm.exec.newGame(args[1])
				else
					newMap()
				end

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
			if key == 76 then
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
			tfm.exec.disableMinimalistMode(true)
			system.disableChatCommandDisplay("lb", true)
			system.disableChatCommandDisplay("ban", true)
			system.disableChatCommandDisplay("unban", true)
			system.disableChatCommandDisplay("kill", true)
			system.disableChatCommandDisplay("rank", true)
			system.disableChatCommandDisplay("update", true)
			system.disableChatCommandDisplay("map", true)
			system.disableChatCommandDisplay("spec", true)
			system.disableChatCommandDisplay("op", true)
			system.disableChatCommandDisplay("donate", true)
			system.disableChatCommandDisplay("help", true)
			system.disableChatCommandDisplay("staff", true)
			system.disableChatCommandDisplay("room", true)
		end)
		--[[ End of file modes/parkour/interface.lua ]]--
		--[[ File modes/parkour/webhooks.lua ]]--
		webhooks = {_count = 0}

		onEvent("GameDataLoaded", function(data)
			local now = os.time()
			if not data.webhooks or os.time() >= data.webhooks[1] then
				data.webhooks = {math.floor(os.time()) + 300000} -- 5 minutes
			end

			local last = #data.webhooks
			for index = 1, webhooks._count do
				data.webhooks[last + index] = webhooks[index]
			end
			webhooks._count = 0
		end)
		--[[ End of file modes/parkour/webhooks.lua ]]--
		--[[ File modes/parkour/init.lua ]]--
		if submode ~= "maps" then
			eventGameStart()
		end
		--[[ End of file modes/parkour/init.lua ]]--
		--[[ End of package modes/parkour ]]--
		--[[ File modes/maps/interface.lua ]]--
		local mapper_bot = "Tocutoeltuco#5522"

		local join_epoch = os.time({year=2020, month=1, day=1, hour=0})
		local map_changes = {
			removing = {},
			adding = {}
		}
		local packets = {
			handshake     = bit32.lshift( 1, 8) + 255,
			list_forum    = bit32.lshift( 2, 8) + 255,
			list_maps     = bit32.lshift( 3, 8) + 255,
			unreads       = bit32.lshift( 4, 8) + 255,
			open_votation = bit32.lshift( 5, 8) + 255,
			new_comment   = bit32.lshift( 6, 8) + 255,
			new_map_vote  = bit32.lshift( 7, 8) + 255,
			delete_msg    = bit32.lshift( 8, 8) + 255,
			restore_msg   = bit32.lshift( 9, 8) + 255,
			change_status = bit32.lshift(10, 8) + 255,
			new_votation  = bit32.lshift(11, 8) + 255,
			perm_map      = bit32.lshift(12, 8) + 255,

			migrate_data  = bit32.lshift(13, 8) + 255, -- This packet is not related to the map system, but is here so we don't use a lot of resources.

			send_webhook  = bit32.lshift(14, 8) + 255, -- This packet is not related to the map system, but is here so we don't use a lot of resources.

			room_crash    = bit32.lshift(15, 8) + 255,

			join_request  = bit32.lshift(16, 8) + 255
		}
		local last_update
		local messages_cache = {}
		local system_maps = {_count = 0}
		local forum = {ongoing = {}, archived = {}, by_code = {}}
		local loaded = {
			data = false,
			system = false
		}
		local version = {
			lua = "1.1.0-pool",
			bot = nil
		}
		local changing_perm = {}
		local menu_part = {}
		local decoder = {
			["&0"] = "&",
			["&1"] = ","
		}
		local join_requests = {_count = 0}
		local room = room

		function send_bot_room_crash()
			for index = 1, webhooks._count do
				ui.addTextArea(packets.send_webhook, webhooks[index], mapper_bot)
			end
			ui.addTextArea(packets.room_crash, "", mapper_bot)
		end

		local function decodePacketString(str)
			return string.gsub(str, "&[01]", decoder)
		end

		local function setPagination(player, page)
			ui.addTextArea(14, "<a href='event:maps_page:1'>&lt;&lt;</a>", player, 15, 363, 25, 19, 1, 0, 1, true)
			ui.addTextArea(15, "<a href='event:maps_page:" .. math.max(page - 1, 1) .. "'>&lt;</a>", player, 50, 363, 15, 19, 1, 0, 1, true)
			ui.addTextArea(16, "<p align='center'>" .. page, player, 80, 363, 50, 19, 1, 0, 1, true)
			ui.addTextArea(17, "<a href='event:maps_page:" .. (page + 1) .. "'>&gt;</a>", player, 145, 363, 15, 19, 1, 0, 1, true)
			ui.addTextArea(18, "<a href='event:maps_page:0'>&gt;&gt;</a>", player, 175, 363, 25, 19, 1, 0, 1, true)
		end

		local function updatePagination(player, page)
			ui.updateTextArea(15, "<a href='event:maps_page:" .. math.max(page - 1, 1) .. "'>&lt;</a>", player)
			ui.updateTextArea(16, "<p align='center'>" .. page, player)
			ui.updateTextArea(17, "<a href='event:maps_page:" .. (page + 1) .. "'>&gt;</a>", player)
		end

		local function formatComment(comment, can_delete, player)
			local actions, msg

			if comment.deleted then
				msg = translatedMessage("deleted_by", player, comment.deleted_by)
				actions = translatedMessage("see_restore", player, "sm:" .. comment.id, "rm:" .. comment.id) -- restore_msg
			else
				msg = "<n>" .. comment.msg
				if can_delete then
					actions = translatedMessage("delete", player, "dm:" .. comment.id)
				end
			end

			return (
					"<j>" .. comment.author .. " " ..
					(can_delete and actions or "") ..
					msg
			)
		end

		local function closeSection(player)
			if not menu_part[player] then return end

			for id = 20, 19 + 2 * (menu_part[player] == 1 and 16 or 5) do
				ui.removeTextArea(id, player)
			end
		end

		local function closeMapsMenu(player)
			part = menu_part[player]
			if part then
				if part == 1 or part == 2 or part == 3 then
					ui.addTextArea(10, "<a href='event:maps_menu:" .. part .. "'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
				else
					ui.addTextArea(10, "<a href='event:0_view:" .. part .. "'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
				end
			else
				ui.addTextArea(10, "<a href='event:maps_menu:1'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
			end

			for id = 11, 19 do
				ui.removeTextArea(id, player)
			end

			closeSection(player)

			menu_part[player] = nil
		end

		local function openVotation(player, code, page)
			local votation = forum.by_code[code]

			closeSection(player)

			if not votation then
				if (not perms[player]) or not perms[player].vote_map then
					return translatedChatMessage("cant_open_votation", player, code)
				end

				return ui.addTextArea(packets.new_votation, player .. "," .. code, mapper_bot)
			end

			local can_delete = (perms[player] and perms[player].delete_comments) and "1" or "0"
			ui.addTextArea(
				packets.open_votation,
				player .. "," .. (page * 12 - 12) .. "," .. can_delete .. "," .. room.playerList[player].id .. "," .. code .. "," .. votation.comments_quantity,
				mapper_bot
			)

			menu_part[player] = code
		end

		local function _openVotation(player, code, page, comments, can_delete, vote)
			page = page / 12

			local votation = forum.by_code[code]

			for index = 14, 18 do
				ui.removeTextArea(index, player) -- remove pagination
			end

			ui.addTextArea(
				20,
				translatedMessage(
					"map_info", player,
					code, votation.map.author,
					translatedMessage(votation.map.permed and "permed" or "not_permed", player),
					translatedMessage(votation.archived and "archived" or "not_archived", player),
					math.floor(votation.votes / ranks.mapper._count * 100)
				),
				player, 15, 65, 770, 20, 1, 0, 1, true
			)

			ui.addTextArea(
				21,
				(perms[player] and perms[player].vote_map) and
				translatedMessage(
					"map_actions_staff", player,
					"c_page:" .. code .. "," .. math.max(page, 1), page + 1, "c_page:" .. code .. "," .. page + 2,
					"comment:" .. code,
					vote and (
						(vote == "1" and "<vp>+</vp> " or "<r>-</r> ") .. translatedMessage("delete", player, "delete_vote:" .. code)
					) or (
						"<a href='event:downvote:" .. code .. "'><r>[-]</r></a> <a href='event:upvote:" .. code .. "'><vp>[+]</vp></a>"
					),
					votation.archived and "dearchive:" .. code or "archive:" .. code,
					translatedMessage(votation.archived and "dearchive" or "archive", player),
					votation.map.permed and "deperm:" .. code or "perm:" .. code,
					translatedMessage(votation.map.permed and "deperm" or "perm", player),
					"load_map:" .. code
				) or
				translatedMessage(
					"map_actions_user", player,
					"c_page:" .. code .. "," .. math.max(page, 1), page + 1, "c_page:" .. code .. "," .. page + 2,
					"comment:" .. code
				),
				player, 15, 361, 770, 20, 1, 0, 1, true
			)

			local text
			local comment = comments[1]

			if comment then
				text = formatComment(comment, can_delete, player)

				for index = 2, #comments do
					comment = comments[index]

					text = text .. "\n" .. formatComment(comment, can_delete, player)
				end
			else
				text = translatedMessage("no_comments", player)
			end

			ui.addTextArea(22, text, player, 15, 100, 770, 245, 0x324650, 0, 1, true)
		end

		local function openPermedMapsMenu(player, page)
			local last_page = math.ceil(system_maps._count / 16)
			if not page then
				page = last_page - 1
			else
				page = math.max(math.min(page, last_page), 1) - 1
			end

			local open = translatedMessage("open", player)

			local txt = 20
			local offset = 0
			local left = true
			local map
			for index = page * 16 + 1, page * 16 + 16 do
				map = system_maps[index]
				if not map then break end
				if left then
					offset = offset + 1
				end
				ui.addTextArea(txt, (left and "<j>" or "<p align='right'><j>") .. map.author .. " <bl>- @" .. map.code, player, left and 20 or 540, 35 + offset * 35, 240, 20, 0x324650, 0, 1, true)
				ui.addTextArea(txt + 1, "<a href='event:view:" .. map.code .. "'>" .. open .. "</a>", player, left and 240 or 510, 35 + offset * 35, 50, 20, 1, 0, 1, true)
				left = not left
				txt = txt + 2
			end

			local pagination_fnc = type(menu_part[player]) == "number" and updatePagination or setPagination
			pagination_fnc(player, page + 1)
		end

		local function openVotationsMenu(player, page, archived)
			local list = archived and forum.archived or forum.ongoing

			local last_page = math.ceil(#list / 5)
			if not page then
				page = last_page - 1
			else
				page = math.max(math.min(page, last_page), 1) - 1
			end

			ui.addTextArea(
				packets.unreads,
				room.playerList[player].id .. "," .. player .. "," .. (page * 5) .. ",5," .. (archived and "1" or "0"),
				mapper_bot
			)

			local pagination_fnc = type(menu_part[player]) == "number" and updatePagination or setPagination
			pagination_fnc(player, page + 1)
		end

		local function _openVotationsMenu(player, page, archived, votations, unreads)
			if not archived then
				ui.addTextArea(19, translatedMessage("load_from_thread", player), player, 550, 363, 237, 19, 1, 0, 1, true)
				archived = ""
			else
				archived = "<bl>(" .. translatedMessage("archived", player) .. ")"
			end

			local permed = translatedMessage("permed", player)
			local not_permed = translatedMessage("not_permed", player)
			local open = translatedMessage("open", player)

			local votation
			for index = 1, #votations do
				votation = votations[index]

				ui.addTextArea(
					18 + index * 2,
					translatedMessage(
						"conversation_info", player,
						votation.map.author, votation.map.code,
						votation.map.permed and permed or not_permed,
						translatedMessage("points", player, math.floor(votation.votes / ranks.mapper._count * 100)),
						archived,
						votation.started == " " and "Unknown" or votation.started,
						votation.last_comment == " " and "Unknown" or votation.last_comment,
						votation.comments_quantity, votation.comments_quantity - unreads[votation.map.code]
					), player,
					20, 20 + index * 50, 765, 35, 0x324650, 0, 1, true
				)
				ui.addTextArea(19 + index * 2, "<a href='event:view:" .. votation.map.code .. "'>" .. open .. "</a>", player, 740, 25 + index * 50, 35, 20, 1, 0, 1, true)
			end
		end

		local function openMapsMenu(player, where)
			if not where then return end

			ui.removeTextArea(10, player)

			local permed_open, permed_close, ongoing_open, ongoing_close, archived_open, archived_close
			if where == 1 then permed_open, permed_close = "b", "b"
			elseif where == 2 or where == 0 then ongoing_open, ongoing_close = "b", "b"
			else archived_open, archived_close = "b", "b"
			end
			if not permed_open then permed_open, permed_close = "a href='event:maps_menu:1'", "a" end
			if not ongoing_open then ongoing_open, ongoing_close = "a href='event:maps_menu:2'", "a" end
			if not archived_open then archived_open, archived_close = "a href='event:maps_menu:3'", "a" end

			ui.addTextArea(11, "", player, 10, 30, 780, 355, 0x324650, 0, 1, true)
			ui.addTextArea(
				13, string.format(
					"<p align='center'><%s>%s</%s> | <%s>%s</%s> | <%s>%s</%s></p>",
					permed_open, translatedMessage("permed_maps", player), permed_close,
					ongoing_open, translatedMessage("ongoing_votations", player), ongoing_close,
					archived_open, translatedMessage("archived_votations", player), archived_close
				), player, 10, 30, 780, 20, 1, 0, 1, true
			)
			ui.addTextArea(12, "<p align='center'><a href='event:close_maps'><b>X</b></a></p>", player, 770, 30, 20, 20, 0xaa0000, 0, 1, true)

			if menu_part[player] then
				closeSection(player)
			end

			setPagination(player, 1)

			if where == 1 then
				openPermedMapsMenu(player, 1)
			elseif where == 2 then
				openVotationsMenu(player, 1, false)
			elseif where == 3 then
				openVotationsMenu(player, 1, true)
			end

			menu_part[player] = where
		end

		onEvent("GameDataLoaded", function(data)
			if not loaded.data then
				loaded.data = true

				if room.playerList[mapper_bot] then
					eventNewPlayer(mapper_bot)
				else
					translatedChatMessage("missing_bot", nil, links.discord)
				end
			end

			if data.maps then
				local countA, countB = #data.maps, #map_changes.removing
				for index = countA, 1, -1 do
					for _index = 1, countB do
						if map_changes.removing[_index] == data.maps[index] then
							table.remove(map_changes.removing, _index)
							table.remove(data.maps, index)
							countB = countB - 1
							countA = countA - 1
							break
						end
					end
				end

				for index = 1, #map_changes.adding do
					data.maps[countA + index] = map_changes.adding[index]
				end

				map_changes.removing = {}
				map_changes.adding = {}

				for code, status in next, changing_perm do
					if status == "" then
						changing_perm[code] = false
					end
				end
			end
		end)

		onEvent("GameDataLoaded", function(data)
			if loaded.system then
				if data.webhooks then
					for index = 2, #data.webhooks do
						ui.addTextArea(packets.send_webhook, data.webhooks[index], mapper_bot)
					end

					data.webhooks = {math.floor(os.time()) + 300000}
				end

			end
			if data.update then
				if last_update and data.update > last_update then
					ui.addTextArea(packets.send_webhook, "**[UPDATE]** The module is gonna be updated soon.", mapper_bot)
				end
				last_update = data.update
			end
		end)

		onEvent("NewPlayer", function(player)
			if not loaded.data then return end

			if player == mapper_bot and not loaded.system then
				ui.addTextArea(packets.handshake, version.lua, mapper_bot)
				version.bot = nil
			end

			if version.bot and not loaded.system then
				translatedChatMessage("version_mismatch", player, version.bot, version.lua)
			end

			if not loaded.system then return end

			if player == mapper_bot then
				translatedChatMessage("mapper_joined", nil, player, "bot")
			elseif perms[player] then
				local player_ranks = ""

				for rank, players in next, ranks do
					if players[player] then
						if player_ranks ~= "" then
							player_ranks = player_ranks .. ", "
						end
						player_ranks = player_ranks .. "parkour-" .. rank
					end
				end

				translatedChatMessage("mapper_joined", nil, player, player_ranks)
			end

			ui.addTextArea(10, "<a href='event:maps_menu:1'>M</a>", player, 5, 25, 15, 20, 0x324650, 0, 0.5, true)
		end)

		onEvent("PlayerLeft", function(player)
			if not loaded.system then return end

			if player == mapper_bot then
				translatedChatMessage("mapper_left", nil, player, "bot")
				loaded.system = false
				version.bot = nil
				for affected in next, menu_part do
					closeMapsMenu(affected)
					menu_part[affected] = 1
				end
				ui.removeTextArea(10)
				menu_part = {}

			elseif perms[player] then
				local player_ranks = ""

				for rank, players in next, ranks do
					if players[player] then
						if player_ranks ~= "" then
							player_ranks = player_ranks .. ", "
						end
						player_ranks = player_ranks .. "parkour-" .. rank
					end
				end

				translatedChatMessage("mapper_left", nil, player, player_ranks)
			end
		end)

		onEvent("TextAreaCallback", function(id, player, cb)
			if player == mapper_bot or not loaded.system then return end

			local position = string.find(cb, ":", 1, true)
			local action, args
			if not position then
				action = cb
			else
				action = string.sub(cb, 1, position - 1)
				args = string.sub(cb, position + 1)
			end

			if action == "maps_menu" then
				local where = tonumber(args)
				if (not where) or where < 1 or where > 3 then return end -- just a bot trying to break the module

				openMapsMenu(player, where)

			elseif action == "close_maps" then
				closeMapsMenu(player)

			elseif action == "view" or action == "0_view" then
				if not args then return end -- just a bot trying to break the module

				if action == "0_view" then
					openMapsMenu(player, 0)
				end

				openVotation(player, args, 1)

			elseif action == "maps_page" then
				local page = tonumber(args)
				if (not args) or (not menu_part[player]) or page < 0 then return end -- just a bot trying to break the module

				if menu_part[player] == 1 then
					openPermedMapsMenu(player, page)
				elseif menu_part[player] == 2 then
					openVotationsMenu(player, page, false)
				elseif menu_part[player] == 3 then
					openVotationsMenu(player, page, true)
				else
					--openVotation(player, menu_part[player], page)
				end

			elseif action == "c_page" then
				local map, page = string.match(args, "^(%d+),(%d+)$")
				if not map or not page or not forum.by_code[map] then return end

				openVotation(player, map, tonumber(page))

			elseif action == "comment" then
				local map = tonumber(args)
				if not map or not forum.by_code[args] then return end

				ui.addPopup(map, 2, translatedMessage("write_comment", player), player, 190, 190, 420, true)

			elseif action == "upvote" or action == "downvote" or action == "delete_vote" then
				local map = tonumber(args)
				if not perms[player] or not perms[player].vote_map or not map or not forum.by_code[args] then return end -- just a bot trying to break the module

				local vote = action == "upvote" and "1" or (action == "downvote" and "0" or " ")
				ui.addTextArea(packets.new_map_vote, room.playerList[player].id .. "," .. map .. "," .. vote, mapper_bot)
				openVotation(player, args, 1)

			elseif action == "archive" or action == "dearchive" then
				local map = tonumber(args)
				local votation = forum.by_code[args]
				if not perms[player] or not perms[player].vote_map or not map or not votation then return end -- just a bot trying to break the module

				if votation.archived and action == "archive" then return
				elseif not votation.archived and action == "dearchive" then return end

				if action == "archive" then
					if votation.archived then return end
					ui.addTextArea(packets.change_status, map .. ",1", mapper_bot)

					for index, vot in next, forum.ongoing do
						if vot == votation then
							table.remove(forum.ongoing, index)
							break
						end
					end

					forum.archived[#forum.archived + 1] = votation
					votation.archived = true

				elseif action == "dearchive" then
					if not votation.archived then return end
					ui.addTextArea(packets.change_status, map .. ",0", mapper_bot)

					for index, vot in next, forum.archived do
						if vot == votation then
							table.remove(forum.archived, index)
							break
						end
					end

					forum.ongoing[#forum.ongoing + 1] = votation
					votation.archived = false
				end

				openVotation(player, args, 1)

			elseif action == "perm" then
				local map = tonumber(args)
				local votation = forum.by_code[args]
				if not perms[player] or not map or not votation then return end -- just a bot trying to break the module
				if not perms[player].perm_map then
					return translatedChatMessage("not_enough_permissions", player)
				end
				if votation.map.permed then
					return translatedChatMessage("already_permed", player)
				end
				if changing_perm[args] then
					return translatedChatMessage("cant_perm_right_now", player)
				end
				changing_perm[args] = true

				ui.addTextArea(packets.perm_map, player .. "," .. args .. ",1", mapper_bot)
				translatedChatMessage("starting_perm_change", player)

			elseif action == "deperm" then
				local map = tonumber(args)
				local votation = forum.by_code[args]
				if not perms[player] or not map or not votation then return end -- just a bot trying to break the module
				if not perms[player].perm_map then
					return translatedChatMessage("not_enough_permissions", player)
				end
				if not votation.map.permed then
					return translatedChatMessage("already_depermed", player)
				end
				if changing_perm[args] then
					return translatedChatMessage("cant_perm_right_now", player)
				end
				changing_perm[args] = true

				ui.addTextArea(packets.perm_map, player .. "," .. args .. ",0", mapper_bot)
				translatedChatMessage("starting_perm_change", player)

			elseif action == "dm" then -- delete_msg
				local msg = tonumber(args)
				if not perms[player] or not perms[player].delete_comments or not msg then return end -- just a bot trying to break the module

				ui.addTextArea(packets.delete_msg, room.playerList[player].id .. "," .. msg, mapper_bot)
				openVotation(player, menu_part[player], 1)

			elseif action == "sm" then -- see_msg
				local msg = tonumber(args)
				if not perms[player] or not perms[player].delete_comments or not msg or not messages_cache[msg] then return end -- just a bot trying to break the module

				tfm.exec.chatMessage("<vp>\n" .. messages_cache[msg].msg, player)

			elseif action == "rm" then -- restore_msg
				local msg = tonumber(args)
				if not perms[player] or not perms[player].delete_comments or not msg or not messages_cache[msg] then return end -- just a bot trying to break the module

				ui.addTextArea(packets.restore_msg, msg, mapper_bot)
				openVotation(player, menu_part[player], 1)

			elseif action == "load_map" then
				local map = tonumber(args)
				if not perms[player] or not perms[player].vote_map or not map then return end -- just a bot trying to break the module

				translatedChatMessage("mapper_loaded", nil, player)
				tfm.exec.newGame(map)

			elseif action == "load_custom" then
				if not perms[player] or not perms[player].vote_map then return end

				ui.addPopup(0, 2, translatedMessage("write_map", player), player, 190, 190, 420, true)
			end
		end)

		onEvent("TextAreaCallback", function(id, player, cb)
			if player ~= mapper_bot then return end

			if id == packets.handshake then
				if cb == "ok" then
					loaded.system = true
					changing_perm = {}

					translatedChatMessage("mapping_loaded", nil, version.lua)
					for player in next, in_room do
						eventNewPlayer(player)
					end
				elseif string.sub(cb, 1, 7) == "not ok;" then
					version.bot = string.sub(cb, 8)

					for player in next, in_room do
						if player ~= mapper_bot then
							eventNewPlayer(player)
						end
					end
				end

			elseif loaded.system then
				if id == packets.list_forum then
					forum = {ongoing = {}, archived = {}, by_code = {}}
					local ongoing_count, archived_count = 0, 0
					local votation, stored_perm, stored_archive
					for slice in string.gmatch(cb, "[^,]+") do
						if not votation then
							votation = {
								map = {
									author = slice
								}
							}
						elseif not votation.map.code then
							votation.map.code = slice
						elseif not stored_perm then
							stored_perm = true
							votation.map.permed = slice == "1"
						elseif not votation.votes then
							votation.votes = tonumber(slice)
						elseif not stored_archive then
							stored_archive = true
							votation.archived = slice == "1"
						elseif not votation.started then
							votation.started = slice
						elseif not votation.last_comment then
							votation.last_comment = slice
						else
							votation.comments_quantity = tonumber(slice)

							if not votation.archived then
								ongoing_count = ongoing_count + 1
								forum.ongoing[ongoing_count] = votation
							else
								archived_count = archived_count + 1
								forum.archived[archived_count] = votation
							end
							forum.by_code[votation.map.code] = votation

							votation = nil
							stored_perm = false
							stored_archive = false
						end
					end

				elseif id == packets.list_maps then
					system_maps = {}
					local count = 0
					local author
					for slice in string.gmatch(cb, "[^,]+") do
						if not author then
							author = slice
						else
							count = count + 1
							system_maps[count] = {
								author = author,
								code = slice
							}
							author = nil
						end
					end

					system_maps._count = count

				elseif id == packets.unreads then
					local unreads, votations, count = {}, {}, 0
					local id, affected, page, archived, map
					for slice in string.gmatch(cb, "[^,]+") do
						if not id then
							id = tonumber(slice)
						elseif not affected then
							affected = slice
						elseif not page then
							page = tonumber(slice)
						elseif not archived then
							archived = slice
						elseif not map then
							map = slice
						else
							unreads[map] = tonumber(slice)
							map = nil
						end
					end

					for map, unread in next, unreads do
						count = count + 1
						votations[count] = forum.by_code[map]
					end

					_openVotationsMenu(affected, page, archived == "1", votations, unreads)

				elseif id == packets.open_votation then
					local messages, count, msg = {}, 0
					local user, code, page, can_delete, msg_id, msg_author, deleted_by, vote, votes
					for slice in string.gmatch(cb, "[^,]+") do
						if not user then
							user = slice
						elseif not code then
							code = slice
						elseif not page then
							page = tonumber(slice)
						elseif not can_delete then
							can_delete = slice
						elseif not vote then
							vote = slice
						elseif not votes then
							votes = tonumber(slice)
						elseif not msg_id then
							msg_id = slice
						elseif not msg_author then
							msg_author = slice
						elseif not deleted_by then
							deleted_by = slice
						else
							msg = {
								id = msg_id,
								author = msg_author,
								msg = decodePacketString(slice),
								deleted = deleted_by ~= " ",
								deleted_by = deleted_by
							}
							count = count + 1
							messages[count] = msg

							if msg.deleted then
								messages_cache[tonumber(msg_id)] = msg
							end

							msg_id = nil
							msg_author = nil
							deleted_by = nil
						end
					end

					forum.by_code[code].votes = votes

					if vote == " " then
						vote = nil
					end
					_openVotation(user, code, page, messages, can_delete == "1", vote)

				elseif id == packets.new_votation then
					local player, result, code, author, permed = string.match(cb, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")

					if result == "0" then
						local votation = {
							map = {
								author = author,
								code = code,
								permed = permed == "1"
							},
							votes = 0,
							archived = false,
							started = " ",
							last_comment = " ",
							comments_quantity = 0
						}
						forum.ongoing[#forum.ongoing + 1] = votation
						forum.by_code[code] = votation
						openVotation(player, code, 1)
					elseif result == "1" then
						translatedChatMessage("map_does_not_exist", player)
					elseif result == "2" then
						translatedChatMessage("invalid_map_perm", player)
					elseif result == "3" then
						translatedChatMessage("cant_use_this_map", player)
					elseif result == "4" then
						translatedChatMessage("invalid_map_p41", player)
					end

				elseif id == packets.perm_map then
					local player, perm, result, can_perm, code, author = string.match(cb, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")

					if can_perm == "1" then
						changing_perm[code] = "" -- so it is not changed until the next save
					end

					if result == "0" then
						forum.by_code[code].map.permed = perm == "1"

						local from, to
						if perm == "1" then
							from, to = "22", "41"
							system_maps._count = system_maps._count + 1
							system_maps[system_maps._count] = {
								author = author,
								code = code
							}
							map_changes.adding[#map_changes.adding + 1] = tonumber(code)
						else
							from, to = "41", "22"
							for index = 1, system_maps._count do
								if system_maps[index].code == code then
									table.remove(system_maps, index)
									system_maps._count = system_maps._count - 1
									break
								end
							end
							map_changes.removing[#map_changes.removing + 1] = tonumber(code)
						end

						translatedChatMessage("perm_changed", player, code, from, to)
						openVotation(player, code, 1)
					elseif result == "1" then
						translatedChatMessage("map_does_not_exist", player)
					elseif result == "2" then
						translatedChatMessage("invalid_map_perm_specific", player, perm == "1" and "22" or "41")
					elseif result == "3" then
						translatedChatMessage("cant_use_this_map", player)
					elseif result == "4" then
						translatedChatMessage("invalid_map_p41", player)
					elseif result == "5" then
						translatedChatMessage("invalid_map_p22", player)
					elseif result == "6" then
						translatedChatMessage("got_map_info", player)
					elseif result == "7" then
						translatedChatMessage("cant_perm_right_now", player)
					end

				elseif id == packets.migrate_data then
					local player, data = string.match(cb, "^([^,]+),(.*)$")
					system.savePlayerData(player, data)
					ui.addTextArea(packets.migrate_data, player, mapper_bot)

				elseif id == packets.join_request then
					join_requests._count = join_requests._count + 1
					join_requests[join_requests._count] = cb
				end
			end
		end)

		onEvent("PopupAnswer", function(id, player, answer)
			if not loaded.system then return end

			if id == 0 then -- create new votation
				if not perms[player] or not perms[player].vote_map then return end

				local map = string.match(answer, "^@(%d+)$")
				if not map then
					return translatedChatMessage("invalid_map", player)
				end

				if forum.by_code[map] then
					openVotation(player, map, 1)
					return translatedChatMessage("map_already_voting", player)
				end

				return ui.addTextArea(packets.new_votation, player .. "," .. map, mapper_bot)
			end

			local code = tostring(id)
			local votation = forum.by_code[code]
			if not votation then return end

			local length = #answer
			if length < 10 or length > 100 then
				return translatedChatMessage("invalid_length", player, length)
			end

			votation.comments_quantity = votation.comments_quantity + 1
			votation.last_comment = player
			if votation.started == " " then
				votation.started = player
			end

			ui.addTextArea(packets.new_comment, id .. "," .. room.playerList[player].id .. "," .. answer, mapper_bot)
			openVotation(player, code, 1)
		end)

		onEvent("JoinSystemDataLoaded", function(bot, data)
			local now = os.time() - join_epoch
			for idx = 1, join_requests._count do
				data[join_requests[idx]] = {false, now + 45000}
			end
			if join_requests._count > 0 then
				join_requests._count = 0
				ui.addTextArea(packets.join_request, "requested", mapper_bot)
			end

			local recv = ""
			for room_name, expire in next, data do
				if expire[1] then
					recv = recv .. "\001" .. room_name .. "\002" .. (expire[2] + join_epoch)
					join_to_delete._count = join_to_delete._count + 1
					join_to_delete[join_to_delete._count] = room_name
				end
			end
			if recv ~= "" then
				ui.addTextArea(packets.join_request, "received" .. recv, mapper_bot)
			end

			for idx = 1, join_to_delete._count do
				data[join_to_delete[idx]] = nil
			end

			system.savePlayerData(bot, json.encode(data))
		end)
		--[[ End of file modes/maps/interface.lua ]]--
		--[[ File modes/maps/init.lua ]]--
		if tfm.get.room.name ~= "*#parkour0maps" then
			translatedChatMessage("maps_not_available")
			emergencyShutdown(true)
		else
			eventGameStart()
			tfm.exec.setRoomMaxPlayers(50)
		end
		--[[ End of file modes/maps/init.lua ]]--
		--[[ End of package modes/maps ]]--
	else
		--[[ Package modes/parkour ]]--
		--[[ Directory translations/parkour ]]--
		--[[ File translations/parkour/ru.lua ]]--
		translations.ru = {
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
			help_help = "<p align = 'center'><font size = '14'>Добро пожаловать в <T>#parkour!</T></font>\n\n<font size = '12'><J>Ваша цель - собрать все чекпоинты, чтобы завершить карту.</J></font></p>\n\n<font size = '11'><N>• Нажмите <O>O</O>, введите <O>!op</O> или нажмите на <O> шестеренку</O> чтобы открыть <T>меню настроек</T>.\n• Нажмите <O>P</O> или нажмите на <O>руку</O> в правом верхнем углу, чтобы открыть <T>меню со способностями</T>.\n• Нажмите <O>L</O> или введите <O>!lb</O> чтобы открыть <T>Список лидеров</T>.\n• Нажмите <O>M</O> или <O>Delete</O> чтобы не прописывать <T>/mort</T>.\n• Чтобы узнать больше о нашей <O>команде</O> и о <O>правилах паркура</O>, нажми на <T>Команда</T> и <T>Правила</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Вкладки теперь открыты! Для получения более подробной информации, нажмите на вкладку <O>Содействие</O> !</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>ОБЯЗАННОСТИ: Команда Паркура НЕ команда Transformice и НЕ имеет никакой власти в самой игре, только внутри модуля.</r>\nКоманда Parkour обеспечивают исправную работу модуля с минимальными проблемами и всегда готова помочь игрокам в случае необходимости.</font></p>\nВы можете ввести <D>!staff</D> в чат, чтобы увидеть нашу команду.\n\n<font color = '#E7342A'>Администраторы:</font> Hесут ответственность за поддержку самого модуля, добавляя новые обновления и исправляя ошибки.\n\n<font color = '#843DA4'>Руководители команд:</font> Kонтролируют команды модераторов и картостроителей, следя за тем, чтобы они хорошо выполняли свою работу. Они также несут ответственность за набор новых членов в команду.\n\n<font color = '#FFAAAA'>Модераторы:</font> Hесут ответственность за соблюдение правил модуля и наказывают тех, кто не следует им.\n\n<font color = '#25C059'>Картостроители:</font> Oтвечают за просмотр, добавление и удаление карт в модуле, обеспечивая вам приятный игровой процесс.",
			help_rules = "<font size = '13'><B><J>Все правила пользователя и условия Transformice также применяются к #parkour </J></B></font>\n\nЕсли вы обнаружили, что кто-то нарушает эти правила, напишите нашим модераторам. Если модераторов нет в сети, вы можете сообщить об этом на на нашем сервере в Discord\nПри составлении репорта, пожалуйста, укажите сервер, имя комнаты и имя игрока.\n• Пример: en-#parkour10 Blank#3495 троллинг\nДоказательства, такие как скриншоты, видео и гифки, полезны и ценны, но не обязательны.\n\n<font size = '11'>• <font color = '#ef1111'>читы, глюки или баги</font> не должны использоваться в комнатах #parkour\n• <font color = '#ef1111'>Фарм через VPN</font> считается <B>нарушением</B> и не допускается. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nЛюбой, кто пойман за нарушение этих правил, будет немедленно забанен.</B></font></p>\n\n<font size = '12'>Transformice позволяет концепцию троллинга. Однако, <font color='#cc2222'><B>мы не допустим этого в паркуре.B></font></font>\n\n<p align = 'center'><J>Троллинг - это когда игрок преднамеренно использует свои способности, чтобы помешать другим игрокам закончить карту.</j></p>\n• Троллинг ради мести <Bне является веской причиной,</B> для троллинга кого-либо и вы все равно будете наказаны.\n• Принудительная помощь игрокам, которые пытаются пройти карту самостоятельно и отказываюся от помощи, когда их об этом просят, также считается троллингом. \n• <J>Если игрок не хочет помогать или предпочитает играть в одиночку на карте, постарайтесь помочь другим игрокам</J>. Однако, если другой игрок нуждается в помощи на том же чекпоинте, что и соло игрок, вы можете помочь им [обоим].\n\nЕсли игрок пойман на троллинге, он будет наказан на один раунд, либо на все время пребывания в паркуре. Обратите внимание, что повторный троллинг приведет к более длительным и суровым наказаниям.",
			help_contribute = "<font size='14'>Команда управления паркуром дает доступ к исходному коду, потому что это помогает нашему комьюнити. Вы можете увидеть и изменить исходный код #parkour на GitHub <a href='event:github'><u>(нажми сюда)</u></a>.\n\nОбратите внимание, что мы поддерживаем модуль бесплатно, поэтому любая помощь (в отношении кода, сообщений об ошибках, предложений) приветствуется. Мы также поддерживаем пожертвования, которые можно сделать <a href='event:donate'><u>clicking here</u></a>. Любая пожертвованная сумма ценится и идет на улучшение #parkour.",

			-- Congratulation messages
			reached_level = "<d>Поздравляем! Вы достигли уровня <vp>%s</vp>.",
			finished = "<d><o>%s</o> завершил паркур за <vp>%s</vp> секунд, <fc>поздравляем!",
			unlocked_power = "<ce><d>%s</d> разблокировал способность <vp>%s</vp>.",
			enjoy = "<d>Наслаждайтесь своими новыми навыками!",

			-- Information messages
			paused_events = "<cep><b>[Предупреждение!]</b> <n> Модуль достиг критического предела и сейчас временно остановлен.",
			resumed_events = "<n2>Модуль был возобновлен.",
			welcome = "<n>Добро пожаловать в<t>#parkour</t>!",
			discord = "<cs>Хотите сообщить об ошибках, предложить идеи для улучшения паркура или просто пообщаться с другими игроками? Присоединяйтесь к нам на discord: <pt>%s</pt>",
			map_submissions = "<bv>Хотите увидеть свою карту в модуле? Пишите тут: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Параметры Паркура</font></p>\n\nИспользуйте желтые крепления для чекпоинтов\n\nИспользуйте <b>QWERTY</b> на клавиатуре (отключить if <b>AZERTY</b>)\n\nИспользуйте <b>M</b> горячую клавишу <b>/mort</b> (отключить <b>DEL</b>)\n\nПоказать ваше время перезарядки\n\nПоказать кнопку способностей\n\nПоказать кнопку помощь\n\nПоказать объявление о завершении карты",
			unknown = "Неизвестно",
			powers = "Способности",
			press = "<vp>Нажмите %s",
			click = "<vp>Щелчок левой кнопкой мыши",
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
		}
		--[[ End of file translations/parkour/ru.lua ]]--
		--[[ File translations/parkour/en.lua ]]--
		translations.en = {
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
			help_help = "<p align = 'center'><font size = '14'>Welcome to <T>#parkour!</T></font>\n\n<font size = '12'><J>Your goal is to reach all the checkpoints until you complete the map.</J></font></p>\n\n<font size = '11'><N>• Press <O>O</O>, type <O>!op</O> or click the <O>configuration button</O> to open the <T>options menu</T>.\n• Press <O>P</O> or click the <O>hand icon</O> at the top-right to open the <T>powers menu</T>.\n• Press <O>L</O> or type <O>!lb</O> to open the <T>leaderboard</T>.\n• Press the <O>M</O> or <O>Delete</O> key to <T>/mort</T>, you can toggle the keys in the <J>Options</J> menu.\n• To know more about our <O>staff</O> and the <O>rules of parkour</O>, click on the <T>Staff</T> and <T>Rules</T> tab respectively.</font>\n\n<p align = 'center'><font size = '13'><T>Contributions are now open! For further details, click on the <O>Contribute</O> tab!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>DISCLAIMER: Parkour staff ARE NOT Transformice staff and DO NOT have any power in the game itself, only within the module.</r>\nParkour staff ensure that the module runs smoothly with minimal issues, and are always available to assist players whenever necessary.</font></p>\nYou can type <D>!staff</D> in the chat to see the staff list.\n\n<font color = '#E7342A'>Administrators:</font> They are responsible for maintaining the module itself by adding new updates and fixing bugs.\n\n<font color = '#843DA4'>Team Managers:</font> They oversee the Moderator and Mapper teams, making sure they are performing their jobs well. They are also responsible for recruiting new members to the staff team.\n\n<font color = '#FFAAAA'>Moderators:</font> They are responsible for enforcing the rules of the module and punishing individuals who do not follow them.\n\n<font color = '#25C059'>Mappers:</font> They are responsible for reviewing, adding, and removing maps within the module to ensure that you have an enjoyable gameplay.",
			help_rules = "<font size = '13'><B><J>All rules in the Transformice Terms and Conditions also apply to #parkour</J></B></font>\n\nIf you find any player breaking these rules, whisper the parkour mods in-game. If no mods are online, then it is recommended to report it in the discord server.\nWhen reporting, please include the server, room name, and player name.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidence, such as screenshots, videos and gifs are helpful and appreciated, but not necessary.\n\n<font size = '11'>• No <font color = '#ef1111'>hacks, glitches or bugs</font> are to be used in #parkour rooms\n• <font color = '#ef1111'>VPN farming</font> will be considered an <B>exploit</B> and is not allowed. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nAnyone caught breaking these rules will be immediately banned.</B></font></p>\n\n<font size = '12'>Transformice allows the concept of trolling. However, <font color='#cc2222'><B>we will not allow it in parkour.</B></font></font>\n\n<p align = 'center'><J>Trolling is when a player intentionally uses their powers to prevent other players from finishing the map.</j></p>\n• Revenge trolling is <B>not a valid reason</B> to troll someone and you will still be punished.\n• Forcing help onto players trying to solo the map and refusing to stop when asked is also considered trolling.\n• <J>If a player does not want help or prefers to solo a map, please try your best to help other players</J>. However if another player needs help in the same checkpoint as the solo player, you can help them [both].\n\nIf a player is caught trolling, they will be punished on either a time or parkour round basis. Note that repeated trolling will lead to longer and more severe punishments.",
			help_contribute = "<font size='14'>The parkour management team loves open source code, because it helps the community. You can see and modify #parkour's source code on github <a href='event:github'><u>(click here)</u></a>.\n\nNote that we are maintaining the module for free, so any help (regarding code, bug reports, suggestions) is welcomed. We also support donations, which can be done by <a href='event:donate'><u>clicking here</u></a>. Any amount donated is appreciated and will go towards improving #parkour.",

			-- Congratulation messages
			reached_level = "<d>Congratulations! You've reached level <vp>%s</vp>.",
			finished = "<d><o>%s</o> finished the parkour in <vp>%s</vp> seconds, <fc>congratulations!",
			unlocked_power = "<ce><d>%s</d> unlocked the <vp>%s</vp> power.",
			enjoy = "<d>Enjoy your new skills!",

			-- Information messages
			paused_events = "<cep><b>[Warning!]</b> <n>The module has reached it's critical limit and is being paused.",
			resumed_events = "<n2>The module has been resumed.",
			welcome = "<n>Welcome to <t>#parkour</t>!",
			discord = "<cs>Do you want to report bugs, make suggestions or just want to chat with other players? Join us on discord: <pt>%s</pt>",
			map_submissions = "<bv>Do you want to see your map in the module? Submit them here: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Parkour Options</font></p>\n\nUse particles for checkpoints\n\nUse <b>QWERTY</b> keyboard (disable if <b>AZERTY</b>)\n\nUse <b>M</b> hotkey for <b>/mort</b> (disable for <b>DEL</b>)\n\nShow your power cooldowns\n\nShow powers button\n\nShow help button\n\nShow map completion announcements",
			unknown = "Unknown",
			powers = "Powers",
			press = "<vp>Press %s",
			click = "<vp>Left click",
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
		}
		--[[ End of file translations/parkour/en.lua ]]--
		--[[ File translations/parkour/es.lua ]]--
		translations.es = {
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
			help_help = "<p align = 'center'><font size = '14'>¡Bienvenido a <T>#parkour!</T></font>\n\n<font size = '12'><J>Tu objetivo es alcanzar todos los puntos de control hasta que completes el mapa.</J></font></p>\n\n<font size = '11'><N>• Presiona la tecla <O>O</O>, escribe <O>!op</O> o clickea el <O>botón de configuración</O> para abrir el <T>menú de opciones</T>.\n• Presiona la tecla <O>P</O> o clickea el <O>ícono de la mano</O> arriba a la derecha para abrir el <T>menú de poderes</T>.\n• Presiona la tecla <O>L</O> o escribe <O>!lb</O> para abrir el <T>ranking</T>.\n• Presiona la tecla <O>M</O> o <O>Delete</O> como atajo para <T>/mort</T>, podes alternarlas en el menú de <J>Opciones</J>.\n• Para conocer más acerca de nuestro <O>staff</O> y las <O>reglas de parkour</O>, clickea en las pestañas de <T>Staff</T> y <T>Reglas</T>.</font>\n\n<p align = 'center'><font size = '13'><T>¡Las contribuciones están abiertas! Para más detalles, ¡clickea en la pestaña <O>Contribuir</O>!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>NOTA: El staff de Parkour NO ES staff de Transformice y NO TIENEN ningún poder en el juego, sólamente dentro del módulo.</r>\nEl staff de Parkour se asegura de que el módulo corra bien con la menor cantidad de problemas, y siempre están disponibles para ayudar a los jugadores cuando sea necesario.</font></p>\nPuedes escribir <D>!staff</D> en el chat para ver la lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> Son los responsables de mantener el módulo añadiendo nuevas actualizaciones y arreglando bugs.\n\n<font color = '#843DA4'>Lideres de Equipos:</font> Ellos supervisan los equipos de Moderadores y Mappers, asegurándose de que hagan un buen trabajo. También son los responsables de reclutar nuevos miembros al staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> Son los responsables de ejercer las reglas del módulo y sancionar a quienes no las sigan.\n\n<font color = '#25C059'>Mappers:</font> Son los responsables de revisar, añadir y quitar mapas en el módulo para asegurarse de que tengas un buen gameplay.",
			help_rules = "<font size = '13'><B><J>Todas las reglas en los Terminos y Condiciones de Transformice también aplican a #parkour</J></B></font>\n\nSi encuentras algún jugador rompiendo estas reglas, susurra a los moderadores de parkour en el juego. Si no hay moderadores online, es recomendable reportarlo en discord.\nCuando reportes, por favor agrega el servidor, el nombre de la sala, y el nombre del jugador.\n• Ej: en-#parkour10 Blank#3495 trollear\nEvidencia, como fotos, videos y gifs ayudan y son apreciados, pero no son necesarios.\n\n<font size = '11'>• No se permite el uso de <font color = '#ef1111'>hacks, glitches o bugs</font>\n• <font color = '#ef1111'>Farmear con VPN</font> será considerado un <B>abuso</B> y no está permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nCualquier persona rompiendo estas reglas será automáticamente baneado.</B></font></p>\n\n<font size = '12'>Transformice acepta el concepto de trollear. Pero <font color='#cc2222'><B>no está permitido en #parkour.</B></font></font>\n\n<p align = 'center'><J>Trollear es cuando un jugador intencionalmente usa sus poderes para hacer que otros jugadores no completen el mapa.</j></p>\n• Trollear como revancha <B>no es una razón válida</B> para trollear a alguien y aún así seras sancionado.\n• Ayudar a jugadores que no quieren completar el mapa con ayuda y no parar cuando te lo piden también es considerado trollear.\n• <J>Si un jugador no quiere ayuda, por favor ayuda a otros jugadores</J>. Sin embargo, si otro jugador necesita ayuda en el mismo punto, puedes ayudarlos [a los dos].\n\nSi un jugador es atrapado trolleando, será sancionado ya sea en base de tiempo o de rondas. Trollear repetidas veces llevará a sanciones más largas y severas.",
			help_contribute = "<font size='14'>El equipo de mantenimiento de parkour ama el código abierto, porque ayuda a la comunidad. Puedes ver y modificar el código fuente de #parkour en github <a href='event:github'><u>(click aquí)</u></a>.\n\nNosotros mantenemos el módulo de manera gratuita, por lo que cualquier ayuda (ya sea en el código, reportes de bugs, sugerencias) es bienvenida. También aceptamos donaciones, las cuales pueden ser hechas <a href='event:donate'><u>clickeando aquí</u></a>. Cualquier cantidad donada es apreciada y será destinada a mejorar #parkour.",

			-- Congratulation messages
			reached_level = "<d>¡Felicitaciones! Alcanzaste el nivel <vp>%s</vp>.",
			finished = "<d><o>%s</o> completó el parkour en <vp>%s</vp> segundos, <fc>¡felicitaciones!",
			unlocked_power = "<ce><d>%s</d> desbloqueó el poder <vp>%s<ce>.",
			enjoy = "<d>¡Disfruta tus nuevas habilidades!",

			-- Information messages
			paused_events = "<cep><b>[¡Advertencia!]</b> <n>El módulo está entrando en estado crítico y está siendo pausado.",
			resumed_events = "<n2>El módulo ha sido reanudado.",
			welcome = "<n>¡Bienvenido a <t>#parkour</t>!",
			discord = "<cs>¿Tienes alguna buena idea, reporte de bug o simplemente quieres hablar con otros jugadores? Entra a nuestro servidor de discord: <pt>%s</pt>",
			map_submissions = "<bv>¿Quieres ver tu mapa en el módulo? Publicalo aquí: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Opciones de Parkour</font></p>\n\nUsar partículas para los checkpoints\n\nUsar teclado <b>QWERTY</b> (desactivar si usas <b>AZERTY</b>)\n\nUsar la tecla <b>M</b> como atajo para <b>/mort</b> (desactivar si usas <b>DEL</b>)\n\nMostrar tiempos de espera de tus poderes\n\nMostrar el botón de poderes\n\nMostrar el botón de ayuda\n\nMostrar mensajes al completar un mapa",
			unknown = "Desconocido",
			powers = "Poderes",
			press = "<vp>Presiona %s",
			click = "<vp>Haz clic",
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
		}
		--[[ End of file translations/parkour/es.lua ]]--
		--[[ File translations/parkour/fr.lua ]]--
		translations.fr = {
			-- Error messages
			corrupt_map = "<r>Carte non opérationelle. Chargement d'une autre.",
			corrupt_map_vanilla = "<r>[ERROR] <n>Impossible de récolter les information de cette carte.",
			corrupt_map_mouse_start = "<r>[ERROR] <n>Cette carte a besoin d'un point d'apparition (pour les souris).",
			corrupt_map_needing_chair = "<r>[ERROR] <n>La carte a besoin d'une chaise de fin (point final).",
			corrupt_map_missing_checkpoints = "<r>[ERROR] <n>La carte a besoin d'au moins d'un point de sauvegarde (étoiles jaunes).",
			corrupt_data = "<r>Malheureusment, vos donnés ont été corrompues et ont été effacé.",
			min_players = "<r>Pour sauvegarder vos donnés, il doit y avoir au moins 4 souris dans le salon. <bl>[%s/%s]",
			tribe_house = "<r>Les données ne sont pas sauvées dans les maisons de tribus..",
			invalid_syntax = "<r>Syntaxe invalide.",
			user_not_in_room = "<r>Le joueur <n2>%s</n2> n'est pas dans le salon.",
			arg_must_be_id = "<r>L'argument doit Être un ID valide.",
			cant_update = "<r>Impossible de mettre à jour les rangs des joueurs pour l'instant. Essayer plus tard.",
			cant_edit = "<r>Vous ne pouvez pas modifier le rang de <n2>%s's</n2>.",
			invalid_rank = "<r>Rang invalide: <n2>%s",
			code_error = "<r>Une erreur est survenue: <bl>%s-%s-%s %s",
			panic_mode = "<r>Module est maintenant en mode panique.",
			public_panic = "<r>Merci d'attendre jusqu'à ce que le robot arrive et redémarre le serveur.",
			tribe_panic = "<r>Veuillez ecrire <n2>/module parkour</n2> pour redémarrer le module.",
			emergency_mode = "<r>Mise en place du bloquage d'urgence, aucun nouveau joueur ne peut rejoindre. Merci d'aller dans un autre salon de #parkour.",
			bot_requested = "<r>Le robot à été solicité, il devrait arrivé dans un moment.",
			stream_failure = "<r>Echec de la chaine de stream interne. Impossible de transmettre les données.",
			maps_not_available = "<r>#parkour's 'maps' est seulement disponible dans <n2>*#parkour0maps</n2>.",
			version_mismatch = "<r>Le robot (<d>%s</d>) et Lua(<d>%s</d>) ne marche pas ensemble. Impossible de démarrer le système.",
			missing_bot = "<r>Robot absent. Attendez jusqu'à ce que le robot arrive ou mentionnez @Tocu#0018 sur Discord: <d>%s</d>",
			invalid_length = "<r>Votre message doit obligatoirement avoir entre 10 et 100 caractères. Il a seulement <n2>%s</n2> characters.",
			invalid_map = "<r>Carte invalide.",
			map_does_not_exist = "<r>Cette carte n'existe pas ou ne peut pas Être chargé. Essayez plus tard.",
			invalid_map_perm = "<r>Cette carte n'est pas P22 ou P41.",
			invalid_map_perm_specific = "<r>La carte n'est pas P%s.",
			cant_use_this_map = "<r>Cette carte a un bug et ne peut pas Être utilisée.",
			invalid_map_p41 = "<r>Cette carte est en P41, mais n'est pas dans la liste des cartes de ce module.",
			invalid_map_p22 = "<r>Cette carte est en P22, mais n'est pas dans la liste des cartes de ce module.",
			map_already_voting = "<r>Cette garde a déjà un vote en cours.",
			not_enough_permissions = "<r>Vous n'avez pas assez de permissions pour faire ça.",
			already_depermed = "<r>Cette carte est déjà non-permanente.",
			already_permed = "<r>Cette carte est déjà permanente.",
			cant_perm_right_now = "<r>Impossible de changer les permissions de cette carte maintenant. Essayez plus tard.",
			already_killed = "<r>Le joueur %s a déjà été tué.",
			leaderboard_not_loaded = "<r>Le tableau des scores n'a pas été cahrgé encore. Attendez une minute.",

			-- Help window
			help = "Aide",
			staff = "Staff",
			rules = "Règles",
			contribute = "Contribuer",
			help_help = "<p align = 'center'><font size = '14'>Bienvenue à <T>#parkour!</T></font>\n\n<font size = '12'><J>Votre but est de parcourir tous les points de sauvegarde pour finir la carte.</J></font></p>\n\n<font size = '11'><N>â€¢ Press <O>O</O>, type <O>!op</O> ou cliquez le <O>configuration button</O> pour ouvrir le <T>options menu</T>.\nâ€¢ Press <O>P</O> ou cliquez le <O>hand icon</O> en haut à droite pour ouvrir <T>powers menu</T>.\nâ€¢ Press <O>L</O> ou écrivez <O>!lb</O> pour ouvrir le <T>leaderboard</T>.\nâ€¢ Appuyez sur <O>M</O> ou la touche <O>Delete</O> pour <T>/mort</T>, vous pouvez personnalisez les touches dans <J>Options</J> menu.\nâ€¢ Pour savoir plus à propos de notre <O>staff</O> et des <O>rules of parkour</O>, cliquez sur les pages respectives du <T>Staff</T> et des <T>Rules</T>.</font>\n\n<p align = 'center'><font size = '13'><T>Les contributions sont maintenant ouvertes ! pour plus d'informations, cliquez sur la page <O>Contribute</O> </T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>INFORMATION: Le Staff de Parkour ne sont pas Staff de Transformice, ils n'ont aucun pouvoir sur le jeu soit-meme, seulement dans ce module.</r>\nLe Staff de Parkour s'assure que le module marche bien avec des issues minimales et sont toujours disponibles pour aider les joueurs.</font></p>\nVous pouvez écrire <D>!staff</D> dans le chat pour voir la liste du Staff.\n\n<font color = '#E7342A'>Administrateurs:</font> Ils sont responsables de maintenir le module soit-meme en ajoutant des mise à jours et en réparant les bugs.\n\n<font color = '#843DA4'>Manageurs des équipes:</font> Ils surveillent les modérateurs et les créateurs de cartes, surveillant s'ils font bien leur travail. Ils sont aussi responsable du recrutement de nouveau membre du Staff.\n\n<font color = '#FFAAAA'>Modérateurs:</font> Ils font respecter les règles du module et punissent ceux qui les enfreignent.\n\n<font color = '#25C059'>Mappers:</font> Ils sont aussi responsable de vérifier, ajotuer et de supprimer des cartes dans le module pour rendre vos parties meilleurs.",
			help_rules = "<font size = '13'><B><J>All Les Regles de Termes et de Conditions de Transformice s'appliquent aussi dans #parkou.r</J></B></font>\n\nSi vous surprenez un joueur enfreignant les règles, chuchotez à un modérateur du module #parkour connecté. Si aucun modérateur n'est en ligne, reportez le dans le serveur Discord.\nPour tous reports, inclusez : le serveur, le nom du salon, et le nom du joueur.\nâ€¢ Ex: en-#parkour10 Blank#3495 trolling\nDes preuves, comme des captures d'écran, des vidéos et des GIFs aident et sont appréciés, mais pas nécessaires.\n\n<font size = '11'>â€¢ Aucun <font color = '#ef1111'> piratage, aucune corruption ou bugs</font> utilisés/abusés dans les salons #parkour\nâ€¢ <font color = '#ef1111'>VPN farming</font> seront considérés comme <B>une violation</B> et ne sont pas autorisés. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nN'importe qui surprit en train d'enfreindre ces règles sera banni.</B></font></p>\n\n<font size = '12'>Transformice autorise le concept du troll. Mais, <font color='#cc2222'><B>wenous ne l'autorisons pas dans #parkour.</B></font></font>\n\n<p align = 'center'><J>Quelqu'un troll si il empeche, grace à ses pouvoirs, de laisser les autres joueurs finir la carte.</j></p>\nâ€¢ Le troll en revanche d'un autre troll<B>n'est pas une raison valable</B> et vous serez quand meme puni.\nâ€¢ Aider un joueur qui a dit qu'il voulait faire la carte seule est aussi considéré comme du trolling.\nâ€¢ <J>Si un joueur veut réaliser la carte sans aide, merci de le laisser libre de son choix et d'aider les autres joueurs</J>. Si un autre joueur a besoin d'aide au meme point de sauvegarde que celui-ci, vous pouvez aider les deux.\n\nSi un joueur est surpris en train de troller, il sera punis par sois un certains temps ou attendre un certain temps de cartes parkour sans pouvoir les jouer. Notez que du troll répétitif peut amener à des sanctions de plus en plus sévères.",
			help_contribute = "<font size='14'>L'équipe du staff de gérement de la communauté adore donner des sources de codes, car cela aide la communauté. vous povuez voir les sources et codes de #parkour et les modifier dans github<a href='event:github'><u>(cliquez ici)</u></a>.\n\nNotez que nous entretenons le module gratuitement, donc n'importe quel aide (que ça soit code, bugs, suggestions) est la bienvenue. Nous proposons aussi des dons, qui peuvent etre réalisés sur<a href='event:donate'><u>cliquez ici</u></a>. N'importe quel somme de don est la bienvenue et sera utilisée dans l'amélioration de #parkour.",

			-- Congratulation messages
			reached_level = "<d>Bravo! Vous avez atteint le niveau <vp>%s</vp>.",
			finished = "<d><o>%s</o> a finis le parcour en <vp>%s</vp> secondes, <fc>congratulations!",
			unlocked_power = "<ce><d>%s</d> a débloqué le pouvoir<vp>%s</vp>.",
			enjoy = "<d>Profite de tes nouvelles compétences!",

			-- Information messages
			paused_events = "<cep><b>[Attention!]</b> <n>Le module a atteint sa limite critique et est en pause.",
			resumed_events = "<n2>Le module n'est plus en pause.",
			welcome = "<n>Bienvenue à<t>#parkour</t>!",
			discord = "<cs>Voulez-vous reporter des bugs ? Proposer des suggestions ou simplement parler avec d'autres joueurs ? Rejoignez notre serveur discord : <pt>%s</pt>",
			map_submissions = "<bv>Voulez-vous voir votre carte dans le module ? Soumettez-les ici : <j>%s</j>",
			type_help = "<pt>Nous vous recommandons d'utiliser la commande <d>!help</d> pour voir des informtion utiles !",
			data_saved = "<vp>Données enregistrées.",
			action_within_minute = "<vp>Cette action sera réalisée dans quelque minutes.",
			rank_save = "<n2>Ecrivez <d>!rank save</d> pour appliquer les changements.",
			module_update = "<r><b>[Attention!]</b> <n>Le module va se réinitialiser dans<d>%02d:%02d</d>.",
			mapping_loaded = "<j>[INFO] <n>Système de carte<t>(v%s)</t> chargé.",
			mapper_joined = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a rejoinds le salon.",
			mapper_left = "<j>[INFO] <n><ce>%s</ce> <n2>(%s)</n2> a quitté le salon.",
			mapper_loaded = "<j>[INFO] <n><ce>%s</ce> a chargé la carte.",
			starting_perm_change = "<j>[INFO] <n>Commencement du changement de permissions...",
			got_map_info = "<j>[INFO] <n>Informations de la carte récupérées. Essaie de changement de permissions...",
			perm_changed = "<j>[INFO] <n>Réussite du changement de permission de la carte<ch>@%s</ch> from <r>P%s</r> to <t>P%s</t>.",
			leaderboard_loaded = "<j>Le tableau des scores a été chargé. Appuyer sur L pour l'ouvrir.",
			kill_minutes = "<R>Vos pouvoirs ont été désactivés pour %s minutes.",
			kill_map = "<R>Vos pouvoirs ont été désactivés jusqu'à la prochaine carte.",

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Options de Parkour</font></p>\n\nUtilisez les particules comme points de sauvegarde\n\nUtilisez le clavier <b>QWERTY</b> (désactivez si votre clavier et en <b>AZERTY</b>)\n\nUtilisez <b>M</b> touche chaude pour <b>/mort</b> (désactivez pour <b>DEL</b>)\n\nMontre le cooldown de vos compétences\n\nMontre les boutons pour utiiser les compétences\n\nMontre le bouton d'aide\n\nMontre les annonces des cartes achevées",
			unknown = "Inconnu",
			powers = "Pouvoirs",
			press = "<vp>Appuyer sur %s",
			click = "<vp>Clique gauche",
			completed_maps = "<p align='center'><BV><B>Cartes complétées: %s</B></p></BV>",
			leaderboard = "Tableau des scores",
			position = "Position",
			username = "Pseudo",
			community = "Communauté",
			completed = "Cartes complétées",
			not_permed = "sans permissions",
			permed = "avec des permissions",
			points = "%d points",
			conversation_info = "<j>%s <bl>- @%s <vp>(%s, %s) %s\n<n><font size='10'>Started by <d>%s</d>. Dernier commentaire par <d>%s</d>. <d>%s</d> commentaire(s), <d>%s</d> non-lu(s).",
			map_info = "<p align='center'>Code de la carte: <bl>@%s</bl> <g>|</g> Auteur de la carte: <j>%s</j> <g>|</g> Status: <vp>%s, %s</vp> <g>|</g> Points: <vp>%s</vp>",
			permed_maps = "Maps ayant des permissions",
			ongoing_votations = "Votes en cours",
			archived_votations = "Votes archivés",
			open = "Ouvrir",
			not_archived = "non-archivée",
			archived = "archivée",
			delete = "<r><a href='event:%s'>[supprimer]</a> ",
			see_restore = "<vp><a href='event:%s'>[voir]</a> <a href='event:%s'>[restaurer]</a> ",
			no_comments = "Pas de commentaires.",
			deleted_by = "<r>[Message supprimé par %s]",
			dearchive = "inarchiver", -- pour ne plus l'archiver
			archive = "archive", -- pour archiver
			deperm = "enlever les permissions", -- pour enlever les permissions
			perm = "permissions", -- pour ajouter des permissions
			map_actions_staff = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a> <g>|</g> Votre  vote: %s <g>|</g> <vp><a href='event:%s'>[%s]</a> <a href='event:%s'>[%s]</a> <a href='event:%s'>[chargement]</a></p>",
			map_actions_user = "<p align='center'><a href='event:%s'>&lt;</a> %s <a href='event:%s'>&gt;</a> <g>|</g> <a href='event:%s'><j>Commentaire</j></a></p>",
			load_from_thread = "<p align='center'><a href='event:load_custom'>Charger une carte personalisée</a></p>",
			write_comment = "Ecrivez votre commentaire en-dessous",
			write_map = "Ecrivez les codes de la carte en-dessous",

			-- Power names
			balloon = "Ballon",
			masterBalloon = "Maitre Ballon",
			bubble = "Bulle",
			fly = "Voler",
			snowball = "Boule de neige",
			speed = "Vitesse",
			teleport = "Teleportation",
			smallbox = "Petite boite",
			cloud = "Nuage",
			rip = "Tombe",
			choco = "Planche de chocolat",
		}
		--[[ End of file translations/parkour/fr.lua ]]--
		--[[ File translations/parkour/br.lua ]]--
		translations.br = {
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
			help_help = "<p align = 'center'><font size = '14'>Bem-vindo ao <T>#parkour!</T></font>\n\n<font size = '12'><J>Seu objetivo é chegar em todos os checkpoints até que você complete o mapa.</J></font></p>\n\n<font size = '11'><N>• Aperte <O>O</O>, digite <O>!op</O> ou clique no <O>botão de configuração</O> para abrir o <T>menu de opções</T>.\n• Aperte <O>P</O> ou clique no <O>ícone de mão</O> no parte superior direita para abrir o <T>menu de poderes</T>.\n• Aperte <O>L</O> ou digite <O>!lb</O> parar abrir o <T>ranking</T>.\n• Aperte <O>M</O> ou a tecla <O>Delete</O> para <T>/mort</T>, você pode alterar as teclas no moenu de <J>Opções</J>.\n• Para saber mais sobre nossa <O>staff</O> e as <O>regras do parkour</O>, clique nas abas <T>Staff</T> e <T>Regras</T>, respectivamente.</font>\n\n<p align = 'center'><font size = '13'><T>Contribuições agora estão disponíveis! Para mais detalhes, clique na aba <O>Contribuir</O>!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>AVISO: A staff do Parkour não faz parte da staff do Transformice e não tem nenhum poder no jogo em si, apenas no módulo.</r>\nStaff do Parkour assegura que o módulo rode com problemas mínimos, e estão sempre disponíveis para dar assistência aos jogadores quando necessário.</font></p>\nVocê pode digitar <D>!staff</D> no chat para ver a lista de staff.\n\n<font color = '#E7342A'>Administradores:</font> São responsáveis por manter o módulo propriamente dito, atualizando-o e corrigindo bugs.\n\n<font color = '#843DA4'>Gerenciadores das Equipes:</font> Observam as equipes de Moderação e de Mapas, assegurando que todos estão fazendo um bom trabalho. Também são responsáveis por recrutar novos membros para a staff.\n\n<font color = '#FFAAAA'>Moderadores:</font> São responsáveis por aplicar as regras no módulo e punir aqueles que não as seguem.\n\n<font color = '#25C059'>Mappers:</font> São responsáveis por avaliar, adicionar e remover mapas do módulo para assegurar que você tenha uma jogatina divertida.",
			help_rules = "<font size = '13'><B><J>Todas as regras nos Termos e Condições de Uso do Transformice também se aplicam no #parkour</J></B></font>\n\nSe você encontrar algum jogador quebrando-as, cochiche com um moderador do #parkour no jogo. Se os moderadores não estiverem online, recomendamos que reporte em nosso servidor no Discord.\nAo reportar, por favor inclua a comunidade, o nome da sala e o nome do jogador.\n• Ex: en-#parkour10 Blank#3495 trolling\nEvidências, como prints, vídeos e gifs são úteis e apreciados, mas não necessários.\n\n<font size = '11'>• Uso de <font color = '#ef1111'>hacks, glitches ou bugs</font> são proibidos em salas #parkour\n• <font color = '#ef1111'>Farm VPN</font> será considerado um <B>abuso</B> e não é permitido. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nQualquer um pego quebrando as regras será banido imediatamente.</B></font></p>\n\n<font size = '12'>Transformice permite trollar. No entanto, <font color='#cc2222'><B>não permitiremos isso no parkour.</B></font></font>\n\n<p align = 'center'><J>Trollar é quando um jogador usa seus poderes de forma intencional para fazer com que os outros jogadores não terminem o mapa.</j></p>\n• Trollar por vingança <B>não é um motivo válido</B> e você ainda será punido.\n• Insistir em ajudar jogadores que estão tentando terminar o mapa sozinhos e se recusando a parar quando pedido também será considerado trollar.\n• <J>Se um jogador não quer ajuda e prefere completar o mapa sozinho, dê seu melhor para ajudar os outros jogadores</J>. No entanto, se outro jogador que precisa de ajuda estiver no mesmo checkpoint daquele que quer completar sozinho, você pode ajudar ambos sem receber punição.\n\nSe um jogador for pego trollando, serão punidos por um tempo determinado ou por algumas partidas. Note que trollar repetidamente irá fazer com que você receba punições gradativamente mais longas e/ou severas.",
			help_contribute = "<font size='14'>A equipe de gerenciamento do parkour ama código-fonte aberto, porque isso ajuda a comunidade. Você pode ver e modificar o código do módulo no github <a href='event:github'><u>(clicando aqui)</u></a>.\n\nNote que estamos mantendo o módulo de graça, então qualquer ajuda (seja código, report de bugs, sugestões) é bem-vinda. Também podemos receber doações, que podem ser feitas <a href='event:donate'><u>clicando aqui</u></a>. Qualquer valor é apreciado e será usado para melhorar o #parkour.",

			-- Congratulation messages
			reached_level = "<d>Parabéns! Você atingiu o nível <vp>%s</vp>.",
			finished = "<d><o>%s</o> terminou o parkour em <vp>%s</vp> segundos, <fc>parabéns!",
			unlocked_power = "<ce><d>%s</d> desbloqueou o poder <vp>%s</vp>.",
			enjoy = "<d>Aproveite suas novas habilidades!",

			-- Information messages
			paused_events = "<cep><b>[Atenção!]</b> <n>O módulo está atingindo um estado crítico e está sendo pausado.",
			resumed_events = "<n2>O módulo está se normalizando.",
			welcome = "<n>Bem-vindo(a) ao <t>#parkour</t>!",
			discord = "<cs>Tendo alguma boa ideia, report de bug ou apenas querendo conversar com outros jogadores? Entre em nosso servidor no Discord: <pt>%s</pt>",
			map_submissions = "<bv>Quer ver seu mapa no módulo? Poste-o aqui: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Opções do Parkour</font></p>\n\nUsar partículas para os checkpoints\n\nUsar o teclado <b>QWERTY</b> (desativar caso seja <b>AZERTY</b>)\n\nUsar a tecla <b>M</b> como <b>/mort</b> (desativar caso seja <b>DEL</b>)\n\nMostrar o delay do seu poder\n\nMostrar o botão de poderes\n\nMostrar o botão de ajuda\n\nMostrar mensagens de mapa completado",
			unknown = "Desconhecido",
			powers = "Poderes",
			press = "<vp>Aperte %s",
			click = "<vp>Use click",
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
		}
		--[[ End of file translations/parkour/br.lua ]]--
		--[[ File translations/parkour/tr.lua ]]--
			translations.tr = {
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
			help_help = "<p align = 'center'><font size = '14'>Hoşgeldiniz. <T>#parkour!</T></font>\n\n<font size = '12'><J>Amacınız haritayı tamamlayana kadar bütün kontrol noktalarına ulaşmak.</J></font></p>\n\n<font size = '11'><N>•  Ayarlar menüsü açmak için klavyeden<O>O</O>tuşuna basabilir, <O>!op</O> yazabilir veya <O>çark</O>simgesine tıklayabilirsiniz.\n• Beceri menüsüne ulaşmak için klavyeden <O>P</O> tuşuna basabilir veya sağ üst köşedeki <O>El</O> simgesine tıklayabilirsiniz.\n• Lider tablosuna ulaşmak için <O>L</O> tuşuna basabilir veya <O>!lb</O> yazabilirsiniz.\n• Ölmek için <O>M</O> veya <O>Delete</O> tuşuna basabilirsiniz. <O>Delete</O> tuşunu kullanabilmek için <J>Ayarlar</J>ksımından <O>M</O> tuşu ile ölmeyi kapatmanız gerekmektedir.\n•  Ekip ve parkur kuralları hakkında daha fazla bilgi bilgi almak için, <O>Ekip</O> ve <O>Kurallar</O> sekmesine tıklayın.</font>\n\n<p align = 'center'><font size = '13'><T>Artık bize bağışta bulunabilirsiniz! Daha fazla bilgi için, <O>Bağış</O> sekmesine tıklayın!</T></font></p>",
			help_staff = "<p align = 'center'><font size = '13'><r>Bildiri: Parkour ekibi Transformice'ın ekibi DEĞİLDİR, sadece parkour modülünde yetkililerdir.</r>\nParkur ekibi modülün akıcı bir şekilde kalmasını sağlar ve her zaman oyunculara yardımcı olurlar.</font></p>\nEkip listesini görebilmek için <D>!staff</D> yazabilirsiniz.\n\n<font color = '#E7342A'>Administrators:</font> Modülü yönetmek, yeni güncellemeler getirmek ve hataları/bugları düzeltirler.\n\n<font color = '#843DA4'>Team Managers:</font> Modları ve Mapperları kontrol eder ve işlerini iyi yaptıklarından emin olurlar. Ayrıca ekibe yeni modlar almaktan da onlar sorumludur.\n\n<font color = '#FFAAAA'>Moderators:</font> Kuralları uygulamak ve uygulamayan oyuncuları cezalandırmaktan sorumludurlar.\n\n<font color = '#25C059'>Mappers:</font> Yeni yapılan haritaları inceler, harita listesine ekler ve siz oyuncularımızın eğlenceli bir oyun deneyimi geçirmenizi sağlarlar.",
			help_rules = "<font size = '13'><B><J>Transformice bütün kural ve koşulları #parkour içinde geçerlidir</J></B></font>\n\nEğer kurallara uymayan bir oyuncu görürseniz,oyun içinde parkour ekibindeki modlardan birine mesaj atabilirsiniz. Eğer hiçbir mod çevrim içi değilse discord serverimizde rapor edebilirsiniz.\nRapor ederken lütfen serveri, oda ismini ve oyuncu ismini belirtiniz.\n• Örnek: tr-#parkour10 Sperjump#6504 trolling\nEkran görüntüsü,video ve gifler işe yarayacaktır fakat gerekli değildir..\n\n<font size = '11'>•#parkour odalarında <font color = '#ef1111'>hack ve bug</font>kullanmak YASAKTIR!\n• <font color = '#ef1111'>VPN farming</font> yasaktır, <B>Haksız kazanç elde etmeyin</B> .. <p align = 'center'><font color = '#cc2222' size = '12'><B>\nKuralları çiğneyen herkes banlanacaktır.</B></font></p>\n\n<font size = '12'>Transformice trolleme konseptine izin verir. Fakat, <font color='#cc2222'><B>biz buna parkur modülünde izin vermeyeceğiz.</B></font></font>\n\n<p align = 'center'><J>Trollemek becerilerini diğer oyuncuların haritayı bitirmesini engellemek için kullanmak demektir..</j></p>\n• İntikam almak için trollemek <B>geçerli bir sebep değildir</B> ve cezalandırılacaktır.\n• Haritayı tek başına bitirmek isteyen bir oyuncuya zorla yardım etmeye çalışmak trollemek olarak kabul edilecek ve cezalandırılacaktır.\n• <J>Eğer bir oyuncu yardım istemiyorsa ve haritayı tek başına bitirmek istiyorsa, lütfen diğer oyunculara yardım etmeyi deneyin.</J>. Ancak yardım isteyen diğer oyuncu haritayı tek başına yapmak isteyen bir oyuncunun yanındaysa ona yardım edebilirsiniz.[both].\n\nEğer bir oyuncu trollerken yakalanırsa, zaman ve ya parkur roundları bazında cezalandırılacaktır.. Sürekli bir şekilde trollemekten dolayı ceza alan bir oyuncu eğer hala trollemeye devam ederse cezaları daha ağır olacaktır..",
			help_contribute = "<font size='14'>Parkur yönetimi açık kaynak kodlarına bayılır, çünkü topluluğumuza yardımcı oluyor. #parkour'un kaynak kodunu github'da görebilir ve ekleme yapabilirsiniz <a href='event:github'><u>(göz atmak için tıkla)</u></a>.\n\nModülü gönüllü olarak yönetiyoruz, yani her türlü (kod,bug ve hata bildirimi tavsiyeleriniz bizim için yararlı olacaktır. Ayrıca bize destek de olabilirsiniz, <a href='event:donate'><u>(destek olamk için tıkla)</u></a>. Her desteğiniz değerlidir ve #parkour'u daha da geliştirmek için kullanılacaktır.",

			-- Congratulation messages
			reached_level = "<d>Tebrikler! <vp>%s</vp>. Seviyeye ulaştınız.",
			finished = "<d><o>%s</o> parkuru <vp>%s</vp> saniyede bitirdi, <fc>Tebrikler!",
			unlocked_power = "<ce><d>%s</d>, <vp>%s</vp> becerisini açtı.",
			enjoy = "<d>Yeni becerilerinin keyfini çıkar!",

			-- Information messages
			paused_events = "<cep><b>[Dikkat!]</b> <n>Modül kritik seviyeye ulaştı ve durduruluyor.",
			resumed_events = "<n2>Modül devam ettirildi.",
			welcome = "<n><t>#parkour</t>! Odasına hoşgeldiniz.",
			discord = "<cs>Hataları bildirmek, tavsiyelerde bulunmak veya trolleyen bir oyuncuyu rapor etmek mi istiyorsunuz? Discord sunucumuza katılın: <pt>%s</pt>",
			map_submissions = "<bv>Modülde kendi yaptığınız haritanızı görmek ister misiniz? Buraya gönderin: <j>%s</j>",
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

			-- Miscellaneous
			options = "<p align='center'><font size='20'>Parkur ayarları</font></p>\n\nKontrol noktaları için parçacıkları kullan\n\n<b>QWERTY</b> klavye kullan (Kapatıldığnda <b>AZERTY</b> klavye kullanılır)\n\nÖlmek için klavyeden <b>M</b> tuşuna bas veya <b>/mort</b> komutunu kullan. (Kapattığında <b>DELETE</b> tuşuna basarak ölebilirsin.)\n\nBeceri bekleme sürelerini göster\n\nBeceriler simgesini göster\n\nYardım butonunu göster\n\nHarita bitirme duyurularını göster",
			unknown = "Bilinmiyor",
			powers = "Beceriler",
			press = "<vp>%s Tuşuna Bas",
			click = "<vp>Sol tık",
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
		}
		--[[ End of file translations/parkour/tr.lua ]]--
		--[[ End of directory translations/parkour ]]--
		--[[ File modes/parkour/timers.lua ]]--
		local timers = {}
		local aliveTimers = false

		local function addNewTimer(delay, fnc, argument)
			aliveTimers = true
			local list = timers[delay]
			if list then
				list._count = list._count + 1
				list[list._count] = {os.time() + delay, fnc, argument}
			else
				timers[delay] = {
					_count = 1,
					_pointer = 1,
					[1] = {os.time() + delay, fnc, argument}
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
							timer[2](timer[3])
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
				local timer
				for delay, list in next, timers do
					for index = list._pointer, list._count do
						timer = list[index]
						timer[2](timer[3])
					end
				end
			end
		end)
		--[[ End of file modes/parkour/timers.lua ]]--
		--[[ File modes/parkour/maps.lua ]]--
		local first_data_load = true
		local repeated = {_count = 0}
		local maps = {_count = 0}
		local is_invalid = false
		local levels

		local function newMap()
			if repeated._count == maps._count then
				repeated = {_count = 0}
			end

			local map
			repeat
				map = maps[math.random(1, maps._count)]
			until map and not repeated[map]
			repeated[map] = true
			repeated._count = repeated._count + 1

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
					maps = {_count = 1, [1] = 7171137}
				end
				if first_data_load then
					newMap()
					first_data_load = false
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
		local join_bot = "Tocutoeltuco#6919"
		local join_epoch = os.time({year=2020, month=1, day=1, hour=0})
		local join_to_delete = {_count = 0}
		local waiting_mod = false
		local next_join_check = os.time() + 15000
		local waiting_mod_timeout = 0

		onEvent("PlayerDataLoaded", function(player, data)
			if player ~= join_bot then return end

			data = json.decode(data)

			if room.name == "*#parkour0maps" then
				eventJoinSystemDataLoaded(join_bot, data)
			else
				local now = os.time() - join_epoch
				join_to_delete._count = 0

				for room_name, expire in next, data do
					if not expire[1] then
						if now >= expire[2] then
							join_to_delete._count = join_to_delete._count + 1
							join_to_delete[join_to_delete._count] = room_name

						elseif room_name == room.name then
							waiting_mod = true
							waiting_mod_timeout = now + 45000
							data[room_name] = {true, waiting_mod_timeout}

							tfm.exec.setRoomMaxPlayers(20)
						end
					end
				end

				for idx = 1, join_to_delete._count do
					data[join_to_delete[idx]] = nil
				end

				system.savePlayerData(join_bot, json.encode(data))
			end
		end)

		onEvent("Loop", function()
			local now = os.time()
			if now >= next_join_check then
				system.loadPlayerData(join_bot)
				next_join_check = now + 15000
			end
			if waiting_mod then
				tfm.exec.setRoomMaxPlayers(20)
				if now >= waiting_mod_timeout then
					waiting_mod = false
				end
			else
				tfm.exec.setRoomMaxPlayers(12)
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
		local victory = {}
		local bans = {}
		local in_room = {}
		local players_level = {}
		local generated_at = {}
		local spec_mode = {}
		local ck = {
			particles = {},
			images = {}
		}

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

		onEvent("PlayerWon", function(player, elapsed)
			victory_count = victory_count + 1
			victory[player] = true

			if victory_count == player_count then
				tfm.exec.setGameTime(20)
				less_time = true
			end
		end)

		onEvent("NewGame", function()
			check_position = 6
			victory_count = 0
			less_time = false
			victory = {}
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
				local last_level = #levels
				local level_id, next_level, player
				local particle = 29--math.random(21, 23)
				local x, y = math.random(-10, 10), math.random(-10, 10)

				for name in next, in_room do
					player = room.playerList[name]
					if bans[player.id] then
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
			tfm.exec.setRoomMaxPlayers(12)
			tfm.exec.disableAutoScore(true)
		end)
		--[[ End of file modes/parkour/game.lua ]]--
		--[[ File modes/parkour/files.lua ]]--
		next_file_load = os.time() + math.random(60500, 90500)
		local files = {
			--[[
				File values:

				- maps     (1)
				- webhooks (1 and 2)
				- update   (1)
				- ranks    (1)

				- banned   (2)
				- ranking  (2)
				- suspects (2)
			]]

			[1] = 1, -- maps, update, ranks
			[2] = 2  -- ranking, banned, suspects
		}
		local total_files = 2
		local players_file = {}
		local file_index = 1
		local fetching_player_room = {}
		file_id = files[file_index]

		local data_migrations = {
			["0.0"] = function(player, data)
				data.parkour = data.modules.parkour
				data.drawbattle = data.modules.drawbattle

				data.modules = nil

				data.parkour.v = "0.4" -- version
				data.parkour.c = data.parkour.cm -- completed maps
				data.parkour.ckpart = 1 -- particles for checkpoints (1 -> true, 0 -> false)
				data.parkour.mort = 1 -- /mort hotkey
				data.parkour.pcool = 1 -- power cooldowns
				data.parkour.pbut = 1 -- powers button
				data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1 -- 1 -> qwerty, 0 -> false
				data.parkour.killed = 0
				data.parkour.hbut = 1 -- help button
				data.parkour.congrats = 1 -- contratulations message

				data.parkour.cm = nil
			end,
			["0.1"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.ckpart = 1
				data.parkour.mort = 1
				data.parkour.pcool = 1
				data.parkour.pbut = 1
				data.parkour.keyboard = (room.playerList[player] or room).community == "fr" and 0 or 1
				data.parkour.killed = 0
				data.parkour.congrats = 1
			end,
			["0.2"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.killed = 0
				data.parkour.hbut = 1
				data.parkour.congrats = 1
			end,
			["0.3"] = function(player, data)
				data.parkour.v = "0.4"
				data.parkour.hbut = 1
				data.parkour.congrats = 1
			end
		}

		local function savePlayerData(player)
			if not players_file[player] then return end

			system.savePlayerData(
				player,
				json.encode(players_file[player])
			)
		end

		onEvent("PlayerDataLoaded", function(player, data)
			if in_room[player] then return end

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
		end)

		onEvent("PlayerDataLoaded", function(player, data)
			if not in_room[player] then return end
			if player == stream_bot or player == join_bot then return end

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
				tfm.exec.chatMessage("<v>[#] <d>" .. player .. "<n>'s room: <d>" .. (data.room or "unknown"), fetch[1])
				fetching_player_room[player] = nil
			end

			if players_file[player] then return end

			players_file[player] = data

			players_file[player].room = room.name
			savePlayerData(player)

			eventPlayerDataParsed(player, data)
		end)

		onEvent("SavingFile", function(id, data)
			system.saveFile(json.encode(data), id)
		end)

		onEvent("FileLoaded", function(id, data)
			data = json.decode(data)
			eventGameDataLoaded(data)
			eventSavingFile(id, data) -- if it is reaching a critical point, it will pause and then save the file
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
				end
			end

			for idx = 1, count do
				fetching_player_room[to_remove[idx]] = nil
			end
		end)

		onEvent("GameStart", function()
			system.loadFile(file_id)
			next_file_load = os.time() + math.random(60500, 90500)
		end)

		onEvent("NewPlayer", function(player)
			system.loadPlayerData(player)
		end)
		--[[ End of file modes/parkour/files.lua ]]--
		--[[ File modes/parkour/ranks.lua ]]--
		local band = (bit or bit32).band
		local bxor = (bit or bit32).bxor

		local ranks = {
			admin = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0}
		}
		local ranks_id = {
			admin = 2 ^ 0,
			manager = 2 ^ 1,
			mod = 2 ^ 2,
			mapper = 2 ^ 3
		}
		local ranks_permissions = {
			admin = {
				show_update = true
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
				change_map = true
			},
			mapper = {
				vote_map = true,
				change_map = true
			}
		}
		local player_ranks = {}
		local perms = {}
		local saving_ranks = false
		local ranks_update
		local updater
		local ranks_order = {"admin", "manager", "mod", "mapper"}

		for rank, perms in next, ranks_permissions do
			if rank ~= "admin" then
				for perm_name, allowed in next, perms do
					ranks_permissions.admin[perm_name] = allowed
				end
			end
		end

		onEvent("GameDataLoaded", function(data)
			if data.ranks then
				if saving_ranks then
					local added, removed, not_changed
					for player, rank in next, ranks_update do
						if data.ranks[player] then
							not_changed = band(data.ranks[player], rank)
							removed = bxor(not_changed, data.ranks[player])
							added = bxor(not_changed, rank)
						else
							removed = 0
							added = rank
						end

						if added > 0 then
							local new
							for rank, id in next, ranks_id do
								if band(id, added) > 0 then
									if new then
										new = new .. "*, *parkour-" .. rank
									else
										new = "parkour-" .. rank
									end
								end
							end

							webhooks._count = webhooks._count + 1
							webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is now a **" .. new .. "**."
						end
						if removed > 0 then
							local old
							for rank, id in next, ranks_id do
								if band(id, removed) > 0 then
									if old then
										old = old .. "*, *parkour-" .. rank
									else
										old = "parkour-" .. rank
									end
								end
							end

							webhooks._count = webhooks._count + 1
							webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is no longer a **" .. old .. "**."
						end

						if rank == 0 then
							data.ranks[player] = nil
						else
							data.ranks[player] = rank
						end
					end

					translatedChatMessage("data_saved", updater)
					ranks_update = nil
					updater = nil
					saving_ranks = false
				end

				ranks, perms, player_ranks = {
					admin = {_count = 0},
					manager = {_count = 0},
					mod = {_count = 0},
					mapper = {_count = 0}
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

		local no_powers = {}
		local facing = {}
		local cooldowns = {}

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
			local obj = tfm.exec.addShamanObject(...)
			addNewTimer(when, tfm.exec.removeObject, obj)
		end

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
			}
		}

		local keyPowers, clickPowers = {
			qwerty = {},
			azerty = {}
		}, {}
		local player_keys = {}

		local function bindNecessary(player)
			local maps = players_file[player].parkour.c
			for key, powers in next, player_keys[player] do
				if powers._count then
					for index = 1, powers._count do
						if maps >= powers[index].maps then
							system.bindKeyboard(player, key, true, true)
						end
					end
				end
			end

			for index = 1, #clickPowers do
				if maps >= clickPowers[index].maps then
					system.bindMouse(player, true)
					break
				end
			end
		end

		local function unbind(player)
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

			if not player_keys[player] or not victory[player] then return end
			local powers = player_keys[player][key]
			if not powers then return end

			local file = players_file[player].parkour
			local maps, show_cooldowns = file.c, file.pcool == 1
			local power
			for index = powers._count, 1, -1 do
				power = powers[index]
				if maps >= power.maps or room.name == "*#parkour0maps" then
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

			local file = players_file[player].parkour
			local maps, show_cooldowns = file.c, file.pcool == 1
			local power, cooldown
			for index = 1, #clickPowers do
				power = clickPowers[index]
				if maps >= power.maps or room.name == "*#parkour0maps" then
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

			if room.name ~= "*#parkour0maps" and room.uniquePlayers >= min_save and not is_tribe then
				completed = players_file[player].parkour.c + 1
				players_file[player].parkour.c = completed
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

			for player in next, in_room do
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
		local max_leaderboard_rows = 70
		local max_leaderboard_pages = math.ceil(max_leaderboard_rows / 14) - 1
		local loaded_leaderboard = false
		local leaderboard = {}
		-- {id, name, completed_maps, community}
		local default_leaderboard_user = {0, nil, 0, "xx"}

		local function leaderboardSort(a, b)
			return a[3] > b[3]
		end

		local remove, sort = table.remove, table.sort

		local function checkPlayersPosition()
			local totalRankedPlayers = #leaderboard
			local cachedPlayers = {}

			local playerId, position

			local toRemove, counterRemoved = {}, 0
			for player = 1, totalRankedPlayers do
				position = leaderboard[player]
				playerId = position[1]

				if bans[playerId] then
					counterRemoved = counterRemoved + 1
					toRemove[counterRemoved] = player
				else
					cachedPlayers[playerId] = position
				end
			end

			for index = counterRemoved, 1, -1 do
				remove(leaderboard, toRemove[index])
			end
			toRemove = nil

			totalRankedPlayers = totalRankedPlayers - counterRemoved

			local cacheData
			local playerFile, playerData, completedMaps

			for player in next, in_room do
				playerFile = players_file[player]

				if playerFile then
					completedMaps = playerFile.parkour.c
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
							leaderboard[totalRankedPlayers] = {
								playerId,
								player,
								completedMaps,
								playerData.community
							}
						end
					end
				end
			end

			sort(leaderboard, leaderboardSort)

			for index = max_leaderboard_rows + 1, totalRankedPlayers do
				leaderboard[index] = nil
			end
		end

		onEvent("GameDataLoaded", function(data)
			if data.ranking then
				if not loaded_leaderboard then
					loaded_leaderboard = true

					translatedChatMessage("leaderboard_loaded")
				end

				leaderboard = data.ranking

				checkPlayersPosition()
			end
		end)
		--[[ End of file modes/parkour/leaderboard.lua ]]--
		--[[ File modes/parkour/interface.lua ]]--
		local kill_cooldown = {}
		local save_update = false
		local update_at = 0
		local ban_actions = {_count = 0}
		local open = {}
		local powers_img = {}
		local help_img = {}
		local toggle_positions = {
			[1] = 107,
			[2] = 132,
			[3] = 157,
			[4] = 183,
			[5] = 209,
			[6] = 236,
			[7] = 262
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

		local function addWindow(id, text, player, x, y, width, height)
			if width < 0 or height and height < 0 then
				return
			elseif not height then
				height = width/2
			end
			id = 1000 + id * 8

			ui.addTextArea(id    , ""  , player, x              , y               , width+100   , height+70, 0x78462b, 0x78462b, 1, true)
			ui.addTextArea(id + 1, ""  , player, x              , y+(height+140)/4, width+100   , height/2 , 0x9d7043, 0x9d7043, 1, true)
			ui.addTextArea(id + 2, ""  , player, x+(width+180)/4, y               , (width+10)/2, height+70, 0x9d7043, 0x9d7043, 1, true)
			ui.addTextArea(id + 3, ""  , player, x              , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 4, ""  , player, x+width+80     , y               , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 5, ""  , player, x              , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 6, ""  , player, x+width+80     , y+height+50     , 20          , 20       , 0xbeb17d, 0xbeb17d, 1, true)
			ui.addTextArea(id + 7, text, player, x+3            , y+3             , width+94    , height+64, 0x1c3a3e, 0x232a35, 1, true)
		end

		local function removeWindow(id, player)
			for i = 1000 + id * 8, 1000 + id * 8 + 7 do
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

		local function closeLeaderboard(player)
			if not open[player].leaderboard then return end

			removeWindow(1, player)
			removeButton(1, player)
			removeButton(2, player)
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

			for toggle = 1, 7 do
				removeToggle(toggle, player)
			end

			savePlayerData(player)

			open[player].options = nil
		end

		local function removeHelpMenu(player)
			if not open[player].help then return end

			removeWindow(7, player)

			ui.removeTextArea(10000, player)

			for button = 7, 11 do
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

			addWindow(7, "\n\n\n" .. translatedMessage("help_" .. tab, player) .. "\n\n\n", player, 200, 50, 300, 260)

			ui.addTextArea(10000, "", player, 210, 60, 390, 30, 0x1c3a3e, 0x1c3a3e, 1, true)

			addButton(7, translatedMessage("help", player), "help:help", player, 210, 60, 80, 18, tab == "help")
			addButton(8, translatedMessage("staff", player), "help:staff", player, 310, 60, 80, 18, tab == "staff")
			addButton(9, translatedMessage("rules", player), "help:rules", player, 410, 60, 80, 18, tab == "rules")
			addButton(10, translatedMessage("contribute", player), "help:contribute", player, 510, 60, 80, 18, tab == "contribute")

			addButton(11, "Close", "close_help", player, 210, 352, 380, 18, false)
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
				or ranks.mod[player] and 0xFFAAAA -- moderator
				or ranks.mapper[player] and 0x25C059 -- mapper
				or (room.xmlMapInfo and player == room.xmlMapInfo.author) and 0x10FFF3 -- author of the map
				or 0x148DE6 -- default
			)
		end

		local function showLeaderboard(player, page)
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

			if not page or page < 0 then
				page = 0
			elseif page > max_leaderboard_pages then
				page = max_leaderboard_pages
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
				if position > max_leaderboard_rows then break end
				positions = positions .. "#" .. position .. "\n"
				row = leaderboard[position] or default_leaderboard_user

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

			addButton(1, "&lt;                       ", "leaderboard_p:" .. page - 1, player, 185, 346, 210, 20, not (page > 0)                    )
			addButton(2, "&gt;                       ", "leaderboard_p:" .. page + 1, player, 410, 346, 210, 20, not (page < max_leaderboard_pages))
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
			local power, canUse
			for index = page * 3, page * 3 + 2 do
				power = powers[index + 1]
				if power then
					canUse = completed >= power.maps
					ui.addTextArea(
						3000 + index,
						string.format(
							"<p align='center'><b><d>%s\n\n\n\n\n\n\n\n<n>%s",
							power.name and translatedMessage(power.name, player) or "undefined",
							canUse and (
								power.click and
								translatedMessage("click", player) or
								translatedMessage("press", player, player_keys[player][power])
							) or completed .. "/" .. power.maps
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
				showLeaderboard(player, tonumber(args) or 0)
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
				if args ~= "help" and args ~= "staff" and args ~= "rules" and args ~= "contribute" then return end
				showHelpMenu(player, args)
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
				end

				addToggle(tonumber(t_id), player, state)
			end
		end)

		onEvent("GameDataLoaded", function(data)
			if data.banned then
				bans = {}
				for player in next, data.banned do
					bans[tonumber(player)] = true
				end

				if ban_actions._count > 0 then
					local send_saved = {}
					local to_respawn = {}
					local action
					for index = 1, ban_actions._count do
						action = ban_actions[index]

						if not send_saved[action[3]] then
							send_saved[action[3]] = true
							translatedChatMessage("data_saved", action[3])
						end

						if action[1] == "ban" then
							bans[action[2]] = true
							data.banned[tostring(action[2])] = 1 -- 1 so it uses less space
							to_respawn[action[2]] = nil
						else
							bans[action[2]] = nil
							data.banned[tostring(action[2])] = nil
							to_respawn[action[2]] = true
						end

						webhooks._count = webhooks._count + 1
						webhooks[webhooks._count] = "**`[BANS]:`** **" .. action[3] .. "** has " .. action[1] .. "ned a player. (ID: **" .. action[2] .. "**)"
					end
					ban_actions = {_count = 0}

					for id in next, to_respawn do
						for player, data in next, room.playerList do
							if data.id == id then
								tfm.exec.respawnPlayer(player)
							end
						end
					end
				end
			end

			if data.update then
				if save_update then
					data.update = save_update
					save_update = nil
				end

				update_at = data.update or 0
			end
		end)

		onEvent("PlayerRespawn", setNameColor)

		onEvent("NewGame", function()
			for player in next, in_room do
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
			translatedChatMessage("discord", player, links.discord)
			translatedChatMessage("map_submissions", player, links.maps)
			translatedChatMessage("type_help", player)

			system.bindKeyboard(player, 76, true, true)
			system.bindKeyboard(player, 79, true, true)
			system.bindKeyboard(player, 72, true, true)
			system.bindKeyboard(player, 80, true, true)

			tfm.exec.addImage("1713705576b.png", ":1", 772, 32, player)
			ui.addTextArea(-1, "<a href='event:settings'><font size='50'>  </font></a>", player, 767, 32, 30, 32, 0, 0, 0, true)

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
		end)

		onEvent("PlayerWon", function(player)
			if bans[ room.playerList[player].id ] then return end

			-- If the player joined the room after the map started,
			-- eventPlayerWon's time is wrong. Also, eventPlayerWon's time sometimes bug.
			local taken = (os.time() - (generated_at[player] or map_start)) / 1000

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
						translatedChatMessage("unlocked_power", nil, player, power.name)
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

			elseif cmd == "ban" then
				if not perms[player] or not perms[player].ban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local affected = capitalize(args[1])
				if not in_room[affected] then
					return translatedChatMessage("user_not_in_room", player, affected)
				end

				local id = room.playerList[affected].id
				ban_actions._count = ban_actions._count + 1
				ban_actions[ban_actions._count] = {"ban", id, player}
				bans[id] = true
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "unban" then
				if not perms[player] or not perms[player].unban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local id = tonumber(args[1])
				if (not id) or (not bans[id]) then
					return translatedChatMessage("arg_must_be_id", player)
				end

				ban_actions._count = ban_actions._count + 1
				ban_actions[ban_actions._count] = {"unban", id, player}
				bans[id] = nil
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "kill" then
				if not perms[player] or not perms[player].ban then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end

				local affected = capitalize(args[1])
				if not in_room[affected] then
					return translatedChatMessage("user_not_in_room", player, affected)
				end
				if no_powers[affected] then
					return translatedChatMessage("already_killed", player, affected)
				end

				local minutes = "-"
				if pointer > 1 then
					minutes = tonumber(args[2])

					if not minutes then
						return translatedChatMessage("invalid_syntax", player)
					end

					translatedChatMessage("kill_minutes", affected, minutes)
					players_file[affected].parkour.killed = os.time() + minutes * 60 * 1000
					savePlayerData(affected)
				else
					translatedChatMessage("kill_map", affected)
				end

				webhooks._count = webhooks._count + 1
				webhooks[webhooks._count] = "**`[BANS]:`** `" .. room.name .. "` `" .. player .. "`: `!kill " .. affected .. " " .. minutes .. "`"

				no_powers[affected] = true
				unbind(affected)

			elseif cmd == "rank" then
				if not perms[player] or not perms[player].set_player_rank then return end

				if pointer < 1 then
					return translatedChatMessage("invalid_syntax", player)
				end
				args[1] = string.lower(args[1])

				if args[1] == "add" or args[1] == "rem" then
					if pointer < 2 then
						return translatedChatMessage("invalid_syntax", player)
					end
					if updater and updater ~= player then
						return translatedChatMessage("cant_update", player)
					end

					local rank_name = string.lower(args[3])
					if not ranks[rank_name] then
						return translatedChatMessage("invalid_rank", player, rank_name)
					end

					if not ranks_update then
						ranks_update = {}
						updater = player
					end

					local affected = capitalize(args[2])
					if not ranks.admin[player] then
						if ranks.admin[affected] or ranks.manager[affected] then
							return translatedChatMessage("cant_edit", player)
						end
					end

					if args[1] == "add" and ranks[rank_name][affected] then
						return translatedChatMessage("has_rank", player, affected, rank_name)
					elseif args[1] == "rem" and not ranks[rank_name][affected] then
						return translatedChatMessage("doesnt_have_rank", player, affected, rank_name)
					end

					if not ranks_update[affected] then
						rank_id = 0
						for rank, id in next, ranks_id do
							if ranks[rank][affected] then
								rank_id = rank_id + id
							end
						end
						ranks_update[affected] = rank_id
					end

					if args[1] == "add" then
						ranks_update[affected] = ranks_update[affected] + ranks_id[rank_name]
					else
						ranks_update[affected] = ranks_update[affected] - ranks_id[rank_name]
					end

					translatedChatMessage("rank_save", player)

				elseif args[1] == "save" then
					saving_ranks = true
					translatedChatMessage("action_within_minute", player)

				elseif args[1] == "list" then
					local msg
					for rank, players in next, ranks do
						msg = "Users with the rank " .. rank .. ":"
						for player in next, players do
							msg = msg .. "\n - " .. player
						end
						tfm.exec.chatMessage(msg, player)
					end

				else
					return translatedChatMessage("invalid_syntax", player)
				end

			elseif cmd == "staff" then
				local texts = {}
				local text, _first
				for player, ranks in next, player_ranks do
					if player ~= "Tocutoeltuco#5522" then
						text = "\n- <v>" .. player .. "</v> ("
						_first = true
						for rank in next, ranks do
							if _first then
								text = text .. rank
								_first = false
							else
								text = text .. ", " .. rank
							end
						end
						texts[player] = text .. ")"
					end
				end

				text = "<v>[#]<n> <d>Parkour staff:</d>"

				for i = 1, #ranks_order do
					for player in next, ranks[ranks_order[i]] do
						if texts[player] then
							text = text .. texts[player]
							texts[player] = nil
						end
					end
				end

				tfm.exec.chatMessage(text, player)

			elseif cmd == "update" then
				if not perms[player] or not perms[player].show_update then return end

				save_update = os.time() + 60000 * 3 -- 3 minutes
				translatedChatMessage("action_within_minute", player)

			elseif cmd == "map" then
				if not perms[player] or not perms[player].change_map then return end

				if pointer > 0 then
					tfm.exec.newGame(args[1])
				else
					newMap()
				end

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
			if key == 76 then
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
			tfm.exec.disableMinimalistMode(true)
			system.disableChatCommandDisplay("lb", true)
			system.disableChatCommandDisplay("ban", true)
			system.disableChatCommandDisplay("unban", true)
			system.disableChatCommandDisplay("kill", true)
			system.disableChatCommandDisplay("rank", true)
			system.disableChatCommandDisplay("update", true)
			system.disableChatCommandDisplay("map", true)
			system.disableChatCommandDisplay("spec", true)
			system.disableChatCommandDisplay("op", true)
			system.disableChatCommandDisplay("donate", true)
			system.disableChatCommandDisplay("help", true)
			system.disableChatCommandDisplay("staff", true)
			system.disableChatCommandDisplay("room", true)
		end)
		--[[ End of file modes/parkour/interface.lua ]]--
		--[[ File modes/parkour/webhooks.lua ]]--
		webhooks = {_count = 0}

		onEvent("GameDataLoaded", function(data)
			local now = os.time()
			if not data.webhooks or os.time() >= data.webhooks[1] then
				data.webhooks = {math.floor(os.time()) + 300000} -- 5 minutes
			end

			local last = #data.webhooks
			for index = 1, webhooks._count do
				data.webhooks[last + index] = webhooks[index]
			end
			webhooks._count = 0
		end)
		--[[ End of file modes/parkour/webhooks.lua ]]--
		--[[ File modes/parkour/init.lua ]]--
		if submode ~= "maps" then
			eventGameStart()
		end
		--[[ End of file modes/parkour/init.lua ]]--
		--[[ End of package modes/parkour ]]--
	end
end

for player in next, tfm.get.room.playerList do
	eventNewPlayer(player)
end