-- config/performance.lua
-- Performance and rendering configuration

local platform = require('utils.platform')

local M = {}

--- Apply performance configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Rendering backend: prefer WebGPU for GPU-accelerated rendering
  config.front_end = 'WebGpu'

  -- Frame rate limits
  config.max_fps = 120
  config.animation_fps = 60

  -- Scrollback buffer
  config.scrollback_lines = 10000

  -- Graphics protocol (kitty graphics for image support)
  config.enable_kitty_graphics = true

  -- Platform-specific optimizations
  if platform.is_macos then
    config.webgpu_force_fallback_adapter = false
  elseif platform.is_linux then
    config.enable_wayland = true
  end

  return config
end

return M
