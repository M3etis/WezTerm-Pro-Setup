-- utils/git.lua
-- Git integration utilities

local wezterm = require('wezterm')

local M = {}

-- Cache for git status (avoid polling on every render)
local cache = {
  branch = {},
  dirty = {},
  last_update = {},
}

local CACHE_TTL = 5 -- seconds

--- Get current git branch name
--- @param cwd string Working directory
--- @return string Branch name or empty string
function M.get_branch(cwd)
  if not cwd or cwd == '' then return '' end

  -- Check cache
  local now = os.time()
  if cache.branch[cwd] and (now - (cache.last_update[cwd] or 0)) < CACHE_TTL then
    return cache.branch[cwd]
  end

  local ok, success, stdout = pcall(wezterm.run_child_process, {
    'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'
  })

  local branch = ''
  if ok and success then
    branch = stdout:gsub('%s+$', '')
  end

  -- Update cache
  cache.branch[cwd] = branch
  cache.last_update[cwd] = now

  return branch
end

--- Check if working directory has uncommitted changes
--- @param cwd string Working directory
--- @return boolean True if dirty
function M.is_dirty(cwd)
  if not cwd or cwd == '' then return false end

  local now = os.time()
  if cache.dirty[cwd] ~= nil and (now - (cache.last_update[cwd] or 0)) < CACHE_TTL then
    return cache.dirty[cwd]
  end

  local ok, success, stdout = pcall(wezterm.run_child_process, {
    'git', '-C', cwd, 'status', '--porcelain'
  })

  local dirty = ok and success and stdout ~= ''
  cache.dirty[cwd] = dirty

  return dirty
end

--- Get ahead/behind count from upstream
--- @param cwd string Working directory
--- @return number ahead, number behind
function M.get_ahead_count(cwd)
  if not cwd or cwd == '' then return 0, 0 end

  local ok, success, stdout = pcall(wezterm.run_child_process, {
    'git', '-C', cwd, 'rev-list', '--left-right', '--count', 'HEAD...@{upstream}'
  })

  if ok and success then
    local ahead, behind = stdout:match('(%d+)%s+(%d+)')
    return tonumber(ahead) or 0, tonumber(behind) or 0
  end

  return 0, 0
end

--- Get full git status summary
--- @param cwd string Working directory
--- @return table Status info { branch, dirty, ahead, behind }
function M.get_status(cwd)
  local ahead, behind = M.get_ahead_count(cwd)
  return {
    branch = M.get_branch(cwd),
    dirty = M.is_dirty(cwd),
    ahead = ahead,
    behind = behind,
  }
end

--- Clear cache for a specific directory
--- @param cwd string|nil Working directory (nil to clear all)
function M.clear_cache(cwd)
  if cwd then
    cache.branch[cwd] = nil
    cache.dirty[cwd] = nil
    cache.last_update[cwd] = nil
  else
    cache.branch = {}
    cache.dirty = {}
    cache.last_update = {}
  end
end

return M
