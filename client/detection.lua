-- SentinelX Anti-Cheat Client-Erkennung

local function HoleEntityGeschwindigkeit()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local fahrzeug = GetVehiclePedIsIn(ped, false)
        return GetEntitySpeed(fahrzeug) * 3.6 -- Umrechnung in km/h
    end
    return GetEntitySpeed(ped) * 3.6
end

-- Geschwindigkeits-Hack Erkennung
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local aktuelleGeschwindigkeit = HoleEntityGeschwindigkeit()
        TriggerServerEvent('sentinelx:checkSpeed', aktuelleGeschwindigkeit)
    end
end)

-- Weapon damage modification detection
-- Note: Client-side weapon damage checks are limited in FiveM
-- Server-side validation is more reliable and should be the primary method
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Check less frequently
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local _, waffe = GetCurrentPedWeapon(ped, true)
            if waffe and waffe ~= 0 then
                -- Check if weapon damage modifier exists and is accessible
                -- This is a basic check - server-side validation is more reliable
                local success, damageModifier = pcall(function()
                    -- Try to get weapon damage modifier if available
                    if GetWeaponDamageModifier then
                        return GetWeaponDamageModifier(waffe)
                    end
                    return nil
                end)
                
                if success and damageModifier and damageModifier > SentinelX.Config.Schwellenwerte.MaxWaffenSchadenMultiplikator then
                    TriggerServerEvent('sentinelx:waffenModifikation', waffe, damageModifier)
                end
            end
        end
    end
end)

-- Memory integrity checks
local function FuehreSpeicherpruefungDurch()
    -- Basic memory modification detection
    local ped = PlayerPedId()
    local playerId = PlayerId()
    
    -- Check if player ped exists and is valid
    if not DoesEntityExist(ped) or ped == 0 then
        TriggerServerEvent('sentinelx:integritaetsFehler', 'ped_invalid')
        return
    end
    
    -- Check if player ID is valid
    if playerId < 0 or playerId > 32 then
        TriggerServerEvent('sentinelx:integritaetsFehler', 'player_id_invalid')
        return
    end
    
    -- Additional integrity checks can be added here
end

-- Ressourcen-Validierung
AddEventHandler('onResourceStart', function(ressourcenName)
    local ressourcenHash = GetResourceKvpString('ressourcen_hash_' .. ressourcenName)
    if ressourcenHash then
        -- Validiere Ressourcen-Hash
        local aktuellerHash = GetResourceMetadata(ressourcenName, 'hash', 0)
        if ressourcenHash ~= aktuellerHash then
            TriggerServerEvent('sentinelx:ressourceModifiziert', ressourcenName)
        end
    end
end)

-- Protected native function monitoring
-- Note: Direct hooking of FiveM natives is not possible via _G
-- This is a monitoring approach that tracks suspicious patterns
local lastEntityCoords = {}
local lastEntityVelocity = {}

-- Monitor SET_ENTITY_COORDS usage patterns
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local currentCoords = GetEntityCoords(ped)
            local lastCoords = lastEntityCoords[ped]
            
            if lastCoords then
                local distance = #(currentCoords - lastCoords)
                -- Detect suspicious teleportation (handled by advanced_detection.lua)
                -- This is just a basic check
            end
            
            lastEntityCoords[ped] = currentCoords
        end
    end
end)

-- Note: Actual native function protection requires server-side validation
-- Client-side native hooking is not reliable in FiveM

-- Event-Handler für Benachrichtigungen vom Server
RegisterNetEvent('sentinelx:benachrichtigung')
AddEventHandler('sentinelx:benachrichtigung', function(nachricht)
    -- Implementieren Sie hier Ihr Benachrichtigungssystem
    SetNotificationTextEntry('STRING')
    AddTextComponentString(nachricht)
    DrawNotification(false, false)
end)

-- Initialisiere Anti-Cheat auf Client
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Führe Überprüfungen alle 5 Sekunden durch
        FuehreSpeicherpruefungDurch()
        -- Fügen Sie hier weitere periodische Überprüfungen hinzu
    end
end)
