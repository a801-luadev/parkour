-- File migration, built with: python builder.py --migrate 251018_init_npc
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

function init_npc()
  {% require-file "scripts/file_npc.lua" %}
end

init_npc()
