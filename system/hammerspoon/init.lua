MenuBarSpaces = hs.loadSpoon("MenuBarSpaces")
MenuBarSpaces:start()

-- Warp mouse between left and right edges to displays above and below.
-- Required for PaperWM.
WarpMouse = hs.loadSpoon("WarpMouse")
WarpMouse:start()

PaperWM = hs.loadSpoon("PaperWM")
PaperWM:bindHotkeys({
    focus_left  = {{"alt"}, "h"},
    focus_down  = {{"alt"}, "j"},
    focus_up    = {{"alt"}, "k"},
    focus_right = {{"alt"}, "l"},

    swap_left  = {{"alt", "shift"}, "h"},
    swap_down  = {{"alt", "shift"}, "j"},
    swap_up    = {{"alt", "shift"}, "k"},
    swap_right = {{"alt", "shift"}, "l"},

    -- center_window        = {{"alt", "cmd"}, "c"},
    -- full_width           = {{"alt", "cmd"}, "f"},
    -- cycle_width          = {{"alt", "cmd"}, "r"},
    -- reverse_cycle_width  = {{"ctrl", "alt", "cmd"}, "r"},
    -- cycle_height         = {{"alt", "cmd", "shift"}, "r"},
    -- reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

    slurp_in = {{"alt", "shift"}, "["},
    barf_out = {{"alt", "shift"}, "]"},

    -- toggle_floating = {{"alt", "cmd", "shift"}, "escape"},

    switch_space_l = {{"alt"}, "j"},
    switch_space_r = {{"alt"}, "k"},
    switch_space_1 = {{"alt"}, "1"},
    switch_space_2 = {{"alt"}, "2"},
    switch_space_3 = {{"alt"}, "3"},
    switch_space_4 = {{"alt"}, "4"},
    switch_space_5 = {{"alt"}, "5"},
    switch_space_6 = {{"alt"}, "6"},
    switch_space_7 = {{"alt"}, "7"},
    switch_space_8 = {{"alt"}, "8"},
    switch_space_9 = {{"alt"}, "9"},

    move_window_1 = {{"alt", "shift"}, "1"},
    move_window_2 = {{"alt", "shift"}, "2"},
    move_window_3 = {{"alt", "shift"}, "3"},
    move_window_4 = {{"alt", "shift"}, "4"},
    move_window_5 = {{"alt", "shift"}, "5"},
    move_window_6 = {{"alt", "shift"}, "6"},
    move_window_7 = {{"alt", "shift"}, "7"},
    move_window_8 = {{"alt", "shift"}, "8"},
    move_window_9 = {{"alt", "shift"}, "9"}
})
PaperWM:start()
