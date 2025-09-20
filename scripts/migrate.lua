-- File Migration Script 

{% require-package "tech/filemanager" %}
{% require-file "modes/parkour/sanctionfilemanager.lua" %}
{% require-file "modes/parkour/filemanagers.lua" %}

local function saveFile(id, data)
  system.saveFile(filemanagers[tostring(id)]:dump(data), id)
end

{% require-file "scripts/file_shop.lua" %}
