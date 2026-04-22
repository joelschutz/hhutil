-- Rendering module for TODO app

local draw = {}

local SCREEN_WIDTH = 640
local SCREEN_HEIGHT = 480
local MAX_TODO_LENGTH = 60
local ITEM_HEIGHT = 44
local PADDING = 18
local VISIBLE_ITEMS = 8
local TOOLBAR_HEIGHT = 30

local function getKeyboardLayout(state, keyboardLayouts)
    return state.shiftActive and keyboardLayouts.shift or keyboardLayouts.normal
end

function draw.drawMain(state, fonts, p, getKeyboardLayout, animations)
    love.graphics.setColor(p.highlight)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, TOOLBAR_HEIGHT)
    love.graphics.setColor(p.text)
    love.graphics.setFont(fonts.small)
    local title = state.mode == "edit" and (state.editIndex and "Edit Mode" or "Add Mode") or "List Mode"
    love.graphics.printf(title, 0, 4, SCREEN_WIDTH, "center")

    if state.mode == "edit" then
        draw.drawEditMode(state, fonts, p, getKeyboardLayout)
    else
        draw.drawNormalMode(state, fonts, p, animations)
    end
end

function draw.drawNormalMode(state, fonts, p, animations)
    love.graphics.setFont(fonts.normal)

    if #state.todos == 0 then
        love.graphics.setColor(p.completed)
        love.graphics.printf("No todos yet. Press Y to add one.", PADDING, 150, SCREEN_WIDTH - 2 * PADDING, "center")
    else
        for i = 1, math.min(VISIBLE_ITEMS, #state.todos - state.viewOffset) do
            local todoIdx = state.viewOffset + i
            local todo = state.todos[todoIdx]
            local yPos = TOOLBAR_HEIGHT + PADDING + (i - 1) * ITEM_HEIGHT

            if todoIdx == state.selectedIndex then
                love.graphics.setColor(p.selected[1], p.selected[2], p.selected[3], animations.selectedAlpha)
                love.graphics.rectangle("fill", PADDING, yPos, SCREEN_WIDTH - 2 * PADDING, ITEM_HEIGHT - 5, 12, 12)
            end

            love.graphics.setColor(p.text)
            local prefix = todo.completed and "✓ " or "  "
            love.graphics.printf(prefix .. todo.text, PADDING + 10, yPos, SCREEN_WIDTH - 2 * PADDING - 20, "left")

            if todo.completed then
                local prefixWidth = fonts.normal:getWidth(prefix)
                local textWidth = fonts.normal:getWidth(todo.text)
                local lineY = yPos + fonts.normal:getHeight() * 0.55
                love.graphics.setColor(p.completed)
                love.graphics.setLineWidth(3)
                love.graphics.line(PADDING + 10 + prefixWidth, lineY, PADDING + 10 + prefixWidth + textWidth, lineY)
            end
        end
    end

    love.graphics.setFont(fonts.small)
    local bgBrightness = (p.bg[1] + p.bg[2] + p.bg[3]) / 3
    local helpColor = bgBrightness > 0.7 and {0.15, 0.15, 0.15} or p.completed
    love.graphics.setColor(helpColor)
    local helpY = SCREEN_HEIGHT - 25
    love.graphics.printf("Y:Add  B:Edit  X:Del  A:Done  START:Palette", 5, helpY, SCREEN_WIDTH - 10, "left")
end

function draw.drawEditMode(state, fonts, p, getKeyboardLayout)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, TOOLBAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - TOOLBAR_HEIGHT)

    local boxX = PADDING
    local boxY = 70
    local boxW = SCREEN_WIDTH - 2 * PADDING
    local boxH = 120

    love.graphics.setColor(p.highlight)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)
    love.graphics.setColor(p.selected)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH)

    love.graphics.setFont(fonts.normal)
    love.graphics.setColor(p.text)
    local textDisplay = state.editText
    if #textDisplay < MAX_TODO_LENGTH then
        textDisplay = textDisplay .. "_"
    end
    love.graphics.printf(textDisplay, boxX + 12, boxY + 28, boxW - 24, "left")
    love.graphics.setFont(fonts.small)
    love.graphics.printf(#state.editText .. "/" .. MAX_TODO_LENGTH, boxX + 12, boxY + 70, boxW - 24, "left")

    local layout = getKeyboardLayout()
    local keyGap = 6
    local keyH = 42
    local keyboardTop = boxY + boxH + 14

    local bgBrightness = (p.bg[1] + p.bg[2] + p.bg[3]) / 3
    local defaultKeyBg = bgBrightness > 0.7 and {0.92, 0.92, 0.92} or {0.18, 0.18, 0.18}

    for r = 1, #layout do
        local row = layout[r]
        local rowCount = #row
        local keyW = (SCREEN_WIDTH - 2 * PADDING - keyGap * (rowCount - 1)) / rowCount

        for c = 1, rowCount do
            local key = row[c]
            local x = PADDING + (c - 1) * (keyW + keyGap)
            local y = keyboardTop + (r - 1) * (keyH + keyGap)

            if key ~= "" then
                local keyFill = (state.kbRow == r and state.kbCol == c) and p.selected or defaultKeyBg
                love.graphics.setColor(keyFill)
                love.graphics.rectangle("fill", x, y, keyW, keyH, 6, 6)

                local keyTextColor = ((keyFill[1] + keyFill[2] + keyFill[3]) / 3) < 0.65 and {1, 1, 1} or {0, 0, 0}
                love.graphics.setColor(keyTextColor)
                love.graphics.setFont(fonts.small)

                local keyLabel = key
                if key == "SHIFT" then
                    keyLabel = "SHIFT " .. (state.shiftActive and "¾" or "½")
                end

                love.graphics.printf(keyLabel, x + 4, y + 6, keyW - 8, "center")
            end
        end
    end

    love.graphics.setFont(fonts.small)
    love.graphics.setColor(p.text)
    local instructionsY = keyboardTop + #layout * (keyH + keyGap) + 6
    love.graphics.printf("Y: Shift  A: Select  X: Backspace  B: Cancel", boxX + 12, instructionsY, boxW - 24, "left")
end

function draw.drawCredits(p, fonts)
    love.graphics.setColor(p.highlight)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, TOOLBAR_HEIGHT)
    love.graphics.setColor(p.text)
    love.graphics.setFont(fonts.small)
    love.graphics.printf("Credits", 0, 4, SCREEN_WIDTH, "center")

    love.graphics.setFont(fonts.large)
    love.graphics.setColor(p.text)
    love.graphics.printf("TODO List", 0, 80, SCREEN_WIDTH, "center")

    love.graphics.setFont(fonts.normal)
    local creditText = [[
A minimalist TODO app for handheld consoles

Built with LÖVE 2D
Created by joelschutz

Press SELECT to return]]

    love.graphics.printf(creditText, PADDING, 150, SCREEN_WIDTH - 2 * PADDING, "center")
end

return draw
