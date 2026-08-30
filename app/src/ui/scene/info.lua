local accordion = require "src.ui.component.accordion"
local badr      = require "src.ui.component.badr"
local button    = require "src.ui.component.button"
local client    = require "src.client"
local header    = require "src.ui.component.header"
local image     = require "src.ui.component.image"
local picker    = require "src.ui.component.picker"
local scroll    = require "src.ui.component.scroll"
local select    = require "src.ui.component.select"
local text      = require "src.ui.component.text"
local ui        = require "src.ui.scene"
local utils     = require "src.external.utils"

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

    local isWideAspect = (W_WIDTH/W_HEIGHT) > (4/3)
    local outerMargin = W_HEIGHT / 22
    local baseWidth = W_WIDTH - outerMargin
    local imgWidth, imgHeight

    if isWideAspect then
        -- baseWidth = W_WIDTH * 3/5

        if ( itemData.Type == "Movie" or
             itemData.Type == "Series" or
             itemData.Type == "Season" ) then

            imgWidth, imgHeight = utils.dimensions {
                height = W_HEIGHT - header.height - outerMargin,
                aspect = 2/3
            }

            baseWidth = W_WIDTH - imgWidth - (outerMargin * 3/2)

        elseif itemData.Type == "Episode" then
            imgWidth, imgHeight = utils.dimensions {
                width  = baseWidth * 0.45,
                aspect = 4/3
            }

            baseWidth = W_WIDTH - imgWidth - (outerMargin * 3/2)
        end
    end

    local base = scroll {
        id     = "info",
        type   = "vt",
        width  = baseWidth,
        height = W_HEIGHT - header.height - outerMargin,
        gap    = outerMargin * 2/3,
        bias   = "center"
    }

    local title =  text {
        id    = "title",
        text  = itemData.Name,
        width = base.width,
        font  = "large",
        align = "left"
    }

    base = base + title

    -- Add episode-specific information for episodes
    if itemData.Type == "Episode" then
        local episodeInfo = badr {
            id = "episode_info",
            column = true,
            gap = 5
        }

        -- Season and Episode numbers
        if itemData.ParentIndexNumber and itemData.IndexNumber then
            local seasonEpText = text {
                text = string.format("Season %d, Episode %d", itemData.ParentIndexNumber, itemData.IndexNumber),
                width = base.width,
                font = "normal",
                align = "left"
            }
            episodeInfo = episodeInfo + seasonEpText
        end

        -- Air date
        if itemData.PremiereDate then
            local airDateText = text {
                text = "Air Date: " .. os.date("%Y-%m-%d", os.time(utils.parseISODate(itemData.PremiereDate))),
                width = base.width,
                font = "normal",
                align = "left"
            }
            episodeInfo = episodeInfo + airDateText
        end

        -- Production year
        if itemData.ProductionYear then
            local yearText = text {
                text = "Production Year: " .. tostring(itemData.ProductionYear),
                width = base.width,
                font = "normal",
                align = "left"
            }
            episodeInfo = episodeInfo + yearText
        end

        -- Director (if available)
        if itemData.Directors and #itemData.Directors > 0 then
            local directorText = text {
                text = "Director: " .. table.concat(itemData.Directors, ", "),
                width = base.width,
                font = "normal",
                align = "left"
            }
            episodeInfo = episodeInfo + directorText
        end

        -- Writers (if available)
        if itemData.Writers and #itemData.Writers > 0 then
            local writersText = text {
                text = "Writers: " .. table.concat(itemData.Writers, ", "),
                width = base.width,
                font = "normal",
                align = "left"
            }
            episodeInfo = episodeInfo + writersText
        end

        -- Cast (actors) - if available
        if itemData.People and #itemData.People > 0 then
            local castItems = {}
            for _, person in ipairs(itemData.People) do
                if person.Type == "Actor" or person.Type == "GuestStar" then
                    table.insert(castItems, person.Name)
                end
            end

            if #castItems > 0 then
                local castText = text {
                    text = "Cast: " .. table.concat(castItems, ", "),
                    width = base.width,
                    font = "normal",
                    align = "left"
                }
                episodeInfo = episodeInfo + castText
            end
        end

        -- Guest stars (if available)
        if itemData.People and #itemData.People > 0 then
            local guestStars = {}
            for _, person in ipairs(itemData.People) do
                if person.Type == "GuestStar" then
                    table.insert(guestStars, person.Name)
                end
            end

            if #guestStars > 0 then
                local guestText = text {
                    text = "Guest Stars: " .. table.concat(guestStars, ", "),
                    width = base.width,
                    font = "normal",
                    align = "left"
                }
                episodeInfo = episodeInfo + guestText
            end
        end

        -- Add the episode info section to the main content
        if #episodeInfo.children > 0 then
            base = base + episodeInfo
        end
    end

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
                id        = stream.Type:lower().."_"..tostring(stream.Index),
                stype     = stream.Type,
                index     = stream.Index,
                isDefault = stream.IsDefault,
                text      = stream.DisplayTitle,
                align     = "left",
                lmg       = 10,
                rmg       = 10,

                onFocus = function (s)
                    selected.streams[s.stype] = s.index
                    header.reset()
                    header.append("DP", "Select")
                    header.append("B", (#ui.stack.active > 1) and "Back" or "Quit")
                    header.updatePosition()
                end,
            }
        end

        if streams then
            local streamsList = badr {
                id     = "streams",
                column = true,
                gap    = (W_HEIGHT - header.height) / 96,
            }

            for _, streamType in ipairs({"Video","Audio","Subtitle"}) do

                if streams[streamType] ~= nil then
                    local label = streamType:lower()
                    -- Replace select.hzScr with picker
                    local streamPicker = picker.streamPicker(
                        streams[streamType],
                        { id = label.."_streams", width = base.width * 0.85 }
                    )

                    -- Add onSelect handler to update selected stream
                    streamPicker.onSelect = function(value)
                        selected.streams[streamType] = value
                    end

                    streamsList = streamsList + (
                        badr { id = label.."_container", row = true, gap = 0 }
                        + text { id = label.."_label", text = streamType, width = base.width * 0.15 }
                        + streamPicker
                    )
                end
            end

            base = base + streamsList
        end
    end

    if #itemData.Taglines > 0 then
        base = base + text {
            id    = "tagline",
            text  = itemData.Taglines[1],
            width = base.width,
            wrap  = true,
            font  = "normal",
            align = "left"
        }
    end

    if itemData.Overview then
        local overview = accordion {
            id    = "overview",
            text  = itemData.Overview,
            width = base.width,
            wrap  = 8,
            align = "left"
        }

        overview:setContainerScroll(base)

        base = base + overview
    end

    if (#itemData.Genres > 0) or (#itemData.Studios > 0) then
        local miscInfo = badr {
            id = "misc_info",
            column = true,
            gap = 5
        }


        if #itemData.Genres > 0 then
            local label = text {
                text  = "Genres",
                align = "left",
                width = base.width * 0.15
            }

            miscInfo = miscInfo + (
                badr {
                    row = true,
                    gap = 0
                }
                + label
                + text {
                    text  = table.concat(itemData.Genres, ", "),
                    align = "left",
                    color = "primary",
                    width = base.width - label.width,
                    wrap  = 2
                }
            )
        end

        if #itemData.Studios > 0 then
            local label = text {
                text  = "Studios",
                align = "left",
                width = base.width * 0.15
            }

            local studios = {}

            for _,studio in ipairs(itemData.Studios) do
                studios[#studios+1] = studio.Name
            end

            miscInfo = miscInfo + (
                badr {
                    row = true,
                    gap = 0
                }
                + label
                + text {
                    text  = table.concat(studios, ", "),
                    align = "left",
                    color = "primary",
                    width = base.width - label.width,
                    wrap  = 2
                }
            )
        end

        base = base + miscInfo
    end

    local layer = badr:root {}

    if isWideAspect then

        local imageProps = {
            item   = itemData,
            type   = "Primary",
            width  = imgWidth,
            height = imgHeight,
            icon   = false,
            fit    = "fitHeight"
        }

        if itemData.seriesId then
            imageProps.fallback = "/data/cache/"..itemData.seriesId.."/primary.png"
        end

        layer = layer + (
            badr {
                width = W_WIDTH - outerMargin,
                row = true,
                gap = outerMargin / 2
            }
            + image:forItem(imageProps)
            + base
        )
    else
        layer = layer + base
    end

    layer:updatePosition(outerMargin / 2, header.height + (outerMargin / 2))
    layer:focusFirstElement()
    self:insertLayer(layer)
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