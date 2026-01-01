local _session = require "src.client.session"
local _url     = require "src.external.url"

--- @class audio:session
--- Interface for Jellyfin Item API.
local audio = _session {}
audio.__index = audio

--- Initialize new client for Jellyfin Audio API.
--- 
--- @param session session Session parameters
--- 
--- @return audio audio
function audio.new(session)
    return setmetatable(_session(session), audio)
end

--- [URL] Format url for master hls audio playlist.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/DynamicHls/operation/GetMasterHlsAudioPlaylist)
--- 
--- @param itemId string Media item id
--- @param params table  Query parameters
--- 
--- @return string url
function audio.getMasterHlsVideoPlaylistUrl(self, itemId, params)
    params = params or {}
    params["api_key"] = self.token
    local url = self.host.."/Audio/"..itemId.."/master.m3u8"

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

--- [URL] Format url for audio livestream over HTTP.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/DynamicHls/operation/GetVariantHlsAudioPlaylist)
--- 
--- @param itemId string Media item id
--- @param params table  Query parameters
--- 
--- @return string url
function audio.getVariantHlsAudioPlaylistUrl(self, itemId, params)
    params = params or {}
    params["api_key"] = self.token
    local url = self.host.."/Audio/"..itemId.."/main.m3u8"

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

return audio