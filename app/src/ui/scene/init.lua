---@diagnostic disable: param-type-mismatch
local config   = require "src.external.config"
local header   = require "src.ui.component.header"
local nativefs = require "src.external.nativefs"

local scene, stack, export

--#region scene

--- @class scene
---
--- @field layers  badr[]  Root components.
--- @field visible boolean Scene visibility.
---
scene = {}
scene.__index = scene

--- Scene initializer
--- @return scene scene New object.
function scene:new()
    return setmetatable(
        { layers = {}, visible = true },
        scene
    )
end

--- Called for first time initialization.
---
--- @param data table Data for new scene
function scene:load(data) end

--- Called on transition from another scene.
---
--- @param data any
function scene:enter(data)
    header.reset()
    header.append("B", (#export.stack.active > 1) and "Back" or "Quit")
    header.updatePosition()
    local focus = self:focused()
    self.visible = true

    if focus and focus.onFocus then
        focus:onFocus(data)
    end
end

--- Called on transition to another scene.
---
--- @param data table Data for next scene
function scene:leave(data)
    local focus = self:focused()
    self.visible = false
    self:release()

    if focus and focus.onFocusLost then
        focus:onFocusLost(data)
    end
end

function scene:close(data) end

function scene:release()

    for _,layer in ipairs(self.layers) do
        layer:release()
    end

    --collectgarbage("collect")
end

--- Handle keypress.
---
--- @param key string Id for keypress
function scene.keypressed(self, key)
    local focus = self:focused()

    if focus and focus.onKeyPress then
        focus:onKeyPress(key)
    end

    if key == "z" then

        -- Exit layer
        if #self.layers > 1 then
            self:removeLayer()

        -- Exit scene
        elseif #stack.active > 1 then
            stack:pop()

        -- Exit.
        else
            love.event.push("quit")
        end
    end
end

--- Call `update` for all layers.
---
--- @param dt number Time delta
function scene.update(self, dt)

    for _,layer in ipairs(self.layers) do
        layer:update(dt)
    end
end

--- Call `draw` for all layers.
function scene.draw(self)
    if not self.visible then return end
    love.graphics.clear(config.theme:color("UI", "BACKGROUND"))

    for _,layer in ipairs(self.layers) do
        layer:draw()
    end

    header:draw()
end

--- Add a layer at position.
---
--- @param root badr     Layer root
--- @param pos  integer? Insertion index (default: append)
---
--- @return badr root
function scene:insertLayer(root, pos)
    pos = pos or #self.layers+1
    table.insert(self.layers, pos, root)

    return self.layers[pos]
end

--- Remove a layer at position.
---
--- @param pos integer? Layer index (default: last)
--- 
--- @return badr root
function scene:removeLayer(pos)
    local focused

    if pos == nil then
        focused = self.layers[#self.layers-1].focusedElement
        pos = #self.layers
    end

    local removed = table.remove(self.layers, pos)

    if focused and focused.onFocus then
        focused:onFocus()
    end

    return removed
end

--- Get the top layer.
---
--- @return badr? root Layer root
function scene:top()
    return self.layers[#self.layers]
end

--- Get focused element of top layer.
---
--- @return badr? focusedElement current focus.
function scene:focused()

    if #self.layers > 0 then
        return self.layers[#self.layers].focusedElement
    end
end

--#endregion scene

--#region stack

--- @class stack
---
--- @field source table<string, scene> Scene definitions
--- @field active scene[]              Current scene progression
--- @field change boolean              Set during scene transition
---
stack = {
    source   = {},
    active   = {}
}
stack.__index = stack

--- Inititalize scene manager, and set initial scene.
---
--- @param inital string? Name of initial scene
--- @param data   table?  Data for initial scene
function stack:init(inital, data)
    header.load()
    data = data or {}

    for _,file in ipairs(nativefs.getDirectoryItems("src/ui/scene")) do

        if file:match("[^/]*.lua$") then
            local name = string.gsub(file, ".lua", "")

            if name ~= "init" then
                self.source[name] = require("src.ui.scene."..name)
            end
        end
    end

    if inital then
        self:push(inital, data)
    end
end

--- Navigate to next scene.
---
--- @param name string Name of next scene
--- @param data table? Data for next scene
function stack:push(name, data)
    data = data or {}

    if self.active[#self.active] then
        self.active[#self.active]:leave(data)
    end

    table.insert(self.active, self.source[name]:new())
    self.active[#self.active]:load(data)
    self.active[#self.active]:enter(data)
end

--- Return to previous scene.
function stack:pop(data)
    data = data or {}

    if #self.active > 1 then
        self.active[#self.active]:close()
        self.active[#self.active] = nil
    end

    self.active[#self.active]:enter(data)
end

--- Reset progression to specified scene.
---
--- Clears current scene path, setting the specfied
--- scene as the initial.
---
--- @param name string Name of initial scene
--- @param data table? Data for initial scene
function stack:reset(name, data)
    data = data or {}

    for i, _ in ipairs(self.active) do
        table.remove(self.active, i)
    end

    self.active = {}
    self:push(name, data)
end

--- Processes scene keypress logic.
---
--- @param key string Key pressed
function stack:keypressed(key)
    self.active[#self.active]:keypressed(key)
end

--- Processes scene update logic.
---
--- @param dt number Time delta
function stack:update(dt)
    self.active[#self.active]:update(dt)
end

--- Process scene render logic.
function stack:draw()
    self.active[#self.active]:draw()
    -- local luaMem = collectgarbage("count") / 1024  -- MB
    -- local stats = love.graphics.getStats()
    -- local texMem = stats.texturememory / (1024 * 1024)  -- MB
    -- love.graphics.print("Lua Mem: " .. luaMem .. " MB | Tex Mem: " .. texMem .. " MB", 10, 10)
end

function stack:current()
    return self.active[#self.active]
end

--#endregion stack

export = {
    --- Base type for a scene.
    --- @overload fun(props: table<string, any>): scene
    scene = setmetatable(
        { new = scene.new },
        { __index = scene, __call = function (t) return scene:new() end }
    ),
    --- Global scene manager.
    --- @type stack
    stack = stack,
    header = header
}

return export