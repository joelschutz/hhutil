-- =========================================================
--  HABIT TRACKER  •  Love2D  •  Gamepad-Controlled
-- =========================================================
--
--  Gamepad controls:
--    DPad Left / Right   → Navigate days (1 day step)
--    DPad Up   / Down    → Navigate rows (week/column step)
--    LB / RB             → Switch habit
--    A                   → Annotate selected day (toggle / +1)
--    B                   → Cycle visualization mode
--    X                   → Edit current habit
--    Y                   → Create new habit
--
--  Keyboard fallback (all screens):
--    Arrow keys    → DPad
--    Q / E         → LB / RB
--    Enter/Space   → A
--    Escape        → B / Cancel
--    Z             → X  (edit)
--    C             → Y  (new)
--
--  Requires Love2D 11.x or newer.
--  Run with:  love .   (inside the folder containing main.lua)
-- =========================================================

local W, H        = 640, 480

-- ─── Palette ──────────────────────────────────────────────
local P           = {
    bg      = { 0.09, 0.10, 0.13 },
    surface = { 0.14, 0.15, 0.20 },
    surfHi  = { 0.19, 0.21, 0.29 },
    border  = { 0.27, 0.29, 0.40 },
    green   = { 0.28, 0.84, 0.54 },
    amber   = { 0.95, 0.60, 0.20 },
    yellow  = { 0.98, 0.88, 0.22 },
    blue    = { 0.32, 0.64, 0.98 },
    red     = { 0.90, 0.35, 0.35 },
    text    = { 0.92, 0.93, 0.96 },
    mid     = { 0.58, 0.60, 0.67 },
    dim     = { 0.33, 0.35, 0.44 },
    dotOff  = { 0.19, 0.21, 0.30 },
}

-- ─── Global state ─────────────────────────────────────────
local habits      = {}     -- array of habit objects
local selHabit    = 1      -- index into habits[]
local selDay      = 0      -- 0=today, -1=yesterday, …
local vizMode     = 1      -- 1=weekly, 2=monthly, 3=yearly
local screen      = "main" -- "main" | "create" | "edit"
local form        = {}     -- form state when creating/editing
local tabOffset   = 0      -- for tab scrolling

-- ─── Viz constants ────────────────────────────────────────
local VIZ_LABELS  = { "Weekly", "Monthly", "Yearly" }
local VIZ_DAYS    = { 7, 30, 365 }
local VIZ_COLS    = { 7, 10, 53 }
local VIZ_ROWS    = { 1, 3, 7 }

local MONTH_NAMES = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local DAY_ABBR    = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }

-- ─── Fonts ────────────────────────────────────────────────
local fTN, fXS, fSM, fMD, fXL

-- ─── Sound ────────────────────────────────────────────────
local music       = love.audio.newSource("assets/ChillLofiR.mp3", "stream")
local sfx         = love.audio.newSource("assets/pepSound2.mp3", "static")

