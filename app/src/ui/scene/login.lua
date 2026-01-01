local client = require "src.client"
local config = require "src.external.config"
local log    = require "src.helpers.log"
local ui     = require "src.ui.scene"

local font1 = love.graphics.newFont("res/font/Quicksand.ttf", 96)
local font2 = love.graphics.newFont("res/font/Quicksand.ttf", 32)

--- @type love.Text, number, number, number, number
local code, code_x, code_y, code_ox, code_oy
local inst_x, inst_y, inst_w
local elapsed = 0

local instructions = "On a separate device, go to settings > quick connect and enter this code."

--- @class login : scene
--- 
--- Initial authentication / connection.
local login = ui.scene {}
login.__index = login

function login.new()
    return setmetatable(ui:scene(), login)
end

function login:load(data)
    client:connect()

    if not client.connected then

        if  config.client:read("Authentication", "method") == "Basic" then
            -- Authenticate with username and password.
            client:basicAuth()

            if not client.connected then
                log.fatal("Authentication failed (method: Basic).")
                love.event.push("quit")
            end

        else
            client:initQuickConnect()

            if not client.connected then
                log.debug("Initiated QuickConnect to %s.", client.session.host)
                code = love.graphics.newText(font1, client.qcData.code)
                local w, h = code:getDimensions()
                code_ox, code_oy = w/2, h/2
                code_x, code_y = W_WIDTH/2, W_HEIGHT/2
                inst_x = W_WIDTH/6
                inst_y = code_y + h + 10
                inst_w = W_WIDTH*2/3
            end
        end
    end

    if client.connected then
        log.info("Connected to %s.", client.session.host)
        ui.stack:reset("home")
    end
end

function login:update(dt)
    elapsed = elapsed + dt

    if elapsed >= 3.0 then
        log.debug("Checking QuickConnect state.")

        if client:getQuickConnectState() then
            log.info("Connected to %s.", client.session.host)
            ui.stack:reset("home")
            code:release()
            font1:release()
            font2:release()
        end

        elapsed = 0
    end
end

function login:draw()
    love.graphics.push()
    love.graphics.clear(config.theme:color("SPLASH", "BACKGROUND"))
    love.graphics.setColor(config.theme:color("SPLASH", "LOGO_TEXT"))
    love.graphics.draw(code, code_x, code_y, 0,  1, 1, code_ox, code_oy)
    love.graphics.printf(instructions, font2, inst_x, inst_y, inst_w, "center")
    love.graphics.pop()
end

return login