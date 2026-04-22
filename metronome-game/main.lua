-- Minimalist Metronome Template for LÖVE 2D
-- Resolution: 640x480

local bpm = 180
local bpb = 4
local currentBeat = 0
local timer = 0
local isPlaying = false
local showCredits = false

-- Sound Bank Logic (Ensure files exist or replace with dummy functions)
local soundBanks = {}
local currentBank = 1

local fontBig = love.graphics.newFont("assets/c64esque.ttf", 58)
local fontMedium = love.graphics.newFont("assets/c64esque.ttf", 32)
local fontSmall = love.graphics.newFont("assets/c64esque.ttf", 24)

-- Color Palettes
local palettes = {
    { bg = { 0.1, 0.05, 0.2 },   primary = { 0.8, 0.4, 1.0 },    text = { 1, 1, 1 } },
    { bg = { 0.05, 0.1, 0.1 },   primary = { 0.2, 0.9, 0.6 },    text = { 0.9, 1, 0.9 } },
    { bg = { 0.15, 0.1, 0.05 },  primary = { 1, 0.6, 0.2 },      text = { 1, 0.9, 0.8 } },
    { bg = { 0.02, 0.08, 0.18 }, primary = { 0.00, 0.60, 1.00 }, text = { 0.85, 0.95, 1.00 } },
    { bg = { 0.05, 0.02, 0.08 }, primary = { 1.00, 0.00, 0.50 }, text = { 0.00, 1.00, 0.80 } },
    { bg = { 0.18, 0.20, 0.25 }, primary = { 0.53, 0.75, 0.82 }, text = { 0.85, 0.87, 0.91 } },
    { bg = { 0.05, 0.05, 0.05 }, primary = { 0.9, 0.1, 0.3 },    text = { 0.8, 0.8, 0.8 } },
    { bg = { 0.9, 0.9, 0.9 },    primary = { 0.1, 0.1, 0.1 },    text = { 0.2, 0.2, 0.2 } },
}
local currentPalette = 1

function love.load()
    love.window.setMode(640, 480)

    if love.filesystem.getInfo("palette_index.txt") then
        local saved = love.filesystem.read("palette_index.txt")
        currentPalette = tonumber(saved)
    end

    local sounds = {
        "assets/Perc_MetronomeQuartz",
        "assets/Perc_Metal",
        "assets/Perc_Stick",
        "assets/Synth_Bell_B",
        "assets/Synth_Block_C",
        "assets/Perc_Can",
        "assets/Perc_Clap",
        "assets/Perc_Snap",
        "assets/Perc_WhistleRef",
        "assets/Perc_MouthPop",
    }

    for index, value in ipairs(sounds) do
        local bank = {
            down = love.audio.newSource(value .. "_lo.wav", "static"),
            tick = love.audio.newSource(value .. "_hi.wav", "static")
        }
        table.insert(soundBanks, bank)
    end
    -- Load sounds here (omitted for brevity)
end

function love.update(dt)
    if isPlaying then
        timer = timer + dt
        local interval = 60 / bpm

        if timer >= interval then
            timer = 0
            currentBeat = (currentBeat % bpb) + 1

            -- Play sound if loaded
            local bank = soundBanks[currentBank]
            if bank.down and currentBeat == 1 then
                love.audio.play(bank.down)
            elseif bank.tick then
                love.audio.play(bank.tick)
            end
        end
    end
end

