#!/usr/bin/env bash

# Пути
WALL_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/wall-previews"
THEME_SCRIPT="$HOME/.config/binc/wallust-swww"

mkdir -p "$CACHE_DIR"

# Генерируем превью (требуется imagemagick)
for wall in "$WALL_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -e "$wall" ] || continue
    filename=$(basename "$wall")

    # Пропускаем файл с названием "current"
    if [[ "$filename" == "current.jpg" ]]; then
        continue
    fi

    if [ ! -f "$CACHE_DIR/$filename" ]; then
        # Делаем квадратное превью 200x200
        convert "$wall" -thumbnail 200x200^ -gravity center -extent 200x200 "$CACHE_DIR/$filename" &
    fi
done
wait

# Формируем список для Rofi
list_walls() {
    for wall in "$WALL_DIR"/*.{jpg,jpeg,png,webp}; do
        [ -e "$wall" ] || continue
        filename=$(basename "$wall")

        # Исключаем current.jpg из вывода в Rofi
        if [[ "$filename" != "current.jpg" ]]; then
            echo -en "$filename\0icon\x1f$CACHE_DIR/$filename\n"
        fi
    done
}

# Запуск Rofi
selected=$(list_walls | rofi -dmenu -p "Wallpapers:" -theme "$HOME/.config/rofi/scripts/wallpapers.rasi")

if [ -n "$selected" ]; then
    bash "$THEME_SCRIPT" "$WALL_DIR/$selected"
fi
