local SplitRW

do
  local pack, unpack = table.pack, table.unpack
  local gmatch, match = string.gmatch, string.match
  local rep, min = string.rep, math.min
  local concat = table.concat

  local function createInnerPattern(length)
    return "^" .. rep("([^\2]+)\2", length - 1) .. "([^\2]+)$"
  end

  local shop_pattern = createInnerPattern(11)
  local sanction_pattern = createInnerPattern(5)

  local function split(str)
    local arr, len = {}, 0
    for val in gmatch(str, '[^\1]+') do
      len = len + 1
      arr[len] = val
    end
    return arr, len
  end

  local function shouldParse(data, state)
    return not state.ts or state.ts < data.ts
  end

  local function parse(str, state, limit, kind)
    if state.parsed then
      return state.items
    end

    local all, count = state.all, state.count
    local index, indexMap, last = state.index, state.indexMap
    local items, item = state.items or {}

    if not state.count then
      all, count = split(str)
      index = 1
      indexMap = {}
      state.all = all
      state.count = count
      state.index = index
      state.indexMap = indexMap
    end

    state.items = items
    last = min(index + limit - 1, count)

    -- This part could be generalized but sadly this is much more efficient
    if kind == "shop" then
      local id, tab, img, price, scale, hidden, shop_img, shop_scale, x, y, so

      for i=index, last do
        id, tab, img, price, scale, hidden, shop_img, shop_scale, x, y, so = match(all[i], shop_pattern)
        id = tonumber(id)
        -- we use existing table here so references in shop_skins remain valid
        item = items[id] or { id = id }

        item.i = i
        item.tab = tonumber(tab)
        item.img = img ~= "." and img
        item.price = tonumber(price) or -1
        item.scale = scale ~= "." and tonumber(scale) or nil
        item.hidden = hidden ~= '0'
        item.shop_img = shop_img ~= "." and shop_img
        item.shop_scale = shop_scale ~= "." and tonumber(shop_scale) or nil
        item.x = x ~= "." and tonumber(x) or nil
        item.y = y ~= "." and tonumber(y) or nil
        item.so = so ~= "." and tonumber(so) or nil

        indexMap[i] = id
        items[item.id] = item
      end

    elseif kind == "sanction" then
      for i=index, last do
        item = pack(match(all[i], sanction_pattern))
        item.i = i
        item.id = tonumber(item[1])
        item.timestamp = tonumber(item[2])
        item.time = tonumber(item[3])
        item.info = tonumber(item[4]) or 0
        item.level = tonumber(item[5])

        indexMap[i] = item.id
        items[item.id] = item
      end

    else
      error("Invalid kind: " .. tostring(kind))
    end

    state.index = last + 1
    state.prev = index

    if last == count then
      state.parsed = true
    end

    return items
  end

  local function update(state, item, kind)
    if not state.parsed then
      return
    end

    local all = state.all
    local i = item.i

    state.updated = true

    if not i then
      i = state.count + 1
      state.count = i
      item.i = i
      state.items[item.id] = item
      state.indexMap[i] = item.id
    end

    if kind == "shop" then
      item[1] = item.id
      item[2] = item.tab
      item[3] = item.img or "."
      item[4] = item.price or -1
      item[5] = item.scale or 1
      item[6] = item.hidden and "1" or "0"
      item[7] = item.shop_img or "."
      item[8] = item.shop_scale or 1
      item[9] = item.x or "."
      item[10] = item.y or "."
      item[11] = item.so or "."

    elseif kind == "sanction" then
      item[1] = item.id
      item[2] = item.timestamp
      item[3] = item.time
      item[4] = item.info
      item[5] = item.level

    else
      error("Invalid kind: " .. tostring(kind))
    end

    all[i] = concat(item, "\2")

    return true
  end

  local function dump(state)
    if not state.updated then
      return
    end
    return concat(state.all, "\1")
  end

  SplitRW = {
    shouldParse = shouldParse,
    split = split,
    parse = parse,
    update = update,
    dump = dump,
  }
end
