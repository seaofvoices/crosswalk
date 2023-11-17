local Common = require('@pkg/crosswalk-common')

export type Services = Common.Services & {
    ServerScriptService: ServerScriptService,
    ServerStorage: ServerStorage,
}

return Common.makeServices({
    ServerScriptService = game:GetService('ServerScriptService'),
    ServerStorage = game:GetService('ServerStorage'),
}) :: Services
