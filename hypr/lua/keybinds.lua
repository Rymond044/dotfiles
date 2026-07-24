--##################
--## KEYBINDINGS ###
--##################

-- See https://wiki.hypr.land/Configuring/Keywords/
---@module 'hl'

--##################
--## MY PROGRAMS ###
--##################

-- See https://wiki.hypr.land/Configuring/Keywords/
-- Set programs that you use
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "~/.config/rofi/launchers/type-2/launcher.sh"
local appMenu = "~/.config/rofi/applets/bin/apps.sh"
local powermenu = "~/.config/rofi/powermenu/type-1/powermenu.sh"
local browser = "chromium --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation"
local bufferman = "[float; size 900 550; center] kitty -e clipse"
local screenshot = "grim /tmp/temp_screenshot.png && eog /tmp/temp_screenshot.png"
local touchpadToggle = "~/.config/binc/touchpad_toggle"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit()):remove()
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })):remove()
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(powermenu))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- bind = CTRL, Space, exec, kando --trigger menu1

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Переключение рабочих столов с mainMod + [0-9]
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- hl.bind("SUPER + Tab", function() hl.plugin.hyprtasking.toggle("all") end)

-- hl.bind("CTRL + TAB", function()
--     hl.plugin.hyprexpo.expo("toggle")
-- end)

hl.bind("SUPER + TAB", hl.plugin.hymission.toggle)
hl.bind("CTRL + TAB", function()
    hl.plugin.hymission.toggle("onlycurrentworkspace")
end)


-- escape closes the overview if it's open
-- hl.bind("escape", function()
--     if hl.plugin.hyprtasking.is_active() then
--         hl.plugin.hyprtasking.toggle("all")
--     end
-- end, { non_consuming = true })

hl.bind("SHIFT + CTRL + M", hl.dsp.pass({ window = "class:vesktop" }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic")):remove()
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" })):remove()

--Screenshots
-- Сделать скриншот всего экрана и сразу открыть в Swappy
hl.bind("Print", hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('wayfreeze & PID=$!; sleep 0.1; grim -g "$(slurp)" - | wl-copy'))
hl.bind(
    mainMod .. " + O",
    hl.dsp.exec_cmd('wayfreeze & PID=$!; sleep 0.1; grim -g "$(slurp)" - | tesseract stdin stdout -l eng+rus | wl-copy')
)

--буфер обмена
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(bufferman))

--меню приложений
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(appMenu))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(touchpadToggle), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true }):remove()
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }):remove()
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }):remove()
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true }):remove()

--переключение треков
hl.bind(mainMod .. " + SHIFT + code:60", hl.dsp.exec_cmd("playerctl next"))
hl.bind(mainMod .. " + SHIFT + code:59", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mainMod .. " + SHIFT + code:61", hl.dsp.exec_cmd("playerctl play-pause"))
