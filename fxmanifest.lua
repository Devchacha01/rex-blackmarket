fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

name 'rex-blackmarket'
author 'RexShack Gaming'
description 'Advanced blackmarket system RSG Framework'
version '2.1.0'
url 'https://discord.gg/YUV7ebzkqs'

-- core dependencies
dependencies {
    'rsg-core',
    'ox_lib',
    'rsg-inventory',
    'oxmysql',
    'rsg-lawman'
}

-- shared scripts (loaded on both client and server)
shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'shared/config.lua'
}

-- client-side scripts
client_scripts {
    'client/client.lua',
    'client/npcs.lua'
}

-- server-side scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/versionchecker.lua'
}

-- UI files
files {
    'locales/*.json'
}

-- lua version
lua54 'yes'
