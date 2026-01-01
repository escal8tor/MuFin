---@diagnostic disable: cast-local-type, redundant-return-value, undefined-field
local _url     = require "src.external.url"
local json     = require "src.external.json"
local log      = require "src.helpers.log"
local muos     = require "src.helpers.muos"
local nativefs = require "src.external.nativefs"
local utils    = require "src.external.utils"

local HDR_PATH = 'data/header'

--#region response

--- @class response
local response = {}
response.__index = response

--- Initialize a new response object.
--- 
--- @param path string File path for response data.
--- 
--- @return response response Response response... response.
function response:new(path)
    local ok = nativefs.getInfo(path) ~= nil
    return setmetatable({ path = path, ok = ok }, response)
end

--- Decode JSON response data.
--- 
--- @return table json Response data
function response:decode()
    local data = json.decode(nativefs.read(self.path))
    os.execute("rm '"..self.path.."'")
    return data
end

--#endregion response

--#region session

--- @class session
--- 
--- @field protected header string Authorization header
--- 
--- @field device  string  Device name
--- @field host    string  Jellyfin host
--- @field id      string  Device id
--- @field name    string  client name
--- @field token   string  Authentication token
--- @field uid     string  Jellyfin user id
--- @field verify  boolean Ssl certificate verification
--- @field version string  Client version
---
--- Container for jellyfin session parameters.
local session = {}
session.__index = session

--- Initialize a new session object.
--- 
--- @param data table Session data
--- 
--- @return session session Initialized session
function session:new(data)
    local proto = {
        device  = data.device  or muos.getBoardName(),
        host    = data.host,
        id      = data.did     or utils.guid(),
        name    = data.name    or "MuFin",
        uid     = data.uid,
        verify  = data.verify == "true",
        version = _G.version
    }

    self.setHeader(proto, data.token)
    return setmetatable(proto, session)
end

--- Set authorization token
function session.setHeader(self, token)
    nativefs.remove(HDR_PATH)

    local header = ('Authorization: MediaBrowser Client="%s", Device="%s", DeviceId="%s", Version="%s"')
                   :format(self.name, self.device, self.id, self.version)

    if token then
        header = 'Authorization: MediaBrowser Token="'..token..'"'
        self.token = token
    else
        self.token = nil
    end

    nativefs.write(HDR_PATH, header)
end

--- Make a GET request.
--- 
--- Assembles and invokes a curl command using 
--- [os.execute](command:extension.lua.doc?["en-us/51/manual.html/pdf-os.execute"])
---
--- @param endpoint string  Path to Jellyfin API endpoint
--- @param params   table?  Path parameters for request
--- @param filepath string? Output path (default: 'data/response.json')
---
--- @overload fun(self: session, endpoint: string, filepath: string?)
function session.__get(self, endpoint, params, filepath)
    filepath = filepath or 'data/response'
    local url = self.host..endpoint

    if params ~= nil then

        if type(params) ~= "string" then
            url = "'"..url.."?".._url.table(params).."'"
        else
            filepath = params
        end
    end

    local command = "curl "..url..
        (" --header @%s"):format(HDR_PATH)..
        (" -o '%s'"):format(filepath)

    if not self.verify then
        command = command.." -k"
    end

    --log.trace("%s",command)
    os.execute(command)

    return response:new(filepath)
end

--- Make a POST request.
--- 
--- Assembles and invokes a curl command using 
--- [os.execute](command:extension.lua.doc?["en-us/51/manual.html/pdf-os.execute"])
---
--- @param endpoint string  Path to Jellyfin API endpoint
--- @param body     table?  Request payload
--- @param params   table?  Path parameters for request
--- @param filepath string? Output path (default: 'data/response.json')
---
--- @return table response Decoded response from server.
function session.__post(self, endpoint, body, params, filepath)
    filepath = filepath or 'data/response'
    local url = self.host..endpoint

    if type(params) == "table" and #params > 0 then
        url = "'"..url.."?".._url.table(params).."'"

    elseif type(params) == "string" then
        filepath = params
    end

    local command = "curl "..url..
        (" --header @%s"):format(HDR_PATH)..
        (" -o '%s'"):format(filepath)

    if body then
        command = command..(" --json '%s'"):format(json.encode(body))
    end

    if not self.verify then
        command = command.." -k"
    end

    --log.trace("%s",command)
    os.execute(command)

    return response:new(filepath)
end

--#endregion session

return setmetatable(
    { new = session.new },
    { __call = function (t, ...) return session:new(...) end }
)