local fs = require('@lune/fs')
local process = require('@lune/process')
local roblox = require('@lune/roblox')
local PathUtils = require('./path-utils')

local filePath = process.args[1]

local place = roblox.deserializePlace(fs.readFile(filePath))

local assetParent = PathUtils.parent(filePath)

local function extractAsset(serviceName: string, instanceName: string, assetName: string)
    local modelContent =
        roblox.serializeModel({ place:GetService(serviceName):FindFirstChild(instanceName) :: any })
    fs.writeFile(PathUtils.join(assetParent, assetName), modelContent)
end

print('extract crosswalk assets from', filePath)
extractAsset('ReplicatedStorage', 'Common', 'common.rbxm')
extractAsset('ReplicatedStorage', 'ClientLoader', 'client-loader.rbxm')
extractAsset('ServerStorage', 'ServerLoader', 'server-loader.rbxm')

extractAsset('ReplicatedFirst', 'ClientMain', 'client-main.rbxm')
extractAsset('ServerScriptService', 'Main', 'server-main.rbxm')
