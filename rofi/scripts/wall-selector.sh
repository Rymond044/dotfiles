#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Выбор обоев с превью через Rofi
# -----------------------------------------------------------------------------
set -euo pipefail

WALL_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/wall-previews"
THEME_SCRIPT="$HOME/.config/binc/wallust-swww"
ROFI_THEME="$HOME/.config/rofi/scripts/wallpapers.rasi"

mkdir -p "$CACHE_DIR"

# Проверка зависимостей
command -v convert >/dev/null 2>&1 || { echo "Ошибка: ImageMagick не установлен." >&2; exit 1; }
command -v rofi    >/dev/null 2>&1 || { echo "Ошибка: Rofi не установлен." >&2; exit 1; }

# Генерация превью (если нет)
shopt -s nullglob
wall_files=("$WALL_DIR"/*.{jpg,jpeg,png,webp})
shopt -u nullglob

if [[ ${#wall_files[@]} -eq 0 ]]; then
    echo "В $WALL_DIR нет подходящих изображений." >&2
    exit 0
fi

pids=()
for wall in "${wall_files[@]}"; do
    [[ -e "$wall" ]] || continue
    filename="${wall##*/}"
    [[ "$filename" == "current.jpg" ]] && continue

    preview="$CACHE_DIR/$filename"
    if [[ ! -f "$preview" ]]; then
        convert "$wall" -thumbnail 200x200^ -gravity center -extent 200x200 "$preview" &
        pids+=($!)
    fi
done
[[ ${#pids[@]} -gt 0 ]] && wait "${pids[@]}"

# Формируем список для Rofi
list_walls() {
    for wall in "${wall_files[@]}"; do
        [[ -e "$wall" ]] || continue
        filename="${wall##*/}"
        [[ "$filename" == "current.jpg" ]] && continue
        echo -en "${filename}\0icon\x1f$CACHE_DIR/$filename\n"
    done
}

selected=$(list_walls | rofi -dmenu -p "Wallpapers:" -theme "$ROFI_THEME")

if [[ -n "$selected" ]]; then
    bash "$THEME_SCRIPT" "$WALL_DIR/$selected"
fi
