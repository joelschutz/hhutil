-- TODO List App for LÖVE 2D
-- Controller-only interface for handheld consoles

local palette = require "palette"
local persistence = require "persistence"
local flux = require "flux"
local draw = require "draw"

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local SCREEN_WIDTH = 640
local SCREEN_HEIGHT = 480
local MAX_TODO_LENGTH = 60
local ITEM_HEIGHT = 44
local PADDING = 18
local VISIBLE_ITEMS = 8
local TOOLBAR_HEIGHT = 30

local keyboardLayouts = {
    normal = {
        {"1","2","3","4","5","6","7","8","9","0"},
        {"q","w","e","r","t","y","u","i","o","p"},
        {"a","s","d","f","g","h","j","k","l","BACK"},
        {"z","x","c","v","b","n","m",",",".","/"},
        {"SHIFT","SPACE","DONE"}
    },
    shift = {
        {"!","@","#","$","%","^","&","*","(",")"},
        {"Q","W","E","R","T","Y","U","I","O","P"},
        {"A","S","D","F","G","H","J","K","L","BACK"},
        {"Z","X","C","V","B","N","M","<",">","?"},
        {"SHIFT","SPACE","DONE"}
    }
}

-- ============================================================================
-- GLOBAL STATE
-- ============================================================================

local state = {
    todos = {},
    lastId = 0,
    selectedIndex = 1,
    viewOffset = 0,
    showCredits = false,
    mode = "normal", -- "normal" or "edit"
    editIndex = nil,
    editText = "",
    kbRow = 1,
    kbCol = 1,
    shiftActive = false,
    paletteIndex = 1
}

local joystick = nil
local fonts = {
    large = nil,
    normal = nil,
    small = nil
}

local input = {
    moveDelay = 0.15,
    moveTimer = 0,
    confirmDelay = 0.2,
    confirmTimer = 0
}

local animations = {
    selectedScale = 1.0,
    selectedTween = nil
}

