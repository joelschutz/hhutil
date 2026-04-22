local colors = {
    index = 0,
    accent = { 0, 0, 0 },
    light = { 0, 0, 0 },
    primary = { 0, 0, 0 },
    secondary = { 0, 0, 0 },
    dark = { 0, 0, 0 },
    pallets = { {                                       -- Main Pallet
        accent = { 230 / 255, 57 / 255, 70 / 255 },     -- Red
        light = { 241 / 255, 250 / 255, 238 / 255 },    -- White
        primary = { 168 / 255, 218 / 255, 220 / 255 },  -- Light Blue
        secondary = { 69 / 255, 123 / 255, 157 / 255 }, -- Dark Blue
        dark = { 29 / 255, 53 / 255, 87 / 255 },        -- Black
    }, {                                                -- High Contrast
        secondary = { 239 / 255, 71 / 255, 111 / 255 }, -- Red
        dark = { 248 / 255, 255 / 255, 229 / 255 },     -- White
        accent = { 255 / 255, 196 / 255, 61 / 255 },    -- Yellow
        primary = { 6 / 255, 214 / 255, 160 / 255 },    -- Green
        light = { 27 / 255, 154 / 255, 170 / 255 },     -- Blue
    }, {
        secondary = { 221 / 255, 45 / 255, 74 / 255 },
        dark = { 203 / 255, 238 / 255, 243 / 255 },
        accent = { 244 / 255, 156 / 255, 187 / 255 },
        light = { 242 / 255, 106 / 255, 141 / 255 },
        primary = { 136 / 255, 13 / 255, 30 / 255 },
    }, {
        accent = { 24 / 255, 58 / 255, 55 / 255 },
        dark = { 239 / 255, 214 / 255, 172 / 255 },
        primary = { 196 / 255, 73 / 255, 0 / 255 },
        secondary = { 67 / 255, 37 / 255, 52 / 255 },
        light = { 4 / 255, 21 / 255, 31 / 255 },
    }, {
        primary = { 56 / 255, 102 / 255, 65 / 255 },
        dark = { 242 / 255, 232 / 255, 207 / 255 },
        secondary = { 167 / 255, 201 / 255, 87 / 255 },
        light = { 106 / 255, 153 / 255, 78 / 255 },
        accent = { 188 / 255, 71 / 255, 73 / 255 },
    }, {
        secondary = { 235 / 255, 94 / 255, 40 / 255 },
        light = { 37 / 255, 36 / 255, 34 / 255 },
        primary = { 64 / 255, 61 / 255, 57 / 255 },
        accent = { 204 / 255, 197 / 255, 185 / 255 },
        dark = { 255 / 255, 252 / 255, 242 / 255 },
    } }
}

function colors:swapPallet(index)
    self.index = index
    self.accent = self.pallets[index].accent
    self.light = self.pallets[index].light
    self.dark = self.pallets[index].dark
    self.primary = self.pallets[index].primary
    self.secondary = self.pallets[index].secondary
end

colors:swapPallet(1)

return colors
