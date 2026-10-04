--#########################################
--## НАВИГАЦИЯ ВНУТРИ МОНИТОРА И МЕЖДУ НИМИ
--#########################################
-- Super+стрелка: фокус на окно в эту сторону на текущем воркспейсе, у края (или без окон) —
-- на соседний монитор, на окно, ближайшее к краю, через который вошли.
-- Super+Shift+стрелка: tiled-окно двигается внутри раскладки, у края — на соседний монитор
-- (в его активный ws, совместимо с smw); floating и fullscreen — сразу на соседний монитор.
-- Соседний монитор ищется по реальной логической геометрии (scale/transform, неровные стыки),
-- а не по точному касанию краёв, как во встроенном фолбэке Hyprland.
---@module 'hl'

local M = {}

local AXIS = {
	left = { sign = -1, horiz = true },
	right = { sign = 1, horiz = true },
	up = { sign = -1, horiz = false },
	down = { sign = 1, horiz = false },
}

local OPPOSITE = { left = "r", right = "l", up = "d", down = "u" }

---@param m HL.Monitor
local function monitor_box(m)
	local w, h = m.width / m.scale, m.height / m.scale
	if m.transform % 2 == 1 then
		w, h = h, w
	end
	return { x = m.x, y = m.y, w = w, h = h }
end

---@param win HL.Window
local function window_box(win)
	return { x = win.at.x, y = win.at.y, w = win.size.x, h = win.size.y }
end

-- Проекция бокса на ось движения (a) и поперечную ось (p).
local function span(b, horiz)
	if horiz then
		return b.x, b.x + b.w, b.y, b.y + b.h
	end
	return b.y, b.y + b.h, b.x, b.x + b.w
end

local function overlap(a1, a2, b1, b2)
	return math.min(a2, b2) - math.max(a1, b1)
end

-- Сосед монитора `cur` в направлении `dir`: целиком «по ту сторону» центра и не дальше
-- половины ширины внахлёст. Сначала те, что перекрываются по поперечной оси (ближайший
-- по зазору, затем с большим перекрытием), иначе — ближайший по центрам.
---@param cur HL.Monitor
---@return HL.Monitor|nil
local function neighbor_monitor(cur, dir)
	local ax = AXIS[dir]
	local cb = monitor_box(cur)
	local c1, c2, cp1, cp2 = span(cb, ax.horiz)
	local ccenter, cpcenter = (c1 + c2) / 2, (cp1 + cp2) / 2

	local best, best_key
	for _, m in ipairs(hl.get_monitors()) do
		if m.id ~= cur.id and not m.is_mirror then
			local b1, b2, bp1, bp2 = span(monitor_box(m), ax.horiz)
			local bcenter = (b1 + b2) / 2
			local gap = ax.sign > 0 and (b1 - c2) or (c1 - b2)
			local ahead = (bcenter - ccenter) * ax.sign > 0
			if ahead and gap > -math.min(c2 - c1, b2 - b1) / 2 then
				local ov = overlap(cp1, cp2, bp1, bp2)
				local key
				if ov > 0 then
					key = { 0, math.abs(gap), -ov }
				else
					key = { 1, math.abs(bcenter - ccenter) + math.abs((bp1 + bp2) / 2 - cpcenter), 0 }
				end
				if not best_key or key[1] < best_key[1]
					or (key[1] == best_key[1] and (key[2] < best_key[2] - 1
						or (math.abs(key[2] - best_key[2]) <= 1 and key[3] < best_key[3]))) then
					best, best_key = m, key
				end
			end
		end
	end
	return best
end

---@param m HL.Monitor
---@return HL.Workspace|nil
local function shown_workspace(m)
	return m.active_special_workspace or m.active_workspace
end

