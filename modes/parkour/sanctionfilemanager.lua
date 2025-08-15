local SanctionFileManager, bans
do
local function string_split(str, deli)
    local parts, len = {}, 0
    for part in str:gmatch('[^'..deli..']+') do
        len = len + 1
        parts[len] = part
    end
    return parts
end

local function findSanction(data, id)
    local first = data:find("\2"..id.."\3", 1, true)
    if not first then return end
    local last = data:find("\2", first + 1, true)
    return first + 1, last - 1
end

local function parseSanction(data)
    local sanction = string_split(data, "\3")
    return sanction[1], {
        timestamp = tonumber(sanction[2]),
        time = tonumber(sanction[3]),
        info = tonumber(sanction[4]) or 0,
        level = tonumber(sanction[5]),
    }
end

local function getSanction(file, id)
    id = tonumber(id)
    if not id then return end

    local retSanction

    if rawget(file, "_root") then
        retSanction = true
        file = file._root
    end
    if not file._keys[id] then return end

    local first, last = findSanction(file._sanction, id)

    -- Save if not banned
    if not first then
        rawset(file, id, false)
        rawset(file.sanction, tostring(id), false)
        return false
    end

    -- Extract the sanction data
    local sanctionData = file._sanction:sub(first, last)
    local parsedId, sanction = parseSanction(sanctionData)
    local time = sanction.time

    file.sanction[parsedId] = sanction

    -- Check if the sanction is still valid
    if time == 1 or time == 2 or os.time() < time then
        rawset(file, id, sanction.timestamp)
        return retSanction and sanction or sanction.timestamp
    end

    rawset(file, id, false)
    return retSanction and sanction or false
end

local function setSanction(file, id, sanction)
    id = tonumber(id)
    if not id then return end

    local strId = tostring(id)
    local moderator = sanction.info
    local time = sanction.time

    file._updated = true
    file.sanction[strId] = sanction
    file._keys[id] = true

    -- Add moderator to the mod list if not already present
    if moderator then
        if type(moderator) == "string" then
            local mod_index = table_find(file.mods, moderator)
            if not mod_index then
                mod_index = 1 + #file.mods
                file.mods[mod_index] = moderator
            end
            sanction.info = mod_index
        end
    else
        sanction.info = 0
    end

    -- Check if the sanction is still valid
    if time == 1 or time == 2 or os.time() < time then
        rawset(file, id, sanction.timestamp)
    else
        rawset(file, id, false)
    end

    local newSanction = table.concat({
        id,
        sanction.timestamp,
        sanction.time,
        sanction.info,
        sanction.level,
    }, "\3")

    -- Update sanction string
    local first, last = findSanction(file._sanction, id)
    if not first then
        file._sanction = file._sanction .. newSanction .. "\2"
        return
    end

    file._sanction = file._sanction:sub(1, first - 1) .. newSanction .. file._sanction:sub(last + 1)
end

local function parseSanctionKeys(data)
    local keys = {}
    for key in data:gmatch('\2(%d+)\3') do
        keys[tonumber(key)] = true
    end
    return keys
end

SanctionFileManager = {
    lastupdate = "",
    lastdata = nil,

    load = function(self, str, fullparse)
        local updateIndex = str:find("\1", 1, true)
        if not updateIndex then
          error("SplitFileManager: load: invalid data format, no update marker found")
        end

        local update = str:sub(1, updateIndex - 1)
        if self.lastupdate == update then
            return self.lastdata
        end

        local modListEnd = str:find("\1", updateIndex + 1, true)
        if not modListEnd then
          error("SplitFileManager: load: invalid data format, no modlist marker found")
        end

        local modList = string_split(str:sub(updateIndex + 1, modListEnd - 1), "\2")
        local sanctionData = str:sub(modListEnd + 1)

        if not fullparse then
            local root = {
                setSanction = setSanction,

                _sanction = "\2" .. sanctionData .. "\2",

                mods = modList,
            }
            root.sanction = setmetatable({ _root = root }, self)
            root._keys = parseSanctionKeys(root._sanction)

            self.lastupdate = update
            self.lastdata = setmetatable(root, self)
    
            return self.lastdata
        end

        local sanctionList = string_split(sanctionData, "\2")
        local sanctionDict = {}
        local key, sanction

        for i=1, #sanctionList do
            key, sanction = parseSanction(sanctionList[i])
            sanctionDict[key] = sanction
        end

        self.lastupdate = update
        self.lastdata = {
            mods = modList,
            sanction = sanctionDict,
        }

        return self.lastdata
    end,

    dump = function(self, data)
        if data._sanction then
            if not data._updated then return end
            return table.concat({ os.time(), table.concat(data.mods, "\2"), data._sanction:sub(2, -2) }, "\1")
        end

        local sanctionList, len = {}, 0

        for name, sanction in next, data.sanction do
            len = len + 1
            sanctionList[len] = table.concat({
                name,
                sanction.timestamp,
                sanction.time,
                sanction.info,
                sanction.level,
            }, "\3")
        end

        return table.concat({ os.time(), table.concat(data.mods, "\2"), table.concat(sanctionList, "\2") }, "\1")
    end,

    __index = getSanction,
}

bans = setmetatable({
    mods = {},
    _sanction = '',
    _keys = {},
}, SanctionFileManager)
bans.sanction = setmetatable({ _root = bans }, SanctionFileManager)
end
