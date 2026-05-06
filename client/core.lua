RegisterCommand("999", function(source, args)
    local service = args[1] and string.lower(args[1]) or nil
    local anon = args[2] and string.lower(args[2]) or nil
    local message = table.concat(args, " ", 3)
    if not service or not anon or message == "" then
        lib.notify({
            title = "999 Help",
            description = "Usage:\n/999 <service> <anon|true|false> <message>\nServices: police, fire, ambulance, gruppe6, highways, mechanic, all",
            type = "inform",
            position = "top-center"
        })
        return
    end

if anon ~= "true" and anon ~= "false" then
    TriggerClientEvent("lib:notify", src, {
        title = "999 Error",
        description = "Invalid anonymity flag. Use 'true' or 'false'.",
        type = "error",
        position = "top-center"
    })
    return
end

    if service == "police" then
        local alert = {
            coords = GetEntityCoords(PlayerPedId()),
            message = message,
            dispatchCode = 'CODE 3',
            description = 'Emergency Call',
            radius = 0,
            sprite = 52,
            color = 1,
            scale = 1.0,
            length = 3
        }
       exports["ps-dispatch"]:CustomAlert(alert)

end

    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("emergency:sendCall", service, anon, message, coords)
end, false)

-- ?? Register chat suggestion for /999
TriggerEvent('chat:addSuggestion', '/999', 'Call emergency services', {
    { name = 'service required?', help = 'police, fire, ambulance, highways, gruppe6, mechanic, all' },
    { name = 'is this call annonymous?', help = 'true, false' },
    { name = 'how can they help?', help = 'What\'s happening?' }
})
-- ? THEN: Use the function in handlers/commands
AddEventHandler("QBCore:Server:OnPlayerLoaded", function()
        TriggerServerEvent("callecenter:reload", author, message)
end)

