---@diagnostic disable: need-check-nil, duplicate-set-field, missing-fields, cast-local-type
local badr   = require "src.ui.component.badr"
local flux   = require "src.external.flux"
local math   = require "math"
local utils  = require "src.external.utils"

--#region scroll

--- @alias scrDirection 
--- | "hz" Horizontal
--- | "vt" Vertical

--- @alias scrollBias
--- | "lazy"        Just enough so focused is fully in viewport.
--- | "lazy_center" Center, but only when not fully in viewport.
--- | "center"      Center focused.

--- @alias mvAxis  "x"|"y"                  Position metavariable
--- @alias mvDime  "width"|"height"         Dimension metavariable
--- @alias mvVPos  "vx"|"vy"                Viewport position metavariable
--- @alias mvCDime "cw"|"ch"                Content dimension metavariable
--- @alias mvMarg  "tmg"|"rmg"|"bmg"|"lmg"  Margin metavariable

--- @class scroll:badr
---
--- ANIMATION
--- @field group flux   Flux group for animation
--- @field tween tween? Active scrolling animation
--- 
--- CONTENT
--- @field cw          number  Content width
--- @field ch          number  Content height
--- @field csd         mvCDime Varaible for content dimension in scroll axis
--- @field cod         mvCDime Variable for content dimension other axis
--- @field vf          number  Index of first visible child
--- @field lastFocused badr    Last decendent focused
--- 
--- INPUT
--- @field pvc       string  Key for selecting prev. child
--- @field pvp       string  Key for exiting to previous focusable
--- @field nxc       string  Key for selecting next child
--- @field nxp       string  Key for exiting to next focusable
--- @field btnHeld   boolean Set while directional is held
--- @field wrap      boolean Loop to first element at end
--- @field lockFocus boolean Prevent navigation out of scroll.
--- @field rDelay    number  Delay between dir. press and first rep.
--- @field rIntvl    number  Delay for subsequent reps.
--- @field sTime     number? Start time for key hold.
--- @field _thresh   number  Current rep. threshold.
--- 
--- MARGIN
--- @field smu mvMarg Variable for upper margin in scroll axis 
--- @field smg mvMarg Variable for lower margin in scroll axis
--- @field omu mvMarg Variable for upper margin in other axis
--- @field oml mvMarg variable for lower margin in other axis
--- 
--- SCROLL
--- @field sa          mvAxis     Variable for scroll axis
--- @field oa          mvAxis     Variable for other axis
--- @field bias        scrollBias Location to which focus should be moved
--- @field scrDuration number     Time over which to animate scrolling
--- 
--- VIEWPORT
--- @field vx number Viewport position in x axis
--- @field vy number Viewport position in y axis
--- @field vp mvVPos Variable for viewport position in scroll axis
--- @field sd mvDime Variable for viewport dimension in scroll axis
--- @field od mvDime Variable for viewport dimension in other axis
---
--- Scrolling container for UI components.
local scroll = badr {}
scroll.__index = scroll

--- Create a new scroll object
---
--- @param props table? Component properties
---
--- @return scroll scroll New scroll object
function scroll:new(props)
    props = props or {}

    local proto = {
        bias        = props.bias,
        scrDuration = props.duration or 0.25,
        wrap        = props.wrap,
        lockFocus   = props.lockFocus,
        gap         = props.gap or 0,
        rDelay      = props.delay or 0.3,
        group       = flux.group(),
        cw          = 0,
        ch          = 0,
        vx          = 0,
        vy          = 0,
        vf          = 1,
        lastFocused = nil,
        focusable   = false,
        sTime       = nil
    }

    proto._thresh = proto.rDelay
    proto.rIntvl = proto.rIntvl or (proto.scrDuration/3)

    props.type = props.type or "hz"
    local hz = props.type:lower() == "hz"

    proto.row    = hz
    proto.column = not hz

    --- var/metavar values
    local val = (
        hz and
        {"x","y","width","height","cw","ch","rmg","lmg","bmg","tmg","vx"} or
        {"y","x","height","width","ch","cw","bmg","tmg","rmg","lmg","vy"}
    )

    for i, var in pairs({"sa","oa","sd","od","csd","cod","smu","sml","omu","oml","vp"}) do
        proto[var] = val[i]
    end

    --- default directional keys
    local default = (
        hz and
        {"left","up","right","down"} or
        {"up","left","down","right"}
    )

    for i, var in pairs({"pvc","pvp","nxc","nxp"}) do
        proto[var] = props[var] or default[i]
    end

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- @type scroll
    return setmetatable(badr(proto), scroll)
end

