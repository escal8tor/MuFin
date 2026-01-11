---@diagnostic disable: missing-return, assign-type-mismatch
local badr     = require "src.ui.component.badr"
local blurhash = require "src.external.blurhash"
local channels = require "src.helpers.channels"
local config   = require "src.external.config"
local icons    = require "src.ui.component.icon"
local lily     = require "src.external.lily"
local log      = require "src.helpers.log"
local nativefs = require "src.external.nativefs"

--#region blurhash

local downloader --- @type love.Thread
local pixelImage --- @type love.Image

 --- @type love.Shader
local bhShader = love.graphics.newShader([[
// Copyright (c) 2021 semyon422, modified by escal8tor
#define pi 3.1415926535897932384626433832795
uniform int size_x;
uniform int size_y;
uniform int screen_width;
uniform int screen_height;
uniform float pos_x;
uniform float pos_y;
uniform vec3 colors[81];
	
float to_srgb(float value)
{
	float v = max(0.0, min(1.0, value));
	if (v <= 0.0031308) {
        return v * 12.92;
	}
	return 1.055 * pow(v, 1.0 / 2.4) - 0.055;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = vec4(0, 0, 0, 1);
	
	for (int j = 0; j < size_y; j++) {
        for (int i = 0; i < size_x; i++) {
			float arg_x = cos(pi * float(pos_x - screen_coords[0]) * float(i) / float(screen_width));
			float arg_y = cos(pi * float(pos_y - screen_coords[1]) * float(j) / float(screen_height));
            float basis = arg_x * arg_y;
            vec3 color = colors[i + j * size_x];
            pixel[0] += color[0] * basis;
            pixel[1] += color[1] * basis;
            pixel[2] += color[2] * basis;
        }
	}
	pixel[0] = to_srgb(pixel[0]);
	pixel[1] = to_srgb(pixel[1]);
	pixel[2] = to_srgb(pixel[2]);

	return pixel * color;
}
]])

-- load shader required for drawing blurhashes
pcall(function()
	local pixelImageData = love.image.newImageData(1, 1)
	pixelImageData:setPixel(0, 0, 1, 1, 1, 1)
	pixelImage = love.graphics.newImage(pixelImageData)
end)

--#endregion blurhash

--#region image

--- @alias imgFit        
--- | "fill"         Scale image to fill viewport
--- | "fitWidth"     Scale width to fit, preserve aspect ratio
--- | "fitHeight"    Scale height to fit, preserve aspect ratio
--- | "centerWidth"  Fit width and center content
--- | "centerHeight" Fit height and center content

--- @class image:badr
--- 
--- @field protected data      love.Image? Drawable (when loaded)
--- @field protected imgWidth  number      Image width
--- @field protected imgHeight number      Image height
--- @field protected radius    number      Image corner radius
--- @field protected scaleX    number      Image scale factor X
--- @field protected scaleY    number      Image scale factor Y
--- 
--- @field loading  boolean Set while image is loading
--- @field updated  boolean Set once image path has been set
--- @field path     string  Path to image
--- @field fallback string  Path to fallback image
--- @field fit      imgFit  Image positioning within viewport
--- 
--- Image UI element.
local image = badr {}
image.__index = image

--- Initializes a new image object
--- 
--- @param props table? Component properties
--- 
--- @return image image new image object
function image:new(props)
    props = props or {}

    local proto = {
        path = props.path,
        fallback = props.fallback,
        id = props.id or tostring(love.timer.getTime()),
        x = props.x or 0,
        y = props.y or 0,
        width = props.width,
        height = props.height,
        radius = props.cr or 3,
        focusable = props.focusable,
        fit = props.fit or "fill",
        visible = false,
        data = nil,
        imgWidth = nil,
        imgHeight = nil,
        scaleX = nil,
        scaleY = nil,
        loading = false
    }


    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- @type image
    return setmetatable(badr(proto), image)
end

