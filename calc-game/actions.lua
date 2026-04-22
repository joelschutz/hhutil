local flux = require "flux"
-- local colors = require "palette"

local function animateButton(obj)
    -- Click animation (pop)
    flux.to(obj, 0.1, { scale = 1.0 })
        :ease("quadout")
        :after(obj, 0.1, { scale = 1.1 })
end

local normal = {
    {
        label = "AC",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:allclear()
        end
    },
    {
        label = "C",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:clear()
        end
    },
    {
        label = "±",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:sign(false)
        end
    },
    {
        label = "÷",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("/")
        end
    },
    {
        label = "7",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(7)
        end
    },
    {
        label = "8",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(8)
        end
    },
    {
        label = "9",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(9)
        end
    },
    {
        label = "*",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "4",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(4)
        end
    },
    {
        label = "5",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(5)
        end
    },
    {
        label = "6",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(6)
        end
    },
    {
        label = "-",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "1",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(1)
        end
    },
    {
        label = "2",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(2)
        end
    },
    {
        label = "3",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(3)
        end
    },
    {
        label = "+",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "0",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(0)
        end
    },
    {
        label = "(",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushBracket("(")
        end
    },
    {
        label = ")",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushBracket(")")
        end
    },
    {
        label = "=",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushResult()
        end
    },
}

local sci = {
    {
        label = "AC",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:allclear()
        end
    },
    {
        label = "AU",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setAngle(self.label)
            if self.label == "DEG" then
                self.label = "RAD"
            else
                self.label = "DEG"
            end
        end
    },
    {
        label = "π",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(math.pi)
        end
    },
    {
        label = "e",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            local e = math.exp(1)
            state:append(e)
        end
    },
    {
        label = "sin",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "cos",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "tan",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "mod",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "sin⁻¹",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "cos⁻¹",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "tan⁻¹",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "x!",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("!")
        end
    },
    {
        label = "log",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "ln",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "ʸ√x",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("√")
        end
    },
    {
        label = "1/x",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("1/")
        end
    },
    {
        label = "10ˣ",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("10^")
        end
    },
    {
        label = "eˣ",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("e^")
        end
    },
    {
        label = "xʸ",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation("^")
        end
    },
    {
        label = "=",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushResult()
        end
    },
}

local comp = {
    {
        label = "AC",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:allclear()
        end
    },
    {
        label = "C",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:clear()
        end
    },
    {
        label = "2's", --TODO: Change button
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:sign(true)
        end
    },
    {
        label = "BIN",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setBase(self.label)
        end
    },
    {
        label = "NOT",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "«",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "»",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "OCT",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setBase(self.label)
        end
    },
    {
        label = "OR",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "==",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "~=",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "HEX",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setBase(self.label)
        end
    },
    {
        label = "AND",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = ">",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "<",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "DEC",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setBase(self.label)
        end
    },
    {
        label = "XOR",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = ">=",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "<=",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushOperation(self.label)
        end
    },
    {
        label = "=",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushResult()
        end
    },
}

local mem = {
    {
        label = "AC",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:allclear()
        end
    },
    {
        label = "MC",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:memoryclear()
        end
    },
    {
        label = "MR",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setMemMode(self.label)
        end
    },
    {
        label = "MA",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:setMemMode(self.label)
        end
    },
    {
        label = "A",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "B",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "C",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "I",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "D",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "E",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "F",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "J",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "X",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "Y",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "Z",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:append(self.label)
        end
    },
    {
        label = "=",
        color = "accent",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:pushResult()
        end
    },
    {
        label = "I+",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:increment("I", true)
        end
    },
    {
        label = "I-",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:increment("I", false)
        end
    },
    {
        label = "J+",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:increment("J", true)
        end
    },
    {
        label = "J-",
        color = "secondary",
        onClick = function(self, state)
            print("Clicked " .. self.label)
            animateButton(self)
            state:increment("J", false)
        end
    },
}

return { actions = { normal, sci, comp, mem }, names = { "NRM", "SCI", "CMP", "MEM" } }
