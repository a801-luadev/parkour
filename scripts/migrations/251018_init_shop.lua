-- File migration, built with: python builder.py --migrate 251018_init_shop
{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

function init_shop()
  {% require-file "scripts/file_shop.lua" %}
end

init_shop()
