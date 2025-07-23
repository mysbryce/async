Async = {}

local function executeSingleTask(task, cb)
    task(cb)
end

function Async.parallel(tasks, cb)
    local taskCount = #tasks

    if taskCount == 0 then
        cb({})
        return
    end

    if taskCount == 1 then
        executeSingleTask(tasks[1], function(result)
            cb({ result })
        end)
        return
    end

    local remaining = taskCount
    local results = {}

    for i = 1, taskCount do
        results[i] = nil
    end

    for i = 1, taskCount do
        local taskIndex = i
        CreateThread(function()
            tasks[taskIndex](function(result)
                results[taskIndex] = result
                remaining = remaining - 1

                if remaining == 0 then
                    cb(results)
                end
            end)
        end)
    end
end

function Async.parallelLimit(tasks, limit, cb)
    local taskCount = #tasks

    if taskCount == 0 then
        cb({})
        return
    end

    if limit >= taskCount then
        Async.parallel(tasks, cb)
        return
    end

    local remaining = taskCount
    local running = 0
    local currentIndex = 1
    local results = {}

    for i = 1, taskCount do
        results[i] = nil
    end

    local function processNext()
        while running < limit and currentIndex <= taskCount do
            local taskIndex = currentIndex
            currentIndex = currentIndex + 1
            running = running + 1

            CreateThread(function()
                tasks[taskIndex](function(result)
                    results[taskIndex] = result
                    remaining = remaining - 1
                    running = running - 1

                    if remaining == 0 then
                        cb(results)
                    else
                        processNext()
                    end
                end)
            end)
        end
    end

    processNext()
end

function Async.series(tasks, cb)
    Async.parallelLimit(tasks, 1, cb)
end
