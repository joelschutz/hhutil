-- main.lua
-- Basic Love2D template
local anim8 = require 'anim8'
local flux = require "flux"
local text = require "text"

-- =========================
-- Local variables
-- =========================
-- States
local game = {
    width = 640,
    height = 480,
    title = "Test your luck"
}

local player = {
    x = 0,
    y = 0,
    speed = 200,
    select = { 0, 0, 0 },
    cardindex = 1,
    sceneIndex = 1,
    cardTween = { nil, nil, nil },
    cardOffset = {
        a = 0,
        b = 0,
        c = 0
    },
    cardFlip = {
        a = 2,
        b = 2,
        c = 2
    },
    creditcards = { love.math.random(22), love.math.random(22) },
    creditflip = 1,
    creditTween = nil,
    lock = false
}

local active_joystick

-- Assets
local cards = {}
local animation
local cursor
local candle
local flame
local mainFont
local dealSound
local shuffleSound

local light = love.graphics.newShader [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        vec2 center = vec2(320, 240);
        float distance = length(screen_coords - center);
        float fade = clamp(distance / 300.0, 0.0, 1.0);

        pixel.a = pixel.a * fade;

        return pixel * color;
    }
]]

local function animatecards(duration)
    local function animA()
        player.cardTween[1] = flux.to(player.cardOffset, 1 + duration * love.math.random(), { a = love.math.random(5) })
            :ease("backinout"):after(
                1 + duration * love.math.random(),
                { a = 0 }):oncomplete(animA)
    end

    local function animB()
        player.cardTween[2] = flux.to(player.cardOffset, 1 + duration * love.math.random(), { b = love.math.random(5) })
            :ease("backinout"):after(
                1 + duration * love.math.random(),
                { b = 0 }):oncomplete(animB)
    end

    local function animC()
        player.cardTween[3] = flux.to(player.cardOffset, 1 + duration * love.math.random(), { c = love.math.random(5) })
            :ease("backinout"):after(
                1 + duration * love.math.random(),
                { c = 0 }):oncomplete(animC)
    end

    animA()
    animB()
    animC()
end

-- =========================
-- Load (runs once at start)
-- =========================
function love.load()
    love.window.setMode(game.width, game.height)
    love.window.setTitle(game.title)

    -- Get Joystick
    active_joystick = love.joystick.getJoysticks()[1]

    -- Load cards
    love.graphics.setDefaultFilter("nearest")
    local path = "assets/tarot_free/monochrome/"
    cards[0] = love.graphics.newImage(path .. "back.png")
    for i = 0, 21, 1 do
        cards[i + 1] = love.graphics.newImage(path .. string.format("%d.png", i))
    end
    animatecards(3)

    -- Load Cursor
    cursor = love.graphics.newImage("assets/pointer-s.png")

    -- Load Candle
    candle = love.graphics.newImage("assets/candle.png")
    flame = love.graphics.newImage("assets/flames.png")
    local g = anim8.newGrid(16, 16, flame:getWidth(), flame:getHeight())
    animation = anim8.newAnimation(g('1-4', 1), 0.1)

    -- Load Font
    mainFont = love.graphics.newFont("assets/antiquity-print.ttf", 20)

    -- Load Music and sound
    local music = love.audio.newSource("assets/16 - The Calm Before The Storm.ogg", "stream")
    music:setLooping(true)
    music:play()

    dealSound = love.audio.newSource("assets/card-place-2.ogg", "stream")
    shuffleSound = love.audio.newSource("assets/card-fan-1.ogg", "stream")

    -- Set default background color
    local r, g, b = love.math.colorFromBytes(43, 4, 74)
    love.graphics.setBackgroundColor(r, g, b)

    -- Center player
    player.x = game.width / 2
    player.y = game.height - 50
end

