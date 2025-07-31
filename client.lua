local jobXP = {}
local jobLevel = {}
local jobXPToLevel = {}

local jobs = {"pizza_delivery", "gardening", "coding", "dog_walking"}


-- XP UI 


local uiPending = false

RegisterCommand("xp", function()
    uiPending = true
    TriggerServerEvent("rinsey-xpsystem:requestXP")
end, false)

RegisterNUICallback('getJobLevels', function(_, cb)
    local jobData = {}
    print('NUI getJobLevels called')
    for _, job in ipairs(jobs) do
        local level = exports['rinsey-xpsystem']:GetJobLevel(job)
        local xp = exports['rinsey-xpsystem']:GetJobXP(job)
        local xpToLevel = jobXPToLevel[job] or 100
        print(('Job: %s | Level: %s | XP: %s | XPToLevel: %s'):format(job, level, xp, xpToLevel))
        table.insert(jobData, {
            name = job,
            level = level,
            xp = xp,
            xpToLevel = xpToLevel
        })
    end
    cb(jobData)
end)

RegisterNUICallback('closeUI', function(data, cb)
    SendNUIMessage({
        type = "hideUI"
    })
    SetNuiFocus(false, false)
    cb('ok')
end)

-- END

local function DebugPrint(message)
    print("^2[XP CLIENT DEBUG]^7 " .. message)
end

for _, job in ipairs(jobs) do
    jobXP[job] = 0
    jobLevel[job] = 1
    jobXPToLevel[job] = 100
end

DebugPrint("Client script loaded. Jobs initialized: " .. table.concat(jobs, ", "))

RegisterNetEvent("rinsey-xpsystem:loadXP", function(serverData)
    DebugPrint("Received XP data from server (UI check)")
    for job, data in pairs(serverData) do
        jobXP[job] = data.xp or 0
        jobLevel[job] = data.level or 1
        jobXPToLevel[job] = data.xpToLevel or 100
        DebugPrint("Loaded " .. job .. ": Level " .. jobLevel[job] .. ", XP " .. jobXP[job] .. "/" .. jobXPToLevel[job])
    end
    if uiPending then
        SendNUIMessage({ type = "showUI" })
        SetNuiFocus(true, true)
        uiPending = false
    end
end)

RegisterNetEvent("rinsey-xpsystem:updateXP", function(job, xp, level, xpToLevel, leveledUp)
    DebugPrint("Received XP update: " .. job .. " - Level " .. level .. ", XP " .. xp .. "/" .. xpToLevel .. ", Leveled up: " .. tostring(leveledUp))
    local oldLevel = jobLevel[job]
    local oldXP = jobXP[job]

    jobXP[job] = xp
    jobLevel[job] = level
    jobXPToLevel[job] = xpToLevel

    local xpGained = xp - oldXP + (leveledUp and jobXPToLevel[job] or 0)

    if leveledUp then
        DebugPrint("LEVEL UP: " .. job .. " Level " .. oldLevel .. " -> " .. level)
        TriggerEvent("chat:addMessage", {
            color = {0, 255, 0},
            multiline = true,
            args = {"XP System", "🎉 LEVEL UP! " .. string.upper(job:gsub("_", " ")) .. " is now Level " .. level}
        })
    else
        DebugPrint("XP GAIN: +" .. xpGained .. " XP for " .. job)
        TriggerEvent("chat:addMessage", {
            color = {0, 150, 255},
            multiline = false,
            args = {"XP System", "+" .. xpGained .. " XP | " .. string.upper(job:gsub("_", " ")) .. " Level " .. level .. " (" .. xp .. "/" .. xpToLevel .. ")"}
        })
    end
end)

function AddJobXP(job, amount)
    DebugPrint("AddJobXP called: " .. job .. " +" .. amount)
    if not jobXP[job] then
        DebugPrint("ERROR: Invalid job: " .. tostring(job))
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            args = {"XP System", "Invalid job: " .. tostring(job)}
        })
        return
    end
    DebugPrint("Sending addXP event to server")
    TriggerServerEvent("rinsey-xpsystem:addXP", job, amount)
end

exports('AddJobXP', AddJobXP)
exports('GetJobXP', function(job)
    return jobXP[job] or 0
end)
exports('GetJobLevel', function(job)
    return jobLevel[job] or 1
end)

AddEventHandler('playerSpawned', function()
    DebugPrint("Player spawned, requesting XP data in 2 seconds")
    Wait(2000)
    TriggerServerEvent("rinsey-xpsystem:requestXP")
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DebugPrint("Resource started, requesting XP data in 1 second")
        Wait(1000)
        TriggerServerEvent("rinsey-xpsystem:requestXP")
    end
end)

RegisterCommand("addxp", function()
    local job = "dog_walking"
    local amount = 10 
    AddJobXP(job, amount)
end, false)

