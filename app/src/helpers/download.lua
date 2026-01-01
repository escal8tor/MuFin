local globals  = require "src.helpers.globals"
local channels = require "src.helpers.channels"
local client   = require "src.client"
local nativefs = require "src.external.nativefs"

client:connect()

if not nativefs.getInfo('data/cache') then
    nativefs.createDirectory('data/cache')
end

while true do
    --- @type table download task parameters
    local task = channels.DL_INPUT:demand()
    local path = "data/cache/"..task.id

    if not nativefs.getInfo(path) then
        nativefs.createDirectory(path)
    end

    path = path.."/"..task.type:lower()..".png"

    if not nativefs.getInfo(path) or task.force then
        local rsp = client.item:getItemImage(task.id, task.type, path, task.params)
        if not rsp.ok then path = nil end
    end

    channels.DL_OUTPUT:push({
        id = task.id.."_"..task.type:lower(),
        path = path
    })
end