-- config/behavior.lua
-- Terminal behavior configuration

local wezterm = require('wezterm')

local M = {}

--- Apply behavior configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Default shell
  config.default_prog = { '/bin/zsh', '-l' }

  -- Selection word boundaries
  config.selection_word_boundary = ' \t\n{}[]()"\'`,;:@│┃'

  -- Hyperlink rules
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  table.insert(config.hyperlink_rules, {
    regex = [[\b\w+://[\w.-]+\.[a-z]{2,15}\S*\b]],
    format = '$0',
  })

  -- Exit behavior
  config.exit_behavior = 'Close'

  -- Bell
  config.audible_bell = 'Disabled'
  config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 150,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 150,
  }

  -- Default working directory
  config.default_cwd = wezterm.home_dir

  return config
end

return M
