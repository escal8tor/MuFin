local badr   = require "src.ui.component.badr"
local font   = require "src.ui.component.font"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local play   = require "src.helpers.playback"
local text   = require "src.ui.component.text"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

local normal_height = font.normal:getHeight()

--- @class episode : badr
--- 
--- @field image    itemImage Episode thumbnail
--- @field title    text      Episode order and name
--- @field runtime  text      Runtime and endtime
--- @field overview text      Plot summary (if available)
--- 
--- UI component for detailed episode view.
local episode = badr {}
episode.__index = episode

function episode:new(item)
    local proto = {
        id = item.Id,
        focusable = true,
        row = true,
        gap = 15
    }

    local width, height = utils.dimensions {
        width = W_WIDTH,
        aspect = 4/3,
        scale = 2/5
    }

    proto.image = image:forItem {
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

    proto.title = text {
        id = "title",
        text = string.format("%s %s", item.IndexNumber, item.Name),
        width = W_WIDTH - width - 50,
        font = "normal",
        align = "left"
    }

    local title = badr {
        column = true,
        gap = 2
    }
    + proto.title

    if item.RunTimeTicks then
        local runtime = utils.to_minutes(item.RunTimeTicks)
        local endtime = os.date("%I:%M %p",os.time() + utils.to_seconds(item.RunTimeTicks))

        proto.runtime = text {
            id = item.Id.."_runtime",
            text = string.format("%dm Ends at %s", runtime, endtime:upper()),
            width = W_WIDTH - width - 50,
            font = "normal",
            color = "primary",
            align = "left"
        }

        title = title + proto.runtime
    else
        local err_icon = text {
            id = item.Id.."_err_icon",
            text = utf8.char(0xE001),
            font = "normal_icon",
            color = "error"
        }

        proto.runtime = text {
            id = item.Id.."_runtime_not_found",
            text = " Null runtime",
            width = W_WIDTH - width - err_icon.width - 50,
            font = "normal",
            color = "error",
            align = "left"
        }

        title = title + (
            badr {
                row = true,
                gap = 0
            }
            + err_icon
            + proto.runtime
        )
    end

    local wrap = math.floor((height - title.height - 13) / normal_height)

    proto.overview = text {
        id = item.Id.."_overview",
        text = item.Overview or "",
        width = W_WIDTH - width - 50,
        wrap = wrap, -- 6,
        font = "normal",
        color = "secondary",
        align = "left",
        scroll = "vt"
    }

    local itemText = badr {
        column = true,
        gap = 8
    }
    + title
    + proto.overview

    local object = setmetatable(badr(proto), episode)

    return object + proto.image + itemText
end


function episode:__add(child)
    return badr.__add(self, child)
end

function episode:onKeyPress(key)

    if key == "x" or key == "t" or key == "s" then
        play { itemId = self.id, static = key == "s", transcode = key == "t" }

    elseif key == "c" then
        ui.stack:push("info", { itemId = self.id } )

    elseif self.parent.onKeyPress then
        self.parent:onKeyPress(key)
    end
end

function episode:onFocus()
    header.reset()
    header.append("X", "Info")
    header.append("A", "Play")
    header.append("B", (#ui.stack.active > 1) and "Back" or "Quit")
    header.updatePosition()

    self.image:onFocus()
    self.overview:onFocus()
end

function episode:onFocusLost()
    self.image:onFocusLost()
    self.overview:onFocusLost()
end

function episode:onUpdate()

    if not self.visible then
        self.image:release()
    end
end

function episode:draw()
    badr.draw(self)
end

---@overload fun(table):episode
local export = setmetatable({}, {
    __call = function(t, ...) return episode:new(...) end,
    __index = episode
})

return export
