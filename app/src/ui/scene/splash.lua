local config = require "src.external.config"
local flux   = require "src.external.flux"
local font   = require "src.ui.component.font"
local ui     = require "src.ui.scene"

--#region helpers

--- @type love.Shader 
--- Shader used in [logo](lua://logo.mask) to create a stencil from an image.
--- 
--- [Link to the original](https://www.love2d.org/wiki/love.graphics.stencil)
local mask = love.graphics.newShader[[
    vec4 effect (vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
       if (Texel(texture, texture_coords).rgb == vec3(1.0)) {
            discard;
       }
       return vec4(0.0);
    }
]]

--- Create a horizontal gradient from one or more colors.
--- 
--- A simplified version of [example one](https://www.love2d.org/wiki/Gradients)
--- 
--- @param ... color Colors to use in the gradient
--- 
--- @return love.Mesh
local function gradient(...)
    local meshData = {}
    local colorLen = select("#", ...)

    for i = 1, colorLen do
        local color = select(i, ...)
        local x = (i - 1) / (colorLen - 1)

        meshData[#meshData + 1] = {x, 1, x, 1, color[1], color[2], color[3], color[4] or 1}
        meshData[#meshData + 1] = {x, 0, x, 0, color[1], color[2], color[3], color[4] or 1}
    end

    return love.graphics.newMesh(meshData, "strip", "static")
end

--#endregion helpers

--#region logo

--- @class logo
local logo =  {}
logo.__index = logo

function logo.load()
    logo.img = love.graphics.newImage("res/image/jellyfin_blank_logo_resized.png")
    logo.w = logo.img:getWidth()
    logo.h = logo.img:getHeight()
    logo.s = 0.5
    logo.x = W_WIDTH/2
    logo.y = W_HEIGHT/2
    logo.mesh = gradient(
        config.theme:color("SPLASH", "LOGO_GR1"),
        config.theme:color("SPLASH", "LOGO_GR2")
    )
end

function logo.mask()
    love.graphics.setShader(mask)
    love.graphics.draw(logo.img, 0, 0, 0, logo.s, logo.s, logo.w/2, logo.h/2)
    love.graphics.setShader()
end

--#endregion logo

--#region text

--- @class text
local text = {}
text.__index = text

function text.load()
    text.data = love.graphics.newText(font.logo, "Jellyfin")
    text.w = text.data:getWidth()
    text.h = text.data:getHeight()
    text.x = W_WIDTH/2
    text.y = W_HEIGHT/2
end

--#endregion text

--- @class splash:scene
--- 
--- Scene startup animation
local splash = ui.scene {}
splash.__index = splash

function splash:new()
    return splash
end

function splash:load(data)
    splash.finished = false
    splash.flux = flux.group()
    logo.load()
    text.load()

    local gap   = 15
    local wLogo = (logo.w * logo.s) / 2
    local wComb = (wLogo - (text.w)) / 2

    -- Calculations for where "center" is between the logo and text.
    local lFinal = wComb - (wLogo/2) - (gap/2)
    local tFinal = wComb + (text.w/2) + (gap/2)

    splash.lOff = 0
    splash.tOff = -W_WIDTH/2

    splash.flux
        -- Move logo back, text slides in underneath, both overshoot.
        :to(splash, 0.4, { lOff = -(logo.w/3), tOff = text.w/2 })
        :ease("quadinout")
        :delay(0.5)
        -- Both fall toward the center.
        :after(splash, 0.2, { lOff = lFinal, tOff = tFinal })
        :ease("cubicinout")
        :delay(0.1)
        -- Do nothing, set finished.
        :after(splash, 0, {})
        :delay(1)
        :oncomplete(splash.finish)
end

function splash:update(dt)
    splash.flux:update(dt)
end

function splash.finish()
    ui.stack:reset("login")
    logo.img:release()
    logo.mesh:release()
    text.data:release()
end

function splash:draw()
    local verts = {
        -(W_WIDTH/2) + splash.lOff, -(logo.y/2) * logo.s,
        0,                          -(logo.y/2) * logo.s,
        (logo.w/4) * logo.s,         (logo.y/2) * logo.s,
        -(W_WIDTH/2) + splash.lOff,  (logo.y/2) * logo.s
    }

    love.graphics.push()
    love.graphics.clear(config.theme:color("SPLASH", "BACKGROUND"))
    love.graphics.setColor(config.theme:color("SPLASH", "LOGO_TEXT"))
    love.graphics.draw(text.data, text.x + splash.tOff, text.y, 0, 1, 1, text.w/2, text.h/2)
    love.graphics.translate(logo.x + splash.lOff, logo.y)
    love.graphics.setColor(config.theme:color("SPLASH", "BACKGROUND"))
    love.graphics.polygon("fill", verts)
    love.graphics.stencil(logo.mask, "replace", 1)
    love.graphics.setStencilTest("equal", 0)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(logo.mesh, 0, -logo.h/7, math.rad(45), logo.w/3.8, logo.h/3.8)
    love.graphics.setStencilTest()
    love.graphics.pop()
end

function splash:keypressed(key)
    -- Cancel animation on any keypress.
    splash:finish()
end

return splash