--- Load image from path.
--- 
--- Creates `love.Image` object from `path`, updating `imgWidth` and `imgHeight`
--- if successful. If `path` is nil or cannot be loaded, `fallback` is assigned to `path` 
--- and loaded instead.
--- 
--- @return boolean success Whether or not image was loaded.
function image:load()

    if self.path then
        lily.newImage(self.path)
        :onComplete(function(ud, img)
            self.loading = false
            self.imgX, self.imgY = self.x, self.y
            self.imgWidth, self.imgHeight = img:getDimensions()
            self.scaleX, self.scaleY = 1, 1
            self.originX, self.originY = nil, nil

            if self.fit:find("fill", 1, true) then
                self.scaleX = self.width / self.imgWidth
                self.scaleY = self.height / self.imgHeight

                if self.fit == "fillWidth" then
                    self.scaleY =  self.scaleX
                    self.imgY = self.imgY + ((self.height - (self.imgHeight + self.scaleY)) / 2)

                elseif self.fit == "fillHeight" then
                    self.scaleX = self.scaleY
                    self.imgX = self.imgX + ((self.width - (self.imgWidth * self.scaleX)) / 2)
                end
            end

            self.data = img
        end)
        :onError(function(ud, err, src)
            log.warn("Failed to load image: %s.", err)
            self.loading = false
            self:set(self.fallback)
            self.fallback = nil
        end)
        self.loading = true
    end
end

--- @protected
--- Draws image
function image:drawImage()

    if self.data then
        love.graphics.setColor(config.theme:color("IMAGE", "IMAGE"))
        love.graphics.draw(
            self.data,
            self.imgX,
            self.imgY,
            0,
            self.scaleX,
            self.scaleY,
            self.originX,
            self.originY
        )

    else
        if not self.loading and self.path then
            self:load()
        end

        love.graphics.setColor(config.theme:color("IMAGE", "BACKGROUND"))
        love.graphics.rectangle(
            "fill",
            self.x,
            self.y,
            self.width,
            self.height
        )
        love.graphics.setColor(1, 1, 1, 1)
    end
end

--- Render image to display
function image:draw()
    if not self.visible then return end
    love.graphics.push()
    love.graphics.stencil(
        function ()
            love.graphics.rectangle(
                "fill",
                self.x,
                self.y,
                self.width,
                self.height,
                self.radius,
                self.radius
            )
        end,
        "replace",
        1
    )
    love.graphics.setStencilTest("greater", 0)
    self:drawImage()
    love.graphics.setStencilTest()
    love.graphics.pop()
end

--- Unload image data, and clear properties that depend on it.
function image:release()
    if self.data == nil then return end

    ::release::
    if self.data:release() then
        self.data = nil
        self.imgWidth = nil
        self.imgHeight = nil
        self.scaleX = nil
        self.scaleY = nil
        self.originX = nil
        self.originY = nil
    else
        goto release
    end
end

--- Set objects image to path.
--- 
--- Prepends `path` to path lists, and releases the current image.
--- Upon the next call to `draw` the new image should be loaded.
--- 
--- @param path? string File path for image
function image:set(path)
    self.path = path and path or self.fallback
    self:release()
end

--#endregion image

--#region itemImage

local _dl_callbacks = {}

--- @class itemImage:image
--- 
--- @field protected bhWidth     number   Blurhash width
--- @field protected bhHeight    number   Blurhash height
--- @field protected bhColors    number[] Blurhash colors
--- @field protected icon        string   Name of icon for indicator
--- @field protected iconOpacity number   Indicator icon opacity
--- @field protected ovlyOpacity number   Overlay opacity
--- @field protected ovlyTween   tween?   Animation
--- 
--- Specialized image for card components
--- 
--- Manages an image that represents a selectable item. For example, 
--- poster art to represent a movie, or a screen cap to represent an episode.
local itemImage = image:new {}
itemImage.__index = itemImage