function love.draw()
    local p = palettes[currentPalette]
    love.graphics.clear(p.bg)

    if showCredits then
        drawCredits(p)
        drawBlinkingDot(p)
        return
    end

    -- --- LEFT SIDE: CONTROLS ---
    love.graphics.setFont(fontBig)
    love.graphics.setColor(p.text)

    -- BPM: Up Arrow | Value | Down Arrow
    drawTriangle(100, 120, 20, "up")
    love.graphics.printf(bpm, 45, 140, 120, "center")
    drawTriangle(100, 220, 20, "down")

    -- BPB: Left Arrow | Value | Right Arrow
    drawTriangle(170, 170, 20, "left")
    love.graphics.printf(bpb, 160, 140, 120, "center")
    drawTriangle(270, 170, 20, "right")

    love.graphics.setFont(fontMedium)
    -- Sound Bank: Dots
    love.graphics.print("Y", 25, 275)
    for i = 1, #soundBanks do
        local r = (i == currentBank) and 8 or 4
        love.graphics.circle("fill", 40 + (i * 25), 290, r)
    end
    love.graphics.print("X", 315, 275)

    -- Play/Pause Icons
    love.graphics.print("A", 70, 382)
    drawPlayIcon(100, 390)

    love.graphics.print("B", 150, 382)
    drawPauseIcon(180, 390)

    -- --- RIGHT SIDE: METRONOME ---
    local centerX, centerY = 480, 240
    local baseRadius = 50
    local radius = baseRadius

    if isPlaying then
        local pulse = (timer / (60 / bpm)) * 50
        radius = baseRadius + pulse
    end

    love.graphics.setColor(p.primary)
    if currentBeat == 1 and isPlaying then
        love.graphics.circle("fill", centerX, centerY, radius)
    else
        love.graphics.circle("line", centerX, centerY, radius)
    end
end

-- UI Helper Functions
function drawTriangle(x, y, size, dir)
    local hw = size / 2
    if dir == "up" then
        love.graphics.polygon("fill", x, y, x - hw, y + hw, x + hw, y + hw)
    elseif dir == "down" then
        love.graphics.polygon("fill", x, y, x - hw, y - hw, x + hw, y - hw)
    elseif dir == "left" then
        love.graphics.polygon("fill", x, y, x + hw, y - hw, x + hw, y + hw)
    elseif dir == "right" then
        love.graphics.polygon("fill", x, y, x - hw, y - hw, x - hw, y + hw)
    end
end

function drawPlayIcon(x, y)
    love.graphics.polygon("fill", x, y, x, y + 15, x + 12, y + 7.5)
end

function drawPauseIcon(x, y)
    love.graphics.rectangle("fill", x, y, 4, 15)
    love.graphics.rectangle("fill", x + 7, y, 4, 15)
end

function drawBlinkingDot(p)
    if isPlaying then
        local alpha = 1 - (timer / (60 / bpm))
        love.graphics.setColor(p.primary[1], p.primary[2], p.primary[3], alpha)
        love.graphics.circle("fill", 610, 450, 10)
    end
end

function drawCredits(p)
    love.graphics.setColor(p.text)
    love.graphics.setFont(fontSmall)
    love.graphics.printf(
        "CREDITS\n\nMinimalist Metronome\nCreated by KaMiSaMa\nSounds by Ludwig Peter Müller\nBuilt with LÖVE", 0, 180,
        640,
        "center")
end

function love.gamepadpressed(joystick, button)
    if button == "dpup" then
        bpm = math.min(bpm + 1, 300)
    elseif button == "dpdown" then
        bpm = math.max(bpm - 1, 30)
    elseif button == "dpleft" then
        bpb = math.max(bpb - 1, 1)
    elseif button == "dpright" then
        bpb = math.min(bpb + 1, 16)
    elseif button == "a" then
        isPlaying = true; timer = 0; currentBeat = 0
    elseif button == "b" then
        isPlaying = false; currentBeat = 0
    elseif button == "y" then
        currentBank = (currentBank - 2) % #soundBanks + 1
    elseif button == "x" then
        currentBank = (currentBank % #soundBanks) + 1
    elseif button == "start" then
        currentPalette = (currentPalette % #palettes) + 1
        love.filesystem.write("palette_index.txt", tostring(currentPalette))
    elseif button == "back" then
        showCredits = not showCredits
    end
end
