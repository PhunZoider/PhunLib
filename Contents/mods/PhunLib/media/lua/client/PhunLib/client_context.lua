if isServer() then
    return
end

local Core = PhunLib
local PZ = PhunZones
local PLewt = PhunLewt
local PM = PhunMart or PhunMart2

function Core:showContext(playerObj, context, worldobjects)

    if isAdmin() or isDebugEnabled() then

        local mainMenu = context:addOption("Phun Admin")

        if PZ and PZ.appendContext then
            PZ:appendContext(context, mainMenu, playerObj, worldobjects)
        end

        if PM and PM.appendContext then
            PM:appendContext(context, mainMenu, playerObj, worldobjects)
        end

        if PLewt and PLewt.appendContext then
            PLewt:appendContext(context, mainMenu, playerObj, worldobjects)
        end

    end

end
