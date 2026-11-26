-- File migration, built with: python builder.py --migrate 261125_migrate_sanctions
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

-- file 63's sanction (ts, mods, data) -> file 84's, and counts of what went
-- where. now in ms. History older than 2 years is archived (left out; the bot
-- keeps every row), and so are the odd rows: time 1 (pending bans from 2023)
-- and time -2 (unknown).
local function sanctions63to84(old, now)
  local floor, concat = math.floor, table.concat
  local cutoff = now - 730 * 24 * 60 * 60 * 1000

  -- end - ts in minutes, as SanctionRW.write stores it
  local function minutes(ts, time)
    if time <= ts then return 0 end
    return math.max(1, floor((time - ts) / 60000 + 0.5))
  end

  -- the "-" entry is dropped: unknown is index 0, the rest move down
  local mods, mod_map, dash = {}, {[0] = 0}, 0
  for index = 1, #old.mods do
    if old.mods[index] == "-" then
      dash = dash + 1
      mod_map[index] = 0
    else
      mods[#mods + 1] = old.mods[index]
      mod_map[index] = #mods
    end
  end

  local legacy, perma, temp, data = {}, {}, {}, {}
  local counts = {rows = 0, legacy = 0, perma = 0, temp = 0, data = 0, archived = 0,
    archived_odd = 0, archived_ts0 = 0, dashes = dash, duplicates = 0}
  local seen = {}

  for row in string.gmatch(old.data, "[^\1]+") do
    local id, ts, time, mod, level = string.match(row, "^([^\2]*)\2([^\2]*)\2([^\2]*)\2([^\2]*)\2([^\2]*)$")
    id, ts, time, level = tonumber(id), tonumber(ts), tonumber(time), tonumber(level) or 0
    mod = mod_map[tonumber(mod) or 0] or 0
    counts.rows = counts.rows + 1

    if not id or not ts or not time then
      error("bad row: " .. string.gsub(row, "\2", ","))
    end
    if seen[id] then counts.duplicates = counts.duplicates + 1 end
    seen[id] = true

    local seconds = floor(ts / 1000)
    if time == 1 or time == -2 then
      counts.archived = counts.archived + 1
      counts.archived_odd = counts.archived_odd + 1
    elseif ts == 0 and (time == 2 or time > now) then
      legacy[#legacy + 1] = id
    elseif time == 2 then
      perma[#perma + 1] = id .. "\2" .. seconds .. "\2" .. mod
    elseif time > now then
      temp[#temp + 1] = concat({id, seconds, minutes(ts, time), mod, level}, "\2")
    elseif ts >= cutoff then
      local duration = time > 2 and minutes(ts, time) or 0
      data[#data + 1] = concat({id, seconds, duration, mod, level}, "\2")
    else
      counts.archived = counts.archived + 1
      if ts == 0 then counts.archived_ts0 = counts.archived_ts0 + 1 end
    end
  end

  counts.legacy, counts.perma, counts.temp, counts.data = #legacy, #perma, #temp, #data
  -- every row between \1s, empty: "\1"
  local function wrap(rows)
    return "\1" .. concat(rows, "\1") .. (#rows > 0 and "\1" or "")
  end
  return {
    ts = now,
    mods = mods,
    legacy = wrap(legacy),
    perma = wrap(perma),
    temp = wrap(temp),
    data = wrap(data),
    archived = floor(cutoff / 1000),
  }, counts
end

-- copies file 63 rows newer than file 84's into it.
-- -> rows written, level differences (only listed)
local function sanctions63catchup(old, new)
  local since = (new.archived + 730 * 24 * 60 * 60) * 1000 -- the migration
  local written, levels = {}, {}

  for row in string.gmatch(old.data, "[^\1]+") do
    local id, ts, time, mod, level = string.match(row, "^([^\2]*)\2([^\2]*)\2([^\2]*)\2([^\2]*)\2([^\2]*)$")
    id, ts, time, level = tonumber(id), tonumber(ts), tonumber(time), tonumber(level) or 0
    if not id or not ts or not time then
      error("bad row: " .. string.gsub(row, "\2", ","))
    end

    -- time 1 and -2 are the odd rows the migration archived
    if time ~= 1 and time ~= -2 then
      local name = old.mods[tonumber(mod) or 0]
      local seconds = SanctionRW.fileTs(ts)
      local fts, ftime, _, flevel = SanctionRW.find(new, id)

      if fts == seconds then
        if time ~= 2 and ftime ~= 2 and level ~= flevel then
          levels[#levels + 1] = {id, level, flevel}
        end
      elseif (fts and seconds > fts) or (not fts and seconds >= since) then
        SanctionRW.write(new, id, ts, time, SanctionRW.modIndex(new, name), level)
        written[#written + 1] = {id, ts, time, name or "-", level}
      end
    end
  end

  return written, levels
end

-- file 63 -> 84. !load reads 63 and prints what the migration would write.
-- !save writes 84, only if 84 isn't migrated yet. Once it is, !catchup
-- lists the sanctions rooms on the old module wrote to 63 since (they run
-- until they close), and !catchup save writes them: it reads 84 and writes
-- it in the same event, as rooms on the new module write 84 too. Each
-- command loads a file: wait a few seconds between them. File 63 is left as
-- it is (the backup).
function migrate_sanctions_261125()
  local prevId = 63
  local newId = 84
  local oldManager = FileManager.new({
    type = "dictionary",
    map = {
      {
        name = "sanction",
        type = "dictionary",
        map = {
          { name = "ts", type = "number" },
          { name = "mods", type = "array", objects = { type = "string" } },
          { name = "data", type = "string" },
        }
      }
    }
  }):disableValidityChecks():prepare()
  local old, converted, action

  tfm.exec.setRoomMaxPlayers(1)

  function eventLoop()end

  local function loaded63(fileData)
    old = oldManager:load(fileData).sanction
    local counts
    converted, counts = sanctions63to84(old, os.time())

    local parts = {}
    for name, count in next, counts do
      parts[#parts + 1] = name .. "=" .. count
    end
    table.sort(parts)
    tfm.exec.chatMessage("File 63: " .. #fileData .. " B, ts " .. tostring(old.ts) .. ", " .. #old.mods .. " mods")
    tfm.exec.chatMessage("Rows: " .. table.concat(parts, " "))
    tfm.exec.chatMessage(string.format("Bytes: legacy %d, perma %d, temp %d, data %d; %d mods; archived %d",
      #converted.legacy, #converted.perma, #converted.temp, #converted.data, #converted.mods, converted.archived))
    tfm.exec.chatMessage("Type !save to migrate, or !catchup if file 84 is migrated already.")
  end

  local function loaded84(fileData)
    -- a file 84 that decodes with an archived ts is migrated: never overwrite it
    local ok, data = pcall(filemanagers[tostring(newId)].load, filemanagers[tostring(newId)], fileData)
    local migrated = ok and data.sanction and (data.sanction.archived or 0) > 0

    if action == "save" then
      if migrated then
        tfm.exec.chatMessage("<r>File 84 is migrated already, use !catchup.")
        return
      end
      saveFile(newId, {sanction = converted})
      tfm.exec.chatMessage("Saved file " .. newId .. ".")
      return
    end

    if not migrated then
      tfm.exec.chatMessage("<r>File 84 isn't migrated, use !save.")
      return
    end
    local written, levels = sanctions63catchup(old, data.sanction)
    for index = 1, #written do
      tfm.exec.chatMessage("<v>" .. table.concat(written[index], " "))
    end
    for index = 1, #levels do
      local diff = levels[index]
      tfm.exec.chatMessage(string.format("<j>%d: level %d in 63, %d in 84 (not changed)", diff[1], diff[2], diff[3]))
    end
    tfm.exec.chatMessage(#written .. " rows to write, " .. #levels .. " level differences.")

    if action == "catchup save" and #written > 0 then
      data.sanction.ts = os.time()
      saveFile(newId, data)
      tfm.exec.chatMessage("Saved file " .. newId .. ".")
    elseif #written > 0 then
      tfm.exec.chatMessage("Type !catchup save to write them.")
    end
  end

  function eventFileLoaded(fileNumber, fileData)
    fileNumber = tonumber(fileNumber)
    if fileNumber == prevId then
      loaded63(fileData)
    elseif fileNumber == newId and action then
      loaded84(fileData)
      action = nil
    end
  end

  function eventChatCommand(playerName, command)
    if command == "load" then
      system.loadFile(prevId)
    elseif command == "save" or command == "catchup" or command == "catchup save" then
      if not old then
        tfm.exec.chatMessage("Nothing loaded, type !load first.")
        return
      end
      action = command
      system.loadFile(newId)
    end
  end
end

migrate_sanctions_261125()
