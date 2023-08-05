local fs = require('@lune/fs')

local PathUtils = require('./path-utils')

local function createAllDirectories(path: string)
    if fs.isDir(path) then
        return
    end

    fs.writeDir(path)
end

local function clearDirectory(path: string)
    if not fs.metadata(path).exists then
        return
    end
    if fs.isFile(path) then
        error('clearDirectory cannot be called on files')
    end
    local clearStack = {}
    local current: string? = path
    while current do
        if fs.isDir(current) then
            local entries = fs.readDir(current)
            if #entries == 0 then
                fs.removeDir(current)
            else
                table.insert(clearStack, current)
                for _, entry in entries do
                    table.insert(clearStack, PathUtils.join(current, entry))
                end
            end
        elseif fs.isFile(current) then
            fs.removeFile(current)
        end

        current = table.remove(clearStack)
    end
end

local function copy(from: string, destination: string)
    local fromName = PathUtils.fileName(from)
    if fs.isFile(from) then
        fs.copy(from, PathUtils.join(destination, fromName))
    elseif fs.isDir(from) then
        local copiedDir = PathUtils.join(destination, fromName)
        createAllDirectories(copiedDir)
        for _, entry in fs.readDir(from) do
            copy(PathUtils.join(from, entry), copiedDir)
        end
    else
        error('unexpected entry at ' .. from)
    end
end

return {
    copy = copy,
    clearDirectory = clearDirectory,
    createAllDirectories = createAllDirectories,
}