---@param ws HL.Workspace
---@return HL.Window[]
local function workspace_windows(ws)
	local out = {}
	for _, w in ipairs(hl.get_windows()) do
		if w.mapped and not w.hidden and w.workspace and w.workspace.id == ws.id then
			out[#out + 1] = w
		end
	end
	return out
end

-- Окно в направлении `dir` от `from` среди `wins`. Кандидат должен начинаться дальше и иметь
-- центр дальше по оси. Приоритет: перекрытие по поперечной оси → меньший зазор → недавний фокус.
-- Без перекрытия — только в конусе 45° (иначе это «по диагонали», а не «в сторону»).
---@param from HL.Window
---@param wins HL.Window[]
---@param filter? fun(w: HL.Window): boolean
---@return HL.Window|nil
local function window_in_direction(from, wins, dir, filter)
	local ax = AXIS[dir]
	local f1, f2, fp1, fp2 = span(window_box(from), ax.horiz)
	local fcenter, fpcenter = (f1 + f2) / 2, (fp1 + fp2) / 2

	local best, best_key
	for _, w in ipairs(wins) do
		if w.address ~= from.address and (not filter or filter(w)) then
			local b1, b2, bp1, bp2 = span(window_box(w), ax.horiz)
			local along = ((b1 + b2) / 2 - fcenter) * ax.sign
			local lead = ax.sign > 0 and (b2 - f2) or (f1 - b1)
			if along > 1 and lead > 1 then
				local gap = math.max(0, ax.sign > 0 and (b1 - f2) or (f1 - b2))
				local perp = math.abs((bp1 + bp2) / 2 - fpcenter)
				local key
				if overlap(fp1, fp2, bp1, bp2) > 1 then
					key = { 0, gap, w.focus_history_id }
				elseif perp <= along then
					key = { 1, along + perp, w.focus_history_id }
				end
				if key and (not best_key or key[1] < best_key[1]
					or (key[1] == best_key[1] and (key[2] < best_key[2] - 1
						or (math.abs(key[2] - best_key[2]) <= 1 and key[3] < best_key[3])))) then
					best, best_key = w, key
				end
			end
		end
	end
	return best
end

-- Окно на мониторе `m`, ближайшее к краю, через который входим (при движении вправо — к левому).
---@param m HL.Monitor
---@param ref_box table|nil бокс, откуда пришли (для выбора по поперечной оси)
---@return HL.Window|nil
local function entry_window(m, dir, ref_box)
	local ws = shown_workspace(m)
	if not ws then
		return nil
	end
	if ws.has_fullscreen and ws.fullscreen_window then
		return ws.fullscreen_window
	end
	local ax = AXIS[dir]
	local rpcenter
	if ref_box then
		local _, _, rp1, rp2 = span(ref_box, ax.horiz)
		rpcenter = (rp1 + rp2) / 2
	end

	local best, best_key
	for _, w in ipairs(workspace_windows(ws)) do
		local b1, b2, bp1, bp2 = span(window_box(w), ax.horiz)
		local edge = ax.sign > 0 and b1 or -b2
		local perp = 0
		if rpcenter then
			perp = (rpcenter >= bp1 and rpcenter <= bp2) and 0 or math.abs((bp1 + bp2) / 2 - rpcenter)
		end
		local key = { edge, perp, w.focus_history_id }
		if not best_key or key[1] < best_key[1] - 2
			or (math.abs(key[1] - best_key[1]) <= 2 and (key[2] < best_key[2]
				or (key[2] == best_key[2] and key[3] < best_key[3]))) then
			best, best_key = w, key
		end
	end
	return best
end

local function active_on(mon)
	local w = hl.get_active_window()
	local ws = shown_workspace(mon)
	if w and ws and w.workspace and w.workspace.id == ws.id then
		return w, ws
	end
	return nil, ws
end

---@param dir "left"|"right"|"up"|"down"
function M.focus(dir)
	local mon = hl.get_active_monitor()
	if not mon then
		return
	end
	local w, ws = active_on(mon)

	if w and w.fullscreen == 0 and ws then
		local target = window_in_direction(w, workspace_windows(ws), dir)
		if target then
			hl.dispatch(hl.dsp.focus({ window = target }))
			return
		end
	end

	local nm = neighbor_monitor(mon, dir)
	if not nm then
		return
	end
	local target = entry_window(nm, dir, w and window_box(w) or monitor_box(mon))
	if target then
		hl.dispatch(hl.dsp.focus({ window = target }))
	else
		hl.dispatch(hl.dsp.focus({ monitor = nm.name }))
	end
end

-- Сохраняет относительное положение floating-окна при переезде на другой монитор и
-- вписывает его в рабочую область (минус reserved: waybar и т. п.).
local function fit_floating(win, old_mon, new_mon, box)
	local function usable(m)
		local b = monitor_box(m)
		local r = m.reserved or {}
		local top, bottom, left, right = r.top or 0, r.bottom or 0, r.left or 0, r.right or 0
		return { x = b.x + left, y = b.y + top, w = b.w - left - right, h = b.h - top - bottom }
	end
	local ob, nb = usable(old_mon), usable(new_mon)
	local w, h = math.min(box.w, nb.w), math.min(box.h, nb.h)
	local fx = ob.w > box.w and (box.x - ob.x) / (ob.w - box.w) or 0.5
	local fy = ob.h > box.h and (box.y - ob.y) / (ob.h - box.h) or 0.5
	fx, fy = math.max(0, math.min(1, fx)), math.max(0, math.min(1, fy))
	local x = math.floor(nb.x + fx * (nb.w - w) + 0.5)
	local y = math.floor(nb.y + fy * (nb.h - h) + 0.5)
	if w ~= box.w or h ~= box.h then
		hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = win }))
	end
	hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = win }))
end

---@param dir "left"|"right"|"up"|"down"
function M.move(dir)
	local mon = hl.get_active_monitor()
	if not mon then
		return
	end
	local w, ws = active_on(mon)
	if not w or not ws then
		return
	end

	if not w.floating and w.fullscreen == 0 then
		local tiled = window_in_direction(w, workspace_windows(ws), dir, function(c)
			return not c.floating
		end)
		if tiled then
			hl.dispatch(hl.dsp.window.move({ direction = dir }))
			return
		end
	end

	local nm = neighbor_monitor(mon, dir)
	if not nm then
		return
	end
	local floating, box = w.floating and w.fullscreen == 0, window_box(w)

	-- Tiled встаёт у края, через который вошёл: dwindle разбивает окно под курсором,
	-- сторону задаём preselect (иначе force_split всегда кладёт справа/снизу).
	local tws = shown_workspace(nm)
	if not floating and tws and not tws.has_fullscreen and tws.tiled_layout == "dwindle" then
		local entry = entry_window(nm, dir, box)
		if entry and not entry.floating then
			hl.dispatch(hl.dsp.focus({ window = entry }))
			hl.dispatch(hl.dsp.layout("preselect " .. OPPOSITE[dir]))
		end
	end

	hl.dispatch(hl.dsp.window.move({ monitor = nm.name, window = w }))
	if floating then
		fit_floating(w, mon, nm, box)
	end
end

return M
