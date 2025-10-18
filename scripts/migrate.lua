-- File Migration Script 

{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/sanctionfilemanager.lua" %}
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


--init_shop()
--init_npc()
--migrate_leaderboard()
