-- SentinelX Datenbankintegration

local function InitialisiereDB()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS anticheat_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            spieler_id VARCHAR(50),
            spieler_name VARCHAR(255),
            verstoss_typ VARCHAR(50),
            details TEXT,
            screenshot_url TEXT,
            zeitstempel TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {}, function(success)
        if success then
            print('[SentinelX] Datenbank initialisiert')
        end
    end)
end

-- Verstöße in Datenbank speichern
function SpeichereVerstoss(spielerId, verstossTyp, details, screenshotUrl)
    local spielerName = GetPlayerName(spielerId)
    local identifier = GetPlayerIdentifiers(spielerId)[1]
    
    MySQL.Async.execute([[
        INSERT INTO anticheat_logs 
        (spieler_id, spieler_name, verstoss_typ, details, screenshot_url)
        VALUES (@spielerId, @spielerName, @verstossTyp, @details, @screenshotUrl)
    ]], {
        ['@spielerId'] = identifier,
        ['@spielerName'] = spielerName,
        ['@verstossTyp'] = verstossTyp,
        ['@details'] = json.encode(details),
        ['@screenshotUrl'] = screenshotUrl
    })
end

-- Prüfe Spielerhistorie
function PruefeSpielerverlauf(spielerId)
    local identifier = GetPlayerIdentifiers(spielerId)[1]
    
    MySQL.Async.fetchAll([[
        SELECT COUNT(*) as verstoss_anzahl 
        FROM anticheat_logs 
        WHERE spieler_id = @spielerId 
        AND zeitstempel > DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]], {
        ['@spielerId'] = identifier
    }, function(results)
        if results[1].verstoss_anzahl >= SentinelX.Config.Schwellenwerte.MaxWarnungen then
            -- Automatischer Bann bei zu vielen Verstößen
            BanneSpieler(spielerId, SentinelX.Config.Bestrafungen.BannDauer, 
                "Zu viele Cheat-Verstöße in 24 Stunden")
        end
    end)
end

-- Discord Webhook Integration
function SendeDiscordBenachrichtigung(spielerId, verstossTyp, details)
    local spielerName = GetPlayerName(spielerId)
    local identifier = GetPlayerIdentifiers(spielerId)[1]
    
    local embed = {
        {
            ["title"] = "⚠️ Cheat-Erkennung",
            ["description"] = string.format(
                "Spieler: %s\nID: %s\nVerstoß: %s\nDetails: %s",
                spielerName, identifier, verstossTyp, json.encode(details)
            ),
            ["color"] = 16711680, -- Rot
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(SentinelX.Config.DiscordWebhook, function(err, text, headers) end, 
        'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Initialisierung
Citizen.CreateThread(function()
    Wait(1000) -- Warte auf MySQL-Ready
    InitialisiereDB()
end)
