# Разделение установки на system и user — предложение

Дата аудита: 2026-11-19. Обсуждение завершено, реализация разрешена владельцем.
Актуальный исполняемый каталог — `packages/scopes.json`, инструкция — `INSTALL.md`.
Ниже сохранён ход обсуждения и историческая классификация, она не является установочным списком.

Здесь scope означает обязательность установки. Pacman/AUR по-прежнему устанавливают пакеты для всей машины; это не разделение по Unix-пользователям.

Проверены 1783 установленных пакетов по локальным метаданным pacman, 351 явно установленных пакетов, 349 записей текущих списков. Объединение явных и сохранённых: 351.

Таблица ниже — рабочая классификация, уточняемая после обсуждения. Ранее найденные 36 требований к базе не представлены отдельными строками старых списков: часть уже установлена как зависимости.

Предварительный расчёт первого варианта базы с MSI дал 973 пакета с зависимостями. После выбора всех текущих приложений по умолчанию состав меняется; это не итоговый размер установки. Зависимости не копируются вручную в установочный список.

## Уточнения владельца после первого предложения

- Три независимые части: system packages (обязательное окружение), user packages (выбор программ), hardware configs (восстанавливаемая конфигурация конкретного компьютера, со своими пакетами и службами).
- systemd и GRUB сами по себе не означают hardware: общие правила остаются общими, персональные параметры отделяются. В одном текущем файле могут быть обе части.
- В GRUB общая оболочка отделяется от xe/i915 force_probe, PSR, NVMe APST и текущих обходов UART/TPM; последние пока переносить только в профиль этого ноутбука.
- mkinitcpio: общие HOOKS отдельно, MODULES=(btrfs xe) зависят от ФС/железа. Не копировать как универсальный файл.
- ec-sync, msi-ec, EC/BAT1, Cooler Boost, лимиты заряда, nvme-apst, Intel Wi-Fi d3cold/power_save/uapsd и PCI runtime PM относятся к hardware:msi.
- power-profiles-daemon и автоматический выбор Eco/Balanced при зарядке — общая политика по уточнению владельца; записи MSI EC остаются аппаратными. sleep-hold — общая интеграция блокировки перед сном.
- Настройки Snapper/Btrfs привязаны к схеме установки и файловой системе, не к бренду MSI. Общая схема включения служб должна учитывать наличие соответствующих компонентов.
- Мониторы/масштабы, выбранный VA-API драйвер, сканер и контроллеры — hardware-профили. Автологин с именем rymond044 — параметр пользователя/установки, не железа.
- Кнопки EC, Cooler Boost и MSI Control Center должны появляться только при наличии hardware-профиля; обычный выбор профиля питания остаётся в общей базе.
- Уточнение владельца: автоматическое переключение Eco от батареи / Balanced от зарядки — общее поведение, не только hardware:msi; аппаратные EC-действия отделить от общей политики.
- Необязательные приложения выбираются чекбоксами при установке. KeePassXC и qBittorrent необязательны, но отмечены по умолчанию. KFontView пока сохраняется. Кнопка Edit dotfiles переводится на Neovim в kitty. Выбор hardware-профиля явный с автоматической подсказкой.
- Решение владельца: URI-обработчики регистрируются только для выбранных приложений. Из user по умолчанию отмечены KeePassXC, qBittorrent, Telegram и Discord. Выбор пользователя не сохраняется отдельным профилем. AI-разметка — одна опция установки Ollama и модели.
- Повторный запуск: невыбранные уже установленные программы пропускаются, не удаляются. Конфиги необязательных программ разворачиваются только при их выборе. Сканер, Xbox controller, fprintd и howdy выбираются отдельными hardware-чекбоксами, не включаются автоматически вместе с профилем MSI.

| Реальная текущая ассоциация | Пакет | Статус обсуждения |
|---|---|---|
| Web / terminal / folders / text | chromium / kitty / nautilus / neovim | Обязательные |
| Images / audio-video / archives | eog / mpv / ark | Обязательные |
| PDF / DjVu / comics | papers | Обязательный |
| PS / EPS / DVI / XPS | evince | Обязательный: текущий отдельный обработчик |
| Books | bookworm | Обязательный |
| Office documents | libreoffice-still | Обязательный |
| XCF / PSD | gimp | Обязательный |
| KeePass databases | keepassxc | user: необязательный, чекбокс включён по умолчанию |
| Torrents / magnet | qbittorrent | user: необязательный, чекбокс включён по умолчанию |
| Fonts | plasma-workspace (kfontview) | Текущий просмотрщик пока сохраняется по решению владельца |
| PNG alternate handler / books alternate handler | swappy / fbreader | Added Associations, а не основной обработчик: пока user |
| discord/kando/claude/claude-cli/codex URI | Соответствующие приложения | Назначать только при выборе соответствующего приложения |

В текущем mimeapps есть несуществующие на машине vesktop.desktop и kando.desktop. Их следует условно регистрировать только при установке приложения, а не восстанавливать как рабочие базовые назначения.

## Правило границы

- system: запуск сессии, все используемые штатные действия панели/Control Center/quickseek, приложения для повседневного открытия файлов, выбранная тема, свои интегрированные приложения и плагины.
- hardware:msi: отдельный восстанавливаемый профиль этого ноутбука; на другом железе выбирается другой профиль. Не применять MSI udev/modprobe/GRUB вслепую.
- user: личные программы, рабочие инструменты, игры, альтернативные интерфейсы и необязательные функции. Группы служат удобным выбором внутри одного user scope.
- Включение user-программы в общий поиск приложений не повышает её до system. Жёсткий вызов из штатной кнопки должен либо попасть в system, либо стать условным/получить базовую замену.
- Зависимости user-программ могут одновременно требоваться базе. Scope определяет требование, а не запрет на наличие пакета в другом графе зависимостей.

## Проверенные связи

| Потребитель | Обязательные зависимости/действия |
|---|---|
| Hyprland autostart и клавиши | uwsm, hypridle/lock/sunset/polkitagent, awww, swaync, clipse, qs, kitty, chromium, nautilus, playerctl, brightnessctl |
| Waybar modules.jsonc | wiremix, bluetui, impala, btop, calcure, playerctl, swaync-client, qs и cc |
| Control Center | jq, busctl, iwctl, bluetoothctl, wpctl, nwg-displays, battery-monitor, mcontrolcenter (MSI), yay, gum/fzf; Zed заменить вызовом базового редактора |
| quickseek | fd/plocate для файлов, libqalculate для калькулятора, file/poppler/ffmpeg/libvips для превью, wl-clipboard/clipse, Python для вспомогательных инструментов |
| quickdesk | Quickshell и ImageMagick для текущих функций обоев/автоматического размещения; Battery Monitor задаётся внешней настройкой |
| Обои/тема/экран блокировки | Python, numpy, Pillow, libvips, wallust, matugen, fontconfig, используемые шрифты, GTK/KDE интеграция |
| OCR | grim, slurp, wayfreeze, tesseract + eng/rus, wl-clipboard, libnotify |
| Заставка quickseek | kitty + terminaltexteffects (tte); таймер заставки в hypridle закомментирован, но ручное действие включено |
| hymission | CMake, toolchain, pkgconf, заголовки совместимого Hyprland, Lua, GTK4, libadwaita, gtk4-layer-shell; ставится helper hymission-search-input |
| HyprCapture | CMake/toolchain, Hyprland/Lua, glib2, libpulse/libpipewire, FFmpeg, FFTW, Qt6 Base/Svg, LayerShellQt, nlohmann-json, OpenCV; нужны UI/helper и данные, а не только .so |
| Battery Monitor / sleep-hold | Python GObject, GTK4/libadwaita для GUI; пользовательские юниты |
| Neovim | LazyVim/lazy.nvim и плагины, ripgrep/fd; языковые серверы и Mason отделить от рабочего DevOps-набора |

