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
