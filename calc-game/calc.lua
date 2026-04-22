local bit = require("bit")

local state = {
    tokens = {},
    register = 0,
    ans = nil,
    buffer = {},
    bufferTail = 0,
    width = 0,
    height = 0,
    font = {},
    base = "DEC",
    var = {
        A = 0,
        B = 0,
        C = 0,
        D = 0,
        E = 0,
        F = 0,
        I = 0,
        J = 0,
    },
    memMode = nil,
    angleUnit = "RAD"
}

local priorityMap = {
    -- Postfix / Unários (Maior prioridade)
    ["!"] = { 50, 0 }, -- Fatorial

    -- Potências e Raízes
    ["^"] = { 41, 40 }, -- Associativo à direita
    ["√"] = { 41, 40 },

    -- Aritmética Multiplicativa
    ["*"] = { 30, 31 }, -- Associativo à esquerda
    ["/"] = { 30, 31 },
    ["mod"] = { 30, 31 },

    -- Aritmética Aditiva
    ["+"] = { 20, 21 },
    ["-"] = { 20, 21 },

    -- Deslocamento de Bits (Bitwise)
    ["<<"] = { 18, 19 },
    [">>"] = { 18, 19 },

    -- Operadores Comparativos / Relacionais
    ["<"] = { 14, 15 },
    [">"] = { 14, 15 },
    ["<="] = { 14, 15 },
    [">="] = { 14, 15 },
    ["=="] = { 12, 13 },
    ["!="] = { 12, 13 }, -- ou "~=" se preferir o padrão Lua

    -- Operadores Lógicos / Bitwise Lógicos
    ["AND"] = { 8, 9 },
    ["XOR"] = { 6, 7 },
    ["OR"] = { 4, 5 },
}

-- Auxiliar functions
local function factorial(n)
    if n == 0 then return 1 end
    return n * factorial(n - 1)
end

local function nthRoot(x, n)
    if x < 0 and n % 2 ~= 0 then
        return -((-x) ^ (1 / n))
    else
        return x ^ (1 / n)
    end
end

local function logicToCalc(result)
    if result then
        return 1
    end
    return 0
end

local operationMap = {
    ["+"] = function(a, b) return a + b end,
    ["-"] = function(a, b) return a - b end,
    ["*"] = function(a, b) return a * b end,
    ["/"] = function(a, b) return a / b end,
    ["^"] = function(a, b) return a ^ b end,
    ["mod"] = function(a, b) return a % b end,
    ["√"] = function(a, b) return nthRoot(b, a) end,

    ["OR"] = function(a, b) return bit.bor(a, b) end,
    ["AND"] = function(a, b) return bit.band(a, b) end,
    ["XOR"] = function(a, b) return bit.bxor(a, b) end,
    ["«"] = function(a, b) return bit.lshift(a, b) end,
    ["»"] = function(a, b) return bit.rshift(a, b) end,
    ["=="] = function(a, b) return logicToCalc(a == b) end,
    ["~="] = function(a, b) return logicToCalc(a ~= b) end,
    [">="] = function(a, b) return logicToCalc(a >= b) end,
    ["<="] = function(a, b) return logicToCalc(a <= b) end,
    [">"] = function(a, b) return logicToCalc(a > b) end,
    ["<"] = function(a, b) return logicToCalc(a < b) end,
}

local mathFunctions = {
    ["sin"] = function(a) return math.sin(a) end,
    ["sin⁻¹"] = function(a) return math.asin(a) end,
    ["cos"] = function(a) return math.cos(a) end,
    ["cos⁻¹"] = function(a) return math.acos(a) end,
    ["tan"] = function(a) return math.tan(a) end,
    ["tan⁻¹"] = function(a) return math.atan(a) end,
    ["log"] = function(a) return math.log(a, 10) end,
    ["10^"] = function(a) return 10 ^ a end,     -- Check alternative
    ["ln"] = function(a) return math.log(a) end,
    ["e^"] = function(a) return math.exp(a) end, -- Check alternative
    ["!"] = function(a) return factorial(a) end,
    ["1/"] = function(a) return 1 / a end,       -- Check alternative

    ["NOT"] = function(a) return bit.bnot(a) end,
}

-- Lexer for evaluation
local lexer = {
    tokens = {},
    index = 1
}

function lexer:new(tokens)
    local obj = {
        tokens = tokens,
        index = 1
    }
    return setmetatable(obj, { __index = self })
end

function lexer:next()
    local r = self.tokens[self.index]
    self.index = self.index + 1
    return r
end

function lexer:peek()
    return self.tokens[self.index]
end

-- Methods
function state:New()
    local obj = {
        tokens = {},
        register = 0,
        buffer = {},
        bufferTail = 0,
        ans = nil,
        width = 0,
        height = 0,
        font = {},
        base = "DEC",
        var = {
            A = 0,
            B = 0,
            C = 0,
            D = 0,
            E = 0,
            F = 0,
            I = 0,
            J = 0,
        },
        memMode = nil,
        angleUnit = "RAD"
    }
    return setmetatable(obj, { __index = self })
