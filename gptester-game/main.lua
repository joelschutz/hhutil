local anim8 = require "anim8"

-- Sprites Data
local sheet = nil
local dpadBackground = {}
local buttonSprites = {
    ["a"] = {},
    ["b"] = {},
    ["x"] = {},
    ["y"] = {},
    ["start"] = {},
    ["back"] = {},
    ["dpup"] = {},
    ["dpdown"] = {},
    ["dpleft"] = {},
    ["dpright"] = {},
    ["leftshoulder"] = {},
    ["rightshoulder"] = {},
    ["triggerleft"] = {},
    ["triggerright"] = {},
    ["leftstick"] = {},
    ["rightstick"] = {},
    ["guide"] = {},
}

-- Sticks data
local stickState = {
    left = { x = 0.0, y = 0.0 },
    right = { x = 0.0, y = 0.0 },
}

function stickState:offsetL()
    return { self.left.x * 500.0 * -1.0, self.left.y * 500.0 * -1.0 }
end

function stickState:sizeR()
    return math.sqrt(self.right.x ^ 2 + self.right.y ^ 2)
end

-- Palletes
local pallets = { -- Grey, Purple, Blue, Green, Orange, Red, White
    { 1, 0, 0 },
    { 0, 1, 0 },
    { 0, 0, 1 },
    { 1, 0, 1 },
    { 1, 1, 0 },
    { 0, 1, 1 },
    { 1, 1, 1 },
}

local currentPalette = 1

-- Fonts and text effects
local fontText = love.graphics.newFont("assets/AtariGames.ttf", 24)
local fontScroller = love.graphics.newFont("assets/AtariGames.ttf", 36)

local demosceneText = love.filesystem.read("assets/Demoszene.txt")
local startTextAt = 1
local lineOffset = { 28, 0, -5, -28, -27, 0, 21, 0, 0, 0 } -- To adjust horizontal position for each line if needed
local shakeStrength = 0

-- Shaders
local time = 0.0
local timeOffset = math.random() * 10.0
local scale = math.random(5, 25) * 1.0 -- Adjust this value to change the scale
local plasma = love.graphics.newShader("assets/plasma.glsl")

-- Music
local musics = {
    love.audio.newSource("assets/Juhani Junkala [Retro Game Music Pack] Ending.mp3", "stream"),
    love.audio.newSource("assets/Juhani Junkala [Retro Game Music Pack] Level 1.mp3", "stream"),
    love.audio.newSource("assets/Juhani Junkala [Retro Game Music Pack] Level 2.mp3", "stream"),
    love.audio.newSource("assets/Juhani Junkala [Retro Game Music Pack] Level 3.mp3", "stream"),
    love.audio.newSource("assets/Juhani Junkala [Retro Game Music Pack] Title Screen.mp3", "stream"),
}

local currentMusic = 1


