if isServer() then
    return
end
local Core = PhunLib

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name then
        Core:setIsNight(command == Core.commands.OnDusk)
    end
end)

Events.OnCreatePlayer.Add(function(player)
    Core:ini()
end)

-- Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
--     Core:showContext(playerObj, context, worldobjects)
-- end);
