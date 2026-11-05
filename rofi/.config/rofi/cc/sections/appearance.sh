# Внешний вид: обои (выбиралка на Quickshell — quickshell/.config/quickshell/walls, бэкенд binc/walls),
# светлая/тёмная тема (binc/theme) и стекло (binc/glass).
# Тема: глобальный режим (Auto / Always light / Always dark) главнее пометки обоев (Auto / Light / Dark),
# пометка — главнее автоопределения по яркости обоев.
WALLS=~/Wallpapers
THEME_BIN=~/.config/binc/theme

# appearance_get КЛЮЧ — поле из `theme status` (mode, source, global, wallpaper, auto, lightness…)
appearance_get() { "$THEME_BIN" status | awk -F'\t' -v k="$1" '$1 == k { print $2 }'; }

appearance_status() {
	local mode
	mode=$(appearance_get mode)
	printf '%s' "${mode^}"
	[[ $(~/.config/binc/glass status) == on ]] && printf ' · glass'
	return 0
}

appearance_rows() {
	TITLE=Appearance
	local st mode wall glob
	st=$("$THEME_BIN" status)
	mode=$(awk -F'\t' '$1 == "mode" { print $2 }' <<<"$st")
	wall=$(awk -F'\t' '$1 == "wallpaper" { print $2 }' <<<"$st")
	glob=$(awk -F'\t' '$1 == "global" { print $2 }' <<<"$st")
	MESG="Theme: ${mode^}"
	row "$(lbl 󰸉 "Choose wallpaper…")" launch qs -c walls -n
	row "$(lbl 󰒝 "Random wallpaper")" appearance_random
	row "$(lbl 󰔎 "This wallpaper: ${wall^}")" appearance_wall_menu
	if [[ $glob == auto ]]; then
		row "$(lbl 󰏘 "Global mode: Auto")" appearance_global_menu
	else
		row "$(lbl 󰏘 "Global mode: Always ${glob}")" appearance_global_menu
	fi
	row "$(lbl 󰂵 "Liquid glass" "$([[ $(~/.config/binc/glass status) == on ]] && echo on || echo off)")" \
		appearance_glass
}

# Метка «●» у текущего варианта
appearance_mark() { [[ $1 == "$2" ]] && printf ' ●'; return 0; }

appearance_wall_menu() {
	local cur keep=$SEL
	cur=$(appearance_get wallpaper)
	ROWS=() ACTS=() SEL=0
	row "$(lbl 󰔎 "Auto$(appearance_mark auto "$cur")")" appearance_wall auto
	row "$(lbl 󰖨 "Light$(appearance_mark light "$cur")")" appearance_wall light
	row "$(lbl 󰖔 "Dark$(appearance_mark dark "$cur")")" appearance_wall dark
	pick "This wallpaper" "Theme for the current wallpaper (remembered)" || true
	SEL=$keep
}

appearance_global_menu() {
	local cur keep=$SEL
	cur=$(appearance_get global)
	ROWS=() ACTS=() SEL=0
	row "$(lbl 󰔎 "Auto$(appearance_mark auto "$cur")")" appearance_global auto
	row "$(lbl 󰖨 "Always light$(appearance_mark light "$cur")")" appearance_global light
	row "$(lbl 󰖔 "Always dark$(appearance_mark dark "$cur")")" appearance_global dark
	pick "Global mode" "Overrides every wallpaper while not Auto" || true
	SEL=$keep
}

# Действия (их же можно звать без rofi: cc appearance wall light, cc appearance global auto)
appearance_wall() { "$THEME_BIN" wall "${1:-cycle}"; }
appearance_global() { "$THEME_BIN" set "${1:-cycle}"; }
appearance_glass() { ~/.config/binc/glass; }

appearance_random() {
	local f
	f=$(find "$WALLS" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\|webp\|gif\)' | shuf -n1)
	[[ -n $f ]] || { notify "Wallpaper" "No images in $WALLS"; return 1; }
	launch ~/.config/binc/wallust-swww "$f"
}
