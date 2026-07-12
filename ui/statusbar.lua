-- ui/statusbar.lua
-- Rich status bar composition using reusable components

local wezterm = require('wezterm')
local components = require('ui.components')
local colors = require('ui.colors')
local icons = require('ui.icons')
local separators = require('ui.separators')
local cwd_utils = require('utils.cwd')

local M = {}

-- CPU and Memory helpers (not in components, so we add them here) ---------

local function get_cpu_usage()
  local no_err, ok, stdout, _ = pcall(wezterm.run_child_process, { 'sysctl', '-n', 'hw.ncpu' })
  if not no_err or not ok then return nil end
  local cores = tonumber(stdout:match('(%d+)'))
  if not cores then return nil end

  -- Get load average
  no_err, ok, stdout, _ = pcall(wezterm.run_child_process, { 'sysctl', '-n', 'vm.loadavg' })
  if not no_err or not ok then return nil end
  local load1 = stdout:match('{ ([%d%.]+) ')
  if not load1 then return nil end

  local pct = math.floor((tonumber(load1) / cores) * 100)
  return math.min(pct, 100)
end

local function get_memory_usage()
  local no_err, ok, stdout, _ = pcall(wezterm.run_child_process, { 'vm_stat' })
  if not no_err or not ok then return nil end

  local page_size = 16384 -- 16KB on Apple Silicon, typical
  local free_pages = tonumber(stdout:match('Pages free:%s+(%d+)')) or 0
  local active_pages = tonumber(stdout:match('Pages active:%s+(%d+)')) or 0
  local wired_pages = tonumber(stdout:match('Pages wired down:%s+(%d+)')) or 0
  local compressed_pages = tonumber(stdout:match('Pages occupied by compressor:%s+(%d+)')) or 0

  local used_mb = ((active_pages + wired_pages + compressed_pages) * page_size) / (1024 * 1024)
  local total_mb = ((free_pages + active_pages + wired_pages + compressed_pages) * page_size) / (1024 * 1024)

  if total_mb <= 0 then return nil end
  return math.floor((used_mb / total_mb) * 100)
end

-- Segment builder (powerline style) ---------------------------------------

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

-- Left status: CWD + Git info --------------------------------------------

local function build_left_status(window, pane)
  local segments = {}
  local pane_cwd = cwd_utils.get(pane)

  -- Current directory
  local display_cwd = cwd_utils.get_for_display(pane, 3)
  if display_cwd ~= '' then
    for _, s in ipairs(segment(icons.ui.pane .. ' ' .. display_cwd, colors.palette.text, colors.palette.surface0)) do
      table.insert(segments, s)
    end
  end

  -- Git branch
  for _, s in ipairs(components.git_branch(pane_cwd)) do
    table.insert(segments, s)
  end

  -- Git dirty indicator
  for _, s in ipairs(components.git_dirty(pane_cwd)) do
    table.insert(segments, s)
  end

  -- Zoom indicator
  if pane:is_zoomed() then
    for _, s in ipairs(segment(icons.ui.zoom .. ' ZOOM', colors.palette.peach, colors.palette.surface0)) do
      table.insert(segments, s)
    end
  end

  window:set_left_status(wezterm.format(segments))
end

-- Right status: all status components ------------------------------------

local function build_right_status(window, pane)
  local segments = {}

  -- Language / tool environments
  for _, s in ipairs(components.python_env()) do
    table.insert(segments, s)
  end

  for _, s in ipairs(components.node_version()) do
    table.insert(segments, s)
  end

  for _, s in ipairs(components.rust_version()) do
    table.insert(segments, s)
  end

  for _, s in ipairs(components.go_version()) do
    table.insert(segments, s)
  end

  -- Container / orchestration
  for _, s in ipairs(components.docker_context()) do
    table.insert(segments, s)
  end

  for _, s in ipairs(components.k8s_context()) do
    table.insert(segments, s)
  end

  -- CPU usage
  local cpu = get_cpu_usage()
  if cpu then
    local fg = colors.palette.green
    if cpu > 80 then
      fg = colors.palette.red
    elseif cpu > 50 then
      fg = colors.palette.yellow
    end
    for _, s in ipairs(segment('CPU: ' .. cpu .. '%', fg, colors.palette.surface0)) do
      table.insert(segments, s)
    end
  end

  -- Memory usage
  local mem = get_memory_usage()
  if mem then
    local fg = colors.palette.green
    if mem > 80 then
      fg = colors.palette.red
    elseif mem > 50 then
      fg = colors.palette.yellow
    end
    for _, s in ipairs(segment('RAM: ' .. mem .. '%', fg, colors.palette.surface0)) do
      table.insert(segments, s)
    end
  end

  -- Battery
  for _, s in ipairs(components.battery()) do
    table.insert(segments, s)
  end

  -- Workspace
  for _, s in ipairs(components.workspace()) do
    table.insert(segments, s)
  end

  -- Domain (SSH, etc.)
  local domain_segments = components.domain(pane)
  for _, s in ipairs(domain_segments) do
    table.insert(segments, s)
  end

  -- Hostname (only when connected via SSH)
  if #domain_segments > 0 then
    local domain_name = pane:get_domain_name() or ''
    if domain_name:lower():find('ssh') then
      for _, s in ipairs(components.hostname()) do
        table.insert(segments, s)
      end
    end
  end

  window:set_right_status(wezterm.format(segments))
end

-- Setup -------------------------------------------------------------------

function M.setup()
  wezterm.on('update-right-status', function(window, pane)
    build_right_status(window, pane)
  end)

  wezterm.on('update-left-status', function(window, pane)
    build_left_status(window, pane)
  end)
end

return M
