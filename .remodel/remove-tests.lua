local function join(a, b)
    return ('%s/%s'):format(a, b)
end

local buildFolder = './build'

local function clearScripts(object)
    for _, child in ipairs(object:GetChildren()) do
        if child.ClassName == 'ModuleScript' and child.Name:match('.spec$') then
            print('delete', child)
            child:Destroy()
        else
            clearScripts(child)
        end
    end
end

remodel.createDirAll(buildFolder)

for _, file in ipairs(remodel.readDir(buildFolder)) do
    local model = remodel.readModelFile(join(buildFolder, file))[1]

    print('Process model', file, model.Name)

    clearScripts(model)

    remodel.writeModelFile(model, join(buildFolder, file))
end
