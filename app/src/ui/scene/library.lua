local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local grid   = require "src.ui.component.grid"
local header = require "src.ui.component.header"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

--- @class library:scene
local library = ui.scene {}
library.__index = library

function library:new()
    --- @type library
    return setmetatable(ui:scene(), library)
end

function library:load(data)
    local itemData = utils.preq(function()
        return client.item:getItems({
            SortBy = "SortName",
            SortOrder = "Ascending",
            Fields = "PrimaryImageAspectRatio",
            ParentId = data.itemId
        }):decode()
    end)

    local isWideAspect = (W_WIDTH / W_HEIGHT) > (4/3)
    local gridWidth = isWideAspect and 4 or 3
    local outerMargin = W_HEIGHT / 22
    local innerMargin = outerMargin * 0.38
    local cardWidth = (W_WIDTH - outerMargin - (innerMargin * (gridWidth - 1))) / gridWidth
    local textOffset = innerMargin / 5

    local itemCards = grid {
        id = "library_grid",
        type = "vt",
        width = W_WIDTH,
        height = W_HEIGHT - header.height - outerMargin,
        gap = innerMargin,
        bias = "center"
    }

    for _,item in ipairs(itemData.Items) do
        local width, height = utils.dimensions {
            width = cardWidth,
            aspect = 2/3,
            -- scale = 3/5
        }

        itemCards = itemCards + card {
            item = item,
            width = width,
            height = height,
            gap = textOffset
        }
    end

    local layer = badr:root { row = true } + itemCards
    layer:updatePosition((outerMargin / 2), header.height + (outerMargin / 2))
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return library
