function set_sprite(id,name,frames_x,frames_y,speed,direction,tile_w, tile_h, offset_x, offset_y)
    local sprite = load_resource(name,"sprite")
    local grid = anim8.newGrid(tile_w,tile_h,sprite:getWidth(),sprite:getHeight())
    local anim = anim8.newAnimation(grid(frames_x,frames_y),speed)
    if direction==-1 then
        anim:flipH()
    end
    game.sprites[id] = {anim = anim, sprite = sprite, direction=direction, offset_x=offset_x, offset_y=offset_y, active=true}
    game.direction[id] = direction
end


function add_player(x,y)
    local id = new_entity()
    local w = 15
    local h = 25
    local feet_pos = 5
    local sprite_w = 32
    local sprite_h = 64

    local offset_x = math.floor(0.5*(w-sprite_w))
    local offset_y = math.floor(h-sprite_h + feet_pos)

    set_sprite(id,"player.png",1,1+game.player_count,0.2,1,sprite_w,sprite_h,offset_x, offset_y)
    game.dynamic[id] = true

    game.player_ids[1] = id

    game.players[id] = {
        offset_x = offset_x,
        offset_y = offset_y,
        walking = false,
        jump_cooldown = 0,
    }

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.size[id] = {w=w,h=h}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

function add_coin(x,y)
    local game = game
    local id = new_entity()
    local w = 16
    local h = 16
    local center_x = 0.5
    local center_y = 0.5
    local sprite_w = 16
    local sprite_h = 16
    local feet_pos = 0

    local offset_x = 0.5*(w-sprite_w)
    local offset_y = h-sprite_h + feet_pos

    set_sprite(id,"puhzil_0.png",2,7,0.2,1,sprite_w,sprite_h,offset_x,offset_y)
    game.coins[id] = true

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.size[id] = {w=w,h=h}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

function add_portal(x,y,level)
    local game = game
    local id = new_entity()
    local w = 16
    local h = 16
    local center_x = 0.5
    local center_y = 0.5
    local sprite_w = 16
    local sprite_h = 16
    local feet_pos = 0

    local offset_x = 0.5*(w-sprite_w)
    local offset_y = h-sprite_h + feet_pos

    set_sprite(id,"puhzil_0.png",7,7,0.2,1,sprite_w,sprite_h,offset_x,offset_y)
    --game.dynamic[id] = true
    game.portals[id] = level
    if level == nil then
        print("Warning, no target for the portal!")
    end

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.size[id] = {w=w,h=h}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

function update_player(dt,id)
    local speed = 200.0
    local jump  = 300.0
    local walking = false
    local input = get_input(1)
    local pos = game.pos[id]
    local player = game.players[id]
    local min_input = 0.4
    if input.left > min_input then
        pos.vx = -speed*input.left
        game.direction[id] = -1
        walking = true
    elseif input.right > min_input then
        pos.vx = speed*input.right
        game.direction[id] = 1
        walking = true
    else
        pos.vx = 0
    end

    if input.jump > min_input then
        if(player.jump_cooldown > 0) then 
            game.pos[id].vy = -jump
        end
    end
    player.jump_cooldown = player.jump_cooldown - dt

    if walking ~= player.walking then
        local w = 0.5
        local h = 0.5
        local sprite_w = 32
        local sprite_h = 64
        local offset_x = player.offset_x
        local offset_y = player.offset_y
        if walking == true then
            set_sprite(id,"player_walk.png","1-10",1,0.1,1,sprite_w,sprite_h,offset_x, offset_y)
        else
            set_sprite(id,"player.png",1,1,0.2,game.direction[id],sprite_w,sprite_h,offset_x, offset_y)
        end
        player.walking = walking
    end

end

function add_tile(x,y,w,h)
    local id = new_entity()
    game.tiles[id] = "sand"

    game.pos[id] = {x=x,y=y,vx=0,vy=0}
    game.world:add(id, game.pos[id].x,game.pos[id].y, w, h)
    return id
end

