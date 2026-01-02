local nativefs = require "src.external.nativefs"

local muos = {}

--- Get device model name (e.g. trimui-brick).
--- 
--- @return string name
function muos.getDeviceName()

    for name in nativefs.lines("/opt/muos/device/config/board/name") do
        return name
    end

    return "muos"
end

--- Get screen resolution.
--- 
--- @return number width
--- @return number height
function muos.getResolution()
    local width, height

    for value in nativefs.lines("/opt/muos/device/config/mux/width") do
        width = tonumber(value) or 640
    end

    for value in nativefs.lines("/opt/muos/device/config/mux/height") do
        height = tonumber(value) or 480
    end

    return width, height
end

return muos