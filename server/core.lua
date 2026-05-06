local QBCore = exports['qb-core']:GetCoreObject()


local OnDutyServices = {
    police = {},
    fire = {},
    ambulance = {},
    highways = {},
    mechanic = {},
    gruppe6 = {},
    all = {} -- for convenience, updated automatically
}



-- Lookup tables for all jobs by service
local Jobs = {
    police = {"police"},
    fire = {"fire"},
    highways = {"highways"},
    gruppe6 = {"gruppe6"},
    mechanic = {"mechanic", "lscustoms", "bennys", "highways"},
    ambulance = {"ambulance", "firearms", "police", "fire", "standbymedic"},
    all = {"police", "response", "firearms", "cid", "roadspolicing", "fire", "ambulance"}
}

-- ? FIRST: Define the function
local function RefreshOnDutyCache()
    OnDutyServices.police = {}
    OnDutyServices.fire = {}
    OnDutyServices.ambulance = {}
    OnDutyServices.highways = {}
    OnDutyServices.mechanic = {}
    OnDutyServices.gruppe6 = {}
    OnDutyServices.all = {}

    for _, src in ipairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(src)
        if not player then goto continue end

        local job = player.PlayerData.job
        if not job or not job.onduty then goto continue end

        for service, jobList in pairs(Jobs) do
            if service ~= "all" then
                for _, jName in ipairs(jobList) do
                    if job.name == jName then
                        table.insert(OnDutyServices[service], src)
                        break
                    end
                end
            end
        end

        for _, jName in ipairs(Jobs.all) do
            if job.name == jName then
                table.insert(OnDutyServices.all, src)
                break
            end
        end

        ::continue::
    end
end


local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1352957897780494406/MNWVmffS7QE86NIymjLcBAn8apjuebaV1BMVxPKla0YYEyODElD-zTTPzIyprQvZByLf' -- replace with your real URL


local function SendDiscord999Log(data)
    local embed = {
        {
            title = "?? 999 Call - " .. data.service:upper(),
            color = 16753920, -- orange/yellowish
            fields = {
                { name = "Caller", value = data.caller, inline = true },
                { name = "Service", value = data.service, inline = true },
                { name = "Message", value = data.message, inline = false },
                { name = "Location", value = string.format("X: %.2f, Y: %.2f, Z: %.2f", data.coords.x, data.coords.y, data.coords.z), inline = false },
                { name = "Citizen ID", value = data.citizenid or "Hidden", inline = true }
            },
            footer = { text = "Emergency Command System" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(DISCORD_WEBHOOK_URL, function(err, text, headers) end, "POST", json.encode({
        username = "999 Dispatcher",
        embeds = embed
    }), { ["Content-Type"] = "application/json" })
end

RegisterServerEvent("emergency:sendCall", function(service, anon, message, coords)
RefreshOnDutyCache()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local jobList = Jobs[service]
    if not jobList then
        TriggerClientEvent("lib:notify", src, {
            title = "999 Error",
            description = "Invalid service. Use: police, fire, ambulance, highways, mechanic, gruppe6, or all.",
            type = "error",
            position = "top-center"
        })
        return
    end

    local responders = OnDutyServices[service] or {}
    local validResponders = {}
    for _, responderSrc in ipairs(responders) do
        if QBCore.Functions.GetPlayer(responderSrc) then
            table.insert(validResponders, responderSrc)
        end
    end

    -- Count total receivers (cross-check job names)
-- Count total receivers ONLY from jobList
local totalReceivers = 0
for _, responderSrc in ipairs(QBCore.Functions.GetPlayers()) do
    local p = QBCore.Functions.GetPlayer(responderSrc)
    if p then
        local responderJob = p.PlayerData.job
        if responderJob and responderJob.onduty then
            for _, validJob in ipairs(jobList) do
                if responderJob.name == validJob then
                    totalReceivers = totalReceivers + 1
                    break
                end
            end
        end
    end
end

    -- Send client feedback to original caller
if totalReceivers > 1 then
    TriggerClientEvent("emergency:dispatchFeedback", src, true, service)
elseif totalReceivers == 0 then
    TriggerClientEvent("emergency:dispatchFeedback", src, false, service)
else
    -- Optional: You could also show "Dispatched to 1 unit."
    TriggerClientEvent("emergency:dispatchFeedback", src, true, service)
end

    local charinfo = Player.PlayerData.charinfo
    local name = ("%s %s [%s]"):format(charinfo.firstname, charinfo.lastname, Player.PlayerData.citizenid)
    local displayName = (anon == "true") and "Anonymous" or name

    SendDiscord999Log({
        service = service,
        caller = name .. ' Annonymously',
        citizenid = Player.PlayerData.citizenid,
        message = message,
        coords = coords
    })

    -- Get name or anonymous

    -- Send call to all jobs in list
    for _, job in ipairs(jobList) do
        TriggerClientEvent("emergency:receiveCall", -1, job, displayName, message, coords, service)
    end

    SendDiscord999Log({
        service = service,
        caller = displayName,
        citizenid = (anon == "true") and "Hidden" or Player.PlayerData.citizenid,
        message = message,
        coords = coords
    })
end)
AddEventHandler('reload', function()
    RefreshOnDutyCache()
end)

AddEventHandler("playerDropped", function()
    RefreshOnDutyCache()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    RefreshOnDutyCache()
end)

CreateThread(function()
    Wait(1000)
    RefreshOnDutyCache()
end)

RegisterCommand("dutycachedump", function(source)
    print(json.encode(OnDutyServices, { indent = true }))
end, true)




