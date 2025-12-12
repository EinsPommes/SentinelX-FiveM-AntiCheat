-- SentinelX Anti-Cheat Main Server File

-- Player tracking table
local PlayerStates = {}

-- Helper function to check if player is admin/whitelisted
local function IstSpielerWhitelisted(spielerId)
    if not SentinelX.Config.Whitelist.AdminRollen then
        return false
    end
    
    -- Check if player has admin role (implement based on your admin system)
    -- Example: if using ESX or similar framework
    -- local xPlayer = ESX.GetPlayerFromId(spielerId)
    -- if xPlayer and xPlayer.getGroup() then
    --     for _, role in ipairs(SentinelX.Config.Whitelist.AdminRollen) do
    --         if xPlayer.getGroup() == role then
    --             return true
    --         end
    --     end
    -- end
    
    return false
end

-- Helper function to check if teleport is in whitelisted zone
local function IstTeleportErlaubt(position)
    if not SentinelX.Config.Whitelist.TeleportZonen then
        return false
    end
    
    for _, zone in ipairs(SentinelX.Config.Whitelist.TeleportZonen) do
        local distance = #(position - vector3(zone.x, zone.y, zone.z))
        if distance <= zone.radius then
            return true
        end
    end
    
    return false
end

-- Initialize player tracking
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    
    -- Initial checks (e.g., check banned players from database)
    Wait(0)
    
    -- Check player history from database
    if database and database.PruefeSpielerverlauf then
        database.PruefeSpielerverlauf(source)
    end
    
    -- Initialize player state
    PlayerStates[source] = {
        warnungen = 0,
        verstoesse = {},
        letzteGeschwindigkeit = 0,
        letztePosition = vector3(0, 0, 0),
        letzteGesundheit = 100,
        fehlgeschlagenePruefungen = 0,
        letzteTeleportZeit = 0
    }
    
    deferrals.done()
end)

-- Cleanup when player disconnects
AddEventHandler('playerDropped', function()
    local source = source
    if PlayerStates[source] then
        PlayerStates[source] = nil
    end
end)

-- Speed hack detection
RegisterNetEvent('sentinelx:checkSpeed')
AddEventHandler('sentinelx:checkSpeed', function(aktuelleGeschwindigkeit)
    local source = source
    if not PlayerStates[source] then return end
    
    -- Skip check for whitelisted players
    if IstSpielerWhitelisted(source) then return end
    
    if aktuelleGeschwindigkeit > SentinelX.Config.Schwellenwerte.MaxGeschwindigkeit then
        BehandleVerstoss(source, 'speedhack', {geschwindigkeit = aktuelleGeschwindigkeit})
    end
    
    PlayerStates[source].letzteGeschwindigkeit = aktuelleGeschwindigkeit
end)

-- Handle anti-cheat violations
function BehandleVerstoss(spielerId, verstossTyp, daten)
    if not PlayerStates[spielerId] then return end
    
    -- Skip for whitelisted players
    if IstSpielerWhitelisted(spielerId) then return end
    
    -- Add violation to history
    table.insert(PlayerStates[spielerId].verstoesse, {
        typ = verstossTyp,
        zeit = os.time(),
        daten = daten
    })
    
    PlayerStates[spielerId].warnungen = PlayerStates[spielerId].warnungen + 1
    
    -- Request screenshot if enabled
    if SentinelX.Config.Screenshot.Aktiviert and SentinelX.Config.Screenshot.AutomatischBeiVerstoß then
        TriggerClientEvent('sentinelx:requestScreenshot', spielerId)
    end
    
    -- Determine punishment based on violation count and type
    local strafe = BestimmeStrafe(spielerId, verstossTyp)
    
    if strafe == "bann" then
        local dauer = SentinelX.Config.Bestrafungen.BannDauer
        BanneSpieler(spielerId, dauer, "Cheat-Erkennung: " .. verstossTyp)
    elseif strafe == "kick" then
        KickSpieler(spielerId, SentinelX.Config.Bestrafungen.KickNachricht)
    elseif strafe == "warnung" then
        TriggerClientEvent('sentinelx:benachrichtigung', spielerId, SentinelX.Config.Bestrafungen.WarnungsNachricht)
    end
    
    -- Log violation
    ProtokolliereVerstoss(spielerId, verstossTyp, daten)
    
    -- Send Discord notification
    if database and database.SendeDiscordBenachrichtigung then
        database.SendeDiscordBenachrichtigung(spielerId, verstossTyp, daten)
    end
end

-- Determine punishment based on violation count and type
function BestimmeStrafe(spielerId, verstossTyp)
    local zustand = PlayerStates[spielerId]
    if not zustand then return "warnung" end
    
    -- Check specific cheat punishment
    if SentinelX.Config.Bestrafungen.CheatStrafen[verstossTyp] then
        return SentinelX.Config.Bestrafungen.CheatStrafen[verstossTyp]
    end
    
    -- Use staged system
    if SentinelX.Config.Bestrafungen.StufenSystem then
        for _, stufe in ipairs(SentinelX.Config.Bestrafungen.StufenSystem) do
            if zustand.warnungen >= stufe.Verstöße then
                return stufe.Aktion
            end
        end
    end
    
    -- Default: warning
    return "warnung"
end

