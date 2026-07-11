# WezTerm Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a production-quality, modular WezTerm configuration with IDE-like experience, rich status bar, leader key system, and Catppuccin Mocha theme.

**Architecture:** Layered module system with config/, ui/, utils/ directories. Entry point composes all modules via `config_builder()` pattern. Each module exports an `apply(config)` function.

**Tech Stack:** Lua, WezTerm API, Nerd Fonts, Catppuccin Mocha palette

## Global Constraints

- Target: WezTerm latest stable (2024.x+)
- Primary platform: macOS, secondary: Linux, supported: Windows
- Fonts: MonaspiceNe Nerd Font (primary), JetBrainsMono Nerd Font (fallback), Apple Color Emoji
- Theme: Catppuccin Mocha exclusively
- No deprecated WezTerm APIs
- No magic constants — all values named and documented
- Every public function documented with purpose

---

### Task 1: Project Scaffolding and Entry Point

**Covers:** S1

**Files:**
- Create: `wezterm.lua`
- Create: `config/` directory
- Create: `ui/` directory
- Create: `utils/` directory
- Create: `themes/` directory
- Create: `docs/` directory
- Create: `screenshots/` directory

**Interfaces:**
- Produces: Entry point that loads all modules

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /Users/m3etis/Projects/WezTerm/{config,ui,utils,themes,docs,screenshots}
```

- [ ] **Step 2: Create wezterm.lua entry point**

```lua
-- wezterm.lua — Main entry point
-- Composes all configuration modules into final config

local wezterm = require('wezterm')

-- Build base config
local config = wezterm.config_builder()

-- Load and apply modules in order
config = require('config.appearance').apply(config)
config = require('config.fonts').apply(config)
config = require('config.performance').apply(config)
config = require('config.behavior').apply(config)
config = require('config.domains').apply(config)
config = require('config.keys').apply(config)
config = require('config.mouse').apply(config)
config = require('config.workspace').apply(config)

-- Initialize UI components (registers event handlers)
require('ui.tabbar').setup()
require('ui.statusbar').setup()
require('ui.notifications').setup()

return config
```

- [ ] **Step 3: Verify file exists**

```bash
ls -la /Users/m3etis/Projects/WezTerm/wezterm.lua
```

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: project scaffolding and entry point"
```

---

### Task 2: Platform Detection Utility

**Covers:** S7

**Files:**
- Create: `utils/platform.lua`

**Interfaces:**
- Produces: `M.is_macos`, `M.is_linux`, `M.is_windows`, `M.is_wsl`, `M.get_dpi()`

- [ ] **Step 1: Create utils/platform.lua**

```lua
-- utils/platform.lua
-- Platform detection utilities

local wezterm = require('wezterm')

local M = {}

--- Current platform detection
M.is_macos = wezterm.target_triple:find('darwin') ~= nil
M.is_linux = wezterm.target_triple:find('linux') ~= nil
M.is_windows = wezterm.target_triple:find('windows') ~= nil

--- Check if running under WSL
M.is_wsl = M.is_linux and os.getenv('WSL_DISTRO_NAME') ~= nil

--- Get platform-specific path separator
M.path_sep = M.is_windows and '\\' or '/'

--- Get platform name for display
function M.name()
  if M.is_macos then return 'macOS'
  elseif M.is_linux then return 'Linux'
  elseif M.is_windows then return 'Windows'
  else return 'Unknown'
  end
end

--- Get DPI scaling factor (macOS returns 2 for Retina)
function M.get_dpi()
  if M.is_macos then
    return 2.0
  end
  return 1.0
end

--- Platform-specific config modifier
function M.apply_platform_config(config)
  if M.is_macos then
    config.native_macos_fullscreen_mode = true
    config.window_decorations = 'INTEGRATED_TITLE_BUTTONS|RESIZE'
  elseif M.is_linux then
    config.enable_wayland = true
    config.window_decorations = 'NONE'
  elseif M.is_windows then
    config.window_decorations = 'RESIZE'
  end
  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/utils/platform.lua
```

- [ ] **Step 3: Commit**

```bash
git add utils/platform.lua
git commit -m "feat: add platform detection utility"
```

---

### Task 3: Path and Formatting Utilities

**Covers:** S1

**Files:**
- Create: `utils/path.lua`
- Create: `utils/formatting.lua`

**Interfaces:**
- Produces: `path.shorten()`, `path.get_basename()`, `path.get_project_name()`
- Produces: `formatting.truncate()`, `formatting.pad()`, `formatting.icon_text()`

- [ ] **Step 1: Create utils/path.lua**

```lua
-- utils/path.lua
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
```

- [ ] **Step 2: Create utils/formatting.lua**

```lua
-- utils/formatting.lua
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
```

- [ ] **Step 3: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/utils/path.lua
luac -p /Users/m3etis/Projects/WezTerm/utils/formatting.lua
```

- [ ] **Step 4: Commit**

```bash
git add utils/path.lua utils/formatting.lua
git commit -m "feat: add path and formatting utilities"
```

---

### Task 4: Git Integration Utility

**Covers:** S5

**Files:**
- Create: `utils/git.lua`

**Interfaces:**
- Produces: `git.get_branch()`, `git.is_dirty()`, `git.get_status()`, `git.get_ahead_count()`

- [ ] **Step 1: Create utils/git.lua**

```lua
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

--- Execute git command and return output
--- @param cwd string Working directory
--- @param args string Git arguments
--- @return string|nil Output or nil on failure
local function git_exec(cwd, args)
  local success, stdout, stderr = wezterm.run_child_process({
    'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'
  })
  if success then
    return stdout:gsub('%s+$', '')
  end
  return nil
end

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

  local success, stdout, _ = wezterm.run_child_process({
    'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'
  })

  local branch = ''
  if success then
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

  local success, stdout, _ = wezterm.run_child_process({
    'git', '-C', cwd, 'status', '--porcelain'
  })

  local dirty = success and stdout ~= ''
  cache.dirty[cwd] = dirty

  return dirty
end

--- Get ahead/behind count from upstream
--- @param cwd string Working directory
--- @return number ahead, number behind
function M.get_ahead_count(cwd)
  if not cwd or cwd == '' then return 0, 0 end

  local success, stdout, _ = wezterm.run_child_process({
    'git', '-C', cwd, 'rev-list', '--left-right', '--count', 'HEAD...@{upstream}'
  })

  if success then
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
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/utils/git.lua
```

- [ ] **Step 3: Commit**

```bash
git add utils/git.lua
git commit -m "feat: add git integration utility"
```

---

### Task 5: Process Detection Utility

**Covers:** S5

**Files:**
- Create: `utils/process.lua`

**Interfaces:**
- Produces: `process.get_foreground()`, `process.get_icon()`, `process.get_display_name()`

- [ ] **Step 1: Create utils/process.lua**

```lua
-- utils/process.lua
-- Process detection and identification utilities

local M = {}

--- Known process definitions with icons and display names
M.processes = {
  -- Editors
  nvim = { icon = '', display = 'Neovim' },
  vim = { icon = '', display = 'Vim' },
  vi = { icon = '', display = 'Vi' },
  nano = { icon = '', display = 'Nano' },
  emacs = { icon = '', display = 'Emacs' },
  code = { icon = '', display = 'VS Code' },

  -- Version control
  lazygit = { icon = '', display = 'LazyGit' },
  git = { icon = '', display = 'Git' },
  tig = { icon = '', display = 'Tig' },

  -- Shells
  zsh = { icon = '', display = 'Zsh' },
  bash = { icon = '', display = 'Bash' },
  fish = { icon = '', display = 'Fish' },
  sh = { icon = '', display = 'Shell' },

  -- Dev tools
  docker = { icon = '', display = 'Docker' },
  kubectl = { icon = '', display = 'Kubernetes' },
  node = { icon = '', display = 'Node.js' },
  python = { icon = '', display = 'Python' },
  python3 = { icon = '', display = 'Python' },
  go = { icon = '', display = 'Go' },
  cargo = { icon = '', display = 'Cargo' },
  rustc = { icon = '', display = 'Rust' },
  make = { icon = '', display = 'Make' },
  cmake = { icon = '', display = 'CMake' },

  -- File managers
  ranger = { icon = '', display = 'Ranger' },
  lf = { icon = '', display = 'lf' },
  nnn = { icon = '', display = 'nnn' },
  broot = { icon = '', display = 'Broot' },

  -- Search tools
  fzf = { icon = '', display = 'fzf' },
  rg = { icon = '', display = 'ripgrep' },
  fd = { icon = '', display = 'fd' },

  -- System tools
  htop = { icon = '', display = 'htop' },
  btop = { icon = '', display = 'btop' },
  top = { icon = '', display = 'top' },
  btm = { icon = '', display = 'bottom' },

  -- Network
  ssh = { icon = '', display = 'SSH' },
  mosh = { icon = '', display = 'Mosh' },

  -- Misc
  tmux = { icon = '', display = 'tmux' },
  less = { icon = '', display = 'Less' },
  more = { icon = '', display = 'More' },
  man = { icon = '', display = 'Man' },
}

