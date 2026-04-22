-- App state and UI variables
local state = "main" -- "main" or "credits"
local dice = {}      -- Table to hold dice objects
local selected = 1
local max_dice_count = 8

-- Animation settings
local roll_duration = 0.8 -- Duration of the roll animation in seconds

-- Available dice types, now including D2
local dice_types = { 2, 4, 6, 8, 10, 12, 20, 100 }

-- Palette definitions expanded with Crit Success and Crit Failure colors
-- {bg, text, highlight, crit_success, crit_fail}
local palettes = {
    -- Dark theme
    {
        bg = { 0.1, 0.1, 0.12 },
        text = { 0.9, 0.9, 0.9 },
        highlight = { 0.2, 0.8, 0.3 },
        crit_succ = { 0.2, 1.0, 0.4 },
        crit_fail = { 1.0, 0.3, 0.3 }
    },
    -- Light theme
    {
        bg = { 0.9, 0.9, 0.9 },
        text = { 0.1, 0.1, 0.1 },
        highlight = { 0.8, 0.2, 0.2 },
        crit_succ = { 0.1, 0.7, 0.2 },
        crit_fail = { 0.9, 0.1, 0.1 }
    },
    -- Blue theme
    {
        bg = { 0.15, 0.2, 0.3 },
        text = { 0.9, 0.95, 1.0 },
        highlight = { 1.0, 0.8, 0.1 },
        crit_succ = { 0.4, 1.0, 0.9 },
        crit_fail = { 1.0, 0.5, 0.5 }
    }
}
local cur_palette = 1

-- Screen dimensions constant
local SCR_W, SCR_H = 640, 480

-- Sound effects
local add_sound = love.audio.newSource("assets/threeTone2.mp3", "static")
local remove_sound = love.audio.newSource("assets/threeTone1.mp3", "static")
local roll_sound = love.audio.newSource("assets/powerUp1.mp3", "static")

local function playSFX(sfx)
    if sfx:isPlaying() then
        sfx:stop()
    end
    sfx:play()
end

-- Helper function to create a new die object
local function create_die(max_val)
    return {
        max = max_val or 6,
        current_display = 1, -- What's shown during animation
        final_val = 1,       -- The actual result
        anim_timer = 0,      -- Countdown for animation
        is_rolling = false
    }
end

-- Function to initiate the roll animation for a specific die
local function start_roll(die)
    playSFX(roll_sound)
    die.is_rolling = true
    die.anim_timer = roll_duration
    die.final_val = math.random(1, die.max)
end

function love.load()
    -- Request specific resolution
    love.window.setMode(SCR_W, SCR_H, { resizable = false, vsync = true })
    love.window.setTitle("Dice Roller")
    math.randomseed(os.time())

    if love.filesystem.getInfo("palette_index.txt") then
        local saved = love.filesystem.read("palette_index.txt")
        cur_palette = tonumber(saved)
    end

    -- Load fonts (using defaults, scaled)
    font_large = love.graphics.setNewFont("assets/DSEG14Classic-Regular.ttf", 60)
    font_small = love.graphics.setNewFont("assets/DSEG14ClassicMini-Regular.ttf", 20)
    font_hint = love.graphics.setNewFont("assets/SuperTechnology.ttf", 18)

    -- Initialize with one D20
    table.insert(dice, create_die(20))

    -- Load Music
    local music = love.audio.newSource("assets/Cyberpunk Moonlight Sonata v2.mp3", "stream")
    music:setLooping(true)
    music:setVolume(0.04)
    music:play()
end

function love.update(dt)
    -- Handle dice animation timers
    for _, d in ipairs(dice) do
        if d.is_rolling then
            d.anim_timer = d.anim_timer - dt

            -- While rolling, fluctuate the display value rapidly
            d.current_display = math.random(1, d.max)

            -- Animation finished
            if d.anim_timer <= 0 then
                d.is_rolling = false
                d.anim_timer = 0
                d.current_display = d.final_val -- Set to actual result
            end
        end
    end
end

