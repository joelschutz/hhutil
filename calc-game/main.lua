local flux = require "flux"
local modes = require "actions"
local colors = require "palette"

if love.filesystem.getInfo("palette_index.txt") then
    local saved = love.filesystem.read("palette_index.txt")
    colors:swapPallet(tonumber(saved))
end

local state = require "calc"

local cols = 4
local rows = 5
local selectedCol = 1
local selectedRow = 1

local selectedMode = 1
local actions = modes.actions[selectedMode]

local credits = false

local function updateButtoons()
    local btns = {}
    local i = 1
    for r = 1, rows do
        btns[r] = {}
        for c = 1, cols do
            btns[r][c] = {}
            btns[r][c].onClick = actions[i].onClick
            btns[r][c].label = actions[i].label
            if btns[r][c].label == "AU" then -- adcionar botão da unidade de angulo
                if state.angleUnit == "DEG" then
                    btns[r][c].label = "RAD"
                else
                    btns[r][c].label = "DEG"
                end
            end
            if r == selectedRow and c == selectedCol then
                btns[r][c].scale = 1.15
            else
                btns[r][c].scale = 1
            end
            btns[r][c].color = colors[actions[i].color]
            if btns[r][c].color == nil then
                btns[r][c].color = colors.primary
            end
            i = i + 1
        end
    end
    return btns
end

local function updateSelection()
    local prev = buttons[lastSelected.row][lastSelected.col]
    local curr = buttons[selectedRow][selectedCol]

    if prev == curr then
        flux.to(prev, 0.15, { scale = 1 }):after(0.15, { scale = 1.15 })
    else
        -- Animate previous back to normal
        flux.to(prev, 0.15, { scale = 1 })
        -- flux.to(prev.color, 0.15, { [1] = 0.7, [2] = 0.7, [3] = 0.7 })

        -- Animate current selection
        flux.to(curr, 0.15, { scale = 1.15 })
        -- flux.to(curr.color, 0.15, { [1] = 0.8, [2] = 0.2, [3] = 0.2 })
    end

    lastSelected.row = selectedRow
    lastSelected.col = selectedCol
end

local function convertToBase(num, base)
    if base == "OCT" then
        return string.format("%o", num)
    elseif base == "HEX" then
        return string.format("%X", num)
    elseif base == "BIN" then
        if num == 0 then return "0" end
        local bits = ""
        while num > 0 do
            local remainder = num % 2
            bits = tostring(remainder) .. bits
            num = math.floor(num / 2)
        end
        return bits
    end
    return num
end

local fadeText = love.graphics.newShader [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        float fade = (screen_coords.y - 25.0) / 240.0;

        color.a = color.a * (fade);
        return pixel * color ;
    }
]]

local buttonGradient = love.graphics.newShader [[
    uniform vec2 center;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        float distance = length(screen_coords - center) / 300.0;
        float tint = 1.0 - clamp(distance, 0.0, 1.0);

        color.rgb *= tint;
        //color.rg = screen_coords;
        return color ;
    }
]]

local scanLines = love.graphics.newShader [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        float linex = floor(screen_coords.x);
        float liney = floor(screen_coords.y);

        if ((mod(linex,4.0) == 0.0) || (mod(liney,4.0) == 0.0)){
            color.rgb *= 0.9;
        };
        return color ;
    }
]]

local gradientInv = love.graphics.newShader [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        float tint = ((screen_coords.y+100.0) / 240.0);
        tint = clamp(tint, 0.6, 1.0);

        color.rgb *= tint;
        return color ;
    }
]]


