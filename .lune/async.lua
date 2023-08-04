local task = require('@lune/task')

local function runAllTask(tasks: { () -> () })
    local startTime = os.clock()

    local running = table.create(#tasks, true)
    for i, callback in tasks do
        task.spawn(function()
            local success, err = pcall(callback :: any)
            running[i] = false
            if not success then
                error(err)
            end
        end)
    end

    local allFinished = false
    repeat
        task.wait()
        allFinished = true
        for _, isRunning in running do
            if isRunning then
                allFinished = false
                break
            end
        end
    until allFinished

    local duration = os.clock() - startTime
    return duration
end

return {
    runAllTask=runAllTask
}
