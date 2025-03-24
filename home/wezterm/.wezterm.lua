local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Don't set SSH_AUTH_SOCK; we manage this via ~/.ssh/config
config.mux_enable_ssh_agent = false

config.enable_wayland = true
config.front_end = "WebGpu"

config.window_frame = {
  font = wezterm.font { family = 'Poppins' },
}
config.window_background_opacity = 0.85

config.command_palette_font_size = 18.0

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font('MonaspiceKr NF')
config.font_size = 14.0

config.color_scheme = 'Tokyo Night Storm'
config.colors = { background = '#1a1b26' }

return config
