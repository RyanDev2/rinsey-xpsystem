fx_version 'cerulean'
game 'gta5'

author 'Rinsey Development'
description 'XP System'
version 'Very Beta Legit Just Started LMAO LMAO'

dependency 'mysql-async'

ui_page 'html/index.html'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua',
}

files {
    'html/index.html',
    'html/style.css', 
    'html/script.js'
}

