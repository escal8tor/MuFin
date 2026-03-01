---@diagnostic disable: return-type-mismatch
local badr   = require "src.ui.component.badr"
local config = require "src.external.config"
local fonts  = require "src.ui.component.font"
local header = require "src.ui.component.header"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"

--#region accordion

--- @class accordion : badr
--- 
--- THEMING
--- @field normalFg  string Normal text color
--- @field normalBg  string Normal background color
--- @field focusedFg string Focused text color
--- @field focusedBg string Focused background color
--- 
--- STATE
--- @field collapsed boolean Set while component is collapsed
--- @field cHeight   number  Height while collapsed
--- @field fHeight   number  Height while expanded
--- @field sEnd      number  Final index of substring when collapsed
---
--- INPUT
--- @field btnHeld   boolean Set while directional is held
--- @field rDelay    number  Delay between dir. press and first rep
--- @field rIntvl    number  Delay for subsequent reps
--- @field sTime     number? Start time for key hold
--- @field _thresh   number  Current rep. threshold
--- 
--- SCROLL
--- @field cScroll scroll? Scroll affected by this object
--- @field delta   number? Scroll delta per-input
--- 
--- UI component for collapsible text area.
local accordion = badr {}
accordion.__index = accordion

--- Create new accordion object.
--- 
--- @param props table Component properties
--- 
--- @return accordion accordion New accordion object.
function accordion:new(props)
    props = props or {}

    local proto = {
        focusable = true,
        content   = props.text,
        width     = props.width or _G.W_WIDTH,
        height    = props.height,
        font      = text.normFont(props.font),
        align     = props.align or "left",
        normalFg  = props.normalFg or "ACCORDION:NORMAL_FG",
        normalBg  = props.normalBg or "ACCORDION:NORMAL_BG",
        focusedFg = props.focusedFg or "ACCORDION:FOCUSED_FG",
        focusedBg = props.focusedBg or "ACCORDION:FOCUSED_BG",
        wrap      = type(props.wrap) == "number" and props.wrap or 1,
        collapsed = true,
        vpPos     = 0,
        rDelay    = 0.1,
        rIntvl    = 0.1
    }

    local _

    _, proto.height, proto.sEnd = text.contentDime(proto, proto.wrap)
    proto.cHeight = proto.height
    _, proto.fHeight, _ = text.contentDime(proto, true)
    proto.colorFg = proto.normalFg
    proto.colorBg = proto.normalBg
    proto.delta = fonts[proto.font]:getHeight() * 1.75

    --- Copy over remaining properties.
    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    return setmetatable(badr(proto), accordion)
end

function accordion:setContainerScroll(other)
    self.cScroll = other
end

function accordion:onFocus()
    self.colorFg = self.focusedFg
    self.colorBg = self.focusedBg
    self:updateHeader()
end

function accordion:onFocusLost()
    self.colorFg = self.normalFg
    self.colorBg = self.normalBg
end

function accordion:updateHeader()
    header.reset()

    if self.fHeight > self.cHeight then

        if self.collapsed then
            header.append("A", "Open")
        else
            header.append("DP", "Scroll")
            header.append("A",  "Close")
        end
    end

    header.append("B", (#ui.stack.active > 1) and "Back" or "Quit")
    header.updatePosition()
end

function accordion:toggle()
    self.collapsed = not self.collapsed
    self.height = self.collapsed and self.cHeight or self.fHeight
    self.vpPos = 0
    self.sTime = nil
    self.lastKey = nil
    self._thresh = self.rDelay
    self.parent:refreshLayout()
    self:updateHeader()
end

function accordion:onKeyPress(key)

    if self.fHeight > self.cHeight then

        if key == "x" or ((key == "left" or key == "right") and not self.collapsed) then
            self:toggle()

            return
        end

        if not self.collapsed and self.cScroll and (key == "up" or key == "down") then
            local delta = key == "up" and -self.delta or self.delta
            self.vpPos = self.vpPos + delta

            -- Scroll if both object and container scroll can continue.
            if self.cScroll:scrollDelta(delta) then
                self.sTime   = love.timer.getTime()
                self.lastKey = key

            -- Stop if repeating.
            elseif self.lastKey then
                self.sTime = nil
                self.lastKey = nil
            end

            return
        end
    end

    if self.parent and (key == "up" or key == "down") then
        local focused = self:getRoot().focusedElement
        local nxFocus = self.parent:getNextFocusable(key == "down" and "next" or "previous")

        if nxFocus and nxFocus ~= focused then
            self:setFocus(nxFocus)

            if not self.collapsed then
                self:toggle()
            end

            if self.cScroll then
                self.cScroll:scrollToFocused(nxFocus)
            end
        end
    end
end

function accordion:draw()
    if not self.visible then return end
    love.graphics.push()
    love.graphics.setFont(fonts[self.font])
    love.graphics.setColor(config.theme:color(self.colorBg))
    love.graphics.stencil(
        function () love.graphics.rectangle("fill", self.x, self.y, self.width, self.height) end,
        "replace", 1
    )
    love.graphics.setStencilTest("greater", 0)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(config.theme:color(self.colorFg))

    if self.collapsed then
        pcall(function ()
            local sEnd = self.sEnd ~= 0 and self.sEnd or self.content:len()
            love.graphics.printf(self.content:sub(1, sEnd), self.x, self.y, self.width, self.align)
        end)

    else
        love.graphics.printf(self.content, self.x, self.y, self.width, self.align)
    end

    love.graphics.setStencilTest()
    love.graphics.pop()
end

function accordion:update(dt)
    if not self.cScroll then return end

    if self.lastKey and self.sTime ~= nil then

        if (love.timer.getTime() - self.sTime) >= self._thresh then

            if love.keyboard.isDown(self.lastKey) then
                self._thresh = self.rIntvl
                self:onKeyPress(self.lastKey)
                return
            end

            self._thresh = self.rDelay
            self.lastKey = nil
            self.sTime = nil
        end
    end
end

--#endregion accordion

--- @overload fun(props: table): text
local export = setmetatable(
    {
        new = accordion.new,
    },
    {
        __call = function (t, ...) return accordion:new(...) end,
        __index = accordion
    }
)

return export