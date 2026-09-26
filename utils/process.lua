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

--- Get foreground process info from a pane or PaneInformation table
--- @param pane table WezTerm Pane object or PaneInformation (from format-tab-title)
--- @return table { name, icon, display, path }
function M.get_foreground(pane)
  local process_path = ''

  if pane ~= nil then
    -- PaneInformation (format-tab-title): plain table with process_name field
    local ok_name, name = pcall(function() return pane.process_name end)
    if ok_name and type(name) == 'string' then
      process_path = name
    else
      -- Pane userdata: real method (pcall — type may not expose it)
      local ok_path, path = pcall(function()
        return pane:get_foreground_process_name()
      end)
      if ok_path and type(path) == 'string' then
        process_path = path
      end
    end
  end

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
