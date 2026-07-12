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