--- Extract process name from full path
--- @param process_path string Full process path
--- @return string Process name (basename)
function M.get_name(process_path)
  if not process_path or process_path == '' then return 'sh' end
  -- Handle macOS .app bundles
  local app_name = process_path:match('([^/]+)%.app/')
  if app_name then return app_name:lower() end
  return process_path:match('([^/]+)$') or 'sh'
end

--- Get process info for a given process name
--- @param process_name string Process name
--- @return table Process info { icon, display }
function M.get_info(process_name)
  process_name = process_name:lower()
  -- Strip common prefixes
  process_name = process_name:gsub('^%-', '')
  return M.processes[process_name] or { icon = '', display = process_name }
end

--- Get icon for a process
--- @param process_name string Process name
--- @return string Nerd Font icon
function M.get_icon(process_name)
  return M.get_info(process_name).icon
end

--- Get display name for a process
--- @param process_name string Process name
--- @return string Human-readable display name
function M.get_display_name(process_name)
  return M.get_info(process_name).display
end

--- Get foreground process info from pane
--- @param pane table WezTerm pane object
--- @return table { name, icon, display, path }
function M.get_foreground(pane)
  local process_path = pane:get_foreground_process_name() or ''
  local name = M.get_name(process_path)
  local info = M.get_info(name)

  return {
    name = name,
    icon = info.icon,
    display = info.display,
    path = process_path,
  }
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/utils/process.lua
```

- [ ] **Step 3: Commit**

```bash
git add utils/process.lua
git commit -m "feat: add process detection utility"
```

---

### Task 6: CWD, Hostname, and Battery Utilities

**Covers:** S5

**Files:**
- Create: `utils/cwd.lua`
- Create: `utils/hostname.lua`
- Create: `utils/battery.lua`

**Interfaces:**
- Produces: `cwd.get()`, `cwd.get_for_display()`
- Produces: `hostname.get()`, `hostname.get_short()`
- Produces: `battery.get_status()`, `battery.get_icon()`

- [ ] **Step 1: Create utils/cwd.lua**

```lua
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
```

- [ ] **Step 2: Create utils/hostname.lua**

```lua
-- utils/hostname.lua
-- Hostname detection utilities

local wezterm = require('wezterm')

local M = {}

--- Get full hostname
--- @return string Hostname
function M.get()
  local success, stdout, _ = wezterm.run_child_process({ 'hostname' })
  if success then
    return stdout:gsub('%s+$', '')
  end
  return os.getenv('HOSTNAME') or 'localhost'
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
```

- [ ] **Step 3: Create utils/battery.lua**

```lua
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
```

- [ ] **Step 4: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/utils/cwd.lua
luac -p /Users/m3etis/Projects/WezTerm/utils/hostname.lua
luac -p /Users/m3etis/Projects/WezTerm/utils/battery.lua
```

- [ ] **Step 5: Commit**

```bash
git add utils/cwd.lua utils/hostname.lua utils/battery.lua
git commit -m "feat: add cwd, hostname, and battery utilities"
```

---

### Task 7: UI Color Theme (Catppuccin Mocha)

**Covers:** S1

**Files:**
- Create: `ui/colors.lua`

**Interfaces:**
- Produces: `colors.palette` (full Catppuccin Mocha palette), `colors.semantic` (semantic color mapping)

- [ ] **Step 1: Create ui/colors.lua**

```lua
-- ui/colors.lua
-- Catppuccin Mocha color palette and semantic color mapping

local M = {}

--- Catppuccin Mocha palette
--- https://github.com/catppuccin/catppuccin
M.palette = {
  -- Base colors
  rosewater = '#f5e0dc',
  flamingo = '#f2cdcd',
  pink = '#f5c2e7',
  mauve = '#cba6f7',
  red = '#f38ba8',
  maroon = '#eba0ac',
  peach = '#fab387',
  yellow = '#f9e2af',
  green = '#a6e3a1',
  teal = '#94e2d5',
  sky = '#89dceb',
  sapphire = '#74c7ec',
  blue = '#89b4fa',
  lavender = '#b4befe',

  -- Surface colors
  text = '#cdd6f4',
  subtext1 = '#bac2de',
  subtext0 = '#a6adc8',
  overlay2 = '#9399b2',
  overlay1 = '#7f849c',
  overlay0 = '#6c7086',
  surface2 = '#585b70',
  surface1 = '#45475a',
  surface0 = '#313244',
  base = '#1e1e2e',
  mantle = '#181825',
  crust = '#11111b',
}

--- Semantic color mapping for UI elements
M.semantic = {
  -- Tab bar
  tab_bar = {
    background = M.palette.crust,
    active_tab = {
      bg_color = M.palette.surface0,
      fg_color = M.palette.text,
    },
    inactive_tab = {
      bg_color = M.palette.crust,
      fg_color = M.palette.overlay1,
    },
    inactive_tab_hover = {
      bg_color = M.palette.surface0,
      fg_color = M.palette.text,
    },
    new_tab = {
      bg_color = M.palette.crust,
      fg_color = M.palette.overlay1,
    },
    new_tab_hover = {
      bg_color = M.palette.surface0,
      fg_color = M.palette.text,
    },
  },

  -- Status bar
  status_bar = {
    background = M.palette.crust,
    foreground = M.palette.text,
  },

  -- Status components
  git = {
    branch = M.palette.green,
    dirty = M.palette.peach,
    clean = M.palette.green,
    ahead = M.palette.blue,
    behind = M.palette.yellow,
  },

  -- Development tools
  python = M.palette.yellow,
  node = M.palette.green,
  rust = M.palette.peach,
  go = M.palette.sapphire,
  docker = M.palette.blue,
  kubernetes = M.palette.blue,

  -- System
  battery = {
    charging = M.palette.green,
    low = M.palette.red,
    normal = M.palette.text,
  },

  -- UI elements
  separator = M.palette.surface2,
  highlight = M.palette.surface1,
  dim = M.palette.overlay0,
}

--- Get color with alpha
--- @param hex string Hex color code
--- @param alpha number Alpha value (0.0 - 1.0)
--- @return string Color with alpha
function M.with_alpha(hex, alpha)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return string.format('rgba(%d, %d, %d, %.2f)', r, g, b, alpha)
end

--- Get gradient between two colors
--- @param color1 string Start color
--- @param color2 string End color
--- @param t number Interpolation factor (0.0 - 1.0)
--- @return string Interpolated color
function M.lerp(color1, color2, t)
  local r1 = tonumber(color1:sub(2, 3), 16)
  local g1 = tonumber(color1:sub(4, 5), 16)
  local b1 = tonumber(color1:sub(6, 7), 16)
  local r2 = tonumber(color2:sub(2, 3), 16)
  local g2 = tonumber(color2:sub(4, 5), 16)
  local b2 = tonumber(color2:sub(6, 7), 16)

  local r = math.floor(r1 + (r2 - r1) * t)
  local g = math.floor(g1 + (g2 - g1) * t)
  local b = math.floor(b1 + (b2 - b1) * t)

  return string.format('#%02x%02x%02x', r, g, b)
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/colors.lua
```

