-- File migration, built with: python builder.py --migrate 260720_migrate_init
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

function migrate_init_260720()
  local prevId = 40
  local newId = 17
  local oldManager = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "ranks",
				type = "dictionary",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps2",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps3",
				type = "array",
				objects = {
					type = "number"
				}
			},
		}
	}):disableValidityChecks():prepare()

  function eventFileLoaded(fileNumber, fileData)
    if prevId == tonumber(fileNumber) then
      local data = oldManager:load(fileData)
      data.maps4 = {}
      data.maps5 = {}
      data.map_polls = {}
      saveFile(newId, data)
    end
  end

  system.loadFile(prevId)
end

migrate_init_260720()
