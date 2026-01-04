---@diagnostic disable: missing-return-value, return-type-mismatch
local badr   = require "src.ui.component.badr"
local config = require "src.external.config"
local flux   = require "src.external.flux"
local fonts  = require "src.ui.component.font"
local math   = require "math"

--#region helpers

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

--#endregion helpers

--#region text

--- @alias align "center" | "justify" | "left" | "right"

--- @class text : badr
--- comment
--- 
--- @field protected scroll scrDirection?    Enables scrolling in specified direction when set
--- @field protected vx     number           Viewport X coordinate
--- @field protected vy     number           Viewport Y coordinate
--- @field protected sEnd   integer          Index for end of visible content when viewport is a rest
--- 
--- @field group   flux?  Flux group for animation
--- @field content string Text content
--- @field font    string Font name
--- @field align   align  Text alignment
--- @field color   color  Color Id
--- @field tail    string Appended to content as separator when scrolling horizontally
--- 
--- General-purpose text container.
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
        vx      = 0,
        vy      = 0
    }

    -- Calculate dimensions.
    local wTxt, hTxt, sEnd = text.contentDime(proto, props.wrap)
    proto.height = proto.height or hTxt
    proto.width  = proto.width or wTxt
    proto.sEnd   = sEnd

    --- Copy over remaining properties.
    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- @type text
    return setmetatable(badr(proto), text)
end

--- Calculate content dimensions.
--- 
--- This function finds the width and height of a text component for one of four use-cases
--- (automatically, based on the value of `self.width` (wd) and `wrap` (wr)):
--- 
--- ```plain                           
---                                     - use-case - 
---  wd\wr   nil   set   int     1. full-width single line.
---        ┌─────┬─────┬─────┐   2. Truncated single line.
---    nil │  1  │  1  │  1  │   3. Full-height wrapped.
---        │─────┼─────┼─────│   4. Truncated wrapped.              
---    set │  2  │  3  │  4  │
---        └─────┴─────┴─────┘
--- ```
--- 
--- @param self text             Text object
--- @param wrap boolean|integer? Enables line wrapping (up to # lines, if an integer)
---  
--- @return number width     Content width
--- @return number height    Content height
--- @return number substring Cutoff index for visible lines
--- 
--- @overload fun(self: text, maxLines: integer): number, number, number
function text.contentDime(self, wrap)
    if not self.content then return end
    local sEnd = 0
    local height = fonts[self.font]:getHeight()
    local width, lines

    -- A desired width was specified, and wrapping was requested.
    if self.width and wrap then
        width, lines = fonts[self.font]:getWrap(self.content, self.width)

        -- Limit for number of lines to wrap was also specified.
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

--- Handle focus gained.
--- 
--- If scrolling is enabled, and the text within goes beyond the viewport,
--- this will set an animation to gradually scroll in pre-defined direction.
--- Scrolling starts after a delay, progresses at a reasonable speed, and then 
--- snaps back to original position (again, after delay). 
function text:onFocus()
    if not self.scroll then return end
    local wTxt, hTxt, _ = self:contentDime(self.scroll == "vt")
    local delay = self.delay or 5

    if self.tween ~= nil then
        self.tween:stop()
        self.tween = nil
    end

    --- Snap back to original position after delay.
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
            -- Scroll to end position after delay.
            :to(self, endPos * speed, { vy = endPos })
            :ease("linear")
            :delay(delay)
            :oncomplete(reset)

    elseif self.scroll == "hz" and wTxt > self.width then
        local wTail = fonts[self.font]:getWidth(self.tail)
        local speed = self.speed or 0.061

        --- @type tween
        self.tween = self.group
            -- Scroll to end position after delay.
            :to(self, wTxt * speed, { vx = wTxt + wTail })
            :ease("linear")
            :delay(delay)
            :oncomplete(reset)
    end
end

--- Handle focus lost.
--- 
--- If an animation is in-progress, this will clear the animation and snap 
--- the viewport back to it's original position.
function text:onFocusLost()
    if self.tween == nil then return end
    self.tween:stop()
    self.tween = nil
    self.vx = 0
    self.vy = 0
end

--- Update scrolling animation (if assigned).
function text:update(dt)
    if self.tween == nil then return end
    self.group:update(dt)
end

--- Render text component to screen.
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

--#endregion text

--#region collapsibleText

--- @class collapsibleText : text
--- 
--- @field collapsed  boolean Set while text is expanded
--- @field fullHeight number  Uncollapsed text height
--- 
--- UI component for collapsible text area.
local collapsibleText = text:new{}
collapsibleText.__index = collapsibleText

--- Create new collapsibleText component.
--- 
--- @param props table Component properties
--- 
--- @return collapsibleText collapsibleText New text object.
function collapsibleText:new(props)
    local proto = { focusable = true }

    local object = setmetatable(text:new(proto), collapsibleText)

    return object
end

--#endregion collapsibleText

--- @overload fun(props: table): text
local export = setmetatable(
    { new = text.new },
    { __call = function (t, ...) return text:new(...) end }
)

return export