--- MIT License
--- 
--- Copyright (c) [2024] [Gabriel Vale]
---
--- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
--- documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
--- the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
--- and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
---
--- The above copyright notice and this permission notice shall be included in all copies or substantial portions 
--- of the Software.
---
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
--- TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
--- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
--- CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
--- DEALINGS IN THE SOFTWARE.
--- 
---
--- @diagnostic disable: assign-type-mismatch, return-type-mismatch, cast-local-type

local ini      = require "src.external.ini"
local nativefs = require "src.external.nativefs"
local utils    = require "src.external.utils"

--#region config

--- @class config
--- 
--- @field protected value table Contents
--- 
--- @field type   string Type of config
--- @field path   string Path to configuration file
--- 
--- Base type for configurations.
local config   = {}
config.__index = config

--- Create new config object
---
--- @param path string  Path to configuration file
--- @param type string? Config type/name.
--- 
--- @return config config New config object
function config.new(path, type)
    local proto = {
        type = type or "generic",
        path = path,
        values = {}
    }

    return setmetatable(proto, config)
end

--- Load configuration
--- 
--- @return boolean ok Operation status
function config:load()
    local values = ini.load(self.path)

    if values ~= nil then
        self.values = values
    end

    return values ~= nil
end

--- Save configuration
--- 
--- @return boolean ok Operation status
function config:save()
    return ini.save_ordered(self.values, self.path)
end

--- Create configuration file from template
--- 
--- @param template string Path to template configuration
--- 
--- @return boolean ok Operation status
function config:createFrom(template)
    local example = ini.load(template)

    if example and ini.save(example, self.path) then
        self.values = example
        return true
    end

    return false
end

--- Read a configuration value
--- 
--- @param section string Section name
--- @param key     string Key name
--- 
--- @return string? value Value
function config:read(section, key)

    if not self:section_exists(section) then
        return
    end

    return ini.readKey(self.values, section, key)
end

--- Add/set a configuration value
--- 
--- @param section string Section name
--- @param key     string Key name
--- @param value   string Value
function config:insert(section, key, value)

    if self.values[section] == nil then
        self.values[section] = {}
    end

    ini.addKey(self.values, section, key, tostring(value))
end

--- Delete a configuration value.
--- 
--- @param section string Section name
--- @param key     string Key name
function config:remove(section, key)

    if self:section_exists(section) then
        ini.deleteKey(self.values, section, key)
    end
end

--- Evaluate whether section exists.
--- 
--- @param section string Section name
--- 
--- @return boolean exists Whether section exists
function config:section_exists(section)
    return self.values[section] ~= nil
end

--- Returns configuration contents.
--- 
--- @return table values Raw configuration
function config:getValues()
    return self.values
end

--#endregion config

--#region clientConfig

--- @class clientConfig:config
local clientConfig = setmetatable({}, { __index = config })
clientConfig.__index = clientConfig

--- Initializes user configuration instance.
--- 
--- @param name string -- Path to configuration file.
--- @return config self new instance for jellyfin config.
function clientConfig.create(name)
  local self = config.new("../config.ini", name)

  if not self:load() then
    self:createFrom("res/static/config.ini")
  end
  return self
end

--#endregion clientConfig

--#region themeConfig

--- @alias color [number, number, number, number]
--- red, green, blue, alpha

--- @class themeConfig:config
--- Specialized config type for UI theme
local themeConfig   = setmetatable({}, { __index = config })
themeConfig.__index = themeConfig

--- Inititalize theme
--- 
--- @param path string Config path
--- @param name string Theme name
--- 
--- @return themeConfig theme Theme object
function themeConfig.create(path, name)
    local object = setmetatable(config.new(path, name), themeConfig)
    object:load()
    --- @type themeConfig
    return object
end

--- Load configuration
--- 
--- @return boolean ok Operation status
function themeConfig:load()
    local values = ini.load(self.path)

    if values ~= nil then

        for section, colors in pairs(values) do
            self.values[section] = {}

            for key, value in pairs(colors) do
                self.values[section][key] = utils.hex2color(value)
            end
        end
    end

    return values ~= nil
end

--- Returns color defiend in theme by name.
--- 
--- @param section  string  Config section
--- @param key      string  Color key
--- @param alpha    number? Alpha value (0-1)
--- 
--- @return color color RGBA color value
--- @overload fun(self, id: string, alpha: number?): color
function themeConfig:color(section, key, alpha)
    local value

    if section[1] == "#" then
        return utils.hex2color(section)

    elseif key == nil or type(key) == "number" then
        alpha = key

        if section:sub(1,1) == "#" then
            value = utils.hex2color(section)
            goto skip
        end

        section, key = unpack(utils.split(section, ":"))
    end

    value = self:read(section, key)

    ::skip::
    if type(alpha) == "number" then
        value[4] = math.max(math.min(alpha, 1.0), 0.0)
    end

    return value
end

--#endregion themeConfig

--#region Initialization

local clientInst = clientConfig.create("settings")

--- @class theme
--- 
--- @field themes themeConfig[] Theme definitions
--- @field active string        Selected theme
--- @field names  string[]      Names of available themes
--- 
--- Handler for theme selection.
local theme = {
    themes = {},
    names = {},
    active = clientInst:read("Style", "theme")
}
theme.__index = theme

--- Returns color defiend in theme by name.
--- 
--- @param section  string  Config section
--- @param key      string  Color key
--- @param alpha    number? Alpha value (0-1)
--- 
--- @return color color RGBA color value
--- @overload fun(self, id: string, alpha: number?): color
function theme:color(section, key, alpha)
    return self.themes[self.active]:color(section, key, alpha)
end

function theme:next()

    for idx, name in ipairs(self.names) do

        if name == self.active then

            if idx < #self.names then
                self.active = self.names[idx+1]

            else
                self.active = self.names[1]
            end

            break
        end
    end

    clientInst:insert("Style", "theme", self.active)
    clientInst:save()
end

function theme:prev()

    for idx, name in ipairs(self.names) do

        if name == self.active then

            if idx > 1 then
                self.active = self.names[idx-1]

            else
                self.active = self.names[#self.names]
            end

            break
        end
    end

    clientInst:insert("Style", "theme", self.active)
    clientInst:save()
end


local path = "res/theme/"

for _, file in ipairs(nativefs.getDirectoryItems(path)) do

    if string.find(file, ".ini") then
        local name = string.gsub(file, ".ini", "")
        theme.themes[name] = themeConfig.create(path..file, name)
        theme.names[#theme.names+1] = name
    end
end

--#endregion Initialization

return {
    client = clientInst,
    theme  = theme
}