local json = require("json")
local flux = require("flux")

-- Estados e Variáveis de Controle
local STATE = "LOADING"
local message = "Iniciando..."
local CACHE_FILE = "weather_cache.json"
local RES_W, RES_H = 640, 480
local font_big, font_small, font_tiny
local margin = { top = 180, bottom = 80, left = 40, right = 40 }
local chart_w, chart_h

local weather_icons = {} -- Armazena as imagens estáticas (PNGs)
-- Para animação simulada (assumindo que você tenha quadros de animação)
local current_anim_frame = 1
local anim_timer = 0
local anim_speed = 0.2      -- Segundos por quadro
local total_anim_frames = 4 -- Exemplo: se tiver 4 quadros para animação atual

local iconOffset = { y = 0 }

-- Dados das Cidades
local locations = {}
local current_city_idx = 1
local last_update = 0

-- Dados das Paletas
local palettes = {
    { bg = { 0.16, 0.05, 0.18 }, axis = { 0.3, 0.2, 0.4 } }, -- Roxo (Padrão)
    { bg = { 0.05, 0.15, 0.10 }, axis = { 0.2, 0.4, 0.3 } }, -- Verde
    { bg = { 0.05, 0.10, 0.20 }, axis = { 0.2, 0.3, 0.5 } }, -- Azul Escuro
    { bg = { 0.15, 0.05, 0.05 }, axis = { 0.4, 0.2, 0.2 } }  -- Vermelho Escuro
}
local current_pal = 1

-- UI Input: (Lat: ±00.000, Lon: ±00.000) -> 12 slots
-- Índices: 1(Sinal), 2-3(Int), 4-6(Dec) | 7(Sinal), 8-9(Int), 10-12(Dec)
local input_digits = { '+', 0, 0, 0, 0, 0, '+', 0, 0, 0, 0, 0 }
local input_cursor = 1

local cmd_channel, res_channel

-- Função Auxiliar: Texto com Contorno
function printOutline(text, x, y, color, font)
    love.graphics.setFont(font or font_small)
    love.graphics.setColor(0, 0, 0, 1) -- Sombra/Contorno Preto
    for i = -1, 1 do
        for j = -1, 1 do
            if i ~= 0 or j ~= 0 then
                love.graphics.print(text, x + i, y + j)
            end
        end
    end
    love.graphics.setColor(color or { 1, 1, 1 })
    love.graphics.print(text, x, y)
end

local gradient = love.graphics.newShader [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        vec2 center = vec2(320, 40);
        float distance = length(screen_coords - center);
        float fade = clamp(distance / 400.0, 0.0, 1.0);

        pixel.a = pixel.a * fade;

        return pixel * color;
    }
]]

