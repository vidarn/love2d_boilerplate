gamestate = require "lib.hump.gamestate"
sti       = require "lib.sti"
require "resource_loader"
require "game"
require "menu"

g_screenres = {
    w=math.floor(love.graphics.getWidth()/2),
    h=math.floor(love.graphics.getHeight()/2)
}

g_music = {
    axxo = load_resource("axxo.mp3","music"),
}

g_num_players = 1

g_key_codes = {
    'left',
    'right',
    'jump',
}

g_key_names = {
    left = 'WALK LEFT', 
    right = 'WALK RIGHT', 
    jump = 'JUMP', 
}

g_keys = {
    {
        controller = 'keyboard',
        left = 'left', 
        right = 'right', 
        jump = 'up',
    },
}


g_font = love.graphics.newImageFont(load_resource('8pxfont.png','font'),[[!"#$%&`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'abcdefghijlkmnopqrstuvwxyz{|}~ ]])

function love.load()
    love.window.setTitle("Game")
    love.audio.play(g_music.axxo)
    love.graphics.setFont(g_font)
    gamestate.registerEvents()
    gamestate.switch(menu)
end



