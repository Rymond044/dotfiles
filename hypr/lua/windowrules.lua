---@module 'hl'

--#############################
--## WINDOWS AND WORKSPACES ###
--#############################

-- See https://wiki.hypr.land/Configuring/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules


hl.window_rule({
    name  = "dragging_fix",
    match = {
        class = "^$",
        title = "^$",
        xwayland = 1,
        float = 1,
        fullscreen = 0,
        pin = 0,
    },
})

hl.window_rule({
    name       = "screensaver",
    match      = {
        class = "arch.screensaver",
    },
    fullscreen = 1,
})

hl.window_rule({
    name  = "previewer",
    match = {
        class = "org.gnome.NautilusPreviewer",
    },
    float = 1,
    size  = { 800, 600 },
})

hl.window_rule({
    name  = "vpn",
    match = {
        class = "Windscribe",
    },
    float = 1,
    size  = { 350, 284 },
})

hl.window_rule({
    name  = "calculator",
    match = {
        class = "org.gnome.Calculator",
    },
    float = 1,
})

hl.window_rule({
    name            = "chromium_scroll",
    match           = {
        class = "chromium",
    },
    scroll_touchpad = 0.1,
})

hl.window_rule({
    name            = "vencord_scroll",
    match           = {
        class = "vesktop",
    },
    scroll_touchpad = 0.1,
})

hl.window_rule({
    name  = "wiremix",
    match = {
        class = "wiremix"
    },
    float = 1,
    size  = { 1300, 750 },
})

hl.window_rule({
    name  = "bluetui",
    match = {
        class = "bluetui"
    },
    float = 1,
    size  = { 1300, 750 },
})

hl.window_rule({
    name  = "impala",
    match = {
        class = "impala"
    },
    float = 1,
    size  = { 1300, 750 },
})

hl.window_rule({
    name  = "btop",
    match = {
        class = "btop"
    },
    float = 1,
    size  = { 1300, 750 },
})

hl.window_rule({
    name  = "calcure",
    match = {
        class = "calcure"
    },
    float = 1,
    size  = { 1300, 750 },
})

hl.window_rule({
    name  = "install",
    match = {
        class = "install"
    },
    float = 1,
    size  = { 1300, 750 },
})
