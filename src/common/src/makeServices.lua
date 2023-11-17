export type Services = {
    AssetService: AssetService,
    AvatarEditorService: AvatarEditorService,
    BadgeService: BadgeService,
    CollectionService: CollectionService,
    GroupService: GroupService,
    HttpService: HttpService,
    Lighting: Lighting,
    LogService: LogService,
    PhysicsService: PhysicsService,
    Players: Players,
    ReplicatedStorage: ReplicatedStorage,
    SoundService: SoundService,
    TextChatService: TextChatService,
    TextService: TextService,
    TweenService: TweenService,
    Workspace: Workspace,
}

local function makeServices<T>(specificServices: { [string]: Instance }): Services
    local services = {
        Lighting = game:GetService('Lighting'),
        HttpService = game:GetService('HttpService'),
        Players = game:GetService('Players'),
        ReplicatedStorage = game:GetService('ReplicatedStorage'),
        SoundService = game:GetService('SoundService'),
        Workspace = game:GetService('Workspace'),
    }
    for name, serviceObject in specificServices do
        services[name] = serviceObject
    end
    return setmetatable(services, {
        __index = function(self, serviceName): unknown
            local success, service = pcall(function()
                return game:GetService(serviceName) :: any
            end)

            if not success then
                local errorMessage = tostring(service)
                error(('Cannot find service %q: %s'):format(serviceName, errorMessage))
            end

            self[serviceName] = service

            return service
        end,
    }) :: any
end

return makeServices