function love.load()
    love.window.setMode(RES_W, RES_H, { resizable = false, vsync = true })

    if love.filesystem.getInfo("palette_index.txt") then
        local saved = love.filesystem.read("palette_index.txt")
        current_pal = tonumber(saved)
    end
    chart_w = RES_W - margin.left - margin.right
    chart_h = RES_H - margin.top - margin.bottom

    font_big = love.graphics.newFont("assets/Kubasta.ttf", 31)
    font_small = love.graphics.newFont("assets/Kubasta.ttf", 24)
    font_tiny = love.graphics.newFont("assets/Kubasta.ttf", 20)

    cmd_channel = love.thread.getChannel("api_cmd")
    res_channel = love.thread.getChannel("api_res")

    -- Lista simplificada de códigos WMO principais que você traduziu do repo SVG para PNG
    -- Ex: 0 (Céu limpo), 1-3 (Parcialmente nublado), 45-48 (Nevoeiro), 61-65 (Chuva), etc.
    local codes_to_load = { 0, 1, 2, 3, 45, 48, 61, 63, 65, 80, 81, 82, 95 }
    love.graphics.setDefaultFilter("nearest")
    for _, code in ipairs(codes_to_load) do
        local path = "assets/" .. code .. ".png"
        if love.filesystem.getInfo(path) then
            weather_icons[code] = love.graphics.newImage(path)
        end
    end

    local threadCode = [[
        local http = require("socket.http")
        local https = require("https")
        local request_func = https.request
        local json = require("json")
        local c_in = love.thread.getChannel("api_cmd")
        local c_out = love.thread.getChannel("api_res")

        -- Função auxiliar para tratar a resposta com segurança
        local function handle_response(action_name, b, c, cmd, extra_data)
            if b and c == 200 then
                local ok, decoded = pcall(json.decode, b)
                if ok and not decoded.error then
                    local res = { action = action_name, data = decoded }
                    if cmd.idx then res.idx = cmd.idx end
                    if cmd.lat then res.lat = cmd.lat; res.lon = cmd.lon end
                    c_out:push(res)
                else
                    c_out:push({ action = "error", msg = "Coordenadas inválidas ou erro nos dados." })
                end
            else
                c_out:push({ action = "error", msg = "Falha de conexão. Verifique sua internet." })
            end
        end

        while true do
            local cmd = c_in:demand()
            local url = ""

            if cmd.type == "fetch_ip" then
                url = "http://ip-api.com/json/"
                local c, b = request_func(url)
                handle_response("ip_data", b, c, cmd)

            elseif cmd.type == "reverse_geo" then
                url = string.format("https://nominatim.openstreetmap.org/reverse?lat=%f&lon=%f&format=json&zoom=12", cmd.lat, cmd.lon)
                local c, b = request_func(url, {headers={["User-Agent"] = "Love2D_WeatherApp/2.0"}})
                handle_response("geo_data", b, c, cmd)

            elseif cmd.type == "fetch_weather" then
                url = string.format(
                    "https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f" ..
                    "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunset,sunrise,weather_code" ..
                    "&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto",
                    cmd.lat, cmd.lon
                )
                local c, b = request_func(url)
                handle_response("weather_data", b, c, cmd)

            elseif cmd.type == "fetch_hourly" then
                url = string.format("https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f&hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&forecast_days=1&timezone=auto", cmd.lat, cmd.lon)
                local c, b = request_func(url)
                handle_response("hourly_data", b, c, cmd)
            end
        end
    ]]
    love.thread.newThread(threadCode):start()

    -- Carregar Cache
    if love.filesystem.getInfo(CACHE_FILE) then
        local content = love.filesystem.read(CACHE_FILE)
        local data = json.decode(content)
        locations = data.locations
        last_update = data.last_update
        STATE = "VIEWING"
        if os.time() - last_update > 3600 then refresh_weather() end
    else
        cmd_channel:push({ type = "fetch_ip" })
    end

    -- Carregar Música
    local music = love.audio.newSource("assets/8bit Bossa.mp3", "stream")
    music:setLooping(true)
    music:play()

    -- Animation
    local function animateIcon()
        flux.to(iconOffset, 2, { y = 5 }):ease("sineinout"):after(2, { y = 0.5 }):oncomplete(animateIcon)
    end
    animateIcon()
end

function refresh_weather()
    STATE = "LOADING"
    message = "Buscando dados semanais..."
    for i, loc in ipairs(locations) do
        cmd_channel:push({ type = "fetch_weather", lat = loc.lat, lon = loc.lon, idx = i })
    end
end

