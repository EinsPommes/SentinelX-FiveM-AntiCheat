fx_version 'cerulean'
game 'gta5'

author 'SentinelX'
description 'Fortschrittliches FiveM Anti-Cheat System'
version '1.0.0'

-- Client Skripte
client_scripts {
    'client/*.lua'
}

-- Server Skripte
server_scripts {
    'server/*.lua'
    'server/modules/*.lua'
}

-- Gemeinsam genutzte Skripte
shared_scripts {
    'shared/*.lua'
}
