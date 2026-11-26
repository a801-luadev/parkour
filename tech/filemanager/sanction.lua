-- Reads and writes the sanction file's rows. data.sanction holds four
-- strings, each id in at most one of them, rows joined by \1:
--   legacy: ids of permas from before sanctions had a date (ts 0, unknown
--           moderator, level 4)
--   perma:  id \2 ts \2 mod (level 4)
--   temp:   id \2 ts \2 duration \2 mod \2 level, bans that haven't ended
--   data:   the same fields: unbans (duration 0), ended bans, levels
-- ts is in seconds, duration in minutes (end = ts + duration), mod is an
-- index into data.sanction.mods (0 = unknown). Every value crossing this API is in ms, with time as rooms
-- use it: 0 unban, 2 perma, else the end ts.
-- A global since modules are close to the 200 locals limit.
do
  local find, sub, gmatch, match = string.find, string.sub, string.gmatch, string.match
  local tonumber, floor, next = tonumber, math.floor, next

  local legacy_pattern = "[^\1]+"
  local perma_pattern = "(%d+)\2(%d+)\2%d+"
  local row_pattern = "(%d+)\2(%d+)\2(%d+)\2%d+\2%d+"

  -- the row of id in str (legacy: only ids) -> its text, start and end in
  -- str, or nil
  local function locate(str, id, legacy)
    local wrapped = "\1" .. str .. "\1"
    local start = find(wrapped, "\1" .. id .. (legacy and "\1" or "\2"), 1, true)
    if not start then return end
    local stop = find(wrapped, "\1", start + 1, true)
    -- positions in str: wrapped has one more character in front
    return sub(wrapped, start + 1, stop - 1), start, stop - 2
  end

  -- str without the row at [start, stop] and the \1 that joins it
  local function cut(str, start, stop)
    if start > 1 then
      return sub(str, 1, start - 2) .. sub(str, stop + 1)
    end
    return sub(str, stop + 2)
  end

  local function append(str, row)
    if str == "" then return row end
    return str .. "\1" .. row
  end

  -- the row of an id in its string -> ts, time, mod, level (ms)
  local function readRow(row)
    local _, ts, duration, mod, level = match(row, "^(%d+)\2(%d+)\2(%d+)\2(%d+)\2(%d+)$")
    ts, duration = tonumber(ts), tonumber(duration)
    return ts * 1000, duration == 0 and 0 or ts * 1000 + duration * 60000, tonumber(mod), tonumber(level)
  end

  -- fills bans (id -> ts ms) and ends (id -> end ms, temp bans only) with
  -- the active bans, removing ids that aren't active any more
  local function decodeActive(sanction, bans, ends)
    local now = os.time()
    local active, active_ends = {}, {}

    for id in gmatch(sanction.legacy, legacy_pattern) do
      active[tonumber(id)] = 0
    end
    for id, ts in gmatch(sanction.perma, perma_pattern) do
      active[tonumber(id)] = tonumber(ts) * 1000
    end
    local stop
    for id, ts, duration in gmatch(sanction.temp, row_pattern) do
      ts = tonumber(ts)
      stop = ts * 1000 + tonumber(duration) * 60000
      if stop > now then
        id = tonumber(id)
        active[id] = ts * 1000
        active_ends[id] = stop
      end
    end

    -- no new keys while traversing with next: collect first
    local gone, count = {}, 0
    for id in next, bans do
      if not active[id] then
        count = count + 1
        gone[count] = id
      end
    end
    for index = 1, count do
      bans[gone[index]] = nil
    end
    for id in next, ends do
      if not active_ends[id] then
        ends[id] = nil
      end
    end

    for id, ts in next, active do
      bans[id] = ts
    end
    for id, stop in next, active_ends do
      ends[id] = stop
    end
  end

  -- -> ts, time, mod, level (ms) of id's row, or nil
  local function findRow(sanction, id)
    local row = locate(sanction.temp, id)
    if row then return readRow(row) end

    row = locate(sanction.perma, id)
    if row then
      local _, ts, mod = match(row, "^(%d+)\2(%d+)\2(%d+)$")
      return tonumber(ts) * 1000, 2, tonumber(mod), 4
    end

    if locate(sanction.legacy, id, true) then
      return 0, 2, 0, 4
    end

    row = locate(sanction.data, id)
    if row then return readRow(row) end
  end

  -- removes id's row from the four strings
  local function remove(sanction, id)
    local _, start, stop = locate(sanction.temp, id)
    if start then sanction.temp = cut(sanction.temp, start, stop) return end

    _, start, stop = locate(sanction.perma, id)
    if start then sanction.perma = cut(sanction.perma, start, stop) return end

    _, start, stop = locate(sanction.legacy, id, true)
    if start then sanction.legacy = cut(sanction.legacy, start, stop) return end

    _, start, stop = locate(sanction.data, id)
    if start then sanction.data = cut(sanction.data, start, stop) end
  end

  -- writes id's row (ts, time ms; mod an index, 0 = unknown); the string
  -- comes from time: perma (always level 4), temp if it hasn't ended, else data.
  -- The duration is end - ts to the nearest minute (bans are whole minutes),
  -- at least 1 for an end after ts
  local function write(sanction, id, ts, time, mod, level)
    remove(sanction, id)

    local seconds = floor(ts / 1000)
    if time == 2 then
      sanction.perma = append(sanction.perma, id .. "\2" .. seconds .. "\2" .. mod)
      return
    end

    local duration = 0
    if time > 2 and time > ts then
      duration = floor((time - ts) / 60000 + 0.5)
      if duration < 1 then duration = 1 end
    end

    local row = id .. "\2" .. seconds .. "\2" .. duration .. "\2" .. mod .. "\2" .. level
    if duration > 0 and seconds * 1000 + duration * 60000 > os.time() then
      sanction.temp = append(sanction.temp, row)
    else
      sanction.data = append(sanction.data, row)
    end
  end

  -- sets the level of id's row; false for a perma (always level 4) or no row
  local function setLevel(sanction, id, level)
    local ts, time, mod = findRow(sanction, id)
    if not ts or time == 2 then return false end
    write(sanction, id, ts, time, mod, level)
    return true
  end

  -- moves ended temp bans to data; true if any moved
  local function prune(sanction, now)
    local keep, ended, kept, count = {}, {}, 0, 0
    for row in gmatch(sanction.temp, "[^\1]+") do
      local _, ts, duration = match(row, "^(%d+)\2(%d+)\2(%d+)\2")
      if tonumber(ts) * 1000 + tonumber(duration) * 60000 > now then
        kept = kept + 1
        keep[kept] = row
      else
        count = count + 1
        ended[count] = row
      end
    end
    if count == 0 then return false end

    sanction.temp = table.concat(keep, "\1")
    for index = 1, count do
      sanction.data = append(sanction.data, ended[index])
    end
    return true
  end

  -- ms -> the whole second the file keeps, in ms
  local function fileTs(ts)
    return floor(ts / 1000) * 1000
  end

  -- index of a moderator in sanction.mods, added if missing; 0 = unknown
  local function modIndex(sanction, name)
    if not name or name == "-" then return 0 end
    local mods = sanction.mods
    for index = 1, #mods do
      if mods[index] == name then return index end
    end
    mods[#mods + 1] = name
    return #mods
  end

  -- the moderator of an index: "-" if unknown, the index if not in mods
  local function modName(sanction, index)
    if index == 0 then return "-" end
    return sanction.mods[index] or index
  end

  SanctionRW = {
    decodeActive = decodeActive,
    find = findRow,
    write = write,
    setLevel = setLevel,
    prune = prune,
    fileTs = fileTs,
    modIndex = modIndex,
    modName = modName,
  }
end
