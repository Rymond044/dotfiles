#!/usr/bin/env bash
# Запуск waybar с барами под текущие мониторы.
# По логической ширине монитора: < WAYBAR_COMPACT_WIDTH — компактный бар (compact.jsonc поверх
# config.jsonc), < WAYBAR_MEDIUM_WIDTH — средний (medium.jsonc: короче плеер), иначе полный.
# Конфиг пишется в ~/.cache/waybar/config.jsonc; waybar перезапускается, только если конфиг
# изменился или waybar не запущен (скрипт зовётся из Hyprland на каждое добавление/удаление монитора).
#   launch.sh          — по необходимости
#   launch.sh --force  — перезапустить в любом случае
set -euo pipefail

compact=${WAYBAR_COMPACT_WIDTH:-1400}
medium=${WAYBAR_MEDIUM_WIDTH:-1800}
conf_dir="$HOME/.config/waybar"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
out="$cache_dir/config.jsonc"
mkdir -p "$cache_dir"

exec 9>"$cache_dir/launch.lock"
flock 9
# События мониторов приходят пачкой — даём раскладке устояться.
[[ ${1:-} == --force ]] || sleep 0.5

monitors=$(hyprctl monitors -j)
new=$(jq --argjson c "$compact" --argjson m "$medium" --arg d "$conf_dir" '
	map(select(.disabled | not)
		| {name, w: ((if .transform % 2 == 1 then .height else .width end) / .scale)})
	| [
		{ name: "full", outputs: map(select(.w >= $m) | .name), include: ["\($d)/config.jsonc"] },
		{ name: "medium", outputs: map(select(.w >= $c and .w < $m) | .name),
		  include: ["\($d)/medium.jsonc", "\($d)/config.jsonc"] },
		{ name: "compact", outputs: map(select(.w < $c) | .name),
		  include: ["\($d)/compact.jsonc", "\($d)/config.jsonc"] }
	]
	| map(select(.outputs | length > 0) | { name, output: .outputs, include })
' <<<"$monitors")

if [[ ${1:-} != --force ]] && pgrep -x waybar >/dev/null && [[ -f $out ]] && [[ $new == "$(<"$out")" ]]; then
	exit 0
fi

printf '%s\n' "$new" >"$out"
# Состояние плеера для custom/playerctl* (идемпотентно; юнит живёт до конца сессии).
systemctl --user start waybar-player.service || true
pkill -x waybar || true
while pgrep -x waybar >/dev/null; do sleep 0.05; done
setsid -f waybar -c "$out" -s "$conf_dir/style.css" </dev/null >/dev/null 2>&1 9>&-
