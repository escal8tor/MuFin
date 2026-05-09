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

--#region variables

local config = require("src.external.config").client

local outerMargin = W_HEIGHT / 22
local innerMargin = outerMargin * 0.38
local textOffset = innerMargin / 5

--#endregion variables

--#region helpers

--- Create component tree for user views.
---
--- @return badr userViews Jellyfin view data
local function getUserViews(viewData)
    local viewCards = scroll {
        type = "hz",
        id = "view_cards",
        gap = innerMargin,
        width = W_WIDTH - outerMargin,
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
            height = height,
            gap = textOffset
        }
    end

    return (
        badr {
            column = true,
            gap = innerMargin
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
        gap = innerMargin,
        width = W_WIDTH - outerMargin,
        bias = "center"
    }

    for _, item in ipairs(data) do
        local aspect = 2/3

        if item.Type == "Episode" then
            local pref = config:read("Recents","allowItems")
            local ok

            if pref == "yes" then
                aspect = 4/3

            elseif pref == "parent" then
                ok, item = pcall(function()
                    return client.item:getItem(item.SeriesId):decode()
                end)

                if not ok then
                    goto continue
                end

            elseif pref == "shortcut" then
                goto continue
            else
                goto continue
            end
        end

        local width, height = utils.dimensions {
            aspect = aspect,
            scale = 3/5
        }

        recentCards = recentCards + card {
            item = item,
            width = width,
            height = height,
            gap = textOffset
        }

        ::continue::
    end

    return (
        badr {
            column = true,
            gap = innerMargin
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

    local menu = scroll {
        id = "home_menu",
        type = "vt",
        gap = outerMargin / 2,
        height = W_HEIGHT - header.height - outerMargin,
        bias = "center",
        lockFocus = true
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
    layer:updatePosition((outerMargin / 2), header.height + (outerMargin / 2))
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return home