function love.load()
    love.window.setMode(640, 480)

    toolbarHeight = 25

    -- Create button grid
    buttons = updateButtoons()

    joystick = nil
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        joystick = joysticks[1]
    end

    moveDelay = 0.2
    moveTimer = 0

    -- Load Assets
    font = love.graphics.newFont("assets/LCDBlock2.ttf", 40)
    fontSmall = love.graphics.newFont("assets/LCDBlock2.ttf", 32)
    love.graphics.setFont(font)

    clickSound = love.audio.newSource("assets/keypress-003.wav", "stream")
    scrollSound = love.audio.newSource("assets/keypress-016.wav", "stream")
    optionsSound = love.audio.newSource("assets/keypress-009.wav", "stream")
    moveSound = love.audio.newSource("assets/keypress-020.wav", "stream")

    lastSelected = { row = 1, col = 1 }

    -- Config calculator
    state:setScreenSize(300, 380)
    state:setScreenFont(fontSmall)
end

function love.update(dt)
    flux.update(dt)

    if joystick then
        moveTimer = moveTimer - dt

        if moveTimer <= 0 then
            if joystick:getGamepadAxis("triggerright") > 0.8 then
                moveTimer = moveDelay
                state:moveFloat(true)
                scrollSound:play()
            end

            if joystick:getGamepadAxis("triggerleft") > 0.8 then
                moveTimer = moveDelay
                selectedMode = selectedMode - 1
                if selectedMode < 1 then
                    selectedMode = #modes.actions
                end
                actions = modes.actions[selectedMode]
                buttons = updateButtoons()
                scrollSound:play()
            end

            local x = joystick:getGamepadAxis("leftx")
            local y = joystick:getGamepadAxis("lefty")

            local moved = false

            if x > 0.5 then
                selectedCol = math.min(cols, selectedCol + 1)
                moved = true
            elseif x < -0.5 then
                selectedCol = math.max(1, selectedCol - 1)
                moved = true
            end

            if y > 0.5 then
                selectedRow = math.min(rows, selectedRow + 1)
                moved = true
            elseif y < -0.5 then
                selectedRow = math.max(1, selectedRow - 1)
                moved = true
            end

            if moved then
                moveTimer = moveDelay
                updateSelection()
            end
        end
    end
end

function love.gamepadpressed(joy, button)
    if credits then
        credits = false
    end
    if button == "dpright" then
        selectedCol = math.min(cols, selectedCol + 1)
        updateSelection()
        moveSound:play()
    elseif button == "dpleft" then
        selectedCol = math.max(1, selectedCol - 1)
        updateSelection()
        moveSound:play()
    elseif button == "dpdown" then
        selectedRow = math.min(rows, selectedRow + 1)
        updateSelection()
        moveSound:play()
    elseif button == "dpup" then
        selectedRow = math.max(1, selectedRow - 1)
        updateSelection()
        moveSound:play()
    elseif button == "a" then
        local btn = buttons[selectedRow][selectedCol]
        if btn and btn.onClick then
            btn:onClick(state)
            clickSound:play()
        end
    elseif button == "b" then
        state:backspace()
        clickSound:play()
    elseif button == "x" then
        if state.ans ~= nil then
            state.register = state.ans
            clickSound:play()
        end
    elseif button == "y" then
        state:pushResult()
        clickSound:play()
    elseif button == "select" or button == "back" then
        credits = true
        optionsSound:play()
    elseif button == "start" then
        local i = colors.index + 1
        if i > #colors.pallets then
            i = 1
        end
        colors:swapPallet(i)
        buttons = updateButtoons()
        optionsSound:play()
        love.filesystem.write("palette_index.txt", tostring(colors.index))
    elseif button == "leftshoulder" then
        selectedMode = selectedMode + 1
        if selectedMode > #modes.actions then
            selectedMode = 1
        end
        actions = modes.actions[selectedMode]
        buttons = updateButtoons()
        scrollSound:play()
    elseif button == "rightshoulder" then
        state:moveFloat(false)
        scrollSound:play()
    end
end

