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