-- ─── Serializer (pure Lua, no deps) ──────────────────────
local function ser(v)
    if type(v) == "table" then
        local parts = {}
        for k, val in pairs(v) do
            local key = type(k) == "string"
                and ('["' .. k:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"]')
                or ("[" .. tostring(k) .. "]")
            parts[#parts + 1] = key .. "=" .. ser(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then
        return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    else
        return tostring(v)
    end
end

-- ─── Persistence ──────────────────────────────────────────
local function saveHabits()
    love.filesystem.write("habits.dat", ser(habits))
end

local function loadHabits()
    if love.filesystem.getInfo("habits.dat") then
        local ok, data = pcall(function()
            local s = love.filesystem.read("habits.dat")
            return (load("return " .. s))()
        end)
        if ok and type(data) == "table" then
            habits = data
            return
        end
    end
    -- Default sample habits
    habits = {
        { name = "Exercise",     htype = "binary",  scale = "more", target = 1, entries = {} },
        { name = "Water (cups)", htype = "numeric", scale = "more", target = 8, entries = {} },
        { name = "Screen time",  htype = "numeric", scale = "less", target = 2, entries = {} },
    }
end

-- ─── Date helpers ─────────────────────────────────────────
local function ts(off)
    return os.time() + (off or 0) * 86400
end

local function dkey(off)
    local d = os.date("*t", ts(off))
    return ("%04d-%02d-%02d"):format(d.year, d.month, d.day)
end

local function getVal(h, off)
    return h.entries[dkey(off)] or 0
end

local function setVal(h, off, v)
    h.entries[dkey(off)] = (v and v > 0) and v or nil
    saveHabits()
end

local function annotate(h, off)
    local cur = getVal(h, off)
    if h.htype == "binary" then
        setVal(h, off, cur == 0 and 1 or 0)
    else
        setVal(h, off, cur + 1)
    end
end

-- ─── Metrics ──────────────────────────────────────────────
local function calcStreak(h)
    local s = 0
    while s < 366 and getVal(h, -s) > 0 do s = s + 1 end
    return s
end

local function calcAverage(h, days)
    local sum, cnt = 0, 0
    for i = 0, days - 1 do
        local v = getVal(h, -i)
        if v > 0 then
            sum = sum + v; cnt = cnt + 1
        end
    end
    if h.htype == "binary" then
        return cnt / days
    else
        return cnt > 0 and sum / cnt or 0
    end
end

-- ─── Draw utilities ───────────────────────────────────────
local function setCol(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function fillRect(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r or 0)
end

local function strokeRect(x, y, w, h, r)
    love.graphics.rectangle("line", x, y, w, h, r or 0)
end

-- Interpolate two palette colors by t ∈ [0,1]
local function lerpCol(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

-- Dot fill color for a habit entry
local function dotColor(h, off)
    local v = getVal(h, off)
    if v == 0 then return P.dotOff end
    if h.htype == "binary" then return P.green end
    -- numeric
    local t = h.target or 1
    local ratio = v / t
    if h.scale == "more" then
        if ratio >= 1 then
            return P.green
        else
            return lerpCol(P.yellow, P.green, ratio)
        end
    else -- less
        if ratio <= 1 then
            return P.green
        else
            return lerpCol(P.green, P.red, math.min(ratio - 1, 1))
        end
    end
end

-- ─── Grid renderers ───────────────────────────────────────

-- Weekly: 7 large dots in a single row
local function drawGridWeekly(h, gx, gy, gw, gh)
    local spacing = gw / 7
    local cy = gy + gh * 0.46
    local dotR = math.min(spacing * 0.36, 38)

    for i = 0, 6 do
        local off   = -(6 - i) -- i=0 → 6 days ago; i=6 → today
        local cx    = gx + i * spacing + spacing * 0.5
        local dc    = dotColor(h, off)
        local di    = os.date("*t", ts(off))
        local isSel = off == selDay

        -- Selection glow
        if isSel then
            setCol(P.yellow, 0.25)
            love.graphics.circle("fill", cx, cy, dotR + 14)
            setCol(P.yellow, 0.80)
            love.graphics.circle("fill", cx, cy, dotR + 6)
        end

        -- Dot
        setCol(dc)
        love.graphics.circle("fill", cx, cy, dotR)

        -- Value inside dot
        local v = getVal(h, off)
        if v > 0 then
            love.graphics.setFont(fMD)
            setCol(P.bg, 0.9)
            love.graphics.printf(
                h.htype == "binary" and "✓" or tostring(v),
                cx - spacing * 0.45 + 2, cy - 17, spacing * 0.9, "center")
        end

        -- Day abbreviation below
        love.graphics.setFont(fSM)
        setCol(isSel and P.yellow or P.mid)
        love.graphics.printf(DAY_ABBR[di.wday],
            cx - spacing * 0.45, cy + dotR + 9, spacing * 0.9, "center")

        -- Date above
        love.graphics.setFont(fXS)
        setCol(isSel and P.mid or P.dim)
        love.graphics.printf(
            ("%d/%d"):format(di.day, di.month),
            cx - spacing * 0.45, cy - dotR - 40, spacing * 0.9, "center")
    end
end

-- Monthly: 10 × 3 rolling grid (30 days)
local function drawGridMonthly(h, gx, gy, gw, gh)
    local cols, rows = VIZ_COLS[2], VIZ_ROWS[2]
    local spX = gw / cols
    local spY = gh / rows
    local dotR = math.min(math.min(spX, spY) * 0.36, 22)

    for i = 0, VIZ_DAYS[2] - 1 do
        local off   = -(VIZ_DAYS[2] - 1 - i)
        local c     = i % cols
        local r     = math.floor(i / cols)
        local cx    = gx + c * spX + spX * 0.5
        local cy    = gy + r * spY + spY * 0.5
        local isSel = off == selDay

        if isSel then
            setCol(P.yellow, 0.22)
            love.graphics.circle("fill", cx, cy, dotR + 12)
            setCol(P.yellow, 0.82)
            love.graphics.circle("fill", cx, cy, dotR + 5)
        end

        setCol(dotColor(h, off))
        love.graphics.circle("fill", cx, cy, dotR)

        -- Show numeric value if > 1
        local v = getVal(h, off)
        if v > 1 then
            love.graphics.setFont(fXS)
            setCol(P.bg, 0.85)
            love.graphics.printf(tostring(v), cx - 13, cy - 15, 28, "center")
        end

        -- Dot border for binary done
        if h.htype == "binary" and v > 0 then
            setCol(P.green, 0.5)
            love.graphics.circle("line", cx, cy, dotR)
        end
    end
end

-- Yearly: GitHub-style 53-week heatmap
local function drawGridYearly(h, gx, gy, gw, gh)
    local cols, rows = VIZ_COLS[3], VIZ_ROWS[3]
    local spX = gw / cols
    local spY = gh / rows
    local dotR = math.min(spX, spY) * 0.4

    -- Month labels
    love.graphics.setFont(fTN)
    setCol(P.dim)
    local lastMonth = -1
    for i = 0, 364 do
        local off = -(364 - i)
        local di  = os.date("*t", ts(off))
        if di.month ~= lastMonth and i % 7 == 0 then
            local wc = math.floor(i / 7)
            love.graphics.print(MONTH_NAMES[di.month], gx + wc * spX, gy - 16)
            lastMonth = di.month
        end
    end

    -- Weekday labels on the left
    local wdLabels = { "S", "M", "T", "W", "T", "F", "S" }
    for r = 0, 6 do
        setCol(P.dim)
        love.graphics.print(wdLabels[r + 1], gx - 14, gy + r * spY + spY * 0.3 - 9)
    end

    -- Dots
    for i = 0, 364 do
        local off   = -(364 - i)
        local wc    = math.floor(i / 7)
        local dr    = i % 7
        local cx    = gx + wc * spX + spX * 0.5
        local cy    = gy + dr * spY + spY * 0.5
        local isSel = off == selDay

        if isSel then
            setCol(P.yellow, 0.90)
            love.graphics.circle("fill", cx, cy, dotR + 3)
        end

        setCol(dotColor(h, off))
        love.graphics.circle("fill", cx, cy, dotR)
    end
end

local function drawGrid(h, gx, gy, gw, gh)
    if vizMode == 1 then
        drawGridWeekly(h, gx, gy, gw, gh)
    elseif vizMode == 2 then
        drawGridMonthly(h, gx, gy, gw, gh)
    else
        drawGridYearly(h, gx, gy, gw, gh)
    end
end

-- ─── Summary panel ────────────────────────────────────────
local function drawSummary(h, sx, sy, sw, sh)
    local px = sx + 22
    local py = sy + 8

    -- Habit name
    love.graphics.setFont(fXL)
    setCol(P.green)
    love.graphics.print(h.name, px, py)
    py = py + 52

    -- Type / scale chips
    love.graphics.setFont(fXS)
    local function chip(lbl, x, y, tc)
        setCol(P.surfHi)
        fillRect(x, y, 80, 30, 4)
        setCol(tc)
        love.graphics.printf(lbl, x, y, 80, "center")
    end
    chip(h.htype == "binary" and "Binary" or "Numeric", px, py, P.blue)
    chip(h.scale == "more" and "↑ More" or "↓ Less", px + 88, py,
        h.scale == "more" and P.green or P.amber)
    py = py + 40

    -- Section helper
    local function section(lbl, value, vc)
        love.graphics.setFont(fXS)
        setCol(P.dim)
        love.graphics.print(lbl, px, py)
        py = py + 18
        love.graphics.setFont(fXL)
        setCol(vc or P.text)
        love.graphics.print(value, px, py)
        py = py + (52)
    end

    -- Selected day
    local di = os.date("*t", ts(selDay))
    local dayStr = selDay == 0 and "Today"
        or selDay == -1 and "Yesterday"
        or ("%s %d %s"):format(DAY_ABBR[di.wday], di.day, MONTH_NAMES[di.month])
    section("SELECTED DAY", dayStr)

    -- Annotation
    local v = getVal(h, selDay)
    local valStr, valCol
    if h.htype == "binary" then
        valStr = v > 0 and "✓ Done" or "x Not done"
        valCol = v > 0 and P.green or P.dim
    else
        valStr = tostring(v)
        valCol = v > 0 and P.green or P.dim
    end
    section("ANNOTATION", valStr, valCol)

    -- Average
    local avg = calcAverage(h, VIZ_DAYS[vizMode])
    local avgStr = h.htype == "binary"
        and ("%.0f%%"):format(avg * 100)
        or ("%.1f"):format(avg)
    section("AVG  (" .. VIZ_LABELS[vizMode]:upper() .. ")", avgStr)

    -- Streak
    local sk = calcStreak(h)
    section("STREAK", sk .. (sk == 1 and " day" or " days"),
        sk > 0 and P.amber or P.dim)
end

-- ─── Form overlay ─────────────────────────────────────────
local FORM_FIELD_NAMES = { "Name", "Type", "Scale", "Target", "── Save ──" }

local keyboard = {
    { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
    { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" },
    { "a", "s", "d", "f", "g", "h", "j", "k", "l", "↑" },
    { "z", "x", "c", "v", "b", "n", "m", " ", "<", "OK" },
}

local keyboardShift = {
    { "!", "@", "#", "$", "%", "^", "*", "&", "(", ")" },
    { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" },
    { "A", "S", "D", "F", "G", "H", "J", "K", "L", "↑" },
    { "Z", "X", "C", "V", "B", "N", "M", " ", "<", "OK" },
}

local keyb = keyboard
local shift = false

local function formValueStr(i)
    if i == 1 then return form.name ~= "" and form.name or "(enter name)" end
    if i == 2 then return form.htype == 1 and "Binary" or "Numeric" end
    if i == 3 then return form.scale == 1 and "More is Better  ↑" or "Less is Better  ↓" end
    if i == 4 then return form.target or "1" end
    return ""
end

local function drawForm()
    -- Scrim
    setCol({ 0, 0, 0 }, 0.72)
    love.graphics.rectangle("fill", 0, 0, W, H)

    local fw, fh = 500, 390
    local fx = (W - fw) / 2
    local fy = (H - fh) / 2

    -- Card background
    setCol(P.surface)
    fillRect(fx, fy, fw, fh, 10)
    setCol(P.border)
    strokeRect(fx, fy, fw, fh, 10)

    -- Title
    love.graphics.setFont(fXL)
    setCol(P.green)
    love.graphics.print(screen == "edit" and "Edit Habit" or "New Habit", fx + 24, fy)
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print(screen == "edit" and "Modify the habit properties below." or
        "Fill in the details and press Save.", fx + 24, fy + 30)

    -- Fields (Name, Type+Target, Scale, Save)
    -- Name field
    local iy1 = fy + 78
    local isSel1 = form.field == 1
    setCol({ 0.12, 0.13, 0.18 })
    fillRect(fx + 20, iy1, fw - 40, 54, 7)
    if isSel1 then
        setCol(P.green, 0.18)
        fillRect(fx + 20, iy1, fw - 40, 54, 7)
        setCol(P.green, 0.55)
        strokeRect(fx + 20, iy1, fw - 40, 54, 7)
    end
    local iylabel1 = iy1 - 7
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print("Name", fx + 32, iylabel1 + 7)
    love.graphics.setFont(fMD)
    if form.field == 1 and form.inputting then
        setCol(P.yellow)
        love.graphics.print(form.name .. "|", fx + 32, iylabel1 + 26)
    else
        setCol(isSel1 and P.text or P.mid)
        love.graphics.print(formValueStr(1), fx + 32, iylabel1 + 26)
    end
    if isSel1 and not form.inputting then
        love.graphics.setFont(fXS)
        setCol(P.dim)
        love.graphics.print("[A] to type", fx + fw - 120, iylabel1 + 28)
    end

    -- Type + Target row
    local iy2 = fy + 78 + 68
    local fieldW = (fw - 40 - 8) / 2
    local leftX = fx + 20
    local rightX = leftX + fieldW + 8

    -- Type field (left)
    local isSel2 = form.field == 2
    setCol({ 0.12, 0.13, 0.18 })
    fillRect(leftX, iy2, fieldW, 54, 7)
    if isSel2 then
        setCol(P.green, 0.18)
        fillRect(leftX, iy2, fieldW, 54, 7)
        setCol(P.green, 0.55)
        strokeRect(leftX, iy2, fieldW, 54, 7)
    end
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print("Type", leftX + 12, iy2 - 7 + 7)
    love.graphics.setFont(fMD)
    setCol(isSel2 and P.text or P.mid)
    love.graphics.print(form.htype == 1 and "Binary" or "Numeric", leftX + 12, iy2 - 7 + 26)
    if isSel2 then
        love.graphics.setFont(fXS)
        setCol(P.dim)
        love.graphics.print("< > to toggle", fx + fw - 155, iy2 - 7 + 28)
    end

    -- Target field (right)
    local isSel4 = form.field == 3
    local targetActive = form.htype == 2
    setCol({ 0.12, 0.13, 0.18 })
    fillRect(rightX, iy2, fieldW, 54, 7)
    if isSel4 then
        setCol(P.green, 0.18)
        fillRect(rightX, iy2, fieldW, 54, 7)
        setCol(P.green, 0.55)
        strokeRect(rightX, iy2, fieldW, 54, 7)
    end
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print("Target", rightX + 12, iy2 - 7 + 7)
    love.graphics.setFont(fMD)
    if targetActive then
        setCol(isSel4 and P.text or P.mid)
        love.graphics.print(form.target or "1", rightX + 12, iy2 - 7 + 26)
        if isSel4 then
            love.graphics.setFont(fXS)
            setCol(P.dim)
            love.graphics.print("< > to change", rightX + fieldW - 120, iy2 - 7 + 28)
        end
    else
        setCol(P.mid)
        love.graphics.print("-", rightX + 12, iy2 - 7 + 26)
    end

    -- Scale field (full width)
    local iy3 = fy + 78 + 2 * 68
    local isSel3 = form.field == 4
    setCol({ 0.12, 0.13, 0.18 })
    fillRect(fx + 20, iy3, fw - 40, 54, 7)
    if isSel3 then
        setCol(P.green, 0.18)
        fillRect(fx + 20, iy3, fw - 40, 54, 7)
        setCol(P.green, 0.55)
        strokeRect(fx + 20, iy3, fw - 40, 54, 7)
    end
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print("Scale", fx + 32, iy3 - 7 + 7)
    love.graphics.setFont(fMD)
    setCol(isSel3 and P.text or P.mid)
    love.graphics.print(formValueStr(3), fx + 32, iy3 - 7 + 26)
    if isSel3 then
        love.graphics.setFont(fXS)
        setCol(P.dim)
        love.graphics.print("< > to toggle", fx + fw - 155, iy3 - 7 + 28)
    end

    -- Confirm button (Save)
    local iy4 = fy + 78 + 3 * 68
    local isSel5 = form.field == 5
    setCol(isSel5 and P.green or P.surfHi)
    fillRect(fx + 20, iy4, fw - 40, 48, 8)
    love.graphics.setFont(fMD)
    setCol(isSel5 and P.bg or P.mid)
    love.graphics.printf("Save Habit  [A]", fx + 20, iy4 + 7, fw - 40, "center")

    -- Footer hint
    love.graphics.setFont(fXS)
    setCol(P.dim)
    love.graphics.print("↑↓ Navigate fields  •  A Select / Confirm  •  B Cancel",
        fx + 20, fy + fh - 36)

    -- Virtual keyboard (name only)
    if form.inputting and form.field == 1 then
        local kbX = fx + 20
        local kbY = fy + fh - 120
        local keyW, keyH = 24, 24
        fillRect(kbX - 5, kbY - 18, keyW * 11 + 4, keyH * 5 + 5, 4)
        for r, row in ipairs(keyb) do
            for c, key in ipairs(row) do
                local kx = kbX + (c - 1) * 26
                local ky = kbY + (r - 1) * 26
                setCol(P.surfHi)
                fillRect(kx, ky, keyW, keyH, 4)
                if r == form.kbRow and c == form.kbCol then
                    setCol(P.green, 0.5)
                    fillRect(kx, ky, keyW, keyH, 4)
                end
                love.graphics.setFont(fXS)
                setCol(P.text)
                love.graphics.printf(key, kx, ky - 4, keyW, "center")
            end
        end
        love.graphics.setFont(fXS)
        setCol(P.mid)
        love.graphics.print("Select: Dpad | Press: A | OK: B", fx + 20, kbY - 24)
    end
end

-- ─── love.load ────────────────────────────────────────────
function love.load()
    love.window.setMode(W, H, { resizable = false, vsync = true })
    love.window.setTitle("Habit Tracker")
    love.graphics.setLineWidth(1.5)

    fTN = love.graphics.newFont("assets/TinyUnicode.ttf", 20)
    fXS = love.graphics.newFont("assets/TinyUnicode.ttf", 30)
    fSM = love.graphics.newFont("assets/TinyUnicode.ttf", 32)
    fMD = love.graphics.newFont("assets/TinyUnicode.ttf", 34)
    fXL = love.graphics.newFont("assets/TinyUnicode.ttf", 46)

    loadHabits()

    music:setLooping(true)
    music:setVolume(0.1)
    music:play()
end

-- ─── love.draw ────────────────────────────────────────────
function love.draw()
    setCol(P.bg)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- ── Determine safe habit index ──────────────────────
    selHabit = math.max(1, math.min(selHabit, math.max(#habits, 1)))

    -- ── Empty state ──────────────────────────────────────
    if #habits == 0 then
        love.graphics.setFont(fMD)
        setCol(P.mid)
        love.graphics.printf(
            "No habits yet!\n\nPress  [Y]  to create your first habit.",
            0, H / 2 - 32, W, "center")
        -- Still allow form overlay
        if screen == "create" or screen == "edit" then drawForm() end
        return
    end

    local h = habits[selHabit]

    setCol(P.surface)
    fillRect(0, 0, W, 40)

    -- Habit tabs
    local maxTabs = 4
    local tabW = math.min(360, (W * 0.85 - 12) / maxTabs - 4)
    love.graphics.setFont(fMD)
    local visible = math.min(maxTabs, math.max(0, #habits - tabOffset))
    for i = 1, visible do
        local idx = tabOffset + i
        local hh = habits[idx]
        local tx = 16 + (i - 1) * (tabW + 5)
        if idx == selHabit then
            setCol(P.green); fillRect(tx, 5, tabW, 30, 7)
            setCol(P.bg)
        else
            setCol(P.surfHi); fillRect(tx, 5, tabW, 30, 7)
            setCol(P.mid)
        end
        -- Truncate name to fit tab
        local nm = hh.name
        local maxW = tabW - 14
        while love.graphics.getFont():getWidth(nm) > maxW and #nm > 1 do
            nm = nm:sub(1, -2)
        end
        if nm ~= hh.name then nm = nm .. "…" end
        love.graphics.print(nm, tx + 8, 3)
    end
    if tabOffset > 0 then
        love.graphics.setFont(fSM)
        setCol(P.dim)
        love.graphics.print("<", 7, 3)
    end
    local hidden = #habits - (tabOffset + visible)
    if hidden > 0 then
        love.graphics.setFont(fSM)
        setCol(P.dim)
        love.graphics.print("+" .. hidden .. " more", 18 + visible * (tabW + 5), 3)
    end


    -- ── Grid panel ───────────────────────────────────────
    local gx, gy = 14, 64
    local gw = math.floor(W * 0.60)
    local gh = H - gy - 100

    setCol(P.surface)
    fillRect(gx, gy, gw, gh - 110, 8)

    -- Panel title
    love.graphics.setFont(fSM)
    setCol(P.mid)
    love.graphics.print(VIZ_LABELS[vizMode] .. " View", gx + 16, gy + 10)

    -- Grid inner bounds
    local padH = 18
    local gridX = gx + padH
    local gridW = gw - padH * 2
    local gridY = gy + 34
    local gridH = gh - 156
    if vizMode == 3 then
        gridY = gy + 50 -- extra room for month labels
        gridH = gridH - 16
        gridX = gx + 28 -- room for weekday labels
        gridW = gw - 28 - padH
    end

    drawGrid(h, gridX, gridY, gridW, gridH)

    -- ── Summary panel ────────────────────────────────────
    local sx = gx + gw + 10
    local sw = W - sx - 14

    setCol(P.surface)
    fillRect(sx, gy, sw, gh + 70, 8)
    drawSummary(h, sx, gy, sw, gh)

    if screen == "create" or screen == "edit" then
        -- ── Form overlay ─────────────────────────────────────
        drawForm()
    else
        -- ── Control hints ────────────────────────────────────
        local hx = gx
        local hy = gridY + gridH + 25
        local hw = gw
        setCol(P.surface)
        fillRect(hx, hy, hw, 50, 8)
        love.graphics.setFont(fXS)
        setCol(P.dim)
        local hints = {
            "[DPad]:Navigate [A]:Annotate [B]:Cycle View",
            "[LB/RB]:Switch Habit [X]:Edit [Y]:New",
        }
        for i, hint in ipairs(hints) do
            love.graphics.printf(hint, hx, hy + (i - 1) * 16, hw, "center")
        end
        -- ── Credits ───────────────────────────────────────────
        hy = hy + 60
        setCol(P.surface)
        fillRect(hx, hy, hw, 108, 8)
        love.graphics.setFont(fXS)
        setCol(P.dim)
        local hints = {
            "Habit Tracker",
            "Created by KaMiSaMa",
            "Music by omfgdude",
            "SFX by Kenney",
            "",
            "Made with LOVE",
        }
        for i, hint in ipairs(hints) do
            love.graphics.printf(hint, hx, hy + (i - 1) * 16, hw, "center")
        end
    end
end

-- ─── Action helpers ───────────────────────────────────────
local function openCreate()
    form = { field = 1, name = "", htype = 1, scale = 1, target = "1", inputting = false, kbRow = 1, kbCol = 1 }
    screen = "create"
end

local function openEdit()
    if #habits == 0 then return end
    local h = habits[selHabit]
    form = {
        field     = 1,
        name      = h.name,
        htype     = h.htype == "binary" and 1 or 2,
        scale     = h.scale == "more" and 1 or 2,
        target    = tostring(h.target or 1),
        inputting = false,
        kbRow     = 1,
        kbCol     = 1,
    }
    screen = "edit"
end

local function submitForm()
    local name = (form.name ~= "" and form.name) or ("Habit " .. (#habits + 1))
    local ht   = form.htype == 1 and "binary" or "numeric"
    local sc   = form.scale == 1 and "more" or "less"
    local tg   = tonumber(form.target) or 1
    if screen == "create" then
        table.insert(habits, { name = name, htype = ht, scale = sc, target = tg, entries = {} })
        selHabit = #habits
    else
        habits[selHabit].name   = name
        habits[selHabit].htype  = ht
        habits[selHabit].scale  = sc
        habits[selHabit].target = tg
    end
    saveHabits()
    -- ensure selected tab visible
    local maxTabs = 3
    if selHabit < tabOffset + 1 then
        tabOffset = math.max(0, selHabit - 1)
    elseif selHabit > tabOffset + maxTabs then
        tabOffset = math.max(0, math.min(#habits - maxTabs, selHabit - maxTabs))
    end
    screen = "main"
end

-- ─── Button dispatch ──────────────────────────────────────
local function handleMain(btn)
    if btn == "a" then
        if #habits > 0 then annotate(habits[selHabit], selDay) end
    elseif btn == "b" then
        vizMode = vizMode % 3 + 1
        -- Clamp selDay to new range
        selDay = math.max(selDay, -(VIZ_DAYS[vizMode] - 1))
    elseif btn == "x" then
        openEdit()
    elseif btn == "y" then
        openCreate()
    elseif btn == "leftshoulder" then
        selHabit = math.max(1, selHabit - 1)
        local maxTabs = 3
        if selHabit < tabOffset + 1 then
            tabOffset = math.max(0, selHabit - 1)
        end
    elseif btn == "rightshoulder" then
        selHabit = math.min(#habits, selHabit + 1)
        local maxTabs = 3
        if selHabit > tabOffset + maxTabs then
            tabOffset = math.max(0, math.min(#habits - maxTabs, selHabit - maxTabs))
        end
    elseif btn == "dpright" then
        selDay = math.min(0, selDay + 1)
    elseif btn == "dpleft" then
        selDay = math.max(-(VIZ_DAYS[vizMode] - 1), selDay - 1)
    elseif btn == "dpup" then
        local step = vizMode == 3 and 7 or VIZ_COLS[vizMode]
        selDay = math.min(0, selDay + step)
    elseif btn == "dpdown" then
        local step = vizMode == 3 and 7 or VIZ_COLS[vizMode]
        selDay = math.max(-(VIZ_DAYS[vizMode] - 1), selDay - step)
    end
end

local function handleForm(btn)
    -- B always cancels / exits text input
    if btn == "b" then
        if form.inputting then
            form.inputting = false
        else
            screen = "main"
        end
        return
    end

    -- While typing (virtual keyboard) — only for the Name field

    if form.inputting then
        if form.field == 1 then
            if btn == "dpup" then
                form.kbRow = math.max(1, form.kbRow - 1)
            elseif btn == "dpdown" then
                form.kbRow = math.min(#keyb, form.kbRow + 1)
            elseif btn == "dpleft" then
                form.kbCol = math.max(1, form.kbCol - 1)
            elseif btn == "dpright" then
                form.kbCol = math.min(#keyb[form.kbRow], form.kbCol + 1)
            elseif btn == "a" then
                local key = keyb[form.kbRow][form.kbCol]
                if key == "<" then
                    if #form.name > 0 then form.name = form.name:sub(1, -2) end
                elseif key == "↑" then
                    print(key)
                    if shift then
                        keyb = keyboard
                        shift = false
                    else
                        keyb = keyboardShift
                        shift = true
                    end
                elseif key == "OK" then
                    form.inputting = false
                else
                    form.name = form.name .. key
                end
            end
        end
        return
    end

    -- Navigate fields
    if btn == "dpup" then
        form.field = math.max(1, form.field - 1)
        if form.field == 3 and form.htype == 1 then form.field = form.field - 1 end
        return
    end
    if btn == "dpdown" then
        form.field = math.min(#FORM_FIELD_NAMES, form.field + 1)
        if form.field == 3 and form.htype == 1 then form.field = form.field + 1 end
        return
    end

    -- Left/Right on non-text fields: toggle or change target
    if btn == "dpleft" or btn == "dpright" then
        if form.field == 2 then
            form.htype = 3 - form.htype
        elseif form.field == 4 then
            form.scale = 3 - form.scale
        elseif form.field == 3 and form.htype == 2 then
            local v = tonumber(form.target) or 1
            if btn == "dpleft" then v = v - 1 else v = v + 1 end
            if v < 0 then v = 0 end
            form.target = tostring(v)
        end
        return
    end

    if btn == "a" then
        if form.field == 1 then
            form.inputting = true
        elseif form.field == 2 then
            form.htype = 3 - form.htype
        elseif form.field == 3 then
            form.scale = 3 - form.scale
        elseif form.field == 5 then
            submitForm()
        end
    end
end

local function playSfx()
    sfx:stop()
    sfx:play()
end

local function dispatch(btn)
    if screen == "main" then handleMain(btn) else handleForm(btn) end
    playSfx()
end

-- ─── Gamepad callbacks ────────────────────────────────────
function love.gamepadpressed(_, btn)
    dispatch(btn)
end

-- ─── Keyboard fallback ────────────────────────────────────
local KMAP = {
    ["return"] = "a",
    ["space"] = "a",
    ["escape"] = "b",
    ["z"] = "x",
    ["c"] = "y",
    ["q"] = "leftshoulder",
    ["e"] = "rightshoulder",
    ["right"] = "dpright",
    ["left"] = "dpleft",
    ["up"] = "dpup",
    ["down"] = "dpdown",
}

function love.keypressed(key)
    -- Keyboard fallback
    local btn = KMAP[key]
    if btn then dispatch(btn) end
end
