#!/usr/bin/env bash
# Развернуть dotfiles на свежем Arch: пакеты → yay → stow → /etc → подсказки.
# Каждый шаг спрашивает подтверждение, повторный запуск безопасен.
set -euo pipefail

DOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ask() { local a; read -r -p "$1 [y/N] " a; [[ $a == [yYдД]* ]]; }
step() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }

[[ -f /etc/arch-release ]] || { echo "Скрипт рассчитан на Arch Linux"; exit 1; }

step "Базовые инструменты (git, stow, base-devel)"
sudo pacman -S --needed git stow base-devel

step "Сабмодули (split-monitor-workspaces)"
git -C "$DOT" submodule update --init --recursive

if ! command -v yay >/dev/null; then
  step "yay"
  if ask "Собрать yay-bin из AUR?"; then
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si)
    rm -rf "$tmp"
  fi
fi

step "Пакеты из packages/pkglist.txt и aurlist.txt"
ask "Установить пакеты?" && "$DOT/dot" pkgs install

step "Ссылки stow"
# Уже существующие файлы мешают stow. Убираем их в бэкап, а не удаляем.
backup="$HOME/.dotfiles-backup/$(date +%F_%H%M%S)"
conflicts=()
while read -r pkg; do
  while IFS= read -r -d '' f; do
    rel="${f#"$DOT/$pkg/"}"; tgt="$HOME/$rel"
    [[ -e $tgt || -L $tgt ]] || continue
    [[ "$(readlink -f "$tgt")" == "$(readlink -f "$f")" ]] && continue
    conflicts+=("$rel")
  done < <(find "$DOT/$pkg" \( -type f -o -type l \) -not -path '*/.git/*' -not -name .git -print0)
done < <("$DOT/dot" list)
if ((${#conflicts[@]})); then
  printf 'Мешают уже существующие файлы:\n'; printf '  ~/%s\n' "${conflicts[@]}"
  if ask "Перенести их в $backup?"; then
    for rel in "${conflicts[@]}"; do
      mkdir -p "$backup/$(dirname "$rel")"; mv "$HOME/$rel" "$backup/$rel"
    done
  fi
fi
"$DOT/dot" link
"$DOT/dot" check || true

step "Системные файлы (system/ → /etc)"
"$DOT/dot" sys install

step "Что сделать руками"
cat <<'EOF'
  • getty@tty1 override содержит имя пользователя (rymond044) — поправь, если другое:
      /etc/systemd/system/getty@tty1.service.d/override.conf
  • Сервисы, которые не включаются автоматически:
      sudo systemctl enable hyprlock-delay.service power-profiles-daemon.service
  • oh-my-zsh: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --keep-zshrc
    оболочка: chsh -s /usr/bin/zsh
  • ~/.zshenv не в репо (там секреты) — создай руками.
  • hyprpm-плагины (после первого входа в Hyprland):
      hyprpm update
      hyprpm add https://github.com/<hymission> && hyprpm enable hymission   # у нас локальный клон ~/Apps/hymission, ветка local
      hyprpm add <hyprcapture> && hyprpm enable hyprcapture
  • Цвета: hyprland.lua и hyprlock.conf ждут результатов wallust —
      binc/wallust-swww <картинка>   (или: wallust run <картинка>)
EOF
