local flux = require "src.external.flux"

---@diagnostic disable: return-type-mismatch, need-check-nil
---
--- Badr
---
--- Copyright (c) 2024 Nabeel20
---
--- This library is free software; you can redistribute it and/or modify it
--- under the terms of the MIT license. See LICENSE for details.
--- 
--- Focus-related methods added by gabrielfvale

--- @class badr
---
--- @field protected children badr[] Child objects
--- @field protected parent   badr   Parent object
--- @field protected group    flux?  Animation group
---
--- @field id        string   Unique identifier for object
--- @field x         integer  X-coordinate of object
--- @field y         integer  Y-coordinate of object
--- @field height    integer  Height of object
--- @field width     integer  Width of object
--- @field tmg       number   Margin top
--- @field bmg       number   Margin bottom
--- @field lmg       number   Margin left
--- @field rmg       number   Margin right
--- @field visible   boolean  Toggles draw logic
--- @field focusable boolean  Controls whether object can be focused
--- @field focused   boolean  Whether object is focused
--- @field root      badr     Reference to root component
---
--- @field focusedElement badr?    Currently focused element (only set for root component)
---
--- Base UI element type.
local badr = {}
badr.__index = badr

--- Create a new [badr](lua://badr) object.
---
--- @param props table? object properties
---
--- @return badr object new object
function badr:new(props)
    props = props or {}

    local proto = {
        x = 0,
        y = 0,
        height = 0,
        width = 0,
        parent = props.parent or nil,
        id = tostring(love.timer.getTime()),
        visible = true,
        children = {},
        focusable = false,
        focused = false,
        tmg = props.tmg or 0,
        bmg = props.bmg or 0,
        lmg = props.lmg or 0,
        rmg = props.rmg or 0
    }

    for key, value in pairs(props) do
        proto[key] = value
    end

    local object = setmetatable(proto, badr)

    if object.focusable and not (object.root and object.root.focusedElement) then
        object.root = self:getRoot()
    end

    return object
end

--- Add a child [badr](lua://badr) object. 
--- 
--- @param child badr Object to add. 
--- 
--- @return badr self? Updated object.
function badr:__add(child)
    assert(child or type(child) ~= "table", "Cannot add "..type(child).." object.")
    child.parent = self
    child.x = self.x + child.x + self.lmg
    child.y = self.y + child.y + self.tmg
    local childrenSize = { width = 0, height = 0 }

    for _, object in ipairs(self.children) do
        childrenSize.width = childrenSize.width + object.width
        childrenSize.height = childrenSize.height + object.height
    end

    local gap = self.gap or 0
    local lastChild = self.children[#self.children] or {}

    if self.column then
        child.y = (lastChild.height or 0) + (lastChild.y or self.y)

        if #self.children > 0 then
            child.y = child.y + gap
        else
            child.y = child.y + self.tmg
        end

        self.height = math.max(self.height, childrenSize.height + child.height + gap * #self.children)
        self.width = math.max(self.width, child.width + self.rmg)
    end

    if self.row then
        child.x = (lastChild.width or 0) + (lastChild.x or self.x)

        if #self.children > 0 then
            child.x = child.x + gap
        else
            child.x = child.x + self.lmg
        end

        self.width = math.max(self.width, childrenSize.width + child.width + gap * #self.children)
        self.height = math.max(self.height, child.height + self.bmg)
    end

    if #child.children > 0 then

        for _, object in ipairs(child.children) do
            object:updatePosition(child.x, child.y)
        end
    end

    table.insert(self.children, child)

    return self
end

--- Remove child
---
--- Removes `component` from object's `children`.
---
--- @param self badr
--- @param component badr child component
---
--- @return badr self updated object
function badr.__sub(self, component)

    if self % component.id then -- check component is, indeed, a child.

        for index, child in ipairs(self.children) do -- find it's index and remove it.

            if child.id == component.id then
                table.remove(self.children, index)
            end
        end
    end

    return self
end

--- Get child by ID
---
--- Returns child of this object with `id`,
--- or `nil` on miss.
---
--- @param self badr
--- @param id string component identifier
---
--- @return badr|nil child component
function badr.__mod(self, id)
    assert(type(id) == "string", 'Badar; Provided id must be a string.')

    for _, child in ipairs(self.children) do

        if child.id == id then
            return child
        end
    end
end

--- Get any child by ID
---
--- Returns child of this object, or any of it's children,
--- with `id`. Returns `nil` on miss.
---
--- @param self badr
--- @param id string component identifier
---
--- @return badr|nil child component
function badr.__pow(self, id)
    assert(type(id) == "string", 'Badr: Provided id must be a string.')

    -- Helper function to perform recursive search
    local function search(children)
        for _, child in ipairs(children) do

            if child.id == id then
                return child
            end

            -- Recursive call to search in the child’s children
            local found = search(child.children or {})

            if found then
                return found
            end
        end
    end

    -- Start the search from the current instance’s children
    return search(self.children)
end

--- Return the first available flux group
--- 
--- @param min integer? Minimum to traverse
--- 
--- @return flux? group First group within range
function badr.getGroup(obj, min)
    local lvl = 1
    min = min or 1

    while obj.parent do

        if lvl >= min and obj.group then
            return obj.group
        end

        obj = obj.parent
        lvl = lvl + 1
    end

    error("No group found.")
end

--- Check for relation to `child`
---
--- @param child badr object to check against
---
--- @return boolean related relation status
function badr:isAncestorOf(child)
    if not child then return false end

    while child do

        if child == self then
            return true
        end

        child = child.parent
    end

    return false
end

--- Executes object draw routine, provided it's visible.
function badr:draw()
    if not self.visible then
        return
    end

    if #self.children > 0 then

        for _, child in ipairs(self.children) do
            child:draw()
        end
    end
end

--- Adds delta to object's coordinates.
---
--- @param x integer Delta X.
--- @param y integer Delta Y.
function badr:updatePosition(x, y)
    self.x = self.x + x
    self.y = self.y + y

    for _, child in ipairs(self.children) do
        child:updatePosition(x, y)
    end
end

--- Set object's position to (x,y).
--- 
--- @param x integer X coordinate
--- @param y integer Y coordinate
function badr:setPosition(x, y)
    local dx, dy = x - self.x, y - self.y
    self.x, self.y = x, y

    for _, child in ipairs(self.children) do
        child:updatePosition(dx,dy)
    end
end

--- Apply animation to this object.
---
--- @param props table|function Must be callable.
function badr:animate(props)
    props(self)

    for _, child in ipairs(self.children) do
        child:animate(props)
    end
end

--- Calls object's `onUpdate`.
---
--- @param dt table Update data.
function badr:update(dt)

    if self.group then
        self.group:update(dt)
    end

    if self.onUpdate then
        self:onUpdate(dt)
    end

    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

-- Focus-related methods
-- Added by gabrielfvale

--- Retreive root component.
---
--- @return badr root component.
function badr:getRoot()
    local root = self

    while root.parent do
        root = root.parent -- Traverse up to find the root
    end

    return root
end

--- Set focus on `component`.
---
--- @param component badr component to focus
function badr:setFocus(component)
    local root = self:getRoot() -- Get the root node of the element
    
    if component.focusable and component ~= root.focusedElement then
        
        if root.focusedElement then
            root.focusedElement.focused = false -- Unfocus the current element
            
            if root.focusedElement.onFocusLost then
                root.focusedElement:onFocusLost()
            end
        end
        
        component.focused = true -- Set the new element as focused

        if component.onFocus then
            component:onFocus()
        end

        --- @type badr Focused element
        root.focusedElement = component
    end
end

--- Get all focusable children of this component.
--- 
--- @param parent badr Parent component.
--- 
--- @return badr[] focusable Child components
function badr.gatherFocusableChildren(parent)
    local focusable = {}

    for _,child in ipairs(parent.children or {}) do

        if child.focusable and not child.disabled then
            table.insert(focusable, child)
        end
    end

    return focusable
end

--- Gather focusable components.
---
--- Assembles a table of all foucsable components in the tree,
--- starting at `root`.
---
--- @param ancestor badr Ancestor component
---
--- @return badr[] focusable Decendent components
function badr.gatherFocusableDecendents(ancestor)
    local focusable = {}

    local function gather(parent)
        if parent.focusable and not parent.disabled then
            table.insert(focusable, parent)
        end

        for _, child in ipairs(parent.children or {}) do
            gather(child)
        end
    end

    gather(ancestor)
    return focusable
end

--- Get next focusable component.
---
--- Returns next focusable in tree for `direction`, or `nil` if none exist.
---
--- @param direction string "previous" or "next"
---
--- @return badr|nil next next focusable component
function badr:getNextFocusable(direction)
    local root = self:getRoot() -- Focus within the current root context
    local focusables = badr.gatherFocusableDecendents(root)

    for idx, component in ipairs(focusables) do

        if component == root.focusedElement then
            if direction == "previous" then
                nextIndex = idx > 1 and idx - 1 or #focusables
            elseif direction == "next" then
                nextIndex = idx < #focusables and idx + 1 or 1
            end

            return focusables[nextIndex]
        end
    end
end

--- Get Nth next focusable component.
---
--- Returns the next focusable in the tree, delta `n` from current focusable
--- in the specified `direction`. If `n` exceeds the number of focusables in
--- `direction`, returns the first or last focusable instead. Returns `nil`
--- if no focusables exist.
---
--- @param direction string "previous" or "next"
--- @param n integer delta
---
--- @return badr|nil nth
function badr:getNthFocusable(direction, n)
    local root = self:getRoot() -- Focus within the current root context
    local focusables = badr.gatherFocusableDecendents(root)
    local currentIndex = nil

    for i, component in ipairs(focusables) do

        if component == root.focusedElement then
            currentIndex = i
            break
        end
    end

    if not currentIndex then return nil end

    local nextIndex
    local total = #focusables

    if direction == "previous" then
        nextIndex = math.max(1, currentIndex - n) -- go to -n or the first element
    elseif direction == "next" then
        nextIndex = math.min(total, currentIndex + n) -- go to +n or the last element
    end

    nextIndex = math.max(1, math.min(total, nextIndex))

    return focusables[nextIndex]
end

--- Sets focus on first focusable element in the tree.
function badr:focusFirstElement()
    local root = self:getRoot() -- Get the root context of this element

    for _, child in ipairs(badr.gatherFocusableDecendents(root)) do
        root:setFocus(child)      -- Set focus to the first focusable element
        break
    end
end

--- Default handler for keyboard navigation.
---
--- @param key string individual key pressed (e.g. "a", "[", etc.).
function badr:keypressed(key)
    local root = self:getRoot()
    if not root.focusedElement then return end

    if root.focusedElement.onKeyPress then
        root.focusedElement:onKeyPress(key)
    end
end

--#region export

---@overload fun(table):badr
local export = setmetatable({}, {
    __call = function(t, ...) return badr:new(...) end,
    __index = badr
})

--- Create a new root object.
--- 
--- @param props table Object properties
--- 
--- @return badr root Root object
function export:root(props)
    props = props or {}
    props.focusedElement = nil
    props.group = flux.group()
    return self:new(props)
end

return export

--#endregion export