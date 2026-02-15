local badr   = require "src.ui.component.badr"
local card   = require "src.ui.component.card"
local client = require "src.client"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local log    = require "src.helpers.log"
local scroll = require "src.ui.component.scroll"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

--#region helpers

--- Create component tree for user views.
---
--- @return badr userViews Jellyfin view data
local function getUserViews(viewData)
    local viewCards = scroll {
        type = "hz",
        id = "view_cards",
        gap = 15,
        width = W_WIDTH - 40,
        bias = "center"
    }

    for _,item in ipairs(viewData.Items) do
        local width, height = utils.dimensions {
            aspect = item.PrimaryImageAspectRatio,
            scale = 3/5
        }

        viewCards = viewCards + card {
            item = item,
            width = width,
            height = height
        }
    end

    return (
        badr {
            column = true,
            gap = 15
        }
        + text {
            text = "My Media",
            font = "large"
        }
        + viewCards
    )
end

--- Create component tree(s) for recently added media.
---
--- @param name string Source view title
--- @param id   string Source view id
--- @param data table  Jellyfin results for latest query
---
--- @return badr tree Component tree
local function getRecentlyAdded(name, id, data)
    local recentCards = scroll {
        type = "hz",
        id = "recently_added_"..id,
        gap = 15,
        width = W_WIDTH - 40,
        bias = "center"
    }

    for _, item in ipairs(data) do
        local aspect

        if item.Type == "Episode" then
            aspect = 4/3
        else
            aspect = 2/3
        end

        local width, height = utils.dimensions {
            aspect = aspect,
            scale = 3/5
        }

        recentCards = recentCards + card {
            item = item,
            width = width,
            height = height
        }
    end

    return (
        badr {
            column = true,
            gap = 15
        }
        + text {
            text = "Recently added in "..name,
            font = "large",
            color = "bright"
        }
        + recentCards
    )
end

--#endregion helpers

--- @class home : scene
local home = ui.scene {}
home.__index = home

function home:new()
    --- @type home
    return setmetatable(ui:scene(), home)
end

function home:load(data)
    -- client authentication is complete by this point
    image.startThread()

    local viewData = utils.preq(function ()
        return client.user:getUserViews():decode()
    end)

    local menu = scroll:multi {
        id = "home_menu",
        type = "vt",
        gap = 20,
        height = W_HEIGHT - header.height - 40,
        bias = "center",
    }

    menu = menu + getUserViews(viewData)

    for _,item in ipairs(viewData.Items) do
        local latestData = utils.preq(function ()
            return client.item:getLatestMedia({
                parentId = item.Id,
                limit = 24,
                fields = "PrimaryImageAspectRatio"
            }):decode()
        end)

        local latestArea = getRecentlyAdded(item.Name, item.Id, latestData)
        menu = menu + latestArea
        latestArea:updatePosition(0,0)
    end

    local layer = badr:root { row = true } + menu
    layer:updatePosition(20, header.height + 20)
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return home