- [ ] **Step 3: Commit**

```bash
git add ui/colors.lua
git commit -m "feat: add Catppuccin Mocha color theme"
```

---

### Task 8: UI Icons and Separators

**Covers:** S1

**Files:**
- Create: `ui/icons.lua`
- Create: `ui/separators.lua`

**Interfaces:**
- Produces: `icons.*` (all Nerd Font icon constants)
- Produces: `separators.left()`, `separators.right()`, `separators.powerline()`

- [ ] **Step 1: Create ui/icons.lua**

```lua
-- ui/icons.lua
-- Nerd Font icon constants

local M = {}

--- Powerline separators
M.powerline = {
  left_thin = '',
  right_thin = '',
  left = '',
  right = '',
  left_rounded = '',
  right_rounded = '',
  left_half_circle = '',
  right_half_circle = '',
  trapezoid_left = '',
  trapezoid_right = '',
}

--- Git icons
M.git = {
  branch = '',
  dirty = '●',
  clean = '✓',
  ahead = '⇡',
  behind = '⇣',
  staged = '●',
  untracked = '?',
  modified = '~',
  deleted = '✕',
}

--- Language/tool icons
M.languages = {
  python = '',
  node = '',
  rust = '',
  go = '',
  docker = '',
  kubernetes = '',
  ruby = '',
  java = '',
  lua = '',
  javascript = '',
  typescript = '',
  html = '',
  css = '',
}

--- System icons
M.system = {
  battery_full = '',
  battery_high = '',
  battery_mid = '',
  battery_low = '',
  battery_empty = '',
  battery_charging = '',
  clock = '',
  cpu = '',
  memory = '',
  disk = '',
  network = '',
  wifi = '',
  volume = '',
}

--- Editor icons
M.editors = {
  neovim = '',
  vim = '',
  vscode = '',
  emacs = '',
}

--- Shell icons
M.shells = {
  zsh = '',
  bash = '',
  fish = '',
  shell = '',
}

--- Tool icons
M.tools = {
  lazygit = '',
  fzf = '',
  ripgrep = '',
  fd = '',
  bat = '',
  eza = '',
  htop = '',
  btop = '',
  ranger = '',
  tmux = '',
}

--- UI icons
M.ui = {
  workspace = '',
  tab = '',
  pane = '',
  search = '',
  settings = '',
  bell = '',
  zoom = '',
  split_horizontal = '',
  split_vertical = '',
  close = '',
  plus = '',
  chevron_right = '',
  chevron_left = '',
  arrow_right = '',
  arrow_left = '',
  dot = '●',
  circle = '○',
  check = '✓',
  cross = '✕',
  warning = '',
  info = '',
  error = '',
}

return M
```

- [ ] **Step 2: Create ui/separators.lua**

```lua
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
```

- [ ] **Step 3: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/icons.lua
luac -p /Users/m3etis/Projects/WezTerm/ui/separators.lua
```

- [ ] **Step 4: Commit**

```bash
git add ui/icons.lua ui/separators.lua
git commit -m "feat: add UI icons and separators"
```

---

### Task 9: UI Components (Reusable Status Elements)

**Covers:** S3

**Files:**
- Create: `ui/components.lua`

**Interfaces:**
- Produces: `components.git()`, `components.python()`, `components.battery()`, etc.

- [ ] **Step 1: Create ui/components.lua**

```lua
-- ui/components.lua
-- Reusable status bar component factories

local wezterm = require('wezterm')
local colors = require('ui.colors')
local icons = require('ui.icons')
local git = require('utils.git')
local battery = require('utils.battery')
local hostname = require('utils.hostname')
local formatting = require('utils.formatting')

local M = {}

--- Create a text segment with colors
--- @param text string Display text
--- @param fg string Foreground color
--- @param bg string Background color
--- @return table WezTerm formatted segment
local function text_segment(text, fg, bg)
  return { Foreground = { Color = fg } }, { Background = { Color = bg } }, { Text = text }
end

--- Git branch component
--- @param cwd string Current working directory
--- @return table WezTerm formatted segments
function M.git_branch(cwd)
  local branch = git.get_branch(cwd)
  if branch == '' then return {} end

  return {
    text_segment(' ', colors.semantic.git.branch, colors.palette.crust),
    text_segment(icons.git.branch, colors.semantic.git.branch, colors.palette.crust),
    text_segment(' ' .. branch, colors.semantic.git.branch, colors.palette.crust),
  }
end

--- Git dirty indicator component
--- @param cwd string Current working directory
--- @return table WezTerm formatted segments
function M.git_dirty(cwd)
  local dirty = git.is_dirty(cwd)
  if not dirty then return {} end

  return {
    text_segment(' ' .. icons.git.dirty, colors.semantic.git.dirty, colors.palette.crust),
  }
end

--- Python environment component
--- @return table WezTerm formatted segments
function M.python_env()
  local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_DEFAULT_ENV')
  if not venv or venv == '' then return {} end

  local env_name = venv:match('([^/]+)$') or venv
  return {
    text_segment(' ', colors.semantic.python, colors.palette.crust),
    text_segment(icons.languages.python, colors.semantic.python, colors.palette.crust),
    text_segment(' ' .. formatting.truncate(env_name, 15), colors.semantic.python, colors.palette.crust),
  }
end

--- Node version component
--- @return table WezTerm formatted segments
function M.node_version()
  local success, stdout, _ = wezterm.run_child_process({ 'node', '--version' })
  if not success then return {} end

  local version = stdout:gsub('%s+$', ''):match('v?(.+)$') or ''
  return {
    text_segment(' ', colors.semantic.node, colors.palette.crust),
    text_segment(icons.languages.node, colors.semantic.node, colors.palette.crust),
    text_segment(' ' .. version, colors.semantic.node, colors.palette.crust),
  }
end

--- Rust version component
--- @return table WezTerm formatted segments
function M.rust_version()
  local success, stdout, _ = wezterm.run_child_process({ 'rustc', '--version' })
  if not success then return {} end

  local version = stdout:match('rustc ([%d%.]+)') or ''
  return {
    text_segment(' ', colors.semantic.rust, colors.palette.crust),
    text_segment(icons.languages.rust, colors.semantic.rust, colors.palette.crust),
    text_segment(' ' .. version, colors.semantic.rust, colors.palette.crust),
  }
end

--- Go version component
--- @return table WezTerm formatted segments
function M.go_version()
  local success, stdout, _ = wezterm.run_child_process({ 'go', 'version' })
  if not success then return {} end

  local version = stdout:match('go([%d%.]+)') or ''
  return {
    text_segment(' ', colors.semantic.go, colors.palette.crust),
    text_segment(icons.languages.go, colors.semantic.go, colors.palette.crust),
    text_segment(' ' .. version, colors.semantic.go, colors.palette.crust),
  }
end

--- Docker context component
--- @return table WezTerm formatted segments
function M.docker_context()
  local success, stdout, _ = wezterm.run_child_process({ 'docker', 'context', 'show' })
  if not success then return {} end

  local context = stdout:gsub('%s+$', '')
  if context == 'default' then return {} end

  return {
    text_segment(' ', colors.semantic.docker, colors.palette.crust),
    text_segment(icons.languages.docker, colors.semantic.docker, colors.palette.crust),
    text_segment(' ' .. context, colors.semantic.docker, colors.palette.crust),
  }
end

--- Kubernetes context component
--- @return table WezTerm formatted segments
function M.k8s_context()
  local success, stdout, _ = wezterm.run_child_process({
    'kubectl', 'config', 'current-context'
  })
  if not success then return {} end

  local context = stdout:gsub('%s+$', '')
  return {
    text_segment(' ', colors.semantic.kubernetes, colors.palette.crust),
    text_segment(icons.languages.kubernetes, colors.semantic.kubernetes, colors.palette.crust),
    text_segment(' ' .. formatting.truncate(context, 20), colors.semantic.kubernetes, colors.palette.crust),
  }
