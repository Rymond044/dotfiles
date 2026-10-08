# Утилиты: скриншоты (hyprcapture), OCR, буфер обмена, пипетка.
# Действия с выделением запускаются с паузой — сначала должно исчезнуть само меню.

utils_rows() {
	TITLE=Utilities
	row "$(lbl 󰩭 "Screenshot" "region / window")" utils_capture
	row "$(lbl 󰹑 "Screenshot full screen")" utils_capture fullscreen
	row "$(lbl 󰊄 "Text from screen" "OCR → clipboard")" launch sh -c 'sleep 0.3; exec ~/.config/binc/ocr'
	row "$(lbl 󰅌 "Clipboard history" clipse)" utils_clipboard
	row "$(lbl 󰈊 "Color picker" "→ clipboard")" utils_picker
}

utils_capture() { # [режим hyprcapture]
	launch sh -c "sleep 0.3; exec hyprctl dispatch \"(function() hl.plugin.hyprcapture.open(${1:+'$1'}) return hl.dsp.no_op() end)()\""
}

utils_clipboard() {
	hyprctl dispatch "hl.dsp.exec_cmd('[float; size 900 550; center] kitty -e clipse')" >/dev/null
	exit 0
}

utils_picker() {
	command -v hyprpicker >/dev/null || { notify "Color picker" "hyprpicker is not installed"; return 1; }
	launch sh -c 'sleep 0.3; c=$(hyprpicker -a) && notify-send -t 3000 "Color picker" "$c copied"'
}
