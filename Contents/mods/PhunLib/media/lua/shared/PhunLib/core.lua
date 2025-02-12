local fileTools = require("PhunLib/files")
local tableTools = require("PhunLib/table")
local stringTools = require("PhunLib/strings")

local climateManager = nil
local gt = nil

PhunLib = {
    inied = false,
    name = "PhunLib",
    events = {
        OnReady = "OnPhunLibReady",
        OnEmptyServer = "OnPhunLibEmptyServer",
        OnDawn = "OnPhunLibDawn",
        OnDusk = "OnPhunLibDusk"
    },
    commands = {
        onDusk = "PhunLibOnDusk",
        onDawn = "PhunLibOnDawn"
    },
    file = fileTools,
    table = tableTools,
    string = stringTools
}

local Core = PhunLib
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        triggerEvent(self.events.OnReady)
    end

end

-- wrapper for getOnlinePlayers that returns only local players if a client
function Core.onlinePlayers(all)

    local onlinePlayers;

    if Core.isLocal then
        onlinePlayers = ArrayList.new();
        local p = getPlayer()
    elseif all ~= false and isClient() then
        onlinePlayers = ArrayList.new();
        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i);
            if player:isLocalPlayer() then
                onlinePlayers:add(player);
            end
        end
    else
        onlinePlayers = getOnlinePlayers();
    end

    return onlinePlayers;
end

function Core.getPlayerByUsername(name)
    local online = Core.onlinePlayers()
    for i = 0, online:size() - 1 do
        local player = online:get(i);
        if player:getUsername() == name then
            return player
        end
    end
    return nil
end

function Core.debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            Core.printTable(v)
        else
            print(tostring(v))
        end
    end

end

function Core.printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core.printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:setIsNight(value)

    if self.isNight == value then
        return
    end
    self.isNight = value
    local speed = Core.settings.DaySpeed
    if value then
        speed = Core.settings.NightSpeed
    end
    getSandboxOptions():getOptionByName("DayLength"):setValue(speed)
    getSandboxOptions():applySettings()

    if isServer() then
        sendServerCommand(Core.name, value and Core.commands.onDusk or Core.commands.onDawn, {})
    end
    triggerEvent(value and self.events.OnDusk or self.events.OnDawn)
end

function Core:testNight()

    if not climateManager and getClimateManager then
        climateManager = getClimateManager()
    end
    if not gt and getGameTime then
        gt = getGameTime()
    end
    if gt and climateManager and climateManager.getSeason then

        local season = climateManager:getSeason()
        if season and season.getDawn then
            local time = gt:getTimeOfDay()
            self.dawnTime = season:getDawn() + self.settings.DayOffset
            self.duskTime = season:getDusk() + self.settings.NightOffset
        end
    end
    if self.duskTime and self.dawnTime then
        local currentTime = gt:getTimeOfDay()
        local night = currentTime > self.duskTime or currentTime < self.dawnTime
        if night ~= self.isNight then
            self:setIsNight(night)
        end
    end
end
