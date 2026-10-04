-- hl.config({
--     plugin = {
--         hyprtasking = {
--             layout = "grid",
--             gap_size = 10,
--             border_size = 3,
--             bg_color = 0xee111111,
--             select_button = 273,
--             drag_button = 272,
--             exit_on_hovered = false,
--             gestures = {
--                 enabled = true,
--                 open_fingers = 3,
--                 move_fingers = 6,
--             },
--             grid = {
--                 gaps_use_aspect_ratio = true,
--             },
--         },
--     },
-- })

hl.config({
	plugin = {
		hymission = {
			outer_padding = 92,
			layout_engine = "grid",
			toggle_switch_mode = 0,
			hide_hyprbars_during_overview = 1,
			niri_mode = 1,
			switch_release_key = "Super_L",
			workspace_strip_anchor = "up",
			hover_expand_scale = 1.18,
			selected_expand_scale = 1.035,
			multi_workspace_sort_recent_first = 0,
			debug_logs = 0,
			debug_surface_logs = 0,
			vim_keys = 1,
			info_notifications = 0,
			workspace_strip_center_active = 1,
			workspace_strip_keyboard_nav = 1,
		},
	},
})

hl.config({
	plugin = {
		hyprcapture = {
			default_mode = "region",
			fullscreen_scope = "all",
			overlay_scope = "fix",
			window_background = "follow-system",
			window_border = "keep",
			window_shadow = "keep",
			notification_backend = "hyprland",
			screenshot_notification = true,
			notification_title_template = "Screenshot captured",
			notification_body_template = "Saved {filename} ({window_title})",
			save = false,
			clipboard = true,
			show_thumbnail = true,
			remember_settings = false,
			allow_quick = false,
			confirm_before_capture = false,
			fusion_mode = false,
			capture_fullscreen_clients_as_monitor = false,
			dynamic_window_metadata = true,
			window_wheel_scroll = true,
			window_wheel_scope = "workspace",
			fullscreen_preview_rounding = "auto",
			save_dir = "$XDG_PICTURES_DIR/Screenshots",
			filename_template = "Screenshot-%Y-%m-%d-%H%M%S.png",
			record_save_dir = "$XDG_VIDEOS_DIR/Screenrecords",
			record_filename_template = "Recording-%Y-%m-%d-%H%M%S.mp4",
			record_format = "mp4",
			record_transparent_format = "webm",
			record_fps = 30,
			record_fps_options = "15 24 30 60, 144",
			record_window_fps_limit = 144,
			record_window_real_bg_fps_limit = 8,
			record_audio = "off",
			record_audio_output = "auto",
			record_audio_input = "default",
			record_codec = "auto",
			record_transparent_codec = "auto",
			record_solid_alpha = false,
			record_preset = "veryfast",
			record_gsr_flags = "",
			record_window_backend = "auto",
			record_max_seconds = 0,
			record_countdown_seconds = 0,
			include_cursor = false,
			thumbnail_timeout_ms = 5000,
			thumbnail_monitor = "active",
			watermark = "",
			watermark_position = "central",
			watermark_width = "20%",
			watermark_offset = "0 0",
		},
	},
})

-- hl.config({
-- 	plugin = {
-- 		hyprbars = {
-- 			bar_height = 20,
-- 			on_double_click = "hyprctl dispatch fullscreen 1",
-- 		},
-- 	},
-- })
--
-- hl.plugin.hyprbars.add_button({
-- 	bg_color = "rgb(ff4040)",
-- 	fg_color = "rgb(ffffff)",
-- 	size = 10,
-- 	icon = "X",
-- 	action = "hyprctl dispatch 'hl.dsp.window.close()'",
-- })
--
-- hl.plugin.hyprbars.add_button({
-- 	bg_color = "rgb(eeee11)",
-- 	fg_color = "rgb(000000)",
-- 	size = 10,
-- 	icon = "_",
-- 	action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
-- })

hl.plugin.hymission.gesture({
	fingers = 3,
	direction = "vertical",
	action = "toggle",
})

local smw = require("plugins")
smw.setup({
	workspace_count = 9,
	keep_focused = true,
	enable_persistent_workspaces = true,
	enable_notifications = false,
	enable_wrapping = false,
})
local mainMod = "SUPER"

for i = 1, smw.get_amount_of_workspaces() do
	local n = tostring(i)

	if n == "10" then
		n = "0"
	end

	hl.bind(mainMod .. " +" .. n, smw.workspace(n))
	hl.bind(mainMod .. " + SHIFT +" .. n, smw.move_to_workspace(n))
end
