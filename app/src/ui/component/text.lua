---@diagnostic disable: missing-return-value
local badr   = require "src.ui.component.badr"
local config = require "src.external.config"
local flux   = require "src.external.flux"
local fonts  = require "src.ui.component.font"
local math   = require "math"

--- Normalize color property
--- 
--- @param id string? Color id or name
--- 
--- @return string id Normalized color id
local function normColor(id)

    if type(id) == "string" then
        id = id:upper()

        if not id:find(":") then
            id = "TEXT:"..id
        end

    elseif not id then
        id = "TEXT:NORMAL"
    end

    return id
end

--- Normalize font property
---
--- @param name string? Font name
--- 
--- @return string name Normalized font name
local function normFont(name)

    if type(name) == "string" then
        name = name:lower()
        assert(fonts[name], "No such font: "..name)

    else
        name = "normal"
    end

    return name
end

--- @alias align "center" | "justify" | "left" | "right"

--- @class text:badr
--- 
--- @field protected scroll scrDirection? Enables scrolling in specified direction
--- @field protected vx     number        Viewport X coordinate
--- @field protected vy     number        Viewport Y coordinate
--- @field protected sEnd   integer       Index for end of visible content when viewport is a rest
--- 
--- @field group   flux?  Flux group for animation
--- @field content string Text content
--- @field font    string Font name
--- @field align   align  Text alignment
--- @field color   color  Color Id
--- @field tail    string Appended to content as separator when scrolling horizontally
--- 
--- Text area UI component
local text = badr {}
text.__index = text

--- Create new text component.
--- 
--- @param props table Component properties
--- 
--- @return text text New text object.
function text:new(props)
    props = props or {}

    local proto = {
        id      = props.id,
        content = props.text,
        width   = props.width,
        height  = props.height,
        font    = normFont(props.font),
        color   = normColor(props.color),
        delay   = props.delay,
        align   = props.align or "left",
        scroll  = props.scroll,
        speed   = props.speed,
        group   = flux.group(),
        tail    = props.tail or " | ",
        loop    = 0,
        vx     = 0,
        vy     = 0,
    }

    -- Calculate dimensions of object based on content
    local wTxt, hTxt, sEnd = text.contentDime(proto, props.wrap)
    proto.height = proto.height or hTxt
    proto.width  = proto.width or wTxt
    proto.sEnd   = sEnd

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- @type text
    return setmetatable(badr(proto), text)
end

--- Calculate width and height of content
--- 
--- @param self     text     Text object
--- @param wrap     boolean? Wrap text if it exceeds object's width
--- 
--- @return number width     Content width
--- @return number height    Content height
--- @return number substring Cutoff index for visible content.
--- @overload fun(self: text, maxLines: number): number, number, number
function text.contentDime(self, wrap)
    if not self.content then return end
    local sEnd = 0
    local height = fonts[self.font]:getHeight()
    local width, lines

    -- A desired width was specified, and wrapping was requested.
    if self.width and wrap then
        width, lines = fonts[self.font]:getWrap(self.content, self.width)

        if type(wrap) == "number" then
            height = math.min((height * #lines), (height * wrap))

            for i=1, math.min(#lines, wrap) do
                sEnd = sEnd + lines[i]:len()
            end
        else
            height = height * #lines
        end
    else
        width = fonts[self.font]:getWidth(self.content)
    end

    return width, height, sEnd
end

function text:onFocus()
    if not self.scroll then return end
    local wTxt, hTxt, _ = self:contentDime(self.scroll == "vt")
    local delay = self.delay or 5

    if self.tween ~= nil then
        self.tween:stop()
        self.tween = nil
    end

    local function reset()
        self.tween = self.group
            :to(self, 0, { vx = 0, vy = 0 } )
            :delay(delay)
            :oncomplete(function()
                self.tween = nil
            end)
    end

    if self.scroll == "vt" and hTxt > self.height then
        local endPos = hTxt - self.height + 2
        local speed = self.speed or 0.122

        --- @type tween
        self.tween = self.group
            -- Scroll to end position.
            :to(self, endPos * speed, { vy = endPos })
            :ease("linear")
            :delay(delay)
            :oncomplete(reset)

    elseif self.scroll == "hz" and wTxt > self.width then
        local wTail = fonts[self.font]:getWidth(self.tail)
        local speed = self.speed or 0.061

        --- @type tween
        self.tween = self.group
            :to(self, wTxt * speed, { vx = wTxt + wTail })
            :ease("linear")
            :delay(delay)
            :oncomplete(reset)
    end
end

function text:onFocusLost()
    if self.tween == nil then return end
    self.tween:stop()
    self.tween = nil
    self.vx = 0
    self.vy = 0
end

function text:update(dt)
    if self.tween == nil then return end
    self.group:update(dt)
end

function text:draw()
    if not self.visible then return end
    love.graphics.push()
    love.graphics.setFont(fonts[self.font])
    love.graphics.setColor(config.theme:color(self.color))
    love.graphics.stencil(
        function () love.graphics.rectangle("fill", self.x, self.y, self.width, self.height) end,
        "replace", 1
    )
    love.graphics.setStencilTest("greater", 0)
    love.graphics.translate(-self.vx, -self.vy)

    if self.vx == 0 then -- the vp hasn't scrolled horizontally

        if self.vy == 0 then -- the vp hasn't scrolled vertically either.
            pcall(function ()
                local sEnd = self.sEnd ~= 0 and self.sEnd or self.content:len()

                -- When the viewport is at rest, only draw what's visible. this prevents
                -- long synopsies from tanking performance.
                love.graphics.printf(
                    self.content:sub(1, sEnd),
                    self.x,
                    self.y,
                    self.width,
                    self.align
                )
            end)

        else
            love.graphics.printf(
                self.content,
                self.x,
                self.y,
                self.width,
                self.align
            )
        end
    else
        -- 
        love.graphics.print(
            self.content..self.tail..self.content,
            self.x,
            self.y
        )
    end

    love.graphics.setStencilTest()
    love.graphics.pop()
end

--- @overload fun(props: table): text
local export = setmetatable(
    { new = text.new },
    { __call = function (t, ...) return text:new(...) end }
)

return export