local badr   = require "src.ui.component.badr"
local config = require "src.external.config"
local header = require "src.ui.component.header"
local image  = require "src.ui.component.image"
local text   = require "src.ui.component.text"
local scroll = require "src.ui.component.scroll"
local ui     = require "src.ui.scene"
local utils  = require "src.external.utils"

--- @class settings:scene
local settings = ui.scene {}
settings.__index = settings

function settings:new()
    --- @type settings
    return setmetatable(ui:scene(), settings)
end

function settings:load(data)
    local layer = badr:root { column = true, gap = 15 }

    layer = layer + text {
        text = "Settings",
        font = "large",
        color = "normal"
    }

    layer:updatePosition(20, header.height + 20)
    layer:focusFirstElement()
    self:insertLayer(layer)
end

return settings