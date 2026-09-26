-- config/appearance.lua
-- Window appearance configuration

local colors = require("ui.colors")
local platform = require("utils.platform")

local M = {}

--- Apply appearance configuration
--- @param config table WezTerm config
--- @return table Modified config
function M.apply(config)
	-- Window size (character cells; ~800px width at font_size 14)
	config.initial_cols = 100
	config.initial_rows = 30

	-- Window padding
	config.window_padding = {
		left = 12,
		right = 12,
		top = 12,
		bottom = 8,
	}

	-- Window frame (integrated title buttons on macOS)
	config.window_frame = {
		font = require("wezterm").font_with_fallback({
			{ family = "MonaspiceNe NF", weight = "Bold" },
			{ family = "MonaspiceNe Nerd Font", weight = "Bold" },
			{ family = "JetBrainsMono NF", weight = "Bold" },
		}),
		font_size = 13.0,
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
	config.default_cursor_style = "BlinkingBar"
	config.cursor_blink_rate = 500
	config.cursor_blink_ease_in = "Constant"
	config.cursor_blink_ease_out = "Constant"
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
	config.color_scheme = "Catppuccin Mocha"

	-- Tab bar
	config.enable_tab_bar = true
	config.use_fancy_tab_bar = true
	config.tab_bar_at_bottom = false
	config.status_update_interval = 1000

	-- Platform-specific
	platform.apply_platform_config(config)

	return config
end

return M
