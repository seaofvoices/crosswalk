return function()
    local ClientModuleLoader = require('./ClientModuleLoader')

    local ClientRemotes = require('./ClientRemotes')
    type ClientRemotes = ClientRemotes.ClientRemotes
    local Mocks = require('../Common/TestUtils/Mocks')
    local ReporterBuilder = require('../Common/TestUtils/ReporterBuilder')

    local moduleMocks = {}
    local function requireMock(moduleScript)
        return moduleMocks[moduleScript]
    end

    local function createClientRemotesMock(): ClientRemotes
        return {
            _remotes = {},
            _serverModules = {},
            getServerModules = function(self)
                return self._serverModules
            end,
            listen = Mocks.Function.new(),
            disconnect = Mocks.Function.new(),
            connectRemote = function(self, module, functionName, callback)
                if self._remotes[module] == nil then
                    self._remotes[module] = {
                        [functionName] = callback,
                    }
                else
                    self._remotes[module][functionName] = callback
                end
            end,
            fireReadyRemote = Mocks.Function.new(),
        } :: any
    end

    type NewModuleLoaderConfig = {
        shared: { ModuleScript }?,
        client: { ModuleScript }?,
        external: { [string]: any }?,
        player: Player?,
        clientRemotes: ClientRemotes?,
        reporter: ReporterBuilder.Reporter?,
    }
    local function newModuleLoader(config: NewModuleLoaderConfig?)
        local config: NewModuleLoaderConfig = config or {}
        return ClientModuleLoader.new({
            shared = config.shared or {},
            client = config.client or {},
            external = config.external or {},
            player = config.player or Mocks.Player.new(),
            requireModule = requireMock,
            clientRemotes = config.clientRemotes or createClientRemotesMock(),
            reporter = config.reporter,
        })
    end

    local callEvents = {}

    local function getEventLogger(label)
        return function(...)
            table.insert(callEvents, {
                label = label,
                parameters = { ... },
            })
        end
    end

    local MODULE_FUNCTIONS = { 'Init', 'Start', 'OnPlayerReady', 'OnPlayerLeaving' }

    local function generateModule(moduleName, options)
        options = options or {}
        local newModule = {}
        for _, functionName in ipairs(MODULE_FUNCTIONS) do
            if options[functionName] == nil or options[functionName] then
                newModule[functionName] = getEventLogger(('%s-%s'):format(moduleName, functionName))
            end
        end
        return newModule
    end

    beforeEach(function()
        callEvents = {}
        moduleMocks = {}
    end)

    describe('loadModules', function()
        local moduleA: ModuleScript
        local moduleB: ModuleScript
        local moduleC: ModuleScript

        beforeEach(function()
            moduleA = { Name = 'A' } :: any
            moduleB = { Name = 'B' } :: any
            moduleC = { Name = 'C' } :: any

            moduleMocks = {
                [moduleA] = generateModule('A', {
                    OnPlayerReady = false,
                    OnPlayerLeaving = false,
                }),
                [moduleB] = generateModule('B', {
                    OnPlayerReady = false,
                    OnPlayerLeaving = false,
                }),
            }
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
                    moduleMocks[moduleC] = generateModule('C', { OnPlayerLeaving = false })
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
                    moduleMocks[moduleC] = generateModule('C', { OnPlayerReady = false })
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
                    moduleMocks[moduleC] = generateModule('C', {
                        OnPlayerReady = false,
                        OnPlayerLeaving = false,
                    })
                    moduleMocks[moduleC].OnUnapprovedExecution = function() end
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

            expect(#callEvents).to.equal(4)
            expect(callEvents[1].label).to.equal('A-Init')
            expect(callEvents[2].label).to.equal('B-Init')
            expect(callEvents[3].label).to.equal('A-Start')
            expect(callEvents[4].label).to.equal('B-Start')
        end)

        it("calls shared module's Init function first", function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                client = { moduleB },
            })
            moduleLoader:loadModules()

            expect(#callEvents).to.equal(4)
            expect(callEvents[1].label).to.equal('A-Init')
            expect(callEvents[2].label).to.equal('B-Init')
            expect(callEvents[3].label).to.equal('A-Start')
            expect(callEvents[4].label).to.equal('B-Start')
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
