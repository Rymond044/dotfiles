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

step "Проекты из ~/Apps (свои репо и форки)"
mkdir -p "$HOME/Apps"
# clone_app ИМЯ URL ВЕТКА — идемпотентно: существующую папку не трогаем
clone_app() {
  local name="$1" url="$2" branch="$3" dir="$HOME/Apps/$1"
  if [[ -d $dir/.git ]]; then echo "  ✓ $name уже есть"; return 0; fi
  git clone --branch "$branch" "$url" "$dir" || echo "  ✗ не удалось клонировать $name"
}
if ask "Склонировать quickseek, quickdesk, linux-battery-monitor, hymission, HyprCapture?"; then
  clone_app quickseek             git@github.com:Rymond044/quickseek.git             main
  clone_app quickdesk             git@github.com:Rymond044/quickdesk.git             main
  clone_app linux-battery-monitor git@github.com:Rymond044/linux-battery-monitor.git main
  clone_app hymission             git@github.com:Rymond044/hymission.git             local
  clone_app HyprCapture           git@github.com:Rymond044/HyprCapture.git           local
  [[ -x $HOME/Apps/linux-battery-monitor/install.sh ]] && "$HOME/Apps/linux-battery-monitor/install.sh"
fi

step "Юниты systemd (packages/units-*.txt)"
ask "Включить юниты из списков?" && "$DOT/dot" units enable

step "Что сделать руками"
cat <<'EOF'
  • getty@tty1 override содержит имя пользователя (rymond044) — поправь, если другое:
      /etc/systemd/system/getty@tty1.service.d/override.conf
  • Сервисы, которые не включаются автоматически:
      (юниты из packages/units-system.txt уже включены шагом выше; `dot units diff` покажет расхождение)
  • oh-my-zsh: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --keep-zshrc
    оболочка: chsh -s /usr/bin/zsh
  • ~/.zshenv не в репо (там секреты) — скопируй docs/zshenv.example в ~/.zshenv и впиши значения.
  • hyprpm-плагины (после первого входа в Hyprland, из терминала внутри сессии):
      hyprpm update
      hyprpm add https://github.com/hyprnux/hyprglass && hyprpm enable hyprglass
      hyprpm add ~/Apps/hymission local && hyprpm enable hymission
      hyprpm add ~/Apps/HyprCapture local && hyprpm enable hyprcapture
      (hyprpm reload стартует из автостарта)
  • Цвета: hyprland.lua и hyprlock.conf ждут результатов wallust —
      binc/wallust-swww <картинка>   (или: wallust run <картинка>)
EOF
