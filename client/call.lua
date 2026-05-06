local callBlips = {}

RegisterNetEvent("emergency:receiveCall", function(job, caller, message, coords, service)
    local playerData = exports.qbx_core:GetPlayerData()
    local playerJob = playerData.job.name

    -- Job categories
    local policeJobs = { police = true }
    local fireJobs = { fire = true }
    local ambulanceJobs = { ambulance = true }
    local highwaysJobs = { highways = true }
    local gruppe6Jobs = { gruppe6 = true }
    local mechanicJobs = { mechanic = true, lscustoms = true, bennys = true, highways = true }


    local function isJobInGroup(jobName)
        return policeJobs[jobName] or fireJobs[jobName] or ambulanceJobs[jobName] or gruppe6Jobs[jobName] or mechanicJobs[jobName] or highwaysJobs[jobName]
    end

    -- Eligibility check
    local eligible = false
    if job == "all" then
        eligible = isJobInGroup(playerJob)
    elseif playerJob == job then
        eligible = true
    end

    if not eligible then return end

    -- Sound (played twice for emphasis)
    for _ = 1, 2 do
        PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
        Wait(100)
    end

    -- Blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.5)
    SetBlipColour(blip, service == "police" and 3 or service == "fire" and 1 or 2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Emergency Call")
    EndTextCommandSetBlipName(blip)

    -- Auto-remove blip after 4 minutes
    CreateThread(function()
        Wait(240000)
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)


    -- Center screen notification
    lib.notify({
        title = "?? EMERGENCY - " .. service:upper(),
        description = "**From:** " .. caller .. "\n**Message:** " .. message .. "\n**Press E near the call to assign.**",
        type = "inform",
        duration = 15000,
        position = "top-center"
    })

    -- GPS assignment on "E"
    CreateThread(function()
        local assigned = false
        while not assigned do
            Wait(0)
            if IsControlJustPressed(0, 38) then
                SetNewWaypoint(coords.x, coords.y)
                lib.notify({
                    description = "Call assigned. GPS set to emergency location.",
                    type = "success",
                    position = "top-center"
                })
                assigned = true
            end
        end
    end)

end)

RegisterNetEvent("emergency:dispatchFeedback", function(success, service)
    if success then
        lib.notify({
            title = "?? Dispatch System",
            description = "Emergency call successfully dispatched to " .. service .. " units.",
            type = "success",
            position = "top-center"
        })
    else
        lib.notify({
            title = "?? Dispatch System",
            description = "No available " .. service .. " units available to answer your call.",
            type = "error",
            position = "top-center"
        })
    end
end)
