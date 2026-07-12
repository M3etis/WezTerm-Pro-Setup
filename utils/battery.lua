-- utils/battery.lua
-- Battery status utilities

local wezterm = require('wezterm')

local M = {}

--- Get battery info from system
--- @return table { percentage, state, charging }
function M.get_info()
  local success, stdout, _ = wezterm.run_child_process({ 'pmset', '-g', 'batt' })
  if not success then
    return { percentage = -1, state = 'unknown', charging = false }
  end

  local percentage = stdout:match('(%d+)%%') or '-1'
  percentage = tonumber(percentage) or -1

  local charging = stdout:find('charging') ~= nil
  local charged = stdout:find('charged') ~= nil
  local discharging = stdout:find('discharging') ~= nil

  local state = 'unknown'
  if charged then state = 'charged'
  elseif charging then state = 'charging'
  elseif discharging then state = 'discharging'
  end

  return {
    percentage = percentage,
    state = state,
    charging = charging or charged,
  }
end

--- Get battery icon based on percentage and state
--- @param percentage number Battery percentage (0-100)
--- @param charging boolean Whether battery is charging
--- @return string Nerd Font icon
function M.get_icon(percentage, charging)
  if percentage < 0 then return '' end

  if charging then
    if percentage > 90 then return '' end
    if percentage > 60 then return '' end
    if percentage > 30 then return '' end
    if percentage > 10 then return '' end
    return ''
  end

  if percentage > 90 then return '' end
  if percentage > 60 then return '' end
  if percentage > 30 then return '' end
  if percentage > 10 then return '' end
  return ''
end

--- Get formatted battery status for display
--- @return string Formatted battery string (icon + percentage)
function M.get_status()
  local info = M.get_info()
  if info.percentage < 0 then return '' end

  local icon = M.get_icon(info.percentage, info.charging)
  return icon .. ' ' .. info.percentage .. '%'
end

return M
