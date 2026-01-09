local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local grid   = require "src.ui.component.grid"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

local cardWidth

if W_WIDTH == 1280 then
    cardWidth = (W_WIDTH - 82) / 4
else
    cardWidth = (W_WIDTH - 62) / 3
end

local function libraryGrid(itemData)
    local menu = grid {
        type = "vt",
        width = W_WIDTH - 0,
        height = W_HEIGHT - header.height - 40,
        gap = 15,
        bias = "center"
    }

    for _,item in ipairs(itemData.Items) do
        -- Dimensions for item's primary image.
        local width, height = utils.dimensions {
            width = cardWidth,
            aspect = 2/3,
            -- scale = 3/5
        }

        --- create item's component
        menu = menu + (
            card {
                id = item.Id,
                src = item,
                column = true,
                gap = 3,
                focusable = true
            }
            + image:forItem {
                item = item,
                type = "Primary",
                width = width,
                height = height,
                icon = utils.getIcon(item.Type)
            }
            + text {
                id = "title",
                text = item.Name,
                width = width,
                font = "normal",
                align = "center"
            }
            + text {
                id = "subtitle",
                text = utils.formatItemSubtitle(item),
                width = width,
                font = "small",
                color = "secondary",
                align = "center"
            }
        )
    end

    return menu
end

--- @class library:scene
local library = ui.scene {}
library.__index = library

function library:new()
    --- @type library
    return setmetatable(ui:scene(), library)
end

function library:load(data)
    local items = utils.preq(function()
        return client.item:getItems({
            SortBy = "SortName",
            SortOrder = "Ascending",
            Fields = "PrimaryImageAspectRatio",
            ParentId = data.itemId
        }):decode()
    end)

    local layer = badr:root { row = true } + libraryGrid(items)
    layer:updatePosition(18, header.height + 20)
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return library