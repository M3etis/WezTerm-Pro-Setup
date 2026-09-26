-- config/performance.lua
-- Performance and rendering configuration

local platform = require('utils.platform')

local M = {}

--- Apply performance configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Rendering backend: OpenGL is the reliable default.
  -- WebGPU is faster on supported machines but fails to start on others.
  config.front_end = 'OpenGL'

  -- Frame rate limits
  config.max_fps = 120
  config.animation_fps = 60

  -- Scrollback buffer
  config.scrollback_lines = 10000

  -- Graphics protocol (kitty graphics for image support)
  config.enable_kitty_graphics = true

  -- Platform-specific optimizations
  if platform.is_linux then
    config.enable_wayland = true
  end

  return config
end

return M