--- Create object for Jellyfin item image.
---
--- @param props table Component properties 
---
--- @return itemImage itemImage New itemImage object
function itemImage:new(props)
    props = props or {}

    local proto = {
        id          = props.item.Id.."_"..props.type:lower(),
        itemId      = props.itemId,
        imageType   = props.type,
        icon        = props.item.IsFolder and "enter" or "play",
        width       = props.width,
        height      = props.height,
        fallback    = props.fallback,
        iconOpacity = 0.0,
        ovlyOpacity = 0.0,
        updated     = false,
        tween       = nil
    }

    for key, value in pairs(props) do

        if not proto[key] then
            proto[key] = value
        end
    end

    --- Decode blurhash parameters.
    for imageType, hashes in pairs(props.item.ImageBlurHashes) do

        if imageType == props.type then
            pcall(function()
                proto.bhWidth, proto.bhHeight, proto.bhColors =
                    blurhash.decode(hashes[props.item.ImageTags[props.type]])
            end)
        end
    end

    --- @type itemImage
    local object = setmetatable(image:new(proto), itemImage)
    local filepath = "data/cache/"..props.item.Id.."/"..props.type:lower()..".png"

    if nativefs.getInfo(filepath) == nil then
        --- Generate a job to download the item's image.
        channels.DL_INPUT:push({
            id = props.item.Id,
            type = props.type,
            params = {
                maxWidth = props.width,
                maxHeight = props.height,
                format = "Png"
            }
        })

        --- Create a callback to assign the result.
        _dl_callbacks[object.id] = function(path)
            if object then 
                object:set(path)
                object:load()
            end
        end
    else
        -- Set path to cached image.
        object:set(filepath)
    end

    return object
end

--- Determine image path and download if necessary.
function itemImage:preload()
    if self.data or self.loading then return end
    local path = "data/cache/"..self.itemId.."/"..self.imageType:lower()..".png"

    if nativefs.getInfo(path) then
        self:set(path)
        self:load()

    elseif not self.downloadEnqueued then
        self.downloadEnqueued = true

        -- Enqueue a job to download the image 
        channels.DL_INPUT:push({
            id = self.itemId,
            type = self.imageType,
            params = {
                maxWidth = self.width,
                maxHeight = self.height,
                format = "Png"
            }
        })

        --- Create a callback to assign the result.
        _dl_callbacks[self.id] = function(path)
            if self then
                self.downloadEnqueued = false
                self:set(path)
                self:load()
            end
        end
    end
end

--- Activate fade in for overlay and icon.
--- 
--- Initializes `tween` to fade the overlay and icon in gradually.
--- Makes transition feel less abrupt/jarring.
function itemImage:onFocus()

    if self.ovlyTween then
        self.ovlyTween:stop()
        self.ovlyTween = nil
    end

    self.ovlyTween = self:getGroup(2)
        :to(self, 0.2, { ovlyOpacity = 0.52 })
        :oncomplete(function() self.ovlyTween = nil end)
        :ease("linear")
        :delay(0.1)

    if self.iconTween then
        self.iconTween:stop()
        self.iconTween = nil
    end

    self.iconTween = self:getGroup(2)
        :to(self, 0.1, { iconOpacity = 1.0 })
        :oncomplete(function() self.iconTween = nil end)
        :ease("linear")
        :delay(0.12)
end

--- Activate fade out for overlay and icon.
--- 
--- Same idea as `onFocus`, but inverted. Timing and order are adjusted 
--- for visual appeal.
function itemImage:onFocusLost()
    self.iconOpacity = 0.0

    if self.ovlyTween then
        self.ovlyTween:stop()
        self.ovlyTween = nil
    end

    if self.iconTween then
        self.iconTween:stop()
        self.iconTween = nil
    end

    self.ovlyTween = self:getGroup(2)
        :to(self, 0.096, { ovlyOpacity = 0.0 } )
        :ease("linear")
        :oncomplete(function() self.ovlyTween = nil end)
end

--- @private
--- Draw partially transparent rectangle over the image.
--- 
--- Dims the image, improving contrast with indicator icon.
function itemImage:drawOverlay()
    love.graphics.setColor(config.theme:color("IMAGE", "FOCUSED", self.ovlyOpacity))
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        self.height,
        self.radius,
        self.radius
    )
    love.graphics.setColor(1, 1, 1, 1)
