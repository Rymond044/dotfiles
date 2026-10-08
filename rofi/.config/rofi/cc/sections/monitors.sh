# Мониторы: вкл/выкл выходов через hypr/lua/monitorctl.lua, раскладка — nwg-displays.
INTERNAL=eDP-1

# Имя, описание, выключен (true/false), режим.
monitors_list() {
	hyprctl monitors all -j | jq -r '.[] | [.name, (.description | gsub("[\t\n]"; " ") | sub(" (0x[0-9A-Fa-f]+|[0-9]{5,})$"; "")), .disabled,
		"\(.width)x\(.height)@\(.refreshRate | round)"] | @tsv'
}

monitors_status() {
	local n
	n=$(hyprctl monitors -j | jq length)
	echo "$n active"
}

monitors_rows() {
	TITLE=Monitors
	local name desc off mode
	while IFS=$'\t' read -r name desc off mode; do
		row "$(lbl "$([[ $name == "$INTERNAL" ]] && echo 󰌢 || echo 󰍹)" "$name" \
			"$(esc "$desc") · $([[ $off == true ]] && echo off || echo "$mode")")" \
			monitors_set "$name" "$([[ $off == true ]] && echo on || echo off)"
	done < <(monitors_list)
	row "$(lbl 󰌢 "Laptop screen only")" monitors_only_internal
	row "$(lbl 󰍺 "All monitors")" monitors_all
	row "$(lbl 󰒓 "Arrange (nwg-displays)")" launch nwg-displays
}

monitors_set() { # ИМЯ on|off
	if [[ $2 == off ]]; then
		local active
		active=$(hyprctl monitors -j | jq --arg n "$1" '[.[] | select(.name != $n)] | length')
		((active > 0)) || { notify "Monitors" "$1 is the last active monitor"; return 1; }
	fi
	hl_run "require('monitorctl').set('$1', $([[ $2 == on ]] && echo true || echo false))"
}

monitors_only_internal() {
	monitors_set "$INTERNAL" on
	local name
	for name in $(hyprctl monitors -j | jq -r --arg i "$INTERNAL" '.[] | select(.name != $i) | .name'); do
		monitors_set "$name" off
	done
}

monitors_all() { hl_run "require('monitorctl').all()"; }
