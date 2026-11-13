# Общие функции control center (подключается из ./cc).
#
# Строка меню = подпись + действие. Действие хранится как функция и аргументы,
# разделённые \x1f, и вызывается напрямую, без eval: в аргументах бывают SSID и имена
# устройств — чужие строки.

US=$'\x1f'

ROWS=() ACTS=() SEL=0

# row ПОДПИСЬ ФУНКЦИЯ [АРГ…]
row() {
	ROWS+=("$1")
	local IFS=$US
	ACTS+=("${*:2}")
}

# Подпись строки. Для quickseek их переопределяет quickseek.sh (поля через \x1e).
esc() { printf '%s' "$1"; }
lbl() { printf '%s   %s%s' "$1" "$2" "${3:+   $3}"; }

# Меню, ввод и подтверждение есть только в quickseek (quickseek.sh). Действие, которому они
# нужны, из командной строки не выполняется.
pick() { echo "cc: '${1:-menu}' needs quickseek: cc ${CC_SECTION:-}" >&2; return 1; }
ask() { echo "cc: '$1' needs input, use quickseek" >&2; return 1; }
confirm() { echo "cc: '$1' needs confirmation, use quickseek" >&2; return 1; }

# Запустить программу отдельно от меню и закрыть control center.
launch() {
	setsid -f "$@" >/dev/null 2>&1 </dev/null
	exit 0
}

# Закрыть control center (действие само запустило что-то в Hyprland)
close_menu() { exit 0; }

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
