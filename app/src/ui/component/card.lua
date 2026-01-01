local badr   = require "src.ui.component.badr"
-- local button = require "src.ui.component.button"
-- local config = require "src.config"
local header = require "src.ui.component.header"
-- local image  = require "src.ui.component.image"
-- local scroll = require "src.ui.component.scroll"
-- local select = require "src.ui.component.select"
-- local text   = require "src.ui.component.text"
local play   = require "src.helpers.playback"
local ui     = require "src.ui.scene"
-- local utils  = require "src.utils"

--- @class card:badr
--- 
--- @field src table Jellyfin item data
local card = badr {}
card.__index = card

function card:new(props)
    props.image = props.image or 1
    return setmetatable(badr(props), card)
end

function card:__add(child)
    return badr.__add(self, child)
end

-- function card:downloadMenu()
--     local items = {}

--     items[#items+1] = button {
--         text = "All",
--         font = "normal",
--         action = function ()
--             ui.scenes:current():removeLayer()
--             self.layer = nil
--         end
--     }

--     items[#items+1] = button {
--         text = "New",
--         font = "normal",
--         action = function ()
--             ui.scenes:current():removeLayer()
--             self.layer = nil
--         end
--     }

--     items[#items+1] = button {
--         text = "Unwatched",
--         font = "normal",
--         action = function ()
--             ui.scenes:current():removeLayer()
--             self.layer = nil
--         end
--     }

--     items[#items+1] = button {
--         text = "Select",
--         font = "normal",
--         action = function ()
--             ui.scenes:current():removeLayer()
--             self.layer = nil
--         end
--     }

--     local inst = select.list(items, { title = "Download" })
--     self.layer = badr:root {
--         width = inst.width,
--         height = inst.height
--     }
--     self.layer = self.layer + inst
--     self.layer:focusFirstElement()
--     ui.scenes:current():insertLayer(self.layer)

--     header.reset()
--     header.append("DP", "Nav.")
--     header.append("A", "Go")
--     header.append("B", "Back")
--     header.updatePosition()
-- end

-- function card:contextMenu()
--     local items = {}

--     if self.src.Type == "Movie" or
--        self.src.Type == "Episode" or
--        self.src.Type == "Series" or
--        self.src.Type == "Season" then
--         items[#items+1] = button {
--             text = "Download",
--             font = "normal",
--             action = function ()
--                 ui.scenes:current():removeLayer()
--                 self.layer = nil

--                 if self.src.Type == "Series" or self.src.Type == "Season" then
--                     self:downloadMenu()
--                 end
--             end
--         }
--     end

--     if #items > 0 then
--         local inst = select.list(items)
--         self.layer = badr:root {
--             width = inst.width,
--             height = inst.height
--         }
--         self.layer = self.layer + inst
--         self.layer:focusFirstElement()
--         ui.scenes:current():insertLayer(self.layer)

--         header.reset()
--         header.append("A", "Go")
--         header.append("B", "Back")
--         header.updatePosition()
--     end
-- end

function card:onKeyPress(key)

    if key == "z" and self.layer then
        self.layer = nil
        return

    elseif key == "x" or key == "t" or key == "s" then

        if self.src.Type == "CollectionFolder" then
            ui.stack:push("library", { itemId = self.src.Id })

        elseif self.src.Type == "Series" then
            ui.stack:push("seasons", { seriesId = self.src.Id })

        elseif self.src.Type == "Season" then
            ui.stack:push("episodes", {
                seriesId = self.src.SeriesId,
                seasonId = self.src.Id
            })

        elseif self.src.Type == "Movie" or self.src.Type == "Episode" then
            play {
                itemId = self.src.Id,
                static = key == "s",
                transcode = key == "t"
            }
        end

    -- elseif key == "a" and self.src.Type ~= "CollectionFolder" then
    --     self:contextMenu()

    elseif key == "c" then
        ui.stack:push("info", self.src)

    elseif self.parent.onKeyPress then
        self.parent:onKeyPress(key)
    end
end

function card:onFocus()
    header.reset()

    -- if self.src.Type ~= "CollectionFolder" then
    --     header.append("Y", "Menu")
    -- end

    header.append("X", "Info")
    header.append("A", self.src.IsFolder and "Open" or "Play")
    header.append("B", (#ui.stack.active > 1) and "Back" or "Quit")
    header.updatePosition()

    for _, child in ipairs(self.children) do

        if child.onFocus then
            child:onFocus()
        end
    end
end

function card:onFocusLost()

    for _, child in ipairs(self.children) do

        if child.onFocusLost then
            child:onFocusLost()
        end
    end
end

function card:onUpdate()

    if not self.visible then

        for _, child in ipairs(self.children) do

            if child.release then
                child.release()
            end
        end
    end
end

function card:draw()

    -- if self.layer then
    --     local img = self.children[self.image]
    --     local x,y = love.graphics.transformPoint(img.x,img.y)
    --     x = x + (img.width/2) - (self.layer.width/2) - 3
    --     y = y + (img.height/2) - (self.layer.height/2) - 3

    --     if self.layer.x ~= x or self.layer.y ~= y then
    --         self.layer:setPosition(x, y)
    --     end
    -- end

    badr.draw(self)
end


---@overload fun(table):card
local export = setmetatable({}, {
    __call = function(t, ...) return card:new(...) end,
    __index = card
})

return export