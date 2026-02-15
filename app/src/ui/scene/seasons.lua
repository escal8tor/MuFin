local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local header = require "src.ui.component.header"
local scroll = require "src.ui.component.scroll"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"


--- @class seasons:scene
local seasons = ui.scene {}
seasons.__index = seasons

function seasons:new()
    --- @type seasons
    return setmetatable(ui:scene(), seasons)
end

function seasons:load(data)
    local itemData = utils.preq(function ()
        return client.show:getSeasons(
            data.seriesId, {
                Fields = "PrimaryImageAspectRatio",
                enableImages = "true"
            }
        ):decode()
    end)

    if #itemData.Items > 1 then
        local seasonCards = scroll {
            id        = "seasons",
            type      = "hz",
            width     = W_WIDTH - 40,
            gap       = 15,
            bias      = "center",
            lockFocus = true
        }

        for _, item in ipairs(itemData.Items) do
            local width, height = utils.dimensions {
                height = (W_HEIGHT - header.height - 65),
                aspect = 2/3
            }

            seasonCards = seasonCards + card {
                item = item,
                width = width,
                height = height,
                seriesId = data.seriesId
            }
        end

        local layer = badr:root { row = true } + seasonCards
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

function seasons:enter(data)

    if not self:focused() then
        ui.stack:pop()

    else
        ui.scene.enter(self, data)
    end
end

return seasons