function scroll.__add(self, other)
    assert(other or type(other) ~= "table", "Cannot add "..type(other).." object.")
    local last = self.children[#self.children] or {}
    local ct = { width = 0, height = 0 }

    for _, child in ipairs(self.children) do
        ct.width =  ct.width + child.width
        ct.height = ct.height + child.height
    end

    other.parent = self
    other.visible = false
    other.x = self.x + other.x + self.lmg
    other.y = self.y + other.y + self.tmg

    other[self.sa] = (last[self.sd] or 0)
                   + (last[self.sa] or self[self.sa])
                   + (#self.children > 0 and self.gap or self[self.sml])

    self[self.cod] = math.max(self[self.cod], self[self.od])
    self[self.od]  = math.max(self[self.od],  other[self.od] + self[self.smu])
    self[self.csd] = math.max(self[self.csd], ct[self.sd] + other[self.sd] + self.gap * #self.children)

    if #other.children > 0 then

        for _, child in ipairs(other.children) do
            child:updatePosition(other.x, other.y)
        end
    end

    self.children[#self.children+1] = other
    return self
end

--- Measure an object's distance from the viewport.
---
--- @param other badr Object against which to measure.
---
--- @return number distToPos    Distance to object's position
--- @return number distPlusSize Distance plus object's size
function scroll:relativeTo(other)
    local pos = other[self.sa] - self[self.sa] - self[self.vp]

    return pos, pos + other[self.sd]
end

--- Measure distance from object's center to center of viewport
--- 
--- @param other badr Object against which to measure.
---
--- @return number distToPos
function scroll:relativeToCenter(other)

    return (
        (other[self.sa] + (other[self.sd]/2)) -
        (self[self.vp] + (self[self.sd]/2)) -
        self[self.sa]
    )
end

--- Animate viewport motion.
---
--- @param newPos number New position of viewport
function scroll:setAnimation(newPos, easing)
    easing = easing or "quadinout"

    if self.tween ~= nil then
        easing = "quadout"
        self.tween:stop()
        self.tween = nil
    end

    self.tween = self.group
        :to(self, self.scrDuration, { [self.vp] = newPos })
        :oncomplete(function() self.tween = nil end)
        :ease(easing)
end

--- @protected
--- Scroll focused element into viewport.
--- 
--- @param foc badr Currently focused element.
function scroll:scrollToFocused(foc)
    local np -- New viewport position.

    if self.bias == "center" then
        local d2p = self:relativeToCenter(foc)

        if d2p ~= 0 then
            np = self[self.vp] + d2p
        end

    else
        local d2p, dps = self:relativeTo(foc)
        -- Get distance from viewport to either end
        -- of the focused element.

        if d2p < 0 then
            np = self[self.vp] + d2p
            -- ┄┐L═╗┌┋┐┌┄  Move viewport lesser edge ('┋')
            -- ┄┘╚═G└┋┘└┄  before focused lesser edge ('L')

            if self.bias == "lazy_center" then
                np = np + foc[self.sa] + (foc[self.sd]/2)
            end

        elseif dps > self[self.sd] then
            np = self[self.vp] + dps - self[self.sd]
            -- ┄┐┌┋┐L═╗┌┄  Move viewport greater edge ('┋')
            -- ┄┘└┋┘╚═G└┄  beyond focused greater edge ('G')

            if self.bias == "lazy_center" then
                np = np - foc[self.sa] + (foc[self.sd]/2)
            end
        end
    end

    if np then
        np = math.min(np, (self[self.csd] - self[self.sd]))
        -- ┄┐┊<╎┐╔═╗│  New vp pos. ('╎') cannot exceed content dim. ('│'), 
        -- ┄┘┊└╎┘╚═╝│  less vp dim. ('┊').

        np = math.max(np, 0)
        -- ╎>┊╔═╗┌─┐┌┄  New vp pos. ('╎') is an offset from start of
        -- ╎ │╚═╝└─┘└┄  content ('│'), so it cannot subceed zero ('┊').

        -- If not animating, just snap to new position.
        if self.scrDuration <= 0 then self[self.vp] = np

        else self:setAnimation(np) end
    end
end

--- Evaluate whether child component is visible.
---
--- @param other badr Child component
---
--- @return boolean isVisible
function scroll:inView(other)
    local d2p, dps = self:relativeTo(other)

    return (dps > (d2p - dps)) and
           (d2p < self[self.sd] + other[self.sd])
end

--- Update component.
---
--- @param dt number Time delta
function scroll:update(dt)
    if #self.children < 1 then return end
    self.group:update(dt)

    --- Absolute viewport position
    local avp = self[self.sa] + self[self.vp]

    for i=(self.vf > 1 and self.vf-1 or 1), #self.children do
        local child = self.children[i]
        local d2p = child[self.sa] - avp -- Distance to position
        local hsd = child[self.sd] / 2   -- Half child dimension

        -- Child is visible so long as it is within the viewport
        child.visible = ((d2p + child[self.sd]) >= -hsd) and
                        (d2p < (self[self.sd] + hsd))

        if child.visible then
            child:update(dt)

            if i < self.vf then self.vf = i end

        elseif i > self.vf then break

        elseif i == self.vf and self.vf < #self.children then
            self.vf = self.vf + 1
        end
    end

    if self.lastKey and self.sTime ~= nil then

        if (love.timer.getTime() - self.sTime) >= self._thresh then

            if love.keyboard.isDown(self.lastKey) then

                if self:onKeyPress(self.lastKey) then
                    self._thresh = self.rIntvl
                    return
                end
            end

            self._thresh = self.rDelay
            self.lastKey = nil
            self.sTime = nil
        end
    end
end

--- Draw component.
function scroll:draw()
    love.graphics.push()
    love.graphics.translate(-self.vx, -self.vy)

    for i=self.vf, #self.children do
        local child = self.children[i]

        if child.visible then child:draw()
        else break end
    end

    love.graphics.pop()
end

--- @protected
--- Get index of ajacent item in scroll direction.
---
--- Returns the index of the next adjacent child in the direction
--- corresponding to `key`.
---
--- @param key  string   Directional key
--- @param idx  integer  Index
--- @param size integer  Number of elements
--- @param step integer? Step size (default: 1)
---
--- @return integer next Index of next focusable child.
function scroll:nextIndex(key, idx, size, step)
    step = step or 1

    if key == self.pvc then

        if idx > step then
            idx = idx - step

        elseif self.wrap then
            idx = step - (size - idx)
        end

    elseif key == self.nxc then

        if idx <= (size - step) then
            idx = idx + step

        elseif self.wrap then
            idx = idx + step - size
        end
    end

    return idx
end

--- @protected
--- Get next focusable child
---
--- @param key     string   Key for direction
--- @param step    integer? Step size, 1 by default
--- @param focused badr?    Currently focused element
---
--- @return badr? next Next focusable child
--- @overload fun(key, focused?): badr?
function scroll:nextFocusableChild(key, step, focused)
    local focusable = self:gatherFocusableChildren()
    step = step or 1

    if type(step) == "number" then
        focused = focused or self:getRoot().focusedElement
    else
        focused = step
        step = 1
    end

    for idx, child in ipairs(focusable) do

        if child == focused then
            local nxt = self:nextIndex(key, idx, #focusable, step)

            if focusable[nxt] and focusable[nxt] ~= focused then
                self.lastFocused = focusable[nxt]
                break
            end

            return nil
        end
    end

    return self.lastFocused or focusable[1]
end

--- @protected
--- Find next focusable element in an adjacent scroll.
---
--- @param key string Directional
--- @param foc badr?  Focused element
---
--- @return badr? nxFoc Next focusable decendent
---
--- @see scroll.keypressed
function scroll:nextScroll(key, foc)
    local nxFoc

    local function dive(dec)

        if utils.isInstance(dec, scroll) then
            nxFoc = dec:nextFocusableChild(key)
            if nxFoc then return true end
        end

        for _, child in ipairs(dec.children) do
            if dive(child) then return true end
        end
    end

    -- Identify ancestor of caller.
    for sidx, child in ipairs(self.children) do

        if badr.__pow(child, foc.id) then
            dive(self.children[self:nextIndex(key, sidx, #self.children)])
            return nxFoc
        end
    end
end

--- Handle keypress
function scroll:onKeyPress(key)
    local root = self:getRoot()
    local nxFoc, ancestor

    if key == self.nxc or key == self.pvc then
        nxFoc = self:nextFocusableChild(key, root.focusedElement)

    elseif not self.lockFocus and (key == self.nxp or key == self.pvp) then
        ancestor = self.parent

        while ancestor do

            if utils.isInstance(ancestor, scroll) then
                -- Get next focusable in an ajacent scroll.
                nxFoc = ancestor:nextScroll(key, self)
                break

            elseif ancestor.parent == nil then
                -- Hit root component, find next focusable.
                nxFoc = ancestor:getNextFocusable(
                    key == self.nxp
                    and "previous"
                    or "next"
                )
                break
            end

            ancestor = ancestor.parent
        end
    end

    if nxFoc and nxFoc ~= root.focusedElement then
        self.sTime = love.timer.getTime()
        self.lastKey = key
        self:setFocus(nxFoc)

        if ancestor then
            self.sTime = nil
            self.lastKey = nil

            if ancestor.scrollToFocused then
                ancestor:scrollToFocused(nxFoc)
            end
        else
            self:scrollToFocused(nxFoc)
        end

        return true
    end

    return false
end

--#endregion scroll

--- @overload fun(props: table<string, any>): scroll
local export = setmetatable({
    new = scroll.new
}, {
    __call = function (t, ...) return scroll:new(...) end,
    __index = scroll
})

return export
