-- utils/hostname.lua
-- Hostname detection utilities

local wezterm = require('wezterm')

local M = {}

--- Get full hostname
--- @return string Hostname
function M.get()
  local ok, success, stdout = pcall(wezterm.run_child_process, { 'hostname' })
  if ok and success then
    return stdout:gsub('%s+$', '')
  end
  return os.getenv('HOSTNAME') or os.getenv('COMPUTERNAME') or 'localhost'
end

--- Get short hostname (without domain)
--- @return string Short hostname
function M.get_short()
  local hostname = M.get()
  return hostname:match('^([^%.]+)') or hostname
end

--- Check if current session is SSH
--- @param pane table WezTerm pane object
--- @return boolean True if SSH session
function M.is_ssh(pane)
  local process = pane:get_foreground_process_name() or ''
  return process:find('ssh') ~= nil
end

return M
