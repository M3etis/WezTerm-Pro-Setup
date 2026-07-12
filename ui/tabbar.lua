-- ui/tabbar.lua
-- Custom powerline tab bar with process icons and rounded separators

local wezterm = require('wezterm')
local colors = require('ui.colors')
local icons = require('ui.icons')
local process = require('utils.process')

local M = {}

-- Palette shortcuts
local p = colors.palette

-- Segment helpers

local function separator(fg, bg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = icons.powerline.right_rounded }
end

local function text_seg(fg, bg, text)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = text }
end

-- Build formatted segments for a single tab
local function format_tab(tab_info, is_active, is_last, max_width)
  local segments = {}
  local pane = tab_info.active_pane
  local proc = process.get_foreground(pane)

  local bg = is_active and p.surface0 or p.crust
  local fg = is_active and p.text or p.overlay1
  local sep_fg = is_active and p.surface0 or p.crust

  -- Left rounded separator
  for _, s in ipairs({ separator(sep_fg, p.crust) }) do
    table.insert(segments, s)
  end

  -- Process icon
  if proc.icon ~= '' then
    for _, s in ipairs({ text_seg(fg, bg, ' ' .. proc.icon) }) do
      table.insert(segments, s)
    end
  end

  -- Tab index
  for _, s in ipairs({ text_seg(fg, bg, ' ' .. (tab_info.tab_index + 1) .. ':') }) do
    table.insert(segments, s)
  end

  -- Title (truncated if needed)
  local title = tab_info.tab_title ~= '' and tab_info.tab_title or proc.display
  local max_title = max_width - 8
  if #title > max_title then
    title = title:sub(1, max_title - 1) .. '…'
  end
  for _, s in ipairs({ text_seg(fg, bg, ' ' .. title .. ' ') }) do
    table.insert(segments, s)
  end

  -- Zoomed pane indicator
  if pane.is_zoomed and pane:is_zoomed() then
    for _, s in ipairs({ text_seg(p.peach, bg, icons.ui.zoom .. ' ') }) do
      table.insert(segments, s)
    end
  end

  -- Unread activity indicator
  if tab_info.has_unseen_output then
    for _, s in ipairs({ text_seg(p.yellow, bg, icons.ui.bell .. ' ') }) do
      table.insert(segments, s)
    end
  end

  -- Right rounded separator
  local right_bg = is_last and p.crust or p.crust
  for _, s in ipairs({ separator(sep_fg, right_bg) }) do
    table.insert(segments, s)
  end

  return segments
end

-- Event registration

function M.setup()
  wezterm.on('format-tab-title', function(tab, _tabs, _panes, config, max_width)
    local is_active = tab.is_active
    local is_last = (tab.tab_index == #_tabs - 1)
    return format_tab(tab, is_active, is_last, max_width)
  end)
end

return M
