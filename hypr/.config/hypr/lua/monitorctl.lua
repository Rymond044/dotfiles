---@module 'hl'
-- Вкл/выкл мониторов из control center (rofi/cc/sections/monitors.sh).
-- Выключить = hl.monitor{disabled}. Включить можно только полной спецификацией, а её знает
-- monitors.lua (nwg-displays): читаем его, подменив hl.monitor, и применяем нужный выход.
-- Состояние живёт до `hyprctl reload` (тот перечитает monitors.lua и включит всё).
local M = {}

local MONITORS = os.getenv("HOME") .. "/.config/hypr/monitors.lua"

local function specs()
	local out, real = {}, hl.monitor
	hl.monitor = function(t)
		out[t.output] = t
	end
	local ok, err = pcall(dofile, MONITORS)
	hl.monitor = real
	if not ok then
		hl.exec_cmd("notify-send -u critical monitorctl " .. string.format("%q", tostring(err)))
	end
	return out
end

function M.set(name, on)
	if not on then
		hl.monitor({ output = name, disabled = true })
		return
	end
	local spec = specs()[name] or { output = name, mode = "preferred", position = "auto", scale = "auto" }
	local t = {}
	for k, v in pairs(spec) do
		t[k] = v
	end
	t.disabled = false
	hl.monitor(t)
end

-- Включить все выходы из monitors.lua.
function M.all()
	for name in pairs(specs()) do
		M.set(name, true)
	end
end

return M
