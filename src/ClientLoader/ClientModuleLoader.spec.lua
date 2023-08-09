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

    local requireMock = RequireMock.new()

    beforeEach(function()
        requireMock:reset()
    end)

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
            requireModule = requireMock.requireModule,
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

        for _, useNestedMode in { false, true } do
            local describeName = 'modules signature'
                .. if useNestedMode then ' (nested mode)' else ''

            describe(describeName, function()
                local moduleD: ModuleScriptMock
                local moduleB2: ModuleScriptMock
                local moduleC2: ModuleScriptMock

                local aLoadedWith: RequiredArgs
                local bLoadedWith: RequiredArgs
                local b2LoadedWith: RequiredArgs
                local cLoadedWith: RequiredArgs
                local c2LoadedWith: RequiredArgs
                local dLoadedWith: RequiredArgs
                local servicesMock

                beforeEach(function()
                    moduleD = requireMock:createModule('D', noPlayerFunctions)

                    if useNestedMode then
                        moduleB2 = requireMock:createModule('B2', noPlayerFunctions)
                        moduleC2 = requireMock:createModule('C2', noPlayerFunctions)

                        moduleB.GetChildren:returnSameValue({ moduleB2 })
                        moduleC.GetChildren:returnSameValue({ moduleC2 })
                    end

                    servicesMock = {}
                    local moduleLoader = newModuleLoader({
                        shared = { moduleA, moduleB },
                        client = { moduleC, moduleD },
                        services = servicesMock,
                        useNestedMode = useNestedMode,
                    })
                    moduleLoader:loadModules()

                    aLoadedWith = requireMock:getRequiredArgs(moduleA)
                    bLoadedWith = requireMock:getRequiredArgs(moduleB)
                    cLoadedWith = requireMock:getRequiredArgs(moduleC)
                    dLoadedWith = requireMock:getRequiredArgs(moduleC)

                    if useNestedMode then
                        b2LoadedWith = requireMock:getRequiredArgs(moduleB2)
                        c2LoadedWith = requireMock:getRequiredArgs(moduleC2)
                    end

                    expect(aLoadedWith.n).to.equal(3)
                    expect(bLoadedWith.n).to.equal(3)
                    expect(cLoadedWith.n).to.equal(3)
                    expect(dLoadedWith.n).to.equal(3)
                end)

                if useNestedMode then
                    it('loads shared modules with nested module', function()
                        local bModules = bLoadedWith[1]
                        expect(bModules.B2).to.equal(requireMock:getContent(moduleB2))
                    end)

                    it('loads nested shared modules with its parent module', function()
                        local b2Modules = b2LoadedWith[1]
                        expect(b2Modules.B).to.equal(requireMock:getContent(moduleB))
                    end)

                    it("loads nested shared modules with its parent's siblings", function()
                        local b2Modules = b2LoadedWith[1]
                        expect(b2Modules.A).to.equal(requireMock:getContent(moduleA))
                    end)

                    it('loads client modules with nested module', function()
                        local cModules = cLoadedWith[1]
                        expect(cModules.C2).to.equal(requireMock:getContent(moduleC2))
                    end)

                    it('loads nested client modules with its parent module', function()
                        local c2Modules = c2LoadedWith[1]
                        expect(c2Modules.C).to.equal(requireMock:getContent(moduleC))
                    end)

                    it("loads nested client modules with its parent's siblings", function()
                        local c2Modules = c2LoadedWith[1]
                        expect(c2Modules.D).to.equal(requireMock:getContent(moduleD))
                    end)
                end

                it('loads shared modules with other shared modules', function()
                    local aModules = aLoadedWith[1]
                    expect(aModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(aModules.B).to.equal(requireMock:getContent(moduleB))

                    local bModules = bLoadedWith[1]
                    expect(bModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(bModules.B).to.equal(requireMock:getContent(moduleB))
                end)

                it('loads shared modules with `Services` utility', function()
                    local aServices = aLoadedWith[2]
                    local bServices = bLoadedWith[2]

                    expect(aServices).to.equal(servicesMock)
                    expect(bServices).to.equal(servicesMock)
                end)

                it('loads client module with `Services` utility', function()
                    local cServices = cLoadedWith[3]

                    expect(cServices).to.equal(servicesMock)
                end)

                it('loads shared modules with `isServer` boolean to false', function()
                    local aIsServer = aLoadedWith[3]
                    local bIsServer = bLoadedWith[3]

                    expect(aIsServer).to.equal(false)
                    expect(bIsServer).to.equal(false)
                end)

                it('loads client modules with shared modules', function()
                    local cModules = cLoadedWith[1]
                    expect(cModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(cModules.B).to.equal(requireMock:getContent(moduleB))

                    local dModules = dLoadedWith[1]
                    expect(dModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(dModules.B).to.equal(requireMock:getContent(moduleB))
                end)

                it('loads client module with other client modules', function()
                    local cModules = cLoadedWith[1]

                    expect(cModules.C).to.equal(requireMock:getContent(moduleC))
                    expect(cModules.D).to.equal(requireMock:getContent(moduleD))

                    local dModules = dLoadedWith[1]
                    expect(dModules.C).to.equal(requireMock:getContent(moduleC))
                    expect(dModules.D).to.equal(requireMock:getContent(moduleD))
                end)
            end)
        end

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

        describe('use nested mode', function()
            local moduleD: ModuleScriptMock

            beforeEach(function()
                moduleD = requireMock:createModule('D', noPlayerFunctions)
            end)

            for _, moduleKind in { 'client', 'shared' } do
                describe(('with %s modules'):format(moduleKind), function()
                    it('loads a nested module', function()
                        moduleB.GetChildren:returnSameValue({ moduleC })

                        local moduleLoader = newModuleLoader({
                            client = { moduleA, moduleB },
                            useNestedMode = true,
                        } :: any)
                        moduleLoader:loadModules()

                        requireMock:expectEventLabels(expect, {
                            'A-Init',
                            'B-Init',
                            'C-Init',
                            'A-Start',
                            'B-Start',
                            'C-Start',
                        })
                    end)

                    it('loads a nested module in a nested module', function()
                        moduleA.GetChildren:returnSameValue({ moduleB })
                        moduleB.GetChildren:returnSameValue({ moduleC })

                        local moduleLoader = newModuleLoader({
                            [moduleKind] = { moduleA },
                            useNestedMode = true,
                        } :: any)
                        moduleLoader:loadModules()

                        requireMock:expectEventLabels(expect, {
                            'A-Init',
                            'B-Init',
                            'C-Init',
                            'A-Start',
                            'B-Start',
                            'C-Start',
                        })
                    end)

                    it('loads two nested modules', function()
                        moduleA.GetChildren:returnSameValue({ moduleB })
                        moduleC.GetChildren:returnSameValue({ moduleD })

                        local moduleLoader = newModuleLoader({
                            [moduleKind] = { moduleA, moduleC },
                            useNestedMode = true,
                        } :: any)
                        moduleLoader:loadModules()

                        requireMock:expectEventLabels(expect, {
                            'A-Init',
                            'C-Init',
                            'B-Init',
                            'D-Init',
                            'A-Start',
                            'C-Start',
                            'B-Start',
                            'D-Start',
                        })
                    end)
                end)
            end

            it('calls `Init` function on nested shared modules before client modules', function()
                moduleA.GetChildren:returnSameValue({ moduleB })
                moduleC.GetChildren:returnSameValue({ moduleD })

                local moduleLoader = newModuleLoader({
                    shared = { moduleA },
                    client = { moduleC },
                    useNestedMode = true,
                })
                moduleLoader:loadModules()

                requireMock:expectEventLabels(expect, {
                    'A-Init',
                    'B-Init',
                    'C-Init',
                    'D-Init',
                    'A-Start',
                    'B-Start',
                    'C-Start',
                    'D-Start',
                })
            end)
        end)
    end)
end
