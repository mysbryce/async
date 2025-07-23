--- @alias AsyncTask fun(callback: fun(result: any): nil): nil
--- @alias AsyncCallback fun(results: any[]): nil

--- @class Async
--- @field parallel fun(tasks: AsyncTask[], cb: AsyncCallback): nil
--- @field parallelLimit fun(tasks: AsyncTask[], limit: integer, cb: AsyncCallback): nil
--- @field series fun(tasks: AsyncTask[], cb: AsyncCallback): nil
Async = {}

--- Execute a single task with callback
--- @param task AsyncTask The task function to execute
--- @param cb fun(result: any): nil Callback function for the result
local function executeSingleTask(task, cb)
    task(cb)
end

--- Execute multiple tasks in parallel
--- @param tasks AsyncTask[] Array of task functions
--- @param cb AsyncCallback Callback function that receives array of results
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

--- Execute multiple tasks in parallel with concurrency limit
--- @param tasks AsyncTask[] Array of task functions
--- @param limit integer Maximum number of concurrent tasks
--- @param cb AsyncCallback Callback function that receives array of results
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
    
    ---@type fun(): nil
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

--- Execute multiple tasks in series (one after another)
--- @param tasks AsyncTask[] Array of task functions
--- @param cb AsyncCallback Callback function that receives array of results
function Async.series(tasks, cb)
    Async.parallelLimit(tasks, 1, cb)
end