function love.load()
    -- Set the window title and size
    love.window.setTitle("Gamepad Tester")
    love.window.setMode(640, 480)

    -- Load saved palette index if it exists
    if love.filesystem.getInfo("user_data.txt") then
        local saved = love.filesystem.read("user_data.txt")
        -- First Digit: palette index, Second Digit: music index
        currentPalette = tonumber(saved:sub(1, 1))
        currentMusic = tonumber(saved:sub(2, 2))
    end

    -- Load the demo text file and print it to the console
    demosceneText = string.gsub(demosceneText, "\n", " ") -- Remove newlines for smoother scrolling

    -- Load assets and initialize animations
    love.graphics.setDefaultFilter("nearest", "nearest")
    sheet = love.graphics.newImage("/assets/gdb-xbox-2.png")
    local gridButtons = anim8.newGrid(16, 16, sheet:getWidth(), sheet:getHeight(), 144, 496)

    buttonSprites["triggerleft"] = anim8.newAnimation(gridButtons('1-3', 1), 0.03, "pauseAtEnd")
    buttonSprites["triggerright"] = anim8.newAnimation(gridButtons('1-3', 2), 0.03, "pauseAtEnd")
    buttonSprites["leftshoulder"] = anim8.newAnimation(gridButtons('8-10', 1), 0.03, "pauseAtEnd")
    buttonSprites["rightshoulder"] = anim8.newAnimation(gridButtons('8-10', 2), 0.03, "pauseAtEnd")
    local gridSticks = anim8.newGrid(16, 16, sheet:getWidth(), sheet:getHeight(), 176, 352)
    buttonSprites["leftstick"] = anim8.newAnimation(gridSticks('2-1', 1), 0.03, "pauseAtEnd")
    buttonSprites["rightstick"] = anim8.newAnimation(gridSticks('2-1', 1), 0.03, "pauseAtEnd")

    buttonSprites["x"] = anim8.newAnimation(gridButtons('1-3', 5), 0.03, "pauseAtEnd")
    buttonSprites["y"] = anim8.newAnimation(gridButtons('1-3', 7), 0.03, "pauseAtEnd")
    buttonSprites["a"] = anim8.newAnimation(gridButtons('1-3', 6), 0.03, "pauseAtEnd")
    buttonSprites["b"] = anim8.newAnimation(gridButtons('1-3', 8), 0.03, "pauseAtEnd")

    buttonSprites["back"] = anim8.newAnimation(gridButtons('8-10', 5), 0.03, "pauseAtEnd")
    buttonSprites["start"] = anim8.newAnimation(gridButtons('8-10', 6), 0.03, "pauseAtEnd")
    buttonSprites["guide"] = anim8.newAnimation(gridButtons('8-10', 4), 0.03, "pauseAtEnd")

    local gridDpad = anim8.newGrid(32, 32, sheet:getWidth(), sheet:getHeight(), 16, 496)
    dpadBackground = anim8.newAnimation(gridDpad(1, 1), 0.03, "pauseAtEnd")
    dpadBackground:pauseAtStart()
    buttonSprites["dpup"] = anim8.newAnimation(gridDpad(3, 1, 2, 1), 0.03, "pauseAtEnd")
    buttonSprites["dpright"] = anim8.newAnimation(gridDpad(3, 2, 2, 2), 0.03, "pauseAtEnd")
    buttonSprites["dpdown"] = anim8.newAnimation(gridDpad(3, 3, 2, 3), 0.03, "pauseAtEnd")
    buttonSprites["dpleft"] = anim8.newAnimation(gridDpad(3, 4, 2, 4), 0.03, "pauseAtEnd")

    for name, anim in pairs(buttonSprites) do
        anim:pauseAtStart()
        print("Initialized animation for button: " .. name)
    end

    -- Load music and set looping
    for _, music in ipairs(musics) do
        music:setLooping(true)
    end
    musics[currentMusic]:play()

    -- Load shaders
    plasma:send("resolution", { 640.0, 480.0 })
end

function love.update(dt)
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]

        -- Update stick states
        stickState.left.x = joystick:getGamepadAxis("leftx")
        stickState.left.y = joystick:getGamepadAxis("lefty")
        stickState.right.x = joystick:getGamepadAxis("rightx")
        stickState.right.y = joystick:getGamepadAxis("righty")

        -- Update button animations based on current input
        for name, anim in pairs(buttonSprites) do
            if name == "triggerleft" then
                if joystick:getGamepadAxis("triggerleft") > 0.1 then anim:resume() else anim:pauseAtStart() end
            elseif name == "triggerright" then
                if joystick:getGamepadAxis("triggerright") > 0.1 then anim:resume() else anim:pauseAtStart() end
            elseif joystick:isGamepadDown(name) then
                anim:resume()
            else
                anim:pauseAtStart()
            end
        end
    end

    -- Update all animations
    for _, anim in pairs(buttonSprites) do
        anim:update(dt)
    end

    -- Update Shaders and effects
    time = time + dt * (stickState:sizeR() * 10 + 2)
    shakeStrength = math.max(0, shakeStrength - dt * 5) -- Decay shake strength over time, but clamps it to a minimum of 0
    plasma:send("time", time + timeOffset)
    plasma:send("offset", stickState:offsetL())
    plasma:send("scale", scale)
end

