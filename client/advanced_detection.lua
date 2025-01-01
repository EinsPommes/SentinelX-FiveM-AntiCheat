-- SentinelX Erweiterte Erkennungsmechanismen

-- Noclip Erkennung
local function PruefeNoclip()
    local ped = PlayerPedId()
    local position = GetEntityCoords(ped)
    local hoehe = position.z
    
    -- Prüfe ob Spieler durch Wände oder Boden geht
    if not IsEntityTouchingGround(ped) and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped) then
        local _, groundZ = GetGroundZFor_3dCoord(position.x, position.y, position.z, false)
        if math.abs(hoehe - groundZ) > 5.0 then
            return true
        end
    end
    return false
end

-- Godmode Erkennung
local function PruefeGodmode()
    local ped = PlayerPedId()
    local startHealth = GetEntityHealth(ped)
    
    -- Versuche Schaden zuzufügen (unsichtbar für den Spieler)
    ApplyDamageToPed(ped, 1, false)
    Wait(50)
    local endHealth = GetEntityHealth(ped)
    
    -- Stelle Gesundheit wieder her
    SetEntityHealth(ped, startHealth)
    
    -- Wenn kein Schaden genommen wurde, könnte Godmode aktiv sein
    return startHealth == endHealth
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
            local rotSpeed = #(endRot - startRot) / 0.05 -- Rotationsgeschwindigkeit
            
            if rotSpeed > 500.0 then -- Zu schnelle Rotation könnte auf Aimbot hinweisen
                return true
            end
        end
    end
    return false
end

-- ESP/Wallhack Erkennung
local function PruefeESP()
    local ped = PlayerPedId()
    local los = HasEntityClearLosToEntity -- Line of Sight
    
    -- Prüfe ob Spieler Entities durch Wände sieht
    local entities = GetGamePool('CPed')
    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) and entity ~= ped then
            if not los(ped, entity, 17) then -- 17 = Includes all objects
                -- Hier könnte man prüfen ob der Spieler trotzdem auf verdeckte Entities reagiert
                local targetRot = GetEntityRotation(ped, 2)
                local entityPos = GetEntityCoords(entity)
                local pedPos = GetEntityCoords(ped)
                local direction = normalize(entityPos - pedPos)
                
                -- Wenn Spieler auf verdeckte Entities zielt, könnte ESP aktiv sein
                if IsPedFacingEntity(ped, entity, 30.0) then
                    return true
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

-- Hauptprüfschleife
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        -- Noclip Erkennung
        if PruefeNoclip() then
            TriggerServerEvent('sentinelx:cheatDetected', 'noclip')
        end
        
        -- Godmode Erkennung
        if PruefeGodmode() then
            TriggerServerEvent('sentinelx:cheatDetected', 'godmode')
        end
        
        -- Aimbot Erkennung
        if PruefeAimbot() then
            TriggerServerEvent('sentinelx:cheatDetected', 'aimbot')
        end
        
        -- ESP/Wallhack Erkennung
        if PruefeESP() then
            TriggerServerEvent('sentinelx:cheatDetected', 'esp')
        end
        
        -- Teleport Erkennung
        if PruefeTeleport() then
            TriggerServerEvent('sentinelx:cheatDetected', 'teleport')
        end
    end
end)

-- Screenshot-System für Beweissicherung
RegisterNetEvent('sentinelx:requestScreenshot')
AddEventHandler('sentinelx:requestScreenshot', function()
    if exports['screenshot-basic'] then
        exports['screenshot-basic']:requestScreenshot(function(data)
            TriggerServerEvent('sentinelx:submitScreenshot', data)
        end)
    end
end)
