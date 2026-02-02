#!/bin/bash
current_profile=$(powerprofilesctl get)

case "$current_profile" in
    "performance")
        performance_text="Performance ✓"
        balanced_text="Balanced"
        powersaver_text="Power Saver"
        ;;
    "balanced")
        performance_text="Performance"
        balanced_text="Balanced ✓"
        powersaver_text="Power Saver"
        ;;
    "power-saver")
        performance_text="Performance"
        balanced_text="Balanced"
        powersaver_text="Power Saver ✓"
        ;;
    *)
        performance_text="Performance"
        balanced_text="Balanced"
        powersaver_text="Power Saver"
        ;;
esac

choice=$(printf "%s\n%s\n%s" "$performance_text" "$balanced_text" "$powersaver_text" | \
    rofi -dmenu -p "Power Mode" -markup -markup-rows \
    -theme ~/.config/waybar/scripts/power-profiles.rasi)

choice_clean=$(echo "$choice" | sed 's/\*//g')

case "$choice_clean" in
    *Performance*)
        powerprofilesctl set performance
        notify-send -t 2000 "Power Profile" "Set to Performance"
        ;;
    *Balanced*)
        powerprofilesctl set balanced
        notify-send -t 2000 "Power Profile" "Set to Balanced"
        ;;
    *Power\ Saver*)
        powerprofilesctl set power-saver
        notify-send -t 2000 "Power Profile" "Set to Power Saver"
        ;;
esac
