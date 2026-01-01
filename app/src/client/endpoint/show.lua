local _session = require "src.client.session"

--- @class show:session
--- Interface for Jellyfin Subtitle API.
local show = _session {}
show.__index = show

--- Initialize new client for Jellyfin Subtitle API.
--- 
--- @param session session Session parameters
--- 
--- @return show show
function show.new(session)
    return setmetatable(_session(session), show)
end

--- [GET] Get seasons for a series.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/TvShows/operation/GetSeasons)
---
--- @param seriesId string Series item id
--- @param params   table  Query parameters
--- 
--- @return response response
function show.getSeasons(self, seriesId, params)
    return self:__get("/Shows/"..seriesId.."/Seasons", params)
end

--- [GET] Get episodes for a series.
---
--- [View Documents](https://api.jellyfin.org/#tag/TvShows/operation/GetEpisodes)
--- 
--- Note: To get episodes for a specific season,
---       use the seasonId parameter.
---
--- @param seriesId string Series item id
--- @param params   table  Query parameters
--- 
--- @return response response
function show.getEpisodes(self, seriesId, params)
    return self:__get("/Shows/"..seriesId.."/Episodes", params)
end

--- [GET] Get next up episodes.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/TvShows/operation/GetNextUp)
---
--- @param params table Query parameters
--- 
--- @return response response
function show.getNextUp(self, params)
    return self:__get("/Shows/NextUp", params)
end

return show