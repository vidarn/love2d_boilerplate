bump      = require "lib.bump.bump"
anim8     = require "lib.anim8.anim8"
timer     = require "lib.hump.timer"
require "common"
require "entity"
require "game_control"

game = {}

game.camera = {
    x = 14, y=14,
    shake_amplitude = 0.0, shake_frequency = 20., shake_time = 0.0,
    offset_x = 0.0, offset_y = 0.0,
}

game.debug = false
game.player_ids = {}
game.money = 20
game.start_message = 1

game.tile_size = {
    w=16,h=16,
}

game.keys = {
}

game.level = 'test'


game.components = {
    "sprites",
    "pos",
    "size",
    "direction",
    "players",
    "dynamic",
    "tiles",
    "coins",
    "portals",
}

game.player_count = 0

function create_component_managers()
    for _,component in pairs(game.components) do
        game[component] = {}
    end
end

function kill_entity(id)
    game.alive[id] = false
    for _,component in pairs(game.components) do
        game[component][id] = nil
    end
end

function new_entity()
    for key,val in pairs(game.alive) do
        if(val == false) then
            game.alive[key] = true
            return key
        end
    end
    table.insert(game.alive,true)
    return table.getn(game.alive)
end

function game:resize(w,h)
    g_screenres = {
        w=math.floor(love.graphics.getWidth()/2),
        h=math.floor(love.graphics.getHeight()/2)
    }
    game.canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    game.tmp_canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    game.canvas:setFilter('nearest','nearest')
end

function game:enter()
    game.keys[1] = g_keys[1]
end

function load_level(name)
    game.alive = {}
    create_component_managers()
    game.world = bump.newWorld(game.tile_size.w)

    game.start_message = 1
    timer.tween(2,game,{start_message =0},'in-expo')

    -- load map
    game.map = load_resource("data/levels/"..name..".lua","map")
    for _,layer in pairs(game.map.layers) do
        for _,col in pairs(layer.colliders) do 
            add_tile(col.x,col.y,col.w,col.h)
        end
    end
    spawn_from_map(game.map,"objects",true)
    game.current_level = name
    game.level = nil

    --prerun_physics(100)
end

function game:init()
    game.canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    game.tmp_canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    game.canvas:setFilter('nearest','nearest')
    game.bkg = load_resource('clouds.png','sprite')
    game.bkg_offset = 0
end

function game:keyreleased(key, code)
    if key == 'f1' then
        game.debug = not game.debug
    end
end

function prerun_physics(steps)
    game.prerun = true
    local dt = 0.01
    for step = 1,steps do
        for id,val in pairs(game.dynamic) do 
            if game.alive[id] and val==true then
                update_physics(dt,id)
            end
        end
    end
    game.prerun = false
end

function update_physics(dt,id)
    local game = game
    local max_speed = 400.0
    -- Update physics
    local pos = game.pos[id];
    pos.vy = pos.vy + 20
    local sy = sign(pos.vy)
    pos.vy = math.min(math.abs(pos.vy),max_speed)*sy
    local dy = dt*(pos.vy)
    local dx = dt*(pos.vx) 
    local new_x = pos.x + dx
    local new_y = pos.y + dy
    local x = math.floor(pos.x/game.tile_size.w)
    -- collisions
    local colliders = {}

    -- check y
    local collisions, len = game.world:check(id, pos.x, new_y)
    local moved = false -- Make sure we move to the first (closest) intersected tile
    if len >= 1 then
        for _,col in pairs(collisions) do
            local tl, tt, nx, ny = col:getTouch()
            local other = col.other
            if game.tiles[other] then
                if not moved then
                    new_y = tt
                    if game.players[id] then
                        game.pos[id].vy = 0
                        if(dy > 0) then
                            game.players[id].jump_cooldown = 0.3
                        end
                    end
                    moved = true
                end
            end
            if colliders[other] == nil then
                colliders[other] = {}
            end
            table.insert(colliders[other],{col=col, dir='y'})
        end
    end

    -- check x
    collisions, len = game.world:check(id, new_x, new_y)
    moved = false
    if len >= 1 then
        for _,col in pairs(collisions) do
            local tl, tt, nx, ny = col:getTouch()
            local other = col.other
            if game.tiles[other] then
                if not moved then
                    new_x = tl
                    moved = true
                end
            end
            if colliders[other] == nil then
                colliders[other] = {}
            end
            table.insert(colliders[other],{col=col, dir='x'})
        end
    end
    if not game.prerun then
        for other,cols in pairs(colliders) do 
            handle_collision(id,other,cols)
        end
    end
    pos.x = new_x
    pos.y = new_y
    game.world:move(id, new_x, new_y)
