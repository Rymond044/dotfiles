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
	keep_focused = 1,
	enable_persistent_workspaces = true,
	enable_notifications = 0,
	enable_wrapping = 0,
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