function love.update(dt)
    if STATE == "VIEWING" and locations[current_city_idx] and locations[current_city_idx].current then
        anim_timer = anim_timer + dt
        if anim_timer >= anim_speed then
            anim_timer = anim_timer - anim_speed
            current_anim_frame = (current_anim_frame % total_anim_frames) + 1
        end
    end

    local res = res_channel:pop()
    if res then
        if res.action == "ip_data" then
            locations[1] = { city = res.data.city, country = res.data.country, lat = res.data.lat, lon = res.data.lon }
            cmd_channel:push({ type = "fetch_weather", lat = res.data.lat, lon = res.data.lon, idx = 1 })
        elseif res.action == "geo_data" then
            local a = res.data.address
            local name = a.city or a.town or a.village or a.municipality or "Local Desconhecido"
            table.insert(locations, { city = name, country = a.country or "Terra", lat = res.lat, lon = res.lon })
            current_city_idx = #locations
            cmd_channel:push({ type = "fetch_weather", lat = res.lat, lon = res.lon, idx = #locations })
        elseif res.action == "weather_data" then
            locations[res.idx].current = res.data.current
            locations[res.idx].daily = res.data.daily
            last_update = os.time()
            save_cache()
            STATE = "VIEWING"
        elseif res.action == "hourly_data" then
            locations[res.idx].hourly = res.data.hourly
            STATE = "HOURLY"
        elseif res.action == "error" then
            message = res.msg; STATE = "VIEWING_ERROR" -- Modificado para não travar na tela de load
        end
    end
    flux.update(dt)
end

function save_cache()
    love.filesystem.write(CACHE_FILE, json.encode({ locations = locations, last_update = last_update }))
end

-- Formatação de Data com Dia da Semana
function get_day_label(date_str, weekday)
    local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
    local t = os.time({ year = y, month = m, day = d })
    local days = { "Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb" }
    local days_full = { "Domingo", "Segunda-Feira", "Terça-Feira", "Quarta-Feira", "Quinta-Feira", "Sexta-Feira",
        "Sábado" }

    if weekday then
        return days_full[tonumber(os.date("%w", t)) + 1]
    else
        return days[tonumber(os.date("%w", t)) + 1] .. "\n" .. d .. "/" .. m
    end
end

local function map(val, min_val, max_val, height)
    if max_val == min_val then return height / 2 end
    return (val - min_val) / (max_val - min_val) * height
end

-- Atualização da lógica de desenho com escalas e textos de instrução
function love.draw()
    love.graphics.setBackgroundColor(palettes[current_pal].bg)
    love.graphics.setShader(gradient)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, RES_W, RES_H)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()

    if STATE == "LOADING" then
        love.graphics.printf(message, 0, RES_H / 2, RES_W, "center")
        return
    elseif STATE == "VIEWING_ERROR" then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf("ERRO:\n" .. message, 0, RES_H / 2 - 20, RES_W, "center")
        love.graphics.setColor(0.5, 0.4, 0.6)
        love.graphics.printf("Aperte qualquer botão para voltar", 0, RES_H - 40, RES_W, "center")
        return
    elseif STATE == "INPUT" then
        draw_input()
        return
    elseif STATE == "CREDITS" then
        draw_credits()
        return
    elseif STATE == "HOURLY" then
        draw_hourly()
        return
    end

    local loc = locations[current_city_idx]
    if not loc or not loc.daily then return end

    -- HEADER: Localização e Dados Atuais
    love.graphics.setFont(font_big)
    love.graphics.setColor(1, 1, 1)

    local current_code = loc.current.weather_code
    local header_text_1 = string.format("%s, %s\n%.1f°C | Umidade: %d%%",
        loc.city, loc.country, loc.current.temperature_2m, loc.current.relative_humidity_2m)
    local header_text_2 = string.format("%s\n%s", get_day_label(loc.current.time, true), os.date("%d/%m/%Y %H:%M:%S"))

    -- Centraliza o bloco de texto + ícone
    local text_w_1 = font_big:getWidth(header_text_1)
    local text_w_2 = font_big:getWidth(header_text_2)
    local icon_size = 64
    local total_w = text_w_1 + icon_size + 20
    local start_x = (RES_W - total_w) / 16

    love.graphics.printf(header_text_1, start_x + icon_size + 20, 5, text_w_1, "left")
    love.graphics.printf(header_text_2, RES_W - text_w_2 - 20, 5, text_w_2, "center")

    -- Desenha o ícone atual (Usando estático por enquanto,
    -- precisaria carregar sequência de imagens para animar de fato)
    if weather_icons[current_code] then
        love.graphics.setColor(1, 1, 1, 1) -- Garante opacidade total
        -- Se tiver animação real, usaria weather_anim[current_code][current_anim_frame]
        love.graphics.draw(weather_icons[current_code], start_x,
            iconOffset.y + 20 + (font_big:getHeight() - icon_size) / 2,
            0,
            icon_size / weather_icons[current_code]:getWidth(), icon_size / weather_icons[current_code]:getHeight())
    end

    -- INDICADORES: Página e Última Atualização
    love.graphics.setFont(font_tiny)
    love.graphics.setColor(palettes[current_pal].axis)
    local info_text = string.format("Localidade %d/%d  |  Última atualização: %s",
        current_city_idx, #locations, os.date("%H:%M", last_update))
    love.graphics.printf(info_text, 0, 60, RES_W, "center")

    -- Eixo X Base
    love.graphics.setColor(palettes[current_pal].axis)
    love.graphics.line(margin.left, margin.top + chart_h, margin.left + chart_w, margin.top + chart_h)

    local num_days = #loc.daily.time
    local step_x = chart_w / (num_days - 1)

    -- ESCALAS DINÂMICAS (Cálculo de limites para o mapeamento)
    local max_t, min_t = -99, 99
    local max_rain = 0.1
    for i = 1, 7 do
        max_t = math.max(max_t, loc.daily.temperature_2m_max[i])
        min_t = math.min(min_t, loc.daily.temperature_2m_min[i])
        max_rain = math.max(max_rain, loc.daily.precipitation_sum[i])
    end
    max_t, min_t = max_t + 2, min_t - 2 -- Margem de respiro

    for i = 1, num_days do
        local x = margin.left + (i - 1) * step_x
        local d = loc.daily

        if i % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.rectangle("fill", x - step_x / 2, margin.top - 95, step_x,
                RES_H - margin.top + 67)
        end

        -- Mapeamento Y (Normalizado)
        local y_max = (margin.top + chart_h) - map(d.temperature_2m_max[i], min_t, max_t, chart_h)
        local y_min = (margin.top + chart_h) - map(d.temperature_2m_min[i], min_t, max_t, chart_h)
        local y_prob = (margin.top + chart_h) - map(d.precipitation_probability_max[i], 0, 100, chart_h)
        local bar_h = map(d.precipitation_sum[i], 0, max_rain, chart_h * 0.4) -- Barra ocupa até 40% da altura

        -- --- NOVA RENDERIZAÇÃO ÍCONE DIÁRIO (Estático no topo) ---
        love.graphics.setColor(1, 1, 1, 0.8) -- Leve transparência para o gráfico
        local daily_code = d.weather_code[i]
        local daily_icon_size = 48

        if weather_icons[daily_code] then
            -- Desenha o ícone centralizado acima da linha do nascer do sol
            love.graphics.draw(weather_icons[daily_code],
                x - daily_icon_size / 2,
                margin.top - 95, -- Posicionado acima do nascer do sol
                0,
                daily_icon_size / weather_icons[daily_code]:getWidth(),
                daily_icon_size / weather_icons[daily_code]:getHeight())
        end

        -- 1. Sol (Sunrise/Sunset)
        love.graphics.setFont(font_tiny)
        love.graphics.setColor(1, 0.8, 0)
        printOutline("☼ " .. d.sunrise[i]:sub(12, 16), x - 25, margin.top - 45, { 1, 0.8, 0 }, font_tiny)
        love.graphics.setColor(1, 0.4, 0)
        printOutline("☽ " .. d.sunset[i]:sub(12, 16), x - 25, margin.top - 30, { 1, 0.4, 0 }, font_tiny)

        -- 2. Barras de Chuva
        love.graphics.setColor(0.2, 0.8, 0.3, 0.3)
        love.graphics.rectangle("fill", x - 10, (margin.top + chart_h) - bar_h, 20, bar_h)

        -- 3. Desenho de Linhas e Labels
        if i < num_days then
            local nx = x + step_x
            local ny_max = (margin.top + chart_h) - map(d.temperature_2m_max[i + 1], min_t, max_t, chart_h)
            local ny_min = (margin.top + chart_h) - map(d.temperature_2m_min[i + 1], min_t, max_t, chart_h)
            local ny_prob = (margin.top + chart_h) - map(d.precipitation_probability_max[i + 1], 0, 100, chart_h)

            love.graphics.setLineWidth(2)
            love.graphics.setColor(1, 0.2, 0.2, 0.6); love.graphics.line(x, y_max, nx, ny_max)
            love.graphics.setColor(0.3, 0.6, 1, 0.6); love.graphics.line(x, y_min, nx, ny_min)
            love.graphics.setColor(1, 0.6, 0, 0.6); love.graphics.line(x, y_prob, nx, ny_prob)
        end

        -- Pontos e Labels com Outline
        printOutline(d.precipitation_probability_max[i] .. "%", x - 12, y_prob - 18, { 1, 0.7, 0 }, font_tiny)
        if d.precipitation_sum[i] > 0 then
            printOutline(string.format("%.1fmm", d.precipitation_sum[i]), x - 20, (margin.top + chart_h) - bar_h - 18,
                { 0.2, 0.8, 0.3 }, font_tiny)
        end
        printOutline(math.floor(d.temperature_2m_max[i]) .. "°", x + 5, y_max - 5, { 1, 0.3, 0.3 })
        printOutline(math.floor(d.temperature_2m_min[i]) .. "°", x + 5, y_min - 5, { 0.4, 0.7, 1 })

        -- Eixo X: Dia da Semana + Data
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font_small)
        love.graphics.printf(get_day_label(d.time[i]), x - 30, margin.top + chart_h + 10, 60, "center")
    end

    -- INSTRUÇÕES DOS BOTÕES (Rodapé)
    love.graphics.setFont(font_small)
    love.graphics.setColor(palettes[current_pal].axis)
    love.graphics.printf("[DPAD] Cidades  [A] Atualizar  [B] Horários  [Y] Adicionar  [X] Excluir", 0, RES_H - 30, RES_W,
        "center")
end

function draw_hourly()
    local loc = locations[current_city_idx]
    if not loc or not loc.hourly then return end

    -- Título
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_big)
    love.graphics.printf("Previsão Horária - Hoje", 0, 20, RES_W, "center")

    -- Legenda das Cores
    love.graphics.setFont(font_tiny)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Vermelho: Temp | Azul: Umidade | Cinza: Vento | Verde: Chuva", 0, margin.top - 40, RES_W,
        "center")

    -- Eixo X Base (Usando a cor da paleta atual)
    love.graphics.setColor(palettes[current_pal].axis)
    love.graphics.line(margin.left, margin.top + chart_h, margin.left + chart_w, margin.top + chart_h)

    local num_hours = 24
    local step_x = chart_w / (num_hours - 1)

    -- 1. ENCONTRAR LIMITES PARA AS ESCALAS DINÂMICAS
    local max_t, min_t = -99, 99
    local max_w = 0.1
    local max_rain = 0.1

    for i = 1, num_hours do
        max_t = math.max(max_t, loc.hourly.temperature_2m[i])
        min_t = math.min(min_t, loc.hourly.temperature_2m[i])
        max_w = math.max(max_w, loc.hourly.wind_speed_10m[i])
        max_rain = math.max(max_rain, loc.hourly.precipitation[i])
    end
    max_t, min_t = max_t + 2, min_t - 2 -- Margem de respiro para a temperatura

    -- 2. LOOP DE DESENHO DO GRÁFICO
    for i = 1, num_hours do
        local x = margin.left + (i - 1) * step_x
        local h_data = loc.hourly

        -- Fundo alternado a cada 3 horas para guiar a leitura vertical
        if i % 6 < 3 then
            love.graphics.setColor(1, 1, 1, 0.03)
            love.graphics.rectangle("fill", x - step_x / 2, margin.top - 10, step_x, chart_h + 10)
        end

        -- Normalização dos valores para o eixo Y
        local y_t = (margin.top + chart_h) - map(h_data.temperature_2m[i], min_t, max_t, chart_h)
        local y_h = (margin.top + chart_h) - map(h_data.relative_humidity_2m[i], 0, 100, chart_h) -- Umidade é 0 a 100%
        local y_w = (margin.top + chart_h) - map(h_data.wind_speed_10m[i], 0, max_w + 5, chart_h)
        local bar_h = map(h_data.precipitation[i], 0, max_rain, chart_h * 0.4)

        -- Barras de Chuva
        love.graphics.setColor(0.2, 0.8, 0.3, 0.3)
        love.graphics.rectangle("fill", x - (step_x * 0.4), (margin.top + chart_h) - bar_h, step_x * 0.8, bar_h)

        -- Linhas conectando ao próximo ponto
        if i < num_hours then
            local nx = x + step_x
            local ny_t = (margin.top + chart_h) - map(h_data.temperature_2m[i + 1], min_t, max_t, chart_h)
            local ny_h = (margin.top + chart_h) - map(h_data.relative_humidity_2m[i + 1], 0, 100, chart_h)
            local ny_w = (margin.top + chart_h) - map(h_data.wind_speed_10m[i + 1], 0, max_w + 5, chart_h)

            love.graphics.setLineWidth(2)
            love.graphics.setColor(1, 0.3, 0.3, 0.8); love.graphics.line(x, y_t, nx, ny_t)   -- Temp
            love.graphics.setColor(0.3, 0.6, 1, 0.8); love.graphics.line(x, y_h, nx, ny_h)   -- Umidade
            love.graphics.setColor(0.7, 0.7, 0.7, 0.6); love.graphics.line(x, y_w, nx, ny_w) -- Vento
        end

        -- Pontos e Textos (Desenhados apenas a cada 3 horas para evitar poluição visual)
        if i % 3 == 1 or i == num_hours then
            -- Círculos marcadores
            love.graphics.setColor(1, 0.3, 0.3); love.graphics.circle("fill", x, y_t, 3)
            love.graphics.setColor(0.3, 0.6, 1); love.graphics.circle("fill", x, y_h, 3)
            love.graphics.setColor(0.7, 0.7, 0.7); love.graphics.circle("fill", x, y_w, 3)

            -- Textos dos valores com contorno
            printOutline(math.floor(h_data.temperature_2m[i]) .. "°", x + 4, y_t - 15, { 1, 0.3, 0.3 }, font_tiny)
            printOutline(math.floor(h_data.relative_humidity_2m[i]) .. "%", x + 4, y_h + 4, { 0.4, 0.7, 1 }, font_tiny)
            printOutline(math.floor(h_data.wind_speed_10m[i]) .. "k/h", x - 15, y_w - 18, { 0.8, 0.8, 0.8 }, font_tiny)

            -- Texto de chuva (só exibe se for maior que zero)
            if h_data.precipitation[i] > 0 then
                printOutline(string.format("%.1f", h_data.precipitation[i]), x - 10, (margin.top + chart_h) - bar_h - 15,
                    { 0.2, 1, 0.4 }, font_tiny)
            end

            -- Label do Eixo X (Hora no formato HH:MM)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(font_tiny)
            local time_str = h_data.time[i]:sub(12, 16)
            love.graphics.printf(time_str, x - 20, margin.top + chart_h + 10, 40, "center")
        end
    end

    -- 3. INDICADOR DE HORA ATUAL (BARRA VERTICAL)
    local now = os.date("*t")
    -- O gráfico cobre de 0 a 23h. O cálculo proporcional usa a hora e os minutos atuais.
    local current_time_decimal = now.hour + (now.min / 60)
    local now_x = margin.left + current_time_decimal * step_x

    -- Desenha apenas se a hora estiver dentro do intervalo do gráfico
    if now_x >= margin.left and now_x <= margin.left + chart_w then
        -- Linha vertical pontilhada ou semi-transparente
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.line(now_x, margin.top - 10, now_x, margin.top + chart_h)

        -- Marcador de texto "AGORA" no topo da linha
        love.graphics.setColor(1, 1, 1, 1)
        printOutline("AGORA", now_x - 18, margin.top - 25, { 1, 1, 1 }, font_tiny)

        -- Pequeno círculo no pé da linha para destaque
        love.graphics.circle("fill", now_x, margin.top + chart_h, 3)
    end

    -- Instrução de rodapé
    love.graphics.setFont(font_small)
    love.graphics.setColor(palettes[current_pal].axis)
    love.graphics.printf("[B] Previsão Semanal", 0, RES_H - 30, RES_W, "center")
