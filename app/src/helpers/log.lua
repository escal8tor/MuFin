---@diagnostic disable: assign-type-mismatch
--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
-- Modified by escal8tor for use with love2d
local channels = require "src.helpers.channels"
local config   = require "src.external.config"
local nativefs = require "src.external.nativefs"
local utils    = require "src.external.utils"

local thread = love.thread.newThread([[
local path = ...
local nativefs = require "src.external.nativefs"
local channel  = require("src.helpers.channels").LOG_INPUT

while true do
    local msg = channel:demand()
    nativefs.append(path, msg)
]])

--- @enum (key) LogLevel
local logLevel = {
    trace = 1, -- Granular runtime information.
    debug = 2, -- Detailed runtime information.
    info  = 3, -- Nominal activity.
    warn  = 4, -- Exceptional, but otherwise benign activity.
    error = 5, -- Exceptional, problematic activity.
    fatal = 6  -- Irrecoverable circumstances.
}

--- @class log
--- 
--- @field path    string   Path to log file.
--- @field level   LogLevel Logging level.
--- @field running boolean  Set while logging backend is running.
--- 
--- @field trace fun(...) 
--- @field debug fun(...) 
--- @field info  fun(...) 
--- @field warn  fun(...) 
--- @field error fun(...) 
--- @field fatal fun(...) 
--- 
--- client logging facility
local log = {
    path    = config.client:read("Logging","path") or "data/client.log",
    level   = config.client:read("Logging","level") or "info",
    running = false
}

--- Start logging backend.
function log.start()
    thread:start(log.path)
end

function log.stop()
    thread:release()
end

--- Add functions for each of the log levels.
for name, value in pairs(logLevel) do
    local nameupper = name:upper()

    log[name] = function(...)
        if value < logLevel[log.level] then return end
        local msg = string.format(...)
        local info = debug.getinfo(2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline
        local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)

        if log.running then
            channels.LOG_INPUT:push(str)
        else
            nativefs.append(log.path, str)
        end
    end
end

return log
