-- SentinelX Anti-Cheat Gemeinsame Konfiguration

SentinelX = {}
SentinelX.Config = {
    -- Allgemeine Einstellungen
    DebugModus = false,
    LogLevel = 3, -- 1: Fehler, 2: Warnung, 3: Info, 4: Debug
    
    -- Erkennungsschwellen
    Schwellenwerte = {
        MaxGeschwindigkeit = 150.0, -- km/h
        MaxGesundheit = 200.0,
        MaxRuestung = 100.0,
        MaxWaffenSchadenMultiplikator = 1.0,
        TeleportDistanz = 100.0, -- Maximal erlaubte sofortige Positionsänderung
        MaxWarnungen = 3
    },
    
    -- Whitelist-Konfiguration
    Whitelist = {
        Ressourcen = {
            "es_extended",
            "esx_basicneeds",
            -- Fügen Sie hier weitere erlaubte Ressourcen hinzu
        },
        Befehle = {
            "car",
            "dv",
            -- Fügen Sie hier weitere erlaubte Admin-Befehle hinzu
        }
    },
    
    -- Bestrafungseinstellungen
    Bestrafungen = {
        BannDauer = 72, -- Stunden
        KickNachricht = "SentinelX: Cheat-Erkennung ausgelöst.",
        BannNachricht = "Sie wurden wegen Cheatens gebannt. Einspruch auf unserem Discord.",
        WarnungsNachricht = "⚠️ WARNUNG: Verdächtige Aktivität erkannt!"
    }
}
