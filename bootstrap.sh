#!/usr/bin/env bash
# Интерактивная установка; --plan не выполняет изменений.
set -euo pipefail
DOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
preview=false
for arg in "$@"; do
    [[ $arg != --plan && $arg != --help && $arg != -h && $arg != --audit && $arg != --check && $arg != --export ]] || preview=true
done
missing=()
command -v python3 >/dev/null || missing+=(python)
if ! $preview; then
    command -v gum >/dev/null || missing+=(gum)
fi
if ((${#missing[@]})); then
    ! $preview || {
        echo 'Python 3 is required to preview the installer.' >&2; exit 1;
    }
    [[ -f /etc/arch-release ]] || { echo 'Arch Linux is required.' >&2; exit 1; }
    read -r -p "Install ${missing[*]} to open the installer? [y/N] " answer
    [[ $answer == [yY] ]] || exit 1
    sudo pacman -S --needed "${missing[@]}"
fi
exec python3 "$DOT/install/installer.py" "$@"
