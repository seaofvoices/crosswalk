return function()
    local ModuleLoader = require('./ModuleLoader')
    type ModuleLoader = ModuleLoader.ModuleLoader
    local ServerRemotes = require('./ServerRemotes')

    local TestUtils = require('@pkg/crosswalk-test-utils')
    local Mocks = TestUtils.Mocks
    local ReporterBuilder = TestUtils.ReporterBuilder
    type ModuleScriptMock = TestUtils.ModuleScriptMock
    local RequireMock = TestUtils.RequireMock
    type RequiredArgs = TestUtils.RequiredArgs
    local createModuleLoaderTests = TestUtils.createModuleLoaderTests
    local createServerRemotesMock = require('./tests-utils/createServerRemotesMock')
    type RemoteEventMock = createServerRemotesMock.RemoteEventMock

    type Reporter = TestUtils.Reporter

    local requireMock = RequireMock.new()

    beforeEach(function()
        requireMock:reset()
    end)

    type NewModuleLoaderConfig = {
        requireModule: ((ModuleScript, ...any) -> any)?,
        shared: { ModuleScript }?,
        server: { ModuleScript }?,
        client: { ModuleScript }?,
        external: { [any]: any }?,
        serverRemotes: ServerRemotes.ServerRemotes?,
        reporter: Reporter?,
        useRecursiveMode: boolean?,
        services: any,
    }
    local function newModuleLoader(config: NewModuleLoaderConfig?): ModuleLoader
        local config: NewModuleLoaderConfig = config or {}
        return ModuleLoader.new({
            shared = config.shared or {} :: any,
            server = config.server or {} :: any,
            client = config.client or {} :: any,
            external = config.external or {},
            requireModule = config.requireModule or requireMock.requireModule,
            serverRemotes = config.serverRemotes or createServerRemotesMock(),
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
        createModuleLoaderTests('server', function(config)
            return newModuleLoader({
                requireModule = config.requireModule,
                server = config.self,
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
            end).to.throw(
                'shared module named "A" was already registered as a shared module'
            )
        end)

        it('throws if a server module name is used also for a shared module', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                server = { moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'server module named "A" was already registered as a shared module'
            )
        end)

        it('throws if a server module name is used twice', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA, moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'server module named "A" was already registered as a server module'
            )
        end)

        it('throws if a shared module name is used also for an external module', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                external = { [moduleA.Name] = {} },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'shared module named "A" was already provided as an external server module. '
                    .. 'Rename the shared module or the external module'
            )
        end)

        it('throws if a server module name is used also for an external module', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
                external = { [moduleA.Name] = {} },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'server module named "A" was already provided as an external server module. '
                    .. 'Rename the server module or the external module'
            )
        end)

        it('throws if a client module name is used also for a shared module', function()
            local moduleLoader = newModuleLoader({
                client = { moduleA },
                shared = { moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'client module named "A" was already registered as a shared module'
            )
        end)

        it('throws if a client module name is used also for a server module', function()
            local moduleLoader = newModuleLoader({
                client = { moduleA },
                server = { moduleA },
            })
            expect(function()
                moduleLoader:loadModules()
            end).to.throw(
                'client module named "A" was already registered as a server module'
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

        local CASES = {
            test_event = {
                type = 'event',
                name = 'test',
                security = 'High',
            },
            test_risky_event = {
                type = 'event',
                name = 'test',
                security = 'Low',
            },
            test_danger_event = {
                type = 'event',
                name = 'test',
                security = 'None',
            },
            test_func = {
                type = 'function',
                name = 'test',
                security = 'High',
            },
            test_risky_func = {
                type = 'function',
                name = 'test',
                security = 'Low',
            },
            test_danger_func = {
                type = 'function',
                name = 'test',
                security = 'None',
            },
        }

        for concreteName, info in pairs(CASES) do
            describe(('module with a function called `%s`'):format(concreteName), function()
                local serverRemotesMock
                beforeEach(function()
                    serverRemotesMock = createServerRemotesMock()
                    local moduleAImpl = requireMock:getContent(moduleA)
                    moduleAImpl[concreteName] = function(arg): any
                        if info.type == 'function' then
                            return true, 'ok:' .. arg
                        else
                            return true
                        end
                    end
                    local moduleLoader = newModuleLoader({
                        server = { moduleA },
                        serverRemotes = serverRemotesMock,
                    })
                    moduleLoader:loadModules()
                end)

                it(('adds a %s to server'):format(info.type), function()
                    local expectedKind: { RemoteEventMock } = if info.type
                            == 'event'
                        then serverRemotesMock.events
                        else serverRemotesMock.functions
                    local otherKind = if info.type == 'event'
                        then serverRemotesMock.functions
                        else serverRemotesMock.events
                    expect(#expectedKind).to.equal(1)
                    expect(#otherKind).to.equal(0)

                    local event = expectedKind[1]
                    expect(event.moduleName).to.equal(moduleA.Name)
                    expect(event.name).to.equal(info.name)
                    local moduleAImpl = requireMock:getContent(moduleA)
                    expect(event.func).to.equal(moduleAImpl[concreteName])
                    expect(event.security).to.equal(info.security)
                end)

                it('adds a function to call it from another server module', function()
                    local moduleAImpl = requireMock:getContent(moduleA)
                    local callback = moduleAImpl[info.name]
                    expect(callback).to.be.a('function')
                    if info.type == 'function' then
                        expect(callback('0')).to.equal('ok:0')
                    else
                        expect(callback).never.to.throw()
                    end
                end)
            end)

            describe(('shared module with a function called `%s`'):format(concreteName), function()
                local serverRemotesMock
                local reporterMock
                beforeEach(function()
                    serverRemotesMock = createServerRemotesMock()
                    local moduleAImpl = requireMock:getContent(moduleA)
                    moduleAImpl[concreteName] = function() end
                    reporterMock = ReporterBuilder.new():onlyWarn():build()
                    local moduleLoader = newModuleLoader({
                        shared = { moduleA },
                        serverRemotes = serverRemotesMock,
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()
                end)

                it(('does not add a %s to server'):format(info.type), function()
                    expect(#serverRemotesMock.events).to.equal(0)
                    expect(#serverRemotesMock.functions).to.equal(0)
                end)

                if _G.DEV then
                    it('warns', function()
                        expect(#reporterMock.events).to.equal(1)
                        expect(reporterMock.events[1].message).to.equal(
                            (
                                'shared module "A" has a function "%s" that is meant to exist on '
                                .. 'client or server modules. It should probably be renamed to "%s"'
                            ):format(concreteName, info.name)
                        )
                        expect(reporterMock.events[1].level).to.equal('warn')
                    end)
                else
                    it('does not warn', function()
                        expect(#reporterMock.events).to.equal(0)
                    end)
                end
            end)
        end

        if _G.DEV then
            describe('warn for wrong usage of shared modules', function()
                local reporterMock
                beforeEach(function()
                    reporterMock = ReporterBuilder.new():onlyWarn():build()
                end)

                it('warns if a shared module has a `OnPlayerReady` function', function()
                    local testModule = requireMock:createModule('test', { OnPlayerLeaving = false })
                    local moduleLoader = newModuleLoader({
                        shared = { testModule },
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'shared module "test" has a `OnPlayerReady` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved into a server module or a '
                            .. 'client module.'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
                end)

                it('warns if a shared module has a `OnPlayerLeaving` function', function()
                    local testModule = requireMock:createModule('test', { OnPlayerReady = false })
                    local moduleLoader = newModuleLoader({
                        shared = { testModule },
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'shared module "test" has a `OnPlayerLeaving` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved into a server module.'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
                end)

                it('warns if a shared module has a `OnUnapprovedExecution` function', function()
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

            describe('warn for bad usage', function()
                local reporterMock
                local moduleAImpl
                beforeEach(function()
                    reporterMock = ReporterBuilder.new():onlyWarn():build()
                    moduleAImpl = requireMock:getContent(moduleA)
                end)

                it('warns when an `_event` function returns more than one value', function()
                    moduleAImpl.forgetValidation_event = function()
                        return true, 'result'
                    end
                    local moduleLoader = newModuleLoader({
                        server = { moduleA },
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()

                    expect(moduleAImpl.forgetValidation).to.be.a('function')

                    moduleAImpl.forgetValidation()

                    expect(#reporterMock.events).to.equal(1)
                    expect(reporterMock.events[1].message).to.equal(
                        'function `A.forgetValidation_event` is declared as an exposed remote '
                            .. 'event, but it is returning more than the '
                            .. 'required validation boolean.\n\nTo make this '
                            .. 'function return values to clients, replace '
                            .. 'the `_event` suffix with `_func`. If the '
                            .. 'function does not need to return values, '
                            .. 'remove them as they are ignored by crosswalk'
                    )
                    expect(reporterMock.events[1].level).to.equal('warn')
                end)

                local functionExtensions = {
                    '_event',
                    '_func',
                }

                for _, extension in ipairs(functionExtensions) do
                    local functionName = 'forgetValidation' .. extension

                    it(('warns when a `%s` function returns nothing'):format(extension), function()
                        moduleAImpl[functionName] = function() end
                        local moduleLoader = newModuleLoader({
                            server = { moduleA },
                            reporter = reporterMock,
                        })
                        moduleLoader:loadModules()

                        expect(moduleAImpl.forgetValidation).to.be.a('function')

                        moduleAImpl.forgetValidation()

                        expect(#reporterMock.events).to.equal(1)
                        expect(reporterMock.events[1].message).to.equal(
                            ('function `A.%s` should return a boolean '):format(functionName)
                                .. 'to indicate whether the call was approved or not, but got '
                                .. '`nil` (of type `nil`).\n\nLearn more about server modules '
                                .. 'function validation at: '
                                .. 'https://crosswalk.seaofvoices.ca/Guide/ServerModules/#validation'
                        )
                        expect(reporterMock.events[1].level).to.equal('warn')
                    end)

                    it(
                        ('warns when a `%s` function does not return a boolean'):format(extension),
                        function()
                            moduleAImpl[functionName] = function()
                                return 1
                            end
                            local moduleLoader = newModuleLoader({
                                server = { moduleA },
                                reporter = reporterMock,
                            })
                            moduleLoader:loadModules()

                            expect(moduleAImpl.forgetValidation).to.be.a('function')

                            moduleAImpl.forgetValidation()

                            expect(#reporterMock.events).to.equal(1)
                            expect(reporterMock.events[1].message).to.equal(
                                ('function `A.%s` should return a boolean '):format(functionName)
                                    .. 'to indicate whether the call was approved or not, but got '
                                    .. '`1` (of type `number`).\n\nLearn more about server modules '
                                    .. 'function validation at: '
                                    .. 'https://crosswalk.seaofvoices.ca/Guide/ServerModules/#validation'
                            )
                            expect(reporterMock.events[1].level).to.equal('warn')
                        end
                    )

                    it(('warns when a `%s` function does not succeed'):format(extension), function()
                        moduleAImpl[functionName] = function()
                            return false
                        end
                        local moduleLoader = newModuleLoader({
                            server = { moduleA },
                            reporter = reporterMock,
                        })
                        moduleLoader:loadModules()

                        expect(moduleAImpl.forgetValidation).to.be.a('function')

                        local function callForgetValidation()
                            moduleAImpl.forgetValidation()
                        end

                        callForgetValidation()

                        local line: number, moduleCaller = debug.info(callForgetValidation, 'ls')

                        expect(#reporterMock.events).to.equal(1)
                        expect(reporterMock.events[1].message).to.equal(
                            ('function `A.%s` is declared as an exposed '):format(functionName)
                                .. 'remote, but the validation failed when calling '
                                .. ('it from `callForgetValidation` at line %d'):format(line + 1)
                                .. (' in server module `%s`'):format(moduleCaller)
                        )
                        expect(reporterMock.events[1].level).to.equal('warn')
                    end)
                end
            end)
        end

        it("calls shared module's `Init` and `Start` function first", function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                server = { moduleB },
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
                server = { moduleB },
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

    describe('hasLoaded', function()
        it('is true after calling `loadModules`', function()
            local moduleLoader = newModuleLoader()
            moduleLoader:loadModules()
            expect(moduleLoader:hasLoaded()).to.equal(true)
        end)

        it('is false before calling `loadModules`', function()
            local moduleLoader = newModuleLoader()
            expect(moduleLoader:hasLoaded()).to.equal(false)
        end)
    end)

    describe('onPlayerReady', function()
        local moduleA: ModuleScriptMock
        local moduleB: ModuleScriptMock

        beforeEach(function()
            moduleA = requireMock:createModule('A')
            moduleB = requireMock:createModule('B')
        end)

        it('calls `OnPlayerReady` functions on server modules', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerReady(player)

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'A-Start',
                'A-OnPlayerReady',
            })

            local onPlayerReadyParameters = requireMock:getEvent(3).parameters
            expect(onPlayerReadyParameters.n).to.equal(1)
            expect(onPlayerReadyParameters[1]).to.equal(player)
        end)

        it('calls `OnPlayerReady` functions on nested server modules', function()
            moduleA.GetChildren:returnSameValue({ moduleB })

            local moduleLoader = newModuleLoader({
                server = { moduleA },
                useRecursiveMode = true,
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerReady(player)

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
                expect(onPlayerLeavingParameters.n).to.equal(1)
                expect(onPlayerLeavingParameters[1]).to.equal(player)
            end
        end)

        it('does not call `OnPlayerReady` on shared modules', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                server = { moduleB },
                reporter = ReporterBuilder.new():build(),
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerReady(player)

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
                'B-OnPlayerReady',
            })

            local onPlayerReadyParameters = requireMock:getEvent(5).parameters
            expect(onPlayerReadyParameters.n).to.equal(1)
            expect(onPlayerReadyParameters[1]).to.equal(player)
        end)
    end)

    describe('onPlayerRemoving', function()
        local moduleA: ModuleScriptMock
        local moduleB: ModuleScriptMock

        beforeEach(function()
            moduleA = requireMock:createModule('A')
            moduleB = requireMock:createModule('B')
        end)

        it('calls `OnPlayerLeaving` functions on server modules', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerRemoving(player)

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'A-Start',
                'A-OnPlayerLeaving',
            })

            local onPlayerLeavingParameters = requireMock:getEvent(3).parameters
            expect(onPlayerLeavingParameters.n).to.equal(1)
            expect(onPlayerLeavingParameters[1]).to.equal(player)
        end)

        it('calls `OnPlayerLeaving` functions on nested server modules', function()
            moduleA.GetChildren:returnSameValue({ moduleB })

            local moduleLoader = newModuleLoader({
                server = { moduleA },
                useRecursiveMode = true,
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerRemoving(player)

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
                'A-OnPlayerLeaving',
                'B-OnPlayerLeaving',
            })

            for i = 5, 6 do
                local onPlayerLeavingParameters = requireMock:getEvent(i).parameters
                expect(onPlayerLeavingParameters.n).to.equal(1)
                expect(onPlayerLeavingParameters[1]).to.equal(player)
            end
        end)

        it('does not call `OnPlayerLeaving` on shared modules', function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                server = { moduleB },
                reporter = ReporterBuilder.new():build(),
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerRemoving(player)

            requireMock:expectEventLabels(expect, {
                'A-Init',
                'B-Init',
                'A-Start',
                'B-Start',
                'B-OnPlayerLeaving',
            })

            local onPlayerLeavingParameters = requireMock:getEvent(5).parameters
            expect(onPlayerLeavingParameters.n).to.equal(1)
            expect(onPlayerLeavingParameters[1]).to.equal(player)
        end)

        it('clears the remotes associated with the player', function()
            local serverRemotes = createServerRemotesMock()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
                serverRemotes = serverRemotes,
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerRemoving(player)

            serverRemotes.clearPlayer:expectCalledOnce(expect, serverRemotes, player)
        end)
    end)
end
