-- config/fonts.lua
-- Font and typography configuration

local wezterm = require('wezterm')

local M = {}

--- Apply font configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Font family
  config.font = wezterm.font_with_fallback({
    'MonaspiceNe Nerd Font',
    'JetBrainsMono Nerd Font',
    'Apple Color Emoji',
  })

  -- Font size and line height
  config.font_size = 14.0
  config.line_height = 1.2

  -- Ligatures and shaping
  config.harfbuzz_features = { 'calt', 'clig', 'liga' }

  -- Bold color behavior
  config.bold_brightens_ansi_colors = true

  return config
end

return M
