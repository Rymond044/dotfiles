# Система: пакеты (бывший rofi/applets/bin/apps.sh), обновление, конфиги, снапшот.
BINC=~/.config/binc

system_rows() {
	TITLE=System
	MESG="Packages: $(pacman -Qq | wc -l) · AUR: $(pacman -Qqm | wc -l)"
	row "$(lbl 󰚰 "Update system" "yay -Syu")" term install sh -c 'yay -Syu; echo; read -rp "Press Enter to close"'
	row "$(lbl 󰏗 "Install package")" term install "$BINC/pkg_install.sh"
	row "$(lbl 󰣇 "Install from AUR")" term install "$BINC/pkg_aur_install.sh"
	row "$(lbl 󰆴 "Remove package")" term install "$BINC/pkg_remove.sh"
	row "$(lbl 󰷈 "Edit dotfiles" "~/dotfiles")" launch zeditor ~/dotfiles
	row "$(lbl 󰍛 "Resource monitor" btop)" term btop btop
	row "$(lbl 󰆓 "Snapper snapshot" root)" term install sh -c \
		'sudo snapper -c root create -d "manual (control center)" && snapper -c root list | tail -5; echo; read -rp "Press Enter to close"'
}
