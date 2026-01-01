---@diagnostic disable: param-type-mismatch
require "src.helpers.globals"

local ui, image
local log   = require "src.helpers.log"
local utils = require "src.external.utils"

-- local font = love.graphics.newFont("assets/fonts/NotoSans.ttf", 16)
-- love.graphics.setFont(font)

function love.load(args)
    log.info("### START ###")

    if #args > 0 then
        local res = args[1]

        if res then
            _G.resolution = res
            res = utils.split(res, "x")
            -- Set window resolution.
            love.window.setMode(
                tonumber(res[1]) or 640,
                tonumber(res[2]) or 480
            )
        end
    end


    W_WIDTH, W_HEIGHT = love.window.getMode()
    log.debug(string.format("resolution set to %dx%d", W_WIDTH, W_HEIGHT))

    image = require "src.ui.component.image"
    ui    = require "src.ui.scene"
    ui.stack:init("splash")
end

function love.update(dt)
    image.updateImagePaths()
    ui.stack:update(dt)
end

function love.draw()
    ui.stack:draw()
end

function love.keypressed(key)
    ui.stack:keypressed(key)
end