local _session = require "src.client.session"
local _url     = require "src.external.url"

--- @class quickconnect:session
--- Interface for Jellyfin Media API.
local quickconnect = _session {}
quickconnect.__index = quickconnect

--- Initialize new client for Jellyfin Media API.
--- 
--- @param session session Session parameters
--- 
--- @return quickconnect quickconnect Client object.
function quickconnect.new(session)
    return setmetatable(_session(session), quickconnect)
end

--- [POST] Inititate a QuickConnect.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/QuickConnect/operation/InitiateQuickConnect)
--- 
--- @return response response
function quickconnect.initiateQuickConnect(self)
    return self:__post("/QuickConnect/Initiate")
end

--- [GET] Attempt to retreive authentication information.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/QuickConnect/operation/GetQuickConnectState)
---
--- @param secret string Secret returned from initiate endpoint.
--- 
--- @return response
function quickconnect.getQuickConnectState(self, secret)
    return self:__get("/QuickConnect/Connect", { secret = secret })
end

--- [GET] Check if quick connect is enabled.
---
--- [View Documents](https://api.jellyfin.org/#tag/QuickConnect/operation/GetQuickConnectEnabled) 
--- 
--- @param self quickconnect
function quickconnect.getQuickConnectEnabled(self)
    return self:__get("/QuickConnect/Enabled")
end

return quickconnect