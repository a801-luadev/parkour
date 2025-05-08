local newSessionTable

do
  local registered = { _len = 0 }

  newSessionTable = function()
    local tbl = {}
    registered._len = registered._len + 1
    registered[registered._len] = tbl
    return tbl
  end

  onEvent("PlayerLeft", function(player)
    for i=1, registered._len do
      registered[i][player] = nil
    end
  end)
end
