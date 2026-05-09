---@diagnostic disable: param-type-mismatch
local image, log, ui

function love.load(args)

    require "src.helpers.globals"

    if #args > 0 then
        local res = args[1]

        if res then
            _G.resolution = res
            res = utils.split(res, "x")
            love.window.setMode(tonumber(res[1]) or 640, tonumber(res[2]) or 480)
            W_WIDTH, W_HEIGHT = love.window.getMode()
        end

        _G.OS_NAME = args[2]
    end

    image = require "src.ui.component.image"
    log   = require "src.helpers.log"
    ui    = require "src.ui.scene"

    log.info("### START ###")
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
