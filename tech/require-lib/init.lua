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