-- =========================
-- Update (runs every frame)
-- =========================
function love.update(dt)
    -- Movement
    if love.keyboard.isDown("w", "up") then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("s", "down") then
        player.y = player.y + player.speed * dt
    end
    if love.keyboard.isDown("a", "left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d", "right") then
        player.x = player.x + player.speed * dt
    end

    if active_joystick then
        if active_joystick:isGamepadDown("dpup") then
            player.y = player.y - player.speed * dt
        end
        if active_joystick:isGamepadDown("dpdown") then
            player.y = player.y + player.speed * dt
        end
        if active_joystick:isGamepadDown("dpleft") then
            player.x = player.x - player.speed * dt
        end
        if active_joystick:isGamepadDown("dpright") then
            player.x = player.x + player.speed * dt
        end

        player.x = player.x + dt * player.speed * active_joystick:getGamepadAxis("leftx")
        player.y = player.y + dt * player.speed * active_joystick:getGamepadAxis("lefty")
    end

    -- Animation update
    animation:update(dt)
    flux.update(dt)
end

-- =========================
-- Draw (runs every frame)
-- =========================
function love.draw()
    love.graphics.setShader(light)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()

    if player.sceneIndex == 1 then
        DrawTarot()
    elseif player.sceneIndex == 2 then
        DrawCredits()
    end
end

function DrawTarot()
    -- Draw Cards
    love.graphics.draw(cards[player.select[1]], 51 + 73, 127 + player.cardOffset.a, 0, player.cardFlip.a, 2, 73 / 2, 0)
    love.graphics.draw(cards[player.select[2]], 51 + 146 + 50 + 73, 127 + player.cardOffset.b, 0, player.cardFlip.b, 2,
        73 / 2, 0)
    love.graphics.draw(cards[player.select[3]], 51 + 146 + 50 + 146 + 50 + 73, 127 + player.cardOffset.c, 0,
        player.cardFlip.c, 2, 73 / 2, 0)

    -- Draw text
    love.graphics.print(text.mainScene[1], mainFont, (game.width / 2) - (mainFont:getWidth(text.mainScene[1]) / 2), 53)
    love.graphics.print(text.mainScene[2], mainFont, 51 + 73 - (mainFont:getWidth(text.mainScene[2]) / 2), 127 + 226 + 26)
    love.graphics.print(text.mainScene[3], mainFont, 51 + 146 + 50 + 73 - (mainFont:getWidth(text.mainScene[3]) / 2),
        127 + 226 + 26)
    love.graphics.print(text.mainScene[4], mainFont,
        51 + 146 + 50 + 146 + 50 + 73 - (mainFont:getWidth(text.mainScene[4]) / 2),
        127 + 226 + 26)

    -- Draw Candles
    love.graphics.draw(candle, 73, 55, 0, 2, 2)
    animation:draw(flame, 74, 40, 0, 2, 2)

    love.graphics.draw(candle, game.width - 32 - 73, 55, 0, 2, 2)
    animation:draw(flame, game.width - 32 - 72, 40, 0, 2, 2)

    -- Draw cursor
    love.graphics.draw(cursor, player.x, player.y, 0, 2, 2)
end

function DrawCredits()
    -- Draw Cards
    love.graphics.draw(cards[player.creditcards[1]], 73, game.height - 126, 0, player.creditflip, 1, 73 / 2, 0)
    love.graphics.draw(cards[player.creditcards[2]], game.width - 73, game.height - 126, 0, player.creditflip, 1, 73 / 2,
        0)


    -- Draw text
    love.graphics.print(text.creditsScene[1], mainFont, (game.width / 2) - (mainFont:getWidth(text.creditsScene[1]) / 2),
        53)
    love.graphics.print(text.creditsScene[2], mainFont, (game.width / 2) - (mainFont:getWidth(text.creditsScene[2]) / 2),
        127)
    love.graphics.print(text.creditsScene[3], mainFont,
        (game.width / 2) - (mainFont:getWidth(text.creditsScene[3]) / 2),
        127 + 68)
    love.graphics.print(text.creditsScene[4], mainFont,
        (game.width / 2) - (mainFont:getWidth(text.creditsScene[4]) / 2),
        127 + 68 + 98)
    love.graphics.print(text.creditsScene[5], mainFont,
        (game.width / 2) - (mainFont:getWidth(text.creditsScene[5]) / 2),
        game.height - 68)

    -- Draw Candles
    love.graphics.draw(candle, 73, 55, 0, 2, 2)
    animation:draw(flame, 74, 40, 0, 2, 2)

    love.graphics.draw(candle, game.width - 32 - 73, 55, 0, 2, 2)
    animation:draw(flame, game.width - 32 - 72, 40, 0, 2, 2)