## Проекты в ~/Apps

| Каталог | Scope | Причина |
|---|---|---|
| quickseek | system | Штатный поиск и Control Center |
| quickdesk | system | Штатные виджеты |
| linux-battery-monitor | system | Кнопка питания и виджет |
| hymission | system | Super+Tab, обзор и helper |
| HyprCapture | system | Штатные скриншоты/редактор/запись и helpers |
| msi-ec | hardware:msi, при необходимости исходников | Обычно достаточно msi-ec-git; не устанавливать одновременно второй независимый способ |
| yay | инструмент установки | Достаточно установленного AUR helper; клон не самостоятельное приложение окружения |
| KBE 4.0, Python-3.14.3, idevicerestore, pacmods | user / уточнить | Из проверенных точек входа рабочего окружения обязательность не следует; само наличие в Apps не основание для базовой установки |

Существующие ветки/коммиты и helpers нужно зафиксировать в манифесте проектов. hyprglass также входит в system, хотя отдельного каталога Apps для него нет. split-monitor-workspaces уже поставляется git-сабмодулем. Нужна проверка ABI плагинов против выбранного Hyprland. Живые плагины во время аудита не обновлялись.

## Конфиги и секреты

- Версионируемые .zshrc, starship и список Oh My Zsh plugins оставить обычными конфигами. Oh My Zsh и четыре custom plugins устанавливать из манифеста (autosuggestions, shift-select, syntax-highlighting, z).
- Добавить templates/env.example с пустыми значениями секретов и templates/zshenv.example с безопасным подключением локального env. Установщик создаёт локальный ~/.config/dotfiles/.env с правами 600 и ~/.zshenv только при отсутствии; существующие значения не заменяет.
- Не переносить содержимое конфигурации Oh My Zsh в dotenv: это shell-код. Локальные переменные/пути допускаются в отдельном shell-совместимом .env.example.
- Подключение ~/.cargo/env должно быть условным. kubectl completion — только если kubectl установлен. DevOps aliases не должны требовать установки Docker/Kubernetes в базе.
- Только source из оболочки не передаёт секреты каждому GUI: если GUI нужны конкретные переменные, определить ограниченный явный набор для окружения uwsm. Не экспортировать все секреты всему рабочему столу автоматически.
- Пустые значения не должны ломать вход в систему; зависимые онлайн-функции сообщают о настройке при обращении.

## Предлагаемая структура

```text
packages/system/{repo,aur}.txt
packages/user/{repo,aur}.txt
packages/user/groups/...         # необязательные подборки
profiles/msi/{packages,units,system-files}...
projects/...                    # URL, ref, установка, helpers, проверки
templates/{env,zshenv}.example
```

Согласованный UX: bootstrap ставит system + явно выбранный hardware-профиль; user-программы выбираются чекбоксами (KeePassXC, qBittorrent, Telegram и Discord отмечены по умолчанию). Отдельный личный профиль выбора не сохраняется. dot pkgs save не должен снова смешивать scope: он показывает неразобранные пакеты и сохраняет назначенную категорию.

## Условия до реализации

- Решение владельца: сохранить все текущие приложения по умолчанию, включая LibreOffice, GIMP, Bookworm и Evince. KeePassXC/qBittorrent необязательны и отмечены по умолчанию, текущий просмотрщик шрифтов сохраняется; URI-схемы мессенджеров/AI-приложений не смешивать с базовыми обработчиками документов без явного решения.
- Решение владельца: Zed оставить user, кнопку Edit dotfiles перевести на Neovim в kitty.
- Решение владельца: Ollama/модель — отдельная опция, не влияющая на выбиралку. Tag with Gemma без Ollama/модели обязан корректно сообщать о недоступности и сохранять рабочее окно. Бэкенд cmd_tag уже ловит исключения и уведомляет; UI пока запускает его без проверки доступности. Живая проверка отсутствующей Ollama не выполнялась. Не включать автозапуск разметки.
- Docker/libvirt/Kubernetes/gungnir относятся к user/work-профилю. Списки включаемых служб разделить вместе с пакетами. Docker/libvirt по требованию, без запуска Docker service при загрузке.
- Нельзя переносить весь /etc/pacman.conf с этой машины на другую: подключение стороннего репозитория, ключи и multilib должны зависеть от выбранных приложений.
- Текущий portals.conf выбирает hyprland;gtk, поэтому backend KDE предложен необязательным. Это отдельно от plasma-integration, которая используется текущей Qt-темой.
- HyprCapture при установке также пытается подготовить необязательный AEC runtime. Подавление эха, дополнительные модели и другие тяжёлые функции следует учитывать отдельно от обязательных скриншотов и записи; ошибка AEC уже не блокирует обычную установку в текущем install-aec.sh.
- Системная установка здесь означает настройку уже установленного Arch. Разметка диска, создание пользователей, установка загрузчика и перенос данных требуют отдельной процедуры.
- Текущие wallpapers, .walls.json, базы приложений, история и секреты — отдельные данные/бэкап. По решению владельца в поставку скопированы пять случайных обоев; при первой настройке установщик должен выбрать один случайный и подготовить тему/lock config. При повторном запуске текущий фон сохраняется. Базовая аватарка — копия нынешней свинки с ноутбуком; существующий пользовательский pfp не заменять.
- Финальная проверка: чистый Arch в VM; базовые кнопки/диалоги/поиск/OCR/просмотрщики/lock, отсутствие user-приложений и ненужных служб. Данный аудит статический и не доказывает, что перечисленными зависимостями исчерпаны все динамические ветви.

## Полная классификация явных/сохранённых пакетов

Все строки — предложение, не команда удаления. Наличие ссылки в описании pacman не является доказательством использования программы. Локальные описания взяты из установленной базы пакетов.

