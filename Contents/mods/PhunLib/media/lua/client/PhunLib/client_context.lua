if isServer() then
    return
end

local Core = PhunLib
local PZ = PhunZones

function Core:showContext(playerObj, context, worldobjects)

    if isAdmin() or isDebugEnabled() then

        local mainMenu = context:addOption("Phun Admin")

        if PZ then
            PZ:appendContext(context, mainMenu, playerObj, worldobjects)
        end

    end

end
