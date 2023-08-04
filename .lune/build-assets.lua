local fs = require('@lune/fs')
local process = require('@lune/process')
local roblox = require('@lune/roblox')

local Async = require('./async')
local FsHelpers = require('./fs-helpers')
local PathUtils = require('./path-utils')

print('build crosswalk assets')

local buildFolder = 'build'

local function runDarklua(...: string): process.SpawnResult
    local darkluaArgs = table.pack(...)
    local args = {
        'run',
        '--manifest-path',
        '../darklua-github/Cargo.toml',
        '--',
    }
    table.move(darkluaArgs, 1, darkluaArgs.n, #args, args)
    return process.spawn('cargo', args)
end

local function rojoBuild(configPath: string, output: string)
    local result = process.spawn('rojo', {
        'build',
        configPath,
        '--output',
        output,
    })

    if not result.ok then
        error('failed rojo build: ' .. result.stderr)
    end
end

type DarkluaConfigOptions = { config: string, container: string }
type BuildAssetOptions = {
    name: string,
    srcs: { string }?,
    darkluaConfigs: { DarkluaConfigOptions }?,
    rojoSourcemapConfig: string?,
    copyContent: { string }?,
    keepTemporaryFiles: boolean?
}
local function buildAsset(options: BuildAssetOptions)
    local logPrefix = '[' .. options.name .. ']'
    local function log(...)
        print(logPrefix, ...)
    end
    log('starting build for', options.name)
    local tmpFolder = PathUtils.join(buildFolder, 'tmp-' .. options.name)
    FsHelpers.clearDirectory(tmpFolder)

    local rojoDirectory = PathUtils.join(tmpFolder, 'rojo')

    FsHelpers.createAllDirectories(rojoDirectory)

    local rojoConfigName = options.name .. '.project.json'
    local rojoSourcemapConfigPath =
        PathUtils.join(rojoDirectory, options.rojoSourcemapConfig or rojoConfigName)
    local rojoConfigPath = PathUtils.join(rojoDirectory, rojoConfigName)

    FsHelpers.copy('rojo', tmpFolder)

    if options.copyContent then
        for _, contentPath in options.copyContent do
            FsHelpers.copy(contentPath, tmpFolder)
        end
    end

    local srcFolder = PathUtils.join(tmpFolder, 'src')
    local function setupSources()
        if options.srcs then
            for _, srcEntry in options.srcs do
                FsHelpers.copy(PathUtils.join('src', srcEntry), srcFolder)
            end
        else
            FsHelpers.copy('src', tmpFolder)
        end
    end
    setupSources()

    log('generate sourcemap for ', rojoSourcemapConfigPath)
    local result = process.spawn('rojo', { 'sourcemap', rojoSourcemapConfigPath })

    local sourcemapPath = PathUtils.join(rojoDirectory, 'sourcemap.json')

    if result.ok then
        fs.writeFile(sourcemapPath, result.stdout)
    else
        error('failed to generate rojo sourcemap: ' .. result.stderr)
    end

    local configs: { DarkluaConfigOptions } = options.darkluaConfigs
        or {
            { config = 'prod.json5', container = buildFolder },
            { config = 'debug.json5', container = PathUtils.join(buildFolder, 'debug') },
        }

    for i, info in configs do
        if i ~= 1 then
            FsHelpers.clearDirectory(srcFolder)
            setupSources()
        end

        FsHelpers.copy(PathUtils.join('scripts', 'darklua', info.config), tmpFolder)
        local darkluaConfigPath = PathUtils.join(tmpFolder, info.config)

        log('run darklua with config', info.config)
        local darkluaResult =
            runDarklua('process', '--config', darkluaConfigPath, srcFolder, srcFolder)

        log('darklua', darkluaResult.stdout)
        log('darklua stderr:', darkluaResult.stderr)
        if not darkluaResult.ok then
            error('failed to run darklua: ' .. darkluaResult.stderr)
        end

        FsHelpers.createAllDirectories(info.container)
        local assetLocation = PathUtils.join(info.container, options.name .. '.rbxm')
        log('build asset...', assetLocation)

        rojoBuild(rojoConfigPath, assetLocation)

        fs.removeFile(darkluaConfigPath)
    end

    log('create temporary directory', tmpFolder)
    if not options.keepTemporaryFiles then
        FsHelpers.clearDirectory(tmpFolder)
    end
end

local testPlaceTemplate: roblox.DataModel = nil
local testFolder = 'test-places'

local duration = Async.runAllTask({
    function()
        buildAsset({
            name = 'server-loader',
            srcs = { 'Common', 'ServerLoader' },
        })
    end,
    function()
        buildAsset({
            name = 'client-loader',
            srcs = { 'Common', 'ClientLoader' },
        })
    end,
    function()
        buildAsset({
            name = 'server-main',
            rojoSourcemapConfig = 'test-place.project.json',
            copyContent = { 'test-place', 'modules' },
        })
    end,
    function()
        buildAsset({
            name = 'client-main',
            rojoSourcemapConfig = 'test-place.project.json',
            copyContent = { 'test-place', 'modules' },
        })
    end,
    function()
        local tmpPlace = PathUtils.join(buildFolder, 'tmp-place.rbxl')
        print('create test place template', tmpPlace)
        rojoBuild('rojo/test-model.project.json', tmpPlace)

        testPlaceTemplate = roblox.deserializePlace(fs.readFile(tmpPlace))
        print('  read and stored DataModel for test place file')

        fs.removeFile(tmpPlace)
    end,
    function()
        FsHelpers.clearDirectory(testFolder)
        FsHelpers.createAllDirectories(testFolder)
    end,
})

local function buildTestPlace(modelPath: string, testPlacePath: string)
    print('build test place', testPlacePath)
    local place = testPlaceTemplate:Clone() :: roblox.DataModel

    local asset = roblox.deserializeModel(fs.readFile(modelPath))[1]

    local testModel = asset:Clone()
    testModel.Parent = place:GetService('ReplicatedStorage')
    testModel.Name = 'Model'

    print('  write test place', testPlacePath)
    fs.writeFile(testPlacePath, roblox.serializePlace(place))

    print('  clean test files in', modelPath)
    for _, descendant in asset:GetDescendants() do
        if descendant:IsA('ModuleScript') and string.match(descendant.Name, '%.spec') then
            descendant:Destroy()
        end
    end

    local testUtilsInstance = asset:FindFirstAncestor('TestUtils')
    if testUtilsInstance then
        testUtilsInstance:Destroy()
    end

    print('  rewrite model', modelPath)
    fs.writeFile(modelPath, roblox.serializeModel({ asset }))
end

do
    local startGenerateTestPlace = os.clock()
    buildTestPlace(
        PathUtils.join(buildFolder, 'server-loader.rbxm'),
        PathUtils.join(testFolder, 'server-loader.rbxl')
    )
    buildTestPlace(
        PathUtils.join(buildFolder, 'debug', 'server-loader.rbxm'),
        PathUtils.join(testFolder, 'server-loader-debug.rbxl')
    )
    buildTestPlace(
        PathUtils.join(buildFolder, 'client-loader.rbxm'),
        PathUtils.join(testFolder, 'client-loader.rbxl')
    )
    buildTestPlace(
        PathUtils.join(buildFolder, 'debug', 'client-loader.rbxm'),
        PathUtils.join(testFolder, 'client-loader-debug.rbxl')
    )
    duration += os.clock() - startGenerateTestPlace
end

print('\nRan all tasks in', string.format('%.1fs', duration))
