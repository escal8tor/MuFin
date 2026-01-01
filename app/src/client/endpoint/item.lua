local _session = require "src.client.session"
local _url     = require "src.external.url"

--- @class item:session
--- Interface for Jellyfin Item API.
local item = _session {}
item.__index = item

--- Initialize new client for Jellyfin Item API.
--- 
--- @param session session Session parameters
--- 
--- @return item item Client object.
function item.new(session)
    return setmetatable(_session(session), item)
end

--- [GET] Get items based on a query.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Items/operation/GetItems)
--- 
--- @param params table Query parameters
--- 
--- @return response response
function item.getItems(self, params)
    return self:__get("/Users/"..self.uid.."/Items", params)
end

--- [GET] Download item.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Library/operation/GetDownload)
--- 
--- @param itemId string Media item id
--- 
--- @return response response
function item.getDownload(self, itemId)
    return self:__get("/Items/"..itemId.."/Download")
end

--- @alias imgType
--- | "Primary"
--- | "Art"
--- | "Backdrop"
--- | "Banner" 
--- | "Logo" 
--- | "Thumb" 
--- | "Disc" 
--- | "Box" 
--- | "Screenshot" 
--- | "Menu" 
--- | "Chapter" 
--- | "BoxRear" 
--- | "Profile"

--- [GET] Download image for item.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/Image/operation/GetItemImage2)
--- 
--- @param itemId string  Media item id
--- @param type   imgType Image type
--- @param path   string  File path
--- @param params table   Query parameters
--- 
--- @return response response
function item.getItemImage(self, itemId, type, path, params)
    return self:__get("/Items/"..itemId.."/Images/"..type, params, path)
end

--- [GET] Get an item from a user's library.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/UserLibrary/operation/GetItem)
--- 
--- @param itemId string Jellyfin item id
--- @param params table  Path parameters
--- 
--- @return response response
function item.getItem(self, itemId, params)
    return self:__get("/Users/"..self.uid.."/Items/"..itemId, params)
end

--- [GET] Get latest media.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/UserLibrary/operation/GetLatestMedia)
--- 
--- @param params table Query parameters
--- 
--- @return response response
function item.getLatestMedia(self, params)
    return self:__get("/Items/Latest", params)
end

--- [GET] Get in-progress items based on query.
--- 
--- @param params table  Query parameters
--- 
--- @return response response
function item.getResumeItems(self, params)
    return self:__get("/UserItems/Resume", params)
end

return item