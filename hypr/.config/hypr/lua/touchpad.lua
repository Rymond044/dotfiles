-- Вкл/выкл тачпада без sudo: через конфиг устройства Hyprland, а не через sysfs `inhibited`.
-- Состояние — файл в $XDG_RUNTIME_DIR: переживает `hyprctl reload`, сбрасывается с перезагрузкой.
---@module 'hl'

local M = {}

local NAME = "msnb0001:00-04ca:2642-touchpad"
local STATE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-touchpad-disabled"

local function disabled()
	local f = io.open(STATE)
	if f then
		f:close()
	end
	return f ~= nil
end

-- Конфиг устройства (из input.lua) с учётом текущего состояния.
function M.apply(spec)
	spec = spec or {}
	spec.name = NAME
	spec.enabled = not disabled()
	hl.device(spec)
end

function M.toggle()
	if disabled() then
		os.remove(STATE)
	else
		io.open(STATE, "w"):close()
	end
	M.apply()
	local msg = disabled() and "Disabled" or "Enabled"
	hl.exec_cmd("notify-send -t 1500 -h string:x-canonical-private-synchronous:touchpad Touchpad " .. msg)
end

return M
