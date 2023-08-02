return function()
    local ModuleLoader = require(script.Parent.ModuleLoader)

    local TestUtils = script.Parent.Common.TestUtils
    local Mocks = require(TestUtils.Mocks)
    local ReporterBuilder = require(TestUtils.ReporterBuilder)

    local moduleMocks = {}
    local function requireMock(moduleScript)
        return moduleMocks[moduleScript]
    end

    local function createServerRemotesMock()
        return {
            events = {},
            functions = {},
            addEventToServer = function(self, moduleName, name, func, security)
                table.insert(self.events, {
                    moduleName = moduleName,
                    name = name,
                    func = func,
                    security = security,
                })
            end,
            addFunctionToServer = function(self, moduleName, name, func, security)
                table.insert(self.functions, {
                    moduleName = moduleName,
                    name = name,
                    func = func,
                    security = security,
                })
            end,
            clearPlayer = Mocks.Function.new(),
        }
    end

    local function newModuleLoader(config)
        config = config or {}
        return ModuleLoader.new({
            shared = config.shared or {},
            server = config.server or {},
            client = config.client or {},
            external = config.external or {},
            requireModule = requireMock,
            serverRemotes = config.serverRemotes or createServerRemotesMock(),
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
        local moduleA = { Name = 'A' }
        local moduleB = { Name = 'B' }
        local moduleC = { Name = 'C' }

        beforeEach(function()
            callEvents = {}
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
                    moduleMocks[moduleA][concreteName] = function(arg)
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
                    local expectedKind = info.type == 'event' and 'events' or 'functions'
                    local otherKind = info.type == 'event' and 'functions' or 'events'
                    expect(#serverRemotesMock[expectedKind]).to.equal(1)
                    expect(#serverRemotesMock[otherKind]).to.equal(0)

                    local event = serverRemotesMock[expectedKind][1]
                    expect(event.moduleName).to.equal(moduleA.Name)
                    expect(event.name).to.equal(info.name)
                    expect(event.func).to.equal(moduleMocks[moduleA][concreteName])
                    expect(event.security).to.equal(info.security)
                end)

                it('adds a function to call it from another server module', function()
                    local callback = moduleMocks[moduleA][info.name]
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
                    moduleMocks[moduleA][concreteName] = function() end
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

            describe('warn for bad usage', function()
                local reporterMock
                beforeEach(function()
                    reporterMock = ReporterBuilder.new():onlyWarn():build()
                    moduleMocks[moduleA] = generateModule('A', {
                        OnPlayerReady = false,
                        OnPlayerLeaving = false,
                    })
                end)

                it('warns when an `_event` function returns more than one value', function()
                    moduleMocks[moduleA].forgetValidation_event = function()
                        return true, 'result'
                    end
                    local moduleLoader = newModuleLoader({
                        server = { moduleA },
                        reporter = reporterMock,
                    })
                    moduleLoader:loadModules()

                    expect(moduleMocks[moduleA].forgetValidation).to.be.a('function')

                    moduleMocks[moduleA].forgetValidation()

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
                        moduleMocks[moduleA][functionName] = function() end
                        local moduleLoader = newModuleLoader({
                            server = { moduleA },
                            reporter = reporterMock,
                        })
                        moduleLoader:loadModules()

                        expect(moduleMocks[moduleA].forgetValidation).to.be.a('function')

                        moduleMocks[moduleA].forgetValidation()

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
                            moduleMocks[moduleA][functionName] = function()
                                return 1
                            end
                            local moduleLoader = newModuleLoader({
                                server = { moduleA },
                                reporter = reporterMock,
                            })
                            moduleLoader:loadModules()

                            expect(moduleMocks[moduleA].forgetValidation).to.be.a('function')

                            moduleMocks[moduleA].forgetValidation()

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
                        moduleMocks[moduleA][functionName] = function()
                            return false
                        end
                        local moduleLoader = newModuleLoader({
                            server = { moduleA },
                            reporter = reporterMock,
                        })
                        moduleLoader:loadModules()

                        expect(moduleMocks[moduleA].forgetValidation).to.be.a('function')

                        local function callForgetValidation()
                            moduleMocks[moduleA].forgetValidation()
                        end

                        callForgetValidation()

                        local line, moduleCaller = debug.info(callForgetValidation, 'ls')

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

            expect(#callEvents).to.equal(4)
            expect(callEvents[1].label).to.equal('A-Init')
            expect(callEvents[2].label).to.equal('B-Init')
            expect(callEvents[3].label).to.equal('A-Start')
            expect(callEvents[4].label).to.equal('B-Start')
        end)

        it("calls shared module's Init function first", function()
            local moduleLoader = newModuleLoader({
                shared = { moduleA },
                server = { moduleB },
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
        local moduleA = { Name = 'A' }
        local moduleB = { Name = 'B' }

        beforeEach(function()
            callEvents = {}
            moduleMocks = {
                [moduleA] = generateModule('A'),
                [moduleB] = generateModule('B'),
            }
        end)

        it('calls `OnPlayerReady` functions on server modules', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerReady(player)

            expect(#callEvents).to.equal(3)
            local event = callEvents[3]
            expect(event.label).to.equal('A-OnPlayerReady')
            expect(#event.parameters).to.equal(1)
            expect(event.parameters[1]).to.equal(player)
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

            expect(#callEvents).to.equal(5)
            expect(callEvents[1].label).to.equal('A-Init')
            expect(callEvents[2].label).to.equal('B-Init')
            expect(callEvents[3].label).to.equal('A-Start')
            expect(callEvents[4].label).to.equal('B-Start')
            local event = callEvents[5]
            expect(event.label).to.equal('B-OnPlayerReady')
            expect(#event.parameters).to.equal(1)
            expect(event.parameters[1]).to.equal(player)
        end)
    end)

    describe('onPlayerRemoving', function()
        local moduleA = { Name = 'A' }
        local moduleB = { Name = 'B' }

        beforeEach(function()
            callEvents = {}
            moduleMocks = {
                [moduleA] = generateModule('A'),
                [moduleB] = generateModule('B'),
            }
        end)

        it('calls `OnPlayerLeaving` functions on server modules', function()
            local moduleLoader = newModuleLoader({
                server = { moduleA },
            })
            moduleLoader:loadModules()
            local player = Mocks.Player.new()
            moduleLoader:onPlayerRemoving(player)

            expect(#callEvents).to.equal(3)
            local event = callEvents[3]
            expect(event.label).to.equal('A-OnPlayerLeaving')
            expect(#event.parameters).to.equal(1)
            expect(event.parameters[1]).to.equal(player)
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

            expect(#callEvents).to.equal(5)
            expect(callEvents[1].label).to.equal('A-Init')
            expect(callEvents[2].label).to.equal('B-Init')
            expect(callEvents[3].label).to.equal('A-Start')
            expect(callEvents[4].label).to.equal('B-Start')
            local event = callEvents[5]
            expect(event.label).to.equal('B-OnPlayerLeaving')
            expect(#event.parameters).to.equal(1)
            expect(event.parameters[1]).to.equal(player)
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
