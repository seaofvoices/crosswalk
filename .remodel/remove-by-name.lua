local function join(a, b)
    return ('%s/%s'):format(a, b)
end

local function clearScripts(object, nameMatch)
    for _, child in ipairs(object:GetChildren()) do
        if child.Name:match(nameMatch) then
            child:Destroy()
        else
            clearScripts(child, nameMatch)
        end
    end
end

local function isModelFile(path)
    return (path:match('%.rbxmx$') or path:match('%.rbxm$')) and true or false
end

local function isPlaceFile(path)
    return (path:match('%.rbxlx$') or path:match('%.rbxl$')) and true or false
end

local function processFile(path, nameMatch)
    if isModelFile(path) then
        print('Remove tests in model: ' .. path)
        local models = remodel.readModelFile(path)

        if #models > 1 then
            error(
                ('remodel cannot write back models with multiple root instances (in file %q)'):format(
                    path
                )
            )
        end

        clearScripts(models[1], nameMatch)

        remodel.writeModelFile(models[1], path)
    elseif isPlaceFile(path) then
        print('Remove tests in place: ' .. path)
        local place = remodel.readPlaceFile(path)

        clearScripts(place, nameMatch)

        remodel.writePlaceFile(place, path)
    end
end

local processPath

local function processDirectory(directoryPath, nameMatch)
    for _, file in ipairs(remodel.readDir(directoryPath)) do
        local path = join(directoryPath, file)
        processPath(path, nameMatch)
    end
end

function processPath(path, nameMatch)
    local success, isFile = pcall(function()
        return remodel.isFile(path)
    end)

    if success and isFile then
        if isModelFile(path) or isPlaceFile(path) then
            processFile(path, nameMatch)
        end
    elseif success and not isFile then
        processDirectory(path, nameMatch)
    else
        error(('could not find directory or file `%s`'):format(path))
    end
end

local nameMatch = ...

for i = 2, select('#', ...) do
    local path = select(i, ...)

    processPath(path, nameMatch)
end
