---@diagnostic disable: param-type-mismatch, redundant-return-value
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
local nativefs = require "src.external.nativefs"


local utils = {}

--- Generate a GUID.
--- 
--- [Source](https://gist.github.com/jrus/3197011)
---
--- @return string guid
function utils.guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end


function utils.round(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

function utils.tostring(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = utils.round(x, .01)
    end
    t[#t + 1] = tostring(x)
  end
  return table.concat(t, " ")
end

--- Evaluate whether an `object` is of `type`.
--- 
--- https://medium.com/better-programming/oop-in-lua-9962e47ed603
--- 
--- @param object table Object to inspect
--- @param type   table Type for which to check
--- 
--- @return boolean isInstance
function utils.isInstance(object, type)

    while object do
        object = getmetatable(object)

        if object == type then
            return true
        end
    end

    return false
end

--- Split a string
--- 
--- @param value string String to split
--- @param sep   string Delimiter
--- 
--- @return table parts Array parts from string
function utils.split(value, sep)
    sep = sep or "%s"
    local parts = {}

    for str in string.gmatch(value, "([^"..sep.."]+)") do
        table.insert(parts, str)
    end

    return parts
end

function utils.strip_ansi_colors(str)
    return str:gsub("\27%[%d*;*%d*m", "")
end

function utils.strip_quotes(str)
    return str:gsub('"', '')
end

function utils.append_quotes(str)
    return '"' .. str .. '"'
end

function utils.get_extension(str)
    return str:match('.+%.(%w+)$')
end

function utils.get_filename(str)
    if not str then return nil end
    return str:gsub("%.%w+$", "")
end

function utils.match_extension(str, ext)
    return str:match('.+' .. ext .. '$')
end

function utils.get_filename_from_path(str)
    if not str then return nil end
    return str:match("([^/]+)%.%w+$")
end

function utils.escape_html(input)
    local entities = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["\""] = "&quot;",
        ["'"] = "&apos;"
    }

    local escapedString = input:gsub("[&<>'\"]", function(c)
        return entities[c] or c
    end)

    return escapedString
end

function utils.unescape_html(input)
    local entities = {
        ["&amp;"] = "&",
        ["&lt;"] = "<",
        ["&gt;"] = ">",
        ["&quot;"] = "\"",
        ["&apos;"] = "'"
    }

    local unescapedString = input:gsub("(&[%w#]+;)", function(entity)
        return entities[entity] or entity
    end)

    return unescapedString
end

--- Convert a hex color to a love-friendly equivalent
--- 
--- https://github.com/s-walrus/hex2color/blob/master/hex2color.lua
--- 
--- @param value string  Hex-formatted color value
--- @param alpha number? Alpha channel value
--- 
--- @return table RGBA { R, G, B, A }
function utils.hex2color(value, alpha)
    value = value:gsub("#", "") -- strip leading '#'.
    local color = {}

    for i=1, #value, 2 do
        color[#color+1] = tonumber(string.sub(value, i, i+1) or "0", 16) / 256
    end

    if not color[4] then
        color[4] = alpha or 1.0
    end

    return color
end

local function __genOrderedIndex(t)
    local orderedIndex = {}

    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end

    table.sort(orderedIndex)
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex(t)
        key = t.__orderedIndex[1]
    
    else
    
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
        
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function utils.orderedPairs(t)
  -- Equivalent of the pairs() function on tables. Allows to iterate
  -- in order
  return orderedNext, t, nil
end

function utils.tableMerge(...)
    local result = {}
    
    for _, t in ipairs({ ... }) do
    
        for k, v in pairs(t) do
            result[k] = v
        end
    end

    return result
end

function utils.load_image(path)
    local file_data = nativefs.newFileData(path)
    if not file_data then return nil end

    -- Use pcall to handle any errors that might occur when loading image data
    local success, image_data = pcall(function()
        return love.image.newImageData(file_data)
    end)

    if not success then return nil end

    return love.graphics.newImage(image_data)
end


function utils.keypoll(start, delay, ...)

    if (love.timer.getTime() - start) >= delay then

        for _, key in ipairs(...) do

            if love.keyboard.isDown(key) then
                return key
            end
        end
    end
end



--- @class dimKwds
--- @field width   number? Width for image/component
--- @field height  number? Height for image/component
--- @field aspect  number? Apply aspect ratio
--- @field scale   number? Scale factor

--- Calculate dimensions for an object.
---
--- @param kwds dimKwds Calculation parameters
--- 
--- @return number width  Item width
--- @return number height Item height
function utils.dimensions(kwds)
  kwds.scale = kwds.scale or 1

  if kwds.aspect then
      kwds.aspect = tonumber(kwds.aspect, 10)

      if not (kwds.width or kwds.height) then
        kwds.height = W_HEIGHT * kwds.scale
        kwds.width = kwds.height * kwds.aspect

      -- params.width xor params.height
      elseif not kwds.width ~= not kwds.height then

          if kwds.width then
              kwds.width = kwds.width * kwds.scale
              kwds.height = kwds.width / kwds.aspect

          else
              kwds.height = kwds.height * kwds.scale
              kwds.width = kwds.height * kwds.aspect
          end
      end
  end

  return math.floor(kwds.width), math.floor(kwds.height)
end

function utils.to_minutes(ticks)
    return math.floor(ticks / 10000000 / 60 )
end

function utils.to_seconds(ticks)
    return math.floor(ticks / 10000000)
end

--- Format card subtitle for Jellyfin item.
--- 
--- @param item table Jellyfin item
--- 
--- @return string subtitle for item
function utils.formatItemSubtitle(item)
    local subtitle = ""

    if item.Type == "MusicAlbum" and item.AlbumArtist ~= nil then
        subtitle = item.AlbumArtist

    else
        subtitle = tostring(item.ProductionYear)

        if item.Status == "Continuing" then
            subtitle = subtitle.." - Present"

        elseif item.EndDate then
            local endYear = string.match(item.EndDate, "^(%d*)")

            if endYear and endYear ~= subtitle then
                subtitle = subtitle.." - "..endYear
            end
        end
    end

    return subtitle
end

--- Format card title for Jellyfin item.
--- 
--- @param item table Jellyfin item
--- 
--- @return string title for item
function utils.formatItemTitle(item)
    local title = item.Name

    if item.Type == "Episode" then
        title = string.format("S%d:E%d - %s", item.ParentIndexNumber, item.IndexNumber, item.Name)
    end

    return title
end

--- Get icon name for item.
--- 
--- @param itemType string Type property of jellyfin item.
function utils.getIcon(itemType)

    if itemType == "Movie" or itemType == "Episode" then
        return  "play"
    end
end

return utils