| Пакет | Scope | Назначение / основание | Описание установленного пакета |
|---|---|---|---|
| `acpi` | user | Диагностика и эксперименты | Client for battery, power, and thermal readings |
| `adw-gtk-theme` | system | Тема и используемые шрифты | Unofficial GTK 3 port of the libadwaita theme |
| `adwaita-colors-icon-theme` | system | Тема и используемые шрифты | Adwaita Colors enhances the Adwaita icon theme by integrating GNOME’s accent color feature. It ensures that your Adwaita icons reflect the same accent color as your GNOME theme. |
| `alacritty` | user | Дополнительные терминалы и редакторы | A cross-platform, GPU-accelerated terminal emulator |
| `alsa-utils` | system | Сеть, звук и кнопки Waybar | Advanced Linux Sound Architecture - Utilities |
| `ansible` | user | Разработка и инфраструктура | Official assortment of Ansible collections |
| `ansible-lint` | user | Разработка и инфраструктура | Checks playbooks for practices and behaviour that could potentially be improved. |
| `apple-fonts` | system | Тема и используемые шрифты | Fonts for Apple platforms, including San Francisco and New York typefaces |
| `arc-icon-theme` | user | Дополнительные темы и шрифты | Arc icon theme. Official releases only. |
| `argocd` | user | Разработка и инфраструктура | Declarative continuous deployment for Kubernetes |
| `ark` | system | Базовые приложения и поиск | Archiving Tool |
| `ascii-2048` | user | Оформление и развлечения терминала | 2048 game for terminal in ASCII |
| `asciiquarium` | user | Оформление и развлечения терминала | An aquarium/sea animation in ASCII art |
| `audacity` | user | Медиа и творчество | A program that lets you manipulate digital audio waveforms |
| `auto-cpufreq` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Automatic CPU speed & power optimizer |
| `awww` | system | Сессия и интерфейс | An Answer to your Wayland Wallpaper Woes |
| `azure-cli` | user | Разработка и инфраструктура | Command-line tools for Microsoft Azure |
| `base` | system | Arch и установка | Minimal package set to define a basic Arch Linux installation |
| `base-devel` | system | Arch и установка | Basic tools to build Arch Linux packages |
| `bat` | system | Оболочка и управление пакетами | Cat clone with syntax highlighting and git integration |
| `battop` | user | Диагностика и эксперименты | Interactive batteries viewer |
| `bibata-cursor-theme` | system | Тема и используемые шрифты | Material Based Cursor Theme |
| `bind` | user | VPN, сеть и загрузки | A complete, highly portable implementation of the DNS protocol |
| `bluetui` | system | Сеть, звук и кнопки Waybar | TUI for managing bluetooth devices |
| `bookworm` | system | Текущий обработчик файлов по умолчанию; включить по решению владельца | A simple user centric eBook reader which displays multiple eBooks formats uniformly |
| `bootconfig` | user | Диагностика и эксперименты | Apply, delete or show boot config to initrd |
| `bpf` | user | Диагностика и эксперименты | BPF tools |
| `breeze-cursors` | user | Дополнительные темы и шрифты | Breeze cursors |
| `brightnessctl` | system | Сессия и интерфейс | Lightweight brightness control tool |
| `btop` | system | Сеть, звук и кнопки Waybar | A monitor of system resources, bpytop ported to C++ |
| `btrfs-assistant` | system | Общее управление Btrfs/Snapper при выбранной ФС | An application for managing BTRFS subvolumes and Snapper snapshots |
| `btrfs-progs` | system | Общие инструменты Btrfs при выбранной ФС | Btrfs filesystem utilities |
| `calcure` | system | Сеть, звук и кнопки Waybar | Modern TUI calendar and task manager |
| `cava` | user | Оформление и развлечения терминала | Console-based Audio Visualizer with support for multiple backends |
| `cbonsai` | user | Оформление и развлечения терминала | A bonsai tree generator, written in C using ncurses |
| `chatgpt-bin` | user | Связь и AI-приложения | ChatGPT desktop application by OpenAI |
| `chromium` | system | Базовые приложения и поиск | A web browser built for speed, simplicity, and security |
| `clang` | user | Разработка и инфраструктура | C language family frontend for LLVM |
| `claude-code` | user | Связь и AI-приложения | An agentic coding tool that lives in your terminal |
| `claude-desktop` | user | Связь и AI-приложения | Official Claude AI desktop app from Anthropic — Chat, Cowork, and Claude Code |
| `clipse` | system | Сессия и интерфейс | A configurable TUI clipboard manager for Unix, built for wayland. |
| `cmatrix` | user | Оформление и развлечения терминала | A curses-based scrolling 'Matrix'-like screen |
| `cowsay` | user | Оформление и развлечения терминала | Configurable talking cow (and a bit more) |
| `cpupower` | user | Диагностика и эксперименты | Linux kernel tool to examine and tune power saving related features of your processor |
| `cups` | user | Печать и сканирование | OpenPrinting CUPS - daemon package |
| `discord` | user | Необязательный; чекбокс включён по умолчанию | All-in-one voice and text chat for gamers |
| `dkms` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Dynamic Kernel Modules System |
| `dmidecode` | user | Диагностика и эксперименты | Desktop Management Interface table related utilities |
| `dnsmasq` | user | Виртуализация и устройства | Lightweight, easy to configure DNS forwarder and DHCP server |
| `docker` | user | Разработка и инфраструктура | Pack, ship and run any application as a lightweight container |
| `docker-buildx` | user | Разработка и инфраструктура | Docker CLI plugin for extended build capabilities with BuildKit |
| `docker-compose` | user | Разработка и инфраструктура | Fast, isolated development environments using Docker |
| `downgrade` | user | Диагностика и эксперименты | Bash script for downgrading one or more packages to a version in your cache or the A.L.A. |
| `drawing` | user | Медиа и творчество | Basic image editor for the GNOME desktop |
| `droidcam` | user | Медиа и творчество | A tool to turn your phone/tablet into a wireless/usb webcam |
| `dunst` | user | Дополнительные GUI и прежние компоненты | Customizable and lightweight notification-daemon |
| `durdraw` | user | Оформление и развлечения терминала | Frame based ASCII and ANSI drawing and playback program |
| `easyeffects` | user | Медиа и творчество | Audio Effects for Pipewire applications |
| `efibootmgr` | system | Общая поддержка UEFI; зависит от схемы загрузки | Linux user-space application to modify the EFI Boot Manager |
| `electron33-bin` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Build cross platform desktop apps with web technologies — prebuilt |
| `eog` | system | Базовые приложения и поиск | Eye of Gnome: An image viewing and cataloging program |
| `escrcpy-bin` | user | Виртуализация и устройства | 📱Graphical Scrcpy to display and control Android devices powered by Electron(Prebuilt version.Use system-wide electron).使用图形化的 Scrcpy 显示和控制您的 Android 设备，由 Electron 驱动。 |
| `execstack` | user | Диагностика и эксперименты | set the executable stack flag of ELF binaries and libraries |
| `expac` | user | Диагностика и эксперименты | alpm data (pacman database) extraction utility |
| `eza` | system | Оболочка и управление пакетами | A modern replacement for ls (community fork of exa) |
| `fastfetch` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | A feature-rich and performance oriented neofetch like system information tool |
| `fbreader` | user | Офис, книги и учёба | An e-book reader for Linux |
| `fd` | system | Базовые приложения и поиск | Simple, fast and user-friendly alternative to find |
| `figlet` | user | Оформление и развлечения терминала | A program for making large letters out of ordinary text |
| `figlet-fonts` | user | Оформление и развлечения терминала | Additional asciiart fonts for figlet |
| `firewalld` | user | Дополнительная аутентификация и защита | Firewall daemon with D-Bus interface |
| `flatpak` | user | Дополнительные GUI и прежние компоненты | Linux application sandboxing and distribution framework (formerly xdg-app) |
| `flatseal` | user | Дополнительные GUI и прежние компоненты | A permissions manager for Flatpak |
| `fortune-mod` | user | Оформление и развлечения терминала | The Fortune Cookie Program from BSD games |
| `fprintd` | user | Дополнительная аутентификация и защита | D-Bus service to access fingerprint readers |
| `fwupd` | system | Обновление прошивок на поддерживаемом оборудовании | Simple daemon to allow session software to update firmware |
| `fzf` | system | Оболочка и управление пакетами | Command-line fuzzy finder |
| `gamemode` | user | Игры и совместимость | A daemon/lib combo that allows games to request a set of optimisations be temporarily applied to the host OS |
| `gamescope` | user | Игры и совместимость | SteamOS session compositing window manager |
| `geekbench` | user | Диагностика и эксперименты | A cross-platform benchmark that measures processor and memory performance |
| `genact` | user | Оформление и развлечения терминала | A nonsense activity generator |
| `ghostty` | user | Дополнительные терминалы и редакторы | Fast, native, feature-rich terminal emulator pushing modern features |
| `gimp` | system | Текущий обработчик файлов по умолчанию; включить по решению владельца | GNU Image Manipulation Program |
| `git` | system | Arch и установка | the fast distributed version control system |
| `git-filter-repo` | user | Разработка и инфраструктура | Quickly rewrite git repository history (filter-branch replacement) |
| `github-cli` | user | Разработка и инфраструктура | The GitHub CLI |
| `github-copilot-cli-bin` | user | Связь и AI-приложения | GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal. |
| `github-desktop` | user | Разработка и инфраструктура | GUI for managing Git and GitHub |
| `gitlab` | user | Разработка и инфраструктура | Project management and code hosting application |
| `gitlab-runner` | user | Разработка и инфраструктура | The official GitLab CI runner written in Go |
| `gnome-calculator` | user | Дополнительные GUI и прежние компоненты | GNOME Scientific calculator |
| `gnome-keyring` | system | Сессия и интерфейс | Stores passwords and encryption keys |
| `gnome-mines` | user | Оформление и развлечения терминала | Clear hidden mines from a minefield |
| `gnome-power-manager` | user | Дополнительные GUI и прежние компоненты | System power information and statistics |
| `gparted-git` | user | Диагностика и эксперименты | A Partition Magic clone, frontend to GNU Parted |
| `gprbuild` | user | Разработка и инфраструктура | Builder for multi-language systems. |
| `greed` | user | Оформление и развлечения терминала | A game of consumption. Eat as much as you can before munching yourself into a corner! |
| `grim` | system | Базовые приложения и поиск | Screenshot utility for Wayland |
| `grimblast-git` | user | Дополнительные GUI и прежние компоненты | A helper for screenshots within Hyprland. |
| `gromit-mpx` | user | Медиа и творчество | On-screen annotation tool |
| `grub` | system | Общая настройка загрузки; применять только при выбранном GRUB | GNU GRand Unified Bootloader (2) |
| `grub-btrfs` | system | Интеграция снимков при GRUB + Btrfs | Include btrfs snapshots in GRUB boot options |
| `gsettings-qt5` | user | Дополнительные GUI и прежние компоненты | Library to access GSettings from Qt5 |
| `gst-libav` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Multimedia graph framework - libav plugin |
| `gst-plugins-bad` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Multimedia graph framework - bad plugins |
| `gst-plugins-ugly` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Multimedia graph framework - ugly plugins |
| `gti` | user | Оформление и развлечения терминала | A silly git launcher |
| `gum` | system | Оболочка и управление пакетами | A tool for glamorous shell scripts |
| `guvcview` | user | Медиа и творчество | Simple GTK interface for capturing and viewing video from V4L2 devices |
| `hardinfo2` | user | Диагностика и эксперименты | System Information and Benchmark for Linux Systems. |
| `helm` | user | Разработка и инфраструктура | The Kubernetes Package Manager |
| `howdy` | user | Дополнительная аутентификация и защита | Windows Hello style facial authentication for Linux |
| `hplip` | user | Печать и сканирование | Drivers for HP DeskJet, OfficeJet, Photosmart, Business Inkjet and some LaserJet |
| `htop` | user | Диагностика и эксперименты | Interactive process viewer |
| `hyfetch` | user | Диагностика и эксперименты | Neofetch with LGBTQ+ pride flags! |
| `hyperv` | user | Виртуализация и устройства | Hyper-V tools |
| `hyprgraphics` | system | Сессия и интерфейс | hyprland graphics resources and utilities |
| `hypridle` | system | Сессия и интерфейс | hyprland’s idle daemon |
| `hyprland` | system | Сессия и интерфейс | a highly customizable dynamic tiling Wayland compositor |
| `hyprlang` | system | Сессия и интерфейс | implementation library for the hypr config language |
| `hyprlock` | system | Сессия и интерфейс | hyprland’s GPU-accelerated screen locking utility |
| `hyprpicker` | system | Сессия и интерфейс | A wlroots-compatible Wayland color picker that does not suck |
| `hyprpm` | system | Сессия и интерфейс | Plugin manager for Hyprland |
| `hyprpolkitagent` | system | Сессия и интерфейс | Simple polkit authentication agent for Hyprland, written in QT/QML |
| `hyprsunset` | system | Сессия и интерфейс | An application to enable a blue-light filter on Hyprland |
| `hyprutils` | system | Сессия и интерфейс | Hyprland utilities library used across the ecosystem |
| `ifuse` | user | Виртуализация и устройства | A fuse filesystem to access the contents of an iPhone or iPod Touch |
| `imagemagick` | system | Базовые приложения и поиск | An image viewing/manipulation program |
| `impala` | system | Сеть, звук и кнопки Waybar | TUI for managing wifi |
| `inetutils` | user | VPN, сеть и загрузки | A collection of common network programs |
| `inotify-tools` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | a C library and a set of command-line programs for Linux providing a simple interface to inotify. |
| `intel-gpu-tools` | user | Диагностика и эксперименты | Tools for development and testing of the Intel DRM driver |
| `intel-media-driver` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Intel Media Driver for VAAPI — Broadwell+ iGPUs |
| `intel-oneapi-compiler-shared-runtime-libs` | user | Диагностика и эксперименты | Intel oneAPI compiler runtime libraries: Minimal compiler libraries |
| `intel-oneapi-openmp` | user | Диагностика и эксперименты | Intel oneAPI OpenMP runtime library |
| `intel-speed-select` | user | Диагностика и эксперименты | Intel Speed Select |
| `intel-ucode` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Microcode update files for Intel CPUs |
| `intel-undervolt` | user | Диагностика и эксперименты | Intel CPU undervolting tool |
| `inxi` | user | Диагностика и эксперименты | Full featured CLI system information tool |
| `iotop` | user | Диагностика и эксперименты | View I/O usage of processes |
| `iw` | user | Диагностика и эксперименты | nl80211 based CLI configuration utility for wireless devices |
| `iwd` | system | Сеть, звук и кнопки Waybar | Internet Wireless Daemon |
| `kamoso` | user | Медиа и творчество | A webcam recorder from KDE community |
| `kcpuid` | user | Диагностика и эксперименты | Kernel tool for various cpu debug outputs |
| `kdiskmark` | user | Диагностика и эксперименты | HDD and SSD benchmark tool with a very friendly graphical user interface |
| `keepassxc` | user | Необязательный; чекбокс включён по умолчанию по решению владельца | Cross-platform community-driven port of Keepass password manager |
| `kind` | user | Разработка и инфраструктура | Kubernetes IN Docker - local clusters for testing Kubernetes |
| `kitty` | system | Базовые приложения и поиск | A modern, hackable, featureful, OpenGL-based terminal emulator |
| `ksnip` | user | Медиа и творчество | Qt-based screenshot tool that provides many annotation features |
| `kubelet` | user | Разработка и инфраструктура | An agent that runs on each node in a Kubernetes cluster making sure that containers are running in a Pod |
| `lazydocker` | user | Разработка и инфраструктура | A simple terminal UI for docker and docker-compose, written in Go with the gocui library. |
| `lazygit` | user | Разработка и инфраструктура | Simple terminal UI for git commands |
| `lib32-gamemode` | user | Игры и совместимость | A daemon/lib combo that allows games to request a set of optimisations be temporarily applied to the host OS |
| `lib32-mesa` | user | Игры и совместимость | Open-source OpenGL drivers - 32-bit |
| `lib32-vulkan-intel` | user | Игры и совместимость | Open-source Vulkan driver for Intel GPUs - 32-bit |
| `libnotify` | system | Сессия и интерфейс | Library for sending desktop notifications |
| `libreoffice-still` | system | Текущий обработчик файлов по умолчанию; включить по решению владельца | LibreOffice maintenance branch |
| `libva-intel-driver` | user | Дополнительные GUI и прежние компоненты | VA-API implementation for Intel G45 and HD Graphics family |
| `libva-utils` | user | Диагностика и эксперименты | Intel VA-API Media Applications and Scripts for libva |
| `libvirt` | user | Виртуализация и устройства | API for controlling virtualization engines (openvz,kvm,qemu,virtualbox,xen,etc) |
| `libvpl-tools` | user | Диагностика и эксперименты | Tools for Intel Video Processing Library |
| `linux` | system | Arch и установка | The Linux kernel and modules |
| `linux-firmware` | system | Arch и установка | Firmware files for Linux - Default set |
| `linux-headers` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Headers and scripts for building modules for the Linux kernel |
| `localsend-bin` | user | Связь и AI-приложения | An open source cross-platform alternative to AirDrop |
| `lolcat` | user | Оформление и развлечения терминала | Okay, no unicorns. But rainbows!! |
| `lutris` | user | Игры и совместимость | Open Gaming Platform |
| `man-db` | system | Arch и установка | A utility for reading man pages |
| `mate-icon-theme` | user | Дополнительные темы и шрифты | MATE icon theme |
| `matugen-bin` | system | Сессия и интерфейс | A material you and base16 color generation tool with templates |
| `mc` | user | Дополнительные терминалы и редакторы | A file manager that emulates Norton Commander |
| `mcontrolcenter-bin` | hardware:msi | Загрузка, графика, питание и восстановление MSI | An application that allows you to change the settings of MSI laptops |
| `meld` | user | Разработка и инфраструктура | Compare files, directories and working copies |
| `mesa` | system | Общая графическая инфраструктура | Open-source OpenGL drivers |
| `miraclecast-git` | user | Виртуализация и устройства | MiracleCast provides software to connect external monitors to your system via Wifi. It is compatible to Miracast. Link-management works, everything else is still being worked on. Replaces openwfd. Contribute on https://github.com/albfan/aur-miraclecast |
| `mkcert` | user | Разработка и инфраструктура | Simple tool for making locally-trusted development certificates |
| `monitui` | user | Диагностика и эксперименты | A delightfully minimal TUI for wrangling Hyprland monitors |
| `mpv` | system | Базовые приложения и поиск | a free, open source, and cross-platform media player |
| `msi-ec-git` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Driver for MSI laptop EC |
| `nano` | user | Дополнительные терминалы и редакторы | Pico editor clone with enhancements |
| `nautilus` | system | Базовые приложения и поиск | Default file manager for GNOME |
| `ncdu` | user | Диагностика и эксперименты | Disk usage analyzer with an ncurses interface |
| `neovim` | system | Базовые приложения и поиск | Fork of Vim aiming to improve user experience, plugins, and GUIs |
| `netplan` | user | VPN, сеть и загрузки | Network configuration abstraction renderer |
| `nginx` | user | Разработка и инфраструктура | Lightweight HTTP server and IMAP/POP3 proxy server |
| `nlohmann-json` | system | Сборка кастомных плагинов | JSON for Modern C++ |
| `nmap` | user | VPN, сеть и загрузки | Utility for network discovery and security auditing |
| `nodejs-mapscii` | user | Оформление и развлечения терминала | Map+Ascii -> MapSCII! Console Map Viewer. |
| `noto-fonts-cjk` | system | Тема и используемые шрифты | Google Noto CJK fonts |
| `noto-fonts-emoji` | system | Тема и используемые шрифты | Google Noto Color Emoji font |
| `noto-fonts-extra` | user | Дополнительные темы и шрифты | Google Noto TTF fonts - additional variants |
| `nvtop` | user | Диагностика и эксперименты | GPUs process monitoring for AMD, Intel and NVIDIA |
| `nwg-displays` | system | Сессия и интерфейс | Output management utility for sway and Hyprland Wayland compositors |
| `nwg-look` | system | Сессия и интерфейс | GTK settings editor adapted to work on wlroots-based compositors |
| `nyancat` | user | Оформление и развлечения терминала | Nyancat rendered in your terminal. |
| `obs-studio` | user | Медиа и творчество | Free, open source software for live streaming and recording |
| `ocrdesktop` | user | Дополнительные GUI и прежние компоненты | OCR the current window or desktop and make it browsable for the user |
| `ollama` | user | AI-разметка обоев | Create, run and share large language models (LLMs) |
| `ollama-vulkan` | user | AI-разметка обоев | Create, run and share large language models (LLMs) with Vulkan |
| `oneko` | user | Оформление и развлечения терминала | A cat that chases around your cursor |
| `openai-codex` | user | Связь и AI-приложения | OpenAIs lightweight coding agent that runs in your terminal |
| `opencode` | user | Связь и AI-приложения | The open source coding agent |
| `openresolv` | user | VPN, сеть и загрузки | resolv.conf management framework (resolvconf) |
| `openvpn` | user | VPN, сеть и загрузки | An easy-to-use, robust and highly configurable VPN (Virtual Private Network) |
| `os-prober` | system | Дополнение GRUB для других ОС; включение по выбору | Utility to detect other OSes on a set of drives |
| `otf-font-awesome` | system | Тема и используемые шрифты | Iconic font designed for Bootstrap - otf format |
| `pacutils` | user | Диагностика и эксперименты | Helper tools for libalpm |
| `patchelf` | user | Диагностика и эксперименты | Small utility to modify the dynamic linker and RPATH of ELF executables |
| `pavucontrol` | user | Дополнительные GUI и прежние компоненты | PulseAudio Volume Control |
| `peaclock` | user | Оформление и развлечения терминала | A colourful binary clock for the terminal |
| `perf` | user | Диагностика и эксперименты | Linux kernel performance auditing tool |
| `pipes.sh` | user | Оформление и развлечения терминала | Animated pipes terminal screensaver |
| `pipewire-pulse` | system | Сеть, звук и кнопки Waybar | Low-latency audio/video router and processor - PulseAudio replacement |
| `plantuml` | user | Офис, книги и учёба | Component that allows to quickly write uml diagrams |
| `plocate` | system | Базовые приложения и поиск | Alternative to locate, faster and compatible with mlocate's database. |
| `pods` | user | Дополнительные GUI и прежние компоненты | Manage your Podman/Docker containers |
| `polkit-kde-agent` | user | Дополнительные GUI и прежние компоненты | Daemon providing a polkit authentication UI for KDE |
| `postgresql` | user | Разработка и инфраструктура | Sophisticated object-relational DBMS |
| `power-profiles-daemon` | system | Сеть, звук и кнопки Waybar | Makes power profiles handling available over D-Bus |
| `powerstat` | user | Диагностика и эксперименты | A tool for measuring a laptops power usage via the battery. |
| `powertop` | user | Диагностика и эксперименты | A tool to diagnose issues with power consumption and power management |
| `praat` | user | Офис, книги и учёба | A speech analysis tool used for doing phonetics by computer |
| `protonup-qt` | user | Игры и совместимость | Install and manage Proton-GE and Luxtorpeda for Steam and Wine-GE for Lutris |
| `ptui-bin` | user | Диагностика и эксперименты | Picture TUI |
| `pyalpm` | user | Разработка и инфраструктура | Python bindings for libalpm |
| `pyenv` | user | Разработка и инфраструктура | Easily switch between multiple versions of Python |
| `python-git-dummy` | user | Разработка и инфраструктура | Generate dummy Git repositories populated with the desired number of commits, branches, and structure. |
| `python-pipx` | user | Разработка и инфраструктура | Install and Run Python Applications in Isolated Environments |
| `python-pyqt5` | user | Разработка и инфраструктура | A set of Python bindings for the Qt5 toolkit |
| `python-redis` | user | Разработка и инфраструктура | The Python interface to the Redis key-value store |
| `python312` | user | Разработка и инфраструктура | Major release 3.12 of the Python high-level programming language |
| `python313` | user | Разработка и инфраструктура | Major release 3.13 of the Python programming language |
| `qbittorrent` | user | Необязательный; чекбокс включён по умолчанию по решению владельца | An advanced BitTorrent client programmed in C++, based on Qt toolkit and libtorrent-rasterbar |
| `qemu-desktop` | user | Виртуализация и устройства | A QEMU setup for desktop environments |
| `qt5-wayland` | system | Сессия и интерфейс | Provides APIs for Wayland |
| `qt6-multimedia` | system | Сессия и интерфейс | Classes for audio, video, radio and camera functionality |
| `qt6-wayland` | system | Сессия и интерфейс | Provides APIs for Wayland |
| `quickshell` | system | Сессия и интерфейс | Flexible toolkit for making desktop shells with QtQuick |
| `samba` | user | VPN, сеть и загрузки | SMB Fileserver and AD Domain server |
| `scrcpy` | user | Виртуализация и устройства | Display and control your Android device |
| `slurp` | system | Базовые приложения и поиск | Select a region in a Wayland compositor |
| `sof-firmware` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Sound Open Firmware |
| `sox` | user | Медиа и творчество | The Swiss Army knife of sound processing tools |
| `starship` | system | Оболочка и управление пакетами | The cross-shell prompt for astronauts |
| `steam` | user | Игры и совместимость | Valve's digital software delivery system |
| `stow` | system | Arch и установка | Manage installation of multiple softwares in the same directory tree |
| `stress` | user | Диагностика и эксперименты | A tool that stress tests your system (CPU, memory, I/O, disks) |
| `stress-ng` | user | Диагностика и эксперименты | Software to stress test a computer system in various selectable ways |
| `sudo` | system | Arch и установка | Give certain users the ability to run some commands as root |
| `sushi` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | A quick previewer for Nautilus |
| `swappy` | user | Медиа и творчество | A Wayland native snapshot editing tool |
| `swaync` | system | Сессия и интерфейс | A simple GTK based notification daemon for Sway |
| `swtpm` | user | Виртуализация и устройства | Libtpms-based TPM emulator with socket, character device, and Linux CUSE interface |
| `sysfsutils` | user | Диагностика и эксперименты | System Utilities Based on Sysfs |
| `system-config-printer` | user | Печать и сканирование | A CUPS printer configuration tool and status applet |
| `systemctl-tui` | user | Диагностика и эксперименты | A fast, simple TUI for interacting with systemd services and their logs |
| `sysz` | user | Диагностика и эксперименты | fzf terminal UI for systemctl |
| `telegram-desktop` | user | Необязательный; чекбокс включён по умолчанию | Official Telegram Desktop client |
| `terminaltexteffects-git` | system | Штатная заставка из quickseek | Visual effects engine applied to text in the terminal. |
| `terraform` | user | Разработка и инфраструктура | HashiCorp tool for building and updating infrastructure as code idempotently |
| `terragrunt` | user | Разработка и инфраструктура | Thin wrapper for Terraform and OpenTofu for working with multiple modules |
| `tesseract-data-eng` | system | Базовые приложения и поиск | Tesseract OCR data (eng) |
| `tesseract-data-rus` | system | Базовые приложения и поиск | Tesseract OCR data (rus) |
| `texlive-basic` | user | Офис, книги и учёба | TeX Live - Essential programs and files |
| `texlive-bibtexextra` | user | Офис, книги и учёба | TeX Live - BibTeX additional styles |
| `texlive-binextra` | user | Офис, книги и учёба | TeX Live - TeX auxiliary programs |
| `texlive-fontsrecommended` | user | Офис, книги и учёба | TeX Live - Recommended fonts |
| `texlive-langcyrillic` | user | Офис, книги и учёба | TeX Live - Cyrillic |
| `texlive-latex` | user | Офис, книги и учёба | TeX Live - LaTeX fundamental packages |
| `texlive-latexextra` | user | Офис, книги и учёба | TeX Live - LaTeX additional packages |
| `texlive-latexrecommended` | user | Офис, книги и учёба | TeX Live - LaTeX recommended packages |
| `texlive-mathscience` | user | Офис, книги и учёба | TeX Live - Mathematics, natural sciences, computer science packages |
| `texlive-plaingeneric` | user | Офис, книги и учёба | TeX Live - Plain (La)TeX packages |
| `tk` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | A windowing toolkit for use with tcl |
| `tldr` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Command line client for tldr, a collection of simplified man pages. |
| `tmon` | user | Диагностика и эксперименты | Monitoring and Testing Tool for Linux kernel thermal subsystem |
| `tmux` | user | Дополнительные терминалы и редакторы | Terminal multiplexer |
| `toilet` | user | Оформление и развлечения терминала | Free replacement for the FIGlet utility |
| `trash-cli` | system | Оболочка и управление пакетами | Command line trashcan (recycle bin) interface |
| `tree` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | A directory listing program displaying a depth indented list of files |
| `ttf-cascadia-code` | user | Дополнительные темы и шрифты | A monospaced font by Microsoft that includes programming ligatures |
| `ttf-cascadia-code-nerd` | system | Тема и используемые шрифты | Patched font Cascadia Code (Caskaydia) from nerd fonts library |
| `ttf-cascadia-mono-nerd` | system | Тема и используемые шрифты | Patched font Cascadia Mono (Caskaydia) from nerd fonts library |
| `ttf-dejavu` | user | Дополнительные темы и шрифты | Font family based on the Bitstream Vera Fonts with a wider range of characters |
| `ttf-jetbrains-mono-nerd` | user | Дополнительные темы и шрифты | Patched font JetBrains Mono from nerd fonts library |
| `ttf-linux-libertine` | user | Дополнительные темы и шрифты | Serif (Libertine) and Sans Serif (Biolinum) OpenType fonts with large Unicode coverage |
| `ttf-material-symbols-variable` | system | Тема и используемые шрифты | Material Design icons by Google (Material Symbols - 4 axis variable) |
| `ttf-meslo` | user | Дополнительные темы и шрифты | Meslo LG is a customized version of Apple's Menlo font with various line gap and dotted zero |
| `ttf-nerd-fonts-symbols` | user | Дополнительные темы и шрифты | High number of extra glyphs from popular 'iconic fonts' |
| `ttf-nerd-fonts-symbols-mono` | user | Дополнительные темы и шрифты | High number of extra glyphs from popular 'iconic fonts' (monospace) |
| `ttf-ubuntu-font-family` | user | Дополнительные темы и шрифты | Ubuntu font family |
| `tuime` | user | Оформление и развлечения терминала | A colorful and fun TUI clock written in Rust, with a screensaver mode |
| `turbostat` | user | Диагностика и эксперименты | Report processor frequency and idle statistics |
| `ufw` | user | Дополнительная аутентификация и защита | Uncomplicated and easy to use CLI tool for managing a netfilter firewall |
| `unzip` | system | Arch и установка | For extracting and viewing files in .zip archives |
| `usbip` | user | Виртуализация и устройства | An USB device sharing system over IP network |
| `usbmuxd` | user | Виртуализация и устройства | USB Multiplex Daemon |
| `uv` | user | Разработка и инфраструктура | An extremely fast Python package installer and resolver written in Rust |
| `uwsm` | system | Сессия и интерфейс | A standalone Wayland session manager |
| `valkey` | user | Разработка и инфраструктура | An in-memory database that persists on disk |
| `vde2` | user | Виртуализация и устройства | Virtual Distributed Ethernet for emulators like qemu |
| `video-trimmer` | user | Медиа и творчество | Cut out a fragment of a video quickly |
| `vim` | user | Дополнительные терминалы и редакторы | Vi Improved, a highly configurable, improved version of the vi text editor |
| `vimix-cursors` | user | Дополнительные темы и шрифты | An X Cursor theme inspired by Material design and based on capitaine-cursors |
| `virt-manager` | user | Виртуализация и устройства | Desktop user interface for managing virtual machines |
| `virtualbox` | user | Виртуализация и устройства | Powerful x86 virtualization for enterprise as well as home use |
| `virtualbox-host-dkms` | user | Виртуализация и устройства | VirtualBox Host kernel modules sources |
| `visual-studio-code-bin` | user | Разработка и инфраструктура | Visual Studio Code (vscode): Editor for building and debugging modern web and cloud applications (official binary version) |
| `vitetris` | user | Оформление и развлечения терминала | Virtual terminal *tris clone |
| `vulkan-intel` | hardware:msi | Загрузка, графика, питание и восстановление MSI | Open-source Vulkan driver for Intel GPUs |
| `wallust` | system | Сессия и интерфейс | Generate colors from an image |
| `waybar-git` | system | Сессия и интерфейс | Highly customizable Wayland bar for Sway and Wlroots based compositors |
| `waydroid` | user | Виртуализация и устройства | A container-based approach to boot a full Android system on a regular Linux system |
| `wayfreeze-git` | system | Базовые приложения и поиск | Tool to freeze the screen of a Wayland compositor |
| `waypaper` | user | Дополнительные GUI и прежние компоненты | GUI wallpaper setter for Wayland and Xorg window managers. It works as a frontend for popular wallpaper backends like swaybg, swww, wallutils, hyprpaper and feh. |
| `wev` | user | Дополнительные GUI и прежние компоненты | A tool for debugging wayland events on a Wayland window, analagous to the X11 tool xev |
| `wget` | system | Arch и установка | Network utility to retrieve files from the web |
| `windscribe` | user | VPN, сеть и загрузки | Windscribe Client |
| `wine` | user | Игры и совместимость | A compatibility layer for running Windows programs |
| `wine-mono` | user | Игры и совместимость | Wine's built-in replacement for Microsoft's .NET Framework |
| `wireguard-tools` | user | VPN, сеть и загрузки | next generation secure network tunnel - tools for configuration |
| `wireless_tools` | user | VPN, сеть и загрузки | Tools allowing to manipulate the Wireless Extensions |
| `wiremix` | system | Сеть, звук и кнопки Waybar | A simple TUI audio mixer for PipeWire |
| `wireplumber` | system | Сеть, звук и кнопки Waybar | Session / policy manager implementation for PipeWire |
| `wl-clipboard` | system | Сессия и интерфейс | Command-line copy/paste utilities for Wayland |
| `woff2-font-awesome` | user | Дополнительные темы и шрифты | Iconic font designed for Bootstrap - woff2 format |
| `x86_energy_perf_policy` | user | Диагностика и эксперименты | Read or write MSR_IA32_ENERGY_PERF_BIAS |
| `xboxdrv` | user | Игры и совместимость | Userspace Xbox gamepad driver and input remapper |
| `xclip` | user | Дополнительные GUI и прежние компоненты | Command line interface to the X11 clipboard |
| `xdg-desktop-portal-gtk` | system | GTK порталы | A backend implementation for xdg-desktop-portal using GTK |
| `xdg-desktop-portal-hyprland` | system | Screen sharing и порталы Hyprland | xdg-desktop-portal backend for hyprland |
| `xdg-desktop-portal-kde` | user | Дополнительный backend: текущий portals.conf использует hyprland;gtk | A backend implementation for xdg-desktop-portal using Qt/KF5 |
| `xdg-user-dirs` | system | Стандартные пользовательские каталоги | Manage user directories like ~/Desktop and ~/Music |
| `xdotool` | user | Дополнительные GUI и прежние компоненты | Command-line X11 automation tool |
| `xf86-video-intel` | user | Дополнительные GUI и прежние компоненты | X.org Intel i810/i830/i915/945G/G965+ video drivers |
| `xmlada` | user | Разработка и инфраструктура | An XML parser for Ada. |
| `xorg-server` | user | Дополнительные GUI и прежние компоненты | Xorg X server |
| `xorg-xev` | user | Дополнительные GUI и прежние компоненты | Print contents of X events |
| `xorg-xinput` | user | Дополнительные GUI и прежние компоненты | Small commandline tool to configure devices |
| `xpadneo-dkms` | user | Игры и совместимость | Advanced Linux Driver for Xbox One Wireless Gamepad |
| `yad` | user | Дополнительные GUI и прежние компоненты | A fork of zenity - display graphical dialogs from shell scripts or command line |
| `yay` | system | Arch и установка | Yet another yogurt. Pacman wrapper and AUR helper written in go. |
| `yay-debug` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Detached debugging symbols for yay |
| `yazi` | user | Дополнительные терминалы и редакторы | Blazing fast terminal file manager written in Rust, based on async I/O |
| `yt-dlp` | user | Медиа и творчество | A youtube-dl fork with additional features and fixes |
| `zed` | user | Разработка и инфраструктура | A high-performance, multiplayer code editor from the creators of Atom and Tree-sitter |
| `zerotier-one` | user | VPN, сеть и загрузки | Creates virtual Ethernet networks of almost unlimited size. |
| `zip` | system | Arch и установка | Compressor/archiver for creating and modifying zipfiles |
| `zsh` | system | Arch и установка | A very advanced and programmable command interpreter (shell) for UNIX |
| `zsh-autocomplete` | user | Дополнительный пакет; обязательный вызов не подтверждён — проверить перед реализацией | Real-time type-ahead completion for Zsh |
| `zsh-autosuggestions` | system | Оболочка и управление пакетами | Fish-like autosuggestions for zsh |

