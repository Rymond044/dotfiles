#!/usr/bin/env bash
# Кнопка prev/next для waybar: видна, только пока плеер в Playing/Paused.
# Без поллинга: playerctl -F печатает статус при каждом изменении.
icon=󰒮
[[ ${1:-} == next ]] && icon=󰒭

show() {
	case $1 in
	Playing | Paused) printf '{"text": "%s"}\n' "$icon" ;;
	*) printf '{"text": ""}\n' ;;
	esac
}

show "$(playerctl status 2>/dev/null)"
playerctl -F status 2>/dev/null | while read -r status; do show "$status"; done
