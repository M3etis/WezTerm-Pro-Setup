-- config/fonts.lua
-- Font and typography configuration

local wezterm = require('wezterm')

local M = {}

--- Apply font configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Also scan common user font locations so the bundled Nerd Fonts resolve
  -- even when CoreText/fontconfig caching has not picked them up yet.
  local home = os.getenv('HOME') or os.getenv('USERPROFILE') or ''
  config.font_dirs = {
    home .. '/Library/Fonts',
    home .. '/.local/share/fonts',
    '/Library/Fonts',
  }

  -- Font family
  -- Nerd Fonts 3.x expose both "X NF" (nameID 1) and "X Nerd Font" (nameID 16).
  config.font = wezterm.font_with_fallback({
    'MonaspiceNe NF',
    'MonaspiceNe Nerd Font',
    'JetBrainsMono NF',
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
