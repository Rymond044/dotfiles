---@module 'hl'

--################
--## AUTOSTART ###
--################

-- Сессия запускается через uwsm: окружение — в ~/.config/uwsm/env*, uwsm сам передаёт его
-- в systemd/D-Bus. Демоны запускаем через `uwsm app -s b --`: каждый в своём юните в
-- background.slice (видно в `systemctl --user status`, логи в journalctl).
local function daemon(cmd)
	hl.exec_cmd("uwsm app -s b -- " .. cmd)
end

hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/binc/lock") -- первым: сессия стартует заблокированной (autologin)
	hl.exec_cmd("~/.config/binc/portals-restart") -- иначе порталы могут остаться от «пустого» окружения
	os.execute("~/.config/binc/glass sync") -- до waybar/swaync: их стили импортируют ~/.cache/glass/*
	daemon("hypridle")
	daemon("awww-daemon") -- сам восстанавливает последние обои
	daemon("swaync")
	daemon("hyprsunset") -- ночной режим, только вручную (Super+N)
	-- polkit: один агент на сессию, обслуживает и KDE-приложения (btrfs-assistant). Бинарник не в PATH,
	-- поэтому через юнит пакета (start, не enable).
	hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
	daemon("clipse -listen")
	daemon("qs -p ~/Apps/quickseek -n") -- quickseek (Super+Alt+Space), окно создаётся только при открытии
	hl.exec_cmd("~/.config/waybar/scripts/launch.sh --force")
	hl.exec_cmd("hyprpm reload")
end)

-- Waybar: бар под ширину каждого монитора (полный/средний/компактный). Скрипт сам
-- пропускает события, после которых конфиг не меняется.
for _, event in ipairs({ "monitor.added", "monitor.removed", "monitor.layout_changed" }) do
	hl.on(event, function()
		hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
	end)
end

-- Обои: новый или повёрнутый монитор получает свой кадр (портретным — обрезка от walls).
-- Пауза — awww-daemon должен успеть создать поверхность на новом выходе.
for _, event in ipairs({ "monitor.added", "monitor.layout_changed" }) do
	hl.on(event, function()
		hl.exec_cmd("sleep 1 && ~/.config/binc/walls outputs")
	end)
end
