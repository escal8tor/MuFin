local _session = require "src.client.session"
local _url     = require "src.external.url"

--- @class media:session
--- Interface for Jellyfin Media API.
local media = _session {}
media.__index = media

--- Initialize new client for Jellyfin Media API.
--- 
--- @param session session Session parameters
--- 
--- @return media media Client object.
function media.new(session)
    return setmetatable(_session(session), media)
end

--- [GET] Get playback info for media.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/MediaInfo/operation/GetPlaybackInfo)
--- 
--- @param itemId  string  Media item id
--- @param params  table   Query parameters
--- 
--- @return table response Decoded response 
function media.getPlaybackInfo(self, itemId, params)
    return self:__get("/Items/"..itemId.."/PlaybackInfo", params)
end

--- [POST] Get playback info for media.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/MediaInfo/operation/GetPostedPlaybackInfo)
--- 
--- @param itemId string Media item id
--- @param body   table  Request body
--- 
--- @return response response
function media.getPostedPlaybackInfo(self, itemId, body)
    return self:__post("/Items/"..itemId.."/PlaybackInfo" , body)
end

--- [POST] Open a media source.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/MediaInfo/operation/OpenLiveStream)
--- 
--- @param body table Request payload
--- 
--- @return response response
function media.openLiveStream(self, params, body)
    return self:__post("/LiveStreams/Open", body, params)
end

--- [POST] Close a media source.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/MediaInfo/operation/CloseLiveStream)
--- 
--- @param liveId string Livestream id
--- 
--- @return response response
function media.closeLiveStream(self, liveId)
    return self:__post("/LiveStreams/Close?liveStreamId="..liveId, {})
end

return media