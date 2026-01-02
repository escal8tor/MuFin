local badr   = require "src.ui.component.badr"
local header = require "src.ui.component.header"
local play   = require "src.helpers.playback"
local ui     = require "src.ui.scene"

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

    elseif key == "c" then
        ui.stack:push("info", self.src)

    elseif self.parent.onKeyPress then
        self.parent:onKeyPress(key)
    end
end

function card:onFocus()
    header.reset()
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
    badr.draw(self)
end


---@overload fun(table):card
local export = setmetatable({}, {
    __call = function(t, ...) return card:new(...) end,
    __index = card
})

return export