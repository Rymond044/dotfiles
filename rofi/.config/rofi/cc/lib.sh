# Общие функции control center (подключается из ./cc).
#
# Строка меню = подпись (pango) + действие. Действие хранится как функция и аргументы,
# разделённые \x1f, и вызывается напрямую, без eval: в аргументах бывают SSID и имена
# устройств — чужие строки.

THEME="$CC_DIR/cc.rasi"
US=$'\x1f'

ROWS=() ACTS=() SEL=0

# row ПОДПИСЬ ФУНКЦИЯ [АРГ…]
row() {
	ROWS+=("$1")
	local IFS=$US
	ACTS+=("${*:2}")
}

# Экранирование для pango-разметки.
esc() {
	local s=${1//&/&amp;}
	s=${s//</&lt;}
	printf '%s' "${s//>/&gt;}"
}

# lbl ИКОНКА ТЕКСТ [СТАТУС] — текст уже экранирован; статус приглушённым справа.
lbl() {
	printf '%s   %s' "$1" "$2"
	[[ -n ${3:-} ]] && printf '   <span alpha="55%%">%s</span>' "$3"
	return 0
}

# pick ЗАГОЛОВОК [СООБЩЕНИЕ] — показать ROWS, выполнить действие выбранной строки.
# 1 — Esc (назад). Ошибка действия меню не закрывает: о ней сообщает само действие.
pick() {
	local idx n=${#ROWS[@]} args
	((n)) || return 1
	idx=$(printf '%s\n' "${ROWS[@]}" | rofi -dmenu -i -markup-rows -no-custom -format i \
		-p "$1" ${2:+-mesg "$2"} -selected-row "$SEL" -theme "$THEME" \
		-theme-str "listview { lines: $((n < 12 ? n : 12)); }") || return 1
	[[ $idx =~ ^[0-9]+$ ]] || return 1
	SEL=$idx
	IFS=$US read -r -a args <<<"${ACTS[idx]}"
	[[ ${args[0]:-} ]] || return 0
	"${args[@]}" || true
}

# ask ЗАГОЛОВОК СООБЩЕНИЕ [-password] — строка ввода, результат в stdout.
ask() {
	rofi -dmenu -p "$1" -mesg "$2" ${3:+"$3"} -theme "$THEME" \
		-theme-str 'listview { enabled: false; }' </dev/null
}

# confirm ВОПРОС — да/нет.
confirm() {
	local a
	a=$(printf '%s\n' "󰄬   Yes" "󰜺   No" | rofi -dmenu -i -no-custom -format i -p "$1" \
		-theme "$THEME" -theme-str 'listview { lines: 2; }') || return 1
	[[ $a == 0 ]]
}

# Запустить программу отдельно от меню и закрыть control center.
launch() {
	setsid -f "$@" >/dev/null 2>&1 </dev/null
	exit 0
}

# term КЛАСС КОМАНДА… — TUI в kitty (классы с оконными правилами — hypr/lua/windowrules.lua).
term() {
	launch kitty --class "$1" -e "${@:2}"
}

# Lua-выражение в Hyprland, без возврата диспетчера.
hl_run() {
	hyprctl dispatch "(function() $1 return hl.dsp.no_op() end)()" >/dev/null
}

notify() {
	notify-send -t 2000 -h "string:x-canonical-private-synchronous:cc-${CC_SECTION:-main}" "$@"
}

# Долгая операция (подключение и т. п.): уведомление сразу, результат заменит его тем же notify.
busy() {
	notify-send -t 15000 -h "string:x-canonical-private-synchronous:cc-${CC_SECTION:-main}" "$1" "${2:-…}"
}