## Дополнения к явным требованиям system

| Пакет | Основание | Уже установлен |
|---|---|---|
| `bluez` | Bluetooth через Quickshell и Waybar | да |
| `bluez-utils` | bluetoothctl в Control Center | да |
| `breeze` | Текущий Qt-стиль | да |
| `cmake` | Сборка hymission/HyprCapture | да |
| `ffmpeg` | Превью видео и сборка HyprCapture | да |
| `fftw` | HyprCapture | да |
| `file` | Определение формата превью | да |
| `fontconfig` | fc-match для отрисовки часов | да |
| `glib2` | gio/gsettings и сборка плагинов | да |
| `gsettings-desktop-schemas` | Настройки GTK/GNOME | да |
| `gtk4` | Battery Monitor и hymission | да |
| `gtk4-layer-shell` | hymission-search-input | да |
| `jq` | JSON в скриптах панели и Control Center | да |
| `layer-shell-qt` | HyprCapture UI | да |
| `libadwaita` | Battery Monitor и hymission | да |
| `libpulse` | pactl и сборка HyprCapture | да |
| `libqalculate` | qalc в quickseek | да |
| `libvips` | vips/vipsthumbnail для обоев и превью quickseek | да |
| `lua` | Lua API плагинов | да |
| `networkmanager` | nmcli и существующая сеть; настройки backend iwd сохранить отдельно | да |
| `opencv` | HyprCapture | да |
| `papers` | Основной PDF-просмотрщик по решению владельца | да |
| `pipewire` | Аудиосервер | да |
| `pkgconf` | Проверка зависимостей плагинов | да |
| `plasma-integration` | QT_QPA_PLATFORMTHEME=kde | да |
| `playerctl` | Медиаклавиши, Waybar и suspend quickseek | да |
| `poppler` | pdftoppm для PDF-превью | да |
| `python` | Скрипты окружения и quickseek | да |
| `python-gobject` | sleep-hold и Battery Monitor | да |
| `python-numpy` | Группировка обоев и стекло hyprlock | да |
| `python-pillow` | Обои и стекло hyprlock | да |
| `qt6-base` | HyprCapture UI | да |
| `qt6-svg` | HyprCapture UI | да |
| `ripgrep` | Поиск LazyVim | да |
| `tesseract` | OCR по Super+O | да |
| `xdg-utils` | Открытие файлов и MIME | да |