function love.draw()
    -- Draw background
    love.graphics.setShader(plasma)
    love.graphics.setColor(pallets[currentPalette])
    love.graphics.rectangle("fill", 0, 0, 640, 480)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()

    -- Draw Scroller text
    -- local demoStr = "Press START to change palette, BACK to change music"
    local baseX = 320 - (time * 80)
    for i = startTextAt, #demosceneText, 1 do
        local letter = demosceneText:sub(i, i)
        local thisTime = time + i * 0.15
        local loc = (baseX + i * (15))
        if loc > -20 and loc < 660 then
            love.graphics.print(letter, fontScroller, baseX + i * (15), (480 - 70) + 40 * math.sin(thisTime * 2))
        elseif loc < -20 then
            -- Skip drawing letters that are off-screen to the left
            startTextAt = i + 1
        elseif loc > 660 then
            break
        end
    end


    local scale = 3

    -- Shoulder buttons and triggers
    buttonSprites["triggerleft"]:draw(sheet, 16 * scale, 16 * scale, 0, scale, scale)
    buttonSprites["leftshoulder"]:draw(sheet, 16 * scale, 32 * scale, 0, scale, scale)
    buttonSprites["triggerright"]:draw(sheet, 184 * scale, 16 * scale, 0, scale, scale)
    buttonSprites["rightshoulder"]:draw(sheet, 184 * scale, 32 * scale, 0, scale, scale)

    -- Menu buttons
    local menuX = 82.5 * scale
    local menuY = 16 * scale
    buttonSprites["back"]:draw(sheet, menuX, menuY, 0, scale, scale)
    buttonSprites["guide"]:draw(sheet, menuX + 16 * scale, menuY, 0, scale, scale)
    buttonSprites["start"]:draw(sheet, menuX + 32 * scale, menuY, 0, scale, scale)

    -- Face buttons
    local faceX = 172 * scale
    local faceY = 62 * scale
    buttonSprites["x"]:draw(sheet, faceX, faceY, 0, scale, scale)
    buttonSprites["a"]:draw(sheet, faceX + 12 * scale, faceY + 12 * scale, 0, scale, scale)
    buttonSprites["y"]:draw(sheet, faceX - 12 * scale, faceY + 12 * scale, 0, scale, scale)
    buttonSprites["b"]:draw(sheet, faceX, faceY + 24 * scale, 0, scale, scale)

    -- D-pad
    local dpadX = 20 * scale
    local dpadY = 64 * scale
    dpadBackground:draw(sheet, dpadX, dpadY, 0, scale, scale)
    buttonSprites["dpup"]:draw(sheet, dpadX, dpadY, 0, scale, scale)
    buttonSprites["dpright"]:draw(sheet, dpadX, dpadY, 0, scale, scale)
    buttonSprites["dpdown"]:draw(sheet, dpadX, dpadY, 0, scale, scale)
    buttonSprites["dpleft"]:draw(sheet, dpadX, dpadY, 0, scale, scale)

    -- Sticks
    -- Circle shows max stick range, cross shows current stick position
    -- Sprite is drawn at the center of the stick, so we need to offset it by half the sprite size (8 pixels) and also by the stick positions
    local leftStickCenterX = 32 * scale
    local leftStickCenterY = 120 * scale
    local rightStickCenterX = 168 * scale
    local rightStickCenterY = 120 * scale
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", leftStickCenterX + 8 * scale, leftStickCenterY + 8 * scale, 16 * scale)
    love.graphics.circle("fill", rightStickCenterX + 8 * scale, rightStickCenterY + 8 * scale, 16 * scale)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("line", leftStickCenterX + 8 * scale, leftStickCenterY + 8 * scale, 8 * scale)
    love.graphics.circle("line", rightStickCenterX + 8 * scale, rightStickCenterY + 8 * scale, 8 * scale)
    buttonSprites["leftstick"]:draw(sheet, leftStickCenterX + stickState.left.x * 16 * scale,
        leftStickCenterY + stickState.left.y * 16 * scale, 0, scale, scale)
    buttonSprites["rightstick"]:draw(sheet, rightStickCenterX + stickState.right.x * 16 * scale,
        rightStickCenterY + stickState.right.y * 16 * scale, 0, scale, scale)

    -- Draw Credits at the center of the screen
    -- local strCredits = "Gamepad Tester"
    local strCredits =
    "Gamepad Tester\n\nCreated by KaMiSaMa\nIcons by greatdocbrown\nMusic by subspaceaudio\n\nBuilt with LOVE"
    love.graphics.setColor(1, 1, 1, 1)
    local posY = 120
    local offsetX = 0
    local lineCount = 1
    for i = 1, #strCredits do
        local letter = strCredits:sub(i, i)
        if letter == "\n" then
            posY = posY + fontText:getHeight() + 5
            offsetX = i
            lineCount = lineCount + 1
        else
            local rX = math.random() * 2 - 1
            local rY = math.random() * 2 - 1
            love.graphics.print(letter, fontText,
                (rX * shakeStrength) + 320 - (fontText:getWidth(strCredits) / 2) + lineOffset[lineCount] +
                (i - 1 - offsetX) * 14, posY + (rY * shakeStrength))
        end
    end
end

-- Handle gamepad input to change palette and save it on exit
function love.gamepadpressed(_, button)
    if button == "start" then
        currentPalette = currentPalette % #pallets + 1
        scale = math.random(5, 25) * 1.0 -- Adjust this value to change the scale
    elseif button == "back" then
        currentMusic = currentMusic % #musics + 1
        for _, music in ipairs(musics) do
            music:stop()
        end
        musics[currentMusic]:play()
    end

    shakeStrength = shakeStrength + 5
end

-- Save the current palette index on exit
function love.quit()
    love.filesystem.write("user_data.txt", tostring(currentPalette) .. tostring(currentMusic))
end
