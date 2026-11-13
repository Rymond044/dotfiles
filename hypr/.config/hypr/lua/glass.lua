---@module 'hl'

--###############################
--## HYPRGLASS (LIQUID GLASS) ###
--###############################

-- Стекло «как в iOS 26 / macOS 26»: почти прозрачная тонировка, сильная линза по ободу
-- (edge_height) с отражением, плоский центр, тонкая светлая кромка только со стороны света.
-- Дока: https://github.com/hyprnux/hyprglass (README). Подбор вживую:
--   hyprctl eval 'hl.plugin.hyprglass.preset("ios", { edge_height = 30 })'
-- Стекло видно только сквозь полупрозрачные пиксели: непрозрачные окна (браузер, GTK) его
-- не показывают — как и в iOS, где стекло на «хроме», а контент непрозрачный.
--
-- Вкл/выкл целиком (плагин + прозрачность waybar/swaync/quickseek/quickdesk): `~/.config/binc/glass [on|off]`,
-- CC → Appearance. Выключено, если есть ~/.local/state/glass/off — тогда всё как до стекла.

if not hl.plugin.hyprglass then
	return
end

local hg = hl.plugin.hyprglass

local function glass_off()
	local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	local f = io.open(state .. "/glass/off")
	if f then
		f:close()
		return true
	end
	return false
end

-- Светлая/тёмная тема (binc/theme пишет ~/.cache/theme/mode): ветки light/dark у пресетов
local function theme_mode()
	local cache = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
	local f = io.open(cache .. "/theme/mode")
	if not f then
		return "dark"
	end
	local m = f:read("l")
	f:close()
	return m == "light" and "light" or "dark"
end

if glass_off() then
	hg.config({ enabled = false, layers = { enabled = false } })
	return
end

-- База: встроенный pomme (Apple-подобный) + линзовый обод фиксированной ширины в px,
-- одинаковый на любом размере окна и scale монитора.
hg.preset("ios", {
	inherits = "pomme",

	-- Умеренное размытие: сильное прячет линзу по краю
	blur_strength = 1.0,
	blur_iterations = 3,
	noise_strength = 0.0,

	-- Обод-линза: узкий резкий изгиб с отражением соседнего, плоский центр
	edge_thickness_px = 18,
	edge_height = 40,
	refraction_strength = 0.9,
	fresnel_reflection = 0.45,
	lens_distortion = 0.0,
	chromatic_aberration = 0.2,

	-- Свет: блик сверху и тонкая белая кромка только сверху-слева. Без свечения по всему
	-- периметру (fresnel) и без тени кромки — иначе выходит ровная серая обводка.
	specular_strength = 0.7,
	specular_angle = 0,
	fresnel_strength = 0.06,
	bevel_strength = 0.85,
	bevel_size = 1.2,
	bevel_tint = 0.0,
	bevel_color = 0xffffff00,
	bevel_angle = 315,
	bevel_shadow = 0.0,

	-- Цвета за стеклом сочнее и светлее, как у Apple; тонировка еле заметная
	saturation = 1.35,
	vibrancy = 0.3,
	vibrancy_darkness = 0.5,

	dark = { brightness = 1.12, contrast = 0.95, tint_color = 0x1418201f, adaptive_dim = 0.15 },
	light = { brightness = 1.1, contrast = 0.97, tint_color = 0xffffff40, adaptive_boost = 0.1 },
})

-- Мелкие элементы (пилюли waybar, уведомления): обод уже, иначе съедает всю высоту
hg.preset("ios_small", {
	inherits = "ios",
	edge_thickness_px = 10,
	edge_height = 22,
	bevel_size = 1.0,
})

-- Панели и меню (центр уведомлений, выбиралка обоев, quickseek): больше размытия, чтобы текст читался
hg.preset("ios_panel", {
	inherits = "ios",
	blur_strength = 2.0,
	edge_thickness_px = 16,
	edge_height = 34,
	dark = { tint_color = 0x14182040 },
	light = { tint_color = 0xffffff60 },
})

-- Окна: подсветка активного по ободу; над другими окнами стекло мутнеет (frost),
-- над обоями остаётся прозрачным — текст терминала не спорит с текстом позади
hg.preset("ios_window", {
	inherits = "ios",
	blur_strength = 1.6,
	edge_thickness_px = 20,
	edge_height = 44,
	focus_light = 0.35,
	focus_light_color = 0xffffff00,
	frost = 0.8,
	frost_blur = 2.0,
})

hg.config({
	enabled = true,
	default_theme = theme_mode(),
	default_preset = "ios_window",

	-- Кэш стекла пересобирается, только когда фон меняется; 30 fps хватает и бережёт батарею
	windows = { live_resample = true, live_resample_fps = 30 },

	layers = {
		enabled = true,
		preset = "ios_small",
		-- contour: у каждой нарисованной фигуры (пилюля, карточка) свой обод и блики,
		-- а не один на весь слой. Порог ниже прозрачности фона пилюль (0.12 в waybar/glass.css),
		-- feather 0: иначе всё бледнее threshold + feather получает ослабленное стекло
		mask_mode = "contour",
		mask_threshold = 0.05,
		mask_feather = 0,
		live_resample = true,
		live_resample_fps = 30,
	},
})

-- Слои: перечисленные получают стекло, остальные — нет (awww-daemon = обои, его не трогаем).
-- waybar: имена баров из waybar/scripts/launch.sh
for _, bar in ipairs({ "full", "medium", "compact" }) do
	hg.layer(bar, { preset = "ios_small" })
end
hg.layer("swaync-control-center", { preset = "ios_panel" })
hg.layer("swaync-notification-window", { preset = "ios_small" })
hg.layer("walls", { preset = "ios_panel" })
hg.layer("quickseek", { preset = "ios_panel" })
-- quickdesk: стекло только у карточек (слой "quickdesk"); виджеты-текст — слой "quickdesk-text", без стекла
hg.layer("quickdesk", { preset = "ios_panel" })

-- Полноэкранное и видео стекло не нужно (и не видно)
hl.window_rule({ name = "glass_off_fullscreen", match = { fullscreen = true }, tag = "+hyprglass_disabled" })
hl.window_rule({ name = "glass_off_mpv", match = { class = "mpv" }, tag = "+hyprglass_disabled" })
