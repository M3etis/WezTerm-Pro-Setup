-- ui/components.lua
-- Reusable status bar component factories
-- Each function returns WezTerm formatted status segments

local colors = require('ui.colors')
local icons = require('ui.icons')
local git = require('utils.git')
local battery = require('utils.battery')
local hostname = require('utils.hostname')
local cwd = require('utils.cwd')

local M = {}

-- Helpers -----------------------------------------------------------------

local function segment(text, fg, bg)
  if not text or text == '' then return {} end
  local bg = bg or colors.palette.surface0
  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = ' ' .. text .. ' ' },
    { Background = { Color = colors.palette.crust } },
    { Foreground = { Color = bg } },
    { Text = icons.powerline.right },
  }
end

local function run(cmd)
  local no_err, ok, stdout, _ = pcall(require('wezterm').run_child_process, cmd)
  if no_err and ok then return stdout:gsub('%s+$', '') end
  return nil
end

--- Try to detect a version by running a command, cached per key.
local version_cache = {}
local function cached_version(key, cmd)
  if version_cache[key] ~= nil then return version_cache[key] end
  local out = run(cmd)
  version_cache[key] = out or false -- false = tried but unavailable
  return version_cache[key]
end

-- Git ---------------------------------------------------------------------

--- Show current git branch
--- @param cwd_path string Working directory path
--- @return table segments
function M.git_branch(cwd_path)
  local branch = git.get_branch(cwd_path)
  if branch == '' then return {} end
  local text = icons.git.branch .. ' ' .. branch
  return segment(text, colors.semantic.git.branch, colors.palette.surface0)
end

--- Show dirty/clean indicator for git working tree
--- @param cwd_path string Working directory path
--- @return table segments
function M.git_dirty(cwd_path)
  if not cwd_path or cwd_path == '' then return {} end
  local dirty = git.is_dirty(cwd_path)
  if dirty then
    return segment(icons.git.dirty, colors.semantic.git.dirty, colors.palette.surface0)
  end
  return segment(icons.git.clean, colors.semantic.git.clean, colors.palette.surface0)
end

-- Language / tool environments --------------------------------------------

--- Show active Python virtual environment
--- @return table segments
function M.python_env()
  local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_DEFAULT_ENV')
  if not venv or venv == '' then return {} end
  local name = venv:match('([^/]+)$') or venv
  local text = icons.languages.python .. ' ' .. name
  return segment(text, colors.semantic.python, colors.palette.surface0)
end

--- Show Node.js version (from nvm/fnm or system)
--- @return table segments
function M.node_version()
  local ver = cached_version('node', { 'node', '--version' })
  if not ver then return {} end
  local text = icons.languages.node .. ' ' .. ver
  return segment(text, colors.semantic.node, colors.palette.surface0)
end

--- Show Rust version
--- @return table segments
function M.rust_version()
  local ver = cached_version('rustc', { 'rustc', '--version' })
  if not ver then return {} end
  -- Extract just "rustc X.Y.Z"
  local short = ver:match('^(rustc [%d%.]+)') or ver
  local text = icons.languages.rust .. ' ' .. short
  return segment(text, colors.semantic.rust, colors.palette.surface0)
end

--- Show Go version
--- @return table segments
function M.go_version()
  local ver = cached_version('go', { 'go', 'version' })
  if not ver then return {} end
  -- "go version go1.22.0 ..." -> "go1.22.0"
  local short = ver:match('go (go[%d%.]+)') or ver:match('(go[%d%.]+)') or ver
  local text = icons.languages.go .. ' ' .. short
  return segment(text, colors.semantic.go, colors.palette.surface0)
end

-- Container / orchestration -----------------------------------------------

--- Show active Docker context
--- @return table segments
function M.docker_context()
  local ctx = cached_version('docker_ctx', { 'docker', 'context', 'show' })
  if not ctx or ctx == 'default' then return {} end
  local text = icons.languages.docker .. ' ' .. ctx
  return segment(text, colors.semantic.docker, colors.palette.surface0)
end

--- Show current Kubernetes context
--- @return table segments
function M.k8s_context()
  local ctx = run({ 'kubectl', 'config', 'current-context' })
  if not ctx or ctx == '' then return {} end
  local text = icons.languages.kubernetes .. ' ' .. ctx
  return segment(text, colors.semantic.kubernetes, colors.palette.surface0)
end

-- System ------------------------------------------------------------------

--- Show battery status with icon and percentage
--- @return table segments
function M.battery()
  local info = battery.get_info()
  if info.percentage < 0 then return {} end

  local icon = battery.get_icon(info.percentage, info.charging)
  local fg = colors.semantic.battery.normal
  if info.charging then
    fg = colors.semantic.battery.charging
  elseif info.percentage <= 20 then
    fg = colors.semantic.battery.low
  end

  local text = icon .. ' ' .. info.percentage .. '%'
  return segment(text, fg, colors.palette.surface0)
end

--- Show current time
--- @return table segments
function M.clock()
  local text = icons.system.clock .. ' ' .. os.date('%H:%M')
  return segment(text, colors.palette.text, colors.palette.surface0)
end

--- Show hostname
--- @return table segments
function M.hostname()
  local name = hostname.get_short()
  if not name or name == '' then return {} end
  return segment(name, colors.palette.subtext1, colors.palette.surface0)
end

-- WezTerm workspace / domain / pane --------------------------------------

--- Show current WezTerm workspace name
--- @return table segments
function M.workspace()
  local ws = require('wezterm').mux.get_active_workspace()
  if not ws or ws == '' then return {} end
  local text = icons.ui.workspace .. ' ' .. ws
  return segment(text, colors.palette.lavender, colors.palette.surface0)
end

--- Show domain of the active pane (local, SSH, etc.)
--- @param pane table WezTerm pane object
--- @return table segments
function M.domain(pane)
  if not pane then return {} end
  local ok, domain = pcall(function() return pane:get_domain_name() end)
  if not ok or type(domain) ~= 'string' then return {} end
  if domain == '' or domain == 'local' then return {} end
  return segment(domain, colors.palette.sky, colors.palette.surface0)
end

return M
