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

type Task = () -> ()
type ParallelTasks<T> = { type: nil, [number]: T }
type SeqTask<T> = {
    type: 'seq',
    n: number,
    [number]: T,
}
export type TreeTask = Task | ParallelTasks<TreeTask> | SeqTask<TreeTask>

local function runTree(tree: TreeTask): number
    if type(tree) == 'function' then
        local startTime = os.clock()
        tree()
        return os.clock() - startTime
    else
        local tree = tree :: ParallelTasks<TreeTask> | SeqTask<TreeTask>
        if tree.type == 'seq' then
            local startTime = os.clock()
            for i = 1, tree.n do
                runTree(tree[i])
            end
            return os.clock() - startTime
        else
            local startTime = os.clock()

            local running = table.create(#tree, true)
            for i, subTask in tree do
                task.spawn(function()
                    local success, err = pcall(runTree, subTask)
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

            return os.clock() - startTime
        end
    end
end

return {
    task = function(callback: () -> ()): TreeTask
        return callback
    end,
    parallel = function(tasks: { TreeTask }): TreeTask
        return tasks :: any
    end,
    seq = function(tasks: { TreeTask }): TreeTask
        (tasks :: any).n = #tasks;
        (tasks :: any).type = 'seq'
        return tasks :: any
    end,
    runAllTask = runAllTask,
    runTree = runTree,
}
