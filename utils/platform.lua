-- utils/platform.lua
-- Platform detection utilities

local wezterm = require('wezterm')

local M = {}

--- Current platform detection
M.is_macos = wezterm.target_triple:find('darwin') ~= nil
M.is_linux = wezterm.target_triple:find('linux') ~= nil
M.is_windows = wezterm.target_triple:find('windows') ~= nil

--- Check if running under WSL
M.is_wsl = M.is_linux and os.getenv('WSL_DISTRO_NAME') ~= nil

--- Get platform-specific path separator
M.path_sep = M.is_windows and '\\' or '/'

--- Get platform name for display
function M.name()
  if M.is_macos then return 'macOS'
  elseif M.is_linux then return 'Linux'
  elseif M.is_windows then return 'Windows'
  else return 'Unknown'
  end
end

--- Get DPI scaling factor (macOS returns 2 for Retina)
function M.get_dpi()
  if M.is_macos then
    return 2.0
  end
  return 1.0
end

--- Platform-specific config modifier
function M.apply_platform_config(config)
  if M.is_macos then
    config.native_macos_fullscreen_mode = true
    config.window_decorations = 'RESIZE'
  elseif M.is_linux then
    config.enable_wayland = true
    config.window_decorations = 'NONE'
  elseif M.is_windows then
    config.window_decorations = 'RESIZE'
  end
  return config
end

return M