function love.gamepadpressed(joystick, button)
    -- Global controls
    if button == "back" then
        state = state == "main" and "credits" or "main"
    elseif button == "start" then
        cur_palette = cur_palette % #palettes + 1
        love.filesystem.write("palette_index.txt", tostring(cur_palette))
    end

    -- Main screen controls
    if state == "main" then
        if button == "dpleft" then
            selected = selected > 1 and selected - 1 or #dice
        elseif button == "dpright" then
            selected = selected < #dice and selected + 1 or 1

            -- Cycle dice type (up/down)
        elseif button == "dpup" or button == "dpdown" then
            -- Cannot change type while rolling
            if dice[selected].is_rolling then return end

            local current_max = dice[selected].max
            local type_idx = 1
            -- Find current index in types table
            for i, v in ipairs(dice_types) do
                if v == current_max then
                    type_idx = i; break
                end
            end

            -- Calculate next index with wrapping
            if button == "dpup" then
                type_idx = type_idx % #dice_types + 1
            else
                type_idx = (type_idx - 2) % #dice_types + 1
            end

            -- Apply new type and reset value
            dice[selected].max = dice_types[type_idx]
            dice[selected].final_val = 1
            dice[selected].current_display = 1

            -- Add / Remove dice
        elseif button == "a" and #dice < max_dice_count then
            playSFX(add_sound)
            table.insert(dice, create_die(20)) -- Default new dice to d6
            selected = #dice
        elseif button == "b" and #dice > 1 then
            playSFX(remove_sound)
            table.remove(dice, selected)
            if selected > #dice then selected = #dice end

            -- Roll controls
        elseif button == "y" then
            -- Roll selected if not already rolling
            if not dice[selected].is_rolling then
                start_roll(dice[selected])
            end
        elseif button == "x" then
            -- Roll all if not already rolling
            for _, d in ipairs(dice) do
                if not d.is_rolling then start_roll(d) end
            end
        end
    end
end

function love.draw()
    local p = palettes[cur_palette]
    love.graphics.clear(p.bg)

    if state == "credits" then
        love.graphics.setColor(p.text)
        love.graphics.setFont(font_large)
        love.graphics.printf("Credits", 0, 80, SCR_W, "center")
        love.graphics.setFont(font_small)
        love.graphics.printf(
            "Created!by!KaMiSaMa\n\nMusic by Joth\n\nSFX by Kenney.nl\n\nMade!with!LOVE\n\n\n\nPress!BACK!to!return",
            0,
            200, SCR_W, "center")
        return
    end

    -- Draw Main Screen
    -- Module dimensions adjusted for 640x480
    local mw, mh = 120, 150
    local gap = 15
    local cols = math.min(#dice, 4)

    -- Calculate starting positions to center the layout dynamically
    local total_w = (cols * mw + (cols - 1) * gap)
    local start_x = (SCR_W - total_w) / 2
    local start_y = #dice <= 4 and (SCR_H - mh) / 2 - 20 or (SCR_H - (2 * mh + gap)) / 2 - 20

    for i, d in ipairs(dice) do
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        local x = start_x + col * (mw + gap)
        local y = start_y + row * (mh + gap)

        -- Draw module border
        love.graphics.setColor(p.text)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, mw, mh, 8, 8)

        -- Determine result color (Crit Succ/Fail or normal)
        local text_color = p.text
        local text_off_color = { text_color[1], text_color[2], text_color[3] }
        table.insert(text_off_color, 0.1)
        if not d.is_rolling then
            if d.max > 2 then -- Standard crit rules don't apply to coin flips usually
                if d.final_val == d.max then
                    text_color = p.crit_succ
                elseif d.final_val == 1 then
                    text_color = p.crit_fail
                end
            end
        end

        -- Draw display value (large, top)
        love.graphics.setFont(font_large)
        local display_str = tostring(d.current_display)

        -- Special rendering for D2 (Coin)
        if d.max == 2 then
            display_str = (d.current_display == 1) and "H!" or "T"
        elseif d.current_display == 100 then
            display_str = "00"
        end
        love.graphics.setColor(text_off_color)
        love.graphics.printf("~~", x - 10, y + 25, mw, "right")
        love.graphics.setColor(text_color)
        love.graphics.printf(display_str, x - 10, y + 25, mw, "right")

        -- Draw max value/dice type (small, bottom)
        love.graphics.setFont(font_small)
        love.graphics.setColor(text_off_color)
        love.graphics.printf("~~~~", x, y + mh - 35, mw, "center")
        love.graphics.setColor(p.text) -- Reset to normal text color
        local type_str = "D" .. tostring(d.max)
        if d.max > 9 and d.max < 99 then
            type_str = "!" .. type_str
        end
        if d.max == 2 then type_str = "COIN" end
        love.graphics.printf(type_str, x, y + mh - 35, mw, "center")

        -- Draw selection dot (bottom right corner)
        if i == selected then
            love.graphics.setColor(p.highlight)
            love.graphics.circle("fill", x + mw - 12, y + mh - 12, 5)
        end
    end

    -- Draw Input Hints
    love.graphics.setColor(p.text)
    love.graphics.setFont(font_hint)
    local hints =
    "Y:Roll | X: Roll All | A: Add | B: Remove | D-Pad: Move/Change Dice"
    love.graphics.printf(hints, 0, SCR_H - 45, SCR_W, "center")
end
