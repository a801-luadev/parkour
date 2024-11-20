local function string_split(str, deli)
    local parts, len = {}, 0
    for part in str:gmatch('[^'..deli..']+') do
        len = len + 1
        parts[len] = part
    end
    return parts
end

local SanctionFileManager = {
    lastupdate = "",
    lastdata = nil,

    load = function(self, str)
        local data = string_split(str, "\1")

        if self.lastupdate == data[1] then
            return self.lastdata
        end

        local sanctionList = string_split(data[2], "\2")
        local sanctionDict = {}
        local sanction

        for i=1, #sanctionList do
            sanction = string_split(sanctionList[i], "\3")
            sanctionDict[sanction[1]] = {
                timestamp = tonumber(sanction[2]),
                time = tonumber(sanction[3]),
                info = tonumber(sanction[4]) or 0,
                level = tonumber(sanction[5]),
            }
        end

        self.lastupdate = data[1]
        self.lastdata = {
            sanction = sanctionDict,
        }

        return self.lastdata
    end,

    dump = function(self, data)
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

        return table.concat({ os.time(), table.concat(sanctionList, "\2") }, "\1")
    end,
}