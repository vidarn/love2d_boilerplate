function handle_collision(id, other, cols)
    if game.players[id] then
        if game.coins[other] then
            kill_entity(other)
            play_sound('coin')
        end
        if game.portals[other] then
            game.level = game.portals[other]
            play_sound('portal')
        end
    end
end

function spawn_from_map(map,layername,hide_layer)
    local layer = map.layers[layername]
    if layer then 
        for x = 1, layer.width do
            for y = 1, layer.height do
                local tile = layer.data[x+(y-1)*layer.width] - 1
                if tile ~= nil then
                    local tileset = nil
                    for _,ts in pairs(map.tilesets) do
                        if(tile < ts.lastgid) then
                            tileset = ts
                            break
                        end
                    end
                    if tile > -1 then
                        local properties = tileset.properties[tile]
                        if properties then
                            for key,val in pairs(properties) do
                                if key == "spawn" then
                                    local c_x,c_y = to_canvas_coord(x,y)
                                    if val == "coin" then
                                        add_coin(c_x,c_y)
                                    end
                                    if val == "player" then
                                        add_player(c_x,c_y)
                                    end
                                    if val == "portal" then
                                        level = properties.portal
                                        add_portal(c_x,c_y,level)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if hide_layer then
            layer.visible = false
        end
    else
        print("Error in spawn_from_map: layer\""..layername.."\" does not exist")
    end
end


