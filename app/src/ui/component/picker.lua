---@diagnostic disable: cast-local-type
local badr   = require "src.ui.component.badr"
local fonts  = require "src.ui.component.font"
local header = require "src.ui.component.header"
local scroll = require "src.ui.component.scroll"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"

--#region pickerOption

--- @class pickerOption : badr
--- 
--- THEMING
--- @field normalFg  string Normal text color
--- @field normalBg  string Normal background color
--- @field focusedFg string Focused text color
--- @field focusedBg string Focused background color
--- @field font      string Font name
--- @field align     align  Text alignment
--- 
--- PROPERTIES
--- @field content string Discriptive text for selection
--- @field value   any    Value the component represents
--- 
local pickerOption = badr {}
pickerOption.__index = pickerOption

function pickerOption:new(props)
    props = props or {}

    local proto = {
        content   = props.content,
        value     = props.value,
        normalFg  = props.normalFg  or "PICKER:NORMAL_FG",
        normalBg  = props.normalBg  or "PICKER:NORMAL_BG",
        focusedFg = props.focusedFg or "PICKER:FOCUSED_FG",
        focusedBg = props.focusedBg or "PICKER:FOCUSED_BG",
        font      = text.normFont(props.font),
        lmg       = props.lmg or 10,
        rmg       = props.rmg or 10,
        align     = props.align or "center",
        focusable = true,
        sEnd      = 0
    }

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    proto.height = (proto.height or 0) + (fonts[proto.font]:getLineHeight() + 2)

    return setmetatable(badr(proto), pickerOption)
end

function pickerOption:onFocus()
    header.reset()
    header.append("DP", "Select")
    header.append("B", (#ui.stack.active > 1) and "Back" or "Quit")
    header.updatePosition()
end

function pickerOption:setWidth(width)
    self.width = width
    local _, lines = fonts[self.font]:getWrap(
        self.content,
        self.width - self.lmg - self.rmg
    )

    if #lines > 1 then
        self.sEnd = lines[1]:len() - 3
    else
        self.sEnd = nil
    end
end

function pickerOption:onKeyPress(key)
    self.parent:onKeyPress(key)
end

function pickerOption:draw()
    if not self.visible then return end
    local colorFg = self.focused and self.focusedFg or self.normalFg
    local colorBg = self.focused and self.focusedBg or self.normalBg

    love.graphics.push()
    love.graphics.setFont(fonts[self.font])
    love.graphics.stencil(
        function ()
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cr, self.cr)
        end,
        "increment",
        1,
        true
    )
    love.graphics.setStencilTest("greater", 1)
    love.graphics.setColor(config.theme:color(colorBg))
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cr, self.cr)
    love.graphics.setColor(config.theme:color(colorFg))
    love.graphics.printf(
        self.content:sub(1, self.sEnd)..(self.sEnd and "..." or ""),
        self.x + self.lmg,
        self.y + self.tmg,
        self.width - self.lmg - self.rmg,
        self.align
    )
    love.graphics.setStencilTest()
    love.graphics.pop()
end

--#endregion pickerOption

--#region picker

--- @class picker : scroll
---
--- Input UI component for choosing from a pre-defined set of options 
local picker = scroll {}
picker.__index = picker

function picker:new(props, options)
    props = props or {}

    local proto = {
        id        = props.id,
        type      = "hz",
        bias      = "lazy",
        duration  = 0,
        focusable = false
    }

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    local object = setmetatable(scroll(proto), picker)

    for index, option in ipairs(options) do

        local optionProps = {
            id        = object.id.."_"..(option.id or index),
            content   = option.label,
            value     = option.value,
            normalFg  = props.normalFg,
            normalBg  = props.normalBg,
            focusedFg = props.focusedFg,
            focusedBg = props.focusedBg,
            width     = object.width,
            height    = object.height
        }

        for key, value in pairs(option) do
            if not proto[key] then
                proto[key] = value
            end
        end

        object = object + pickerOption:new(optionProps)
    end

    return object
end

function picker.__add(self, other)
    local initialWidth = self.width
    local updated = scroll.__add(self, other)
    updated.width = initialWidth

    return updated
end

function picker:draw()
    love.graphics.push()
    love.graphics.stencil(
        function() love.graphics.rectangle("fill", self.x, self.y, self.width, self.height) end,
        "replace",
        1
    )
    love.graphics.setStencilTest("greater", 0)
    love.graphics.translate(-self.vx, -self.vy)
    love.graphics.setColor(config.theme:color(self.bgColor))
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1,1,1,1)

    for _, child in ipairs(self.children) do

        if child.visible then
            child:draw()
        end
    end

    love.graphics.setStencilTest()
    love.graphics.pop()
end

--#endregion picker

--#region exports

local exports = {}

function exports:newStreamPicker(streams, props)
    local options = {}

    for _, stream in ipairs(streams) do
        options = options + {
            id        = stream.Type:lower().."_"..tostring(stream.Index),
            stype     = stream.Type,
            index     = stream.Index,
            isDefault = stream.IsDefault,
            label     = stream.DisplayTitle,
            value     = stream.Index
        }
    end

    return picker:new(props, options)
end

--#endregion exports

--- @overload fun(table):picker
exports = etmetatable(
    { streamPicker = function(t, ...) return newStreamPicker(...) end },
    { __call = function(t, ...) return picker:new(...) end, __index = picker }
)

return exports