end

function draw_credits()
    local loc = locations[current_city_idx]
    if not loc or not loc.daily then return end

    -- HEADER: Localização e Dados Atuais
    love.graphics.setFont(font_big)
    love.graphics.setColor(1, 1, 1)

    local current_code = loc.current.weather_code
    local header_text_1 = string.format("%s, %s\n%.1f°C | Umidade: %d%%",
        loc.city, loc.country, loc.current.temperature_2m, loc.current.relative_humidity_2m)
    local header_text_2 = string.format("%s\n%s", get_day_label(loc.current.time, true), os.date("%d/%m/%Y %H:%M:%S"))

    -- Centraliza o bloco de texto + ícone
    local text_w_1 = font_big:getWidth(header_text_1)
    local text_w_2 = font_big:getWidth(header_text_2)
    local icon_size = 64
    local total_w = text_w_1 + icon_size + 20
    local start_x = (RES_W - total_w) / 16

    love.graphics.printf(header_text_1, start_x + icon_size + 20, 5, text_w_1, "left")
    love.graphics.printf(header_text_2, RES_W - text_w_2 - 20, 5, text_w_2, "center")

    -- Desenha o ícone atual (Usando estático por enquanto,
    -- precisaria carregar sequência de imagens para animar de fato)
    if weather_icons[current_code] then
        love.graphics.setColor(1, 1, 1, 1) -- Garante opacidade total
        -- Se tiver animação real, usaria weather_anim[current_code][current_anim_frame]
        love.graphics.draw(weather_icons[current_code], start_x,
            iconOffset.y + 20 + (font_big:getHeight() - icon_size) / 2,
            0,
            icon_size / weather_icons[current_code]:getWidth(), icon_size / weather_icons[current_code]:getHeight())
    end

    -- Creditos
    local text =
    "Criado por KaMiSaMa\n\nÍcones por Dhole\n\nMúsica por Joth\n\nDados fornecidos por\nopenstreetmap.org, open-meteo.com e ip-api.com\n\nMade with LÖVE"
    love.graphics.setFont(font_big)
    love.graphics.printf(text, (RES_W / 2) - (font_big:getWidth(text) / 2) - 60, margin.bottom + 20, RES_W, "center", 0,
        1, 1)

    -- INSTRUÇÕES DOS BOTÕES (Rodapé)
    love.graphics.setFont(font_small)
    love.graphics.setColor(palettes[current_pal].axis)
    love.graphics.printf("Aperte qualquer botão para retornar", 0, RES_H - 30, RES_W, "center")
