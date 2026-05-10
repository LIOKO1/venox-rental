fx_version 'cerulean'
game 'gta5'

author 'Venox'
description 'Simple multi-framework vehicle rental script for QB, Qbox, ESX, and standalone servers.'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua'
}