-- Ban player function
function BanneSpieler(spielerId, dauer, grund)
    local identifier = GetPlayerIdentifiers(spielerId)[1]
    local spielerName = GetPlayerName(spielerId)
    
    -- Save to database if available
    if database and database.SpeichereVerstoss then
        database.SpeichereVerstoss(spielerId, 'bann', {grund = grund, dauer = dauer}, nil)
    end
    
    -- Log ban action
    if SentinelX.Config.DebugModus then
        print(string.format('[SentinelX] BAN - Spieler: %s (%s), Grund: %s, Dauer: %d Stunden', 
            spielerName, identifier, grund, dauer))
    end
    
    -- Drop player with ban message
    DropPlayer(spielerId, SentinelX.Config.Bestrafungen.BannNachricht)
end

-- Kick player function
function KickSpieler(spielerId, nachricht)
    local spielerName = GetPlayerName(spielerId)
    
    if SentinelX.Config.DebugModus then
        print(string.format('[SentinelX] KICK - Spieler: %s', spielerName))
    end
    
    DropPlayer(spielerId, nachricht)
end

-- Log violations for analysis
function ProtokolliereVerstoss(spielerId, verstossTyp, daten)
    if SentinelX.Config.DebugModus then
        print(string.format('[SentinelX] Verstoß erkannt - Spieler: %s, Typ: %s, Details: %s', 
            GetPlayerName(spielerId), verstossTyp, json.encode(daten)))
    end
    
    -- Save to database if available
    if database and database.SpeichereVerstoss then
        database.SpeichereVerstoss(spielerId, verstossTyp, daten, nil)
    end
end

-- Cheat detection event handlers
RegisterNetEvent('sentinelx:cheatDetected')
AddEventHandler('sentinelx:cheatDetected', function(cheatTyp)
    local source = source
    if not PlayerStates[source] then return end
    
    if IstSpielerWhitelisted(source) then return end
    
    BehandleVerstoss(source, cheatTyp, {})
end)

-- Weapon modification detection
RegisterNetEvent('sentinelx:waffenModifikation')
AddEventHandler('sentinelx:waffenModifikation', function(waffe, schaden)
    local source = source
    if not PlayerStates[source] then return end
    
    if IstSpielerWhitelisted(source) then return end
    
    BehandleVerstoss(source, 'waffen_modifikation', {waffe = waffe, schaden = schaden})
end)

-- Integrity error detection
RegisterNetEvent('sentinelx:integritaetsFehler')
AddEventHandler('sentinelx:integritaetsFehler', function(fehlerTyp)
    local source = source
    if not PlayerStates[source] then return end
    
    if IstSpielerWhitelisted(source) then return end
    
    BehandleVerstoss(source, 'integritaets_fehler', {typ = fehlerTyp})
end)

-- Resource modification detection
RegisterNetEvent('sentinelx:ressourceModifiziert')
AddEventHandler('sentinelx:ressourceModifiziert', function(ressourcenName)
    local source = source
    
    -- Check if resource is whitelisted
    local istWhitelisted = false
    for _, whitelistedRessource in ipairs(SentinelX.Config.Whitelist.Ressourcen) do
        if ressourcenName == whitelistedRessource then
            istWhitelisted = true
            break
        end
    end
    
    if not istWhitelisted and PlayerStates[source] then
        BehandleVerstoss(source, 'ressource_modifiziert', {ressource = ressourcenName})
    end
end)

-- Unauthorized native function call
RegisterNetEvent('sentinelx:unerlaubterNative')
AddEventHandler('sentinelx:unerlaubterNative', function(native)
    local source = source
    if not PlayerStates[source] then return end
    
    if IstSpielerWhitelisted(source) then return end
    
    BehandleVerstoss(source, 'unerlaubter_native', {native = native})
end)

-- Screenshot submission
RegisterNetEvent('sentinelx:submitScreenshot')
AddEventHandler('sentinelx:submitScreenshot', function(screenshotData)
    local source = source
    if not PlayerStates[source] then return end
    
    -- Process screenshot (upload to URL if configured)
    local screenshotUrl = nil
    if SentinelX.Config.Screenshot.UploadURL and SentinelX.Config.Screenshot.UploadURL ~= "" then
        -- Implement screenshot upload logic here
        -- screenshotUrl = UploadScreenshot(screenshotData)
    end
    
    -- Save screenshot URL with last violation
    local zustand = PlayerStates[source]
    if zustand and #zustand.verstoesse > 0 then
        local letzterVerstoss = zustand.verstoesse[#zustand.verstoesse]
        if database and database.SpeichereVerstoss then
            database.SpeichereVerstoss(source, letzterVerstoss.typ, letzterVerstoss.daten, screenshotUrl)
        end
    end
end)

-- Regular server-side checks
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000) -- Check every 2 seconds
        
        -- Perform periodic checks for all players
        for spielerId, zustand in pairs(PlayerStates) do
            if GetPlayerPed(spielerId) then
                local ped = GetPlayerPed(spielerId)
                
                -- Check player health
                local gesundheit = GetEntityHealth(ped)
                if gesundheit > SentinelX.Config.Schwellenwerte.MaxGesundheit then
                    if not IstSpielerWhitelisted(spielerId) then
                        BehandleVerstoss(spielerId, 'godmode', {gesundheit = gesundheit})
                    end
                end
                
                -- Check player armor
                local ruestung = GetPedArmour(ped)
                if ruestung > SentinelX.Config.Schwellenwerte.MaxRuestung then
                    if not IstSpielerWhitelisted(spielerId) then
                        BehandleVerstoss(spielerId, 'ruestung_hack', {ruestung = ruestung})
                    end
                end
                
                -- Update last known position
                local position = GetEntityCoords(ped)
                zustand.letztePosition = position
                zustand.letzteGesundheit = gesundheit
            end
        end
    end
end)