end

function game:update(dt)
    local game = game
    if game.level ~= nil then
        load_level(game.level)
    end
    timer.update(dt)
    for id,sprite in pairs(game.sprites) do 
        if game.alive[id] then
            sprite.anim:update(dt)
        end
    end
    for id,val in pairs(game.dynamic) do 
        if game.alive[id] and val==true then
            update_physics(dt,id)
        end
    end
    local player_ids = game.player_ids

    for a,player_id in pairs(player_ids) do
        update_player(dt,player_id)
        -- update camera
    end
    local camera = game.camera
    camera.shake_time = (camera.shake_time + dt*camera.shake_frequency)%1.0
    local player_pos = game.pos[player_ids[1]]
    local tile_size = game.tile_size
    camera.x = math.max(g_screenres.w*0.5+tile_size.w,math.min(game.map.width *tile_size.w-g_screenres.w*0.5+tile_size.w,player_pos.x))
    camera.y = math.min(game.map.height*tile_size.h-g_screenres.h*0.5+tile_size.h,math.max(g_screenres.h*0.5+tile_size.h,player_pos.y))
    game.bkg_offset = game.bkg_offset + dt*4
    while game.bkg_offset > game.bkg:getWidth() do
        game.bkg_offset = game.bkg_offset - game.bkg:getWidth()
    end
end

function game:draw()
    local game = game
    love.graphics.setCanvas(game.canvas)

    love.graphics.setBackgroundColor(99,155,255)
    love.graphics.clear()

    love.graphics.draw(game.bkg, math.floor(game.bkg_offset))
    love.graphics.draw(game.bkg, math.floor(game.bkg_offset-game.bkg:getWidth()))

    love.graphics.push()

    -- Camera shake
    local camera = game.camera
    local offset_x = camera.shake_amplitude*math.sin(camera.shake_time*2*math.pi)
    local offset_y = camera.shake_amplitude*math.sin(camera.shake_time*2*math.pi + 31123.34)
    love.graphics.translate(math.floor(-camera.x + g_screenres.w*0.5 + offset_x), math.floor(-camera.y + g_screenres.h*0.5 + offset_y))

    -- draw map
    for _,layer in pairs(game.map.layers) do
        if layer.name ~= "player" and layer.visible ~= false and not layer.properties.foreground then
            for _,sprite_batch in pairs(layer.sprite_batches) do
                love.graphics.draw(sprite_batch)
            end
        end
    end

    for _,layer in pairs(game.map.layers) do
        if layer.name == "player" and layer.visible ~= false then
            for id,sprite in pairs(game.sprites) do
                if game.alive[id] == true then
                    if game.direction[id] ~= sprite.direction then
                        sprite.direction = game.direction[id]
                        sprite.anim:flipH()
                    end
                    sprite.anim:draw(sprite.sprite,math.floor(game.pos[id].x)+sprite.offset_x,math.floor(game.pos[id].y)+sprite.offset_y)
                    if game.debug then
                        local pos = game.pos[id]
                        local size = game.size[id]
                        if pos and size then
                            local x = math.floor(pos.x)
                            local y = math.floor(pos.y)
                            love.graphics.rectangle('line',x,y,size.w,size.h)
                        end
                    end
                end
            end
        end
    end

    for _,layer in pairs(game.map.layers) do
        if layer.name ~= "player" and layer.visible ~= false and layer.properties.foreground then
            for _,sprite_batch in pairs(layer.sprite_batches) do
                love.graphics.draw(sprite_batch)
            end
        end
    end

    love.graphics.pop()


    love.graphics.setColor(255,255,255)
    local t_w = 300
    love.graphics.setColor(255,255,255,255*game.start_message)
    love.graphics.printf("GO!",(g_screenres.w-t_w)*0.5,g_screenres.h*0.5-80,t_w,'center')


    -- Draw scaled canvas to screen
    love.graphics.setBackgroundColor(99,155,255)
    love.graphics.setColor(255,255,255)
    love.graphics.setCanvas()
    love.graphics.clear()
    local h = love.graphics.getHeight()
    local w = love.graphics.getWidth()
    local s_w = g_screenres.w*2
    local s_h = g_screenres.h*2
    local quad = love.graphics.newQuad(0,0,s_w,s_h,s_w,s_h)
    local x = math.floor((w-s_w)*0.5)
    local y = math.floor((h-s_h)*0.5)
    love.graphics.draw(game.canvas, quad, x, y)
end