end

function draw_input()
    -- Título e Subtítulo
    love.graphics.setFont(font_big)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Adicionar Nova Localidade", 0, 80, RES_W, "center")

    love.graphics.setFont(font_small)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Use o D-Pad para ajustar as coordenadas exatas", 0, 110, RES_W, "center")

    -- Formatação das Strings de Display
    -- Latitude: ±00.000 (Índices 1 a 6)
    local lat_display = string.format("%s%d%d.%d%d%d",
        input_digits[1], input_digits[2], input_digits[3],
        input_digits[4], input_digits[5], input_digits[6])

    -- Longitude: ±00.000 (Índices 7 a 12)
    local lon_display = string.format("%s%d%d.%d%d%d",
        input_digits[7], input_digits[8], input_digits[9],
        input_digits[10], input_digits[11], input_digits[12])

    -- Desenho dos Campos
    local centerX = RES_W / 2
    love.graphics.setFont(font_big)

    -- Bloco Latitude
    if input_cursor <= 6 then love.graphics.setColor(1, 0.8, 0) else love.graphics.setColor(1, 1, 1) end
    love.graphics.print("Lat:", centerX - 140, 200)
    love.graphics.print(lat_display, centerX - 80, 200)

    -- Bloco Longitude
    if input_cursor > 6 then love.graphics.setColor(1, 0.8, 0) else love.graphics.setColor(1, 1, 1) end
    love.graphics.print("Lon:", centerX + 20, 200)
    love.graphics.print(lon_display, centerX + 80, 200)

    -- Indicador Visual (Underline no dígito ativo)
    love.graphics.setColor(1, 0.8, 0)
    local startPos = (input_cursor <= 6) and (centerX - 80) or (centerX + 80)
    local localIdx = (input_cursor <= 6) and input_cursor or (input_cursor - 6)

    -- Ajuste preciso: cada caractere na fonte padrão/monospaçada ocupa aprox. 11px
    local charWidth = 12.5
    local dotOffset = (localIdx > 3) and 7 or 0 -- Desloca se o cursor estiver após o ponto "."

    love.graphics.rectangle("fill", startPos + (localIdx - 1) * charWidth + dotOffset, 225, 11, 3)

    -- Instruções de Rodapé (Layout Antigo)
    love.graphics.setFont(font_small)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("[D-Pad] Alterar Valor/Cursor", 0, 320, RES_W, "center")

    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.printf("[A] Confirmar e Buscar", 0, 350, RES_W, "center")

    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.printf("[B] Cancelar", 0, 375, RES_W, "center")
