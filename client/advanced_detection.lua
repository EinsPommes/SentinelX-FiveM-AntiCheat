-- SentinelX Erweiterte Erkennungsmechanismen

-- Utility function: Normalize vector
local function normalize(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    if length > 0 then
        return vector3(vec.x / length, vec.y / length, vec.z / length)
    end
    return vector3(0, 0, 0)
end

-- Noclip Erkennung
local function PruefeNoclip()
    local ped = PlayerPedId()
    local position = GetEntityCoords(ped)
    local hoehe = position.z
    
    -- Check if player is going through walls or ground
    if not IsEntityTouchingGround(ped) and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped) and not IsPedInAnyVehicle(ped, false) then
        local _, groundZ = GetGroundZFor_3dCoord(position.x, position.y, position.z, false)
        if math.abs(hoehe - groundZ) > SentinelX.Config.Schwellenwerte.NoclipHoehenDifferenz then
            return true
        end
    end
    return false
end

-- Godmode Erkennung
-- Improved: Server-side validation is more reliable
-- This client-side check is limited and should be used carefully
local godmodeCheckCooldown = 0
local function PruefeGodmode()
    local currentTime = GetGameTimer()
    
    -- Only check periodically to avoid false positives
    if currentTime < godmodeCheckCooldown then
        return false
    end
    
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return false
    end
    
    local startHealth = GetEntityHealth(ped)
    local startArmor = GetPedArmour(ped)
    
    -- Check if health exceeds maximum allowed
    if startHealth > SentinelX.Config.Schwellenwerte.MaxGesundheit then
        return true
    end
    
    -- Check if armor exceeds maximum allowed
    if startArmor > SentinelX.Config.Schwellenwerte.MaxRuestung then
        return true
    end
    
    -- Note: Direct damage testing is unreliable and can cause false positives
    -- Server-side validation should handle actual godmode detection
    godmodeCheckCooldown = currentTime + SentinelX.Config.Schwellenwerte.GodmodeTestInterval
    
    return false
end

-- Aimbot Erkennung
local function PruefeAimbot()
    local ped = PlayerPedId()
    if IsPedShooting(ped) then
        local _, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if DoesEntityExist(targetPed) and IsEntityAPed(targetPed) then
            -- Prüfe Präzision und Geschwindigkeit des Zielens
            local startTime = GetGameTimer()
            local startRot = GetGameplayCamRot(2)
            Wait(50)
            local endRot = GetGameplayCamRot(2)
            local rotSpeed = #(endRot - startRot) / 0.05 -- Rotation speed
            
            if rotSpeed > SentinelX.Config.Schwellenwerte.AimbotRotationsGeschwindigkeit then
                return true
            end
        end
    end
    return false
end

-- ESP/Wallhack Erkennung
local function PruefeESP()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return false
    end
    
    -- Check if player is aiming at entities through walls
    local pedPos = GetEntityCoords(ped)
    local nearbyPeds = {}
    
    -- Get nearby peds (more efficient than GetGamePool)
    local handle, entity = FindFirstPed()
    if handle ~= -1 then
        repeat
            if DoesEntityExist(entity) and entity ~= ped and IsPedAPlayer(entity) == false then
                local entityPos = GetEntityCoords(entity)
                local distance = #(pedPos - entityPos)
                
                -- Only check nearby entities (within reasonable range)
                if distance < 50.0 then
                    table.insert(nearbyPeds, entity)
                end
            end
            handle, entity = FindNextPed(handle)
        until not handle
        EndFindPed(handle)
    end
    
    -- Check if player is facing entities without line of sight
    for _, entity in ipairs(nearbyPeds) do
        if DoesEntityExist(entity) then
            if not HasEntityClearLosToEntity(ped, entity, 17) then -- 17 = Includes all objects
                -- Check if player is facing the hidden entity
                if IsPedFacingEntity(ped, entity, SentinelX.Config.Schwellenwerte.ESPWinkel) then
                    -- Additional check: is player aiming at this entity?
                    if IsPedShooting(ped) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Teleport Erkennung
local lastPosition = vector3(0, 0, 0)
local function PruefeTeleport()
    local ped = PlayerPedId()
    local currentPos = GetEntityCoords(ped)
    
    if #(currentPos - lastPosition) > SentinelX.Config.Schwellenwerte.TeleportDistanz then
        -- Prüfe ob legitimer Teleport (z.B. durch Server-Event)
        if not IsPedInAnyVehicle(ped, false) and not IsPlayerSwitchInProgress() then
            return true
        end
    end
    
    lastPosition = currentPos
    return false
end

-- Main detection loop with separate threads for each check type
-- Noclip detection thread
if SentinelX.Config.ErweitertePruefungen.NoclipErkennung then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(SentinelX.Config.ErweitertePruefungen.NoclipInterval)
            if PruefeNoclip() then
                TriggerServerEvent('sentinelx:cheatDetected', 'noclip')
            end
        end
    end)
end

-- Godmode detection thread
if SentinelX.Config.ErweitertePruefungen.GodmodeErkennung then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(SentinelX.Config.ErweitertePruefungen.GodmodeInterval)
            if PruefeGodmode() then
                TriggerServerEvent('sentinelx:cheatDetected', 'godmode')
            end
        end
    end)
end

-- Aimbot detection thread
if SentinelX.Config.ErweitertePruefungen.AimbotErkennung then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(SentinelX.Config.ErweitertePruefungen.AimbotInterval)
            if PruefeAimbot() then
                TriggerServerEvent('sentinelx:cheatDetected', 'aimbot')
            end
        end
    end)
end

-- ESP/Wallhack detection thread
if SentinelX.Config.ErweitertePruefungen.ESPErkennung then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(SentinelX.Config.ErweitertePruefungen.ESPInterval)
            if PruefeESP() then
                TriggerServerEvent('sentinelx:cheatDetected', 'esp')
            end
        end
    end)
end

-- Teleport detection thread
if SentinelX.Config.ErweitertePruefungen.TeleportErkennung then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(SentinelX.Config.ErweitertePruefungen.TeleportInterval)
            if PruefeTeleport() then
                TriggerServerEvent('sentinelx:cheatDetected', 'teleport')
            end
        end
    end)
end

-- Screenshot-System für Beweissicherung
RegisterNetEvent('sentinelx:requestScreenshot')
AddEventHandler('sentinelx:requestScreenshot', function()
    if exports['screenshot-basic'] then
        exports['screenshot-basic']:requestScreenshot(function(data)
            TriggerServerEvent('sentinelx:submitScreenshot', data)
        end)
    end
end)
