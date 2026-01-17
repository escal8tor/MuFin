local badr   = require "src.ui.component.badr"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local play   = require "src.helpers.playback"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"

--#region helpers

--- Format card subtitle for Jellyfin item.
--- 
--- @param item table Jellyfin item
--- 
--- @return string subtitle for item
local function formatItemSubtitle(item)
    if item.Type == "Episode" or item.Type == "CollectionFolder" then return "" end
    local subtitle = ""

    if item.Type == "MusicAlbum" and item.AlbumArtist ~= nil then
        subtitle = item.AlbumArtist

    else
        subtitle = tostring(item.ProductionYear)

        if item.Status == "Continuing" then
            subtitle = subtitle.." - Present"

        elseif item.EndDate then
            local endYear = string.match(item.EndDate, "^(%d*)")

            if endYear and endYear ~= subtitle then
                subtitle = subtitle.." - "..endYear
            end
        end
    end

    return subtitle
end

--- Format card title for Jellyfin item.
--- 
--- @param item table Jellyfin item
--- 
--- @return string title for item
local function formatItemTitle(item)
    local title = item.Name

    if item.Type == "Episode" then
        title = string.format("S%d:E%d - %s", item.ParentIndexNumber, item.IndexNumber, item.Name)
    end

    return title
end

--- Get icon name for item.
--- 
--- @param itemType string Type property of jellyfin item.
local function getIcon(itemType)

    if itemType == "Movie" or itemType == "Episode" then
        return  "play"
    end
end

--#endregion helpers

--#region card

--- @class card : badr
--- 
--- @field seriesId string? Necessary only for season cards. 
--- @field isFolder boolean Indicates whether item can be entered.
--- @field type     string  Item type ("Movie", "Episode", etc.)
--- 
--- Main UI Component for Jellyfin items.
local card = badr {}
card.__index = card

function card:new(props)
    local proto = {
        id        = props.item.Id,
        --src       = item,
        column    = true,
        gap       = 5,
        focusable = true,
        isFolder  = props.item.IsFolder,
        type      = props.item.Type,
        seriesId  = props.seriesId
    }

    local imageProps = {
        item   = props.item,
        type   = props.imageType or "Primary",
        width  = props.width,
        height = props.height,
        icon   = getIcon(proto.type)
    }

    if props.seriesId then
        imageProps.fallback = "/data/cache/"..props.seriesId.."/primary.png"
    end

    local itemImage = image:forItem(imageProps)

    local title = text {
        id    = "title",
        text  = formatItemTitle(props.item),
        width = props.width,
        font  = "normal",
        align = "center"
    }

    local subtitle = text {
        id    = "subtitle",
        text  = formatItemSubtitle(props.item),
        width = props.width,
        font  = "small",
        color = "secondary",
        align = "center"
    }

    local object = setmetatable(badr(proto), card)

    return (
        object
        + itemImage
        + title
        + subtitle
    )
end

function card:__add(child)
    return badr.__add(self, child)
end

function card:onKeyPress(key)

    if key == "z" and self.layer then
        self.layer = nil
        return

    elseif key == "x" or key == "t" or key == "s" then

        if self.type == "CollectionFolder" then
            ui.stack:push("library", { itemId = self.id })

        elseif self.type == "Series" then
            ui.stack:push("seasons", { seriesId = self.id })

        elseif self.type == "Season" then
            ui.stack:push("episodes", {
                seriesId = self.seriesId,
                seasonId = self.id
            })

        elseif self.type == "Movie" or self.type == "Episode" then
            play {
                itemId = self.id,
                static = key == "s",
                transcode = key == "t"
            }
        end

    elseif key == "c" then
        ui.stack:push("info", { itemId = self.id })

    elseif self.parent.onKeyPress then
        self.parent:onKeyPress(key)
    end
end

function card:onFocus()
    header.reset()
    header.append("X", "Info")
    header.append("A", self.IsFolder and "Open" or "Play")
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

function card:draw()
    badr.draw(self)
end

--#endregion card

---@overload fun(table):card
local export = setmetatable({}, {
    __call = function(t, ...) return card:new(...) end,
    __index = card
})

return export