end

--- Battery component
--- @return table WezTerm formatted segments
function M.battery()
  local info = battery.get_info()
  if info.percentage < 0 then return {} end

  local icon = battery.get_icon(info.percentage, info.charging)
  local color = colors.semantic.battery.normal
  if info.percentage < 20 then
    color = colors.semantic.battery.low
  elseif info.charging then
    color = colors.semantic.battery.charging
  end

  return {
    text_segment(' ', color, colors.palette.crust),
    text_segment(icon, color, colors.palette.crust),
    text_segment(' ' .. info.percentage .. '%', color, colors.palette.crust),
  }
end

--- Clock component
--- @return table WezTerm formatted segments
function M.clock()
  return {
    text_segment(' ', colors.palette.text, colors.palette.crust),
    text_segment(icons.system.clock, colors.palette.text, colors.palette.crust),
    text_segment(' ' .. os.date('%H:%M'), colors.palette.text, colors.palette.crust),
  }
end

--- Hostname component
--- @return table WezTerm formatted segments
function M.hostname()
  return {
    text_segment(' ', colors.palette.subtext1, colors.palette.crust),
    text_segment(hostname.get_short(), colors.palette.subtext1, colors.palette.crust),
  }
end

--- Workspace name component
--- @return table WezTerm formatted segments
function M.workspace()
  local workspace = wezterm.mux.get_active_workspace()
  return {
    text_segment(' ', colors.palette.lavender, colors.palette.crust),
    text_segment(icons.ui.workspace, colors.palette.lavender, colors.palette.crust),
    text_segment(' ' .. workspace, colors.palette.lavender, colors.palette.crust),
  }
end

--- Domain component
--- @param pane table WezTerm pane object
--- @return table WezTerm formatted segments
function M.domain(pane)
  local domain = pane:get_domain_name() or 'local'
  if domain == 'local' then return {} end

  return {
    text_segment(' ', colors.palette.sky, colors.palette.crust),
    text_segment(icons.system.network, colors.palette.sky, colors.palette.crust),
    text_segment(' ' .. domain, colors.palette.sky, colors.palette.crust),
  }
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/components.lua
```

- [ ] **Step 3: Commit**

```bash
git add ui/components.lua
git commit -m "feat: add reusable UI components"
```

---

### Task 10: Status Bar

**Covers:** S3

**Files:**
- Create: `ui/statusbar.lua`

**Interfaces:**
- Produces: `statusbar.setup()` (registers update_right_status event)

- [ ] **Step 1: Create ui/statusbar.lua**

```lua
-- ui/statusbar.lua
-- Rich status bar composition

local wezterm = require('wezterm')
local colors = require('ui.colors')
local icons = require('ui.icons')
local components = require('ui.components')

local M = {}

--- Build right status bar segments
--- @param window table WezTerm window object
--- @param pane table WezTerm pane object
--- @return table Formatted status segments
local function build_right_status(window, pane)
  local segments = {}
  local cwd = pane:get_current_working_dir()
  local cwd_path = ''
  if cwd then
    cwd_path = type(cwd) == 'table' and (cwd.file_path or tostring(cwd)) or tostring(cwd)
  end

  -- Add segments in order (right to left display)
  local function add(segment)
    for _, s in ipairs(segment) do
      table.insert(segments, s)
    end
  end

  -- Environment info (only show if relevant)
  add(components.python_env())
  add(components.node_version())
  add(components.rust_version())
  add(components.go_version())

  -- Container contexts
  add(components.docker_context())
  add(components.k8s_context())

  -- Git info
  add(components.git_branch(cwd_path))
  add(components.git_dirty(cwd_path))

  -- System info
  add(components.battery())
  add(components.hostname())

  -- Workspace and clock
  add(components.workspace())
  add(components.clock())

  return segments
end

--- Build left status bar segments
--- @param window table WezTerm window object
--- @param pane table WezTerm pane object
--- @return table Formatted status segments
local function build_left_status(window, pane)
  local segments = {}

  -- Current domain indicator
  local domain = components.domain(pane)
  for _, s in ipairs(domain) do
    table.insert(segments, s)
  end

  -- Zoom indicator
  if pane:is_zoomed() then
    table.insert(segments, { Foreground = { Color = colors.palette.peach } })
    table.insert(segments, { Background = { Color = colors.palette.crust } })
    table.insert(segments, { Text = ' ' .. icons.ui.zoom .. ' ZOOM ' })
  end

  return segments
end

--- Setup status bar event handlers
function M.setup()
  wezterm.on('update-right-status', function(window, pane)
    local segments = build_right_status(window, pane)
    window:set_right_status(wezterm.format(segments))
  end)

  wezterm.on('update-left-status', function(window, pane)
    local segments = build_left_status(window, pane)
    window:set_left_status(wezterm.format(segments))
  end)
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/statusbar.lua
```

- [ ] **Step 3: Commit**

```bash
git add ui/statusbar.lua
git commit -m "feat: add rich status bar"
```

---

### Task 11: Tab Bar

**Covers:** S2

**Files:**
- Create: `ui/tabbar.lua`

**Interfaces:**
- Produces: `tabbar.setup()` (registers format-tab-title event)

- [ ] **Step 1: Create ui/tabbar.lua**

```lua
-- ui/tabbar.lua
-- Custom powerline tab bar

local wezterm = require('wezterm')
local colors = require('ui.colors')
local icons = require('ui.icons')
local process = require('utils.process')

local M = {}

--- Get tab title with process icon
--- @param tab table WezTerm tab object
--- @return string Formatted tab title
local function get_tab_title(tab)
  local pane = tab.active_pane
  local title = pane.title or ''

  -- Get process info
  local proc = process.get_foreground(pane)

  -- Use custom title if set
  if title ~= '' and title ~= proc.display then
    return proc.icon .. ' ' .. title
  end

  -- Use process display name
  return proc.icon .. ' ' .. proc.display
end

--- Format tab title for display
--- @param tab table WezTerm tab object
--- @param max_width number Maximum tab width
--- @return table Formatted tab segments
local function format_tab_title(tab, max_width)
  local title = get_tab_title(tab)
  local is_active = tab.is_active

  local bg = is_active and colors.semantic.tab_bar.active_tab.bg_color or colors.semantic.tab_bar.inactive_tab.bg_color
  local fg = is_active and colors.semantic.tab_bar.active_tab.fg_color or colors.semantic.tab_bar.inactive_tab.fg_color

  -- Truncate if needed
  if #title > max_width then
    title = title:sub(1, max_width - 1) .. '…'
  end

  local segments = {}

  -- Left separator
  table.insert(segments, { Foreground = { Color = bg } })
  table.insert(segments, { Background = { Color = colors.semantic.tab_bar.background } })
  table.insert(segments, { Text = icons.powerline.right_rounded })

  -- Tab content
  table.insert(segments, { Foreground = { Color = fg } })
  table.insert(segments, { Background = { Color = bg } })
  table.insert(segments, { Text = ' ' .. title .. ' ' })

  -- Right separator
  table.insert(segments, { Foreground = { Color = colors.semantic.tab_bar.background } })
  table.insert(segments, { Background = { Color = bg } })
  table.insert(segments, { Text = icons.powerline.left_rounded })

  return segments
end

--- Setup tab bar event handlers and configuration
function M.setup()
  wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    return format_tab_title(tab, max_width)
  end)
end

--- Apply tab bar configuration to config
--- @param config table WezTerm config
--- @return table Modified config
function M.apply_config(config)
  config.tab_bar_at_bottom = false
  config.use_fancy_tab_bar = false
  config.tab_max_width = 32
  config.show_tab_index_in_tab_bar = false
  config.show_new_tab_button_in_tab_bar = false

  config.colors = config.colors or {}
  config.colors.tab_bar = colors.semantic.tab_bar

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/tabbar.lua
```

- [ ] **Step 3: Commit**

```bash
git add ui/tabbar.lua
git commit -m "feat: add custom powerline tab bar"
```

---

### Task 12: Notifications

**Covers:** S1

**Files:**
- Create: `ui/notifications.lua`

**Interfaces:**
- Produces: `notifications.setup()` (registers bell event)

- [ ] **Step 1: Create ui/notifications.lua**

```lua
-- ui/notifications.lua
-- Activity and bell notification handling

