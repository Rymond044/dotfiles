#!/bin/bash

# Show a fuzzy-finder TUI for picking new Arch and OPR packages to install.

fzf_args=(
  --multi
  --preview 'pacman -Sii {1}'
  --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:green,marker:green'
)

mapfile -t pkgs < <(pacman -Slq | fzf "${fzf_args[@]}")

# Esc в fzf — ничего не выбрано, окно закрывается сразу
((${#pkgs[@]})) || exit 0

sudo pacman -S --noconfirm "${pkgs[@]}"
status=$?
"$(dirname "$0")/show_done.sh" "$status"
