---@diagnostic disable: param-type-mismatch
local badr    = require "src.ui.component.badr"
local client  = require "src.client"
local episode = require "src.ui.component.episode"
local header  = require "src.ui.component.header"
local scroll  = require "src.ui.component.scroll"
local ui      = require "src.ui.scene"
local utils   = require "src.external.utils"

--- @class episodes:scene
local episodes = ui.scene {}
episodes.__index = episodes

function episodes:new()
    --- @type episodes
    return setmetatable(ui:scene(), episodes)
end

function episodes:load(data)
    local response = utils.preq(function ()
        return client.show:getEpisodes(
            data.seriesId, {
                Fields   = "PrimaryImageAspectRatio,Overview",
                seasonId = data.seasonId
            }
        ):decode()
    end)

    local outerMargin = W_HEIGHT / 22
    local innerMargin = outerMargin * 0.38

    local list = scroll {
        id = "episodes",
        type  = "vt",
        width = W_WIDTH - outerMargin,
        height = W_HEIGHT - header.height - outerMargin,
        gap = innerMargin,
        bias = "center",
        lockFocus = true,
    }

    for _, item in ipairs(response.Items) do
        list = list + episode(item, { gap = innerMargin })
    end

    local layer = badr:root { row = true } + list
    layer:updatePosition((outerMargin / 2), header.height + (outerMargin / 2))
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return episodes
