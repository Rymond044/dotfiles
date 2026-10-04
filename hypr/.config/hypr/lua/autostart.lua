---@module 'hl'

--################
--## AUTOSTART ###
--################

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
-- exec-once = nm-applet &
-- exec-once = waybar & hyprpaper & firefox
-- exec-once = walker --gapplication-service

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprlock")
	hl.exec_cmd("~/.config/waybar/scripts/launch.sh --force")
	hl.exec_cmd("hyprpm reload")
	hl.exec_cmd("impala")
	hl.exec_cmd("swaync")
	hl.exec_cmd("clipse -listen")
	hl.exec_cmd("swww-daemon")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("hyprpolkitagent")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	hl.exec_cmd("mcontrolcenter")
end)

-- Waybar: бар под ширину каждого монитора (полный/средний/компактный). Скрипт сам
-- пропускает события, после которых конфиг не меняется.
for _, event in ipairs({ "monitor.added", "monitor.removed", "monitor.layout_changed" }) do
	hl.on(event, function()
		hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
	end)
end
