local config = require "src.external.config"
local fonts  = require "src.ui.component.font"
local text   = require "src.ui.component.text"
local utils  = require "src.external.utils"

--#region button

--- @class button:text
local button = text {}
button.__index = button

function button:new(props)
    props = props or {}

    local proto = {
        action    = props.action,
        visible   = props.visible ~= nil and props.visible or true,
        focusable = props.focusable or true,
        align     = props.align or "center",
        cr        = props.cornerRadius or 0,
        nfill     = props.nfill or "BUTTON:NORMAL_FILL",
        ntext     = props.ntext or "BUTTON:NORMAL_TEXT",
        ffill     = props.ffill or "BUTTON:FOCUSED_FILL",
        ftext     = props.ftext or "BUTTON:FOCUSED_TEXT"
    }

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    local object = setmetatable(text(proto), button)
    object.height = object.height + (fonts[object.font]:getLineHeight() + 2)
    object.sEnd = nil

    return object
end

function button:onFocus()
end

function button:onFocusLost()
end

function button:setWidth(width)
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

function button:onKeyPress(key)

    if key == "x" and self.action then
        self.action()

    elseif self.parent.onKeyPress then
        self.parent:onKeyPress(key)
    end
end

function button:draw()
    if not self.visible then return end
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
    love.graphics.setColor(config.theme:color(self.focused and self.ffill or self.nfill))
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cr, self.cr)
    love.graphics.setColor(config.theme:color(self.focused and self.ftext or self.ntext))
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

--#endregion button

---@overload fun(table):button
local export = setmetatable({
    new = button:new()
},{
    __call = function(t, ...) return button:new(...) end,
    __index = button
})

return export