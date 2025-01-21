if isClient() then
    return
end
local Core = PhunLib
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.OnServerStarted.Add(function()
    Core:testNight()
end)

Events.EveryOneMinute.Add(function()
    Core:testNight()
end)

Events.EveryTenMinutes.Add(function()
    if Core.onlinePlayers():size() > 0 then
        emptyServerCalculate = true
    end
end)

Events.OnTickEvenPaused.Add(function()

    if emptyServerCalculate and emptyServerTickCount > 100 then
        local players = Core.onlinePlayers()
        if players:size() == 0 then
            emptyServerCalculate = false
            triggerEvent(Core.events.OnEmptyServer, {})
            Core.doLogs()
        end
    elseif emptyServerTickCount > 100 then
        emptyServerTickCount = 0
    else
        emptyServerTickCount = emptyServerTickCount + 1
    end
end)