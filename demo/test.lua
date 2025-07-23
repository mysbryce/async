local taskId = 0

AddEventHandler('ns_tester:useAsync', function()
    local asyncTasks = {}
    taskId = (taskId or 0) + 1
    local myId = tostring(taskId)

    table.insert(asyncTasks, function(cb)
        for _ = 1, math.random(80, 300) do
            if math.random(0, 10) == 10 then
                break
            end
        end

        cb()
    end)

    Async.parallel(asyncTasks, function()
		print(('Task %s completed'):format(myId))
	end)
end)

AddEventHandler('ns_tester:withoutAsync', function()
    taskId = (taskId or 0) + 1
    local myId = tostring(taskId)

    for _ = 1, math.random(80, 300) do
        if math.random(0, 10) == 10 then
            break
        end
    end

    print(('Task %s completed'):format(myId))
end)

RegisterCommand('test-perf-async', function()
    for _ = 1, 6 do
        CreateThread(function()
            for _ = 1, 100 do
                TriggerEvent('ns_tester:useAsync')
            end
        end)
    end
end, true)

RegisterCommand('test-perf-withoutasync', function()
    for _ = 1, 6 do
        CreateThread(function()
            for _ = 1, 100 do
                TriggerEvent('ns_tester:withoutAsync')
            end
        end)
    end
end, true)