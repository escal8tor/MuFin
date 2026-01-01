--- @type integer[] Font sizes for screen dimensions
local size

if W_HEIGHT == 640 then
    size = { 20, 22, 16, 18, 14, 16, 20 }
else
    size = { 28, 30, 22, 24, 18, 20, 32 }
end

--- @type table<string, love.Font> Fonts for UI components
local fonts = {
    large       = love.graphics.newFont("res/font/NotoSans.ttf", size[1]),
    large_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[2]),
    normal      = love.graphics.newFont("res/font/NotoSans.ttf", size[3]),
    normal_icon = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[4]),
    small       = love.graphics.newFont("res/font/NotoSans.ttf", size[5]),
    small_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[6]),
    prompt      = love.graphics.newFont("res/font/promptfont.ttf", size[7])
}

return fonts