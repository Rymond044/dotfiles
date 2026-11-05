---@module 'hl'

--####################
--## LOOK AND FEEL ###
--####################

-- Refer to https://wiki.hypr.land/Configuring/Variables/
-- https://wiki.hypr.land/Configuring/Variables/#general

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = { top = 0, left = 6, bottom = 6, right = 6 },
		border_size = 1,
		-- https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
		-- Set to true enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = true,
		-- Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
		allow_tearing = false,
		layout = "dwindle",
	},
})

hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
})

-- https://wiki.hypr.land/Configuring/Variables/#decoration

-- Прозрачность окон без фокуса: тёмная тема — 0.95; светлая — 0.97 без стекла и 0.8 со стеклом
-- (тест пользователя). Режим пишет ~/.config/binc/theme, стекло — ~/.config/binc/glass; оба делают reload.
local function inactive_opacity()
	local home = os.getenv("HOME")
	local cache = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")
	local state = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
	local f = io.open(cache .. "/theme/mode")
	local mode = f and f:read("l") or "dark"
	if f then
		f:close()
	end
	if mode ~= "light" then
		return 0.95
	end
	local off = io.open(state .. "/glass/off")
	if off then
		off:close()
		return 0.97
	end
	return 0.8
end

hl.config({
	decoration = {
		rounding = 10,
		rounding_power = 3,
		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = inactive_opacity(),

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

hl.config({
	render = {
		direct_scanout = 1,
	},
})

-- https://wiki.hypr.land/Configuring/Variables/#animations
hl.config({ animations = { enabled = true } })

-- 1. Регистрация кривых Безье (по правильному формату из доки)
-- Curves
hl.curve("easeOutQuint", {
	type = "bezier",
	points = { { 0.23, 1.0 }, { 0.32, 1.0 } },
})

hl.curve("easeInOutCubic", {
	type = "bezier",
	points = { { 0.65, 0.05 }, { 0.36, 1.0 } },
})

hl.curve("linear", {
	type = "bezier",
	points = { { 0.0, 0.0 }, { 1.0, 1.0 } },
})

hl.curve("almostLinear", {
	type = "bezier",
	points = { { 0.5, 0.5 }, { 0.75, 1.0 } },
})

hl.curve("quick", {
	type = "bezier",
	points = { { 0.15, 0.0 }, { 0.1, 1.0 } },
})

hl.curve("myBezier", {
	type = "bezier",
	points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.curve("overshot", {
	type = "bezier",
	points = { { 0.1, 0.5 }, { 0.1, 1.0 } },
})

-- Animations
hl.animation({
	leaf = "global",
	enabled = true,
	speed = 10,
	bezier = "default",
})

hl.animation({
	leaf = "border",
	enabled = true,
	speed = 5.39,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 4.79,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 4.1,
	bezier = "easeOutQuint",
	style = "popin 87%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1.49,
	bezier = "linear",
	style = "popin 87%",
})

hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = 1.73,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 1.46,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 3.03,
	bezier = "quick",
})

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 3.81,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
	style = "fade",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = 1.5,
	bezier = "linear",
	style = "fade",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = 1.79,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = 1.39,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 4,
	bezier = "default",
	style = "slide",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 5,
	bezier = "default",
	style = "slide",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 5,
	bezier = "default",
	style = "slide",
})

hl.animation({
	leaf = "zoomFactor",
	enabled = true,
	speed = 7,
	bezier = "quick",
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
	},
})
