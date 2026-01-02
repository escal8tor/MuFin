--- @type integer[] Font sizes for screen dimensions
local size

if W_HEIGHT == 480 then
    size = { 72, 20, 65, 20, 22, 16, 18, 14, 16, 20 }
else
    size = { 72, 32, 98, 28, 30, 22, 24, 18, 20, 32 }
end

--- @type table<string, love.Font> Fonts for UI components
local fonts = {
    logo        = love.graphics.newFont("res/font/Quicksand.ttf",               size[1]),
    logo_small  = love.graphics.newFont("res/font/Quicksand.ttf",               size[2]),
    logo_large  = love.graphics.newFont("res/font/Quicksand.ttf",               size[3]),
    large       = love.graphics.newFont("res/font/NotoSans.ttf",                size[4]),
    large_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[5]),
    normal      = love.graphics.newFont("res/font/NotoSans.ttf",                size[6]),
    normal_icon = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[7]),
    small       = love.graphics.newFont("res/font/NotoSans.ttf",                size[8]),
    small_icon  = love.graphics.newFont("res/font/MaterialSymbolsOutlined.ttf", size[9]),
    prompt      = love.graphics.newFont("res/font/promptfont.ttf",              size[10])
}

return fonts