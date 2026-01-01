---@diagnostic disable: return-type-mismatch
local _session = require "src.client.session"
local _url     = require "src.external.url"
local nativefs = require "src.external.nativefs"

--- @class video:session
--- Interface for Jellyfin Video API.
local video = _session {}
video.__index = video

--- Initialize new client for Jellyfin Video API.
--- 
--- @param session session Session parameters
--- 
--- @return video video
function video.new(session)
    return setmetatable(_session(session), video)
end

--- [URL] Format url for video playback.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Videos/operation/GetVideoStream)
--- 
--- @param itemId  string Video item id
--- @param params  table  Query parameters 
--- 
--- @return string url
function video.getVideoStreamUrl(self, itemId, params)
    params = params or {}
    params["api_key"] = self.token
    local url = self.host.."/Videos/"..itemId.."/stream"

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

--- @alias containerType
--- | "ts"   Transport Stream
--- | "webm" WebM
--- | "asf"  Advanced Systems Format
--- | "wmv"  Windows Media Video
--- | "ogv"  Ogg Video
--- | "mp4"  MPEG-4
--- | "m4v"  MPEG-4
--- | "mkv"  Matroska
--- | "mpeg" MPEG-1/2
--- | "mpg"  MPEG-1/2
--- | "avi"  Audio Video Interleave
--- | "3gp"  3GPPG Video Standard
--- | "wtv"  Windows Recorded Television Show
--- | "m2ts" MPEG-2 Transport Stream
--- | "mov"  QuickTime File Format Video
--- | "iso"  ISO/IEC Mutlimedia container
--- | "flv"  Flash Video

--- [URL] Format url for video playback with a specific container.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Videos/operation/GetVideoStreamByContainer)
--- 
--- @param itemId    string        Video item id
--- @param container containerType Container type (e.g. mkv)
--- @param params    table         Query parameters 
--- 
--- @return string url
function video.getVideoStreamUrlByContainer(self, itemId, container, params)
    params = params or {}
    params["api_key"] = self.token
    local url = self.host.."/Videos/"..itemId.."/stream."..container

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

--- [URL] Format url for master hls video playlist.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/DynamicHls/operation/GetMasterHlsVideoPlaylist)
--- 
--- @param self session Session Data
--- @param itemId  string  Media item id
--- @param params  table   Query parameters
--- 
--- @return string url
function video.getMasterHlsVideoPlaylistUrl(self, itemId, params)
    params = params or {}
    params["api_key"] = self.token
    local url = self.host.."/Videos/"..itemId.."/master.m3u8"

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

--- [URL] Format url for video livestream over HTTP.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/DynamicHls/operation/GetVariantHlsVideoPlaylist)
--- 
--- @param itemId  string  Media item id
--- @param params  table   Query parameters
--- 
--- @return string url Stream url for video playlist.
function video.getVariantHlsVideoPlaylistUrl(self, itemId, params)
    params = params or {}
    params["api_key"] = self.host
    local url = self.host.."/Videos/"..itemId.."/main.m3u8"

    if params then
        url = url.."?".._url.table(params)
    end

    return url
end

--- [GET] Downlaod a video attachment.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/VideoAttachments/operation/GetAttachment)
---
--- @param source table  Attachment data.
--- @param path   string Output file path.
--- 
--- @return boolean ok Downlaod status.
function video.getAttachment(self, source, path)
    local dst = path.."/"..source.FileName
    local tmp = path.."/tmp"

    self:__get(source.DeliveryUrl, tmp)

    if nativefs.getInfo(path.."/tmp") then
        os.execute("mv '"..tmp.."' '"..dst.."'")
    end

    return nativefs.getInfo(dst)
end

return video