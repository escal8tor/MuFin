---@diagnostic disable: duplicate-set-field, assign-type-mismatch, param-type-mismatch
local math   = require "math"
local scroll = require "src.ui.component.scroll"

--- @class grid:scroll
--- 
--- @field madDime number
--- 
local grid = scroll {}
grid.__index = grid

function grid:new(props)
    props = props or {}
    props.type = props.type or "vt"
    local proto = { step = 0, vl = 0 }

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- @type grid
    local object = setmetatable(scroll(proto), grid)
    object.pvp = "right"
    object.nxp = "left"

    return object
end
local downloader = love.thread

function grid:__add(other)
    assert(other or type(other) ~= "table", "Cannot add "..type(other).." object.")
    local ct = { width = 0, height = 0, groups = 0, maxDime = 0 }
    local last = { [self.oa] = 0, [self.od] = 0 }

    for _, child in ipairs(self.children) do

        if child[self.oa] == last[self.oa] then
            ct[self.od] = ct[self.od] + child[self.od]
            ct.maxDime  = math.max(ct.maxDime, child[self.sd])

        else
            ct[self.od] = child[self.od]
            ct[self.sd] = ct[self.sd] + ct.maxDime
            ct.maxDime  = child[self.sd]
        end

        last = child
    end

    other.parent = self
    other.visible = false
    other.x = self.x + other.x
    other.y = self.y + other.y

    if self[self.cod] + other[self.od] < self[self.od] then
        other[self.oa] = (last[self.od] or 0) + (last[self.oa] or self[self.oa])
        other[self.sa] = last[self.sa] or self[self.sa]

        if #self.children > 0 then
            other[self.oa] = other[self.oa] + self.gap
        end

        self[self.csd] = math.max(self[self.sd],  self[self.csd])
        self[self.sd]  = math.max(self[self.sd],  other[self.sd])
        self[self.cod] = math.max(self[self.cod], self[self.cod] + other[self.od] + self.gap)

    else

        if self.step == 0 then
            self.step = #self.children
        end

        ct.maxDime = math.max(other[self.sd], ct.maxDime)
        other[self.sa] = ct.maxDime + (last[self.sa] or self[self.sa])

        if #self.children > 0 then
            other[self.sa] = other[self.sa] + self.gap
        end

        self[self.cod] = other[self.od]
        self[self.od]  = math.max(self[self.od], other[self.od])
        self[self.csd] = other[self.sa] + other[self.sd]
        self.maxDime   = other[self.sd]
    end

    if #other.children > 0 then

        for _, child in ipairs(other.children) do
            child:updatePosition(other.x, other.y)
        end
    end

    self.children[#self.children+1] = other

    return self
end

--- Update component.
---
--- @param dt number Time delta
function grid:update(dt)
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

        elseif i == self.vf and self.vf < #self.children then
            self.vf = self.vf + 1
        end
    end

    if self.sTime ~= nil then

        if (love.timer.getTime() - self.sTime) >= self._thresh then

            if love.keyboard.isDown(self.lastKey) then

                if self:onKeyPress(self.lastKey) then
                    self._thresh = self.rIntvl
                    self.btnHeld = true
                    return
                end
            end

            self._thresh = self.rDelay
            self.lastKey = nil
            self.sTime = nil
        end
    end
end

function grid:onKeyPress(key)
    local root = self:getRoot()
    local nxFoc

    if key == self.pvc or key == self.nxc then
        nxFoc = self:nextFocusableChild(key, self.step)

    elseif key == self.nxp then
        nxFoc = self:nextFocusableChild(self.pvc)

    elseif key == self.pvp then
        nxFoc = self:nextFocusableChild(self.nxc)
    end

    if nxFoc and nxFoc ~= root.focusedElement then
        self.lastFocused = root.focusedElement
        self.sTime = love.timer.getTime()
        self.lastKey = key
        self:scrollToFocused(nxFoc)
        self:setFocus(nxFoc)

        return true
    end

    return false
end

--- @overload fun(props: table<string, any>): grid
local export = setmetatable(
  { new = grid.new },
  {__call = function (t, ...) return grid:new(...) end}
)

return export
