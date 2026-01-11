local badr   = require "src.ui.component.badr"
local button = require "src.ui.component.button"
local client = require "src.client"
local header = require "src.ui.component.header"
local scroll = require "src.ui.component.scroll"
local select = require "src.ui.component.select"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

--- Media stream selections
local selected = {
    streams = {
        Video    = nil,
        Audio    = nil,
        Subtitle = nil
    }
}

--- @class info:scene
local info = ui.scene {}
info.__index = info

function info:new()
    return setmetatable(ui:scene(), info)
end

function info:load(data)
    local itemData = utils.preq(function ()
        return client.item:getItem(
            data.itemId,
            { userId = client.session.uid }
        ):decode()
    end)

    local layer = badr:root {}
    local base = scroll {
        type = "vt",
        width = W_WIDTH - 0,
        height = W_HEIGHT - header.height - 40,
        gap = 30,
        bias = "center",
        lockFocus = true,
    }
    + text {
        id = "title",
        text = itemData.Name,
        width = W_WIDTH - 40,
        font = "large",
        align = "left"
    }

    if itemData.MediaStreams then
        local streams = {}

        for _, stream in ipairs(itemData.MediaStreams) do

            if streams[stream.Type] == nil then
                streams[stream.Type] = {}
            end

            if stream.IsDefault then
                selected.streams[stream.Type] = stream.Index
            end

            streams[stream.Type][#streams[stream.Type]+1] = button {
                stype = stream.Type,
                index = stream.Index,
                isDefault = stream.IsDefault,
                text = stream.DisplayTitle,
                align = "left",
                lmg = 10,
                rmg = 10,
                onFocus = function (s)
                    selected.streams[s.stype] = s.index
                end,
            }
        end

        for i, label in ipairs({"Video","Audio","Subtitle"}) do

            if streams[label] ~= nil then

                if i > 1 then
                    base.gap = 5
                end

                local streamSelect = select.hzScr(
                    streams[label], { width =  W_WIDTH - 140 }
                )

                base = base + (
                    badr { row = true, gap = 0 }
                    + text { text = label, width = 100 }
                    + streamSelect
                )
            end
        end

        base.gap = 30
    end

    if #itemData.Taglines > 0 then
        base = base + text {
            id = "tagline",
            text = itemData.Taglines[1],
            width = W_WIDTH - 40,
            wrap = true,
            font = "normal",
            align = "left"
        }
    end

    if itemData.Overview then
        base = base + text {
            id = "overview",
            text = itemData.Overview,
            width = W_WIDTH - 40,
            wrap = 8,
            font = "normal",
            align = "left",
            color = "primary"
        }
    end

    if #itemData.Genres > 0 then
        local label = text {
            text = "Genres",
            align = "left",
            width = 100
        }

        base = base + (
            badr {
                row = true,
                gap = 0
            }
            + label
            + text {
                text = table.concat(itemData.Genres, ", "),
                align = "left",
                color = "primary",
                width = W_WIDTH - label.width - 40,
                wrap = 2
            }
        )
    end

    if #itemData.Studios > 0 then

        if #itemData.Genres > 0 then
            base.gap = 5
        end

        local label = text {
            text = "Studios",
            align = "left",
            width = 100
        }

        local studios = {}

        for _,studio in ipairs(itemData.Studios) do
            studios[#studios+1] = studio.Name
        end

        base = base + (
            badr {
                row = true,
                gap = 0
            }
            + label
            + text {
                text = table.concat(studios, ", "),
                align = "left",
                color = "primary",
                width = W_WIDTH - label.width - 40,
                wrap = 2
            }
        )
    end

    layer = layer + base
    layer:updatePosition(20, header.height + 20)
    layer:focusFirstElement()
    self:insertLayer(layer)
end

function info:enter(data)
    header.reset()
    header.append("B", "Back")
    header.updatePosition()
end

function info:keypressed(key)
    local focus = self:focused()

    if focus and focus.onKeyPress then
        focus:onKeyPress(key)
    end

    if key == "z" then

        -- Exit layer
        if #self.layers > 1 then
            self:removeLayer()

        -- Exit scene
        elseif #ui.stack.active > 1 then
            ui.stack:pop(selected)

        -- Exit.
        else
            love.event.push("quit")
        end
    end
end

return info