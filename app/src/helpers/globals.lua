local nativefs = require "src.external.nativefs"
local muos     = require "src.helpers.muos"

local sem_ver = {
  major = 0,
  minor = 1,
  patch = 0,
  extra = ""
}

_G.version = (function()
  local version = string.format("v%d.%d.%d", sem_ver.major, sem_ver.minor, sem_ver.patch)
  if sem_ver.extra ~= "" then
    version = version .. "-" .. sem_ver.extra
  end
  return version
end)()

_G.resolution = "640x480"

_G.device_resolutions = {
  "640x480",
  "720x480",
  "720x720",
  "1024x768",
  "1280x720",
}

W_WIDTH, W_HEIGHT = muos.getResolution()
DEVICE_NAME = muos.getDeviceName()