local createModuleScriptMock = require('./createModuleScriptMock')
type ModuleScriptMock = createModuleScriptMock.ModuleScriptMock

export type RequiredArgs = { [number]: any, n: number }

type ModuleOptions = {
    Init: boolean?,
    Start: boolean?,
    OnPlayerReady: boolean?,
    OnPlayerLeaving: boolean?,
}
export type RequireMock = {
    createModule: (self: RequireMock, name: string, options: ModuleOptions?) -> (),
    getContent: (self: RequireMock, moduleScriptMock: ModuleScriptMock) -> any,
    getRequiredArgs: (self: RequireMock, moduleScriptMock: ModuleScriptMock) -> RequiredArgs,
    reset: (self: RequireMock) -> (),
    expectEventLabels: (self: RequireMock, expect: any, events: { string }) -> (),

    requireModule: (ModuleScript, ...any) -> any,
}

type Private = {
    _callEvents: {},
    _cache: {
        [ModuleScriptMock]: {
            content: any,
            loaded: RequiredArgs?,
        },
    },

    _getEventLogger: (self: RequireMock, label: string) -> (...any) -> (),
}
type RequireMockStatic = RequireMock & Private & {
    new: () -> RequireMock,
}

local RequireMock: RequireMockStatic = {} :: any
local RequireMockMetatable = {
    __index = RequireMock,
}

function RequireMock.new(): RequireMock
    local self
    self = {
        _cache = {},
        _callEvents = {},

        requireModule = function(moduleScript: ModuleScript, ...)
            local self = self :: RequireMock & Private

            local moduleScriptMock = self._cache[moduleScript :: any]

            assert(moduleScriptMock ~= nil, ('module `%s` never created'):format(moduleScript.Name))
            assert(
                moduleScriptMock.loaded == nil,
                ('attempt to require module `%s` twice'):format(moduleScript.Name)
            )

            moduleScriptMock.loaded = table.pack(...)

            return moduleScriptMock.content
        end,
    }
    return setmetatable(self, RequireMockMetatable) :: any
end

function RequireMock:reset()
    local self = self :: RequireMock & Private

    self._cache = {}
    self._callEvents = {}
end

function RequireMock:createModule(name: string, options: ModuleOptions?): ModuleScriptMock
    local self = self :: RequireMock & Private

    local options: ModuleOptions = options or {}
    local scriptMock = createModuleScriptMock(name)
    self._cache[scriptMock] = {
        content = {
            Init = if options.Init == false then nil else self:_getEventLogger(name .. '-Init'),
            Start = if options.Start == false then nil else self:_getEventLogger(name .. '-Start'),
            OnPlayerReady = if options.OnPlayerReady == false
                then nil
                else self:_getEventLogger(name .. '-OnPlayerReady'),
            OnPlayerLeaving = if options.OnPlayerLeaving == false
                then nil
                else self:_getEventLogger(name .. '-OnPlayerLeaving'),
        },
        loaded = nil,
    }
    return scriptMock
end

function RequireMock:getContent(moduleScriptMock: ModuleScriptMock): any
    local self = self :: RequireMock & Private

    local cached = self._cache[moduleScriptMock]

    assert(cached ~= nil, ('module `%s` never created'):format(moduleScriptMock.Name))

    return cached.content
end

function RequireMock:getRequiredArgs(moduleScriptMock: ModuleScriptMock): RequiredArgs
    local self = self :: RequireMock & Private

    local cached = self._cache[moduleScriptMock]

    assert(cached ~= nil, ('module `%s` never created'):format(moduleScriptMock.Name))
    assert(cached.loaded ~= nil, ('module `%s` never loaded'):format(moduleScriptMock.Name))

    return cached.loaded
end

function RequireMock:expectEventLabels(expect: any, events: { string })
    local self = self :: RequireMock & Private

    assert(
        #self._callEvents == #events,
        ('expected %d events but received %d'):format(#events, #self._callEvents)
    )
    for i, label in events do
        expect(self._callEvents[i].label).to.equal(label)
    end
end

function RequireMock:_getEventLogger(label: string): (...any) -> ()
    local self = self :: RequireMock & Private

    return function(...)
        table.insert(self._callEvents, {
            label = label,
            parameters = { ... },
        })
    end
end

return RequireMock
