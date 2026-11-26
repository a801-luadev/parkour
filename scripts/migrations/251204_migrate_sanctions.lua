-- File migration, built with: python builder.py --migrate 251204_migrate_sanctions
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
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

migrate_sanctions_2512()