## Проверка полноты и ограничения

Явных пакетов без узкой функциональной категории (по умолчанию предложены user): auto-cpufreq, electron33-bin, fastfetch, gst-libav, gst-plugins-bad, gst-plugins-ugly, inotify-tools, sushi, tk, tldr, tree, yay-debug, zsh-autocomplete.

Часть библиотек была явно установлена, но фактически нужна только как зависимость. На этапе реализации её следует удалить из списка корневых требований, если она не используется непосредственно; сами библиотеки установит pacman. Исключение — сборочные зависимости собственных репозиториев, которые не описаны пакетным менеджером.

Инвентаризация не читала реальные секреты и не меняла ~/.zshenv, установленные пакеты, службы, /etc, плагины или живую сессию.

Для неиспользуемых отладочных пакетов (например, yay-debug), старых runtime и библиотек в user-части таблицы выбор scope не означает рекомендацию явно устанавливать их: они либо нужны как зависимости выбранной программы, либо вообще исключаются из корневых списков. auto-cpufreq не включается одновременно с текущим power-profiles-daemon по умолчанию.

## Подготовленные изображения

Расположение: `wallust/.local/share/dotfiles/defaults/`. Копии подготовлены в репозитории; установка в домашние каталоги и случайный выбор ещё не реализованы. Текущие обои и pfp не менялись.

