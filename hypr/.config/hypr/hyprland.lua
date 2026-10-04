-- Добавляем локальный путь в package.path для корректной работы require
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua"

-- Инициализация модулей конфигурации
require("monitors")
require("env")
require("autostart")
require("input")
require("looknfeel")
dofile(os.getenv("HOME") .. "/.cache/wallust/hyprland.lua")
require("windowrules")
require("plugin")
require("workspacerules")
require("keybinds")
