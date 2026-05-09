local nativefs = require "src.external.nativefs"

local muos = {}

--- Get device model name (e.g. tui-brick).
--- 
--- @return string name
function muos.getDeviceName()

    local ok, name = pcall(function()
        for name in nativefs.lines("/opt/muos/device/config/board/name") do
            return name
        end
    end)

    return ok and name or "rocknix"
end

--- Get screen resolution.
--- 
--- @return number width
--- @return number height
function muos.getResolution()
    local width, height

    local ok, _ = pcall(function()
        width, height = love.window.getDesktopDimensions(1)
    end)

    if not ok then
        width, height = 640, 480
    end

    return width, height
end

return muos
