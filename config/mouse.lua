-- config/mouse.lua
-- Mouse interaction configuration

local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

--- Apply mouse configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Disable scrollbar
  config.enable_scroll_bar = false

  -- Mouse wheel scrolls the terminal
  config.mouse_wheel_scrolls_tabs = false

  -- Mouse bindings
  config.mouse_bindings = {
    -- Right click: paste from clipboard
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom('Clipboard'),
    },

    -- Middle click: paste from primary selection
    {
      event = { Down = { streak = 1, button = 'Middle' } },
      mods = 'NONE',
      action = act.PasteFrom('PrimarySelection'),
    },

    -- Double click: select word
    {
      event = { Down = { streak = 2, button = 'Left' } },
      mods = 'NONE',
      action = act.SelectTextAtMouseCursor('Word'),
    },

    -- Triple click: select line
    {
      event = { Down = { streak = 3, button = 'Left' } },
      mods = 'NONE',
      action = act.SelectTextAtMouseCursor('Line'),
    },

    -- Ctrl+click: open link
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },
  }

  return config
end

return M
