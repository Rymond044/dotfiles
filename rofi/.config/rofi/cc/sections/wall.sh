# Обои: выбор с превью (позже — селектор из задачи 4) и случайные.
WALLS=~/Wallpapers

wall_rows() {
	TITLE=Wallpaper
	row "$(lbl 󰸉 "Choose wallpaper")" launch ~/.config/rofi/scripts/wall-selector.sh
	row "$(lbl 󰒝 "Random wallpaper")" wall_random
}

wall_random() {
	local f
	f=$(find "$WALLS" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\|webp\|gif\)' | shuf -n1)
	[[ -n $f ]] || { notify "Wallpaper" "No images in $WALLS"; return 1; }
	launch ~/.config/binc/wallust-swww "$f"
}
