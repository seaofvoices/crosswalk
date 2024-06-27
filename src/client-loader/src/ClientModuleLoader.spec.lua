local jestGlobals = require('@pkg/@jsdotlua/jest-globals')
local TestUtils = require('@pkg/crosswalk-test-utils')

local ClientModuleLoader = require('./ClientModuleLoader')

local ClientRemotes = require('./ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes
local createModuleLoaderTests = TestUtils.createModuleLoaderTests
local createClientRemotesMock = require('./tests-utils/createClientRemotesMock')

type ModuleScriptMock = TestUtils.ModuleScriptMock
type RequiredArgs = TestUtils.RequiredArgs

local expect = jestGlobals.expect
local it = jestGlobals.it
local beforeEach = jestGlobals.beforeEach
local describe = jestGlobals.describe
local Mocks = TestUtils.Mocks
local ReporterBuilder = TestUtils.ReporterBuilder
local RequireMock = TestUtils.RequireMock

local requireMock = RequireMock.new()

beforeEach(function()
    requireMock:reset()
end)

type NewModuleLoaderConfig = {
    requireModule: ((ModuleScript, ...any) -> any)?,
    shared: { ModuleScript }?,
    client: { ModuleScript }?,
    external: { [string]: any }?,
    player: Player?,
    clientRemotes: ClientRemotes?,
    reporter: TestUtils.Reporter?,
    useRecursiveMode: boolean?,
    services: any,
}
local function newModuleLoader(config: NewModuleLoaderConfig?)
    local config: NewModuleLoaderConfig = config or {}
    return ClientModuleLoader.new({
        shared = config.shared or {},
        client = config.client or {},
        external = config.external or {},
        player = config.player or Mocks.Player.new(),
        requireModule = config.requireModule or requireMock.requireModule,
        clientRemotes = config.clientRemotes or createClientRemotesMock(),
        reporter = config.reporter,
        useRecursiveMode = config.useRecursiveMode,
        services = config.services,
    })
end

local noPlayerFunctions = {
    OnPlayerReady = false,
    OnPlayerLeaving = false,
}

describe(
    'common',
    createModuleLoaderTests('client', function(config)
        return newModuleLoader({
            requireModule = config.requireModule,
            client = config.self,
            shared = config.shared,
            reporter = config.reporter,
            useRecursiveMode = config.useRecursiveMode,
            services = config.services,
        })
    end)
)

describe('loadModules', function()
    local moduleA: ModuleScriptMock
    local moduleB: ModuleScriptMock
    local moduleC: ModuleScriptMock

    beforeEach(function()
        moduleA = requireMock:createModule('A', noPlayerFunctions)
        moduleB = requireMock:createModule('B', noPlayerFunctions)
        moduleC = requireMock:createModule('C', noPlayerFunctions)
    end)

    it('throws if a shared module name is used twice', function()
        local moduleLoader = newModuleLoader({
            shared = { moduleA, moduleA },
        })
        expect(function()
            moduleLoader:loadModules()
        end).toThrow('shared module named "A" was already registered as a shared module')
    end)

    it('throws if a client module name is used also for a shared module', function()
        local moduleLoader = newModuleLoader({
            shared = { moduleA },
            client = { moduleA },
        })
        expect(function()
            moduleLoader:loadModules()
        end).toThrow('client module named "A" was already registered as a shared module')
    end)

    it('throws if a client module name is used twice', function()
        local moduleLoader = newModuleLoader({
            client = { moduleA, moduleA },
        })
        expect(function()
            moduleLoader:loadModules()
        end).toThrow('client module named "A" was already registered as a client module')
    end)

    it('throws if a shared module name is used also for an external client module', function()
        local moduleLoader = newModuleLoader({
            shared = { moduleA },
            external = { [moduleA.Name] = {} },
        })
        expect(function()
            moduleLoader:loadModules()
        end).toThrow(
            'shared module named "A" was already provided as an external client module. '
                .. 'Rename the shared module or the external module'
        )
    end)

    it('throws if a client module name is used also for an external client module', function()
        local moduleLoader = newModuleLoader({
            client = { moduleA },
            external = { [moduleA.Name] = {} },
        })
        expect(function()
            moduleLoader:loadModules()
        end).toThrow(
            'client module named "A" was already provided as an external client module. '
                .. 'Rename the client module or the external module'
        )
    end)

    if _G.DEV then
        describe('warn for wrong usage of shared modules', function()
            local reporterMock
            beforeEach(function()
                reporterMock = ReporterBuilder.new():onlyWarn():build()
            end)

            it('warns if a shared module has a `OnPlayerReady` function', function()
                moduleC = requireMock:createModule('C', { OnPlayerLeaving = false })
                local moduleLoader = newModuleLoader({
                    shared = { moduleC },
                    reporter = reporterMock,
                })
                moduleLoader:loadModules()

                expect(#reporterMock.events).toEqual(1)
                expect(reporterMock.events[1].message).toEqual(
                    'shared module "C" has a `OnPlayerReady` function defined that will not be called automatically. '
                        .. 'This function should be removed or the logic should be moved into a server module or a '
                        .. 'client module.'
                )
                expect(reporterMock.events[1].level).toEqual('warn')
            end)

            it('warns if a shared module has a `OnPlayerLeaving` function', function()
                moduleC = requireMock:createModule('C', { OnPlayerReady = false })
                local moduleLoader = newModuleLoader({
                    shared = { moduleC },
                    reporter = reporterMock,
                })
                moduleLoader:loadModules()

                expect(#reporterMock.events).toEqual(1)
                expect(reporterMock.events[1].message).toEqual(
                    'shared module "C" has a `OnPlayerLeaving` function defined that will not be called automatically. '
                        .. 'This function should be removed or the logic should be moved into a server module.'
                )
                expect(reporterMock.events[1].level).toEqual('warn')
            end)

            it('warns if a shared module has a `OnUnapprovedExecution` function', function()
                moduleC = requireMock:createModule('C', noPlayerFunctions)
                local moduleCImpl = requireMock:getContent(moduleC)
                moduleCImpl.OnUnapprovedExecution = function() end
                local moduleLoader = newModuleLoader({
                    shared = { moduleC },
                    reporter = reporterMock,
                })
                moduleLoader:loadModules()

                expect(#reporterMock.events).toEqual(1)
                expect(reporterMock.events[1].message).toEqual(
                    'shared module "C" has a `OnUnapprovedExecution` function defined that will not be called automatically. '
                        .. 'This function should be removed or the logic should be moved into a server module.'
                )
                expect(reporterMock.events[1].level).toEqual('warn')
            end)
        end)
    end

    it('errors if called twice', function()
        local moduleLoader = newModuleLoader()
        moduleLoader:loadModules()

        expect(function()
            moduleLoader:loadModules()
        end).toThrow()
    end)

    describe('onPlayerReady', function()
        local player = nil

        beforeEach(function()
            player = Mocks.Player.new()
            moduleA = requireMock:createModule('A')
            moduleB = requireMock:createModule('B')
        end)

        it('calls `OnPlayerReady` functions on client modules', function()
            local moduleLoader = newModuleLoader({
                client = { moduleA },
                player = player,
            })
            moduleLoader:loadModules()

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'A-Start',
                'A-OnPlayerReady',
            })

            local onPlayerReadyParameters = requireMock:getEvent(3).parameters
            expect(onPlayerReadyParameters.n).toEqual(1)
            expect(onPlayerReadyParameters[1]).toBe(player)
        end)

        it('calls `OnPlayerReady` functions on nested client modules', function()
            moduleA.GetChildren:returnSameValue({ moduleB })

            local moduleLoader = newModuleLoader({
                client = { moduleA },
                player = player,
                useRecursiveMode = true,
            })
            moduleLoader:loadModules()

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
                'A-OnPlayerReady',
                'B-OnPlayerReady',
            })

            for i = 5, 6 do
                local onPlayerLeavingParameters = requireMock:getEvent(i).parameters
                expect(onPlayerLeavingParameters.n).toEqual(1)
                expect(onPlayerLeavingParameters[1]).toBe(player)
            end
        end)

        it('does not call `OnPlayerReady` on shared modules', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                client = { moduleB },
                player = player,
                reporter = ReporterBuilder.new():build(),
            })
            moduleLoader:loadModules()

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
                'B-OnPlayerReady',
            })

            local onPlayerReadyParameters = requireMock:getEvent(5).parameters
            expect(onPlayerReadyParameters.n).toEqual(1)
            expect(onPlayerReadyParameters[1]).toBe(player)
        end)
    end)

    it('connects a function ending with `_event`', function()
        local clientRemotes = createClientRemotesMock()
        local moduleImpl = requireMock:getContent(moduleA)
        moduleImpl.testFunction_event = function() end
        local moduleLoader = newModuleLoader({
            client = { moduleA },
            clientRemotes = clientRemotes,
        })
        moduleLoader:loadModules()

        expect(clientRemotes.remotes['A']['testFunction']).toBe(moduleImpl.testFunction_event)
    end)

    it('connects a function ending with `_func`', function()
        local clientRemotes = createClientRemotesMock()
        local moduleImpl = requireMock:getContent(moduleA)
        moduleImpl.testFunction_func = function() end
        local moduleLoader = newModuleLoader({
            client = { moduleA },
            clientRemotes = clientRemotes,
        })
        moduleLoader:loadModules()

        expect(clientRemotes.remotes['A']['testFunction']).toBe(moduleImpl.testFunction_func)
    end)

    it('creates an alias for a function ending with `_event`', function()
        local clientRemotes = createClientRemotesMock()
        local moduleImpl = requireMock:getContent(moduleA)
        moduleImpl.testFunction_event = function() end
        local moduleLoader = newModuleLoader({
            client = { moduleA },
            clientRemotes = clientRemotes,
        })
        moduleLoader:loadModules()

        expect(moduleImpl.testFunction).toBe(moduleImpl.testFunction_event)
    end)

    it('creates an alias for a function ending with `_func`', function()
        local clientRemotes = createClientRemotesMock()
        local moduleImpl = requireMock:getContent(moduleA)
        moduleImpl.testFunction_func = function() end
        local moduleLoader = newModuleLoader({
            client = { moduleA },
            clientRemotes = clientRemotes,
        })
        moduleLoader:loadModules()

        expect(moduleImpl.testFunction).toBe(moduleImpl.testFunction_func)
    end)
end)
