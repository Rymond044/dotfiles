hl.config({
    plugin = {
        hyprtasking = {
            layout = "grid",
            gap_size = 10,
            border_size = 3,
            bg_color = 0xee111111,
            full_render = true,
            select_button = 273,
            drag_button = 272,
            exit_on_hovered = false,
            gestures = {
                enabled = true,
                open_fingers = 3,
                move_fingers = 6,
            },
            grid = {
                gaps_use_aspect_ratio = true,
            },
        },
    },
})

package.path = package.path
    .. ";"
    .. os.getenv("HOME")
    .. "/.config/hypr/?.lua"
    .. ";"
    .. os.getenv("HOME")
    .. "/.config/hypr/?/init.lua"
local smw = require("plugins")
smw.setup({
    workspace_count = 9,
    keep_focused = 1,
    enable_persistent_workspaces = false,
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
