# Wi-Fi через iwd по D-Bus (busctl). Пользователь в wheel — политика iwd разрешает без sudo.
IWD=net.connman.iwd

# Загружает состояние: WDEV (путь устройства), WIFNAME, WPOW (true/false), WSTATE, WSSID.
wifi_load() {
	WIFI_OBJS=$(busctl --system --json=short call $IWD / org.freedesktop.DBus.ObjectManager \
		GetManagedObjects 2>/dev/null | jq '.data[0]') || return 1
	IFS=$'\t' read -r WDEV WIFNAME WPOW WSTATE WSSID < <(jq -r '
		. as $o | to_entries[] | select(.value["net.connman.iwd.Device"]) | .value as $v
		| [.key, $v["net.connman.iwd.Device"].Name.data, $v["net.connman.iwd.Device"].Powered.data,
		   ($v["net.connman.iwd.Station"].State.data // "off"),
		   ($o[$v["net.connman.iwd.Station"].ConnectedNetwork.data // ""]["net.connman.iwd.Network"].Name.data // "")]
		| @tsv' <<<"$WIFI_OBJS" | head -1)
	[[ -n ${WDEV:-} ]]
}

wifi_status() {
	wifi_load || { echo "no device"; return; }
	if [[ $WPOW != true ]]; then echo "off"
	elif [[ $WSTATE == connected ]]; then esc "$WSSID"
	else echo "$WSTATE" | sed 's/disconnected/not connected/'
	fi
}

# Сети по убыванию сигнала: путь, имя, сигнал %, тип, известная (0/1), подключена (true/false).
wifi_networks() {
	local ord
	ord=$(busctl --system --json=short call $IWD "$WDEV" $IWD.Station GetOrderedNetworks 2>/dev/null |
		jq '.data[0]') || return
	jq -r --argjson ord "$ord" '. as $o | $ord[] | .[0] as $p | $o[$p]["net.connman.iwd.Network"] as $n
		| select($n)
		| [$p, ($n.Name.data | gsub("[\t\n]"; " ")),
		   ((.[1] / 100 + 100) * 2 | if . > 100 then 100 elif . < 0 then 0 else floor end),
		   $n.Type.data, (if $n.KnownNetwork then 1 else 0 end), $n.Connected.data] | @tsv' <<<"$WIFI_OBJS"
}

wifi_list() { wifi_load && wifi_networks; }

wifi_rows() {
	TITLE=Wi-Fi
	if ! wifi_load; then
		MESG="iwd is not responding"
		row "$(lbl 󰖩 "Open impala")" wifi_impala
		return
	fi
	if [[ $WPOW != true ]]; then
		MESG="Wi-Fi is off"
		row "$(lbl 󰖩 "Turn Wi-Fi on")" wifi_power on
		row "$(lbl 󱚾 "Open impala")" wifi_impala
		return
	fi
	MESG=$([[ $WSTATE == connected ]] && esc "Connected: $WSSID" || echo "Not connected")
	# Свежий скан в фоне: список ниже — с прошлого скана, «Обновить» покажет новый.
	[[ ${WIFI_SCANNED:-} ]] || { busctl --system call $IWD "$WDEV" $IWD.Station Scan >/dev/null 2>&1 & WIFI_SCANNED=1; }
	row "$(lbl 󰑐 "Rescan")" wifi_scan
	local path name sig type known conn icon note
	while IFS=$'\t' read -r path name sig type known conn; do
		if ((sig >= 75)); then icon=󰤨; elif ((sig >= 50)); then icon=󰤥; elif ((sig >= 25)); then icon=󰤢; else icon=󰤟; fi
		note="$sig %"
		[[ $type == open ]] || note+=" · 󰌾"
		((known)) && note+=" · saved"
		[[ $conn == true ]] && note="connected · $note"
		row "$(lbl "$icon" "$(esc "$name")" "$note")" wifi_net "$path" "$name" "$type" "$known" "$conn"
	done < <(wifi_networks)
	row "$(lbl 󱚾 "Open impala")" wifi_impala
	row "$(lbl 󰖪 "Turn Wi-Fi off")" wifi_power off # внизу: не под курсором при открытии
}

wifi_power() { # on|off|toggle
	wifi_load || return 1
	local v=$1
	[[ $v == toggle ]] && { [[ $WPOW == true ]] && v=off || v=on; }
	busctl --system set-property $IWD "$WDEV" $IWD.Device Powered b "$([[ $v == on ]] && echo true || echo false)"
}

wifi_impala() { term impala impala; }

wifi_scan() {
	wifi_load || return 1
	busy "Wi-Fi" "Scanning…"
	busctl --system call $IWD "$WDEV" $IWD.Station Scan >/dev/null 2>&1
	sleep 3 # Scan асинхронный, результаты приходят за 2–3 с
	notify "Wi-Fi" "Network list updated"
}

# Выбор сети: подключённая → меню отключения; известная/открытая → подключить; новая PSK → пароль.
wifi_net() { # путь имя тип известная подключена
	local path=$1 name=$2 type=$3 known=$4 conn=$5
	if [[ $conn == true ]]; then
		local keep=$SEL
		ROWS=() ACTS=() SEL=0
		row "$(lbl 󰖪 Disconnect)" wifi_disconnect
		row "$(lbl 󰆴 "Forget network")" wifi_forget "$name"
		pick "$(esc "$name")" || true
		SEL=$keep
		return
	fi
	if ((known)) || [[ $type == open ]]; then
		wifi_connect "$name"
	elif [[ $type == psk ]]; then
		local pw
		pw=$(ask "Password" "Network “$(esc "$name")”" -password) || return 0
		[[ -n $pw ]] || return 0
		wifi_connect "$name" "$pw"
	else
		notify "Wi-Fi" "$type network — connect via impala"
		wifi_impala
	fi
}

wifi_connect() { # имя [пароль]
	wifi_load || return 1
	busy "Wi-Fi" "Connecting to $1…"
	local out
	if out=$(iwctl ${2:+--passphrase "$2"} station "$WIFNAME" connect "$1" 2>&1); then
		notify "Wi-Fi" "Connected: $1"
	else
		notify -u critical "Wi-Fi" "Could not connect to $1${out:+: $out}"
		return 1
	fi
}

wifi_disconnect() {
	wifi_load || return 1
	busctl --system call $IWD "$WDEV" $IWD.Station Disconnect && notify "Wi-Fi" "Disconnected"
}

wifi_forget() { # имя
	confirm "Forget “$(esc "$1")”?" || return 0
	local known
	known=$(jq -r --arg n "$1" 'to_entries[] | select(.value["net.connman.iwd.KnownNetwork"].Name.data == $n) | .key' \
		<<<"$WIFI_OBJS" | head -1)
	[[ -n $known ]] || { notify "Wi-Fi" "“$1” is not a saved network"; return 1; }
	busctl --system call $IWD "$known" $IWD.KnownNetwork Forget && notify "Wi-Fi" "Forgotten: $1"
}
