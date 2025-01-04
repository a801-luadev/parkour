local allocateId

do
  local lastId = {}

  allocateId = function(context, start_id, end_id)
    if not lastId[context] or lastId[context] == end_id then
      lastId[context] = start_id or 1
    else
      lastId[context] = lastId[context] + 1
    end
    return lastId[context]
  end
end
