local createModuleScriptMock = require('./createModuleScriptMock')
type ModuleScriptMock = createModuleScriptMock.ModuleScriptMock
local Reporter = require('../Reporter')
type Reporter = Reporter.Reporter
local RequireMock = require('./RequireMock')
type RequiredArgs = RequireMock.RequiredArgs

type NewModuleLoaderConfig = {
    requireModule: (ModuleScript, ...any) -> any,
    shared: { ModuleScript }?,
    self: { ModuleScript }?,
    reporter: Reporter?,
    useNestedMode: boolean?,
}
type ModuleLoaderLike = { loadModules: (self: any) -> () }

type Callback = () -> ()

local function createModuleLoaderTests(
    kind: 'client' | 'server',
    loader: (NewModuleLoaderConfig) -> ModuleLoaderLike
)
    return function()
        local requireMock = RequireMock.new()

        local function createModuleLoader(config: {
            shared: { ModuleScript }?,
            self: { ModuleScript }?,
            reporter: Reporter?,
            useNestedMode: boolean?,
        })
            return loader({
                shared = config.shared,
                self = config.self,
                reporter = config.reporter,
                useNestedMode = config.useNestedMode,
                requireModule = requireMock.requireModule,
            })
        end

        beforeEach(function()
            requireMock:reset()
        end)

        local noPlayerFunctions = {
            OnPlayerReady = false,
            OnPlayerLeaving = false,
        }

        describe('use nested mode', function()
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

            for _, moduleKind in { 'self', 'shared' } do
                describe(
                    ('with %s modules'):format(if moduleKind == 'self' then kind else moduleKind),
                    function()
                        it('loads a nested module', function()
                            moduleB.GetChildren:returnSameValue({ moduleC })

                            local moduleLoader = createModuleLoader({
                                [moduleKind] = { moduleA, moduleB } :: any,
                                useNestedMode = true,
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
                                useNestedMode = true,
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
                                useNestedMode = true,
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
                end
            )
        end)
    end
end

return createModuleLoaderTests
