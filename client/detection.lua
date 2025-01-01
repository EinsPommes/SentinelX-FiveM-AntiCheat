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

-- Waffen-Modifikations-Erkennung
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local _, waffe = GetCurrentPedWeapon(ped, true)
        if waffe then
            local schaden = GetWeaponDamage(waffe)
            -- Überprüfe auf modifizierten Waffenschaden
            if schaden > GetWeaponDamageModifier(waffe) then
                TriggerServerEvent('sentinelx:waffenModifikation', waffe, schaden)
            end
        end
    end
end)

-- Speicher-Integritätsprüfungen
local function FuehreSpeicherpruefungDurch()
    -- Grundlegende Speichermodifikationserkennung
    if not IsPlayerValid(PlayerId()) then
        TriggerServerEvent('sentinelx:integritaetsFehler', 'speicher_modifikation')
    end
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

-- Native Funktionsschutz
local geschuetzte_natives = {
    'SET_ENTITY_COORDS',
    'SET_ENTITY_VELOCITY',
    'SET_PED_INTO_VEHICLE'
}

for _, native in ipairs(geschuetzte_natives) do
    local original = _G[native]
    _G[native] = function(...)
        local stack = debug.traceback()
        -- Überprüfe ob der Aufruf legitim ist
        if not IstAufrufErlaubt(stack) then
            TriggerServerEvent('sentinelx:unerlaubterNative', native)
            return
        end
        return original(...)
    end
end

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
