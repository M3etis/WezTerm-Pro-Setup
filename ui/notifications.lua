-- ui/notifications.lua
-- Bell event handler with toast notifications for unfocused panes

local wezterm = require('wezterm')
local icons = require('ui.icons')

local M = {}

function M.setup()
  wezterm.on('bell', function(window, pane)
    -- Only show toast if the pane is not focused
    if pane:is_focused() then
      return
    end

    local title = 'Bell'
    local pane_title = pane:get_title()
    if pane_title and pane_title ~= '' then
      title = pane_title
    end

    window:toast_notification(
      'WezTerm',
      icons.ui.bell .. ' ' .. title .. ' triggered a bell',
      nil,  -- info URL (optional)
      4000  -- timeout in ms
    )
  end)
end

return M
