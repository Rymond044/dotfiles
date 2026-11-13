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

# Строки трёх режимов.
power_mode_rows() {
  local cur p icon
  cur=$(power_profile)
  for p in power-saver balanced performance; do
    case $p in power-saver) icon=󰌪 ;; balanced) icon=󰾅 ;; performance) icon=󰓅 ;; esac
    row "$(lbl "$icon" "$(power_name "$p")" "$([[ $p == "$cur" ]] && echo "󰄬 active")")" power_set "$p"
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
  row "$(lbl 󰂄 "Charge limit: $end %")" power_charge
  row "$(lbl 󰈐 "Cooler Boost: $boost")" power_boost
  row "$(lbl 󰁹 "Battery monitor")" launch battery-monitor
  row "$(lbl 󰢻 "MSI Control Center")" launch mcontrolcenter
  row "$(lbl 󰐥 "Session…")" power_session
}

# Папка Session quickseek (Lock, Suspend, Restart…) — вместо прежнего powermenu
power_session() {
  qs -p ~/Apps/quickseek ipc call quickseek folder session >/dev/null 2>&1
}

power_set() { "$PM" set "$1"; }
power_charge() { "$PM" charge toggle; }
power_boost() { "$PM" boost toggle; }