local backgroundShader = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function love.load()
    -- Window setup
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {
        resizable = false,
        vsync = true
    })
    love.window.setTitle("TODO List")
    
    -- Font setup
    local fontPath = "assets/TinyUnicode.ttf"
    if love.filesystem.getInfo(fontPath) then
        fonts.large = love.graphics.newFont(fontPath, 42)
        fonts.normal = love.graphics.newFont(fontPath, 36)
        fonts.small = love.graphics.newFont(fontPath, 28)
    else
        fonts.large = love.graphics.newFont(42)
        fonts.normal = love.graphics.newFont(28)
        fonts.small = love.graphics.newFont(20)
    end
    love.graphics.setFont(fonts.normal)
    
    -- Shader setup
    backgroundShader = love.graphics.newShader [[
        extern vec3 topColor;
        extern vec3 bottomColor;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float y = screen_coords.y / 480.0;
            vec3 bgColor = mix(topColor, bottomColor, y);
            return vec4(bgColor, 1.0);
        }
    ]]
    
    -- Joystick setup
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        joystick = joysticks[1]
    end
    
    -- Load data
    local data = persistence.load()
    state.todos = data.todos or {}
    state.lastId = data.lastId or 0
    state.paletteIndex = data.paletteIndex or 1
    palette.setPalette(state.paletteIndex)
    
    -- Update shader with palette
    local p = palette.getPalette()
    backgroundShader:send("topColor", p.bg)
    backgroundShader:send("bottomColor", {p.bg[1] * 0.7, p.bg[2] * 0.7, p.bg[3] * 0.7})
    
    -- Ensure we have at least one visible item
    if #state.todos == 0 then
        state.selectedIndex = 0
    else
        state.selectedIndex = 1
    end
    
    -- Sound setup (optional - create silent stubs if files don't exist)
    local soundPath = "assets/"
    if love.filesystem.getInfo(soundPath .. "confirm.mp3") then
        sounds = {
            confirm = love.audio.newSource(soundPath .. "confirm.mp3", "static"),
            delete = love.audio.newSource(soundPath .. "delete.mp3", "static"),
            navigate = love.audio.newSource(soundPath .. "navigate.mp3", "static"),
            select = love.audio.newSource(soundPath .. "select.mp3", "static")
        }
    else
        sounds = {
            confirm = nil,
            delete = nil,
            navigate = nil,
            select = nil
        }
    end
    
    -- Start pulsing animation for selected item
    animations.selectedAlpha = 1.0
    local function pulse()
        flux.to(animations, 0.8, {selectedAlpha = 0.5}):ease("sineinout"):oncomplete(function()
            flux.to(animations, 0.8, {selectedAlpha = 0.8}):ease("sineinout"):oncomplete(pulse)
        end)
    end
    pulse()
end

-- ============================================================================
-- UPDATE AND INPUT
-- ============================================================================

function love.update(dt)
    flux.update(dt)
    
    if state.showCredits then
        return
    end
    
    -- Handle input delays
    input.moveTimer = input.moveTimer - dt
    input.confirmTimer = input.confirmTimer - dt
    
    if joystick then
        if state.mode == "normal" then
            updateNormalMode(dt)
        elseif state.mode == "edit" then
            updateEditMode(dt)
        end
    end
end

function updateNormalMode(dt)
    if input.moveTimer <= 0 then
        local dpadUp = joystick:isGamepadDown("dpup")
        local dpadDown = joystick:isGamepadDown("dpdown")
        
        if dpadUp or dpadDown then
            input.moveTimer = input.moveDelay
            
            if #state.todos > 0 then
                if dpadUp then
                    state.selectedIndex = state.selectedIndex - 1
                    if state.selectedIndex < 1 then
                        state.selectedIndex = #state.todos
                    end
                elseif dpadDown then
                    state.selectedIndex = state.selectedIndex + 1
                    if state.selectedIndex > #state.todos then
                        state.selectedIndex = 1
                    end
                end
                
                playSound(sounds.navigate)
                updateViewOffset()
            end
        end
    end
end

function updateEditMode(dt)
    if input.moveTimer <= 0 then
        local dpadLeft = joystick:isGamepadDown("dpleft")
        local dpadRight = joystick:isGamepadDown("dpright")
        local dpadUp = joystick:isGamepadDown("dpup")
        local dpadDown = joystick:isGamepadDown("dpdown")

        if dpadLeft or dpadRight or dpadUp or dpadDown then
            input.moveTimer = input.moveDelay
            moveKeyboard(dpadRight and 1 or dpadLeft and -1 or 0, dpadDown and 1 or dpadUp and -1 or 0)
            playSound(sounds.navigate)
        end
    end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function love.gamepadpressed(joystick, button)
    -- Global controls
    if button == "back" then
        state.showCredits = not state.showCredits
        return
    end
    
    if button == "start" then
        palette.nextPalette()
        state.paletteIndex = palette.currentIndex()
        persistence.save(state)
        local p = palette.getPalette()
        backgroundShader:send("topColor", p.bg)
        backgroundShader:send("bottomColor", {p.bg[1] * 0.7, p.bg[2] * 0.7, p.bg[3] * 0.7})
        return
    end
    
    if state.showCredits then
        return
    end
    
    if state.mode == "normal" then
        handleNormalInput(button)
    elseif state.mode == "edit" then
        handleEditInput(button)
    end
end

function handleNormalInput(button)
    if button == "a" and #state.todos > 0 then
        -- Toggle completion
        state.todos[state.selectedIndex].completed = not state.todos[state.selectedIndex].completed
        persistence.save(state)
        playSound(sounds.confirm)
        
    elseif button == "b" and #state.todos > 0 then
        -- Enter edit mode
        state.mode = "edit"
        state.editIndex = state.selectedIndex
        state.editText = state.todos[state.selectedIndex].text
        state.kbRow = 1
        state.kbCol = 1
        state.shiftActive = false
        playSound(sounds.select)
        
    elseif button == "x" and #state.todos > 0 then
        -- Delete todo
        table.remove(state.todos, state.selectedIndex)
        persistence.save(state)
        playSound(sounds.delete)
        
        if state.selectedIndex > #state.todos then
            state.selectedIndex = #state.todos
        end
        if state.selectedIndex < 1 then
            state.selectedIndex = 0
        end
        updateViewOffset()
        
    elseif button == "y" then
        -- Add new todo
        enterEditMode()
        playSound(sounds.select)
    end
end

function handleEditInput(button)
    if button == "b" then
        state.mode = "normal"
        playSound(sounds.navigate)
        return
    end

    if button == "a" then
        selectKeyboardKey()
    elseif button == "x" then
        deleteLastChar()
    elseif button == "y" then
        toggleShift()
    end
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function enterEditMode()
    state.mode = "edit"
    state.editIndex = nil -- New todo
    state.editText = ""
    state.kbRow = 1
    state.kbCol = 1
    state.shiftActive = false
end

function saveEditedTodo()
    local trimmedText = state.editText:match("^%s*(.-)%s*$")
    
    if trimmedText and #trimmedText > 0 then
        if state.editIndex then
            -- Edit existing
            state.todos[state.editIndex].text = trimmedText
        else
            -- Create new
            state.lastId = state.lastId + 1
            table.insert(state.todos, {
                id = state.lastId,
                text = trimmedText,
                completed = false
            })
            state.selectedIndex = #state.todos
        end
        
        persistence.save(state)
        updateViewOffset()
    end
end

local function getKeyboardLayout()
    return state.shiftActive and keyboardLayouts.shift or keyboardLayouts.normal
end

local function getKeyboardKey()
    local layout = getKeyboardLayout()
    return layout[state.kbRow][state.kbCol] or ""
end

local function appendCharacter(char)
    if #state.editText < MAX_TODO_LENGTH then
        state.editText = state.editText .. char
        playSound(sounds.select)
    end
end

function deleteLastChar()
    if #state.editText > 0 then
        state.editText = state.editText:sub(1, -2)
        playSound(sounds.delete)
    end
end

function toggleShift()
    state.shiftActive = not state.shiftActive
    playSound(sounds.navigate)
end

function moveKeyboard(dx, dy)
    local layout = getKeyboardLayout()
    if dy ~= 0 then
        state.kbRow = math.min(#layout, math.max(1, state.kbRow + dy))
        local rowCount = #layout[state.kbRow]
        state.kbCol = math.min(rowCount, state.kbCol)
    end

    if dx ~= 0 then
        local rowCount = #layout[state.kbRow]
        state.kbCol = math.min(rowCount, math.max(1, state.kbCol + dx))
    end
end

function selectKeyboardKey()
    local key = getKeyboardKey()
    if key == "" then
        return
    elseif key == "SHIFT" then
        toggleShift()
    elseif key == "BACK" then
        deleteLastChar()
    elseif key == "SPACE" then
        appendCharacter(" ")
    elseif key == "DONE" then
        saveEditedTodo()
        state.mode = "normal"
        playSound(sounds.confirm)
    else
        appendCharacter(key)
    end
end

function updateViewOffset()
    if #state.todos == 0 then
        state.viewOffset = 0
        return
    end
    
    local itemStart = state.viewOffset + 1
    local itemEnd = state.viewOffset + VISIBLE_ITEMS
    
    if state.selectedIndex < itemStart then
        state.viewOffset = state.selectedIndex - 1
    elseif state.selectedIndex > itemEnd then
        state.viewOffset = state.selectedIndex - VISIBLE_ITEMS
    end
end

function playSound(sound)
    if sound then
        if sound:isPlaying() then
            sound:stop()
        end
        sound:play()
    end
end

-- ============================================================================
-- DRAWING
-- ============================================================================

function love.draw()
    local p = palette.getPalette()
    
    -- Draw background with shader
    love.graphics.setShader(backgroundShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setShader()
    
    love.graphics.setColor(p.text)
    
    if state.showCredits then
        draw.drawCredits(p, fonts)
    else
        draw.drawMain(state, fonts, p, getKeyboardLayout, animations)
    end
end
