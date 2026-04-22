-- Palette system for TODO app
-- Each palette contains: bg, text, highlight, selected, completed, accent

local palettes = {
    -- Palette 1: Dark Purple (Default)
    {
        name = "Dark Purple",
        bg = { 0.08, 0.04, 0.12 },
        text = { 0.9, 0.9, 0.95 },
        highlight = { 0.3, 0.2, 0.5 },
        selected = { 0.7, 0.4, 0.9 },
        completed = { 0.5, 0.5, 0.5 },
        accent = { 0.8, 0.3, 0.7 }
    },
    -- Palette 2: Dark Green
    {
        name = "Dark Green",
        bg = { 0.05, 0.1, 0.08 },
        text = { 0.85, 0.95, 0.85 },
        highlight = { 0.2, 0.4, 0.3 },
        selected = { 0.3, 0.8, 0.5 },
        completed = { 0.4, 0.6, 0.4 },
        accent = { 0.2, 0.9, 0.5 }
    },
    -- Palette 3: Dark Blue
    {
        name = "Dark Blue",
        bg = { 0.05, 0.08, 0.15 },
        text = { 0.8, 0.9, 1.0 },
        highlight = { 0.15, 0.25, 0.45 },
        selected = { 0.3, 0.6, 1.0 },
        completed = { 0.3, 0.5, 0.7 },
        accent = { 0.0, 0.7, 1.0 }
    },
    -- Palette 4: Dark Red
    {
        name = "Dark Red",
        bg = { 0.12, 0.05, 0.06 },
        text = { 0.95, 0.85, 0.8 },
        highlight = { 0.4, 0.15, 0.15 },
        selected = { 0.85, 0.4, 0.4 },
        completed = { 0.6, 0.3, 0.3 },
        accent = { 1.0, 0.3, 0.3 }
    },
    -- Palette 5: High Contrast Light
    {
        name = "High Contrast",
        bg = { 0.95, 0.95, 0.95 },
        text = { 0.1, 0.1, 0.1 },
        highlight = { 0.8, 0.8, 0.9 },
        selected = { 0.2, 0.4, 0.9 },
        completed = { 0.7, 0.7, 0.7 },
        accent = { 0.9, 0.2, 0.2 }
    }
}

-- Current palette index
local currentPalette = 1

local function getPalette()
    return palettes[currentPalette]
end

local function getPaletteCount()
    return #palettes
end

local function nextPalette()
    currentPalette = (currentPalette % #palettes) + 1
    return getPalette()
end

local function setPalette(index)
    if index >= 1 and index <= #palettes then
        currentPalette = index
        return getPalette()
    end
    return getPalette()
end

return {
    palettes = palettes,
    getPalette = getPalette,
    getPaletteCount = getPaletteCount,
    nextPalette = nextPalette,
    setPalette = setPalette,
    currentIndex = function() return currentPalette end
}