- `wallpapers/sundown_mountain.jpg` — SHA-256 `4a5db8c6363fb94d26f0d77b2a80f819f6577f1acf3b1f45a6e1abc13a74b45e`.
- `wallpapers/symmetry-in-the-stillness.jpg` — SHA-256 `684b3adacb2fec762b8f3db1c1368252e79f7ea47bac03c3d8040c6f3d687668`.
- `wallpapers/dark-star.jpg` — SHA-256 `59dc554b2fe81f79b1f89258f838315fbad79d5a71cfd1508f29c56b85acfdbb`.
- `wallpapers/car_on_mars.jpg` — SHA-256 `4beb6e378c463755c342cf9bc1d04ab2f74c5fd1552f9355bc95b84d1c3cd433`.
- `wallpapers/mountain-winter3.jpg` — SHA-256 `f008a930c86112bb2a01521ebc9dc4f9989ee36c0cb70541e8afa3088dadaac1`.
- `avatar.jpg` — копия `~/Pictures/pfp/current_pfp.jpg`, которую использует шаблон hyprlock (розовая плюшевая свинка с ноутбуком).

## Сводка согласованного поведения установщика

1. База обязательна: рабочая сессия, штатные функции окружения, текущие основные обработчики файлов с согласованными исключениями KeePassXC/qBittorrent, Oh My Zsh и используемые плагины, собственные приложения и плагины Hyprland.
2. User: выбор чекбоксами; KeePassXC, qBittorrent, Telegram, Discord отмечены изначально. Отдельный личный профиль выбора не сохраняется.
3. Hardware: явный выбор профиля ноутбука с подсказкой по модели; сканер, Xbox, отпечаток, распознавание лица — отдельные опции.
4. Общая политика питания: Eco на батарее, Balanced при зарядке; MSI EC и ограничения заряда применяются только с соответствующим аппаратным профилем.
5. Установка пропускает невыбранные программы, ничего не удаляет; необязательные конфиги и URI-ассоциации следуют выбору приложений.
6. AI-разметка: одна опция Ollama + Gemma. Без опции выбиралка продолжает работать, запрос разметки корректно сообщает о недоступности.
7. Пять подготовленных обоев: случайный первый фон, текущий фон при повторном запуске сохраняется. Pfp входит в поставку; существующая пользовательская аватарка сохраняется.
8. Env создаётся из example с пустыми секретами; существующие секреты не перезаписываются.

Владелец подтвердил итоговую схему и поручил реализацию. Установщик и разделённый каталог реализованы; текущая система не разворачивалась. Проверки и оставшиеся ограничения — в INSTALL.md.
