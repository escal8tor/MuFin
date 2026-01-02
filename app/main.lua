---@diagnostic disable: param-type-mismatch
require "src.helpers.globals"

local image = require "src.ui.component.image"
local log   = require "src.helpers.log"
local ui    = require "src.ui.scene"

function love.load(args)
    log.info("### START ###")
    love.window.setMode(W_WIDTH, W_HEIGHT)
    log.debug("resolution set to %dx%d", W_WIDTH, W_HEIGHT)
    log.debug("Device name: %s", DEVICE_NAME)
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