end

--- @private
--- Draw an icon against a circle backdrop.
--- 
--- Draws an icon over the image to indicate what pressing east/confirm will do.
--- For example, play icon (right arrow) is shown for playable items. 
function itemImage:drawIndicator(name)
    local icon = icons[name or self.icon]
    local iconSize = icon:getHeight()
    local iconCent = iconSize / 2
    love.graphics.setColor(config.theme:color("IMAGE", "FOCUSED_CIRCLE", self.iconOpacity))
    love.graphics.circle(
        "fill",
        self.x + (self.width/2),
        self.y + (self.height/2),
        (iconSize*4/5)
    )
    love.graphics.setColor(config.theme:color("IMAGE","FOCUSED_ICON", self.iconOpacity))
    love.graphics.draw(
        icon,
        self.x + (self.width/2),
        self.y + (self.height/2),
        0,
        1,
        1,
        iconCent,
        iconCent
    )
end

--- @protected
--- Draw item image.
--- 
--- This function draws the card's image if it's loaded, initiating the load process if it isn't. 
--- In the meantime, if blurhash parameters are set, that will be drawn instead. Otherwise, 
--- the area is filled with the IMAGE:BACKGROUND color.
function itemImage:drawImage()

    -- Image is loaded.
    if self.data ~= nil then
        love.graphics.setColor(config.theme:color("IMAGE", "IMAGE"))
        love.graphics.draw(
            self.data,
            self.imgX,
            self.imgY,
            0,
            self.scaleX,
            self.scaleY,
            self.originX,
            self.originY
        )

    else
        -- Image isn't loaded or loading, and a path is set.
        if not self.loading and self.path then
            self:load()
        end

        -- Blurhash parameters are set.
        if self.bhWidth and bhShader then
            local x, y = love.graphics.inverseTransformPoint(0, 0)
            bhShader:send("size_x", self.bhWidth)
            bhShader:send("size_y", self.bhHeight)
            bhShader:send("colors", self.bhColors[0], unpack(self.bhColors))
            bhShader:send("screen_width", self.width)
            bhShader:send("screen_height", self.height)
            bhShader:send("pos_x", -x + self.x)
            bhShader:send("pos_y", -y + self.y)
            love.graphics.setShader(bhShader)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(pixelImage, self.x, self.y, 0, self.width, self.height)
            love.graphics.setShader()

        else
            love.graphics.setColor(config.theme:color("IMAGE", "BACKGROUND"))
            love.graphics.rectangle(
                "fill",
                self.x,
                self.y,
                self.width,
                self.height
            )
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

--- Draw component.
--- 
--- Draws the component.
function itemImage:draw()
    love.graphics.push()
    love.graphics.stencil(
        function ()
            love.graphics.rectangle(
                "fill",
                self.x,
                self.y,
                self.width,
                self.height,
                self.radius,
                self.radius
            )
        end,
        "replace",
        1
    )
    love.graphics.setStencilTest("greater", 0)
    self:drawImage()

    if (self.ovlyTween ~= nil or self.parent.focused) then

        if self.ovlyOpacity > 0.0 then
            self:drawOverlay()
        end

        if self.icon then
            self:drawIndicator()
        end
    end

    love.graphics.setStencilTest()
    love.graphics.pop()
end

--#endregion itemImage

--- @overload fun(props: table): image
local export = setmetatable(
    { new = image.new, forItem = function (t, ...) return itemImage:new(...) end },
    { __call = function (t, ...) return image:new(...) end, __index = image }
)

--- Proccess image assignment callbacks.
function export.updateImagePaths()
    -- Pop and assign any enqueued results.
    local result = channels.DL_OUTPUT:pop()

    while result do

        if _dl_callbacks[result.id] then
            _dl_callbacks[result.id](result.path)
            _dl_callbacks[result.id] = nil
        end

        result = channels.DL_OUTPUT:pop()
    end
end

function export.startThread()

    if downloader == nil then
        downloader = love.thread.newThread("src/helpers/download.lua")
        downloader:start()
    end
end

return export