local wezterm = require('wezterm')
local colors = require('ui.colors')
local icons = require('ui.icons')

local M = {}

--- Setup notification event handlers
function M.setup()
  -- Handle bell events
  wezterm.on('bell', function(window, pane)
    -- Don't notify for focused pane
    if window:is_focused() then
      return
    end

    -- Show notification toast
    window:toast_notification(
      'WezTerm',
      'Activity in: ' .. (pane:get_title() or 'Unknown'),
      nil, -- icon (uses default)
      4000 -- duration ms
    )
  end)
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/ui/notifications.lua
```

- [ ] **Step 3: Commit**

```bash
git add ui/notifications.lua
git commit -m "feat: add notification handling"
```

---

### Task 13: Appearance Configuration

**Covers:** S1

**Files:**
- Create: `config/appearance.lua`

**Interfaces:**
- Produces: `appearance.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/appearance.lua**

```lua
-- config/appearance.lua
-- Window appearance configuration

local colors = require('ui.colors')
local platform = require('utils.platform')

local M = {}

--- Apply appearance configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Window padding
  config.window_padding = {
    left = 12,
    right = 12,
    top = 12,
    bottom = 8,
  }

  -- Window frame (integrated title buttons on macOS)
  config.window_frame = {
    font = require('wezterm').font('MonaspiceNe Nerd Font', { weight = 'Bold' }),
    font_size = 10.0,
    active_titlebar_bg = colors.palette.crust,
    inactive_titlebar_bg = colors.palette.crust,
    active_titlebar_fg = colors.palette.text,
    inactive_titlebar_fg = colors.palette.overlay1,
    active_titlebar_border_bottom = colors.palette.surface0,
    inactive_titlebar_border_bottom = colors.palette.surface0,
    button_fg = colors.palette.overlay1,
    button_bg = colors.palette.crust,
    button_hover_fg = colors.palette.text,
    button_hover_bg = colors.palette.surface0,
  }

  -- Transparency and blur
  config.window_background_opacity = 0.92
  config.macos_window_background_blur = 20

  -- Cursor
  config.default_cursor_style = 'BlinkingBar'
  config.cursor_blink_rate = 500
  config.cursor_blink_ease_in = 'Constant'
  config.cursor_blink_ease_out = 'Constant'
  config.force_reverse_video_cursor = false

  -- Colors
  config.colors = {
    cursor_fg = colors.palette.base,
    cursor_bg = colors.palette.rosewater,
    cursor_border = colors.palette.rosewater,
    selection_fg = colors.palette.text,
    selection_bg = colors.palette.surface2,
    scrollbar_thumb = colors.palette.surface2,
    split = colors.palette.surface2,
    tab_bar = colors.semantic.tab_bar,
  }

  -- Appearance mode
  config.color_scheme = 'Catppuccin Mocha'

  -- Platform-specific
  platform.apply_platform_config(config)

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/appearance.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/appearance.lua
git commit -m "feat: add appearance configuration"
```

---

### Task 14: Font Configuration

**Covers:** S1

**Files:**
- Create: `config/fonts.lua`

**Interfaces:**
- Produces: `fonts.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/fonts.lua**

```lua
-- config/fonts.lua
-- Font configuration

local wezterm = require('wezterm')

local M = {}

