-- Reads and writes leaderboard strings: rows of {id, name, score, community}
-- with fields joined by \2 and rows by \1, the same layout SplitRW uses.
-- A global since modules are close to the 200 locals limit.
do
  local gmatch, concat, tonumber = string.gmatch, table.concat, tonumber

  local row_pattern = "([^\1\2]+)\2([^\1\2]+)\2([^\1\2]+)\2([^\1\2]+)"

  -- returns the rows (at most maxRows) and their count
  -- malformed rows are skipped
  local function decode(str, maxRows)
    local rows, count = {}, 0

    for id, name, score, community in gmatch(str, row_pattern) do
      id, score = tonumber(id), tonumber(score)

      if id and score then
        count = count + 1
        rows[count] = { id, name, score, community }

        if count == maxRows then
          break
        end
      end
    end

    return rows, count
  end

  local function encode(rows, count)
    local out, row = {}
    for i = 1, count or #rows do
      row = rows[i]
      out[i] = row[1] .. "\2" .. row[2] .. "\2" .. row[3] .. "\2" .. row[4]
    end
    return concat(out, "\1")
  end

  LeaderboardRW = {
    decode = decode,
    encode = encode,
  }
end
