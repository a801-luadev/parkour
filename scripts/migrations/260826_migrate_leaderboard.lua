-- File migration, built with: python builder.py --migrate 260826_migrate_leaderboard
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

function migrate_leaderboard_260826()
  local prevId = 41
  local newId = 77
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
			},
			{
				name = "coinranking",
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
			}
		}
	}):disableValidityChecks():prepare()

  local concat = table.concat

  local function convertLb(lb)
    for i=1, #lb do
      lb[i] = concat(lb[i], '\2')
    end
    return concat(lb, '\1')
  end

  function eventFileLoaded(fileNumber, fileData)
    if prevId == tonumber(fileNumber) then
      local data = oldManager:load(fileData)
      data.ranking = convertLb(data.ranking)
      data.coinranking = convertLb(data.coinranking)
      data.weekly.ranks = convertLb(data.weekly.ranks)
      data.diff1ranking = ""
      data.diff2ranking = ""
      data.diff3ranking = ""
      saveFile(newId, data)
    end
  end

  system.loadFile(prevId)
end

migrate_leaderboard_260826()
