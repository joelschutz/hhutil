-- Persistence module for TODO app
-- Handles saving and loading todos from todos.json file

local persistence = {}
local json = require("json")

-- Default file path
persistence.FILE_PATH = "todos.json"

-- Load todos from JSON file
function persistence.load()
    if not love.filesystem.getInfo(persistence.FILE_PATH) then
        return {
            todos = {},
            lastId = 0,
            paletteIndex = 1
        }
    end

    local content = love.filesystem.read(persistence.FILE_PATH)
    local ok, data = pcall(json.decode, content)
    if ok and data then
        return data
    end

    return {
        todos = {},
        lastId = 0,
        paletteIndex = 1
    }
end

-- Save todos to JSON file
function persistence.save(data)
    local content = json.encode(data)
    if content then
        love.filesystem.write(persistence.FILE_PATH, content)
        return true
    end
    return false
end

-- Create a new todo item
function persistence.createTodo(text, lastId)
    return {
        id = lastId + 1,
        text = text,
        completed = false
    }
end

return persistence
