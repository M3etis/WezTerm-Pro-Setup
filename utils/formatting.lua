-- Text formatting and display utilities

local M = {}

--- Truncate string to max length with ellipsis
--- @param str string Input string
--- @param max_len number Maximum length
--- @return string Truncated string
function M.truncate(str, max_len)
  if not str or #str <= max_len then return str or '' end
  return str:sub(1, max_len - 1) .. '…'
end

--- Pad string to fixed width
--- @param str string Input string
--- @param width number Target width
--- @param align 'left'|'right'|'center' Alignment (default 'left')
--- @return string Padded string
function M.pad(str, width, align)
  align = align or 'left'
  str = str or ''
  local diff = width - #str
  if diff <= 0 then return str:sub(1, width) end

  if align == 'right' then
    return string.rep(' ', diff) .. str
  elseif align == 'center' then
    local left = math.floor(diff / 2)
    local right = diff - left
    return string.rep(' ', left) .. str .. string.rep(' ', right)
  else
    return str .. string.rep(' ', diff)
  end
end

--- Create icon + text display element
--- @param icon string Nerd Font icon
--- @param text string Display text
--- @param separator string Optional separator between icon and text
--- @return string Formatted string
function M.icon_text(icon, text, separator)
  separator = separator or ' '
  if not text or text == '' then return '' end
  return icon .. separator .. text
end

--- Format seconds into human readable duration
--- @param seconds number Duration in seconds
--- @return string Formatted duration
function M.format_duration(seconds)
  if seconds < 60 then
    return string.format('%ds', seconds)
  elseif seconds < 3600 then
    return string.format('%dm', math.floor(seconds / 60))
  else
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format('%dh%dm', hours, mins)
  end
end

return M
