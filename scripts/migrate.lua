-- File Migration Script 

{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end


function init_shop()
  {% require-file "scripts/file_shop.lua" %}
end

function init_npc()
  {% require-file "scripts/file_npc.lua" %}
end

function migrate_leaderboard()
  local prevId = 21
  local newId = 41
  local oldManager = FileManager.new({
    type = "dictionary",
    map = {
      {
        name = "ranking",
        type = "array",
        objects = {
          type = "array",
          map = {
            {
              type = "number"
            },
            {
              type = "string",
            },
            {
              type = "number"
            },
            {
              type = "string",
              length = 2
            }
          }
        }
      },
      {
        name = "weekly",
        type = "dictionary",
        map = {
          {
            name = "ranks",
            type = "array",
            objects = {
              type = "array",
              map = {
                {
                  type = "number"
                },
                {
                  type = "string",
                },
                {
                  type = "number"
                },
                {
                  type = "string",
                  length = 2
                }
              }
            }
          },
          {
            name = "ts",
            type = "string"
          },
          {
            name = "wl",
            type = "dictionary",
            objects = {
              type= "number"
            }
          }
        }
      }
    }
  }):disableValidityChecks():prepare()

  function eventFileLoaded(fileNumber, fileData)
    if prevId == tonumber(fileNumber) then
      local data = oldManager:load(fileData)
      data.coinranking = {}
      saveFile(newId, data)
    end
  end

  system.loadFile(prevId)
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

function migrate_sanctions_2512()
  {% require-file "modes/parkour/sanctionfilemanager.lua" %}

  local prevId = 43
  local newId = 63
  local loaded_data = nil
  local concat = table.concat

  tfm.exec.setRoomMaxPlayers(1)

  function eventLoop()end
  
  function eventFileLoaded(fileNumber, fileData)
    if prevId == tonumber(fileNumber) then
      loaded_data = SanctionFileManager:load(fileData, true)
      tfm.exec.chatMessage("Loaded sanction data of " .. tostring(#loaded_data.sanction) .. " bytes.")
    end
  end

  function eventChatCommand(playerName, command)
    if command == "load" then
      system.loadFile(prevId)
    elseif command == "save" then
      if not loaded_data then
        tfm.exec.chatMessage("No data loaded.")
        return
      end

      local data, count = {}, 0

      for id, sanction in next, loaded_data.sanction do
        count = count + 1
        data[count] = concat({
          id,
          sanction.timestamp,
          sanction.time,
          sanction.info,
          sanction.level,
        }, "\2")
      end

      saveFile(newId, {
        sanction = {
          ts = os.time(),
          mods = loaded_data.mods,
          data = concat(data, '\1'),
        }
      })

      tfm.exec.chatMessage("Saved file: " .. tostring(#loaded_data.mods) .. " mods, " .. tostring(count) .. " sanctions")
    end
  end
end

--init_shop()
--init_npc()
--migrate_leaderboard()
--fix_shop_2512()
--migrate_sanctions_2512()
