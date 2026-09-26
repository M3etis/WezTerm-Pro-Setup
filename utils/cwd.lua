-- utils/cwd.lua
-- Current working directory utilities

local M = {}

--- Get current working directory from pane
--- @param pane table WezTerm pane object
--- @return string Current working directory
function M.get(pane)
  if not pane then return '' end

  local ok, cwd = pcall(function() return pane:get_current_working_dir() end)
  if not ok or not cwd then
    -- PaneInformation exposes a `cwd` field instead of a method
    ok, cwd = pcall(function() return pane.cwd end)
    if not ok then return '' end
  end

  if cwd then
    -- Handle URL object (WezTerm returns URL objects)
    if type(cwd) == 'table' then
      local ok_path, path = pcall(function() return cwd.file_path end)
      if ok_path and path then return path end
      return tostring(cwd)
    end
    return tostring(cwd)
  end
  return ''
end

--- Get display-friendly CWD (shortened)
--- @param pane table WezTerm pane object
--- @param max_depth number Maximum path depth (default 3)
--- @return string Shortened path
function M.get_for_display(pane, max_depth)
  local path = M.get(pane)
  local path_utils = require('utils.path')
  return path_utils.shorten(path, max_depth or 3)
end

return M
