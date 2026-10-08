# Переключатели: ночной свет, тачпад, «Не беспокоить», «Не засыпать».
# «Не засыпать» — systemd-блокировка idle в юните cc-caffeine: hypridle её видит
# («systemd idle inhibit active») и не гасит/не блокирует/не усыпляет. Крышку не трогает.

toggles_night() {
	local t
	t=$(hyprctl hyprsunset temperature 2>/dev/null)
	[[ $t =~ ^[0-9]+$ ]] && ((t < 6000))
}
toggles_touchpad_off() { [[ -e ${XDG_RUNTIME_DIR:-/tmp}/hypr-touchpad-disabled ]]; }
toggles_dnd() { [[ $(swaync-client -D 2>/dev/null) == true ]]; }
toggles_caffeine() { systemctl --user -q is-active cc-caffeine.service; }

toggles_status() {
	local on=()
	toggles_night && on+=("night light")
	toggles_touchpad_off && on+=("touchpad off")
	toggles_dnd && on+=("DND")
	toggles_caffeine && on+=("keep awake")
	local IFS=,
	echo "${on[*]}" | sed 's/,/, /g'
}

# Подпись: ИКОНКА ТЕКСТ ВКЛЮЧЕНО(0/1)
toggles_row() {
	row "$(lbl "$1" "$2" "$( (($3)) && echo on || echo off)")" "${@:4}"
}

toggles_rows() {
	TITLE=Toggles
	toggles_row 󰖔 "Night light" "$(toggles_night && echo 1 || echo 0)" toggles_toggle night
	toggles_row 󰟸 "Touchpad" "$(toggles_touchpad_off && echo 0 || echo 1)" toggles_toggle touchpad
	toggles_row 󰂛 "Do not disturb" "$(toggles_dnd && echo 1 || echo 0)" toggles_toggle dnd
	toggles_row 󰅶 "Keep awake" "$(toggles_caffeine && echo 1 || echo 0)" toggles_toggle caffeine
}

toggles_toggle() { # night|touchpad|dnd|caffeine
	case $1 in
	night) ~/.config/binc/nightlight ;;
	touchpad) ~/.config/binc/touchpad_toggle ;;
	dnd) swaync-client -d >/dev/null ;;
	caffeine)
		if toggles_caffeine; then
			systemctl --user stop cc-caffeine.service
			notify "Keep awake" "off"
		else
			systemd-run --user --quiet --unit cc-caffeine --description "Control center: keep awake" \
				systemd-inhibit --what=idle --who="control center" --why="Keep awake" sleep infinity
			notify "Keep awake" "on: no screen off, lock or sleep on idle"
		fi
		;;
	*) return 2 ;;
	esac
}
