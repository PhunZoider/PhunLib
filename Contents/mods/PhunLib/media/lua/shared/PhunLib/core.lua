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
        onlinePlayers:add(p);
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

local hasServerInstalled = nil

function Core:setIsNight(value)

    if self.isNight == value then
        return
    end
    self.isNight = value
    -- local speed = Core.settings.DaySpeed
    -- if value then
    --     speed = Core.settings.NightSpeed
    -- end
    -- getSandboxOptions():getOptionByName("DayLength"):setValue(speed)
    -- getSandboxOptions():applySettings()
    print("PhunLib: It is now " .. (value and "night." or "day.") .. " - " ..
              tostring(getSandboxOptions():getOptionByName("DayLength"):getValue()) .. " day length.")
    if isServer() then
        sendServerCommand(Core.name, value and Core.commands.onDusk or Core.commands.onDawn, {})
    end
    triggerEvent(value and self.events.OnDusk or self.events.OnDawn)
end

function Core:testNight()

    if hasServerInstalled == nil then
        hasServerInstalled = getActivatedMods():contains("PhunServer")
    end

    if hasServerInstalled then
        return
    end

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
            self.dawnTime = season:getDawn()
            self.duskTime = season:getDusk()
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

function Core.isInSafehouse(square)

    local safehouses = SafeHouse:getSafehouseList()
    for index = 1, safehouses:size(), 1 do
        local safehouse = safehouses:get(index - 1)
        if square:getX() > safehouse:getX() and square:getX() < safehouse:getX2() then
            if square:getY() > safehouse:getY() and square:getY() < safehouse:getY2() then
                return true
            end
        end
    end
end

local tid = nil
function Core.getCategory(item)
    -- from the awesome BetterSorting mod by Blindcoder,
    -- but modified to return the category rather than just set it
    -- local debug = {
    --     ["Base.Jatimatic_Stock"] = true,
    --     ["Base.Brass556"] = true
    -- }

    -- if debug[item:getFullName()] then
    --     print("Debugging category for item: " .. item:getFullName())
    -- end

    if tid == nil then
        if TweakItemData then
            tid = TweakItemData
        else
            tid = false
        end
    end
    if tid then
        local check = TweakItemData[item:getFullName()] or {}
        local test = check["DisplayCategory"] or check["displaycategory"]
        if test then
            return test
        end
    end

    local category = item.getCategory and item:getCategory() or item.getTypeString and item:getTypeString() or nil
    local dcategory = item:getDisplayCategory();

    category = tostring(dcategory or category)

    -- print("Checking category for item: " .. item:getFullName() .. " - DisplayCategory: " .. category)

    if item.fluidContainer then
        local fluid = item.fluidContainer:getFluidContainer():getPrimaryFluid();
        if fluid and item:getFluidContainer():getAmount() > 0 then
            if fluid:isCategory(FluidCategory.Alcoholic) then
                category = "FoodA";
            elseif fluid:isCategory(FluidCategory.Beverage) then
                category = "FoodB";
            elseif fluid:isCategory(FluidCategory.Fuel) then
                category = "Fuel"
            end
        else
            category = "Container";
        end
    elseif item.getCanStoreWater and item:getCanStoreWater() then
        if item:getTypeString() ~= "Drainable" then
            category = "Container";
        else
            category = "FoodB";
        end

    elseif item:getDisplayCategory() == "Water" then
        category = "FoodB";

    elseif item.getTypeString and item:getTypeString() == "Food" then
        if item:getDaysTotallyRotten() > 0 and item:getDaysTotallyRotten() < 1000000000 then
            category = "FoodP";
        else
            category = "FoodN";
        end

    elseif item.getTypeString and item:getTypeString() == "Literature" then
        if string.len(item:getSkillTrained()) > 0 then
            category = "LitS";
        elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
            category = "LitR";
        elseif item:getStressChange() ~= 0 or item:getBoredomChange() ~= 0 or item:getUnhappyChange() ~= 0 then
            category = "LitE";
        else
            category = "LitW";
        end

    elseif item.getTypeString and item:getTypeString() == "Weapon" then
        if item:getDisplayCategory() == "Explosives" or item:getDisplayCategory() == "Devices" then
            category = "WepBomb";
        end

        -- Tsar's True Music Cassette and Vinyls
    elseif string.find(item:getFullName(), "Tsarcraft.Cassette") or string.find(item:getFullName(), "Tsarcraft.Vinyl") then
        category = "MediaA";

        -- Tsar's True Actions Dance Cards
    elseif item.getTypeString and item:getTypeString() == "Normal" and item:getModuleName() == "TAD" then
        category = "Misc";
    end

    return category or "Unknown"
end

function Core.getAllItemCategories()

    if Core.itemCategories == nil then
        Core.getAllItems()
    end

    return Core.itemCategories

end

function Core.getAllItems(refresh)

    if Core.itemsAll ~= nil and not refresh then
        return Core.itemsAll
    end
    Core.itemsAll = {}
    Core.itemCategories = {}
    local catMap = {}

    local itemList = getScriptManager():getAllItems()
    for i = 0, itemList:size() - 1 do
        local item = itemList:get(i)
        if not item:getObsolete() and not item:isHidden() then

            local cat = Core.getCategory(item) or "Unknown" -- Core.getCategory(item)
            if cat ~= "" and catMap[cat] == nil then
                catMap[cat] = true
                table.insert(Core.itemCategories, {
                    label = cat,
                    type = cat
                })
            end
            table.insert(Core.itemsAll, {
                type = item:getFullName(),
                label = item:getDisplayName(),
                texture = item:getNormalTexture(),
                category = cat
            })
        end
    end

    table.sort(Core.itemsAll, function(a, b)
        return a.label:lower() < b.label:lower()
    end)
    table.sort(Core.itemCategories, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    return Core.itemsAll
end
