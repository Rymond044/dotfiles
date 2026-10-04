#!/usr/bin/env bash
# Трек для waybar: «artist - title», виден, только пока плеер в Playing/Paused.
# Без поллинга: playerctl -F печатает строку при каждом изменении (пустую — когда плеер пропал).
# Встроенный mpris не подошёл: после остановки/закрытия вкладки браузера держал старый трек.

show() {
	local status=$1 player=$2 artist=$3 title=$4
	case $status in
	Playing | Paused) ;;
	*) echo '{"text": ""}'; return ;;
	esac
	local text=$title
	[[ -n $artist ]] && text="$artist - $title"
	[[ -z $text ]] && text=$player
	text=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"$text")
	jq -cn --arg text "$text" --arg tooltip "$player : $text" --arg alt "$status" \
		'{text: $text, tooltip: $tooltip, alt: $alt, class: ($alt | ascii_downcase)}'
}

fmt=$'{{status}}\x1f{{playerName}}\x1f{{artist}}\x1f{{title}}'
{
	playerctl metadata --format "$fmt" 2>/dev/null || echo
	playerctl -F metadata --format "$fmt" 2>/dev/null
} | while IFS=$'\x1f' read -r status player artist title; do
	show "$status" "$player" "$artist" "$title"
done
