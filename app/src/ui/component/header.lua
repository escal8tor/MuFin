---@diagnostic disable: missing-return
local badr    = require "src.ui.component.badr"
local configs = require "src.external.config"
local text    = require "src.ui.component.text"
local utf8    = require 'utf8'

--- @class btnIcon
--- 
--- @field id string  Digraph identifier
--- @field btn string full name for button
--- @field sym string unicode character for prompt
--- @field map table  state/mapping table
--- 
--- Visual element for help segment
local btnIcon = {}
btnIcon.__index = btnIcon

function btnIcon.new(props)
    props["map"] = { controls = nil }

    return setmetatable(props, btnIcon)
end

--- (Re)assign mapping for state.
--- @param key string input to map
--- @param state string state to map
--- @param mod table modifiers 
function btnIcon:set(key, state, mod)

    if not self.map[state] then
        self.map[state] = {}
    end

    self.map[state][key] = mod
end

--- Un-assign mapping for `state`
--- @param state string state to remove
function btnIcon:unset(state)

    for mapped,_ in pairs(self.map) do

        if mapped == state then
            self.map[mapped] = nil
            break
        end
    end
end

function btnIcon:get(state)
    state = state or "controls"
    return self.map[state]
end

local input = {
    --- @type btnIcon[] button specification
    _spec = {
        btnIcon.new { id = "Y",  btn = "Y",                  sym = utf8.char(0x21D1) },
        btnIcon.new { id = "X",  btn = "X",                  sym = utf8.char(0x21D0) },
        btnIcon.new { id = "B",  btn = "B",                  sym = utf8.char(0x21D2) },
        btnIcon.new { id = "A",  btn = "A",                  sym = utf8.char(0x21D3) },
        btnIcon.new { id = "FL", btn = "Y",                  sym = utf8.char(0x21A4) },
        btnIcon.new { id = "FU", btn = "X",                  sym = utf8.char(0x21A5) },
        btnIcon.new { id = "FR", btn = "A",                  sym = utf8.char(0x21A6) },
        btnIcon.new { id = "FD", btn = "B",                  sym = utf8.char(0x21A7) },
        btnIcon.new { id = "ST", btn = "START",              sym = utf8.char(0x21F8) },
        btnIcon.new { id = "SL", btn = "SELECT",             sym = utf8.char(0x21F7) },
        btnIcon.new { id = "FN", btn = "GUIDE",              sym = utf8.char(0x21FB) },
        btnIcon.new { id = "DP", btn = "DPAD",               sym = utf8.char(0x21CE) },
        btnIcon.new { id = "DL", btn = "LEFT",               sym = utf8.char(0x219E) },
        btnIcon.new { id = "DU", btn = "UP",                 sym = utf8.char(0x219F) },
        btnIcon.new { id = "DR", btn = "RIGHT",              sym = utf8.char(0x21A0) },
        btnIcon.new { id = "DD", btn = "DOWN",               sym = utf8.char(0x21A1) },
        btnIcon.new { id = "LA", btn = "LEFT_ANALOG",        sym = utf8.char(0x21CB) },
        btnIcon.new { id = "LL", btn = "LEFT_ANALOG_LEFT",   sym = utf8.char(0x21BC) },
        btnIcon.new { id = "LU", btn = "LEFT_ANALOG_UP",     sym = utf8.char(0x21BE) },
        btnIcon.new { id = "LR", btn = "LEFT_ANALOG_RIGHT",  sym = utf8.char(0x21C0) },
        btnIcon.new { id = "LD", btn = "LEFT_ANALOG_DOWN",   sym = utf8.char(0x21C2) },
        btnIcon.new { id = "L3", btn = "L3",                 sym = utf8.char(0x21BA) },
        btnIcon.new { id = "RA", btn = "RIGHT_ANALOG",       sym = utf8.char(0x21CC) },
        btnIcon.new { id = "RL", btn = "RIGHT_ANALOG_LEFT",  sym = utf8.char(0x21BD) },
        btnIcon.new { id = "RU", btn = "RIGHT_ANALOG_UP",    sym = utf8.char(0x21BF) },
        btnIcon.new { id = "RR", btn = "RIGHT_ANALOG_RIGHT", sym = utf8.char(0x21C1) },
        btnIcon.new { id = "RD", btn = "RIGHT_ANALOG_DOWN",  sym = utf8.char(0x21C3) },
        btnIcon.new { id = "R3", btn = "R3",                 sym = utf8.char(0x21BB) }
    },
}

--- Retrieve default button specification by property.
--- @param value string property value to match
--- @return btnIcon
function input.getBtnIcon(value)
    value = value:upper()

    for _,btn in ipairs(input._spec) do

        if btn["id"] == value or btn["btn"] == value then
            return btn
        end
    end
end

local header = {
    layout_left = badr:root { row = true, gap = 10 },
    layout_right = badr:root { row = true, gap = 10 },
    width = 0,
    height = 0
}

local logo, logo_scale

function header.load()
    logo = love.graphics.newImage("res/image/jellyfin_icon.png")
    header.width = W_WIDTH
    header.height = W_HEIGHT / 12
    local alt = 24

    if W_HEIGHT == 480 then
        alt = 16
    end

    logo_scale = (header.height - alt) / logo:getHeight()
end

function header.reset()
    header.layout_left = badr:root { row = true, gap = 15 }
end

--- Add help text for a button.
--- @param btn string button name
--- @param txt string text to display
function header.append(btn, txt)
    local id = btn:lower()
    local off1, off2

    if W_HEIGHT == 480 then
        off1, off2 = 0, 0
    else
        off1, off2 = 2, -4
    end

    header.layout_left = header.layout_left + (
        badr {
            y = header.layout_left.y + off1,
            id = id.."_hint",
            row = true,
            gap = 5
        }
        + text {
            y = header.layout_left.y + off2,
            id = id.."_sym",
            text = input.getBtnIcon(btn).sym,
            font = "prompt",
            color = "HEADER:HINT_ICON"
        }
        + text {
            id = id.."_txt",
            text = txt,
            font = "normal",
            color = "HEADER:HINT_TEXT",
        }
    )
end

function header.extend(map)
    local btns = {}

    for btn,_ in pairs(map) do
        table.insert(btns, btn)
    end
    -- table.sort(btns)

    for i=1, #btns do
        header.append(btns[i], map[btns[i]])
    end
end

function header.updatePosition(xPos, yPos)
    xPos = xPos or W_WIDTH - header.layout_left.width - 20
    yPos = (header.height - header.layout_left.height) / 2
    header.layout_left:updatePosition(xPos, yPos)
end

local y = 12

if W_HEIGHT == 480 then
    y = 8
end

function header:draw()
    love.graphics.setColor(configs.theme:color("HEADER","BACKGROUND"))
    love.graphics.rectangle("fill", 0, 0, header.width, header.height)
    header.layout_left:draw()
    love.graphics.setColor(configs.theme:color("HEADER","LOGO"))
    love.graphics.draw(logo, 20, y, 0, logo_scale, logo_scale)
end

return header