end

-- =========================
-- Key Pressed (single press)
-- =========================
function love.gamepadpressed(joystick, button)
    if player.sceneIndex == 2 then
        resetCredit()
    elseif joystick == active_joystick then
        Interactwithgame(button, true)
    end
end

function love.keypressed(key)
    if player.sceneIndex == 2 then
        resetCredit()
    else
        Interactwithgame(key, false)
    end
end

function resetCredit()
    player.lock = false
    player.creditTween:stop()
    player.creditflip = 1
    player.sceneIndex = 1
end

function Interactwithgame(button, isjoystick)
    if player.lock then
        return
    end

    local function reset()
        flux.to(player.cardFlip, 0.3, { a = 0, b = 0, c = 0 }):ease("quadin"):oncomplete(function()
            player.cardindex = 1
            player.select = { 0, 0, 0 }
            flux.to(player.cardFlip, 0.3, { a = 2, b = 2, c = 2 }):ease("quadout"):oncomplete(function() player.lock = false end)
        end)
        shuffleSound:play()
    end

    local index = { "space", "return", "q" }
    if isjoystick then
        index = { "a", "b", "back" }
    end

    if button == index[1] then
        player.lock = true

        -- Pick card
        local s = love.math.random(22)

        -- Check if card is unique
        for _, value in ipairs(player.select) do
            if value == s then
                s = love.math.random(22)
            end
        end

        -- Animate Rotation
        if player.cardindex == 1 then
            flux.to(player.cardFlip, 0.3, { a = 0 }):ease("quadin"):oncomplete(function()
                player.select[player.cardindex] = s
                player.cardindex = player.cardindex + 1

                flux.to(player.cardFlip, 0.3, { a = 2 }):ease("quadout"):oncomplete(function() player.lock = false end)
            end)
        elseif player.cardindex == 2 then
            flux.to(player.cardFlip, 0.3, { b = 0 }):ease("quadin"):oncomplete(function()
                player.select[player.cardindex] = s
                player.cardindex = player.cardindex + 1
                flux.to(player.cardFlip, 0.3, { b = 2 }):ease("quadout"):oncomplete(function() player.lock = false end)
            end)
        elseif player.cardindex == 3 then
            flux.to(player.cardFlip, 0.3, { c = 0 }):ease("quadin"):oncomplete(function()
                player.select[player.cardindex] = s
                player.cardindex = player.cardindex + 1
                flux.to(player.cardFlip, 0.3, { c = 2 }):ease("quadout"):oncomplete(function() player.lock = false end)
            end)
        end


        -- Reset array
        if player.cardindex > 3 then
            reset()
        else
            dealSound:play()
        end
    end
    if button == index[2] then
        player.lock = true

        -- Reset array
        reset()
    end
    if button == index[3] then
        player.lock = true

        -- Start credit Animation
        function animateCredit()
            player.creditTween = flux.to(player, 1, { creditflip = 0 }):ease("quadin"):oncomplete(function()
                player.creditcards[1] = love.math.random(22)
                player.creditcards[2] = love.math.random(22)
                player.creditTween = flux.to(player, 1, { creditflip = 1 }):ease("quadout"):oncomplete(animateCredit)
            end):delay(1.5)
        end

        animateCredit()

        -- Go to creditsScene
        player.sceneIndex = 2
    end
end
