local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local scroll = require "src.ui.component.scroll"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

local function seasonScroll(item_data, seriesId)
    local menu = scroll {
        type = "hz",
        width = W_WIDTH - 40,
        gap = 15,
        bias = "center",
        lockFocus = true
    }

    for _, item in ipairs(item_data.Items) do
        local width, height = utils.dimensions {
            height = (W_HEIGHT - header.height - 65),
            aspect = 2/3
        }

        item.seriesId = seriesId

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
                fallback = "/data/cache/"..seriesId.."/primary.png"
            }
            + text {
                id = "title",
                text = item.Name,
                width = width,
                font = "normal",
                align = "center"
            }
        )
    end

    return menu
end

--- @class seasons:scene
local seasons = ui.scene {}
seasons.__index = seasons

function seasons:new()
    --- @type seasons
    return setmetatable(ui:scene(), seasons)
end

function seasons:load(data)
    local response = client.show:getSeasons(
        data.seriesId, {
            Fields = "PrimaryImageAspectRatio",
            enableImages = "true"
        }
    )

    if response.ok then
        local itemData = response:decode()

        if #itemData.Items > 1 then
            local layer = badr:root { row = true }
            layer = layer + seasonScroll(itemData, data.seriesId)
            layer:updatePosition(20, header.height + 20)
            layer:focusFirstElement()
            self:insertLayer(layer)

        else
            ui.stack:push( "episodes", {
                seasonId = itemData.Items[1].Id,
                seriesId = data.seriesId
            })
        end
    end
end

function seasons:enter(data)

    if not self:focused() then
        ui.stack:pop()

    else
        ui.scene.enter(self, data)
    end
end

return seasons