end

function handle_btn(btn)
    if btn == "start" then
        current_pal = (current_pal % #palettes) + 1
        love.filesystem.write("palette_index.txt", tostring(current_pal))
    end

    if STATE == "VIEWING" then
        if btn == "dpright" then
            current_city_idx = (current_city_idx % #locations) + 1
        elseif btn == "dpleft" then
            current_city_idx = (current_city_idx - 2) % #locations + 1
        elseif btn == "y" then
            STATE = "INPUT"; input_cursor = 1
        elseif btn == "b" then
            -- Requisição para a tela horária
            STATE = "LOADING"
            message = "Buscando dados horários..."
            local loc = locations[current_city_idx]
            cmd_channel:push({ type = "fetch_hourly", lat = loc.lat, lon = loc.lon, idx = current_city_idx })
        elseif btn == "a" then
            refresh_weather()
        elseif btn == "select" or btn == "back" then
            STATE = "CREDITS"
        elseif btn == "x" and current_city_idx > 1 then
            table.remove(locations, current_city_idx)
            current_city_idx = 1; save_cache()
        end
    elseif STATE == "HOURLY" then
        if btn == "b" then
            STATE = "VIEWING"
        end
    elseif STATE == "INPUT" then
        if btn == "dpright" then
            input_cursor = (input_cursor % 12) + 1
        elseif btn == "dpleft" then
            input_cursor = (input_cursor - 2) % 12 + 1
        elseif btn == "dpup" or btn == "dpdown" then
            local mod = (btn == "dpup") and 1 or -1
            if input_cursor == 1 or input_cursor == 7 then
                input_digits[input_cursor] = (input_digits[input_cursor] == '+') and '-' or '+'
            else
                input_digits[input_cursor] = (input_digits[input_cursor] + mod) % 10
            end
        elseif btn == "a" then
            local lat = tonumber(string.format("%s%d%d.%d%d%d", input_digits[1], input_digits[2], input_digits[3],
                input_digits[4], input_digits[5], input_digits[6]))
            local lon = tonumber(string.format("%s%d%d.%d%d%d", input_digits[7], input_digits[8], input_digits[9],
                input_digits[10], input_digits[11], input_digits[12]))
            STATE = "LOADING"
            message = "Buscando dados da cidade..."
            cmd_channel:push({ type = "reverse_geo", lat = lat, lon = lon })
        elseif btn == "b" then
            STATE = "VIEWING"
        end
    elseif STATE == "CREDITS" then
        STATE = "VIEWING"
    end
end

-- Mapeamento Teclado -> Gamepad para teste
function love.keypressed(k)
    local map = {
        left = "dpleft",
        right = "dpright",
        up = "dpup",
        down = "dpdown",
        z = "a",
        x = "b",
        c = "y",
        v = "x",
        s = "select",
        a = "start",
    }
    if map[k] then handle_btn(map[k]) end
end

function love.gamepadpressed(j, b) handle_btn(b) end
