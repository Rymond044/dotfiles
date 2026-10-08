# Питание: единый режим (ppd + EC, ~/.config/binc/power-mode), порог заряда, Cooler Boost.
PM=~/.config/binc/power-mode
EC=/sys/devices/platform/msi-ec

power_profile() {
  busctl --system get-property org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles \
    org.freedesktop.UPower.PowerProfiles ActiveProfile 2>/dev/null | tr -d '"' | cut -d' ' -f2
}

power_name() {
  case $1 in power-saver) echo Eco ;; balanced) echo Balanced ;; performance) echo Performance ;; *) echo "$1" ;; esac
}

power_status() {
  echo "$(power_name "$(power_profile)") · charge limit $($PM charge) %"
}

# Строки трёх режимов (общие для раздела и для `cc power mode`).
power_mode_rows() {
  local cur p icon note
  cur=$(power_profile)
  for p in power-saver balanced performance; do
    case $p in
    power-saver) icon=󰌪 note="quiet fans, longest battery" ;;
    balanced) icon=󰾅 note="everyday use" ;;
    performance) icon=󰓅 note="full CPU power, louder" ;;
    esac
    [[ $p == "$cur" ]] && note="󰄬 active · $note"
    row "$(lbl "$icon" "$(power_name "$p")" "$note")" power_set "$p"
  done
}

power_rows() {
  TITLE=Power
  if [[ -w $EC/shift_mode ]]; then
    MESG="$(power_status)"
  else
    MESG="⚠ EC is read-only: mode, charge limit and Cooler Boost need the udev rule (dot sys install)"
  fi
  power_mode_rows
  local end boost
  end=$($PM charge) boost=$($PM boost)
  if ((end < 100)); then
    row "$(lbl 󰂄 "Charge limit: $end %" "battery care · Enter → 100 %")" power_charge
  else
    row "$(lbl 󰂄 "Charge limit: 100 %" "Enter → 80 % (battery care)")" power_charge
  fi
  if [[ $boost == on ]]; then
    row "$(lbl 󰈐 "Cooler Boost: on" "fans at max · Enter → off")" power_boost
  else
    row "$(lbl 󰈐 "Cooler Boost: off" "Enter → fans at max")" power_boost
  fi
  row "$(lbl 󰢻 "MSI Control Center" "fan curves, Fn/Win swap")" launch mcontrolcenter
  row "$(lbl 󰐥 "Power menu…" "lock, suspend, reboot")" launch ~/.config/rofi/powermenu/type-1/powermenu.sh
}

# Только выбор режима (левый клик по батарее в waybar): выбрал — закрылось.
power_mode() {
  ROWS=() ACTS=() SEL=0
  power_mode_rows
  pick "Power mode" "$(power_status)"
}

power_set() { "$PM" set "$1"; }
power_charge() { "$PM" charge toggle; }
power_boost() { "$PM" boost toggle; }
