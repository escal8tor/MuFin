local _session = require "src.client.session"

--- @class subtitle:session
--- Interface for Jellyfin Subtitle API.
local subtitle = _session {}
subtitle.__index = subtitle

--- Initialize new client for Jellyfin Subtitle API.
--- 
--- @param session session Session parameters
--- 
--- @return subtitle subtitle Client object.
function subtitle.new(session)
    return setmetatable(_session(session), subtitle)
end

--- [GET] Search remote subtitles.
--- 
--- https://api.jellyfin.org/#tag/Subtitle/operation/SearchRemoteSubtitles
--- 
--- @param itemId   string Media item id
--- @param language string Subtitle language
--- 
--- @return response response
function subtitle.searchRemoteSubtitle(self, itemId, language)
    return self:__get("/Items/"..itemId.."/RemoteSearch/Subtitles/"..language)
end

--- [GET] Format url for remote subtitle.
--- 
--- https://api.jellyfin.org/#tag/Subtitle/operation/GetRemoteSubtitles
--- 
--- @param subtitleId string Subtitle item id
--- 
--- @return string url
function subtitle.formatSubtitleUrl(self, subtitleId)
    return self.host.."/Providers/Subtitles/Subtitles"..subtitleId
end

--- [URL] Format url for subtitle download.
--- 
--- https://api.jellyfin.org/#tag/Subtitle/operation/DownloadRemoteSubtitles
--- 
--- @param itemId     string Media item id
--- @param subtitleId string Subtitle item id
--- 
--- @return string url
function subtitle.formatSubtitleDownloadUrl(self, itemId, subtitleId)
    return self.host.."/Items/"..itemId.."/RemoteSearch/Subtitles/"..subtitleId
end

--- [URL] Format subtitle stream url.
--- 
--- [View Document](https://api.jellyfin.org/#tag/Subtitle/operation/GetSubtitle)
---
--- @param itemId   string  Item id
--- @param sourceId string  Media source id
--- @param index    integer Subtitle stream index
--- @param format   string  Subtitle codec
--- 
--- @return string url
function subtitle.formatGetSubtitleUrl(self, itemId, sourceId, index, format)
    return ("%s/Videos/%s/%s/Subtitles/%s/Stream.%s?api_key=%s"):format(
        self.host,
        itemId,
        sourceId,
        index,
        format,
        self.token
    )
end

--- [GET/URL] Format url for, and attempt to download, subtitle
--- 
--- @param itemId string Media item id
--- @param source table  MediaSource
--- @param stream table  MediaStream for subtitle
--- @param path   string Output directory for file
--- 
--- @return string path
function subtitle.downloadSubtitle(self, itemId, source, stream, path)
    stream.Language = stream.Language or "unk"
    local url

    if stream.IsTextSubtitleStream and stream.DeliveryUrl then
        url = self.host..stream.DeliveryUrl
    else
        url = self:formatGetSubtitleUrl(
            itemId,
            source.Id,
            stream.Index,
            stream.Codec
        )
    end

    path = string.format(
        "%s/%s.%s.%s",
        path,
        stream.Index,
        stream.Language,
        stream.Codec
    )

    -- if self:__get(url, path).ok then
    --     return path
    -- end

    return url
end

--- [URL] Format subtitle stream url.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Subtitle/operation/GetSubtitleWithTicks)
--- 
--- @param itemId   string  Item id
--- @param sourceId string  Media source id
--- @param index    integer Subtitle stream index
--- @param ticks    integer Starting postion ticks
--- @param format   string  Format for subtitle
--- 
--- @return string url
function subtitle.formatGetSubtitleWithTicksUrl(self, itemId, sourceId, index, ticks, format)
    return ("%s/Videos/%s/%s/Subtitles/%d/%d/Stream.%s?api_key=%s"):format(
        self.host,
        itemId,
        sourceId,
        index,
        ticks,
        format,
        self.token
    )
end

return subtitle