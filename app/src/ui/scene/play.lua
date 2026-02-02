local client   = require "src.client"
local json     = require "src.external.json"
local nativefs = require "src.external.nativefs"
local ui       = require "src.ui.scene"

--- Download/format path to subtitles.
--- 
--- @param itemId string Jellyfin media item id.
--- @param source table  Media source
--- 
--- @return string arguments Relevant arguments to MPV.
local function getSubtitles(itemId, source)
    local args = ""-- string.format(" --sid=%d", math.max(source.DefaultSubtitleStreamIndex or 0, 0))
    local path = "data/playback/subtitles"

    if not nativefs.getInfo(path) then
        nativefs.createDirectory(path)
    end

    for _,stream in ipairs(source.MediaStreams) do

        if stream.SupportsExternalStream
            and stream.Type == "Subtitle"
            and stream.DeliveryMethod == "External"
        then
            local subpath = client.subtitle:downloadSubtitle(itemId, source, stream, path)

            if subpath then
                args = args.." --sub-file="..subpath
            end
        end
    end

    return args
end

--- Download media attachments.
--- 
--- Only applicable when transcoding, and only supported on TrimUI devices
--- (requires mpv >= 0.38.0)
--- 
--- @param source table Media sources.
--- 
--- @return string arguments Relevant arguments to MPV.
local function getAttachments(source)
    if not (DEVICE_NAME == "trimui" and source.MediaAttachments) then return "" end
    local path = "data/playback/attachments"

    if not nativefs.getInfo(path) then
        nativefs.createDirectory(path)
    end

    for _,attachment in ipairs(source.MediaAttachments) do

        if attachment.DeliveryUrl ~= nil then
	    client.video:getAttachment(attachment, path)
    	end
    end

    return "--sub-fonts-dir='"..path.."'"
end

local function startPlayback(data)
    local deviceProfile = json.decode(nativefs.read("res/static/device_profile.json"))
    local path = "data/playback"
    local cmdline

    nativefs.createDirectory(path)

    ::force_transcode::
    local info = client.media:getPostedPlaybackInfo( data.itemId, {
        AutoOpenLiveStream = true,
        DeviceProfile = deviceProfile,
        EnableTranscoding = true
    }):decode()

    for _, source in ipairs(info.MediaSources) do

        if (data.static or source.SupportsDirectStream or source.SupportsDirectPlay) and not data.transcode then
            -- Construct url for direct playback
            cmdline = string.format(
                "res/scripts/mpv_launch.sh '%s'",
                client.video:getVideoStreamUrl( data.itemId, {  static = "true" } )
            )

        else

            if source.TranscodingUrl then
                cmdline = string.format(
                    "res/scripts/mpv_launch.sh '%s' %s %s",
                    client.session.host..source.TranscodingUrl,
                    getSubtitles(data.itemId, source),
                    getAttachments(source)
                )

            elseif deviceProfile.DirectPlayProfiles then
                deviceProfile.DirectPlayProfiles = {}
                goto force_transcode

            else
                goto cleanup
            end
        end

        -- nativefs.write("data/command.txt", cmdline)
        break
    end

    if cmdline then
        os.execute(cmdline)
    end

    ::cleanup::
    os.execute("rm -rf "..path)

end

--- @class play : scene
local play = ui.scene {}
play.__index = play

function play:new()
    --- @type home
    return setmetatable(ui:scene(), play)
end

function play:load(data)
    collectgarbage("collect")
    love.window.setMode(1, 1, {borderless = true})

    startPlayback(data)

    love.window.setMode(W_WIDTH, W_HEIGHT, { resizable = true })
    ui.stack:pop()
end

return play
