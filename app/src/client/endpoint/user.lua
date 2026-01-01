local _session = require "src.client.session"

--- @class user:session
--- Interface for Jellyfin User API.
local user = _session {}
user.__index = user

--- Initialize new client for Jellyfin User API.
--- 
--- @param session session Session data
--- 
--- @return user user
function user.new(session)
    return setmetatable(_session(session), user)
end

--- [POST] Authenticate with username and password.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/User/operation/AuthenticateUserByName)
---
--- @param username string  Account name
--- @param password string  Account credential
---
--- @return response response
function user.authenticateByName(self, username, password)
    return self:__post( "/Users/AuthenticateByName", {
        Username = username,
        Pw = password
    })
end

--- [POST] Retreive authentication token using QuickConnect secret.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/User/operation/AuthenticateWithQuickConnect) 
---
--- @param secret string Secret returned from initiate endpoint.
--- 
--- @return response response
function user.authenticateWithQuickConnect(self, secret)
    return self:__post("/Users/AuthenticateWithQuickConnect", { secret = secret })
end

--- [GET] Get user by id.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/User/operation/GetUserById)
--- 
--- @param uid string? Jellyfin user id.
--- 
--- @return response response
function user.getUserById(self, uid)
    uid = uid or self.uid
    return self:__get("/Users/"..self.uid)
end

--- [GET] Get user details using instance auth. token.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/User/operation/GetCurrentUser)
--- 
--- @return response response
function user.getCurrentUser(self)
    return self:__get("/Users/Me")
end

--- [GET] Get user views.
--- 
--- [View Documents](https://api.jellyfin.org/#tag/UserViews/operation/GetUserViews)
--- 
--- @return response response
function user.getUserViews(self)
    return self:__get("/UserViews")
end

return user