end

function state:allclear()
    self.tokens = {}
    self.register = 0
    self.buffer = {}
    self.bufferTail = 0
    self.ans = nil
    self.memMode = nil
end

function state:memoryclear()
    self.var = {
        A = 0,
        B = 0,
        C = 0,
        D = 0,
        E = 0,
        F = 0,
        I = 0,
        J = 0,
    }
    self.memMode = nil
end

function state.clear(self)
    if self.register == 0 then
        self.tokens = {}
        local nb = {}
        for i = 1, self.bufferTail, 1 do
            nb[i] = self.buffer[i]
        end
        self.buffer = nb
    end
    self.memMode = nil
    self.register = 0
end

function state:updateMemory(v)
    if self.memMode == "MR" then
        self.var[v] = self.register
    elseif self.memMode == "MA" then
        self.var[v] = self.ans
    end
    self.memMode = nil
end

function state.append(self, v)
    local function count_decimal_digits(num)
        local s = tostring(num)
        local _, decimal_part = s:match("(%-?%d+)%.(%d+)")
        return decimal_part and #decimal_part or 0
    end

    if (type(v) == "string") and (self.base ~= "HEX") then
        self:updateMemory(v)
        self.register = self.var[v]
        return
    end

    if self.base == "DEC" then
        -- Multiplicação implícita: se digitar número após ")" ou "!"
        local last = self.tokens[#self.tokens]
        if self.register == 0 and (last == ")" or last == "!") then
            table.insert(self.tokens, "*")
        end

        if self.register == 0 then
            self.register = v
        elseif #tostring(self.register) < 14 then
            if self.register < 0 then v = v * -1 end
            local fp = count_decimal_digits(self.register)
            local offset = 1
            if fp > 0 then
                offset = 10
            end
            self.register = (self.register * 10 + (v / 10 ^ fp)) / offset
        end
    elseif self.base == "BIN" then
        if v < 2 then
            self.register = self.register * 2 + v
        end
    elseif self.base == "OCT" then
        if v < 8 then
            self.register = self.register * 8 + v
        end
    elseif self.base == "HEX" then
        local hexLetter = { A = 10, B = 11, C = 12, D = 13, E = 14, F = 15 }
        if type(v) == "string" then
            local m = hexLetter[v]
            if m == nil then
                self:updateMemory(v)
                self.register = self.var[v]
                return
            else
                v = m
            end
        end
        self.register = self.register * 16 + v
    end
end

function state:backspace()
    -- 1. Convert register to string to treat it as text
    local s = tostring(self.register)

    -- 2. If it's a single digit or scientific notation that's too short, reset to 0
    if #s <= 1 then
        self.register = 0
    else
        -- 3. Remove the last character
        s = s:sub(1, -2)

        -- 4. Check if the remaining string is a valid number prefix
        -- If it's empty, just a minus sign, or just a dot, reset to 0
        if s == "" or s == "-" or s == "." or s == "-." then
            self.register = 0
        else
            -- 5. Convert back to number
            self.register = tonumber(s) or 0
        end
    end

    if self.updateBuffer then
        self:updateBuffer()
    end
end

function state:moveFloat(right)
    if self.base == "DEC" then
        if right then
            self.register = self.register * 10
        else
            self.register = self.register / 10
        end
    end
end

function state:increment(var, up)
    local v = 1
    if not up then
        v = -1
    end
    self.var[var] = self.var[var] + v
end

function state:sign(bin)
    if bin then
        self.register = bit.bnot(self.register) + 1
    else
        self.register = self.register * -1
    end
end

function state.pushOperation(self, operation)
    local isPostfix = (operation == "!")
    local isPrefix = (mathFunctions[operation] ~= nil and not isPostfix)
    local isInfix = (operationMap[operation] ~= nil)

    -- 1. PREFIX FUNCTIONS (e.g., sin, cos, log)
    if isPrefix then
        -- Handle implicit multiplication if preceded by a number or closing symbol
        if self.register ~= 0 then
            table.insert(self.tokens, self.register)
            table.insert(self.tokens, "*")
            self.register = 0 -- Reset register without clearing tokens
        elseif #self.tokens > 0 and (self.tokens[#self.tokens] == ")" or self.tokens[#self.tokens] == "!") then
            table.insert(self.tokens, "*")
        end
        table.insert(self.tokens, operation)

        -- 2. POSTFIX OPERATORS (e.g., !)
    elseif isPostfix then
        if self.register ~= 0 then
            table.insert(self.tokens, self.register)
            self.register = 0
        end
        local last = self.tokens[#self.tokens]
        -- Factorial can only succeed a number, ')' or another factorial
        if type(last) == "number" or last == ")" or last == "!" then
            table.insert(self.tokens, "!")
        end

        -- 3. INFIX OPERATORS (e.g., +, -, *, /)
    elseif isInfix then
        if self.register ~= 0 then
            table.insert(self.tokens, self.register)
            self.register = 0
        elseif #self.tokens == 0 then
            return -- Cannot start an expression with an infix operator
        elseif type(self.tokens[#self.tokens]) == "string" and operationMap[self.tokens[#self.tokens]] then
            -- Replace operator if typed consecutively (e.g., change '+' to '*')
            self.tokens[#self.tokens] = operation
            self:updateBuffer()
            return
        end

        table.insert(self.tokens, operation)
    end

    self:updateBuffer()
end

function state:setScreenSize(width, height)
    self.width = width
    self.height = height
end

function state:setScreenFont(font)
    self.font = font
end

function state:setBase(base)
    self.base = base
end

function state:setAngle(unit)
    self.angleUnit = unit
end

function state:setMemMode(mode)
    self.memMode = mode
end

function state:updateBuffer()
    local lines = {}
    function sliceTokens(head)
        local tail = #self.tokens
        local t = table.concat(self.tokens, "", head, tail)
        while self.font:getWidth(t) > self.width do
            tail = tail - 2
            t = table.concat(self.tokens, "", head, tail)
        end
        table.insert(lines, t)
        if tail < #self.tokens then
            sliceTokens(tail + 1)
        end
    end

    sliceTokens(1)
    for i, v in ipairs(lines) do
        if v ~= "" then
            self.buffer[self.bufferTail + i] = v
        end
    end
end

function state:pushBracket(bracket)
    if bracket == ")" then
        -- Count bracket balance to ensure matching
        local count = 0
        for _, token in ipairs(self.tokens) do
            if token == "(" then
                count = count + 1
            elseif token == ")" then
                count = count - 1
            end
        end

        -- Only insert ')' if there are open brackets left to close
        if count > 0 and (self.register ~= 0 or self.tokens[#self.tokens] == ")") then
            if self.register ~= 0 then
                table.insert(self.tokens, self.register)
                self.register = 0
            end
            table.insert(self.tokens, ")")
        end
    else
        -- Handle opening bracket '('
        if self.register ~= 0 then
            table.insert(self.tokens, self.register)
            self.register = 0
            table.insert(self.tokens, "*") -- Implicit multiplication: 5( -> 5*(
        elseif #self.tokens > 0 and self.tokens[#self.tokens] == ")" then
            table.insert(self.tokens, "*") -- Implicit multiplication: )( -> )*(
        end
        table.insert(self.tokens, "(")
    end
    self:updateBuffer()
end

function state:pushResult()
    if #self.tokens ~= 0 or self.tokens[#self.tokens] == ")" or type(self.tokens[#self.tokens]) ~= "string" then
        table.insert(self.tokens, self.register)

        local count = 0
        -- Check if orphan open bracket are present
        for _, token in ipairs(self.tokens) do
            if token == "(" then
                count = count + 1
            elseif token == ")" then
                count = count - 1
            end
        end
        for i = 1, count, 1 do
            table.insert(self.tokens, ")")
        end
        -- Evaluate Result
        local result = self:evaluateResult()
        table.insert(self.buffer, "= " .. result)
        self.ans = result
        self:updateBuffer()
        self.register = 0
        self.tokens = {}
        self.bufferTail = #self.buffer
    end
end

function state:evaluateResult()
    local lex = lexer:new(self.tokens)

    local function parseExpression(minPriority)
        local token = lex:next()
        local left
        -- --- FASE 1: PREFIXO (Termos Iniciais) ---
        if type(token) == "number" or token == 0 then
            left = token
        elseif token == "(" then
            left = parseExpression(0)
            lex:next() -- Consome o ")"
        elseif mathFunctions[token] then
            -- Se for uma função (sin, log, etc), ela tem prioridade altíssima
            -- Ela tenta consumir o próximo termo como seu argumento
            local arg = parseExpression(50)

            -- Checa a unidade do angulo
            if self.angleUnit == "DEG" then
                if token == "sin" or token == "cos" or token == "tan" then
                    arg = math.rad(arg)
                end
            end
            left = mathFunctions[token](arg)
            if self.angleUnit == "DEG" then
                if token == "sin⁻¹" or token == "cos⁻¹" or token == "tan⁻¹" then
                    left = math.deg(left)
                end
            end
        else
            error("Token inesperado: " .. tostring(token))
        end

        -- --- FASE 2: INFIXO E POSTFIX (Operadores) ---
        while true do
            local op = lex:peek()
            if not op or op == ")" then break end

            local prec = priorityMap[op]
            if not prec or prec[1] < minPriority then
                break
            end

            lex:next() -- Consome o operador

            if op == "!" then
                -- Caso especial: Operador Postfix (Fatorial)
                left = mathFunctions["!"](left)
            else
                -- Operadores Binários (+, -, *, /, ^, mod, √)
                -- O 'prec[2]' define a força com que ele puxa o próximo termo
                local right = parseExpression(prec[2])
                left = operationMap[op](left, right)
            end
        end

        return left
    end

    return parseExpression(0)
end

function state.print(self)
    print(self.register)
end

return state:New()