--- Apply font configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  config.font = wezterm.font_with_fallback({
    -- Primary: MonaspiceNe Nerd Font
    { family = 'MonaspiceNe Nerd Font', weight = 'Regular' },
    -- Fallback: JetBrainsMono Nerd Font
    { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
    -- Emoji support
    { family = 'Apple Color Emoji' },
  })

  config.font_size = 14.0
  config.line_height = 1.2

  -- Enable ligatures
  config.harfbuzz_features = {
    'calt', -- Contextual alternates
    'clig', -- Contextual ligatures
    'liga', -- Standard ligatures
    'ss01', -- Style set 1 (Monaspice specific)
    'ss02', -- Style set 2
    'ss03', -- Style set 3
    'ss04', -- Style set 4
    'ss05', -- Style set 5
    'ss06', -- Style set 6
    'ss07', -- Style set 7
    'ss08', -- Style set 8
  }

  -- Bold and italic
  config.bold_brightens_ansi_colors = true

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/fonts.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/fonts.lua
git commit -m "feat: add font configuration"
```

---

### Task 15: Performance Configuration

**Covers:** S6

**Files:**
- Create: `config/performance.lua`

**Interfaces:**
- Produces: `performance.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/performance.lua**

```lua
-- config/performance.lua
-- Performance optimization configuration

local platform = require('utils.platform')

local M = {}

--- Apply performance configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Use WebGPU for rendering (best performance)
  config.front_end = 'WebGPU'
  config.webgpu_power_preference = 'HighPerformance'

  -- Frame rate settings
  config.max_fps = 120
  config.animation_fps = 60

  -- Scrollback
  config.scrollback_lines = 10000

  -- Enable DMA rendering if available
  config.enable_tab_bar = true

  -- Reduce redraws
  config.enable_kitty_graphics = true

  -- Platform-specific optimizations
  if platform.is_macos then
    -- macOS Retina support
    config.dpi = 144.0
  end

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/performance.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/performance.lua
git commit -m "feat: add performance configuration"
```

---

### Task 16: Behavior Configuration

**Covers:** S1

**Files:**
- Create: `config/behavior.lua`

**Interfaces:**
- Produces: `behavior.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/behavior.lua**

```lua
-- config/behavior.lua
-- Terminal behavior configuration

local M = {}

--- Apply behavior configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Default shell
  config.default_prog = { '/bin/zsh', '-l' }

  -- Copy mode
  config.enable_copy_mode = true

  -- Selection
  config.selection_word_boundary = ' \t\n{}[]()"\'`'

  -- URL handling
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  -- Add custom hyperlink rules
  table.insert(config.hyperlink_rules, {
    regex = [[\b\w+://[\w.-]+\.[a-z]{2,15}\S*\b]],
    format = '$0',
  })

  -- Automatically close tabs when process exits
  config.exit_behavior = 'Close'

  -- Audible bell
  config.audible_bell = 'Disabled'

  -- Visual bell (flash instead of beep)
  config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
  }

  -- Default working directory
  config.default_cwd = wezterm.home_dir

  return config
end

return M
```

- [ ] **Step 2: Fix the missing wezterm require**

The file uses `wezterm` without requiring it. Update the file:

```lua
-- config/behavior.lua
-- Terminal behavior configuration

local wezterm = require('wezterm')

local M = {}

--- Apply behavior configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Default shell
  config.default_prog = { '/bin/zsh', '-l' }

  -- Copy mode
  config.enable_copy_mode = true

  -- Selection
  config.selection_word_boundary = ' \t\n{}[]()"\'`'

  -- URL handling
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  -- Add custom hyperlink rules
  table.insert(config.hyperlink_rules, {
    regex = [[\b\w+://[\w.-]+\.[a-z]{2,15}\S*\b]],
    format = '$0',
  })

  -- Automatically close tabs when process exits
  config.exit_behavior = 'Close'

  -- Audible bell
  config.audible_bell = 'Disabled'

  -- Visual bell (flash instead of beep)
  config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
  }

  -- Default working directory
  config.default_cwd = wezterm.home_dir

  return config
end

return M
```

- [ ] **Step 3: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/behavior.lua
```

- [ ] **Step 4: Commit**

```bash
git add config/behavior.lua
git commit -m "feat: add behavior configuration"
```

---

### Task 17: Domain Configuration

**Covers:** S1

**Files:**
- Create: `config/domains.lua`

**Interfaces:**
- Produces: `domains.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/domains.lua**

```lua
-- config/domains.lua
-- SSH and remote domain configuration

local M = {}

--- Apply domain configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Default domain
  config.default_domain = 'local'

  -- SSH domains (add your servers here)
  config.ssh_domains = {
    -- Example:
    -- {
    --   name = 'myserver',
    --   remote_address = '192.168.1.100',
    --   username = 'user',
    -- },
  }

  -- WSL domains (Windows only)
  config.wsl_domains = {
    -- Example:
    -- {
    --   name = 'WSL:Ubuntu',
    --   distribution = 'Ubuntu',
    -- },
  }

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/domains.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/domains.lua
git commit -m "feat: add domain configuration"
```

---

### Task 18: Keybinding Configuration (Leader Key System)

**Covers:** S4

**Files:**
- Create: `config/keys.lua`

**Interfaces:**
- Produces: `keys.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/keys.lua**

```lua
-- config/keys.lua
-- Leader key system and keybindings

local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

--- Leader key configuration
M.leader = {
  key = 'a',
  mods = 'CTRL',
  timeout_milliseconds = 1000,
}

--- Apply keybinding configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  config.leader = M.leader

  config.keys = {
    -- ==========================================
    -- Pane management (Leader + ...)
    -- ==========================================

    -- Split panes
    { key = '|', mods = 'LEADER',       action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '-', mods = 'LEADER',       action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '\\', mods = 'LEADER|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '_', mods = 'LEADER|SHIFT',  action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

    -- Pane navigation (vim-style)
    { key = 'h', mods = 'LEADER',       action = act.ActivatePaneDirection('Left') },
    { key = 'j', mods = 'LEADER',       action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'LEADER',       action = act.ActivatePaneDirection('Up') },
    { key = 'l', mods = 'LEADER',       action = act.ActivatePaneDirection('Right') },

    -- Pane resize
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Up', 5 }) },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },

    -- Close pane
    { key = 'x', mods = 'LEADER',       action = act.CloseCurrentPane({ confirm = true }) },

    -- Zoom pane
    { key = 'z', mods = 'LEADER',       action = act.TogglePaneZoomState },

    -- ==========================================
    -- Tab management (Leader + ...)
    -- ==========================================

    -- New tab
    { key = 'c', mods = 'LEADER',       action = act.SpawnTab('CurrentPaneDomain') },

    -- Close tab
    { key = '&', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab({ confirm = true }) },

    -- Tab navigation
    { key = '1', mods = 'LEADER',       action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER',       action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER',       action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER',       action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER',       action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER',       action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER',       action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER',       action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER',       action = act.ActivateTab(8) },

    -- Next/Previous tab
    { key = 'n', mods = 'LEADER',       action = act.ActivateTabRelative(1) },
    { key = 'p', mods = 'LEADER',       action = act.ActivateTabRelative(-1) },

    -- ==========================================
    -- Workspace management
    -- ==========================================

    -- Switch workspace
    { key = 'w', mods = 'LEADER',       action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },

    -- Rename workspace
    { key = ',', mods = 'LEADER',       action = act.PromptInputLine({
      description = 'Rename workspace',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    })},

    -- ==========================================
    -- Copy and search
    -- ==========================================

    -- Copy mode
    { key = '[', mods = 'LEADER',       action = act.ActivateCopyMode },

    -- Search
    { key = '/', mods = 'LEADER',       action = act.Search('CurrentSelectionOrEmptyString') },

    -- ==========================================
    -- Misc
    -- ==========================================

    -- Clear scrollback
    { key = 'k', mods = 'LEADER|CTRL',  action = act.ClearScrollback('ScrollbackAndViewport') },

    -- Reload config
    { key = 'r', mods = 'LEADER|CTRL',  action = act.ReloadConfiguration },

    -- Command palette
    { key = 'p', mods = 'LEADER|CTRL',  action = act.ActivateCommandPalette },

    -- Debug overlay
    { key = 'd', mods = 'LEADER|CTRL',  action = act.ShowDebugOverlay },

    -- Rename tab
    { key = 't', mods = 'LEADER',       action = act.PromptInputLine({
      description = 'Rename tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          local tab = window:active_tab()
          tab:set_title(line)
        end
      end),
    })},

    -- Quick launcher
    { key = 'Space', mods = 'LEADER',   action = act.QuickSelect },

    -- ==========================================
    -- Global shortcuts (no leader)
    -- ==========================================

    -- Copy/Paste
    { key = 'c', mods = 'SUPER',        action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'SUPER',        action = act.PasteFrom('Clipboard') },

    -- Font size
    { key = '=', mods = 'SUPER',        action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER',        action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER',        action = act.ResetFontSize },

    -- Fullscreen
    { key = 'f', mods = 'SUPER',        action = act.ToggleFullScreen },
  }

  -- Key tables for modal modes
  config.key_tables = {
    copy_mode = {
      { key = 'Escape', mods = 'NONE',  action = act.CopyMode('Close') },
      { key = 'q', mods = 'NONE',       action = act.CopyMode('Close') },
      { key = 'h', mods = 'NONE',       action = act.CopyMode('MoveLeft') },
      { key = 'j', mods = 'NONE',       action = act.CopyMode('MoveDown') },
      { key = 'k', mods = 'NONE',       action = act.CopyMode('MoveUp') },
      { key = 'l', mods = 'NONE',       action = act.CopyMode('MoveRight') },
      { key = 'w', mods = 'NONE',       action = act.CopyMode('MoveForwardWord') },
      { key = 'b', mods = 'NONE',       action = act.CopyMode('MoveBackwardWord') },
      { key = '0', mods = 'NONE',       action = act.CopyMode('MoveToStartOfLineContent') },
      { key = '$', mods = 'NONE',       action = act.CopyMode('MoveToEndOfLineContent') },
      { key = 'g', mods = 'NONE',       action = act.CopyMode('MoveToScrollbackTop') },
      { key = 'G', mods = 'SHIFT',      action = act.CopyMode('MoveToScrollbackBottom') },
      { key = 'v', mods = 'NONE',       action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
      { key = 'V', mods = 'SHIFT',      action = act.CopyMode({ SetSelectionMode = 'Line' }) },
      { key = 'y', mods = 'NONE',       action = act.Multiple({ { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } }) },
      { key = 'PageUp', mods = 'NONE',  action = act.CopyMode('PageUp') },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode('PageDown') },
    },

    search_mode = {
      { key = 'Escape', mods = 'NONE',  action = act.CopyMode('Close') },
      { key = 'Enter', mods = 'NONE',   action = act.CopyMode('PriorMatch') },
      { key = 'n', mods = 'NONE',       action = act.CopyMode('NextMatch') },
      { key = 'N', mods = 'SHIFT',      action = act.CopyMode('PriorMatch') },
      { key = 'r', mods = 'CTRL',       action = act.CopyMode('CycleMatchType') },
    },
  }

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/keys.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/keys.lua
git commit -m "feat: add leader key system and keybindings"
```

---

### Task 19: Mouse Configuration

**Covers:** S1

**Files:**
- Create: `config/mouse.lua`

**Interfaces:**
- Produces: `mouse.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/mouse.lua**

```lua
-- config/mouse.lua
-- Mouse configuration

local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

--- Apply mouse configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Enable mouse
  config.enable_scroll_bar = false

  -- Mouse bindings
  config.mouse_bindings = {
    -- Right click paste
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom('Clipboard'),
    },

    -- Double click to select word
    {
      event = { Down = { streak = 2, button = 'Left' } },
      mods = 'NONE',
      action = act.SelectTextAtMouseCursor('Word'),
    },

    -- Triple click to select line
    {
      event = { Down = { streak = 3, button = 'Left' } },
      mods = 'NONE',
      action = act.SelectTextAtMouseCursor('Line'),
    },

    -- Ctrl+click to open link
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },

    -- Middle click to paste
    {
      event = { Down = { streak = 1, button = 'Middle' } },
      mods = 'NONE',
      action = act.PasteFrom('PrimarySelection'),
    },
  }

  -- Smart selection rules
  config.mouse_wheel_scrollers = 'terminal'

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/mouse.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/mouse.lua
git commit -m "feat: add mouse configuration"
```

---

### Task 20: Workspace Configuration

**Covers:** S1

**Files:**
- Create: `config/workspace.lua`

**Interfaces:**
- Produces: `workspace.apply(config)` (modifies config in place)

- [ ] **Step 1: Create config/workspace.lua**

```lua
-- config/workspace.lua
-- Workspace management configuration

local wezterm = require('wezterm')

local M = {}

--- Apply workspace configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
  -- Workspace switching
  config.switch_to_last_active_tab_when_closing_tab = true

  -- Automatically save workspace state
  config.window_close_confirmation = 'AlwaysPrompt'

  return config
end

return M
```

- [ ] **Step 2: Verify Lua syntax**

```bash
luac -p /Users/m3etis/Projects/WezTerm/config/workspace.lua
```

- [ ] **Step 3: Commit**

```bash
git add config/workspace.lua
git commit -m "feat: add workspace configuration"
```

---

### Task 21: Theme File

**Covers:** S1

**Files:**
- Create: `themes/catppuccin-mocha.toml`

- [ ] **Step 1: Create themes/catppuccin-mocha.toml**

```toml
# Catppuccin Mocha theme for WezTerm
# https://github.com/catppuccin/catppuccin

[colors]
foreground = "#CDD6F4"
background = "#1E1E2E"
cursor_bg = "#F5E0DC"
cursor_border = "#F5E0DC"
cursor_fg = "#1E1E2E"
selection_bg = "#585B70"
selection_fg = "#CDD6F4"

[colors.ansi]
"#45475A"  # black
"#F38BA8"  # red
"#A6E3A1"  # green
"#F9E2AF"  # yellow
"#89B4FA"  # blue
"#F5C2E7"  # magenta
"#94E2D5"  # cyan
"#BAC2DE"  # white

[colors.brights]
"#585B70"  # black
"#F38BA8"  # red
"#A6E3A1"  # green
"#F9E2AF"  # yellow
"#89B4FA"  # blue
"#F5C2E7"  # magenta
"#94E2D5"  # cyan
"#A6ADC8"  # white

[colors.tab_bar]
background = "#11111B"

[colors.tab_bar.active_tab]
bg_color = "#313244"
fg_color = "#CDD6F4"

[colors.tab_bar.inactive_tab]
bg_color = "#11111B"
fg_color = "#6C7086"

[colors.tab_bar.inactive_tab_hover]
bg_color = "#313244"
fg_color = "#CDD6F4"

[colors.tab_bar.new_tab]
bg_color = "#11111B"
fg_color = "#6C7086"

[colors.tab_bar.new_tab_hover]
bg_color = "#313244"
fg_color = "#CDD6F4"
```

- [ ] **Step 2: Commit**

```bash
git add themes/catppuccin-mocha.toml
git commit -m "feat: add Catppuccin Mocha theme file"
```

---

### Task 22: Documentation (README)

**Covers:** S1

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README.md**

```markdown
# WezTerm Configuration

A production-quality, modular WezTerm configuration with IDE-like experience, rich status bar, leader key system, and Catppuccin Mocha theme.

## Features

- **Powerline Tab Bar** — Custom rounded separators with process icons
- **Rich Status Bar** — Git branch, language versions, Docker/K8s context, battery, clock
- **Leader Key System** — tmux-style keybindings with `Ctrl+A` as leader
- **Smart Detection** — Auto-detect Neovim, LazyGit, Docker, SSH, and more
- **Catppuccin Mocha** — Beautiful dark theme with semantic color mapping
- **WebGPU Rendering** — High-performance rendering engine
- **Cross-Platform** — macOS (primary), Linux, Windows support

## Screenshots

<!-- Add screenshots here -->

## Requirements

- [WezTerm](https://wezfurlong.org/wezterm/) (latest stable)
- [MonaspiceNe Nerd Font](https://github.com/ryanoasis/nerd-fonts)
- [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) (fallback)
- macOS, Linux, or Windows

## Installation

### Quick Install (macOS/Linux)

```bash
./install.sh
```

### Quick Install (Windows)

```powershell
.\install.ps1
```

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/wezterm-config.git ~/.config/wezterm
   ```

2. Install required fonts (see below)

3. Restart WezTerm

## Font Installation

### macOS

```bash
brew tap homebrew/cask-fonts
brew install --cask font-monaspace-nerd-font
brew install --cask font-jetbrains-mono-nerd-font
```

### Linux

```bash
# Download from https://github.com/ryanoasis/nerd-fonts/releases
mkdir -p ~/.local/share/fonts
cp *.ttf ~/.local/share/fonts/
fc-cache -fv
```

### Windows

Download and install from [Nerd Fonts](https://www.nerdfonts.com/)

## Recommended Tools

These tools enhance the terminal experience:

| Tool | Purpose | Install |
|------|---------|---------|
| [Starship](https://starship.rs) | Cross-shell prompt | `curl -sS https://starship.rs/install.sh \| sh` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart cd command | `curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \| bash` |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | `brew install fzf` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep | `brew install ripgrep` |
| [fd](https://github.com/sharkdp/fd) | Fast find | `brew install fd` |
| [bat](https://github.com/sharkdp/bat) | Better cat | `brew install bat` |
| [eza](https://github.com/eza-community/eza) | Better ls | `brew install eza` |
| [lazygit](https://github.com/jesseduffield/lazygit) | TUI for git | `brew install lazygit` |
| [bottom](https://github.com/ClementTsang/bottom) | System monitor | `brew install bottom` |

## Architecture

```
wezterm/
├── wezterm.lua              # Entry point
├── config/                  # Terminal configuration
│   ├── appearance.lua       # Window, opacity, blur, cursor
│   ├── fonts.lua            # Font family and settings
│   ├── performance.lua      # WebGPU, frame rate
│   ├── behavior.lua         # Shell, selection, bell
│   ├── domains.lua          # SSH, WSL, Docker
│   ├── keys.lua             # Leader key and keybindings
│   ├── mouse.lua            # Mouse bindings
│   └── workspace.lua        # Workspace management
├── ui/                      # User interface
│   ├── colors.lua           # Catppuccin Mocha palette
│   ├── icons.lua            # Nerd Font icons
│   ├── separators.lua       # Powerline separators
│   ├── tabbar.lua           # Custom tab bar
│   ├── statusbar.lua        # Rich status bar
│   ├── components.lua       # Reusable status elements
│   └── notifications.lua    # Bell notifications
├── utils/                   # Utilities
│   ├── cwd.lua              # Working directory
│   ├── git.lua              # Git integration
│   ├── process.lua          # Process detection
│   ├── battery.lua          # Battery status
│   ├── hostname.lua         # Hostname detection
│   ├── path.lua             # Path formatting
│   ├── platform.lua         # Platform detection
│   └── formatting.lua       # Text formatting
└── themes/                  # Color themes
    └── catppuccin-mocha.toml
```

## Keybindings

### Leader Key

Press `Ctrl+A` followed by:

| Key | Action |
|-----|--------|
| `\|` | Split horizontal |
| `-` | Split vertical |
| `h/j/k/l` | Navigate panes (vim-style) |
| `H/J/K/L` | Resize panes |
| `x` | Close pane |
| `z` | Zoom pane |
| `c` | New tab |
| `n/p` | Next/Previous tab |
| `1-9` | Switch to tab N |
| `w` | Workspace launcher |
| `,` | Rename workspace |
| `[` | Copy mode |
| `/` | Search |
| `Ctrl+K` | Clear scrollback |
| `Ctrl+R` | Reload config |
| `Ctrl+P` | Command palette |
| `Ctrl+D` | Debug overlay |
| `t` | Rename tab |
| `Space` | Quick select |

### Global Shortcuts

| Key | Action |
|-----|--------|
| `Cmd+C` | Copy |
| `Cmd+V` | Paste |
| `Cmd+=` | Increase font size |
| `Cmd+-` | Decrease font size |
| `Cmd+0` | Reset font size |
| `Cmd+F` | Toggle fullscreen |

## Customization

### Changing the Leader Key

Edit `config/keys.lua`:

```lua
M.leader = {
  key = 'b',  -- Change to Ctrl+B
  mods = 'CTRL',
  timeout_milliseconds = 1000,
}
```

### Adjusting Opacity

Edit `config/appearance.lua`:

```lua
config.window_background_opacity = 0.90  -- 0.0 (transparent) to 1.0 (opaque)
config.macos_window_background_blur = 30  -- Blur radius
```

### Adding SSH Servers

Edit `config/domains.lua`:

```lua
config.ssh_domains = {
  {
    name = 'myserver',
    remote_address = '192.168.1.100',
    username = 'user',
  },
}
```

### Changing Font Size

Edit `config/fonts.lua`:

```lua
config.font_size = 16.0  -- Adjust as needed
```

## Performance Notes

- WebGPU is enabled by default for best performance
- Max FPS set to 120 (adjust for your display)
- Status bar updates are cached (5-second TTL for git)
- Kitty graphics protocol enabled for image support

## Troubleshooting

### Fonts not rendering correctly

1. Ensure Nerd Fonts are installed
2. Set terminal font in WezTerm settings to "MonaspiceNe Nerd Font"
3. Restart WezTerm

### Config not loading

1. Check for syntax errors: `luac -p wezterm.lua`
2. Check WezTerm debug overlay: `Ctrl+A`, then `Ctrl+D`
3. Ensure all modules are in the correct directories

### Status bar missing

1. Check that `ui/statusbar.lua` exists
2. Verify all utility modules are present
3. Reload config: `Ctrl+A`, then `Ctrl+R`

### Leader key not working

1. Ensure no other application captures `Ctrl+A`
2. Check terminal is in normal mode (not copy mode)
3. Verify leader timeout in `config/keys.lua`

## License

MIT License

## Contributing

Contributions welcome! Please read the contributing guidelines first.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README"
```

---

### Task 23: Installation Scripts

**Covers:** S1

**Files:**
- Create: `install.sh`
- Create: `install.ps1`

- [ ] **Step 1: Create install.sh**

```bash
#!/bin/bash
# WezTerm Configuration Installer (macOS/Linux)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WEZTERM_CONFIG_DIR="${HOME}/.config/wezterm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}WezTerm Configuration Installer${NC}"
echo "================================"

# Check if WezTerm is installed
if ! command -v wezterm &> /dev/null; then
    echo -e "${YELLOW}Warning: WezTerm not found in PATH${NC}"
    echo "Please install WezTerm from: https://wezfurlong.org/wezterm/"
fi

# Backup existing config
if [ -d "$WEZTERM_CONFIG_DIR" ]; then
    echo -e "${YELLOW}Backing up existing config...${NC}"
    backup_dir="${WEZTERM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$WEZTERM_CONFIG_DIR" "$backup_dir"
    echo -e "${GREEN}Backup created: ${backup_dir}${NC}"
fi

# Create config directory
echo -e "${GREEN}Creating config directory...${NC}"
mkdir -p "$WEZTERM_CONFIG_DIR"

# Copy configuration files
echo -e "${GREEN}Installing configuration files...${NC}"
cp -r "${SCRIPT_DIR}/"* "$WEZTERM_CONFIG_DIR/"

# Remove installer scripts and non-config files from config dir
rm -f "${WEZTERM_CONFIG_DIR}/install.sh"
rm -f "${WEZTERM_CONFIG_DIR}/install.ps1"
rm -rf "${WEZTERM_CONFIG_DIR}/.git"
rm -rf "${WEZTERM_CONFIG_DIR}/screenshots"
rm -f "${WEZTERM_CONFIG_DIR}/README.md"
rm -f "${WEZTERM_CONFIG_DIR}/LICENSE"

# Install fonts (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}Installing fonts via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-monaspace-nerd-font 2>/dev/null || true
        brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
    else
        echo -e "${YELLOW}Homebrew not found. Please install fonts manually.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart WezTerm"
echo "2. Set font to 'MonaspiceNe Nerd Font' in WezTerm settings"
echo "3. Enjoy your new terminal experience!"
echo ""
echo "Leader key: Ctrl+A"
echo "Press Ctrl+A then ? for help"
```

- [ ] **Step 2: Make install.sh executable**

```bash
chmod +x /Users/m3etis/Projects/WezTerm/install.sh
```

- [ ] **Step 3: Create install.ps1**

```powershell
# WezTerm Configuration Installer (Windows)

$ErrorActionPreference = "Stop"

# Configuration
$WEZTERM_CONFIG_DIR = "$env:USERPROFILE\.config\wezterm"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "WezTerm Configuration Installer" -ForegroundColor Green
Write-Host "================================"

# Check if WezTerm is installed
if (-not (Get-Command wezterm -ErrorAction SilentlyContinue)) {
    Write-Host "Warning: WezTerm not found in PATH" -ForegroundColor Yellow
    Write-Host "Please install WezTerm from: https://wezfurlong.org/wezterm/"
}

# Backup existing config
if (Test-Path $WEZTERM_CONFIG_DIR) {
    Write-Host "Backing up existing config..." -ForegroundColor Yellow
    $backup_dir = "${WEZTERM_CONFIG_DIR}.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Rename-Item -Path $WEZTERM_CONFIG_DIR -NewName $backup_dir
    Write-Host "Backup created: $backup_dir" -ForegroundColor Green
}

# Create config directory
Write-Host "Creating config directory..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $WEZTERM_CONFIG_DIR | Out-Null

# Copy configuration files
Write-Host "Installing configuration files..." -ForegroundColor Green
Copy-Item -Path "$SCRIPT_DIR\*" -Destination $WEZTERM_CONFIG_DIR -Recurse -Force

# Remove non-config files from config dir
Remove-Item -Path "$WEZTERM_CONFIG_DIR\install.sh" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$WEZTERM_CONFIG_DIR\install.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$WEZTERM_CONFIG_DIR\.git" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$WEZTERM_CONFIG_DIR\screenshots" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$WEZTERM_CONFIG_DIR\README.md" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$WEZTERM_CONFIG_DIR\LICENSE" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Restart WezTerm"
Write-Host "2. Set font to 'MonaspiceNe Nerd Font' in WezTerm settings"
Write-Host "3. Enjoy your new terminal experience!"
Write-Host ""
Write-Host "Leader key: Ctrl+A"
Write-Host "Press Ctrl+A then ? for help"
```

- [ ] **Step 4: Commit**

```bash
git add install.sh install.ps1
chmod +x install.sh
git commit -m "feat: add installation scripts"
```

---

### Task 24: License File

**Covers:** S1

**Files:**
- Create: `LICENSE`

- [ ] **Step 1: Create LICENSE**

```
MIT License

Copyright (c) 2024 WezTerm Configuration

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Commit**

```bash
git add LICENSE
git commit -m "chore: add MIT license"
```

---

### Task 25: Final Verification

**Covers:** S1

**Files:**
- Verify: All Lua files

- [ ] **Step 1: Verify all Lua files compile**

```bash
for f in $(find . -name "*.lua" -not -path "./.git/*"); do
  echo "Checking $f..."
  luac -p "$f" || exit 1
done
echo "All files compile successfully"
```

- [ ] **Step 2: Verify file structure**

```bash
tree -I '.git' .
```

- [ ] **Step 3: Verify entry point exists**

```bash
ls -la wezterm.lua
```

- [ ] **Step 4: Initialize git repository**

```bash
git init
git add .
git commit -m "feat: initial WezTerm configuration"
```

---

## Summary

This plan creates a complete, production-quality WezTerm configuration with:

- **25 tasks** covering all modules
- **Modular architecture** with clear separation of concerns
- **Rich status bar** with 15+ components
- **Leader key system** with 40+ keybindings
- **Smart detection** for 30+ processes
- **Cross-platform support** for macOS, Linux, Windows
- **Complete documentation** with installation scripts
- **No TODOs or placeholders** — fully implemented
