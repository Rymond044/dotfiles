---@module 'hl'

--##############################
--## QUICKDESK (ВИДЖЕТЫ) #######
--##############################

-- quickdesk (~/Apps/quickdesk) рисует виджеты под окнами. Сообщаем ему, на каких мониторах
-- открыты окна: там он перестаёт тикать (секунды часов, прогресс музыки) — каждая перерисовка
-- под полупрозрачными окнами заставляет Hyprland пересобирать весь стек с blur.
-- Через хук, а не синглтон Hyprland в Quickshell: тот держит сокет событий и будит процесс
-- на каждую смену заголовка окна.

local M = {}

local sent = {}

-- force: отправить заново всё. quickdesk сам просит об этом при старте
-- (occupancyRefresh в quickdesk/settings.json): после перезапуска он не знает состояния
function M.sync(force)
	for _, m in ipairs(hl.get_monitors()) do
		local ws = m.active_workspace
		local busy = ws ~= nil and not ws.is_empty
		if force or sent[m.name] ~= busy then
			sent[m.name] = busy
			hl.exec_cmd("qs -p ~/Apps/quickdesk ipc call quickdesk occupied " .. m.name .. " " .. tostring(busy))
		end
	end
end

function M.setup()
	for _, event in ipairs({
		"window.open",
		"window.close",
		"window.destroy",
		"window.move_to_workspace",
		"workspace.active",
		"workspace.move_to_monitor",
		"monitor.added",
	}) do
		hl.on(event, function()
			M.sync()
		end)
	end
	hl.on("config.reloaded", function()
		M.sync(true)
	end)
end

return M
