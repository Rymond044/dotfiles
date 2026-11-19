#!/bin/bash
# show_done.sh [КОД] — итог операции в терминале и выход по любой клавише (окно kitty закрывается вместе со скриптом).

status=${1:-0}
echo
if ((status == 0)); then
	printf '\e[1;32m✓ Done.\e[0m'
else
	printf '\e[1;31m✗ Failed (exit code %s).\e[0m' "$status"
fi
printf ' Press any key to close…'

# Клавиши, нажатые во время установки, лежат в буфере tty — выбросить, иначе окно закроется сразу.
while read -rsn1 -t 0.05 </dev/tty; do :; done
read -rsn1 </dev/tty
echo
