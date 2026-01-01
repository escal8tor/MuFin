local channels = {
  --- downloader tasking channel
  DL_INPUT = love.thread.getChannel("downloader_in"),
  --- downloader result channel
  DL_OUTPUT = love.thread.getChannel("downloader_out"),
  --- logging input channel
  LOG_INPUT = love.thread.getChannel("logging_input")
}

return channels