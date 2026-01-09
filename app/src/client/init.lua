---@diagnostic disable: invisible, param-type-mismatch, undefined-field, need-check-nil
local config        = require "src.external.config"
local _audio        = require "src.client.endpoint.audio"
local _item         = require "src.client.endpoint.item"
local _media        = require "src.client.endpoint.media"
local _playstate    = require "src.client.endpoint.playstate"
local _quickconnect = require "src.client.endpoint.quickconnect"
local _show         = require "src.client.endpoint.show"
local _subtitle     = require "src.client.endpoint.subtitle"
local _system       = require "src.client.endpoint.system"
local _user         = require "src.client.endpoint.user"
local _video        = require "src.client.endpoint.video"
local _session      = require "src.client.session"
local log           = require "src.helpers.log"

--- @class client
--- 
--- ENDPOINTS
--- @field audio     audio     Audio accessors
--- @field item      item      General metadata 
--- @field media     media     Playback control
--- @field playstate playstate Playback reporting
--- @field show      show      Series-specific methods
--- @field subtitle  subtitle  Subtitle accessors
--- @field system    system    Jellyfin instance
--- @field user      user      Jellyfin user account
--- @field video     video     Video accessors
--- 
--- STATE
--- @field connected boolean Set while client is connected
--- @field qcData    table?  Set during QuickConnect
--- @field session   session User and device identifiers
--- 
--- Jellyfin API client
local client = {
    connected = false,
    session   = _session {
        host   = config.client:read("Host", "base_url"),
        device = config.client:read("Authentication","device"),
        id     = config.client:read("Authentication","did"),
        token  = config.client:read("Authentication","token"),
        verify = config.client:read("Host", "verify_ssl")
    }

}
client.__index = client

--- Connect to Jellyfin instance.
--- 
--- Attempts an authenticated request for user data with current session config.,
--- reporting pass/fail status.
--- 
--- @return boolean connected
function client:connect()

    if client.session.token ~= nil then
        log.trace("Requesting account information.")

        --- Attempt to authenticate using the saved token.
        local ok, response = pcall(function()
            return _user.getCurrentUser(client.session):decode()
        end)

        if ok then
            log.trace("Authenticated as user: %s.", response.Name)

            --- Set user id from response data.
            client.session.uid = response.Id
            self:__initializeEndpoints(client.session)
        else
            log.trace("Request failed.")

            --- clear stale token (if it exists).
            config.client:remove("Authentication","token")
            client.session:setHeader()
        end
    end

    return client.connected
end

--- Authenticate using username and password.
--- 
--- @return boolean connected
function client:basicAuth()

    local ok, response = pcall(function()
        return _user.authenticateByName(
            client.session,
            config.client:read("Authentication","username"),
            config.client:read("Authentication","password")
        ):decode()
    end)

    if ok then
        client.session:setHeader(response.AccessToken)
        config.client:insert("Authentication","token",  response.AccessToken)
        config.client:insert("Authentication","device", client.session.device)
        config.client:insert("Authentication","did",    client.session.id)
        --config.settings:remove("Authentication","password")
        config.client:save()
    else
        log.fatal("BasicAuth - %s", response)
    end

    return client:connect()
end

--- Initiate QuickConnect authentication.
--- 
--- @return boolean connected
function client:initQuickConnect()
    local ok, response = pcall(function()
       return  _quickconnect.initiateQuickConnect(client.session):decode()
    end)

    if ok then
        client.qcData = {
            code   = response.Code,  --- @type string User-facing code.
            secret = response.Secret --- @type string Request identifier.
        }

        return self:__completeQuickConnect(response)
    end

    log.error(response)
    return false
end

--- Get status of QuickConnect authentication.
--- 
--- @return boolean connected
function client:getQuickConnectState()
    local ok, response = pcall(function()
        return _quickconnect.getQuickConnectState(client.session, client.qcData.secret):decode()
    end)

    if ok then
        return self:__completeQuickConnect(response)
    end

    log.error(response)
    return false
end

--- @private
--- Complete quick connect authentication.
--- 
--- @param response response Data from initiate or get status.
--- 
--- @return boolean connected
function client:__completeQuickConnect(response)
    if not (response.Authenticated and client.qcData) then return false end
    local ok

    ok, response = pcall(function()
        return _user.authenticateWithQuickConnect(client.session, client.qcData.secret):decode()
    end)

    if ok then
        client.session:setHeader(response.AccessToken)
        config.client:insert("Authentication","token",  response.AccessToken)
        config.client:insert("Authentication","device", client.session.device)
        config.client:insert("Authentication","did",    client.session.id)
        config.client:save()

        if self:connect() then
            client.qcData = nil
            return true
        end
    end

    return false
end

--- Complete instance initialization.
function client:__initializeEndpoints(session)
    client.audio     = _audio.new(session)
    client.item      = _item.new(session)
    client.media     = _media.new(session)
    client.playstate = _playstate.new(session)
    client.show      = _show.new(session)
    client.subtitle  = _subtitle.new(session)
    client.system    = _system.new(session)
    client.user      = _user.new(session)
    client.video     = _video.new(session)
    client.connected = true
end

return client