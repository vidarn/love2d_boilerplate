menu = {}

function menu:init()
    menu.active_player = 1
    menu.active_key_num = 1
    menu.active_key = g_key_codes[menu.active_key_num]
    menu.canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    menu.tmp_canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    menu.canvas:setFilter('nearest','nearest')
    -- set zero-state for joystick axes
    menu.joystick_zero = {}
    menu.used_axes = {}
    for _,joystick in pairs(love.joystick.getJoysticks()) do
        local zero_pos = {}
        for axis=1,joystick:getAxisCount() do
            local val = joystick:getAxis(axis)
            zero_pos[axis] = 0
            if val < -0.5 then
                zero_pos[axis] = -1
            end
            if val >  0.5 then
                zero_pos[axis] = 1
            end
            print(zero_pos[axis])
        end
        menu.joystick_zero[joystick:getName()] = zero_pos
        menu.used_axes[joystick:getName()] = {}
    end
end

function menu:joystickadded(joystick)
    local zero_pos = {}
    for axis=1,joystick:getAxisCount() do
        local val = joystick:getAxis(axis)
        zero_pos[axis] = 0
        if val < -0.5 then
            zero_pos[axis] = -1
        end
        if val >  0.5 then
            zero_pos[axis] = 1
        end
        print(zero_pos[axis])
    end
    menu.joystick_zero[joystick:getName()] = zero_pos
    menu.used_axes[joystick:getName()] = {}
end

function menu:update(dt)
    for _,joystick in pairs(love.joystick.getJoysticks()) do
        local name = joystick:getName()
        local zero_pos = menu.joystick_zero[name]
        for axis=1,joystick:getAxisCount() do
            local val = joystick:getAxis(axis) - zero_pos[axis]
            if math.abs(val) > 0.9 then
                local valid = true
                local dir = sign(val)
                for _,used_axis in pairs(menu.used_axes[name]) do
                    if used_axis.axis == axis and used_axis.dir == dir then
                        valid = false
                    end
                end
                if valid then
                    local key = {axis=axis,dir=dir}
                    register_key(key,joystick)
                    table.insert(menu.used_axes[name],key)
                end
            end
        end
    end
end

function menu:resize(w,h)
    g_screenres = {
        w=math.floor(love.graphics.getWidth()/2),
        h=math.floor(love.graphics.getHeight()/2)
    }
    menu.canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    menu.tmp_canvas = love.graphics.newCanvas(g_screenres.w, g_screenres.h)
    menu.canvas:setFilter('nearest','nearest')
end

function menu:draw()
    love.graphics.setCanvas(menu.canvas)

    love.graphics.setBackgroundColor(99,155,255)
    love.graphics.clear()

    love.graphics.setColor(255,255,255)
    local t_w = 300
    love.graphics.printf('PRESS THE BUTTON YOU WISH TO USE TO\n"'..g_key_names[menu.active_key]..'"'
        ,(g_screenres.w-t_w)*0.5,g_screenres.h*0.5-100,t_w,'center')


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
    love.graphics.draw(menu.canvas, quad, x, y)
end

function register_key(key,controller)
    if menu.active_key_num == 1 then
        g_keys[menu.active_player].controller = controller
    end
    if g_keys[menu.active_player].controller == controller then
        play_sound('blip')
        g_keys[menu.active_player][menu.active_key] = key
        menu.active_key_num = menu.active_key_num + 1
        if menu.active_key_num > #g_key_codes then
            gamestate.switch(game)
        else
            menu.active_key = g_key_codes[menu.active_key_num]
        end
    else
        play_sound('fail')
    end
end

function menu:keyreleased(key, code)
    register_key(key,'keyboard')
end

function menu:joystickpressed(joystick,button)
    register_key({button=button},joystick)
end

