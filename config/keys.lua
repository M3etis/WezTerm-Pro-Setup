-- config/keys.lua
-- Leader key system and keybindings

local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

--- Leader key configuration
M.leader = {
  key = 'a',
  mods = 'CTRL',
  timeout_milliseconds = 1000,
}

--- Apply keybinding configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  config.leader = M.leader

  config.keys = {
    -- ==========================================
    -- Pane management (Leader + ...)
    -- ==========================================

    -- Split panes (Original)
    { key = '|', mods = 'LEADER',        action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '-', mods = 'LEADER',        action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '\\', mods = 'LEADER|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '_', mods = 'LEADER|SHIFT',  action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    
    -- Split panes (Vim-style, more convenient)
    { key = 'v', mods = 'LEADER',        action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) }, -- Side-by-side
    { key = 's', mods = 'LEADER',        action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },   -- Top-bottom

    -- Pane navigation (vim-style)
    { key = 'h', mods = 'LEADER',        action = act.ActivatePaneDirection('Left') },
    { key = 'j', mods = 'LEADER',        action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'LEADER',        action = act.ActivatePaneDirection('Up') },
    { key = 'l', mods = 'LEADER',        action = act.ActivatePaneDirection('Right') },

    -- Pane resize
    { key = 'H', mods = 'LEADER|SHIFT',  action = act.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'J', mods = 'LEADER|SHIFT',  action = act.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'K', mods = 'LEADER|SHIFT',  action = act.AdjustPaneSize({ 'Up', 5 }) },
    { key = 'L', mods = 'LEADER|SHIFT',  action = act.AdjustPaneSize({ 'Right', 5 }) },

    -- Close pane
    { key = 'x', mods = 'LEADER',        action = act.CloseCurrentPane({ confirm = true }) },

    -- Zoom pane
    { key = 'z', mods = 'LEADER',        action = act.TogglePaneZoomState },

    -- ==========================================
    -- Tab management (Leader + ...)
    -- ==========================================

    -- New tab
    { key = 'c', mods = 'LEADER',        action = act.SpawnTab('CurrentPaneDomain') },

    -- Close tab
    { key = '&', mods = 'LEADER|SHIFT',  action = act.CloseCurrentTab({ confirm = true }) },

    -- Tab navigation
    { key = '1', mods = 'LEADER',        action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER',        action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER',        action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER',        action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER',        action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER',        action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER',        action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER',        action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER',        action = act.ActivateTab(8) },

    -- Next/Previous tab
    { key = 'n', mods = 'LEADER',        action = act.ActivateTabRelative(1) },
    { key = 'p', mods = 'LEADER',        action = act.ActivateTabRelative(-1) },

    -- ==========================================
    -- Workspace management
    -- ==========================================

    -- Switch workspace
    { key = 'w', mods = 'LEADER',        action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },

    -- Rename workspace
    { key = ',', mods = 'LEADER',        action = act.PromptInputLine({
      description = 'Rename workspace',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    })},

    -- ==========================================
    -- Copy and search
    -- ==========================================

    -- Copy mode
    { key = '[', mods = 'LEADER',        action = act.ActivateCopyMode },

    -- Search
    { key = '/', mods = 'LEADER',        action = act.Search('CurrentSelectionOrEmptyString') },

    -- ==========================================
    -- Misc
    -- ==========================================

    -- Clear scrollback
    { key = 'k', mods = 'LEADER|CTRL',   action = act.ClearScrollback('ScrollbackAndViewport') },

    -- Reload config
    { key = 'r', mods = 'LEADER|CTRL',   action = act.ReloadConfiguration },

    -- Command palette
    { key = 'p', mods = 'LEADER|CTRL',   action = act.ActivateCommandPalette },

    -- Debug overlay
    { key = 'd', mods = 'LEADER|CTRL',   action = act.ShowDebugOverlay },

    -- Rename tab
    { key = 't', mods = 'LEADER',        action = act.PromptInputLine({
      description = 'Rename tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          local tab = window:active_tab()
          tab:set_title(line)
        end
      end),
    })},

    -- Quick launcher
    { key = 'Space', mods = 'LEADER',    action = act.QuickSelect },

    -- ==========================================
    -- Global shortcuts (no leader)
    -- ==========================================

    -- Copy/Paste
    { key = 'c', mods = 'SUPER',         action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'SUPER',         action = act.PasteFrom('Clipboard') },

    -- Font size
    { key = '=', mods = 'SUPER',         action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER',         action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER',         action = act.ResetFontSize },

    -- Fullscreen
    { key = 'f', mods = 'SUPER',         action = act.ToggleFullScreen },
  }

  -- Key tables for modal modes
  config.key_tables = {
    copy_mode = {
      { key = 'Escape', mods = 'NONE',  action = act.CopyMode('Close') },
      { key = 'q', mods = 'NONE',       action = act.CopyMode('Close') },
      { key = 'h', mods = 'NONE',       action = act.CopyMode('MoveLeft') },
      { key = 'j', mods = 'NONE',       action = act.CopyMode('MoveDown') },
      { key = 'k', mods = 'NONE',       action = act.CopyMode('MoveUp') },
      { key = 'l', mods = 'NONE',       action = act.CopyMode('MoveRight') },
      { key = 'w', mods = 'NONE',       action = act.CopyMode('MoveForwardWord') },
      { key = 'b', mods = 'NONE',       action = act.CopyMode('MoveBackwardWord') },
      { key = '0', mods = 'NONE',       action = act.CopyMode('MoveToStartOfLineContent') },
      { key = '$', mods = 'NONE',       action = act.CopyMode('MoveToEndOfLineContent') },
      { key = 'g', mods = 'NONE',       action = act.CopyMode('MoveToScrollbackTop') },
      { key = 'G', mods = 'SHIFT',      action = act.CopyMode('MoveToScrollbackBottom') },
      { key = 'v', mods = 'NONE',       action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
      { key = 'V', mods = 'SHIFT',      action = act.CopyMode({ SetSelectionMode = 'Line' }) },
      { key = 'y', mods = 'NONE',       action = act.Multiple({ { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } }) },
      { key = 'PageUp', mods = 'NONE',  action = act.CopyMode('PageUp') },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode('PageDown') },
    },

    search_mode = {
      { key = 'Escape', mods = 'NONE',  action = act.CopyMode('Close') },
      { key = 'Enter', mods = 'NONE',   action = act.CopyMode('PriorMatch') },
      { key = 'n', mods = 'NONE',       action = act.CopyMode('NextMatch') },
      { key = 'N', mods = 'SHIFT',      action = act.CopyMode('PriorMatch') },
      { key = 'r', mods = 'CTRL',       action = act.CopyMode('CycleMatchType') },
    },
  }

  return config
end

return M
