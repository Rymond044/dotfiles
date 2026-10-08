# Bluetooth: состояние — из BlueZ по D-Bus, действия — bluetoothctl.

# Адаптер: BT_POW (true/false/пусто — нет адаптера). Устройства — bt_devices.
bt_load() {
	BT_OBJS=$(busctl --system --json=short call org.bluez / org.freedesktop.DBus.ObjectManager \
		GetManagedObjects 2>/dev/null | jq '.data[0]') || { BT_POW=; return 1; }
	BT_POW=$(jq -r '[.[] | .["org.bluez.Adapter1"] | select(.) | .Powered.data][0] // empty' <<<"$BT_OBJS")
	[[ -n $BT_POW ]]
}

# MAC, имя, иконка («-» — нет: read схлопывает пустые поля), сопряжено, подключено; подключённые первыми.
bt_devices() {
	jq -r '[.[] | .["org.bluez.Device1"] | select(.)
		| {a: .Address.data, n: ((.Alias.data // .Address.data) | gsub("[\t\n]"; " ")),
		   i: (.Icon.data // "-"), p: .Paired.data, c: .Connected.data}]
		| sort_by(if .c then 0 else 1 end, .n)[] | [.a, .n, .i, .p, .c] | @tsv' <<<"$BT_OBJS"
}

bt_icon() {
	case $1 in
	audio-head*) echo 󰋋 ;; audio*) echo 󰓃 ;; input-mouse) echo 󰍽 ;; input-keyboard) echo 󰌌 ;;
	input-gaming) echo 󰊴 ;; phone) echo 󰏲 ;; *) echo 󰂯 ;;
	esac
}

bt_status() {
	bt_load || { echo "no adapter"; return; }
	[[ $BT_POW == true ]] || { echo "off"; return; }
	local names
	names=$(bt_devices | awk -F'\t' '$5 == "true" { printf "%s%s", (n++ ? ", " : ""), $2 }')
	esc "${names:-on}"
}

bt_list() { bt_load && bt_devices; }

bt_rows() {
	TITLE=Bluetooth
	if ! bt_load; then
		MESG="No Bluetooth adapter"
		row "$(lbl 󰂯 "Open bluetui")" bt_tui
		return
	fi
	if [[ $BT_POW != true ]]; then
		MESG="Bluetooth is off"
		row "$(lbl 󰂯 "Turn Bluetooth on")" bt_power on
		row "$(lbl 󰂳 "Open bluetui")" bt_tui
		return
	fi
	MESG="$(bt_status)"
	local mac name icon paired conn
	while IFS=$'\t' read -r mac name icon paired conn; do
		[[ $paired == true ]] || continue
		row "$(lbl "$(bt_icon "$icon")" "$(esc "$name")" "$([[ $conn == true ]] && echo connected)")" \
			bt_toggle "$mac" "$name" "$conn"
	done < <(bt_devices)
	row "$(lbl 󰐕 "Pair new device")" bt_scan
	row "$(lbl 󰆴 "Forget device…")" bt_forget_menu
	row "$(lbl 󰂳 "Open bluetui")" bt_tui
	row "$(lbl 󰂲 "Turn Bluetooth off")" bt_power off # внизу: не под курсором при открытии
}

bt_tui() { term bluetui bluetui; }

bt_power() { # on|off
	[[ $1 == on ]] && rfkill unblock bluetooth 2>/dev/null
	bluetoothctl power "$1" >/dev/null
}

bt_toggle() { # MAC имя подключено
	if [[ $3 == true ]]; then
		bluetoothctl disconnect "$1" >/dev/null && notify "Bluetooth" "Disconnected: $2"
	else
		busy "Bluetooth" "Connecting to $2…"
		if bluetoothctl connect "$1" >/dev/null; then
			notify "Bluetooth" "Connected: $2"
		else
			notify -u critical "Bluetooth" "Could not connect to $2"
		fi
	fi
}

# Поиск 8 с, затем список новых устройств → pair + trust + connect.
bt_scan() {
	busy "Bluetooth" "Searching for devices (8 s)…"
	bluetoothctl --timeout 8 scan on >/dev/null 2>&1
	bt_load || return 1
	local keep=$SEL mac name icon paired conn
	ROWS=() ACTS=() SEL=0
	while IFS=$'\t' read -r mac name icon paired conn; do
		[[ $paired == true ]] && continue
		row "$(lbl "$(bt_icon "$icon")" "$(esc "$name")" "$mac")" bt_pair "$mac" "$name"
	done < <(bt_devices)
	notify "Bluetooth" "New devices found: ${#ROWS[@]}"
	pick "New devices" "Put the device into pairing mode" || true
	SEL=$keep
}

bt_pair() { # MAC имя
	busy "Bluetooth" "Pairing with $2…"
	if bluetoothctl pair "$1" >/dev/null && bluetoothctl trust "$1" >/dev/null &&
		bluetoothctl connect "$1" >/dev/null; then
		notify "Bluetooth" "Paired and connected: $2"
	else
		notify -u critical "Bluetooth" "Failed: $2 (try bluetui)"
	fi
}

bt_forget_menu() {
	local keep=$SEL mac name icon paired conn
	ROWS=() ACTS=() SEL=0
	while IFS=$'\t' read -r mac name icon paired conn; do
		[[ $paired == true ]] || continue
		row "$(lbl "$(bt_icon "$icon")" "$(esc "$name")" "$mac")" bt_forget "$mac" "$name"
	done < <(bt_devices)
	pick "Forget device" || true
	SEL=$keep
}

bt_forget() { # MAC имя
	confirm "Forget “$(esc "$2")”?" || return 0
	bluetoothctl remove "$1" >/dev/null && notify "Bluetooth" "Forgotten: $2"
}
