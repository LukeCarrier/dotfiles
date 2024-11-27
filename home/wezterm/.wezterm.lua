local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.enable_wayland = true
config.front_end = "WebGpu"

config.window_frame = {
  font = wezterm.font { family = 'Poppins' },
}
config.window_background_opacity = 0.85

config.command_palette_font_size = 18.0

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font('MonaSpiceKr NF')
config.font_size = 14.0

config.color_scheme = 'TokyoNightStorm'
config.colors = { background = '#1a1b26' }

return config
