--[[
--- @type integer[] Font sizes for screen dimensions
local size

if W_HEIGHT == 1080 then
    size = { 72, 44, 129, 36, 38, 28, 24, 22, 24, 48 }
elseif W_HEIGHT == 768 then
    size = { 72, 32, 98,  28, 30, 22, 24, 18, 20, 32 }
else
    size = { 72, 20, 65,  20, 22, 16, 18, 14, 16, 20 }
end
]]

--- @type table<string, love.Font> Fonts for UI components
local fonts = {
    logo        = love.graphics.newFont("res/font/Quicksand.ttf", 72),
    logo_small  = love.graphics.newFont("res/font/Quicksand.ttf", W_HEIGHT / 24),
    logo_large  = love.graphics.newFont("res/font/Quicksand.ttf", W_HEIGHT / 10),
    large       = love.graphics.newFont("res/font/NotoSans.ttf", W_HEIGHT / 28),
    large_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", W_HEIGHT / 30),
    normal      = love.graphics.newFont("res/font/NotoSans.ttf", W_HEIGHT / 34),
    normal_icon = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", W_HEIGHT / 30),
    small       = love.graphics.newFont("res/font/NotoSans.ttf", W_HEIGHT / 36),
    small_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", W_HEIGHT / 38),
    prompt      = love.graphics.newFont("res/font/promptfont.ttf", W_HEIGHT / 26)
}

return fonts
