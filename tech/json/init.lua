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