local newSessionTable

do
  local registered = { _len = 0 }
  local index_tables = {}

  newSessionTable = function(index_tbl)
    local tbl = {}
    registered._len = registered._len + 1
    registered[registered._len] = tbl
    index_tables[tbl] = index_tbl
    return tbl
  end

  onEvent("PlayerLeft", function(player)
    local tbl, index_tbl
    for i=1, registered._len do
      tbl = registered[i]
      index_tbl = index_tables[tbl]
      tbl[index_tbl and index_tbl[player] or player] = nil
    end
  end)
end
