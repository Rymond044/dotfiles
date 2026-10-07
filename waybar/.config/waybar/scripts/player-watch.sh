#!/usr/bin/env bash
# Состояние плеера для waybar: один процесс на всю сессию (юнит waybar-player.service).
# Один `playerctl -F` печатает строку при каждом изменении; скрипт пишет JSON в $state и шлёт
# waybar SIGRTMIN+8 — модули custom/playerctl* (signal 8) перечитывают файл через cat.
# Модули сами ничего не держат: раньше у каждого (×3 модуля ×3 бара) был свой bash+playerctl,
# и при каждом перезапуске waybar playerctl оставались сиротами (waybar убивает только прямого
# потомка, SIGPIPE игнорируется — запись в мёртвый пайп их не убивает).
# Трек виден, только пока плеер в Playing/Paused (встроенный mpris держал старый трек после остановки).
shopt -u patsub_replacement 2>/dev/null # `&` в замене ${s//…/…} — литерал

state=${XDG_RUNTIME_DIR:?}/waybar-player.json
signal=8
sigbit=$(($(kill -l RTMIN) + signal - 1)) # бит SIGRTMIN+8 в маске SigCgt

# Экранирование: pango-разметка, затем JSON-строка.
esc() {
	local s=$1
	s=${s//&/&amp;} s=${s//</&lt;} s=${s//>/&gt;}
	s=${s//\\/\\\\} s=${s//\"/\\\"} s=${s//[$'\n\r\t']/ }
	REPLY=$s
}

emit() {
	printf '%s\n' "$1" >"$state.tmp" && mv -f "$state.tmp" "$state"
	# Только тем waybar, что уже поставили обработчик: по умолчанию RT-сигнал убивает процесс,
	# а только что запущенный waybar (launch.sh) мог до него ещё не дойти.
	local pid key cgt
	for pid in $(pgrep -x waybar); do
		cgt=
		while read -r key cgt; do
			[[ $key == SigCgt: ]] && break
		done <"/proc/$pid/status" 2>/dev/null
		((16#${cgt:-0} >> sigbit & 1)) && kill -s RTMIN+$signal "$pid" 2>/dev/null
	done
}

show() {
	local status=$1 player=$2 artist=$3 title=$4
	case $status in
	Playing | Paused) ;;
	*) emit '{"text": ""}'; return ;;
	esac
	local text=$title
	[[ -n $artist ]] && text="$artist - $title"
	[[ -z $text ]] && text=$player
	esc "$text"; text=$REPLY
	esc "$player"
	emit "{\"text\": \"$text\", \"tooltip\": \"$REPLY : $text\", \"alt\": \"$status\", \"class\": \"${status,,}\"}"
}

trap 'rm -f "$state" "$state.tmp"' EXIT
emit '{"text": ""}' # без плеера `playerctl -F` молчит до первого события

while IFS=$'\x1f' read -r status player artist title; do
	show "$status" "$player" "$artist" "$title"
done < <(exec playerctl -F metadata --format $'{{status}}\x1f{{playerName}}\x1f{{artist}}\x1f{{title}}' 2>/dev/null)
