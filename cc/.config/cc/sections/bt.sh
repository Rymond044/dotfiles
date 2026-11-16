# Bluetooth: адаптер и устройства теперь нативные в quickseek (BlueZ, источник "bluetooth",
# точка монтирования — quickseek.sh → SEC_SOURCE). Здесь остались действия для командной строки.

bt_power() { # on|off
	[[ $1 == on ]] && rfkill unblock bluetooth 2>/dev/null
	bluetoothctl power "$1" >/dev/null
}
