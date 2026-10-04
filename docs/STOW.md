# Как устроены dotfiles и как ими пользоваться

## Идея в двух словах

Все конфиги лежат в `~/dotfiles` (это git-репо). В домашней папке вместо настоящих
файлов — **симлинки** в репо. Их расставляет [GNU stow](https://www.gnu.org/software/stow/).
Правишь `~/.config/hypr/...` как раньше, а на самом деле меняется файл в `~/dotfiles`, и
`git status` сразу это видит.

```
~/.config/hypr  ->  ~/dotfiles/hypr/.config/hypr
~/.zshrc        ->  ~/dotfiles/zsh/.zshrc
```

## Структура репо

```
~/dotfiles/
├── hypr/            ← stow-пакет: внутри повторяется путь от $HOME
│   └── .config/hypr/...
├── zsh/
│   ├── .zshrc
│   └── .config/starship.toml
├── …                ← остальные пакеты (см. `./dot list`)
├── system/          ← НЕ stow: копии файлов из /etc (ставятся копированием)
│   └── etc/...
├── packages/        ← pkglist.txt (pacman), aurlist.txt (AUR)
├── docs/            ← эта документация
├── dot              ← скрипт-обёртка для всех операций
└── bootstrap.sh     ← развернуть всё на чистой системе
```

**Пакет** — папка верхнего уровня. Всё внутри неё раскладывается в `$HOME` с теми же путями:
`waybar/.config/waybar/style.css` → `~/.config/waybar/style.css`.

Пакеты: `binc btop clipse fastfetch fontconfig ghostty git gtk hypr kitty nvim nwg-displays
qt rofi session swaync wallust waybar waypaper yazi zsh`.

- `gtk` — gtk-3.0/4.0, `.gtkrc-2.0`, nwg-look, xsettingsd
- `qt` — qt5ct, qt6ct, Kvantum
- `session` — mimeapps.list, chromium/electron-flags, user-dirs, MControlCenter.conf, systemd/user
- `binc` — скрипты в `~/.config/binc` (путь оставлен прежним, на него ссылаются конфиги) + `arch_logo.txt`

## «Свёрнутые» папки (tree folding)

Если папки в `$HOME` ещё нет, stow делает ссылкой **всю папку** (`~/.config/hypr` →
репо). Если папка уже есть, stow создаёт её и ставит ссылки на отдельные файлы.

Свёрнутая папка удобна: всё, что приложение создаст в ней (новые файлы, сгенерированный
`hyprlock.conf`), физически окажется в репо, а лишнее отсекает `.gitignore`.

Исключение — `clipse`: в `~/.config/clipse` лежит история буфера обмена, поэтому папка
настоящая и в ней ссылки только на `config.json` и `custom_theme.json`.

## Повседневное использование

```sh
cd ~/dotfiles
git status               # что поменялось в конфигах
git add -p && git commit # закоммитить
git push
```

Редактировать можно как угодно: через `~/.config/...` или прямо в `~/dotfiles/...`, это одни и те же файлы.

### Скрипт `dot`

```sh
./dot list               # список пакетов
./dot link               # расставить ссылки всех пакетов (stow --restow)
./dot link hypr waybar   # только этих
./dot unlink yazi        # убрать ссылки пакета (файлы в репо остаются)
./dot check              # проверить, что все ссылки на месте
./dot adopt session      # забрать в репо файл, который приложение заменило (см. ниже)
```

Удобно сделать алиас: `alias dot=~/dotfiles/dot`.

### Добавить новый конфиг под учёт

Например, `~/.config/mpv`:

```sh
mkdir -p ~/dotfiles/mpv/.config
mv ~/.config/mpv ~/dotfiles/mpv/.config/
cd ~/dotfiles && ./dot link mpv     # то же самое: stow -t ~ mpv
git add mpv && git commit -m "mpv: add config"
```

Одиночный файл в существующий пакет:

```sh
mv ~/.config/foo.conf ~/dotfiles/session/.config/
./dot link session
```

### Убрать конфиг из-под учёта

```sh
./dot unlink yazi                          # ссылки пропали
cp -r ~/dotfiles/yazi/.config/yazi ~/.config/  # вернуть настоящую папку
git rm -r yazi
```

### Когда приложение «ломает» ссылку

Некоторые программы сохраняют настройки так: пишут временный файл и переименовывают его
поверх старого. Симлинк при этом заменяется обычным файлом, и изменения перестают попадать
в репо. Обычно так ведут себя Qt/GLib-приложения с одиночными файлами: `MControlCenter.conf`,
`mimeapps.list`, `user-dirs.dirs`. Внутри свёрнутых папок проблемы нет.

```sh
./dot check            # покажет REPLACED ~/.config/mimeapps.list
./dot adopt session    # stow --adopt: файл переезжает в репо, ссылка восстанавливается
git diff               # посмотреть, что поменялось; лишнее откатить git checkout -- <файл>
```

### Голый stow (что делает `dot` внутри)

```sh
stow -d ~/dotfiles -t ~ hypr          # создать ссылки
stow -d ~/dotfiles -t ~ -R hypr       # пересоздать (после добавления файлов)
stow -d ~/dotfiles -t ~ -D hypr       # удалить ссылки
stow -d ~/dotfiles -t ~ -n -v hypr    # dry-run: показать, что будет сделано
stow -d ~/dotfiles -t ~ --adopt hypr  # конфликтующие файлы из ~ забрать в репо
```

Если stow пишет `existing target is not owned by stow` — в `$HOME` уже лежит настоящий
файл. Либо убрать его в сторону, либо `--adopt` (тогда содержимое репо заменится файлом из `$HOME`, проверь `git diff`).

## Системные файлы (`system/`)

Файлы из `/etc` **копируются**, а не линкуются: initramfs (mkinitcpio), udev и systemd
читают их до того, как доступен `/home`, и ждут файлы, принадлежащие root.

В репо сейчас: `default/grub`, `mkinitcpio.conf`, `modprobe.d/{iwlwifi,msi-ec,isw,xbox_bt}.conf`,
`modules-load.d/uhid.conf`, udev-правила (Wi-Fi d3cold/power_save, сканер),
`systemd/system/hyprlock-delay.service`, `getty@tty1` override (автологин).

```sh
./dot sys diff           # чем /etc отличается от репо
./dot sys install        # показать diff → спросить → sudo install; затем предложит
                         # grub-mkconfig / mkinitcpio -P / udevadm reload / daemon-reload
./dot sys pull           # правил /etc руками → забрать изменения в репо
./dot sys add /etc/sysctl.d/99-foo.conf   # поставить новый файл на учёт
```

Перед `sys install` с изменениями grub/mkinitcpio сделай снапшот snapper.

## Списки пакетов

```sh
./dot pkgs save      # перезаписать packages/pkglist.txt (pacman -Qqen) и aurlist.txt (-Qqem)
./dot pkgs diff      # что установлено, но не в списке, и наоборот
./dot pkgs install   # pacman -S --needed + yay -S --needed по спискам
```

## Новая машина

```sh
git clone --recurse-submodules git@github.com:Rymond044/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

`bootstrap.sh` ставит git/stow/yay и пакеты, убирает мешающие файлы в `~/.dotfiles-backup/<дата>/`,
расставляет ссылки, копирует `system/` и в конце печатает, что осталось сделать руками:
hyprpm-плагины, oh-my-zsh, `~/.zshenv`, первый прогон wallust.

## Что не в репо

- `~/.zshenv`: там секреты (API-ключи).
- `hypr/hyprlock.conf`: собирает `~/.config/binc/lock` при каждой блокировке из шаблона wallust
  (`wallust/templates/hyprlock.conf.j2` → `~/.cache/wallust/hyprlock.conf`) под текущие мониторы.
- `~/.cache/wallust/*`: тоже генерирует wallust.
- `binc/myvpn`.
- `CLAUDE.md`: рабочий трекер (в `.gitignore`, лежит рядом локально).

## Сабмодуль

`hypr/.config/hypr/plugins`: split-monitor-workspaces. После клонирования:
`git submodule update --init`. Обновить: `git submodule update --remote hypr/.config/hypr/plugins`.
