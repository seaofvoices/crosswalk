local makeServices = require('../Common/makeServices')

export type Services = makeServices.Services & {
    ServerScriptService: ServerScriptService,
    ServerStorage: ServerStorage,
}

return makeServices({
    ServerScriptService = game:GetService('ServerScriptService'),
    ServerStorage = game:GetService('ServerStorage'),
}) :: Services
