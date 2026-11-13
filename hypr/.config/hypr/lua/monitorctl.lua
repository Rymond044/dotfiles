---@module 'hl'
-- Вкл/выкл мониторов из control center (cc/sections/monitors.sh).
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

-- Одиночный монитор — в 0x0. Chromium 151 на Wayland считает своё окно стоящим в (0,0), а диалог
-- закрытия вкладки («Leave site?») вписывает в рабочую область дисплея в глобальных координатах:
-- на мониторе с позицией 3590x559 диалог уезжает за пределы окна и не виден (страница при этом
-- ждёт ответа). Позиция одиночного монитора ни на что не влияет, поэтому двигаем его в начало;
-- когда мониторов снова несколько — возвращаем позиции из monitors.lua.
-- С несколькими мониторами баг остаётся для всех, кроме стоящего в 0x0 (это лечится только в Chromium).
local function copy(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = v
	end
	return r
end

function M.fix_origin()
	local active = {}
	for _, m in ipairs(hl.get_monitors()) do
		if not m.is_mirror then
			active[#active + 1] = m
		end
	end
	local all = specs()
	if #active == 1 then
		local m = active[1]
		if m.x ~= 0 or m.y ~= 0 then
			local t = all[m.name] and copy(all[m.name])
				or { output = m.name, mode = "preferred", scale = "auto" }
			t.position = "0x0"
			hl.monitor(t)
		end
		return
	end
	-- Несколько мониторов: вернуть позицию тем, кого раньше сдвинули в 0x0.
	for _, m in ipairs(active) do
		local spec = all[m.name]
		local x, y = spec and tostring(spec.position or ""):match("^(-?%d+)x(-?%d+)$")
		if x and (tonumber(x) ~= m.x or tonumber(y) ~= m.y) then
			hl.monitor(copy(spec))
		end
	end
end

-- Правила из monitors.lua. Если подключён ровно один монитор, его позиция сразу 0x0: иначе
-- при `hyprctl reload` монитор уезжал на позицию из monitors.lua, а fix_origin возвращал его —
-- курсор при этом прижимался к краю (оказывался справа), а открытый слой (quickseek) терял фокус.
-- При первом старте мониторов ещё нет — тогда как раньше, поправит хук hyprland.start.
function M.load()
	local connected = {}
	for _, m in ipairs(hl.get_monitors({ all = true })) do
		if not m.is_mirror then
			connected[#connected + 1] = m.name
		end
	end
	for name, spec in pairs(specs()) do
		local t = spec
		if #connected == 1 and connected[1] == name then
			t = copy(spec)
			t.position = "0x0"
		end
		hl.monitor(t)
	end
end

function M.setup()
	M.load()
	for _, event in ipairs({ "hyprland.start", "config.reloaded", "monitor.added", "monitor.removed" }) do
		hl.on(event, M.fix_origin)
	end
end

return M
