# Система: пакеты (бывший rofi/applets/bin/apps.sh), обновление, конфиги.
BINC=~/.config/binc

system_rows() {
	TITLE=System
	MESG="Packages: $(pacman -Qq | wc -l) · AUR: $(pacman -Qqm | wc -l)"
	row "$(lbl 󰚰 "Update system")" term install sh -c 'yay -Syu; echo; read -rp "Press Enter to close"'
	row "$(lbl 󰏗 "Install package")" term install "$BINC/pkg_install.sh"
	row "$(lbl 󰣇 "Install from AUR")" term install "$BINC/pkg_aur_install.sh"
	row "$(lbl 󰆴 "Remove package")" term install "$BINC/pkg_remove.sh"
	row "$(lbl 󰷈 "Edit dotfiles")" launch zeditor ~/dotfiles
	row "$(lbl 󰍛 "Resource monitor")" term btop btop
}
