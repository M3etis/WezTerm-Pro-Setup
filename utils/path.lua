-- Path manipulation and shortening utilities

local M = {}

--- Shorten a path to max_depth components
--- @param path string Full path
--- @param max_depth number Maximum directory components to show (default 3)
--- @return string Shortened path
function M.shorten(path, max_depth)
  max_depth = max_depth or 3
  if not path or path == '' then return '' end

  -- Replace home directory with ~
  local home = os.getenv('HOME') or ''
  if home ~= '' then
    path = path:gsub('^' .. home:gsub('%-', '%%-'), '~')
  end

  -- Split path into components
  local parts = {}
  for part in path:gmatch('[^/]+') do
    table.insert(parts, part)
  end

  -- If within max_depth, return as-is
  if #parts <= max_depth then
    return path
  end

  -- Show first char of middle components
  local result = {}
  for i, part in ipairs(parts) do
    if i <= 1 or i >= #parts then
      table.insert(result, part)
    else
      table.insert(result, part:sub(1, 1))
    end
  end

  return table.concat(result, '/')
end

--- Get the basename of a path
--- @param path string Full path
--- @return string Basename
function M.get_basename(path)
  if not path or path == '' then return '' end
  return path:match('([^/]+)$') or path
end

--- Extract project name from a path (git root or directory name)
--- @param path string Full path
--- @return string Project name
function M.get_project_name(path)
  if not path or path == '' then return 'default' end

  -- Try to find git root
  local git_root = path
  while git_root and git_root ~= '/' and git_root ~= '' do
    local handle = io.open(git_root .. '/.git', 'r')
    if handle then
      handle:close()
      return M.get_basename(git_root)
    end
    git_root = git_root:match('(.+)/[^/]*$')
  end

  return M.get_basename(path)
end

return M
