-- utils/cwd.lua
-- Current working directory utilities

local M = {}

--- Get current working directory from pane
--- @param pane table WezTerm pane object
--- @return string Current working directory
function M.get(pane)
  local cwd = pane:get_current_working_dir()
  if cwd then
    -- Handle URL object (WezTerm returns URL objects)
    if type(cwd) == 'table' then
      return cwd.file_path or tostring(cwd)
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
