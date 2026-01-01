---@diagnostic disable: param-type-mismatch
local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local scroll = require "src.ui.component.scroll"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utf8   = require "utf8"
local utils  = require "src.external.utils"


--- Create episode scroll component tree.
--- 
--- @param itemData table Jellyfin results for episode query
--- 
--- @return badr tree Component tree
local function episodeScroll(itemData)
    local menu = scroll {
        type = "vt",
        width = W_WIDTH - 0,
        height = W_HEIGHT - header.height - 40,
        gap = 15,
        bias = "center",
        lockFocus = true,
    }

    for _, item in ipairs(itemData.Items) do
        local width, height = utils.dimensions {
            width = W_WIDTH,
            aspect = 4/3, -- item.PrimaryImageAspectRatio,
            scale = 2/5
        }

        local itemImage = image:forItem {
            item = item,
            type = "Primary",
            width = width,
            height = height,
            fit = "fillHeight"
        }

        if item.ParentIndexNumber > 0 then
            item.IndexNumber = tostring(item.IndexNumber).."."
        else
            item.IndexNumber = "Special -"
        end

        local title = badr {
            column = true,
            gap = 2
        }
        + text {
            id = "title",
            text = string.format("%s %s", item.IndexNumber, item.Name),
            width = W_WIDTH - width - 50,
            font = "normal",
            align = "left"
        }

        if item.RunTimeTicks then
            local runtime = utils.to_minutes(item.RunTimeTicks)
            local endtime = os.date("%I:%M %p",os.time() + utils.to_seconds(item.RunTimeTicks))

            title = title + text {
                id = item.Id.."_runtime",
                text = string.format("%dm Ends at %s", runtime, endtime:upper()),
                width = W_WIDTH - width - 50,
                font = "normal",
                color = "primary",
                align = "left"
            }
        else
            local err_icon = text {
                id = item.Id.."_err_icon",
                text = utf8.char(0xE001),
                font = "normal_icon",
                color = "error"
            }

            title = title + (
                badr {
                    row = true,
                    gap = 0
                }
                + err_icon
                + text {
                    id = item.Id.."_runtime_not_found",
                    text = " Null runtime",
                    width = W_WIDTH - width - err_icon.width - 50,
                    font = "normal",
                    color = "error",
                    align = "left"
                }
            )
        end

        local overview = text {
            id = item.Id.."_overview",
            text = item.Overview or "",
            width = W_WIDTH - width - 50,
            wrap = 6,
            font = "normal",
            color = "secondary",
            align = "left",
            scroll = "vt"
        }

        local itemText = badr {
            column = true,
            gap = 8,
            onFocus = function (...)
                overview:onFocus()
            end,
            onFocusLost = function (...)
                overview:onFocusLost()
            end
        }
        + title
        + overview

        menu = menu + (
            card {
                id = item.Id,
                src = item,
                row = true,
                gap = 15,
                focusable = true,
            }
            + itemImage
            + itemText
        )
    end

    return menu
end

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
        local layer = badr:root { row = true } + episodeScroll(response)
        layer:updatePosition(18, header.height + 20)
        layer:focusFirstElement()
        self:insertLayer(layer)
    end
end

return episodes