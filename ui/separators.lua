-- ui/separators.lua
-- Powerline separator utilities

local icons = require('ui.icons')
local colors = require('ui.colors')

local M = {}

--- Create a powerline left separator with colors
--- @param bg string Background color
--- @param fg string Foreground color
--- @return table WezTerm formatted string segment
function M.left(bg, fg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = icons.powerline.right }
end

--- Create a powerline right separator with colors
--- @param bg string Background color
--- @param fg string Foreground color
--- @return table WezTerm formatted string segments
function M.right(bg, fg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = icons.powerline.left }
end

--- Create a rounded left separator
--- @param bg string Background color
--- @param fg string Foreground color
--- @return table WezTerm formatted string segments
function M.rounded_left(bg, fg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = icons.powerline.right_rounded }
end

--- Create a rounded right separator
--- @param bg string Background color
--- @param fg string Foreground color
--- @return table WezTerm formatted string segments
function M.rounded_right(bg, fg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = icons.powerline.left_rounded }
end

--- Create a status bar segment with separator
--- @param text string Content text
--- @param bg string Background color
--- @param fg string Foreground color
--- @param sep_bg string Separator background (next segment's bg)
--- @return table WezTerm formatted string segments
function M.segment(text, bg, fg, sep_bg)
  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = ' ' .. text .. ' ' },
    { Background = { Color = sep_bg or colors.palette.crust } },
    { Foreground = { Color = bg } },
    { Text = icons.powerline.right },
  }
end

return M
