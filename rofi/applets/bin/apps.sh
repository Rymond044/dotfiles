#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Github  : @adi1090x
#
## Applets : Favorite Applications

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
prompt='Applications'
mesg="Installed Packages : `pacman -Q | wc -l` (pacman)"

if [[ ( "$theme" == *'type-1'* ) || ( "$theme" == *'type-3'* ) || ( "$theme" == *'type-5'* ) ]]; then
	list_col='1'
	list_row='8'
elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
	list_col='8'
	list_row='1'
fi

# CMDs (add your apps here)

install_pkg='hyprctl dispatch exec "[float; size 1300 750; center] kitty -e .config/binc/pkg_install.sh"'
install_pkg_aur='hyprctl dispatch exec "[float; size 1300 750; center] kitty -e .config/binc/pkg_aur_install.sh"'
remove_pkg='hyprctl dispatch exec "[float; size 1300 750; center] kitty -e .config/binc/pkg_remove.sh"'
edit_configs='zeditor ~/.config/'
switch_wallpapers="$HOME/.config/rofi/scripts/wall-selector.sh"
term_cmd='kitty'
file_cmd='nautilus'
web_cmd='chromium'

# Options
layout=`cat ${theme} | grep 'USE_ICON' | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
	option_1=" Install package <span weight='light' size='small'></span>"
	option_2="󰣇 Install package (AUR) <span weight='light' size='small'></span>"
	option_3=" Remove package <span weight='light' size='small'></span>"
	option_4=" Edit configs <span weight='light' size='small'></span>"
	option_5=" Switch wallpapers <span weight='light' size='small'></span>"
	option_6=" Launch TTY <span weight='light' size='small'></span>"
	option_7=" Launch file manager <span weight='light' size='small'></span>"
	option_8=" Launch browser <span weight='light' size='small'></span>"
else
	option_1=""
	option_2="󰣇"
	option_3=""
	option_4=""
	option_5=""
	option_6=""
	option_7=""
	option_8=""
fi

# Rofi CMD
rofi_cmd() {
	rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		-markup-rows \
		-theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6\n$option_7\n$option_8" | rofi_cmd
}

# Execute Command
run_cmd() {
	if [[ "$1" == '--opt1' ]]; then
		eval ${install_pkg}
	elif [[ "$1" == '--opt2' ]]; then
		eval ${install_pkg_aur}
	elif [[ "$1" == '--opt3' ]]; then
		eval ${remove_pkg}
	elif [[ "$1" == '--opt4' ]]; then
		eval ${edit_configs}
	elif [[ "$1" == '--opt5' ]]; then
	    eval ${switch_wallpapers}
	elif [[ "$1" == '--opt6' ]]; then
		eval ${term_cmd}
	elif [[ "$1" == '--opt7' ]]; then
		eval ${file_cmd}
	elif [[ "$1" == '--opt8' ]]; then
	    eval ${web_cmd}
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $option_1)
		run_cmd --opt1
        ;;
    $option_2)
		run_cmd --opt2
        ;;
    $option_3)
		run_cmd --opt3
        ;;
    $option_4)
		run_cmd --opt4
        ;;
    $option_5)
		run_cmd --opt5
        ;;
    $option_6)
		run_cmd --opt6
        ;;
    $option_7)
        run_cmd --opt7
        ;;
    $option_8)
        run_cmd --opt8
        ;;
esac
