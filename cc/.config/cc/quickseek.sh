# Control center как плагин quickseek (протокол — ~/Apps/quickseek/docs/plugins.md).
#   cc quickseek list      разделы (папки) и их строки — из тех же РАЗДЕЛ_rows, JSON lines
#   cc quickseek run ID    выполнить действие; ID — JSON-массив «функция аргументы…»
# pick → вложенное меню, ask → запрос ввода (ответ в $QUICKSEEK_INPUT),
# confirm → меню Yes/No, launch → закрыть окно. Ответы протокола — в fd 3, вывод действий — в /dev/null.
CC_QS=1
RS=$'\x1e'

declare -A SEC_KEYWORDS=([wifi]="wireless network internet wlan" [bt]="bluetooth headphones devices"
	[audio]="audio volume speakers output microphone" [toggles]="night light touchpad dnd caffeine"
	[monitors]="displays screens" [power]="battery profile charge fan" [system]="packages update install"
	[utils]="screenshot ocr clipboard color picker" [appearance]="wallpaper theme dark light glass")

esc() { printf '%s' "$1"; }
lbl() { printf '%s%s%s%s%s' "$1" "$RS" "$2" "$RS" "${3:-}"; }

# Строки «родитель RS иконка RS текст RS статус RS id RS папка RS ключевые слова» → JSON lines
qs_json() {
	jq -cR 'split("\u001e") as $f
		| {title: $f[2], icon: $f[1], status: ($f[3] // "")}
		+ (if ($f[0] // "") != "" then {parent: $f[0]} else {} end)
		+ (if $f[5] == "1" then {id: $f[4], folder: true, keywords: ($f[6] // "")}
		   elif $f[5] == "back" then {id: "", action: "back"}
		   else {id: ($f[4] | split("\u001f") | tojson)} end)'
}

# ROWS/ACTS → строки для qs_json
qs_rows() { # РОДИТЕЛЬ
	local i
	for i in "${!ROWS[@]}"; do printf '%s%s%s%s%s%s\n' "$1" "$RS" "${ROWS[i]}" "$RS" "${ACTS[i]}" "$RS"; done
}

qs_list() {
	local tmp s
	tmp=$(mktemp -d)
	WIFI_SCANNED=1 # не сканировать при каждом открытии, есть Rescan
	for s in "${SECTIONS[@]}"; do
		(
			ROWS=() ACTS=() TITLE= MESG=
			printf '%s%s%s%s%s%s%s%s%s%s1%s%s\n' "" "$RS" "${SEC_ICON[$s]}" "$RS" "${SEC_NAME[$s]}" "$RS" \
				"$(sec_status "$s" 2>/dev/null)" "$RS" "$s" "$RS" "$RS" "${SEC_KEYWORDS[$s]:-}"
			"${s}_rows" >/dev/null 2>&1
			qs_rows "$s"
		) >"$tmp/$s" &
	done
	wait
	for s in "${SECTIONS[@]}"; do cat "$tmp/$s"; done | qs_json
	rm -rf "$tmp"
}

pick() { # ЗАГОЛОВОК — вложенное меню; 1 — чтобы вызвавший остановился, как после Esc
	{
		jq -cn --arg t "$1" '{type: "menu", title: $t}'
		qs_rows "" | qs_json
	} >&3
	return 1
}

ask() { # ЗАГОЛОВОК СООБЩЕНИЕ [-password]
	if [[ -v QUICKSEEK_INPUT ]]; then
		printf '%s' "$QUICKSEEK_INPUT"
		return 0
	fi
	jq -cn --arg t "$1" --arg m "$2" --arg id "$QS_ID" --argjson p "$([[ ${3:-} == -password ]] && echo true || echo false)" \
		'{type: "prompt", title: $t, message: $m, password: $p, id: $id}' >&3
	return 1
}

confirm() { # ВОПРОС
	[[ ${QS_CONFIRMED:-} ]] && return 0
	jq -cn --arg t "$1" '{type: "menu", title: $t}' >&3
	{
		printf '%s%s%s%s%s\n' "" "$RS" "$(lbl 󰄬 Yes)" "$RS" "!$US$QS_ACT"
		printf '%s%s%s%s%s%s\n' "" "$RS" "$(lbl 󰜺 No)" "$RS" "" "${RS}back"
	} | qs_json >&3
	return 1
}

# Отдельный scope uwsm: иначе приложение живёт в юните quickseek и умрёт вместе с ним
launch() {
	if command -v uwsm >/dev/null; then
		setsid -f uwsm app -- "$@" >/dev/null 2>&1 </dev/null
	else
		setsid -f "$@" >/dev/null 2>&1 </dev/null
	fi
	close_menu
}

close_menu() {
	echo '{"type":"close"}' >&3
	exit 0
}

qs_run() { # ID
	local -a args
	mapfile -d '' -t args < <(jq -j '.[] | . + "\u0000"' <<<"$1")
	if [[ ${args[0]:-} == '!' ]]; then
		QS_CONFIRMED=1
		args=("${args[@]:1}")
	fi
	[[ ${args[0]:-} ]] && declare -F "${args[0]}" >/dev/null || { echo "cc: unknown action: $1" >&2; return 2; }
	QS_ID=$(jq -cn '$ARGS.positional' --args "${args[@]}")
	local IFS=$US
	QS_ACT="${args[*]}"
	unset IFS
	CC_SECTION=${args[0]%%_*}
	# Состояние раздела (WIFI_OBJS, BT_OBJS) действию нужно загрузить заново
	declare -F "${CC_SECTION}_load" >/dev/null && "${CC_SECTION}_load" >/dev/null 2>&1
	"${args[@]}" 3>&1 >/dev/null
}

qs_main() {
	case ${1:-} in
	list) qs_list ;;
	run) qs_run "${2:?id}" ;;
	*) echo "usage: cc quickseek list | run ID" >&2; return 2 ;;
	esac
}
