local makeServices = require('../Common/makeServices')

export type Services = makeServices.Services & {
    ContextActionService: ContextActionService,
    ReplicatedFirst: ReplicatedFirst,
    RunService: RunService,
    UserInputService: UserInputService,
}

return makeServices({
    ReplicatedFirst = game:GetService('ReplicatedFirst'),
    RunService = game:GetService('RunService'),
    UserInputService = game:GetService('UserInputService'),
}) :: Services
