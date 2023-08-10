return function()
    local ClientModuleLoader = require('./ClientModuleLoader')

    local ClientRemotes = require('./ClientRemotes')
    type ClientRemotes = ClientRemotes.ClientRemotes
    local Mocks = require('../Common/TestUtils/Mocks')
    local ReporterBuilder = require('../Common/TestUtils/ReporterBuilder')
    local createModuleScriptMock = require('../Common/TestUtils/createModuleScriptMock')
    type ModuleScriptMock = createModuleScriptMock.ModuleScriptMock
    local RequireMock = require('../Common/TestUtils/RequireMock')
    type RequiredArgs = RequireMock.RequiredArgs
    local createClientRemotesMock = require('../Common/TestUtils/createClientRemotesMock')
    local createModuleLoaderTests = require('../Common/TestUtils/createModuleLoaderTests')

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
        reporter: ReporterBuilder.Reporter?,
        useNestedMode: boolean?,
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
            useNestedMode = config.useNestedMode,
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
                useNestedMode = config.useNestedMode,
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
            end).to.throw(
                'shared module named "A" was already registered as a shared module'
            )
        end)

        it('throws if a client module name is used also for a shared module', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                client = { moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'client module named "A" was already registered as a shared module'
            )
        end)

        it('throws if a client module name is used twice', function()
            local moduleLoader = newModuleLoader({
                client = { moduleA, moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'client module named "A" was already registered as a client module'
            )
        end)

        it('throws if a shared module name is used also for an external client module', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                external = { [moduleA.Name] = {} },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
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
            end).to.throw(
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

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'shared module "C" has a `OnPlayerReady` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved into a server module or a '
                            .. 'client module.'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
                end)

                it('warns if a shared module has a `OnPlayerLeaving` function', function()
                    moduleC = requireMock:createModule('C', { OnPlayerReady = false })
                    local moduleLoader = newModuleLoader({
                        shared = { moduleC },
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'shared module "C" has a `OnPlayerLeaving` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved into a server module.'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
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

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'shared module "C" has a `OnUnapprovedExecution` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved into a server module.'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
                end)
            end)
        end

        it("calls shared module's `Init` and `Start` function first", function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                client = { moduleB },
            })
            moduleLoader:loadModules()

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
            })
        end)

        it("calls shared module's Init function first", function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                client = { moduleB },
            })
            moduleLoader:loadModules()

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
            })
        end)

        it('errors if called twice', function()
            local moduleLoader = newModuleLoader()
            moduleLoader:loadModules()

            expect(function()
                moduleLoader:loadModules()
            end).to.throw()
        end)
    end)
end
