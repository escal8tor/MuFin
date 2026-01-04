---@diagnostic disable: param-type-mismatch
local badr    = require "src.ui.component.badr"
local client  = require "src.client"
local episode = require "src.ui.component.episode"
local header  = require "src.ui.component.header"
local scroll  = require "src.ui.component.scroll"
local ui      = require "src.ui.scene"

--- @class episodes:scene
local episodes = ui.scene {}
episodes.__index = episodes

function episodes:new()
    --- @type episodes
    return setmetatable(ui:scene(), episodes)
end

function episodes:load(data)
    local response = client.show:getEpisodes(
        data.seriesId, {
            Fields = "PrimaryImageAspectRatio,Overview",
            seasonId = data.seasonId
        }
    )

    if response.ok then
        response = response:decode()

        local list = scroll {
            type = "vt",
            width = W_WIDTH - 0,
            height = W_HEIGHT - header.height - 40,
            gap = 15,
            bias = "center",
            lockFocus = true,
        }

        for _, item in ipairs(response.Items) do
            list = list + episode(item)
        end

        local layer = badr:root { row = true } + list
        layer:updatePosition(18, header.height + 20)
        layer:focusFirstElement()
        self:insertLayer(layer)
    end
end

return episodes