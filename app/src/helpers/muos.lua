local nativefs = require "src.external.nativefs"

local muos = {}

--- Read device model from system configuration.
--- 
--- @return string name
function muos.getBoardName()

    for name in nativefs.lines("/opt/muos/device/config/board/name") do
        return name
    end

    return "muos"
end

return muos