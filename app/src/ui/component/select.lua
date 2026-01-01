local badr   = require "src.ui.component.badr"
local config = require "src.external.config"
local text   = require "src.ui.component.text"
local scroll = require "src.ui.component.scroll"
local utils  = require "src.external.utils"
local button = require "src.ui.component.button"

--- @class select
local select = {}
select.__index = select

function select.list(items, props)
    local width  = 0 --- @type number Max. width of content
    local height = 0 --- @type number Height of content.
    local title

    props = props or {}
    props.gap = props.gap or 3
    props.border = props.border or props.gap

    for i, item in pairs(items) do
        width = math.max(item.width + 40, width)
        height = height + item.height

        if i > 1 and props.gap then
            height = height + props.gap
        end

        if item.action then
            item.nfill = "SELECT_LIST:NORMAL_FILL"
            item.ffill = "SELECT_LIST:FOCUSED_FILL"
            item.ntext = "SELECT_LIST:NORMAL_TEXT"
            item.ftext = "SELECT_LIST:FOCUSED_TEXT"
        end
    end

    local component = scroll {
        type = "vt",
        gap = props.gap,
        bias = "lazy",
        width = width + (props.border*2),
        height = height + (props.border*2),
        lockFocus = true,
        color = props.color or "UI:BACKGROUND",
        tmg = props.border,
        rmg = props.border,
        bmg = props.border,
        lmg = props.border,
        draw = function(s)
            love.graphics.push()
            love.graphics.stencil(
                function()
                    love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
                end,
                "replace",
                1
            )
            love.graphics.setStencilTest("greater", 0)
            love.graphics.setColor(config.theme:color(s.color))
            love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
            love.graphics.setColor(1,1,1,1)
            love.graphics.translate(-s.vx, -s.vy)

            for _, child in ipairs(s.children) do

                if child.visible then
                    child:draw()
                end
            end

            love.graphics.pop()
        end
    }

    for _, item in pairs(items) do
        item.width = width
        component = component + item
    end

    return component
end

function select.hzScr(items, props)
    local width  = 0 --- @type number Max. width of content
    local height = 0 --- @type number Height of content.
    props = props or {}

    for i, item in pairs(items) do
        width = math.max(item.width + 40, width)
        height = math.max(height, item.height)
        item.nfill = "SELECT_HZSCR:NORMAL_FILL"
        item.ffill = "SELECT_HZSCR:FOCUSED_FILL"
        item.ntext = "SELECT_HZSCR:NORMAL_TEXT"
        item.ftext = "SELECT_HZSCR:FOCUSED_TEXT"
    end

    width = props.width or width

    local component = scroll {
        type = "hz",
        bias = "lazy",
        width = width,
        height = height,
        color = props.color or "UI:BACKGROUND",
        duration = 0,
        draw = function(s)
            love.graphics.push()
            love.graphics.stencil(
                function()
                    love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
                end,
                "replace",
                1
            )
            love.graphics.setStencilTest("greater", 0)
            love.graphics.translate(-s.vx, -s.vy)
            love.graphics.setColor(config.theme:color(s.color))
            love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
            love.graphics.setColor(1,1,1,1)

            for _, child in ipairs(s.children) do

                if child.visible then
                    child:draw()
                end
            end

            love.graphics.setStencilTest()
            love.graphics.pop()
        end,
        __add = function(self, other)
            local updated = scroll.__add(self, other)
            updated.width = width

            return updated
        end
    }

    for _, item in pairs(items) do
        item:setWidth(width)
        component = component + item
    end

    return component
end

return select
