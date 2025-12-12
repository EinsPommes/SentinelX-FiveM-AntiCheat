-- SentinelX Database Integration

-- Database module export
database = {}

-- Check if MySQL is available
local function IstMySQLVerfuegbar()
    return MySQL ~= nil and MySQL.Async ~= nil
end

-- Initialize database
local function InitialisiereDB()
    if not IstMySQLVerfuegbar() then
        print('[SentinelX] WARNUNG: MySQL ist nicht verfügbar. Datenbank-Funktionen sind deaktiviert.')
        return false
    end
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS anticheat_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            spieler_id VARCHAR(50),
            spieler_name VARCHAR(255),
            verstoss_typ VARCHAR(50),
            details TEXT,
            screenshot_url TEXT,
            zeitstempel TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_spieler_id (spieler_id),
            INDEX idx_zeitstempel (zeitstempel)
        )
    ]], {}, function(success)
        if success then
            print('[SentinelX] Datenbank erfolgreich initialisiert')
        else
            print('[SentinelX] FEHLER: Datenbank-Initialisierung fehlgeschlagen')
        end
    end)
    
    return true
end

-- Save violation to database
function database.SpeichereVerstoss(spielerId, verstossTyp, details, screenshotUrl)
    if not IstMySQLVerfuegbar() then
        if SentinelX.Config.DebugModus then
            print('[SentinelX] Datenbank nicht verfügbar - Verstoß nicht gespeichert')
        end
        return
    end
    
    if not spielerId or not GetPlayerName(spielerId) then
        return
    end
    
    local spielerName = GetPlayerName(spielerId)
    local identifiers = GetPlayerIdentifiers(spielerId)
    local identifier = identifiers and identifiers[1] or "unknown"
    
    local detailsJson = "{}"
    if details then
        local success, encoded = pcall(json.encode, details)
        if success then
            detailsJson = encoded
        end
    end
    
    MySQL.Async.execute([[
        INSERT INTO anticheat_logs 
        (spieler_id, spieler_name, verstoss_typ, details, screenshot_url)
        VALUES (@spielerId, @spielerName, @verstossTyp, @details, @screenshotUrl)
    ]], {
        ['@spielerId'] = identifier,
        ['@spielerName'] = spielerName,
        ['@verstossTyp'] = verstossTyp or "unknown",
        ['@details'] = detailsJson,
        ['@screenshotUrl'] = screenshotUrl or ""
    }, function(affectedRows)
        if SentinelX.Config.DebugModus then
            print(string.format('[SentinelX] Verstoß gespeichert: %s - %s', spielerName, verstossTyp))
        end
    end)
end

-- Check player history
function database.PruefeSpielerverlauf(spielerId)
    if not IstMySQLVerfuegbar() then
        return
    end
    
    if not spielerId or not GetPlayerName(spielerId) then
        return
    end
    
    local identifiers = GetPlayerIdentifiers(spielerId)
    local identifier = identifiers and identifiers[1] or nil
    
    if not identifier then
        return
    end
    
    MySQL.Async.fetchAll([[
        SELECT COUNT(*) as verstoss_anzahl 
        FROM anticheat_logs 
        WHERE spieler_id = @spielerId 
        AND zeitstempel > DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]], {
        ['@spielerId'] = identifier
    }, function(results)
        if results and results[1] and results[1].verstoss_anzahl then
            if results[1].verstoss_anzahl >= SentinelX.Config.Schwellenwerte.MaxWarnungen then
                -- Automatic ban for too many violations
                if BanneSpieler then
                    BanneSpieler(spielerId, SentinelX.Config.Bestrafungen.BannDauer, 
                        "Zu viele Cheat-Verstöße in 24 Stunden")
                end
            end
        end
    end)
end

-- Discord Webhook Integration
function database.SendeDiscordBenachrichtigung(spielerId, verstossTyp, details)
    if not SentinelX.Config.DiscordWebhook or SentinelX.Config.DiscordWebhook == "" then
        return
    end
    
    if not spielerId or not GetPlayerName(spielerId) then
        return
    end
    
    local spielerName = GetPlayerName(spielerId)
    local identifiers = GetPlayerIdentifiers(spielerId)
    local identifier = identifiers and identifiers[1] or "unknown"
    
    local detailsText = "Keine Details"
    if details then
        local success, encoded = pcall(json.encode, details)
        if success then
            detailsText = encoded
        else
            detailsText = tostring(details)
        end
    end
    
    local embed = {
        {
            ["title"] = "⚠️ Cheat-Erkennung",
            ["description"] = string.format(
                "**Spieler:** %s\n**ID:** %s\n**Verstoß:** %s\n**Details:** %s",
                spielerName, identifier, verstossTyp, detailsText
            ),
            ["color"] = 16711680, -- Red
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["footer"] = {
                ["text"] = "SentinelX Anti-Cheat"
            }
        }
    }
    
    PerformHttpRequest(SentinelX.Config.DiscordWebhook, function(err, text, headers)
        if err ~= 200 and SentinelX.Config.DebugModus then
            print(string.format('[SentinelX] Discord Webhook Fehler: %d', err))
        end
    end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Initialization
Citizen.CreateThread(function()
    -- Wait for resources to be ready
    Wait(2000)
    
    -- Check if MySQL is available
    if IstMySQLVerfuegbar() then
        InitialisiereDB()
    else
        print('[SentinelX] MySQL nicht verfügbar - Datenbank-Funktionen deaktiviert')
        print('[SentinelX] Installiere mysql-async oder oxmysql für Datenbank-Support')
    end
end)
