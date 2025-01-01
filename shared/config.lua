-- SentinelX Anti-Cheat Gemeinsame Konfiguration

SentinelX = {}
SentinelX.Config = {
    -- Allgemeine Einstellungen
    DebugModus = false,
    LogLevel = 3, -- 1: Fehler, 2: Warnung, 3: Info, 4: Debug
    
    -- Discord Integration
    DiscordWebhook = "", -- Fügen Sie Ihren Discord Webhook hier ein
    
    -- Datenbank Einstellungen
    Database = {
        Host = "localhost",
        User = "root",
        Password = "",
        Database = "fivem_anticheat"
    },
    
    -- Erkennungsschwellen
    Schwellenwerte = {
        MaxGeschwindigkeit = 150.0, -- km/h
        MaxGesundheit = 200.0,
        MaxRuestung = 100.0,
        MaxWaffenSchadenMultiplikator = 1.0,
        TeleportDistanz = 100.0, -- Maximal erlaubte sofortige Positionsänderung
        MaxWarnungen = 3,
        
        -- Neue Schwellenwerte
        AimbotRotationsGeschwindigkeit = 500.0,
        NoclipHoehenDifferenz = 5.0,
        ESPWinkel = 30.0,
        GodmodeTestInterval = 1000, -- ms
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
        },
        -- Neue Whitelist-Kategorien
        TeleportZonen = {
            {x = 100.0, y = 100.0, z = 100.0, radius = 10.0}, -- Beispiel für erlaubte Teleport-Zone
        },
        AdminRollen = {
            "superadmin",
            "admin",
        }
    },
    
    -- Bestrafungseinstellungen
    Bestrafungen = {
        BannDauer = 72, -- Stunden
        KickNachricht = "SentinelX: Cheat-Erkennung ausgelöst.",
        BannNachricht = "Sie wurden wegen Cheatens gebannt. Einspruch auf unserem Discord.",
        WarnungsNachricht = "⚠️ WARNUNG: Verdächtige Aktivität erkannt!",
        
        -- Neue Bestrafungsoptionen
        StufenSystem = {
            {
                Verstöße = 1,
                Aktion = "warnung",
                Dauer = 0
            },
            {
                Verstöße = 2,
                Aktion = "kick",
                Dauer = 0
            },
            {
                Verstöße = 3,
                Aktion = "bann",
                Dauer = 72
            }
        },
        
        -- Spezifische Strafen für verschiedene Cheats
        CheatStrafen = {
            speedhack = "kick",
            aimbot = "bann",
            godmode = "bann",
            noclip = "kick",
            esp = "warnung"
        }
    },
    
    -- Screenshot Einstellungen
    Screenshot = {
        Aktiviert = true,
        Qualität = 80,
        AutomatischBeiVerstoß = true,
        UploadURL = "", -- URL für Screenshot-Upload
    },
    
    -- Erweiterte Erkennungseinstellungen
    ErweitertePruefungen = {
        AimbotErkennung = true,
        GodmodeErkennung = true,
        NoclipErkennung = true,
        ESPErkennung = true,
        TeleportErkennung = true,
        
        -- Prüfungsintervalle (in ms)
        AimbotInterval = 1000,
        GodmodeInterval = 5000,
        NoclipInterval = 1000,
        ESPInterval = 2000,
        TeleportInterval = 1000
    }
}
