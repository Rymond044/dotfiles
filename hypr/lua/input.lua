---@module 'hl'

--############
--## INPUT ###
--############

-- https://wiki.hypr.land/Configuring/Variables/#input

hl.config({
    input = {
        kb_layout = "us, ru",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        -- -1.0 - 1.0, 0
        touchpad = {
            scroll_factor = 0.5,
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Gestures

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more

hl.device({
    name = "msnb0001:00-04ca:2642-touchpad",
    sensitivity = 0.25,
})

hl.device({
    name = "compx-2.4g-wireless-receiver",
    sensitivity = -1,
    scroll_method = "on_button_down",
    scroll_button = 274,
})

hl.device({
    name = "compx-3-mode-mouse",
    sensitivity = -1,
    scroll_method = "on_button_down",
    scroll_button = 274,
})

hl.device({
    name = "compx-2.4g-wireless-receiver-1",
    sensitivity = -0.94,
    scroll_method = "on_button_down",
    scroll_button = 274,
})
