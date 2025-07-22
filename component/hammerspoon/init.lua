-- Warp mouse between left and right edges to displays above and below.
-- Required for PaperWM.
WarpMouse = hs.loadSpoon("WarpMouse")
WarpMouse:start()

PaperWM = hs.loadSpoon("PaperWM")
-- PaperWM.space_names = {1, 2, 3, 4, 5, 6, 7, 8, 9}
PaperWM.default_app_space = {}
PaperWM.swipe_fingers = 3
PaperWM:bindHotkeys({
    focus_left  = {{"alt"}, "h"},
    focus_down  = {{"alt"}, "j"},
    focus_up    = {{"alt"}, "k"},
    focus_right = {{"alt"}, "l"},

    move_left  = {{"alt", "shift"}, "h"},
    move_down  = {{"alt", "shift"}, "j"},
    move_up    = {{"alt", "shift"}, "k"},
    move_right = {{"alt", "shift"}, "l"},

    -- center_window        = {{"alt", "cmd"}, "c"},
    -- full_width           = {{"alt", "cmd"}, "f"},
    -- cycle_width          = {{"alt", "cmd"}, "r"},
    -- reverse_cycle_width  = {{"ctrl", "alt", "cmd"}, "r"},
    -- cycle_height         = {{"alt", "cmd", "shift"}, "r"},
    -- reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},

    slurp_in = {{"alt", "shift"}, "["},
    barf_out = {{"alt", "shift"}, "]"},

    -- toggle_floating = {{"alt", "cmd", "shift"}, "escape"},

    next_screen          = {{"alt"}, "n"},
    space_to_next_screen = {{"alt", "shift"}, "n"},

    focus_space_1 = {{"alt"}, "1"},
    focus_space_2 = {{"alt"}, "2"},
    focus_space_3 = {{"alt"}, "3"},
    focus_space_4 = {{"alt"}, "4"},
    focus_space_5 = {{"alt"}, "5"},
    focus_space_6 = {{"alt"}, "6"},
    focus_space_7 = {{"alt"}, "7"},
    focus_space_8 = {{"alt"}, "8"},
    focus_space_9 = {{"alt"}, "9"},
})
PaperWM:start()
