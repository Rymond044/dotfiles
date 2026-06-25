---@module 'hl'

--####################
--## LOOK AND FEEL ###
--####################

-- Refer to https://wiki.hypr.land/Configuring/Variables/
-- https://wiki.hypr.land/Configuring/Variables/#general

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = { top = 0, left = 4, bottom = 4, right = 4 },
        border_size = 2,
        -- https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,
        -- Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
    },
})

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#decoration

hl.config({
    decoration = {
        rounding = 1,
        rounding_power = 2,
        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 0.95,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        -- https://wiki.hypr.land/Configuring/Variables/#blur
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            xray = false,
            vibrancy = 0.1696,
        },
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#animations

hl.config({ animations = { enabled = true } })

-- Определяем кривую Безье (используется для окон и воркспейсов)
hl.curve("easeOutQuint", {
    type = "bezier",
    points = { { 0.23, 1.0 }, { 0.32, 1.0 } }
})

-- ===== Базовые анимации окон (появление / закрытие) =====
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 2,
    bezier = "easeOutQuint",
    style = "popin 87%" -- плавное появление с лёгким увеличением
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1,
    bezier = "easeOutQuint",
    style = "popin 87%" -- обратный эффект при закрытии
})

-- ===== Анимация переключения рабочих столов (слайд) =====
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint",
    style = "slide" -- горизонтальный сдвиг
})

-- (Опционально) Анимация для слоёв (уведомления, панели) – простая прозрачность
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2,
    bezier = "easeOutQuint",
    style = "fade"
})

hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.5,
    bezier = "easeOutQuint",
    style = "fade"
})



hl.config({
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
})


hl.config({
    master = {
        new_status = "master",
    },
})


hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
        disable_autoreload = false,
    },
})
