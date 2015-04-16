function sign(x)
  return (x<0 and -1) or 1
end

function get_tile_and_tileset(x,y,layer)
    x = math.floor(x)
    y = math.floor(y)
    local tile = layer.data[x+(y-1)*layer.width]
    if tile ~= nil then
        tile = tile - 1
        local tileset = nil
        for _,ts in pairs(game.map.tilesets) do
            if(tile < ts.lastgid) then
                tileset = ts
                break
            end
        end
        if(tileset ~= nil) then
            return tile,tileset
        end
    else
        return nil, nil
    end
end

function set_tile(x,y,layer,tile)
    x = math.floor(x)
    y = math.floor(y)
    layer.data[x+(y-1)*layer.width] = tile+1
end

function to_tile_coord(x,y,truncate)
    if truncate == nil then truncate = true end
    local ret_x = x/game.map.tilewidth
    local ret_y = y/game.map.tileheight
    if truncate then
        return math.floor(ret_x),math.floor(ret_y)
    else
        return ret_x,ret_y
    end
end

function to_canvas_coord(x,y)
    local ret_x = x*game.tile_size.w
    local ret_y = y*game.tile_size.h
    return ret_x,ret_y
end

function play_sound(name)
    local s = load_resource(name..".wav","sfx")
    -- randomize pitch
    s:setPitch(1 - 0.5*(math.random()-0.5)) 
    love.audio.play(s)
end

function get_input(id)
    local keys = game.keys[id]
    ret = {}
    for name,key in pairs(keys) do
        if name ~= 'controller' then
            if keys.controller == 'keyboard' then
                if love.keyboard.isDown(key) then
                    ret[name] = 1
                else
                    ret[name] = 0
                end
            else
                local joystick = keys.controller
                if key.axis then
                    local val = joystick:getAxis(key.axis)
                    ret[name] = math.max(0,val*key.dir)
                else
                    if joystick:isDown(key.button) then
                        ret[name] = 1
                    else
                        ret[name] = 0
                    end
                end
            end
        end
    end
    return ret
end
