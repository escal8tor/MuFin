local _session = require "src.client.session"

--- @class system:session
--- Interface for Jellyfin System API.
local system = _session {}
system.__index = system

--- Initialize new client for Jellyfin System API.
--- 
--- @param session session Session parameters
--- 
--- @return system system
function system.new(session)
    return setmetatable(_session(session), system)
end

return system