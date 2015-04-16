local g_resources = {}

function load_map(name)
    local map = love.filesystem.load(name)()
    for _,tileset in pairs(map.tilesets) do
        tileset.loaded_image = load_resource(tileset.image,"tiles")
        tileset.tiles_x = math.floor(tileset.imagewidth/tileset.tilewidth)
        tileset.tiles_y = math.floor(tileset.imageheight/tileset.tileheight)
        tileset.lastgid = tileset.firstgid + tileset.tiles_x*tileset.tiles_y - 1
        tileset.properties = {}
        for _,tile in pairs(tileset.tiles) do 
            local id = tile.id + tileset.firstgid -1
            local props = tile.properties
            if id ~= nil and props ~= nil then
                tileset.properties[id] = props
            end
        end
    end
    local layers = {}
    for _,layer in pairs(map.layers) do
        layers[layer.name] = layer
    end
    map.layers = layers
    for _,layer in pairs(map.layers) do
        layer.colliders = {}
        layer.sprite_batches = {}
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
                    if(tileset ~= nil) then
                        if layer.sprite_batches[tileset.name] == nil then
                            layer.sprite_batches[tileset.name] = love.graphics.newSpriteBatch(tileset.loaded_image,layer.width*layer.height,"static")
                        end
                        local sprite_batch = layer.sprite_batches[tileset.name]
                        local localgid = tile + 1 - tileset.firstgid
                        local tx = localgid % tileset.tiles_x
                        local ty = math.floor(localgid / tileset.tiles_x)
                        local tw = tileset.tilewidth
                        local th = tileset.tileheight
                        local quad = love.graphics.newQuad(tx*tw, ty*th,tw,th,tileset.imagewidth, tileset.imageheight)
                        sprite_batch:add(quad,x*map.tilewidth,(y+1)*map.tileheight-tileset.tileheight)
                        local properties = tileset.properties[tile]
                        if properties then
                            for key,val in pairs(properties) do
                                if key == "collision" and val == "true" then
                                    table.insert(layer.colliders,{name = "tile", id = tile, x=tw*x, y=th*y, w=tw, h=th})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return map
end

function load_resource(name,resource_type)
    local path,filename,ext = string.match(name, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    local folder = g_resources[resource_type]
    if folder == nil then
        g_resources[resource_type] = {}
        folder = g_resources[resource_type]
    end
    if folder[filename] ~= nil then
        return folder[filename]
    else
        local resource = nil
        if resource_type == "sprite" then
            resource = love.graphics.newImage("data/sprites/"..filename)
        end
        if resource_type == "tiles" then
            resource = love.graphics.newImage("data/tiles/"..filename)
        end
        if resource_type == "font" then
            resource = love.graphics.newImage("data/fonts/"..filename)
        end
        if resource_type == "sfx" then
            resource = love.audio.newSource("data/sfx/"..filename)
            resource:setVolume(0.4)
        end
        if resource_type == "music" then
            resource = love.audio.newSource("data/music/"..filename)
            resource:setLooping(true)
        end
        if resource_type == "map" then
            resource = load_map("data/levels/"..filename)
        end
        if resource == nil then
            print("Error!, could not load file \""..name.."\", did not recognize resource type \""..resource_type.."\"")
        end
        folder[filename] = resource
        return resource
    end
end

