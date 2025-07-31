local jobs = {"pizza_delivery", "gardening", "coding", "dog_walking"}
local baseXPRequired = 100
local xpMultiplier = 1.25

local function DebugPrint(message)
    print("^2[XP SERVER DEBUG]^7 " .. message)
end

RegisterNetEvent("rinsey-xpsystem:requestXP", function()
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local identifier = identifiers[1] or ""
    DebugPrint("Player " .. src .. " requesting XP data. Identifier: " .. identifier)
    if identifier == "" then return end

    MySQL.Async.fetchAll("SELECT * FROM player_xp WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(result)
        local playerData = {}
        for _, row in ipairs(result) do
            playerData[row.job] = {
                xp = row.xp,
                level = row.level,
                xpToLevel = row.xpToLevel
            }
        end
        for _, job in ipairs(jobs) do
            if not playerData[job] then
                playerData[job] = { xp = 0, level = 1, xpToLevel = baseXPRequired }
                MySQL.Async.execute("INSERT INTO player_xp (identifier, job, xp, level, xpToLevel) VALUES (@identifier, @job, 0, 1, @xpToLevel)", {
                    ['@identifier'] = identifier,
                    ['@job'] = job,
                    ['@xpToLevel'] = baseXPRequired
                })
            end
        end
        TriggerClientEvent("rinsey-xpsystem:loadXP", src, playerData)
    end)
end)

RegisterNetEvent("rinsey-xpsystem:saveXP", function(job, xp, level, xpToLevel)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local identifier = identifiers[1] or ""
    if identifier == "" then return end

    MySQL.Async.fetchScalar("SELECT identifier FROM player_xp WHERE identifier = @identifier AND job = @job", {
        ['@identifier'] = identifier,
        ['@job'] = job
    }, function(exists)
        if exists then
            MySQL.Async.execute("UPDATE player_xp SET xp = @xp, level = @level, xpToLevel = @xpToLevel WHERE identifier = @identifier AND job = @job", {
                ['@identifier'] = identifier,
                ['@job'] = job,
                ['@xp'] = xp,
                ['@level'] = level,
                ['@xpToLevel'] = xpToLevel
            })
        else
            MySQL.Async.execute("INSERT INTO player_xp (identifier, job, xp, level, xpToLevel) VALUES (@identifier, @job, @xp, @level, @xpToLevel)", {
                ['@identifier'] = identifier,
                ['@job'] = job,
                ['@xp'] = xp,
                ['@level'] = level,
                ['@xpToLevel'] = xpToLevel
            })
        end
    end)
end)

RegisterNetEvent("rinsey-xpsystem:addXP", function(job, amount)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local identifier = identifiers[1] or ""
    if identifier == "" then return end

    MySQL.Async.fetchAll("SELECT * FROM player_xp WHERE identifier = @identifier AND job = @job", {
        ['@identifier'] = identifier,
        ['@job'] = job
    }, function(result)
        local data = result[1] or {xp = 0, level = 1, xpToLevel = baseXPRequired}
        local newXP = data.xp + amount
        local newLevel = data.level
        local newXPToLevel = data.xpToLevel
        local leveledUp = false

        while newXP >= newXPToLevel do
            newXP = newXP - newXPToLevel
            newLevel = newLevel + 1
            newXPToLevel = math.floor(baseXPRequired * (xpMultiplier ^ (newLevel - 1)))
            leveledUp = true
        end

        if #result == 0 then
            MySQL.Async.execute("INSERT INTO player_xp (identifier, job, xp, level, xpToLevel) VALUES (@identifier, @job, @xp, @level, @xpToLevel)", {
                ['@identifier'] = identifier,
                ['@job'] = job,
                ['@xp'] = newXP,
                ['@level'] = newLevel,
                ['@xpToLevel'] = newXPToLevel
            })
        else
            MySQL.Async.execute("UPDATE player_xp SET xp = @xp, level = @level, xpToLevel = @xpToLevel WHERE identifier = @identifier AND job = @job", {
                ['@identifier'] = identifier,
                ['@job'] = job,
                ['@xp'] = newXP,
                ['@level'] = newLevel,
                ['@xpToLevel'] = newXPToLevel
            })
        end

        TriggerClientEvent("rinsey-xpsystem:updateXP", src, job, newXP, newLevel, newXPToLevel, leveledUp)
    end)
end)

RegisterCommand("testxp", function(source, args)
    local job = args[1] or "coding"
    local amount = tonumber(args[2]) or 25
    TriggerEvent("rinsey-xpsystem:addXP", job, amount)
end, false)

exports('AddPlayerXP', function(playerId, job, amount)
    TriggerEvent("rinsey-xpsystem:addXP", job, amount)
end)
