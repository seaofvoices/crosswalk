local ReplicatedStorage = game:GetService('ReplicatedStorage')

local jest = require('@pkg/@jsdotlua/jest')

local jestRoots = {
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('crosswalk-common'),
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('crosswalk-server'),
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('crosswalk-client'),
    ReplicatedStorage:FindFirstChild('node_modules'):FindFirstChild('crosswalk-test-utils'),
}

local success, result = jest.runCLI(ReplicatedStorage, {}, jestRoots):await()

if not success then
    error(result)
end

task.wait(0.5)
