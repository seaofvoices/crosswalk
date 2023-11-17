local Common = require('@pkg/crosswalk-common')

export type Services = Common.Services & {
    ContextActionService: ContextActionService,
    ReplicatedFirst: ReplicatedFirst,
    RunService: RunService,
    UserInputService: UserInputService,
}

return Common.makeServices({
    ReplicatedFirst = game:GetService('ReplicatedFirst'),
    RunService = game:GetService('RunService'),
    UserInputService = game:GetService('UserInputService'),
}) :: Services
