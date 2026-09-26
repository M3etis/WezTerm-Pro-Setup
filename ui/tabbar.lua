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

-- Safe optional field read: WezTerm userdata errors on unknown fields
local function get_field(tbl, key, default)
  if type(tbl) ~= 'table' and type(tbl) ~= 'userdata' then
    return default
  end
  local ok, value = pcall(function() return tbl[key] end)
  if ok and value ~= nil then
    return value
  end
  return default
end

-- Build formatted segments for a single tab
local function format_tab(tab_info, is_active, is_last, max_width)
  local segments = {}
  local pane = get_field(tab_info, 'active_pane')
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

  -- Tab index (1-based; fall back to a stable placeholder if unavailable)
  local index = (get_field(tab_info, 'tab_index', 0)) + 1
  for _, s in ipairs({ text_seg(fg, bg, ' ' .. index .. ':') }) do
    table.insert(segments, s)
  end

  -- Title (truncated if needed)
  local raw_title = get_field(tab_info, 'tab_title', '')
  if type(raw_title) ~= 'string' or raw_title == '' then
    raw_title = proc.display
  end
  local title = raw_title
  local max_title = math.max(4, (max_width or 40) - 8)
  if #title > max_title then
    title = title:sub(1, max_title - 1) .. '…'
  end
  for _, s in ipairs({ text_seg(fg, bg, ' ' .. title .. ' ') }) do
    table.insert(segments, s)
  end

  -- Zoomed pane indicator (PaneInformation.is_zoomed is a boolean field)
  if get_field(pane, 'is_zoomed', false) then
    for _, s in ipairs({ text_seg(p.peach, bg, icons.ui.zoom .. ' ') }) do
      table.insert(segments, s)
    end
  end

  -- Unread activity indicator
  if get_field(tab_info, 'has_unseen_output', false) then
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
