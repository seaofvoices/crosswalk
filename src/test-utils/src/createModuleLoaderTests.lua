local createModuleScriptMock = require('./createModuleScriptMock')
type ModuleScriptMock = createModuleScriptMock.ModuleScriptMock
local Common = require('@pkg/crosswalk-common')
type Reporter = Common.Reporter
local RequireMock = require('./RequireMock')
type RequiredArgs = RequireMock.RequiredArgs
local FunctionMock = require('./FunctionMock')

type NewModuleLoaderConfig = {
    requireModule: (ModuleScript, ...any) -> any,
    shared: { ModuleScript }?,
    self: { ModuleScript }?,
    reporter: Reporter?,
    useRecursiveMode: boolean?,
    services: any,
}
type ModuleLoaderLike = { loadModules: (self: any) -> () }

type Callback = () -> ()

local function createModuleLoaderTests(
    kind: 'client' | 'server',
    loader: (NewModuleLoaderConfig) -> ModuleLoaderLike
)
    return function()
        local requireMock = RequireMock.new()
        local requireModuleMock = nil

        local function createModuleLoader(config: {
            shared: { ModuleScript }?,
            self: { ModuleScript }?,
            reporter: Reporter?,
            useRecursiveMode: boolean?,
            services: any,
        })
            return loader({
                shared = config.shared,
                self = config.self,
                reporter = config.reporter,
                useRecursiveMode = config.useRecursiveMode,
                requireModule = requireMock.requireModule,
                services = config.services,
            })
        end

        beforeEach(function()
            requireModuleMock = FunctionMock.new()
            requireMock:reset()
            requireMock.onModuleLoaded = function(...)
                local args = { n = select('#', ...) }
                for i = 1, args.n do
                    local value = select(i, ...)
                    args[i] = if type(value) == 'table' then table.clone(value) else value
                end
                requireModuleMock:call(unpack(args, 1, args.n))
            end
        end)

        local noPlayerFunctions = {
            OnPlayerReady = false,
            OnPlayerLeaving = false,
        }

        local moduleA: ModuleScriptMock
        local moduleB: ModuleScriptMock
        local moduleC: ModuleScriptMock
        local moduleD: ModuleScriptMock

        beforeEach(function()
            moduleA = requireMock:createModule('A', noPlayerFunctions)
            moduleB = requireMock:createModule('B', noPlayerFunctions)
            moduleC = requireMock:createModule('C', noPlayerFunctions)
            moduleD = requireMock:createModule('D', noPlayerFunctions)
        end)

        describe('use nested mode', function()
            for _, moduleKind in { 'self', 'shared' } do
                describe(
                    ('with %s modules'):format(if moduleKind == 'self' then kind else moduleKind),
                    function()
                        it('loads a nested module', function()
                            moduleB.GetChildren:returnSameValue({ moduleC })

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA, moduleB } :: any,
                                useRecursiveMode = true,
                            })
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

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA } :: any,
                                useRecursiveMode = true,
                            })
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

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA, moduleC } :: any,
                                useRecursiveMode = true,
                            })
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

                        it('loads a deeply nested module', function()
                            moduleA.GetChildren:returnSameValue({ moduleB })
                            moduleB.GetChildren:returnSameValue({ moduleC })
                            moduleC.GetChildren:returnSameValue({ moduleD })

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA } :: any,
                                useRecursiveMode = true,
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

                        it('calls Init functions in the correct order', function()
                            -- Create this a module structure:
                            -- A
                            -- - B
                            -- - - C
                            -- - D
                            -- - - E
                            -- F
                            -- - G
                            -- - - H
                            -- - I

                            local onlyInitFunctions = {
                                Start = false,
                                OnPlayerReady = false,
                                OnPlayerLeaving = false,
                            }
                            requireMock:reset()
                            moduleA = requireMock:createModule('A', onlyInitFunctions)
                            moduleB = requireMock:createModule('B', onlyInitFunctions)
                            moduleC = requireMock:createModule('C', onlyInitFunctions)
                            moduleD = requireMock:createModule('D', onlyInitFunctions)
                            local moduleE = requireMock:createModule('E', onlyInitFunctions)
                            local moduleF = requireMock:createModule('F', onlyInitFunctions)
                            local moduleG = requireMock:createModule('G', onlyInitFunctions)
                            local moduleH = requireMock:createModule('H', onlyInitFunctions)
                            local moduleI = requireMock:createModule('I', onlyInitFunctions)

                            moduleA.GetChildren:returnSameValue({ moduleB, moduleD })
                            moduleB.GetChildren:returnSameValue({ moduleC })
                            moduleD.GetChildren:returnSameValue({ moduleE })
                            moduleF.GetChildren:returnSameValue({ moduleG, moduleI })
                            moduleG.GetChildren:returnSameValue({ moduleH })

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA, moduleF } :: any,
                                useRecursiveMode = true,
                            })
                            moduleLoader:loadModules()

                            requireMock:expectEventLabels(expect, {
                                'A-Init',
                                'F-Init',
                                'B-Init',
                                'D-Init',
                                'G-Init',
                                'I-Init',
                                'C-Init',
                                'E-Init',
                                'H-Init',
                            })
                        end)
                    end
                )
            end

            it(
                ('calls `Init` function on nested shared modules before %s modules'):format(kind),
                function()
                    moduleA.GetChildren:returnSameValue({ moduleB })
                    moduleC.GetChildren:returnSameValue({ moduleD })

                    local moduleLoader = createModuleLoader({
                        shared = { moduleA },
                        self = { moduleC },
                        useRecursiveMode = true,
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
                end
            )

            it(('loads nested %s modules with access to shared modules'):format(kind), function()
                moduleA.GetChildren:returnSameValue({ moduleC })

                local moduleLoader = createModuleLoader({
                    self = { moduleA },
                    shared = { moduleB },
                    useRecursiveMode = true,
                })
                moduleLoader:loadModules()

                expect(#requireModuleMock.calls).to.equal(3)
                expect(requireModuleMock.calls[1].argumentCount).to.equal(4)
                expect(requireModuleMock.calls[2].argumentCount).to.equal(4)

                local loadSharedModuleArguments = requireModuleMock.calls[1].arguments
                expect(loadSharedModuleArguments[1].Name).to.equal(moduleB.Name)

                local loadModuleArguments = requireModuleMock.calls[2].arguments
                expect(loadModuleArguments[1].Name).to.equal(moduleA.Name)
                expect(loadModuleArguments[2].B).to.be.a('table')

                local loadNestedModuleArguments = requireModuleMock.calls[3].arguments
                expect(loadNestedModuleArguments[1].Name).to.equal(moduleC.Name)
                expect(loadNestedModuleArguments[2].B).to.be.a('table')
            end)
        end)

        for _, useRecursiveMode in { false, true } do
            local describeName = 'modules signature'
                .. if useRecursiveMode then ' (recursive mode)' else ''

            describe(describeName, function()
                local moduleA2: ModuleScriptMock
                local moduleB2: ModuleScriptMock
                local moduleB3: ModuleScriptMock
                local moduleC2: ModuleScriptMock
                local moduleD2: ModuleScriptMock
                local moduleD3: ModuleScriptMock

                local aLoadedWith: RequiredArgs
                local a2LoadedWith: RequiredArgs
                local bLoadedWith: RequiredArgs
                local b2LoadedWith: RequiredArgs
                local b3LoadedWith: RequiredArgs
                local cLoadedWith: RequiredArgs
                local c2LoadedWith: RequiredArgs
                local dLoadedWith: RequiredArgs
                local d2LoadedWith: RequiredArgs
                local d3LoadedWith: RequiredArgs

                local servicesMock

                beforeEach(function()
                    if useRecursiveMode then
                        moduleA2 = requireMock:createModule('A2', noPlayerFunctions)
                        moduleB2 = requireMock:createModule('B2', noPlayerFunctions)
                        moduleB3 = requireMock:createModule('B3', noPlayerFunctions)
                        moduleC2 = requireMock:createModule('C2', noPlayerFunctions)
                        moduleD2 = requireMock:createModule('D2', noPlayerFunctions)
                        moduleD3 = requireMock:createModule('D3', noPlayerFunctions)

                        moduleA.GetChildren:returnSameValue({ moduleA2 })
                        moduleB.GetChildren:returnSameValue({ moduleB2 })
                        moduleB2.GetChildren:returnSameValue({ moduleB3 })
                        moduleC.GetChildren:returnSameValue({ moduleC2 })
                        moduleD.GetChildren:returnSameValue({ moduleD2 })
                        moduleD2.GetChildren:returnSameValue({ moduleD3 })
                    end

                    servicesMock = {}
                    local moduleLoader = createModuleLoader({
                        shared = { moduleA, moduleB },
                        self = { moduleC, moduleD },
                        services = servicesMock,
                        useRecursiveMode = useRecursiveMode,
                    })
                    moduleLoader:loadModules()

                    aLoadedWith = requireMock:getRequiredArgs(moduleA)
                    bLoadedWith = requireMock:getRequiredArgs(moduleB)
                    cLoadedWith = requireMock:getRequiredArgs(moduleC)
                    dLoadedWith = requireMock:getRequiredArgs(moduleD)

                    if useRecursiveMode then
                        a2LoadedWith = requireMock:getRequiredArgs(moduleA2)
                        b2LoadedWith = requireMock:getRequiredArgs(moduleB2)
                        b3LoadedWith = requireMock:getRequiredArgs(moduleB3)
                        c2LoadedWith = requireMock:getRequiredArgs(moduleC2)
                        d2LoadedWith = requireMock:getRequiredArgs(moduleD2)
                        d3LoadedWith = requireMock:getRequiredArgs(moduleD2)

                        expect(b2LoadedWith.n).to.equal(3)
                        expect(b3LoadedWith.n).to.equal(3)
                        expect(c2LoadedWith.n).to.equal(3)
                        expect(d2LoadedWith.n).to.equal(3)
                        expect(d3LoadedWith.n).to.equal(3)
                    end

                    expect(aLoadedWith.n).to.equal(3)
                    expect(bLoadedWith.n).to.equal(3)
                    expect(cLoadedWith.n).to.equal(3)
                    expect(dLoadedWith.n).to.equal(3)
                end)

                if useRecursiveMode then
                    it('loads shared modules with nested module', function()
                        local aModules = aLoadedWith[1]
                        expect(aModules.A2).to.equal(requireMock:getContent(moduleA2))

                        local bModules = bLoadedWith[1]
                        expect(bModules.B2).to.equal(requireMock:getContent(moduleB2))

                        local b2Modules = b2LoadedWith[1]
                        expect(b2Modules.B3).to.equal(requireMock:getContent(moduleB3))
                    end)

                    it('loads nested shared modules with its parent module', function()
                        local a2Modules = a2LoadedWith[1]
                        expect(a2Modules.A).to.equal(requireMock:getContent(moduleA))

                        local b2Modules = b2LoadedWith[1]
                        expect(b2Modules.B).to.equal(requireMock:getContent(moduleB))

                        local b3Modules = b3LoadedWith[1]
                        expect(b3Modules.B).to.equal(requireMock:getContent(moduleB))
                        expect(b3Modules.B2).to.equal(requireMock:getContent(moduleB2))
                    end)

                    it("loads nested shared modules with its parent's siblings", function()
                        local a2Modules = a2LoadedWith[1]
                        expect(a2Modules.B).to.equal(requireMock:getContent(moduleB))

                        local b2Modules = b2LoadedWith[1]
                        expect(b2Modules.A).to.equal(requireMock:getContent(moduleA))

                        local b3Modules = b3LoadedWith[1]
                        expect(b3Modules.A).to.equal(requireMock:getContent(moduleA))
                    end)

                    it(
                        "loads nested shared modules without its parent's siblings children",
                        function()
                            local a2Modules = a2LoadedWith[1]
                            expect(a2Modules.B2).to.equal(nil)
                            expect(a2Modules.B3).to.equal(nil)

                            local b2Modules = b2LoadedWith[1]
                            expect(b2Modules.A2).to.equal(nil)
                        end
                    )

                    it(('loads %s modules with nested module'):format(kind), function()
                        local cModules = cLoadedWith[1]
                        expect(cModules.C2).to.equal(requireMock:getContent(moduleC2))

                        local dModules = dLoadedWith[1]
                        expect(dModules.D2).to.equal(requireMock:getContent(moduleD2))

                        local d2Modules = d2LoadedWith[1]
                        expect(d2Modules.D3).to.equal(requireMock:getContent(moduleD3))
                    end)

                    it(('loads nested %s modules with its parent module'):format(kind), function()
                        local c2Modules = c2LoadedWith[1]
                        expect(c2Modules.C).to.equal(requireMock:getContent(moduleC))

                        local d2Modules = d2LoadedWith[1]
                        expect(d2Modules.D).to.equal(requireMock:getContent(moduleD))

                        local d3Modules = d3LoadedWith[1]
                        expect(d3Modules.D).to.equal(requireMock:getContent(moduleD))
                        expect(d3Modules.D2).to.equal(requireMock:getContent(moduleD2))
                    end)

                    it(
                        ("loads nested %s modules with its parent's siblings"):format(kind),
                        function()
                            local c2Modules = c2LoadedWith[1]
                            expect(c2Modules.D).to.equal(requireMock:getContent(moduleD))

                            local d2Modules = d2LoadedWith[1]
                            expect(d2Modules.C).to.equal(requireMock:getContent(moduleC))

                            local d3Modules = d3LoadedWith[1]
                            expect(d3Modules.C).to.equal(requireMock:getContent(moduleC))
                        end
                    )

                    it(
                        ("loads nested %s modules without its parent's siblings children"):format(
                            kind
                        ),
                        function()
                            local c2Modules = c2LoadedWith[1]
                            expect(c2Modules.D2).to.equal(nil)
                            expect(c2Modules.D3).to.equal(nil)

                            local d2Modules = d2LoadedWith[1]
                            expect(d2Modules.C2).to.equal(nil)
                        end
                    )
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

                it(('loads %s module with `Services` utility'):format(kind), function()
                    local cServices = cLoadedWith[3]

                    expect(cServices).to.equal(servicesMock)
                end)

                local isServer = kind == 'server'
                it(
                    ('loads shared modules with `isServer` boolean to %s'):format(
                        tostring(isServer)
                    ),
                    function()
                        local aIsServer = aLoadedWith[3]
                        local bIsServer = bLoadedWith[3]

                        expect(aIsServer).to.equal(isServer)
                        expect(bIsServer).to.equal(isServer)
                    end
                )

                it('loads client modules with shared modules', function()
                    local cModules = cLoadedWith[1]
                    expect(cModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(cModules.B).to.equal(requireMock:getContent(moduleB))

                    local dModules = dLoadedWith[1]
                    expect(dModules.A).to.equal(requireMock:getContent(moduleA))
                    expect(dModules.B).to.equal(requireMock:getContent(moduleB))
                end)

                it(('loads %s module with other %s modules'):format(kind, kind), function()
                    local cModules = cLoadedWith[1]

                    expect(cModules.C).to.equal(requireMock:getContent(moduleC))
                    expect(cModules.D).to.equal(requireMock:getContent(moduleD))

                    local dModules = dLoadedWith[1]
                    expect(dModules.C).to.equal(requireMock:getContent(moduleC))
                    expect(dModules.D).to.equal(requireMock:getContent(moduleD))
                end)
            end)

            local describeName = 'special function ordering'
                .. if useRecursiveMode then ' (recursive mode)' else ''

            describe(describeName, function()
                it("calls shared module's Init function first", function()
                    local moduleLoader = createModuleLoader({
                        shared = { moduleA },
                        self = { moduleB },
                        useRecursiveMode = useRecursiveMode,
                    })
                    moduleLoader:loadModules()

                    requireMock:expectEventLabels(expect, {
                        'A-Init',
                        'B-Init',
                        'A-Start',
                        'B-Start',
                    })
                end)

                it("calls shared module's `Init` and `Start` function first", function()
                    local moduleLoader = createModuleLoader({
                        shared = { moduleA },
                        self = { moduleB },
                        useRecursiveMode = useRecursiveMode,
                    })
                    moduleLoader:loadModules()

                    requireMock:expectEventLabels(expect, {
                        'A-Init',
                        'B-Init',
                        'A-Start',
                        'B-Start',
                    })
                end)
            end)

            it(
                ('loads %s modules with access to shared modules (recursiveMode = %s)'):format(
                    kind,
                    tostring(useRecursiveMode)
                ),
                function()
                    local moduleLoader = createModuleLoader({
                        self = { moduleA },
                        shared = { moduleB },
                        useRecursiveMode = useRecursiveMode,
                    })
                    moduleLoader:loadModules()

                    expect(#requireModuleMock.calls).to.equal(2)
                    expect(requireModuleMock.calls[1].argumentCount).to.equal(4)
                    expect(requireModuleMock.calls[2].argumentCount).to.equal(4)

                    local loadSharedModuleArguments = requireModuleMock.calls[1].arguments
                    expect(loadSharedModuleArguments[1].Name).to.equal(moduleB.Name)

                    local loadModuleArguments = requireModuleMock.calls[2].arguments
                    expect(loadModuleArguments[1].Name).to.equal(moduleA.Name)
                    expect(loadModuleArguments[2].B).to.be.a('table')
                end
            )
        end
    end
end

return createModuleLoaderTests