function love.draw()
    local width, height = love.graphics.getDimensions()

    -- Toolbar
    love.graphics.setColor(colors.primary)
    love.graphics.rectangle("fill", 0, 0, width, toolbarHeight)
    love.graphics.setColor(colors.dark)
    love.graphics.print("L:[" .. modes.names[selectedMode] .. "]", fontSmall, 5, -3, 0, 1, 1)
    love.graphics.print("A-Press B-Back X-ANS Y-Eval       Float:R", fontSmall, 188, -3, 0, 1, 1)



    local remainingHeight = height - toolbarHeight
    local halfWidth = width / 2

    -- Left side
    --- Background
    love.graphics.setShader(scanLines)
    love.graphics.setColor(colors.light)
    love.graphics.rectangle("fill", 0, toolbarHeight, halfWidth, remainingHeight)
    love.graphics.setShader()
    --- Dotted line
    love.graphics.setColor(colors.dark)
    for i = 1, 14, 1 do
        love.graphics.line(20 * i, remainingHeight - 20, 20 * i + 10, remainingHeight - 20)
    end
    --- Register
    if state.base ~= "DEC" then
        love.graphics.print(string.sub(state.base, 1, 1), 10, remainingHeight - 10, 0, 1, 1)
    end
    if state.memMode then
        love.graphics.setColor(colors.accent)
        love.graphics.print(state.memMode, 10, remainingHeight - 55, 0, 1, 1)
        love.graphics.setColor(colors.dark)
    end
    local register = convertToBase(state.register, state.base)
    love.graphics.print(register, halfWidth - 10, remainingHeight - 10, 0, 1, 1,
        font:getWidth(register), 0)
    --- Tokens
    if credits then
        local text = "Created by K4M1S4M4\nSFX by unicaegames\nMade with LÖVE"
        love.graphics.setFont(font)
        love.graphics.print(text, 10, toolbarHeight + 10, 0, 1, 1)
    else
        love.graphics.setShader(fadeText)
        love.graphics.setFont(fontSmall)
        for i = #state.buffer, 1, -1 do
            t = state.buffer[i]
            love.graphics.print(t, halfWidth - 10, remainingHeight - 60 - (20 * (#state.buffer - i)), 0, 1, 1,
                fontSmall:getWidth(t), 0)
        end
        love.graphics.setFont(font)
        love.graphics.setShader()
    end


    -- Right side
    -- love.graphics.setShader(gradient)
    love.graphics.setColor(colors.dark)
    love.graphics.rectangle("fill", halfWidth, toolbarHeight, halfWidth, remainingHeight)
    -- love.graphics.setShader()

    -- Grid
    local gridX = halfWidth
    local gridY = toolbarHeight
    local gridWidth = halfWidth
    local gridHeight = remainingHeight

    local padding = 10
    local cellWidth = (gridWidth - padding * (cols + 1)) / cols
    local cellHeight = (gridHeight - padding * (rows + 1)) / rows

    for r = 1, rows do
        for c = 1, cols do
            local btn = buttons[r][c]

            local baseX = gridX + padding + (c - 1) * (cellWidth + padding)
            local baseY = gridY + padding + (r - 1) * (cellHeight + padding)

            local w = cellWidth * btn.scale
            local h = cellHeight * btn.scale

            local x = baseX + (cellWidth - w) / 2
            local y = baseY + (cellHeight - h) / 2

            -- Button fill
            local val = { x + (w / 2), y + (h / 2) }
            buttonGradient:send("center", val)
            love.graphics.setShader(buttonGradient)
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", x, y, w, h, 10, 10)
            love.graphics.setShader()
            -- Border
            love.graphics.setColor(colors.light)
            love.graphics.rectangle("line", x, y, w, h, 10, 10)

            -- Label
            love.graphics.setColor(colors.dark)
            local textWidth = font:getWidth(btn.label)
            local textHeight = font:getHeight()

            love.graphics.print(
                btn.label,
                1 + x + (w - textWidth) / 2,
                1 + y + (h - textHeight) / 2
            )
        end
    end
end
