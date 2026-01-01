local _session = require "src.client.session"

--- @class playstate:session
--- Interface for Jellyfin Subtitle API.
local playstate = _session {}
playstate.__index = playstate

--- Initialize new client for Jellyfin Subtitle API.
--- 
--- @param session session Session parameters
--- 
--- @return playstate playstate Client object.
function playstate.new(session)
    return setmetatable(_session(session), playstate)
end

--- [POST] Report playback has started within a session
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Playstate/operation/ReportPlaybackStart)
---
--- @param info table Playback started info
--- 
--- @return response response
function playstate.reportPlaybackStart(self, info)
    return self:__post("/Sessions/Playing", info)
end

--- [POST] Report playback progress within a session
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Playstate/operation/ReportPlaybackProgress)
---
--- @param info table Playback progress info
--- 
--- @return response response
function playstate.reportPlaybackProgress(self, info)
    return self:__post("/Sessions/Playing/Progress", info)
end

--- [POST] Report playback has stopped within a session
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Playstate/operation/ReportPlaybackStopped)
---
--- @param info table Playback stopped info
--- 
--- @return response response Decoded response
function playstate.reportPlaybackStopped(self, info)
    return self:__post("/Sessions/Playing/Stopped", info)
end

return playstate