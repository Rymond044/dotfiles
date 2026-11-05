-- Добавляем локальный путь в package.path для корректной работы require
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua"

-- Инициализация модулей конфигурации
-- monitors.lua (nwg-displays) грузит monitorctl: одиночный монитор сразу в 0x0 (диалоги Chromium)
require("monitorctl").setup()
require("env")
require("autostart")
require("input")
require("looknfeel")
dofile(os.getenv("HOME") .. "/.cache/wallust/hyprland.lua")
require("windowrules")
require("plugin")
require("glass") -- hyprglass (стекло), см. glass.lua
require("keybinds")
