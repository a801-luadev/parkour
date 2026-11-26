-- File migration, built with: python builder.py --migrate 251204_fix_shop
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

function fix_shop_2512()
  local file_id = 54
  local item_id = 2007
  local concat = table.concat

  function eventLoop()end
  
  function eventFileLoaded(fileNumber, fileData)
    if file_id == tonumber(fileNumber) then
      local data = filemanagers[tostring(file_id)]:load(fileData)
      local skins = data.shop.skins
      local parts, count, max_id = {}, 0, 0
      for part in skins:gmatch('[^\1]+') do
        local id = tonumber(part:match("^([^\2]+)"))
        if id ~= item_id then
          count = count + 1
          parts[count] = part
          if id > max_id then
            max_id = id
          end
        else
          tfm.exec.chatMessage("Removed shop item " .. tostring(item_id) .. " from shop file.")
        end
      end
      tfm.exec.chatMessage("Prev last_id is " .. tostring(data.shop.last_id) .. ".")
      data.shop.skins = table.concat(parts, '\1')
      data.shop.last_id = max_id
      tfm.exec.chatMessage("New last_id is " .. tostring(max_id) .. ".")
      saveFile(file_id, data)
    end
  end

  system.loadFile(file_id)
end

fix_shop_2512()
