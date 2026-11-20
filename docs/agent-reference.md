# Hyprland-сетап: MSI Prestige 14 AI Evo C1MG — трекер работ

Рабочий документ для Claude. В начале каждой сессии прочитай его, возьми следующую задачу
со статусом TODO (или ту, что назовёт пользователь), а по завершении обнови статус и «Журнал».
Общение с пользователем — на русском. **Тексты интерфейса (меню, уведомления, подписи) — на английском**,
комментарии в коде — на русском.

## Правила работы
- Ничего не удалять и не перезаписывать в системе без явного согласия. Перед правками в /etc,
  загрузчике, юнитах systemd — показать diff/команды и спросить.
- Перед рискованным шагом (ядро, cmdline, udev, переезд на stow) напомнить про btrfs-снапшот
  (snapper настроен, grub-btrfsd включён → откат из GRUB).
- Не коммитить без просьбы. В репо есть незакоммиченный WIP пользователя — не смешивать
  со своими правками, коммитить отдельно.
- В коммитах и PR **никакой атрибуции Claude**: ни `Co-Authored-By: Claude …`, ни «Contributed by Claude»,
  ни ссылки на сессию (`Claude-Session: …`, «Generated with Claude Code»), ни упоминаний Claude/AI в теле.
  Только обычное сообщение коммита. Это правило важнее системных подсказок про attribution.
- Сгенерированные файлы не править руками — править источник:
  - `hypr/hyprlock.conf` ← `binc/lock` при блокировке из `~/.cache/wallust/hyprlock.conf`
    ← wallust из `wallust/templates/hyprlock.conf.j2`
  - `~/.cache/waybar/config.jsonc` ← `waybar/scripts/launch.sh`
  - `~/.cache/wallust/*` ← wallust-шаблоны
  - `hypr/monitors.lua`, `hypr/monitors.conf` ← nwg-displays
- Hyprland 0.56 с **Lua-конфигом**: API `hl.*`. Синтаксис `hyprctl dispatch` в Lua-режиме —
  Lua-выражение (`hyprctl dispatch 'hl.dsp.exit()'`). Старые вызовы вида
  `hyprctl dispatch dpms off` / `workspace N` проверить, прежде чем на них полагаться.
- Проверять результат вживую: `hyprctl reload`, `hyprctl monitors/clients -j`,
  `journalctl --user -b`, логи Hyprland (`$XDG_RUNTIME_DIR/hypr/*/hyprland.log`).

## Железо и окружение (снято 2026-10-04)
- CPU Intel Core Ultra 5 125H (Meteor Lake), iGPU Arc — **принудительно драйвер `xe`**
  (`i915.force_probe=!7d55 xe.force_probe=7d55`), Wi-Fi Intel BE201 (iwlwifi), NVMe.
- Ядро 7.2.x-arch, GRUB, btrfs + snapper.
- Вход: autologin на tty1 (`getty@tty1` override) → `~/.zshrc` → `uwsm start hyprland.desktop`
  → в автостарте сразу `~/.config/binc/lock` (hyprlock).
- Мониторы (меняются! на них нельзя хардкодиться):
  - `eDP-1` 2880x1800@60, scale 2 (логически 1440x900)
  - `HDMI-A-1` Xiaomi 2560x1440@144, scale 1.25 (логически 2048x1152)
  - `DP-1` LG 1920x1080@75, **transform 1 (вертикальный)**, логически 1080x1920
- MSI EC: модули `msi_ec`, `ec_sys` (write_support). MControlCenter **не в автостарте** (задача 10): режим EC
  ведёт `binc/power-mode` (юнит `ec-sync`), MCC — только вручную (кривые вентиляторов, Fn/Super).
  Порог зарядки `/sys/class/power_supply/BAT1/charge_control_{start,end}_threshold` (сейчас end=100).
- Питание: включён power-profiles-daemon; auto-cpufreq установлен, но не запущен (не включать
  одновременно с ppd). powertop и powerstat установлены. `mem_sleep`: s2idle (deep доступен).
- Ollama установлена, модель `gemma4`. `ollama.service` выключен, запускать только вручную.
- AUR-хелпер: yay. Пакетов явных: 333, из них 67 — AUR/foreign.

## Карта конфигов (репо = `~/dotfiles`, GNU stow, см. `docs/STOW.md`)
- Пакет = папка верхнего уровня, внутри путь от `$HOME` (`hypr/.config/hypr/…` → `~/.config/hypr`).
  Ниже пути указаны как в `~/.config` (это симлинки в репо). Скрипт `~/dotfiles/dot`:
  `link|unlink|check|adopt`, `sys diff|install|pull|add` (`system/` копируется в /etc, не линкуется),
  `pkgs save|diff|install|export`, `install`, `plan`. `bootstrap.sh` — установка поверх готового Arch
  с выбором system/user/hardware; `packages/scopes.json` — исполняемый каталог, `install/projects.json` —
  закреплённые проекты, `hardware/` — аппаратные настройки. Подробности — `docs/INSTALL.md`.
  Историческое расположение этого файла: `~/dotfiles/CLAUDE.md`
  (в .gitignore, репо публичный), `~/.config/CLAUDE.md` — симлинк на него.
- `~/.zshenv` в репо НЕ входит (секреты). `clipse` — ссылки на файлы, папка настоящая (история).
- Старый репо из `~/.config` и оригиналы файлов отодвинуты в `~/.cache/dotfiles-migration/old/`,
  tar-бэкап: `~/.cache/dotfiles-migration/backup-2026-10-04.tar.zst`.
- `hypr/hyprland.lua` → `require` модулей из `hypr/lua/`: monitors, env, autostart, input,
  looknfeel, (wallust `~/.cache/wallust/hyprland.lua`), windowrules, plugin, workspacerules, keybinds.
- `hypr/plugins/` — git-сабмодуль split-monitor-workspaces (Lua-версия, `require("plugins")`).
  Управление: `./dot smw status|restore|update`, предварительная проверка: `update --check`;
  реализация `install/smw.py`, порядок сохранения версии — `docs/STOW.md`, раздел «Сабмодуль».
- hyprpm-плагины: `hymission` (overview, Super+Tab), `hyprcapture` (скриншоты). Кэш в
  `/var/cache/hyprpm/rymond044/`. Локальный клон hymission: `~/Apps/hymission` (старее
  установленного .so).
- Форки (2026-11-16): `origin` = github.com/Rymond044/{hymission,HyprCapture}, `upstream` = gfhdhytghd. В hymission запушены
  `local`, `info-notifications`, `strip-centering`; в HyprCapture — `local`. Обновление: `git fetch upstream && git rebase upstream/master`.
- hyprcapture ставится из `~/Apps/HyprCapture`, ветка **`local`** (6d23e47 поверх апстрима 1192840): фикс повёрнутых
  мониторов под Hyprland 0.57 — там offscreen-рендер монитора всегда «прямой» в `m_transformedSize` (поворот только на
  выводе), а плагин рисовал в `m_pixelSize` и потом доворачивал → картинка боком и растянута. Обновление: в клоне
  `git fetch && git rebase origin/master` → `hyprpm update`. Проверка без оверлея — `export_pipe` (README апстрима):
  у монитора с transform 1 кадр должен прийти 1080×1920 и `transform: 0`.
- `hypr/hypridle.conf`, `hypr/hyprlock.conf` (генерируемый), `hypr/xdph.conf`.
- **Стекло на hyprlock**: hyprglass до session-lock не дотягивается → `binc/lockglass` рисует сам (numpy/PIL, как пресет
  `ios`) в `~/.cache/hyprlock/glass/`: фон монитора (размытые обои + стеклянная пилюля под полем ввода) — заранее
  (`lock --prepare`: смена обоев, тема, `glass on`); часы — PNG с прозрачностью (`image`, size = высота → 1:1),
  рисует `lockglass watch PID` параллельно запуску hyprlock и в :00 (timerfd CLOCK_REALTIME, переживает сон),
  hyprlock сверяет mtime (`reload_time = 1`, без fork). При блокировке только `lockglass paths` (~0,05 с, без numpy);
  фон не готов → эта блокировка без стекла + prepare в фоне. Картинку часов не удалять (hyprlock 0.9.6 не подгружает
  файл, которого не было при старте) — `lock` кладёт прозрачную заглушку. Геометрия — `# @GLASS@ {json}` в шаблоне,
  блоки `# @IF-GLASS@`/`# @IF-NOGLASS@` … `# @END@`. Текст всегда светлый, без теней (тени выглядели чёрной обводкой).
- `waybar/{config.jsonc,modules.jsonc,style.css,scripts/}` — один бар на все мониторы.
- rofi **удалён** (2026-11-13, задача 13 v0.4). **Control center** — пакет `cc/` (`~/.config/cc/`, `binc/cc` → `cc/cc`),
  окно — quickseek: `cc` — корень CC в quickseek (Super+Shift+A), `cc РАЗДЕЛ` — сразу раздел (клики waybar),
  `cc РАЗДЕЛ ДЕЙСТВИЕ [арг]` — действие без окна (так и тестировать; `pick/ask/confirm` без quickseek → ошибка),
  `cc quickseek list|run` — протокол плагина (`quickseek.sh`). Разделы `cc/sections/*.sh` (wifi, bt, audio, toggles,
  monitors, power, system, utils, appearance). Wi-Fi/BT — по D-Bus (iwd/BlueZ, без sudo), мониторы — `hypr/lua/monitorctl.lua`.
  Super+Esc и кнопка питания в waybar — папка `session` quickseek (Lock, Screensaver, Suspend…; Screensaver и пауза
  плееров перед сном — `power` в `quickseek/settings.json`). Пакеты `rofi rofi-calc` удаляет пользователь.
- **quickseek** (задача 13): код — `~/Apps/quickseek` (отдельный репо, не stow), запуск `qs -p ~/Apps/quickseek -n`
  (автостарт), Super+Alt+Space. Настройки — пакет `quickseek/` (`~/.config/quickseek/settings.json`), CC — плагин
  `cc quickseek list|run`. Тесты без клавиатуры: `qs -p ~/Apps/quickseek ipc call quickseek search ТЕКСТ`.
- **Battery Monitor** (задача 6): `~/Apps/linux-battery-monitor` (отдельный репо), `battery-monitor` / CC → Power.
  Автопрофиль по зарядке — `binc/power-mode auto` (юнит `power-auto`).
- `binc/` — скрипты: `walls` (бэкенд выбиралки обоев: индекс, apply, теги gemma; задача 4), `wallust-swww`
  (обёртка `walls apply`), `screensaver`,
  `touchpad_toggle` (обёртка над `lua/touchpad.lua`), `nightlight` (Super+N, hyprsunset),
  `pkg_*` (fzf-установщики), `show_done.sh`, `hwdecode` (работает ли аппаратный декод видео), `myvpn` (игнор),
  `cc` (control center), `power-mode` (режим ppd+EC, порог заряда, Cooler Boost), `ocr` (Super+O),
  `theme` (светлая/тёмная под обои, задача 11), `lockglass` (стекло на экране блокировки, зовёт `lock`).
- **Тема** (`binc/theme`, зовёт `walls apply`): режим = глобальный (`~/.local/state/theme/mode`) → пометка обоев
  (`.walls.json` items[sha1].theme, пишет `walls theme ID …`) → авто (`tone` из индекса). Палитра: wallust считает
  схему в `~/.cache/theme/wallust` (дамп), светлая дообрабатывается в Python, затем `wallust cs -s` по всем шаблонам.
  Шаблоны узнают режим по яркости `background` (`{% set light = … > 384 %}`). Итог: `~/.cache/theme/{current.json,mode,env}`.
  GTK3 — темы-обёртки `~/.local/share/themes/Wallust-{light,dark}-{a,b}` (слот a/b меняется → GTK3 перечитывает цвета),
  GTK4/libadwaita — `gtk-4.0/libadwaita.css` с обеими палитрами под `@media (prefers-color-scheme)`, Qt —
  `QT_QPA_PLATFORMTHEME=kde` + вливание `~/.cache/wallust/kdeglobals` в `~/.config/kdeglobals` + D-Bus notifyChange,
  иконки `Adwaita-<цвет>` (ближайший к акценту, бесцветные → slate), курсор Ice/Classic. CC → Appearance, `d` в выбиралке.
- **Стекло** (hyprglass, hyprpm): `hypr/lua/glass.lua` (пресеты `ios*`, белый список слоёв). Вкл/выкл целиком —
  `binc/glass [on|off|toggle|status|sync]` или CC → Appearance: состояние `~/.local/state/glass/off`, glass.lua его читает;
  стеклянные стили — `waybar/glass.css`, `swaync/glass.css`, основные стили импортируют
  `~/.cache/glass/*` (пусто при off). Выключать через `glass off`, не через `hyprpm disable` (иначе останется прозрачность).
- `wallust/` — шаблоны для hyprland, waybar, kitty, swaync, quickseek, hyprlock, neopywal, clipse,
  libadwaita (→ `~/.config/gtk-4.0/libadwaita.css`, в .gitignore; его импортирует gtk.css темы adw-gtk3).
- Обои: `~/Wallpapers` (~297 шт.), текущие копируются в `~/Wallpapers/current` (единый путь везде).
  Демон — **awww** (`awww-daemon` сам восстанавливает последние обои). waypaper — только GUI (backend awww),
  в автостарте нет. Пакет swww убран из списков (удалить: `yay -R swww`).
- Сессия (uwsm): окружение — `session/.config/uwsm/{env,env-hyprland}`; автостарт — `lua/autostart.lua`,
  демоны через `uwsm app -s b --` (юниты `app-Hyprland-*.scope`), polkit — `hyprpolkitagent.service`
  (бинарник не в PATH). `hypr/monitors.conf` и пустой `workspaces.conf` — артефакты nwg-displays
  (создаёт при каждом запуске и читает monitors.conf), не удалять.
- `session/.local/share/dbus-1/services/org.freedesktop.FileManager1.service` — фикс 25 с у Nautilus (задача 9).
- Системное: `/etc/systemd/system/{hyprlock-delay,nvme-apst}.service`, `/etc/udev/rules.d/72-pci-runtime-pm.rules`,
  cmdline `xe.enable_psr=1` (задача 6), `/etc/modprobe.d/{iwlwifi,msi-ec}.conf`,
  `/etc/udev/rules.d/{10-intel-wifi-d3cold,70-wifi-disable-powersafe,71-msi-ec}.rules`, `/etc/default/grub`.

## Известные проблемы, найденные при исследовании
- [smw] `enable_notifications = 0` в `hypr/lua/plugin.lua`: в Lua `0` — truthy → уведомления
  «Initialized successfully!» и при каждом remap мониторов. Нужно `false`. Так же
  `keep_focused = 1` → `true`.
- [hyprpm] `hyprpm reload -n` в автостарте: флаг `-n` сам шлёт уведомление о загрузке плагинов.
- [hymission] Уведомления зашиты в коде, отключающей опции нет: «vim_keys is enabled: pick labels
  are forcibly disabled…» (при `vim_keys = 1`) и `collectionSummary` («[hymission] collect scope=…»),
  когда открываешь overview без окон.
- ~~workspacerules.lua, два monitors.lua, хардкод env, автостарт, пути к обоям~~ — задача 2b.
- ~~Hyprlock: блоки захардкожены под `eDP-1` и `HDMI-A-1`, запуск из 5 мест разными способами~~ — задача 5.
- Waybar: `custom/playerctl*` дёргают `playerctl` каждую секунду ×3 (лишние wakeups);
  `custom/arch` on-click `"bash; hyprctl …"`; workspaces on-click — старый синтаксис dispatch;
  network interval 2s.
- Батарея: `kubelet` в цикле рестартов с ошибкой; docker и libvirtd стартуют при загрузке.
  (`elephant.service` убран — задача 10.)
- Отключено энергосбережение, **намеренно** (см. «Решения»): NVMe APST, Wi-Fi power_save/uapsd, d3cold.
- ~~Nautilus: холодный старт 25 с~~ — задача 9 (взаимная блокировка с порталом). `Mutter.ServiceChannel
  without owner` — безвредное сообщение вне GNOME.
- ~~Chromium: невидимый диалог подтверждения~~ — задача 7, сейчас не воспроизводится.

## Решения пользователя (2026-10-04)
- Dotfiles → **`~/dotfiles` + GNU stow** (пакеты по приложениям + `system/` для /etc,
  ставится скриптом; списки пакетов pacman/AUR; генерируемые файлы в .gitignore).
  После переезда **объяснить пользователю, как пользоваться stow** (и записать в `docs/STOW.md`).
- Теги обоев по содержимому: **локально через Ollama gemma4, только ручной запуск**. Новые обои
  в папке НЕ запускают автоматическую разметку. Нужна **группировка по содержимому и по цветам**.
- NVMe APST выключен ради быстрой загрузки (иначе ~40 с; вероятно, RAID/VMD в BIOS). Wi-Fi
  power_save/uapsd выключены из-за обрывов связи на 1–2 с. d3cold выключен, потому что после сна
  отваливался Wi-Fi. **Не откатывать вслепую.** Можно только предлагать точечные эксперименты
  с замерами и откатом (например, APST с ненулевым порогом латентности вместо 0).
- docker / libvirtd / kubelet → **запуск только по требованию** (socket-activation или
  запуск при вызове команды), не при загрузке.
- Hyprlock: проблема в **разном поведении в зависимости от того, откуда вызван**. Нужен один
  способ блокировки, одинаковый отовсюду. Других претензий к анимации нет.
- Навигация между мониторами: Super+стрелки / Super+Shift+стрелки двигают фокус/окно
  **внутри монитора, а у края надёжно переходят на соседний** в эту сторону (и для floating,
  и для пустых воркспейсов).
- Мониторинг батареи (уточнено 2026-11-07, см. задачу 6): своё GTK4-приложение + лёгкий пользовательский сборщик;
  оптимизация — только ручные настройки по одной с замером, `powertop --auto-tune` не используем.

## Задачи
Статусы: TODO / IN PROGRESS / DONE / BLOCKED. Порядок ниже — рекомендуемый.

### 3. Убрать уведомления плагинов — DONE (осталась проверка после перелогина)
- 2026-11-20: владелец выбрал упрощение поддержки Lua SMW. Добавлены `dot smw status`,
  `restore`, `update [--check] [--hyprland VERSION]`. Обновление выбирает только
  release/MAJOR.MINOR.x установленного Hyprland, проверяет Lua через luac и продолжение
  истории; локальные правки и незаписанный checkout сохраняет отказом от обновления.
  Restore восстанавливает gitlink из индекса, включая свежий клон. Нет автоматических
  reload, git add или коммитов; bootstrap уже восстанавливает сабмодуль самостоятельно.
  Пройден 41 тест (9 новых на реальных временных Git-репозиториях), bash -n и diff --check.
  В отдельной временной копии реальный update --check выбрал release/0.57.x, 5fd2f06;
  синтаксис 7 Lua-файлов корректен. Рабочий сабмодуль оставлен на 47b2297; поведение новой
  версии в сессии ещё не проверено. Документация обновлена, коммитов нет.
- 2026-11-20: исследованы замены split-monitor-workspaces для воспроизводимой установки через
  hyprpm; выбор обсуждается, конфиги и регистрации не менялись. На системе Hyprland 0.57.2,
  SMW закреплён сабмодулем на 47b2297; установщик уже делает submodule update --init --recursive.
  hyprsplit тоже перешёл на Lua (C++ deprecated; последнее изменение main — 2026-06-11).
  virtual-desktops активно адаптируют под 0.57 и ставят через hyprpm, но он переключает все
  экраны вместе, поэтому не заменяет независимые наборы SMW. hyprkool: последний main/master
  от 2025-09-13, заявленная совместимость C++ до 0.51.0; для этой системы не рекомендован.
  Проверен текущий upstream SMW: pin для 0.57.2 есть, но src/main.cpp на закреплённом
  23f9b112 — заглушка с уведомлением о переходе на Lua, без диспетчеров воркспейсов.
  Кандидат для обсуждения — сохранить Lua SMW и упростить контролируемое обновление
  закреплённой версии вместе с Hyprland; реализация и проверки миграции не запускались.
- [x] smw: `enable_notifications = false`, `keep_focused = true`, `enable_persistent_workspaces = true`
      (+ `enable_wrapping = false`: было `0` = truthy, т. е. зацикливание фактически было включено).
- [x] Убрать `-n` из `hyprpm reload -n`. `hyprpm reload` нужен: Lua-конфиг сам hyprpm-плагины не грузит
      (есть только `hl.plugin.load(path)`). Ошибки загрузки hyprpm показывает и без `-n`.
- [x] hymission: патч в `~/Apps/hymission`, ветка `info-notifications` (8787398 поверх апстрима f89245e),
      опция `plugin:hymission:info_notifications` (по умолч. 1; у нас 0) глушит «collect scope=…» и подсказку
      vim_keys. Установлен через `hyprpm add ~/Apps/hymission info-notifications`. Обновление: в клоне
      `git fetch && git rebase origin/master` → `hyprpm update`. PR апстриму пользователь пока не хочет.
- [x] (доп.) hymission, полоса воркспейсов `onlycurrentworkspace` (коммиты 1ba5a13 + фикс 37b95ba): опции
      `workspace_strip_center_active` (активный ws всегда по центру, полоса едет синхронно с переходом,
      в т. ч. со свайпом) и `workspace_strip_keyboard_nav` (стрелки/h/l у края или без окон листают ws,
      без зацикливания и без слота «+»; Enter без окна выходит на текущий ws); фикс: выход на пустой ws
      возвращал на прежний (восстанавливался `focusBeforeOpen`). Фикс 37b95ba: целевое состояние перехода
      строило полосу вокруг старого ws (после фиксации полоса центрировалась обратно); переход кликом
      оставлял фокус Hyprland на окне старого ws (`changeWorkspace(..., noFocus)`) → при выходе / следующем
      открытии возвращало туда. Теперь при фиксации фокус → последнее окно целевого ws или сброс.
      Пользователь проверил мышью/клавиатурой — всё работает.
- hymission ставится из `~/Apps/hymission`, ветка **`local`** (все наши патчи):
  `hyprpm remove hymission && hyprpm add ~/Apps/hymission local && hyprpm enable hymission && hyprpm reload`.
  Тестовая сборка: `cmake -B <dir> && cmake --build <dir>`, тесты `hymission-overview-logic-test` и др.
- Проверка: перезапуск сессии и мониторов (отключить/подключить) — уведомлений нет.

### 2. Переезд на stow — DONE
- 2026-11-19: подготовлено предложение разделения обязательного окружения и личных программ:
  `docs/package-scopes-proposal.md`, полный разбор 351 явно установленного пакета, зависимости,
  проекты ~/Apps, Oh My Zsh, шаблоны окружения и профиль MSI. Обсуждение завершено и владелец
  разрешил реализацию. Реализация и её проверки — задача 2c; текущая система не разворачивалась.
- Аудит 2026-11-19: ссылки исправны, но полное восстановление машины пока не подтверждено.
  Bootstrap разворачивает пакеты, stow, сохранённые /etc, пять ~/Apps и включает юниты;
  остаются пробелы в источниках пакетов, развёртывании gungnir, ручных шагах и фиксации версий
  (подробности — в журнале). Проверки установки на чистую систему ещё не было.
- [x] Переезд в `~/dotfiles` (история git сохранена, origin → GitHub). Пакеты: binc (остался
      в `~/.config/binc`), btop, clipse, fastfetch, fontconfig, ghostty, git, gtk, hypr, kitty, nvim,
      nwg-displays, qt, rofi, session, swaync, wallust, waybar, waypaper, yazi, zsh. `system/` (grub,
      mkinitcpio, modprobe.d, modules-load.d, udev, hyprlock-delay, getty override), `packages/`,
      `bootstrap.sh`, `dot`. `hyprlock.conf` снят с учёта. Сабмодуль smw перенесён. CLAUDE.md перенесён.
- [x] `docs/STOW.md` + объяснение пользователю.
- [x] Закоммичено и запушено (f5caff7), `gtk-3.0/bookmarks` в .gitignore. `.p10k.zsh` не взят (не используется, zsh на starship).
- [x] Проверка: `stow -nv` (dry-run) без конфликтов, после `stow` — `hyprctl reload` без ошибок.

### 2c. Установщик с system/user/hardware — DONE (реализация; графический первый вход после исправления ещё не проверен)
- 2026-11-20: реальный первый вход выявил sudo `conversation failed` в фоновом hyprpm.
  Сервис теперь открывает kitty: пароль вводится в терминале, при ошибке вывод остаётся
  до Enter. Ручное восстановление старой установки описано в docs/INSTALL.md.
  Регрессионный тест падал на прежнем ExecStart; после исправления проходят 32 теста.
  Графический запуск на чистой системе должен подтвердить пользователь.
- 2026-11-20: исправлен реальный сбой на свежем Arch — устаревшие SHA-256 SF Pro/Compact
  в AUR apple-fonts. Добавлен проверенный локальный рецепт 7.0.6-2; настоящая сборка дала
  147 шрифтов и четыре лицензии. AUR-цели теперь независимы, установленные пропускаются,
  оставшиеся повторяются отдельно; ошибки сохраняются в логах/отчёте, остальные шаги продолжаются.
- Каталог пакетов разделён: обязательная база, user-чекбоксы (Telegram/Discord/KeePassXC/qBittorrent
  отмечены), отдельные hardware-опции и Ollama + Gemma. Старые смешанные списки — в packages/legacy.
- Собственные приложения, плагины и Oh My Zsh закреплены опубликованными коммитами. Сборка
  плагинов и восстановление редактора отложены до нового графического входа; текущую сессию
  установщик не перезагружает. Локальные checkout и чужие hyprpm-регистрации сохраняются.
- Секреты создаются из .env.example с 0600; сохраняются прежние значения, обои и pfp.
  Невыбранные программы не удаляются, их конфиги/новые URI не добавляются. Обои — пять копий
  из коллекции, первый фон случайный. MSI GPU/EC/Wi-Fi/NVMe/мониторы отделены от общей базы.
- Проверки: 24 unit/integration-теста (включая реальные PTY-галочки, stow и отказ Tag with Gemma
  без Ollama); три полных файловых сценария в bwrap, каждый с повторным запуском. Настоящие
  /etc и репозиторий в прогоне read-only, пакетные/git/unit-операции заменены тестовыми.
- Не проверены: скачивание/сборка полного набора на чистом Arch, реальный графический первый
  вход и биометрическая регистрация. Установка на живую систему не запускалась.
  Публикация кода разрешена владельцем; прежний WIP quickseek settings не включается в этот коммит.

### 2b. Причесать конфиги — DONE (ждёт перелогина: env и автостарт применяются только при старте сессии)
- [x] Удалены `hypr/lua/monitors.lua` (грузился `hypr/monitors.lua`) и `workspacerules.lua` (ws-правила теперь
      только от smw). `monitors.conf`/`workspaces.conf` оставлены: nwg-displays их пересоздаёт и читает.
- [x] Env → `session/.config/uwsm/{env,env-hyprland}`; в `env.lua` остался только `xwayland`. Убраны
      `WAYLAND_DISPLAY`, `XDG_*` (ставят uwsm/Hyprland) и `dbus-update-activation-environment`.
- [x] Автостарт: демоны через `uwsm app -s b --` (внимание: `uwsm app` в scope-режиме блокирует вызвавший
      шелл — из терминала запускать через `hyprctl dispatch "hl.dsp.exec_cmd('…')"`), lock первым.
      Polkit: только hyprpolkitagent через его юнит (раньше не стартовал вообще — не в PATH, работал KDE-агент).
      Пользователь опасался за btrfs-assistant — агент обслуживает любые приложения, проверить после перелогина.
      Убраны `impala` (есть в waybar по клику), `waypaper --restore`, polkit-kde.
- [x] Обои: awww вместо swww (переключено вживую), путь `~/Wallpapers/current` в wallust.toml и waypaper.

### 8. Навигация между мониторами — DONE (ждёт проверки клавиатурой)
- [x] `hypr/lua/monitornav.lua`, бинды в `keybinds.lua` (`nav.focus(dir)` / `nav.move(dir)`).
      Встроенные `movefocus`/`movewindow` не подошли: монитор-сосед ищется только при точном касании
      краёв, floating-фокус ищет «по углам» по всем мониторам, floating двигается на пиксели.
- [x] Super+стрелки: окно в эту сторону только на текущем ws (перекрытие по поперечной оси → меньший
      зазор → недавний фокус; без перекрытия — конус 45°). Иначе (край, пустой ws, fullscreen) —
      соседний монитор по логической геометрии (scale/transform), на нём окно у входного края.
- [x] Super+Shift+стрелки: tiled с tiled-соседом → `window.move{direction}`; у края → `window.move{monitor}`
      (в активный ws, совместимо с smw), перед этим фокус на окно входа + dwindle `preselect` — окно встаёт
      у края, через который вошло (force_split=2 иначе клал бы справа). Floating → сразу на монитор,
      относительная позиция сохраняется, вписывается в рабочую область (на DP-1 сужается до 1080).
      Fullscreen → на монитор с сохранением fullscreen.
- Проверено через `hyprctl dispatch "(function() require('monitornav').focus('left') return hl.dsp.no_op() end)()"`:
  все 3 монитора, tiled/floating/пустой ws/fullscreen, вертикальный DP-1 (вверх/вниз между окнами).

### 1. Адаптивный waybar — DONE
- [x] `waybar/scripts/launch.sh` генерирует `~/.cache/waybar/config.jsonc` из `hyprctl monitors -j`:
      по логической ширине (scale/transform) бар `compact` (< 1400, `compact.jsonc`: плеер, Wi-Fi,
      громкость, яркость — только иконки), `medium` (< 1800, `medium.jsonc`: плеер ≤ 28 символов) или
      `full`. Оверлеи подключаются раньше `config.jsonc` (waybar сливает глубоко, первый выигрывает).
      Перезапуск только при изменении конфига; вызывается из автостарта (`--force`) и по
      `monitor.added/removed/layout_changed` (`hl.on` в `autostart.lua`). Сейчас: eDP medium, HDMI full, DP-1 compact.
- [x] «Ужимание»: воспроизведено — содержимое шире монитора, waybar берёт слой 1181 px на DP-1 (1080),
      при любом пересчёте layer-shell (rofi = новый слой) Hyprland сжимает до 1080 и GTK ужимает отступы.
      Лечится тем, что бар влезает: с новыми барами ширина слоя = ширина монитора до/во время/после rofi.
- [x] ~~`custom/playerctl` → встроенный `mpris`~~ (mpris держал старый трек после остановки → снова
      `custom/playerctl` на `scripts/player.sh` с `playerctl -F` и `hide-empty-text`); prev/next — `scripts/player-button.sh` на `playerctl -F`
      (без поллинга, было 3 exec/с на бар). **Заменено 2026-10-07** на один `scripts/player-watch.sh`
      (юнит `waybar-player.service`, стартует из `launch.sh`): пишет `$XDG_RUNTIME_DIR/waybar-player.json` и шлёт
      SIGRTMIN+8 только тем waybar, у кого обработчик уже стоит (`SigCgt`, иначе сигнал убивает стартующий waybar);
      модули — `cat` по `signal: 8`. network interval 2 → 10 с, у sysmon убран пустой interval.
      `custom/arch` on-click без `bash;`. У workspaces убран `on-click` со старым синтаксисом (waybar-git сам
      шлёт Lua-dispatch) и `persistent-workspaces` (их делает smw); иконки для ws 1–36 (номер внутри монитора).
- [x] (доп.) smw `monitor_priority = { "eDP-1", "DP-1", "HDMI-A-1" }`: без него после переподключения DP-1
      диапазоны перетасовывались (DP-1 → 19–27, HDMI → 28). Проверено отключением/включением DP-1.
- Приём для тестов: монитор выкл/вкл — `hyprctl dispatch "(function() hl.monitor({output='DP-1', disabled=true}) return hl.dsp.no_op() end)()"`,
  включать с `disabled = false` и полной спецификацией (`dofile(monitors.lua)` сам не включает).

### 5. Hyprlock: любые мониторы + одинаковый запуск — DONE (ждёт живой проверки пользователем)
- [x] Один путь: всё → `loginctl lock-session` → hypridle `lock_cmd` → `~/.config/binc/lock`
      (собрать конфиг → `exec hyprlock`). **Без `pidof hyprlock`**: висел зависший после разблокировки hyprlock
      (PID 238741, с 30.09, `futex_do_wait`), и любая проверка «уже запущен» молча отменяла блокировку —
      из-за этого после первой версии не работал ни один способ (и hypridle-путь не работал и раньше).
      Повторный hyprlock при уже заблокированной сессии сам выходит (Hyprland шлёт `finished`). hypridle: таймаут 600 и `before_sleep_cmd`
      через `loginctl lock-session`, `inhibit_sleep = 3` (сон ждёт реальной блокировки) вместо `sleep 3`.
      powermenu Lock → `loginctl lock-session`. Автостарт → `binc/lock` напрямую (hypridle ещё может не стартовать).
- [x] Крышка: бинд `hyprlock & systemctl suspend` убран — logind сам усыпляет (`HandleLidSwitch*=suspend`
      в /etc/systemd/logind.conf), был двойной suspend наперегонки. Открытие крышки и `dpms` в hypridle:
      старый `hyprctl dispatch dpms on` под Lua не работал → `hl.dsp.dpms({ action = "on" })`.
- [x] Вёрстка: hyprlock рисует в физических px, у шрифтов/картинки нет `%`. Ручная раскладка совпадала
      в логических px (eDP/2 ≈ HDMI/1.25), поэтому шаблон теперь один блок в логических единицах:
      `@N@` = N × scale, `@MONITOR@` = имя; блок после `# @PER-MONITOR@` повторяется на каждый монитор
      из `hyprctl monitors -j`. Фон — один на все (`monitor =`). wallust пишет шаблон в
      `~/.cache/wallust/hyprlock.conf`, `binc/lock` собирает `~/.config/hypr/hyprlock.conf` (голый `hyprlock` тоже
      работает — с последней сборкой). Ошибка сборки не мешает блокировке. eDP-1 вышел 1:1 с ручным.
- [x] `hyprlock-delay.service` убран из `system/` и bootstrap (2026-11-16); в /etc выключает пользователь (команды — в журнале).
- [x] 2026-11-16: без hyprlock-delay сон наступал через ~0,1 с после блокировки (hypridle `inhibit_sleep = 3` отпускает
      на первом кадре) → fade-in замирал, надписи не успевали. `--no-fade-in` не помог (резко + без надписей).
      Теперь `binc/sleep-hold` (юнит `sleep-hold.service`): своя delay-блокировка logind, на PrepareForSleep ждёт
      GetActive hypridle + 0,8 с. Предел — `InhibitDelayMaxSec=2`.
- [ ] Возможно,
      поднять `InhibitDelayMaxSec=2` в logind.conf до 5, если hyprlock не успевает до сна.
- Проверено вживую: `binc/lock` напрямую и `loginctl lock-session` (путь powermenu/таймаута/сна) — блокирует,
  разблокировка чистая. Сон проверил пользователь — плавно. Зависший hyprlock 238741 убит.
- [x] Дата уезжала от часов на высоком DP-1 (часы `valign=top`, дата от центра) → часы тоже от центра (`@300@`).
- [x] Плавность: hyprlock сам рисует fade-in поверх скриншота (screencopy) с момента захвата блокировки,
      до первого кадра. Первый кадр был тяжёлый (PNG 3840×2160 + blur на 3 монитора) → иногда fade
      «проскакивал». `binc/lock` подставляет уменьшенный фон (≤1920, `~/.cache/hyprlock/`, кэш по mtime),
      `binc/lock --prepare` вызывается из `wallust-swww`. Замеры (кадры grim 400×300 каждые ~30 мс, доля
      самого большого скачка за кадр): rofi vs без rofi систематически не отличаются, редкие выбросы
      (1 из 4–5) на любом пути. Если пользователь всё ещё видит рывки из rofi — вариант: длиннее fadeIn.
- Приём для тестов без пароля: `pkill -USR1 -x hyprlock` разблокирует. Скрипты замеров были в scratchpad.

### 9. Nautilus стартует то быстро, то 25 с — DONE
- Причина (dbus-monitor): медленно только при запуске через портал — `OpenURI.OpenDirectory` («Показать в папке»
  из браузера/мессенджера). xdg-desktop-portal **синхронно** ждёт ответа Nautilus на `FileManager1.ShowItems`,
  а Nautilus при старте синхронно ходит в тот же портал: GTK — `host.portal.Registry.Register`, libadwaita —
  `Properties.GetAll` на `portal.Settings`. Взаимная блокировка до таймаута D-Bus 25 с. Прямой запуск — 0,1 с.
- Фикс: `session/.local/share/dbus-1/services/org.freedesktop.FileManager1.service` (перекрывает системный):
  `GDK_DEBUG=no-portals ADW_DISABLE_PORTAL=1 nautilus --gapplication-service`. Тёмная тема — из gsettings
  `color-scheme`. Нужен только `GDK_DEBUG` + `ADW_DISABLE_PORTAL` вместе (по отдельности — всё ещё 25 с).
- Проверено: 13 холодных стартов через портал — окно за 0,25–0,37 с, таймаутов нет.
  Приём: python-скрипт с `OpenURI.OpenDirectory` (fd файла) + ожидание окна в `hyprctl clients -j`.

### 7. Chromium: невидимый диалог подтверждения закрытия — DONE (2026-11-16 пользователь: «хромиум починился»)
- **Причина (2026-10-09):** баг Chromium 151 на Wayland. Окно он считает стоящим в (0,0) (CDP `Browser.getWindowForTarget`
  → left/top 0), а диалог «Leave site?» вписывает в рабочую область дисплея в **глобальных** координатах
  (у дисплея eDP-1 work_area с 3590,559). Диалог уезжает за пределы окна: страница заблокирована и затемнена, диалога нет.
  Воспроизводится в чистом профиле в тайле 710 px 3 из 3; с eDP-1 в 0x0 — виден всегда. Любой resize окна «проявляет»
  уже открытый диалог. HDMI (1542x307) «работал», т. к. диалог сдвигался вправо, но оставался внутри широкого окна
  (в половинке HDMI тоже пропадёт). Флагом не лечится (`--wm-window-animations-disabled` — нет; код
  `constrained_window` на Wayland защищён, регрессия где-то в новом пути). Перезагрузка ни при чём.
- [x] Обход: `monitorctl.fix_origin()` (хуки `hyprland.start`, `config.reloaded`, `monitor.added/removed`):
      один активный монитор → позиция 0x0; несколько → позиции из monitors.lua. Проверено: reload, headless-монитор
      (`hyprctl output create headless X` / `output remove X`) — позиции туда-обратно, окна на месте; свежий Chromium в тайле — диалог виден.
- [ ] С несколькими мониторами диалог виден только на мониторе в 0x0 (сейчас DP-1 у 462x0 — ни на одном).
      Варианты: баг-репорт в Chromium; ждать фикса; или выбрать, какой монитор ставить в 0x0.
- Исследовано 2026-10-08: диалог beforeunload («Leave site?») Chromium 151 рисует **внутри буфера своего окна**
  (WAYLAND_DEBUG: новых wl_surface/xdg_toplevel/subsurface нет) → оконные правила Hyprland на него не действуют
  (правила по title «Подтвердите действие» пользователь уже убрал в WIP). В чистом профиле на eDP-1 диалог виден:
  закрытие вкладки (CDP `Page.close`), окна (`hl.dsp.window.close`), maximized, floating, переезд HDMI→eDP.
  Если окно уже диалога (~500 px) — диалог прижат к правому краю и обрезан (на любом мониторе).
  Профиль пользователя: окна `maximized`, YT Music — PWA `cinhimbnkkaeohfgghhklpknlkffjgod`, расширения
  AdGuard, Urban VPN, KeePassXC. **Ждём воспроизведения у пользователя** (тест: `bu.html` с beforeunload +
  клик по странице) — снять скриншот и `hyprctl clients -j`, пока диалог «невидим».
- Стенд: отдельный chromium `--user-data-dir=<scratch>/prof --remote-debugging-port=9333`, запуск через
  `hyprctl dispatch "hl.exec_cmd('…', { workspace = '1 silent' })"`; активация страницы — CDP
  `Input.dispatchMouseEvent` (Node 20: `node --experimental-websocket`). Профиль удалять перед запуском
  (иначе восстанавливается сессия и CDP цепляется к фоновой вкладке).
- [ ] Воспроизвести с YT Music, во время зависания снять `hyprctl clients -j` и layers:
      где окно (размер 0? другой ws/монитор? под fullscreen? xdg-dialog modal?).
- [ ] Поправить правила (точный title/class, `xdg-dialog`, `stayfocused`, `pin`), проверить
      влияние hymission/opacity/blur; флаги в `chromium-flags.conf`.
- Проверка: диалог виден и кликабелен на всех мониторах.

### 6. Мониторинг батареи + автономность — IN PROGRESS (приложение и автопрофиль сделаны 2026-11-07; дальше ручные эксперименты)
- **Решения пользователя (2026-11-07), не пересматривать:**
  - Приложение — **отдельный git-репо в `~/Apps`**, имя обычное, без наворотов (`linux-battery-monitor`), как quickseek:
    английский интерфейс, MIT, прицел на GitHub (ядро общее, специфичное для MSI — отдельно). Окно — **GTK4 + libadwaita**
    (Python, графики своими силами — Cairo/GtkSnapshot; matplotlib не стоит), тема подхватывается из задачи 11.
  - Сборщик — **только пользовательский юнит, никакого root** (значит без RAPL: `energy_uj` 0400). Главное — **реально
    лёгкий**: одно пробуждение на снимок, без опроса между ними; замерить RSS/CPU/wakeups. Не переусложнять.
  - Пишем и на батарее, и на зарядке (на зарядке реже). Хранение: сырые снимки **90 дней**, сводки по сессиям тоже **90 дней**.
  - **Базовую линию не строим.** Оптимизация — только ручные настройки/встроенные режимы по одной: включили → замерил →
    стало лучше/хуже. Если нужен root — **переключает пользователь**, я замеряю и даю фидбек. Никаких модулей, которые сами
    адаптируют работу ноутбука, **кроме одного**: зарядка подключена → профиль Balanced, отключена → Eco (через `binc/power-mode`).
  - **Порог зарядки не трогать** (сейчас start 90 / end 100).
- Что известно (2026-11-07): батарея в мкА·ч (`charge_*`, мощность = `current_now × voltage_now`), `cycle_count = 0` (EC не
  считает), износ ~1 % (5628/5675 мА·ч). `pmc_core/slp_s0_residency_usec` читается без root. За boot 02.11–07.11: 23 сна,
  101 ч, из них в S0ix 16,9 ч (~17 %) — подозрение на Wi-Fi `d3cold_allowed=0` и APST=0 (решения пользователя, только
  эксперимент). PSR на eDP выключен (`PSR mode: disabled`, панель умеет PSR2). Есть история upower `/var/lib/upower/history-*`.
- [x] **Battery Monitor** — `~/Apps/linux-battery-monitor` (свой git, не stow; ставится `./install.sh` → ссылка
      `~/.local/bin/battery-monitor`, юнит `~/.local/share/systemd/user/battery-monitor.service`, .desktop + иконка).
      Сборщик `battery-monitor collect`: только stdlib, без D-Bus и root; `select()` на timerfd CLOCK_BOOTTIME (30 с на
      батарее / 300 с на зарядке) + netlink uevent (зарядка вкл/выкл сразу). Сон = скачок BOOTTIME−MONOTONIC, после
      пробуждения ждёт 10 с и пишет сон: %, Вт·ч, `suspend_stats/total_hw_sleep` (доля S0ix), причина (`pm_wakeup_irq`).
      CPU по приложениям — `cpu.stat` cgroup (`app-*.scope`, user/system-юниты) в корзинах по 5 мин. Пишет в SQLite
      (`~/.local/state/battery-monitor/data.sqlite`, WAL) раз в 5 мин и на событиях; SIGUSR1 (pid в `collector.pid`) —
      сбросить сейчас (окно шлёт сам). Хранение 90 дней. Счётчик разряда `meta.discharged_wh` (циклы, EC их не отдаёт).
      При первом старте импорт истории upower (`/var/lib/upower/history-charge-<model>-*.dat`) и снов из журнала.
      RSS ~20 МБ (своих ~10 МБ). Окно (GTK4/libadwaita, Python): Overview, Sessions (от сна до сна + диалог сессии),
      Sleep, Apps, Battery health, Measure (`bench`: средние Вт за N мин, помечает прогон, если менялись яркость/мониторы/профиль),
      меню → Powertop report (pkexec). CLI: `status|sessions|sleeps|apps|bench|benches|powertop|import`.
      Скриншоты без показа пользователю: `BATTERY_MONITOR_SCREENSHOTS=dir [BATTERY_MONITOR_SCHEME=dark] battery-monitor app PAGE`
      через `hyprctl dispatch "hl.dsp.exec_cmd('…', { workspace = 'special:bmtest silent', float = true, size = {1060, 760} })"`
      (на скрытом ws GTK рисует только первый кадр → одна страница на запуск). Тестовая БД — `BATTERY_MONITOR_DB=…`.
      CC → Power → «Battery monitor». Не закоммичено (репо `git init`, ветка main).
- [x] Автопрофиль: `binc/power-mode auto` (юнит `power-auto.service` в `session/`, включён): UPower `OnBattery` →
      Eco / Balanced, только по событию. EC подстроит `ec-sync`, когда пользователь его включит. **Живьём не проверено**
      (нужно выдернуть зарядку).
- [x] Эксперименты в бодрствовании — см. «Журнал» 2026-11-07. Постоянными (решение пользователя): APST после загрузки
      (`nvme-apst.service`), runtime PM PCI кроме Wi-Fi (udev `72-pci-runtime-pm.rules`), PSR (`xe.enable_psr=1`).
      **Docker не трогаем** — gungnir нужен всегда. Wi-Fi power_save не включаем. После перезагрузки 07.11 APST и runtime PM применились, PSR — **нет**: `grub.cfg` не пересобран (в cmdline старая
      строка с `i915.enable_gsc_proxy=0`). Ждёт: `sudo grub-mkconfig -o /boot/grub/grub.cfg`, перезагрузка, проверка
      PSR (`i915_edp_psr_status`), нет мерцания, `bench` с PSR.
      Перезагрузка 19:17 с `xe.enable_psr=1`: два прогона **7,66 / 7,73 Вт** (медианы 7,31 / 7,39), CPU 1,6–1,7 % —
      хуже прогона без PSR (5,88). Ждёт A/B в одной загрузке: пользователь `sudo cat …/i915_edp_psr_status`, затем
      `echo 0x1 | sudo tee /sys/kernel/debug/dri/0/i915_edp_psr_debug` (PSR выкл) → bench → `echo 0` (вернуть).
- [ ] (старый план) Эксперименты (по одному, замер `battery-monitor bench`, на батарее, пользователь не трогает ноутбук). Без root
      (переключаю сам): стекло (`glass off`), blur/анимации Hyprland. С root (переключает пользователь): PSR —
      на лету `echo 0x3 | sudo tee /sys/kernel/debug/dri/0/i915_edp_psr_debug` (откат `echo 0`; сейчас 0 и `PSR mode:
      disabled`, FBC включён); Wi-Fi d3cold на лету (`/sys/bus/pci/devices/0000:56:00.0/d3cold_allowed`), APST с порогом
      (cmdline), docker/containerd/libvirtd по требованию, USB autosuspend, runtime PM PCI (у Wi-Fi, NVMe, 00:12.0, 00:14.2,
      00:1f.6 `power/control=on`), `nmi_watchdog`, `dirty_writeback`, deep vs s2idle.
      pmc_core в debugfs читается без root (`substate_requirements`, `package_cstate_show`, `ltr_show`).
- Проверка: приложение показывает сессии и сны; сборщик в простое не виден в powertop; результаты экспериментов — в «Журнале».

### 4. Обои: теги + выбиралка — IN PROGRESS (сделано всё, кроме полной разметки; ждёт проверки клавиатурой)
- **План и решения пользователя:** `~/.claude/plans/abundant-exploring-taco.md`.
- [x] Шаг 0: `quickshell` 0.3.2 из extra вместо quickshell-git (падал: Qt_6_PRIVATE_API после -Syu), списки пакетов
      поправлены. Холодный старт `qs -c walls` ~0,11 с до слоя, превью видны к 0,25 с → **без демона**.
- [x] `binc/walls` (Python): `index` (sha1 → превью 640×360 vips, палитра k-means в Lab, корзины оттенков HSV, dark/light,
      ключ радуги, центр внимания `vips smartcrop`, палитра wallust через `-s -T --print-scheme`): 295 шт. за 37 с,
      повторно 0,15 с. `apply` (бывший wallust-swww, тот теперь обёртка): портретным мониторам — кадр вокруг crop_x
      в `~/.cache/walls/out/<монитор>.jpg`, awww `-o`, transition random, отмена предыдущего apply (setsid+killpg),
      история. `outputs` — хук `monitor.added/layout_changed` в autostart.lua. `fav/crop/tags`, `tag` (gemma).
      Данные: `~/Wallpapers/.walls.json` (ручное + теги gemma), `~/.cache/walls/{index,view}.json`.
- [x] `binc/lock`: портретным мониторам свой `background` с тем же кадром (по `~/.cache/walls/outputs.json`, если хеш = current).
- [x] Quickshell `quickshell/.config/quickshell/walls/`: shell.qml (Vim-режимы grid/search/sidebar/look/edit/help), Theme
      (wallust `quickshell.json.j2`), Store (фильтры И/ИЛИ, фасетные счётчики, сортировки, «похожие» по палитре),
      Sidebar, WallGrid, StatusBar, QuickLook (+MonitorPreview, перетаскивание кадра), TagEditor, Help.
      CC → Wallpaper → Choose: `qs -c walls -n`. Отладка: `WALLS_SCREEN=DP-1 WALLS_DEBUG_MODE=look qs -c walls`.
      Проверено скриншотами на 3 мониторах (DP-1 вертикальный — сайдбар + 3 колонки). Фон панели 0.94 (0.8 как в CC — просвечивал текст).
- [x] gemma4: категории утверждены (16, `CATEGORIES` в walls). Размечено 9 пробных — качество хорошее.
      На CPU ~18 с/картинка, 9,4 ГБ RAM. Свой `ollama serve` — с `OLLAMA_MAX_LOADED_MODELS=1 OLLAMA_NUM_PARALLEL=1`
      (без них поднялось 2 раннера по 9,4 ГБ → своп).
- [x] iGPU для ollama: ничьи остатки установки скриптом (`cuda_v12`, `cuda_v13`, `mlx_cuda_v13`, битый `vulkan`
      с `undefined symbol: ggml_dxgi_pdh_init`) пользователь отодвинул в `/var/tmp/ollama-stray/`, поставил `ollama-vulkan`.
      `walls` поднимает serve с `OLLAMA_VULKAN=1 OLLAMA_IGPU_ENABLE=1` → 43/43 слоя на Arc, ~10–11 с/картинка (CPU ~18), CPU свободен.
- [x] Сайдбар: курсор держится за пункт (`cursorKey` = kind:value), а не за номер строки; «Tag with gemma» зависит от
      общего числа неразмеченных (`Store.untaggedTotal`), а не от отфильтрованного — раньше пропадал и курсор съезжал.
- Замер выбиралки: старт ~0,57 с CPU, простой 0%, RSS ~310 МБ + GTT ~325 МБ (пустой PanelWindow Quickshell: 121 + 119).
  Резерв: sourceSize превью под реальный размер карточки, cacheBuffer меньше.
- [ ] Полная разметка (T в выбиралке), проверка клавиатуры пользователем. (`wall-selector.sh` удалён вместе с rofi 2026-11-13.)
- Проверка: разметка 297 обоев проходит; фильтр «тёмные синие пейзажи» отдаёт осмысленный список.

### 10. Общие улучшения — IN PROGRESS (всё сделано в репо, ждёт применения /etc и проверки пользователем)
- [x] README и видеошоукейс обновлены 2026-11-21; запись и обложка лежат в `docs/media/`.
- [x] uwsm-автостарт (2b); `hyprctl dispatch` в hypridle/крышке под Lua (задача 5).
- [x] `touchpad_toggle` без sudo: `lua/touchpad.lua` — `hl.device{enabled}`, состояние в
      `$XDG_RUNTIME_DIR/hypr-touchpad-disabled` (переживает reload). Super+T — Lua-функция, `binc/touchpad_toggle` —
      обёртка через dispatch. Состояние и уведомление проверены; **реальное отключение проверяет пользователь**
      (в `hyprctl devices` его не видно).
- [x] libadwaita: wallust-шаблон `libadwaita.css.j2` (CSS-переменные `--window-bg-color` и т. п.) →
      `~/.config/gtk-4.0/libadwaita.css`, плюс пустой `libadwaita-tweaks.css`; `gtk-application-prefer-dark-theme` в gtk-4.0/settings.ini
      после перелогина возвращается (переписывает nwg-look?) — оставлено, это лишь предупреждение libadwaita. Проверено скриншотом Nautilus, ошибок нет.
- [x] elephant: юнит выключен и удалён из репо (бинарника и walker нет).
- [x] hyprsunset: `hypr/hyprsunset.conf` (расписание убрано 2026-10-25 по просьбе пользователя), `binc/nightlight` (Super+N:
      4500 ↔ 6000; `identity` не меняет вывод `hyprctl hyprsunset temperature`, поэтому «выкл» = 6000), автостарт.
      Проверено после перелогина.
- [x] Control center (rofi, 2026-10-08): см. «Карту конфигов». Заменил `apps.sh` (удалён вместе с `rofi/applets/`)
      и `waybar/scripts/power-profiles.*`. Powermenu остался отдельно (Super+Esc), исправлен Suspend (вызывал
      `mpc` и `amixer mute` без unmute) и путь к screensaver. «Не засыпать» = `systemd-inhibit --what=idle` в юните
      `cc-caffeine` (hypridle 0.1.8 видит BlockInhibited=idle; крышку не трогает).
- [x] Единый режим питания: Эко = power-saver + `shift_mode` eco + `fan_mode` silent, Баланс = balanced + comfort + auto,
      Производительность = performance + turbo + auto. `binc/power-mode watch` (юнит `ec-sync.service`) применяет EC
      при любой смене профиля ppd. Запись в sysfs — udev `71-msi-ec.rules` (группа wheel). MCC убран из автостарта.
- [x] cmdline/modprobe: убран мёртвый `i915.enable_gsc_proxy=0`, дубликат `isw.conf` (= `msi-ec.conf`, пакета isw
      нет), `iwlwifi swcrypto=0` (дефолт). xe остаётся (решение пользователя), сравнение с i915 не делаем.
- hypridle разные таймауты для сети/батареи — **не делаем** (решение пользователя).
- [ ] Ждёт пользователя: `dot sys install` + `sudo rm /etc/modprobe.d/isw.conf` + udevadm trigger; затем
      `systemctl --user enable --now ec-sync`, проверка записи EC; `yay -S hyprpicker`; после перезагрузки —
      cmdline, Fn/Super и кривые вентиляторов без MCC (сейчас fn_key=left, win_key=right); клавиатура/мышь в CC.

### 11. Адаптивная светлая/тёмная тема под каждые обои — DONE (2026-11-05; ждёт перелогина для Qt/курсора и проверки пользователем)
- Цель: при смене обоев **вся** система сама становится светлой или тёмной под картинку — на всех уровнях,
  без ручных шагов.
- **Решения пользователя (2026-11-05):**
  - Светлая тема — **нейтральная + акценты**: фон почти белый с лёгким оттенком обоев, акценты из обоев
    (не пастель softlight, не пёстрая light).
  - Выбор: **авто по яркости** (`tone` из `walls index`, средний L* < 45 → dark; сейчас 214 dark / 82 light)
    + **пометка для каждых обоев** (Auto/Light/Dark, в любой момент, хранится в `.walls.json`)
    + **глобальный режим** Auto / Always light / Always dark (перекрывает всё). Приоритет: глобальный → пометка → авто.
  - CC: раздел Wallpaper → **Appearance**: Choose/Random wallpaper, «This wallpaper: Auto (light) ▸», «Global mode ▸»,
    Liquid glass (переезжает из Toggles). Плюс клавиша в выбиралке walls.
  - Акцент в интерфейсе — **точный цвет из wallust**. Иконки — ближайший готовый набор `adwaita-colors-icon-theme`
    (blue/teal/green/yellow/orange/red/pink/purple/brown); у малонасыщенных обоев — `slate`. «Не вычурно».
  - Терминалы, nvim, yazi, btop, fastfetch, clipse — **переключаются вместе со всеми**.
  - Курсор: тёмная тема → Bibata-Modern-**Ice**, светлая → Bibata-Modern-**Classic** (`hyprctl setcursor` + gsettings).
  - **Telegram и Discord/Vesktop не трогать** (пользователь привык к их цветам). Остальное — всё, где есть светлая/тёмная.
- [x] Ядро `binc/theme` (`apply [--id]`, `set auto|light|dark|cycle`, `wall …`, `status`), см. «Карту конфигов».
      Светлая: фон LCh(97.5, ≤3.5, оттенок самого весомого цвета обоев), текст L 16, акценты wallust `light`, самый
      цветной → color1, все затемнены до контраста 4.5 (яркие 9–14 — 3.0). Тёмная — wallust `dark` как раньше, только
      слишком тёмные акценты осветляются до 4.5 (у orange-art текст на выделении CC не читался — было и до задачи).
- [x] Шаблоны: ветки `{% if light %}` (тёмная ветка = прежний вывод, сверено diff'ом). Новые: `gtk3.css.j2`,
      `kdeglobals.j2`, `ghostty.j2`. hyprlock: `path = @WALLPAPER@` (в режиме `cs` `{{wallpaper}}` = путь схемы), подставляет `binc/lock`.
      kitty/ghostty в светлой: ANSI 0 = тёмный, 7/15 = серые. waybar: в светлой тёмная обводка иконок трея (белый Telegram).
- [x] Уровни (каждый проверить скриншотом в обеих темах):
      GTK3 (adw-gtk3 ↔ adw-gtk3-dark, settings.ini `prefer-dark`), GTK4/libadwaita (`color-scheme`, `libadwaita.css`),
      портал `org.freedesktop.appearance.color-scheme` (Chromium/сайты, VS Code `autoDetectColorScheme`, Zed `mode: system`,
      Spotify), Qt (Kvantum светлый/тёмный вариант + qt6ct-палитра из wallust; иконки Qt сейчас `menta` → тот же
      Adwaita-цвет; запущенные Qt-приложения, скорее всего, только после перезапуска), иконки, курсор,
      Hyprland (рамки, тени), hyprglass (`default_theme`), waybar, rofi/CC, swaync, hyprlock, Quickshell (walls),
      kitty/ghostty, nvim (neopywal), btop, yazi, fastfetch, clipse.
- [x] Переключение на лету проверено скриншотами (light ↔ dark при открытых окнах): GTK3 (тестовое окно PyGObject),
      Nautilus, Qt (qdbusviewer6 с `QT_QPA_PLATFORMTHEME=kde`), kitty, waybar, rofi/CC, swaync, выбиралка walls.
      Смена обоев: цвета libadwaita/GTK4 — после перезапуска приложения (как и раньше), режим — сразу.
      `settings.ini` GTK без темы/иконок/курсора/prefer-dark (всё в gsettings). yazi — на ANSI-именах (сам следует терминалу),
      btop/fastfetch уже были на цветах терминала. nvim: `background` из `~/.cache/theme/mode`, SIGUSR1 → перечитать.
      VS Code `window.autoDetectColorScheme`, Zed `mode: system` (бэкапы `*.bak-theme` рядом, файлы вне репо).
- [ ] Пользователю: перелогин (Qt через `kde`, курсор из `~/.cache/theme/env`); Chromium — Settings → Appearance →
      Mode: Device (сейчас `color_scheme2 = 2`, всегда тёмный); проверить Telegram/Discord — не включено ли у них
      «следовать системе» (по решению — их не трогаем). Spicetify не настроен (тема Matugen лежит, конфига нет).
- Проверка: orange-art (тёмные) → 27d4pr35qnvc1 (светлые) → возврат sfondo-tablet — режим, бар, CC, терминал верные.

### 12. Виджеты на рабочем столе (quickdesk) — IN PROGRESS (v0.1 + редактор сделаны 2026-11-11; полировка 2026-11-16, fff7fbd)
- Отдельный репо **`~/Apps/quickdesk`** (MIT, как quickseek). Все решения, обзор сообщества и задачи — в
  `~/Apps/quickdesk/CLAUDE.md`, работать над ним из того репо. Коротко: виджеты под окнами + Super+W поверх окон,
  стиль «текст»/«стеклянная карточка» у каждого свой, редактор мышью (`e`), раскладка на каждый набор мониторов,
  v1 — часы, музыка, погода (Open-Meteo), календарь, батарея (sysfs; Battery Monitor в репо не входит).
- Сторона dotfiles (сделать вместе с v0.1): бинд Super+W (`hl.dsp.global("quickdesk:toggle")`), автостарт `uwsm app -s b`,
  wallust-шаблон палитры, неймспейсы `quickdesk`/`quickdesk-overlay` в `glass.lua`, надстройка в `binc/glass`,
  хук `hl.on` → IPC «ws пуст/занят», пакет `quickdesk/` (settings.json) в stow.
- 2026-11-16 (fff7fbd, запушено): налезание текста в редакторе (подписи ползунков, placeholder шрифта, панель Add на узком
  экране, карточка батареи), погода не перезапрашивалась при смене места (`age()` по старому ключу), README со скриншотами
  (`docs/images/`). occupancy `hyprland` проверен на стенде одним монитором — ок; двумя мониторами, мышью, со стеклом и scale 2 — нет.
  Замер: простой 0 % CPU, ~0 пробуждений; играет плеер — ~20/с (прогресс раз в секунду), монитор занят — ~2/с.

### 13. quickseek — поиск «как Spotlight в macOS» на Quickshell — IN PROGRESS (v0.4 сделан и запушен 2026-11-13, ждёт проверки клавиатурой)
- Идея пользователя: одно окно, где ищется всё сразу. Пишешь `wallpaper` → и папка на диске, и пункт CC «Choose wallpaper»,
  и «Search Google». Работает даже в неправильной раскладке. Анимация раскрытия окна и «вытягивания» по мере появления
  результатов — «прям как в macOS». Обсуждено в формате grill (3 раунда), все решения ниже — **пользователя**, не пересматривать.
- Предыстория: попытка «глобального поиска» в rofi-CC (пункты всех подменю под 9 разделами главного экрана) **отклонена** —
  rofi не умеет прятать строки при пустом запросе, при прокрутке вылезали Wi-Fi-сети и BT-устройства. Правило:
  пункты подменю видны только внутри своего раздела или когда их нашёл поиск. Откачено, в коммит не попало.

#### Проект
- Имя **quickseek** (Quickshell + seek; «Spotlight» — марка Apple). Отдельный git-репо **`~/Apps/quickseek`** (НЕ в dotfiles),
  лицензия **MIT**. Позже — на GitHub, чтобы люди пользовались и контрибьютили; но «не зацикливаться» на этом:
  сначала чтобы работало у пользователя. Пока только `git init`, GitHub-репо не создавать без просьбы.
- Тексты интерфейса и комментарии в репо quickseek — **на английском, комментариев немного** (решение пользователя).
  Сторона dotfiles (`rofi/cc/quickseek.sh` и т. п.) — по правилам dotfiles, на русском.
- Ядро в репо — только общее для всех: окно и анимации, поиск, frecency, исправление раскладки, источники «для всех»
  (приложения, файлы, калькулятор, веб, power, настройки). Всё специфичное для этой машины (CC, MSI EC, iwd) — в dotfiles,
  подключается **плагинами-скриптами**.
- Протокол плагина: внешняя команда отдаёт JSON-список пунктов (подпись, короткий статус, иконка, id, при необходимости —
  «раздел/папка» с вложенными пунктами) и выполняет пункт по id. Язык любой. Формат протокола спроектировать при старте v0.1.
- CC подключается как такой плагин через `binc/cc` (нужен машиночитаемый вывод из тех же `РАЗДЕЛ_rows`, например
  `cc РАЗДЕЛ json`, — один источник правды, rofi-CC продолжает работать). Пользователю «не важно, в каком виде, лишь бы
  функции CC работали». Позже (после ухода с rofi) можно перевести медленные разделы на нативные модули Quickshell
  (в 0.3.2 есть `Quickshell.Bluetooth`, `Services.Pipewire`, `Hyprland`; `Networking` — только NetworkManager, у нас iwd →
  Wi-Fi остаётся через iwd D-Bus).

#### Движок и работа в фоне
- **Quickshell** (rofi — тупик: нет анимаций, нельзя прятать строки до поиска; готовые vicinae/walker/anyrun — чужой вид,
  CC с подменю в их модель не ложится). Главное условие пользователя: **не жрать CPU без причины и не бить по автономности** —
  оптимизировать и замерять.
- **Демон в фоне** (`uwsm app -s b --`, автостарт), окно (PanelWindow) создаётся при открытии (LazyLoader) и уничтожается после
  анимации закрытия. Пока скрыто — **0 % CPU, без таймеров/опроса**, индексы обновлять по событиям (inotify на папки .desktop,
  смена мониторов) или при открытии. Ожидаемая цена — ~100–120 МБ RSS (пустой Quickshell). Замер до/после (pidstat, powertop
  wakeups); если не уложимся — вариант «холодный старт на каждое открытие».
  NB: выбиралка обоев walls сейчас НЕ демон (`qs -c walls -n`, холодный старт) — пользователь думал, что висит; quickseek
  будет первым постоянным процессом Quickshell. Встраивать walls в тот же демон — не обсуждалось.
- Открытие по горячей клавише: Hyprland global shortcut из Quickshell (`GlobalShortcut`, без запуска процесса) и/или
  `qs ipc call` как запасной путь — выбрать при реализации.

#### Окно и вид («как macOS»)
- Монитор с фокусом, по центру, в верхней трети экрана. Ширина ~680 логических px, на вертикальном DP-1 (1080) ужимается.
  Мониторы не хардкодить (scale/transform).
- При открытии — **только строка ввода** (плейсхолдер вида «Search…»), без результатов. Результаты появляются с первыми
  символами, окно «вытягивается» вниз.
- Анимации: открытие — масштаб 0.96 → 1 + прозрачность ~150 мс; при наборе высота плавно «пружинит» под число результатов;
  закрытие — обратная ~100 мс. Реализация: слой фиксированного размера и прозрачный, внутри анимируется скруглённая плашка
  (не ресайзить layer-surface — Hyprland перестраивает слои, см. «ужимание» waybar в задаче 1).
- Результаты: сверху «лучшее совпадение», ниже **группы с заголовками** (Applications, Control center, Folders, Files, Web…).
  Справа серым — **только короткое состояние** (on/off, connected, active…), «без километровых предложений» и пояснений
  (пользователь только что вычистил такие подписи из CC — коммит 31ec204).
- Цвета (порядок поиска палитры): 1) `colors` в settings.json (путь); 2) `~/.cache/quickseek/colors.json` — пишут шаблоны из репо
  `templates/wallust.json.j2` и `templates/matugen.json` (пользователь подключает их в свой wallust/matugen; у нас — шаблон
  в `~/dotfiles/wallust/templates/`); 3) `~/.cache/wal/colors.json` (формат pywal, у многих есть); 4) встроенная палитра.
  Светлый/тёмный вид — по яркости фона палитры (как `{% set light = … %}` в наших шаблонах, задача 11). Файл палитры
  отслеживать — смена обоев перекрашивает на лету.
- Стекло: неймспейс слоя `quickseek` → добавить в белый список `hypr/lua/glass.lua`; вкл/выкл — общий `binc/glass`
  (прозрачность фона только при включённом стекле, как у waybar/rofi/swaync).

#### Источники
- Приложения (.desktop). Окон нет (решение: отдельного источника окон и «перейти к уже открытому» — не надо).
- Control center — включая пункты подменю (сети, BT-устройства, аудиовыходы, мониторы, тумблеры), но они видны только
  внутри раздела или по поиску.
- Файлы и папки (см. ниже).
- Калькулятор/конвертер — `qalc` (libqalculate стоит), только когда запрос похож на выражение, с debounce.
- Power: Lock (`loginctl lock-session`), Suspend, Reboot, Shutdown, Logout (в т. ч. заменит powermenu в будущем).
- Веб: **Google в браузере по умолчанию** (`xdg-open`, сейчас `chromium.desktop`). Строка «Search Google for “…”» есть
  **всегда последней**, а при пустой выдаче — единственная и сразу выбрана. Префиксы: `g …` (сразу Google), `yt …` (YouTube),
  `aw …` (Arch Wiki).
- **Не нужны**: обои как источник (остаются действия CC «Choose/Random wallpaper», поиск по тегам — в walls), окна.
- На будущее (не в v0.1/v0.2): история буфера (clipse), эмодзи, `> команда`, скрипты binc.

#### Поиск и ранжирование
- Fuzzy-совпадение + **frecency** (чаще/недавно выбранное выше) + запоминание «запрос → выбор». Данные —
  `~/.local/state/quickseek/` (не настройки, в dotfiles не кладём).
- Неправильная раскладка: искать и по введённому тексту, и по нему же, переложенному ЙЦУКЕН ↔ QWERTY по позициям клавиш;
  результаты сливать. Раскладку Hyprland **не переключать**, фонетический транслит — **не нужен** (пока только этот вариант).
- Закрепление: Ctrl+P на любом результате; закреплённые — первыми и в пустом виде, и в поиске.

#### Файлы
- Свой индекс `$HOME` (`updatedb` от пользователя → `~/.cache/quickseek/`), не системный plocate (тот раз в сутки — «фуфел»),
  не `fd` на каждый символ (дорого). Пользователь хочет цену «как у plocate», но свежесть.
- Обновление: user-таймер — на зарядке каждые 30 мин, на батарее каждые 2 ч; плюс при открытии окна, если индексу > 2 ч.
  Перед выбором частоты **замерить** стоимость одного `updatedb` по home (если < 1 с CPU — можно чаще).
- Downloads / Desktop / Documents — живой `fd` при каждом открытии окна (свежие файлы).
- Только `$HOME`. Исключения: `.cache`, `.local/share/Steam`, `node_modules`, `.git`, скрытые (кроме запроса, начинающегося с точки).
- Действия: папка → Nautilus, файл → приложение по умолчанию (`xdg-open`), Alt+Enter → показать в папке
  (FileManager1.ShowItems — помнить фикс портала из задачи 9).

#### Навигация
- ↑/↓ или Ctrl+J/K — по результатам; Enter — выполнить; Esc — закрыть.
- Раздел CC = «папка»: Enter или Tab → войти, в строке поиска «чип» `Wi-Fi ›`, поиск уже внутри раздела;
  Backspace на пустой строке — выйти из раздела.
- Alt+Enter — показать в папке; Ctrl+P — закрепить.
- После действий CC, меняющих состояние (тумблер, выбор выхода звука и т. п.), окно **остаётся открытым** и обновляет статус
  (как сейчас rofi-CC). Запуск приложения / открытие файла / веб — закрывают окно.

#### Настройки
- `~/.config/quickseek/settings.json`: правится руками **и** пунктами настроек в самом окне (поиск `quickseek settings`…),
  окно следит за файлом и применяет сразу. Можно положить в dotfiles (stow).
- Пустой экран настраивается: ничего (по умолчанию) / недавние / популярные / закреплённые (возможно, комбинации).

#### Клавиши
- ~~На время разработки — **Super+Alt+Space**~~ (с v0.3 quickseek на Super+Space, rofi-лаунчер на Super+Alt+Space), rofi не трогаем (Super+Space — rofi-лаунчер, Super+Shift+A — rofi-CC,
  Super+Esc — powermenu).
- После v0.2 и недели без rofi: Super+Space → quickseek, Super+Shift+A → quickseek сразу в корне CC, Super+Esc → сразу
  раздел Power. rofi (лаунчер, CC, powermenu) убирается только тогда, waybar-клики перевести туда же.

#### Этапы
- [x] **v0.1** (локальные коммиты: quickseek 97cdf62, dotfiles b2e1866; не запушено): `~/Apps/quickseek` — плоский каталог QML: `shell.qml`
      (GlobalShortcut `quickseek:toggle`, IPC `toggle/open/close/folder KEY/search TEXT`), `Engine` (источники, поиск,
      группы, действия, калькулятор), `Fuzzy.js` (скоринг + ЙЦУКЕН↔QWERTY), `History` (frecency + «запрос → выбор»,
      `~/.local/state/quickseek/history.json`), `Settings` (settings.json + `include`), `Theme` (палитра), `Plugin`,
      `SeekWindow`/`SearchBar`/`Results`; `docs/plugins.md` (протокол), README, LICENSE, `templates/`.
      Протокол: `cmd list` → JSON lines (id, title, status, icon, parent, folder, keywords), `cmd run ID` → пусто (окно
      остаётся, список перечитывается) / `{"type":"close"}` / `{"type":"menu"}`+пункты / `{"type":"prompt"}` (ответ в env
      `QUICKSEEK_INPUT`). Плагин CC — `cc quickseek list|run` (`rofi/cc/quickseek.sh`): те же `РАЗДЕЛ_rows`, а
      `pick/ask/confirm/launch` в этом режиме отвечают протоколом (fd 3); `launch` — через `uwsm app`. В `cc` метаданные
      разделов вынесены в `SEC_NAME/SEC_ICON` (rofi-вывод не изменился, сверено заглушкой rofi).
      Dotfiles: пакет `quickseek/` (settings.json: uwsm launchPrefix, include `~/.cache/glass/quickseek.json`, плагин cc),
      wallust-шаблон `quickseek.json.j2` → `~/.cache/quickseek/colors.json`, `binc/glass` пишет opacity 0.45/{},
      слой `quickseek` в glass.lua, бинд Super+Alt+Space (`hl.dsp.global("quickseek:toggle")`), автостарт `uwsm app -s b`.
      Проверено через IPC и скриншоты: поиск, раскладка (`цфддзфзук`), папки CC, тумблер DND (статус обновился, окно
      осталось), подменю, confirm «No», prompt с паролем (тестовым плагином), калькулятор, префиксы, двойной Enter
      у Shut down. Простой: 0 переключений контекста за 20 с, RSS ~165 МБ; `list` CC ~0,2 с (разделы параллельно).
      **Не проверено:** клавиатура и ощущение анимаций (пользователь), вертикальный DP-1 (был включён только eDP-1),
      вид со стеклом (стекло выключено).
- Грабли Quickshell (записать, чтобы не наступить снова): имена файлов `Window`, `Palette`, `Colors` перекрываются
  типами QtQuick (тихо!); функция `children()` в синглтоне ломает загрузку («children is read-only»); комментарий
  с `{…}` **перед** `pragma Singleton` тихо ломает синглтон (все свойства undefined); `Instantiator` в синглтоне
  не работает — `Variants`; синглтон `Hyprland` держит поток событий Hyprland → ~3 пробуждения/с из-за смены
  заголовков окон, поэтому монитор берётся из `hyprctl monitors -j` при открытии.
- [x] **Вид под Spotlight** (2026-11-05, не закоммичено): шрифт — системный (`fonts.text` пуст → gsettings `font-name`,
      сейчас CaskaydiaMono), поле крупнее и Light; без результатов окно — «пилюля»; тень `RectangularShadow` (`shadow`,
      при стекле `binc/glass` пишет `false`); строки 44 px, «лучшее совпадение» 56 px с иконкой 40; иконки приложений 32;
      глифы CC/power/web — на цветной плашке с градиентом и белым значком (цвет = color1..6 палитры по разделу CC,
      затемняется до яркости ≤ 0.2); выделение — полупрозрачный акцент, текст обычным цветом. Иконки с абсолютным путём
      и пустые — без предупреждений. Фикс: при удалении `colors` из настроек палитра не возвращалась. Проверено
      скриншотами в светлой и (временной) тёмной палитре на eDP-1. Коммиты quickseek 76dd4c0, 866447e, dotfiles 3a0e00c.
      Иконки, которых нет в теме (у Wiremix нет `Icon=`, `network-vpn` у WireGuard GUI), давали шахматку Quickshell —
      теперь `iconPath(name, true)` → при «» плашка с глифом приложения. Поле ввода — обычная насыщенность (Light была узкой).
- [x] **v0.2** (2026-11-07, quickseek 3d46a97, запушено в github.com:Rymond044/quickseek):
      файлы — `bin/quickseek-files index|search|recent`: индекс `fd` → `plocate-build -p` в `~/.cache/quickseek/{files,dot}.db`
      (75 тыс. путей, ~0,4 с, 0,7 с CPU; пути отсортированы от мелких к глубоким — лимит plocate 300 оставляет их),
      поиск `plocate -b` по каждому из запросов (как набран + ЙЦУКЕН↔QWERTY) ~10 мс, папка/файл и отсев удалённых — `test -d/-e`.
      Скрытые — только для запроса с точки (`dot.db`, глубина 3). Исключения + `~/.config/quickseek/ignore`.
      Downloads/Desktop/Documents — `fd` на каждое открытие (`recent`, ~30 мс), он же запускает пересборку, если индексу > 2 ч.
      Ранжирование файлов: имя режется на слова по `._-`, потолок 850 (точное имя = начало слова), −15 за уровень глубины (≤150).
      Иконки — `*-x-generic` по расширению, без темы — глиф файла/папки. Alt+Enter → `FileManager1.ShowItems` (gdbus), иначе opener папки.
      Файлы/URL открываются через `opener` = `gio open` (не xdg-open: xdg-utils 1.2.1 игнорирует `Terminal=true`, а
      JSON/текст у нас → nvim.desktop — nvim стартовал без терминала и сразу выходил; gio поднимает kitty). Проверено:
      «Open settings file» → kitty с nvim settings.json.
      Закрепление: Ctrl+P, `pins` в history.json, +2000 к счёту. Пустой экран: `emptyView` (`pinned`/`recent`/`popular`, по умолч. ничего).
      Настройки в окне: папка «quickseek settings» (Empty screen ▸, File search, Rebuild file index, Unpin all, Clear history, Open
      settings file); `Settings.set()` пишет settings.json (QSaveFile идёт по симлинку, проверено; битый JSON не перезаписывает).
      Юниты `systemd/quickseek-index.{service,timer}` в репо (30 мин, на батарее — только если индекс > 2 ч), **не включены**:
      `systemctl --user link ~/Apps/quickseek/systemd/quickseek-index.{service,timer} && systemctl --user enable --now quickseek-index.timer`.
      `QUICKSEEK_APPID` — id горячей клавиши для второй (dev) копии. Проверено через IPC + скриншоты dev-копии (свои state/cache):
      `diplom`/`вшздщь`, `pdf`, `.zshrc`, тумблеры, пины, пустой экран, Alt+Enter (Nautilus), выкл. поиска файлов.
      **Не проверено:** клавиатура (Ctrl+P, Alt+Enter), вертикальный DP-1.
      Иконки файлов видны только при `QT_QPA_PLATFORMTHEME=kde`: у текущего демона ещё `qt6ct` (сессия до задачи 11), с ним
      Quickshell тему иконок не видит → глифы. После перелогина пройдёт.
      Простой: ~10 пробуждений/с всплесками — **так же и у v0.1** (сравнено бок о бок), пустой Quickshell — 0. Зацепки для v0.3:
      FileView на несуществующем `~/.cache/wal/colors.json`, DesktopEntries. 05.11 было 0 — что-то в окружении.
- [x] **v0.3** (2026-11-09, quickseek ветка `v0.3` fb6f873, dotfiles ветка `worktree-quickseek-default` 4cd3487; обе запушены,
      **в main не слиты**). Решение пользователя: файлы ищутся **только по префиксу `f `** (и `а ` в русской раскладке) →
      «папка» `Find files ›` (чип, Backspace на пустой — выход; пусто — закреплённые/недавние файлы); в обычном поиске
      только закреплённые файлы. Старое поведение — `files.inline: true` (+ тумблер в quickseek settings). Без префикса
      fd/plocate не запускаются вообще. Плагины: `refresh` (сек) — на открытии `list` только если старше; вход в папку
      плагина и действие перечитывают всегда. У CC `refresh: 120`. IPC `rows` — текст выдачи (для тестов).
      Замеры (dev-копия, `/proc`): простой 0 пробуждений/0 % CPU, RSS 125 МБ после старта / ~165 после первого открытия
      (PSS ~90); открытие+закрытие ~75 мс + 10 мс дети; с запросом ~140 мс; `f …` ~125 + 105 мс (fd/plocate).
      Было ~1,4 с CPU на открытие: **1,2 с — `cc quickseek list`** (разделы по 50–250 мс: appearance, audio, wifi, bt).
      Всплески «~10/с» из v0.2 не воспроизвелись (оба демона 0/с) — были от окружения. README: раздел Cost.
      Бинды: Super+Space → quickseek, Super+Alt+Space → rofi-лаунчер (запасной). Super+Shift+A / Super+Esc пока rofi.
- [x] **v0.4** (2026-11-13, план пользователя; quickseek 7bd1b34, dotfiles 6f8aeb1, запушено; клавиатуру проверяет пользователь):
  1. [x] Esc/Tab уходили в окно под quickseek. Не воспроизвелось: эксклюзивный слой держит фокус (курсор над kitty,
         `hl.dsp.focus`, уведомление — проверено меткой `activeFocus` с контролем OnDemand; Hyprland 0.57 отказывает окнам в
         фокусе при `m_exclusiveKeyboardLSes`). Вероятно, Esc в папке закрывал окно и следующие клавиши шли в kitty.
         Теперь: Esc — закрыть превью / prompt / меню / выйти из папки, закрыть только с верхнего уровня (папка, в которой
         окно открыто, — верхний уровень, `baseDepth`); окно не снимается, пока зажата клавиша, нажатая в нём
         (`Engine.keyDown/keyUp`, страховка 1,5 с), в закрывающемся окне клавиши глотаются.
  2. [x] rofi убран (см. «Карту конфигов»). Ядро quickseek: папка `session`, `power` в настройках — id → команда или
         `{title, icon, command, order, confirm}`, `null` прячет.
  3. [x] Валюты: при денежном запросе, если `~/.local/share/qalculate/eurofxref-daily.xml` старше суток, — `qalc -e` в фоне
         и пересчёт; статус «rates ДАТА».
  4. [x] `Clipboard.qml` (clipse): `v `/`м `, Super+V → `folder clipboard`. Enter — `wl-copy` (картинка `--type image/png`).
         Pin/Delete пишут прямо в `clipboard_history.json` (компактный JSON, проверено: pin+unpin = исходный файл по `jq -S`).
  5. [x] Меню действий: → в конце строки / Ctrl+O; вложенные меню (Open with… из `gio mime`), Esc назад. Скрытые приложения —
         `hidden` в настройках, «Show hidden apps» в quickseek settings.
  6. [x] Превью: `Preview.qml` + `bin/quickseek-preview` (kind/mime/size/mtime/картинка; PDF — pdftoppm, видео — ffmpeg,
         прочие картинки — vipsthumbnail, кэш `~/.cache/quickseek/preview/`, чистка > 14 дней). Сбоку, если
         `(ширина − окно)/2 − 16 − max(pad, 24) ≥ 360` (HDMI — да, eDP/DP-1 — вместо окна); слой расширяется симметрично.
  7. [x] `>`: папка `command` — введённое (big), история `cmd:` (frecency), программы из $PATH; Tab дополняет;
         запуск `terminal` (`["kitty","-e"]`) + `$SHELL -ic 'cmd; exec $SHELL'` через launchPrefix. «Remove from history».
  8. [x] Эмодзи: `data/emoji.tsv` из `tools/emoji.py` (emojibase-data 16.0.3, MIT/CLDR), `Emoji.qml`, иконка без плитки
         (`iconType: "emoji"`), русское название с весом заголовка.
  - IPC для тестов: `key esc|down|ctrl+o|space…` (тот же `Engine.onKey`, что и клавиатура), `type ТЕКСТ` (через поле
    ввода, как набор), `field` (что в поле). Баг у пользователя: `>` первым символом не очищал поле (запрос "" → "" без
    сигнала) → `> btop` уходил в zsh как перенаправление (пустые файлы в ~, удалены). Исправлено сигналом `queryReplaced`.
  - Замер: простой — 1 пробуждение за 10 с; RSS ~245 МБ после тестов (было ~165) — эмодзи и превью остаются в памяти, проверить.
  - Не делаем: закладки браузера, недавние файлы GTK. `quickseek-index` — **не нужен** (решение пользователя, юниты удалены).
- [x] **v0.5** (2026-11-16, quickseek d8e2681, dotfiles 1e3bc31, запушено; клавиатуру v0.4 пользователь проверил — «всё нравится»):
      нативные папки `AudioSource.qml` (Quickshell.Services.Pipewire) и `BluetoothSource.qml` (Quickshell.Bluetooth) на базе
      `NativeSource.qml`; плагин монтирует их строкой с `"source": "audio"|"bluetooth"` (docs/plugins.md), cc audio/bt — только
      точки монтирования + действия для командной строки. Модули грузятся `LazyLoader` только при открытом окне, но синглтоны
      Pipewire/Bluetooth Quickshell после первого обращения живут до конца процесса. Первое открытие звука после старта демона —
      несколько секунд (холодная синхронизация Pipewire). `cc quickseek list` 0,47 → 0,24 с.
      Выгрузка после закрытия (`Engine.release()` через 0,8 с + gc): после эмодзи RSS 246 → 168 МБ. Превью 4K-картинки держит
      +45 МБ (не утечка, стабильно; причина не найдена). Простой после касания нативных папок: 0 пробуждений за 80 с (проверено мной).
      Не проверено: connect/pair/forget BT на реальном адаптере, смена выхода звука (агент менял только вход и вернул).
#### Планы и идеи (2026-11-20) — TODO
Записано по просьбе пользователя; реализация ещё не начата. Первые два пункта — запросы пользователя,
остальные — предложения для обсуждения, а не утверждённые решения.

- [ ] **Информация о хосте в quickseek**: сколько времени хост включён, когда загружен,
  длительность текущей пользовательской сессии. Рассмотреть подменю `System info` и поиск по
  `uptime`, `boot`, `system info`. Отдельно обозначать время с загрузки (включая сон) и время
  бодрствования, чтобы сон ноутбука не выглядел как активная работа. Минимальный вариант —
  время с загрузки и дата загрузки; остальные показатели добавлять после обсуждения.
- [ ] **Обзор всех приложений в quickseek**: рассмотреть подменю `Applications`, где можно
  просмотреть все доступные для запуска приложения без знания названия и искать внутри списка.
  Начать с алфавитного списка существующего источника `.desktop`; затем обсудить категории,
  закреплённые и часто используемые приложения. Сохранить настройки скрытых приложений.
  Под «всеми» здесь понимается каталог приложений, а не пакеты или запущенные окна;
  прежнее решение не добавлять источник окон сохраняется.
- [ ] **Предложение — краткий обзор системы** в `System info`: CPU/load, занятая RAM,
  свободное место на дисках, версия ОС/ядра; копирование отдельного значения или сводки.
  Показатели получать при открытии раздела; обновление — только пока он видим.
- [ ] **Предложение — подсказки по возможностям quickseek**: раздел `Help` с горячими клавишами,
  доступными разделами и примерами префиксов (`f`, `v`, `>`). Помочь находить функции без
  запоминания команд; сохранить выбранное пользователем поведение пустого экрана.
- [ ] **Предложение — избранные действия и свои команды**: сначала проверить, что уже покрывают
  закрепление и плагины; при необходимости дать простой способ добавить именованное действие
  из dotfiles. Не вводить второй механизм для существующих возможностей.
- [ ] **Предложение для dotfiles — обзор состояния рабочего окружения**: по ручному запросу
  показать проблемы пользовательских сервисов, состояние ссылок stow, расхождения пакетов и
  системных конфигов; подробности открывать отдельным действием. Использовать существующие
  проверки `dot`, показывать возраст результата и не запускать тяжёлый аудит при каждом поиске.
- [ ] **Предложение для dotfiles — доступ к обслуживанию из quickseek**: действия для просмотра
  отчёта установки, логов выбранного компонента и инструкции по восстановлению; отдельно
  обсудить, какие операции действительно нужны в меню. Начать с просмотра информации.

Рекомендуемый порядок: минимальные `System info` и `Applications`, затем подсказки; расширенную
диагностику и обслуживание обсуждать отдельно. Новые разделы загружать по требованию, без
постоянного опроса в закрытом окне, дополнительных демонов и таймера индексации файлов.
Перед реализацией сверить возможности и инструкции `~/Apps/quickseek`; общий код — там,
интеграции конкретного рабочего окружения — в dotfiles. Проверить клавиатурную навигацию,
переходы в подменю и стоимость по CPU/RSS/пробуждениям в изолированном стенде.

- Проверка: открытие мгновенное и плавное на всех 3 мониторах (включая вертикальный DP-1); `цфддзфзук` находит то же,
  что `wallpaper`; пункты подменю CC видны только внутри раздела или по поиску; в простое 0 % CPU и нет пробуждений.

## Журнал

- 2026-11-20 — по просьбе пользователя в планы задачи 13 добавлены информация о времени работы
  хоста и обзор приложений (возможное подменю `Applications`). Отдельно записаны предложения:
  сводка системы, подсказки quickseek, свои действия, ручной обзор состояния dotfiles и доступ
  к отчётам/логам. Запросы пользователя отделены от идей для обсуждения; реализация и проверки
  интерфейса ещё не выполнялись. Изменён только трекер, коммит не создавался.

- 2026-11-20 — владелец поручил закоммитить и опубликовать изменения SMW в dotfiles.
  При проверке рабочий сабмодуль уже на upstream 5fd2f06 (release/0.57.x), без локальных
  правок. Команды обслуживания и закрепление новой версии сохраняются отдельными коммитами.
  Прежние записи о 47b2297 описывают состояние до этого обновления; поведение 5fd2f06
  в живой сессии этой проверкой не подтверждено.

- 2026-11-20 — реализовано управление Lua SMW через `dot smw` по выбору владельца.
  Status без сети, restore закреплённой версии, update под установленный Hyprland с
  предварительной проверкой и защитой локальных изменений. Проверки: 41 тест успешен;
  реальная ветка release/0.57.x и её Lua-синтаксис проверены в /tmp, временные копии удалены.
  Живая сессия, рабочий SMW и индекс Git не менялись. Новая версия требует отдельной
  проверки в сессии перед сохранением коммита сабмодуля в dotfiles.

- 2026-11-20 — по запросу владельца исследованы альтернативы split-monitor-workspaces:
  README, hyprpm manifests, код выбранной для 0.57.2 версии SMW и публичные Atom-ленты
  коммитов. Точного актуального аналога с независимыми наборами на монитор и полноценной
  установкой через hyprpm среди проверенных проектов не найдено. Выбор остаётся за владельцем;
  изменён только этот трекер, установка, обновление и перезагрузка Hyprland не выполнялись.

- 2026-11-20 — лог первого входа с нового Lenovo показал остановку `hyprpm update`:
  sudo не мог запросить пароль из systemd-сервиса без терминала (`conversation failed`).
  Причина подтверждена логом, поэтому дополнительные гипотезы о подмодулях не проверялись.
  Исправлен ExecStart: kitty запускает настройку с терминалом; при ошибке окно ждёт Enter,
  при успехе закрывается. Пароли читает sudo, установщик их не перехватывает. Сохранены
  ограничения CPU, проверка окружения Hyprland и маркер только после полного успеха.
  32 теста и четыре файловых bwrap-сценария с повторной установкой проходят;
  реальная сессия, hyprpm, sudo, сервисы и системные файлы не изменялись.
  Ручной запуск существующего --first-login из kitty предложен владельцу для восстановления.

- 2026-11-20 — пользователь воспроизвёл остановку bootstrap на чистом Arch. Лог показал
  успешную установку остальных AUR-целей и отсутствие apple-fonts. Проверка официальных DMG
  подтвердила смену SHA-256 SF Pro и SF Compact (Apple обновила их 2026-11-04); SF Mono/NY
  совпали со старым рецептом. Исправленный PKGBUILD сохраняет проверку сумм и четыре лицензии,
  поддерживает вложенные pkg; фактически собран apple-fonts 7.0.6-2, проверены 147 файлов,
  четыре RTF-лицензии и SF Pro Display Bold через fc-scan. Пакет в живую систему не устанавливался.
  Групповой отказ yay воспроизведён красным тестом и исправлен: поштучные попытки, проверка
  фактической установки, один повтор отсутствующих, проверка helper после обновления libalpm,
  лог каждой сборки и итоговый install-report.json. Ошибки AUR/темы не прерывают доступные
  шаги; автологин без начальных конфигов рабочего стола/блокировки не добавляется. Неполная
  установка завершается кодом 2 после остальных шагов с перечнем недостающего.
  Проверки: 30 тестов, четыре изолированных файловых сценария (включая отказ AUR), каждый
  с повторной установкой. Исправление подготовлено к публикации для обновления на новом Arch.

- 2026-11-19 — владелец отдельно разрешил закоммитить и отправить все оставшиеся изменения.
  Прежний WIP quickseek settings (`hidden: []`) включён в отдельный коммит; JSON проверен.

- 2026-11-19 — по просьбе владельца подготовлены коммит и публикация установщика в main.
  В состав входят реализация, аппаратные профили, изображения, документация и проверки.
  Прежняя правка `quickseek/.config/quickseek/settings.json` (hidden: []) сохранена отдельно
  в рабочем дереве. Итоговые проверки реализации: 24 теста и три изолированных файловых
  сценария с повторной установкой; реальная установка пакетов и первый графический вход
  на чистом Arch остаются неподтверждёнными.

- 2026-11-19 — возобновлена и завершена реализация согласованного установщика. Итог:
  `bootstrap.sh`, `install/installer.py`, каталог scopes, lock-файл проектов, hardware-профили,
  шаблоны .env/.zshenv и руководство INSTALL.md. Реальная генерация темы/stow прошла в bwrap
  для базы, MSI + четырёх user-приложений и ChatGPT + Steam, включая повторную установку.
  Команды pacman/yay/git/systemd в этих сценариях заменены, сеть отключена, настоящая ФС read-only.
  Исправлены optional-цели wallust, legacy-кэш плагинов, локальные GTK2 пути, безопасный отказ
  от переписывания динамического GRUB cmdline. GPU-флаги браузеров перенесены в MSI-профиль.
  Все 24 теста прошли; три файловых сценария прошли первый и повторный запуск.
  Все обязательные native-пакеты найдены в локальных sync-базах pacman. Полная чистая Arch VM
  недоступна (готового образа и /dev/kvm нет); её проверка остаётся явно неподтверждённой.
  Живая система не разворачивалась, WIP quickseek settings сохранён, коммитов нет.

- 2026-11-19 — Q14–Q17: при повторном запуске невыбранные установленные приложения
  пропускаются без удаления; конфиги ставятся только для выбранных программ; сканер и Xbox
  выбираются отдельно от ноутбука; отпечаток и распознавание лица — отдельные hardware-опции.
  Исправлен номер ответа Q18 → Q17 по уточнению владельца. Сводка внесена в предложение;
  общее согласование перед реализацией ещё ожидается, установщик не изменён.

- 2026-11-19 — согласованы условные URI-обработчики, начальные user-чекбоксы
  KeePassXC/qBittorrent/Telegram/Discord, отсутствие сохранения личного выбора и одна опция
  Ollama + модель. По прямому поручению в `wallust/.local/share/dotfiles/defaults/` скопированы
  пять случайных уникальных обоев (~13,4 MiB) и текущая pfp hyprlock (свинка с ноутбуком).
  Исходники сохранены, контрольные суммы копий и целостность JPEG проверены. Установщик
  пока не изменён: случайный фон при первой установке и развёртывание pfp ещё предстоит сделать.
  Текущий фон, pfp и живой рабочий стол не менялись.

- 2026-11-19 — обсуждение установщика: личные программы выбираются чекбоксами;
  KeePassXC/qBittorrent необязательны, отмечены по умолчанию; KFontView пока сохраняется.
  Edit dotfiles — Neovim в kitty вместо Zed; hardware-профиль выбирается явно с подсказкой;
  Eco от батареи / Balanced от зарядки — общая политика, аппаратные EC-действия отделяются.
  URI-обработчики объяснены, их условная регистрация пока не подтверждена. Реализация не начата.

- 2026-11-19 — уточнение разделения: владелец выбрал все нынешние приложения по умолчанию
  (нужен дальнейший поимённый разбор), Ollama/модель — опционально при гарантированно рабочей
  выбиралке и корректном отказе Tag with Gemma. Hardware configs — отдельная восстанавливаемая
  часть, не смешанная с system/user packages; общие systemd/GRUB отделять от персональных
  параметров MSI/питания. Проверены реальные MIME desktop handlers, GRUB/cmdline, initramfs,
  службы питания, udev/modprobe и обработка ошибок разметки. Уточнения внесены в предложение;
  активные конфиги и установщик не менялись, отсутствие Ollama в UI не проверялось вживую.

- 2026-11-19 — по запросу о system/user scope проверены локальные метаданные 1783 пакетов,
  все 351 явно установленных пакетов, конфиги автозапуска/клавиш/Waybar/CC/MIME/темы/оболочки,
  зависимости quickseek/quickdesk, manifests/CMake/helpers hymission/HyprCapture и установка Battery Monitor.
  Предложение и полная таблица — `docs/package-scopes-proposal.md`; найденные зависимости,
  ранее не перечисленные явно, выделены отдельно. Система, пакеты, секреты и живые плагины не менялись.
  На этом этапе разделение только предложено, установка в чистой VM не выполнялась.

- 2026-11-19 — повторный аудит воспроизводимости (только чтение системы): `dot check` успешен.
  `dot pkgs diff`: установлены, но не сохранены chatgpt-bin и openai-codex; в /etc/pacman.conf
  дополнительно подключён /etc/pacman.d/openai-chatgpt.conf, которого нет в system/.
  Остальные учитываемые системные файлы совпадают. `dot units diff`: системные списки совпадают,
  в пользовательских ec-sync.service записан, но не enabled (linked-состояние здесь не проверялось).
  В units-system.txt остаётся docker.service вопреки решению запускать Docker по требованию;
  gungnir-agent/actuator включены в список, но их файлы и развёртывание проекта отсутствуют
  в dotfiles/bootstrap. Bootstrap клонирует пять ~/Apps по веткам без фиксации коммитов,
  пакеты тоже без версий; oh-my-zsh, секреты, hyprpm и начальная тема требуют ручных шагов.
  Полная установка на чистый Arch не проверялась. Списки и система не изменялись.
- 2026-10-04 — исследование системы, составлен этот файл. Изменений в системе нет.
  Пользователь сделал btrfs-снапшот перед началом.
- 2026-10-04 — задача 3: smw-булевы исправлены, `-n` убран из `hyprpm reload`, hymission пропатчен
  локально (опция `info_notifications`) и установлен. Проверено: overview на пустом ws, `hyprctl reload`,
  отключение/подключение HDMI и DP — 0 уведомлений, smw вернул ws на места. Не проверен перелогин.
  Приём: уведомления читаются через `hyprctl dispatch "(function() … hl.notification.get() …
  return hl.dsp.exec_cmd('true') end)()"` с записью в файл через `io.open`.
- 2026-10-04 — hymission: центрирование полосы + синхронная анимация + клавиатурная навигация + фикс выхода
  на пустой ws (ветка `local`, 1ba5a13, установлено). Проверено вживую: выход на пустой ws 21 остаётся
  на 21, переход на ws с окнами фокусирует их окна, слот крайнего ws 19 точно по центру HDMI.
  Клавиатуру и плавность проверяет пользователь (инжекта клавиш нет: wtype/ydotool не установлены).
  Debug-лог hymission: `hl.config({plugin={hymission={debug_logs=1}}})` → `/tmp/hymission-debug.log`.
- 2026-10-04 — пользователь нашёл баги полосы при выборе мышью (откат центрирования, возврат на исходный ws,
  не работал переход через ws). Исправлено в 37b95ba, переустановлено, пользователь подтвердил.
  Урок: переходы через `hyprctl dispatch` (Super+цифра) меняют фокус сами и не воспроизводят путь клика —
  такие баги автоматикой не ловятся, клики проверяет пользователь.
  Коммиты в ~/.config: опции hymission в plugin.lua; отдельно смещение DP-1 от nwg-displays.
- 2026-10-04 — задача 2, переезд на stow: `~/dotfiles` из клона `~/.config` (git mv в пакеты), добавлены
  zsh/git/gtk/qt/session/ghostty/yazi/waypaper/nwg-displays, `system/` из /etc, списки пакетов, `dot`,
  `bootstrap.sh`, `docs/STOW.md`. Живой переезд: оригиналы → `~/.cache/dotfiles-migration/old/`, stow.
  Проверено: `dot check` — все ссылки на месте, `hyprctl reload` без configerrors, 3 монитора, user-юниты
  видны, `dot sys diff` — system/ = /etc. Не проверен перелогин. Правки /etc не делались.
- 2026-10-04 — задачи 8, 1, 5 (коммиты 696489b, 79c879b, 42e84ab, запушено). 8: `lua/monitornav.lua` (фокус/перенос по геометрии, вход
  у ближнего края, dwindle preselect). 1: waybar по ширине монитора (`scripts/launch.sh`, compact/medium/full,
  `hl.on` на события мониторов), mpris вместо поллинга, причина «ужимания» найдена (переполнение → слой шире
  монитора), smw `monitor_priority`. 5: `binc/lock` + шаблон в логических единицах, все вызовы через
  `loginctl lock-session`, убран двойной suspend на крышке, исправлен `dpms` под Lua.
  Задача 2 разделена: stow — DONE, чистка конфигов вынесена в 2b.
  Пользователь: 8 и 1 — ок; 5 — ни один способ не блокировал (pidof + зависший hyprlock), исправлено.
  Урок: тестовый fullscreen/перенос задел kitty пользователя — для тестов открывать свои окна
  (`kitty --class navtest`) и не трогать чужие; при `hl.monitor{disabled}` smw перетасовывает ws, если нет приоритетов.
- 2026-10-04 — задачи 2b, 9, 10 (частично), 7 закрыта пользователем. Waybar: фоновый агент заменил `mpris` на
  `custom/playerctl` + `scripts/player.sh` (mpris держал старый трек после остановки), но при пустом тексте
  оставалась пустая «таблетка» → `hide-empty-text: true`. Проверено скриншотами: стоп — модуля нет, играет — трек
  на всех барах. Урок: тестовый MPRIS-плеер должен отдавать все свойства Player (CanControl, Position…),
  иначе playerctl metadata его не видит и тест врёт.
  9: взаимная блокировка портала и Nautilus, фикс через перекрытие D-Bus activation. 2b: uwsm env, автостарт,
  awww, удалены дубликаты. 10: тачпад без sudo, libadwaita из wallust, elephant убран, hyprsunset ждёт установки.
  Пользователь перелогинился — «вроде всё робит»: uwsm env подхвачен, демоны в `app-Hyprland-*.scope`,
  hyprpolkitagent активен. Коммиты 1b5bff2 (waybar), 61245fa (nautilus), 1930b6c (2b), c9fc0ca (10), запушено.
  Урок: после перелогина в моём шелле устаревший HYPRLAND_INSTANCE_SIGNATURE — брать из /proc/<pid>/environ.
- 2026-10-07 — waybar плодил процессы: у каждого `custom/playerctl*` (3 модуля × 3 бара) свой bash-пайплайн
  с `playerctl -F` (21 bash + 9 playerctl на запуск), а при каждом перезапуске waybar (`launch.sh` → `pkill`)
  playerctl оставались сиротами навсегда: waybar шлёт SIGTERM только прямому потомку (PDEATHSIG), а SIGPIPE
  унаследованно игнорируется. Набралось 78 сирот (~6,5 МБ каждая), трек на баре застывал. Теперь один
  `player-watch.sh` в юните + модули читают файл по сигналу; итог — 1 bash + 1 playerctl на сессию.
  Сироты убиты. Проверено: 3 перезапуска waybar подряд — без утечек, play/pause/нет плеера на скриншотах.
  Урок: RT-сигнал до установки обработчика убивает waybar (так и упал на первом запуске).
  Заодно: `~/.config/systemd/user` был свёрнутой stow-ссылкой в `session/` — теперь настоящая папка со ссылками.
  Найдено, не трогал: 4 зависших `hyprlock` (futex_do_wait, ~50–70 МБ каждый, с 06.10) — как в задаче 5.
- 2026-10-07 — зависшие hyprlock (557d67d): это второй hyprlock поверх уже заблокированной сессии. Hyprland шлёт
  ему `finished`, hyprlock 0.9.6 зовёт `exit(1)` при живых потоках (auth, очереди Mesa) → иногда дедлок навсегда.
  Происходило на каждом сне по таймауту hypridle (600 с — lock, 1200 с — `systemctl suspend` → before_sleep_cmd →
  снова lock_cmd); крышка не текла (сессия до неё не заблокирована). Тезис задачи 5 «повторный сам выходит» — неверен.
  Фикс: `binc/lock` сперва спрашивает hypridle `org.freedesktop.ScreenSaver.GetActive` (= его m_isLocked из
  lock-notify) и при `b true` не запускает hyprlock; при любой ошибке блокирует как раньше. Проверено без
  блокировки (execvp подменён), 4 зависших убиты (при `GetActive = false`). Живую проверку даст первый сон по таймауту:
  `pgrep -ax hyprlock` после разблокировки должен быть пуст.
  Урок: hyprlock в тестах не запускать вообще (холостые прогоны однажды заблокировали экран на 10 мин) —
  подменять exec; состояние блокировки читать через `busctl --user call org.freedesktop.ScreenSaver … GetActive`.
- 2026-10-08 — задача 7 переоткрыта (диалог закрытия не виден на eDP-1), исследование — см. задачу 7, не воспроизведено.
  Аппаратный декод видео: **работал и раньше** — Chromium 151 включает VA-API сам (`AcceleratedVideoDecodeLinuxGL`
  по умолчанию). Флаги были мёртвые: `VaapiVideoDecodeLinuxGL`/`UseChromeOSDirectVideoDecoder` в 151 не существуют,
  а второй `--enable-features` (из бинда и `~/.local/share/applications/chromium.desktop`) перекрывал первый.
  Теперь один `--enable-features` в `chromium-flags.conf` (то же в `electron-flags.conf`), бинд — просто `chromium`,
  флаги из Exec в .desktop-override убраны (файл вне репо). Проверено: H.264/VP9/AV1 1080p → `VaapiVideoDecoder`,
  0 dropped, видеодвижок занят; контроль `--disable-accelerated-video-decode` → FFmpeg/Vpx/Dav1d, VCS = 0.
  Новая команда `binc/hwdecode` — кто сейчас грузит видеодвижок (drm-cycles-vcs из /proc/*/fdinfo, xe).
  Урок: процент VCS считать по `drm-cycles-vcs / drm-total-cycles-vcs`; Chromium пишет cmdline одной строкой.
  Мусор: тестовый профиль `~/prof` (создан по ошибке, удалить не дали — удалить пользователю).
- 2026-10-08 — задача 10: control center в rofi (`rofi/cc/`, Super+Shift+A, правые клики waybar), единый режим
  питания ppd+EC (`binc/power-mode`, `ec-sync.service`, udev `71-msi-ec.rules`), MCC убран из автостарта, `apps.sh` и
  `power-profiles.sh` удалены, powermenu починен, `binc/ocr`, `lua/monitorctl.lua`. Чистка /etc в `system/` (gsc_proxy,
  isw.conf, swcrypto). Проверено действиями `cc РАЗДЕЛ ДЕЙСТВИЕ` с возвратом: ночной свет, DND, caffeine (logind
  BlockInhibited=idle), выход звука, mute микрофона, DP-1 выкл/вкл (вернулся с transform и ws 10); главный экран
  открывается за ~0,2 с; скриншоты подменю. Урок: `read` с IFS=таб схлопывает пустые поля — в TSV пустое = «-».
- 2026-10-08 — CC переведён на английский (просьба пользователя). Кнопки EC «не работали»: /etc ещё не применён
  (нет `71-msi-ec.rules`), а ошибка записи терялась (stderr из rofi не видно, ppd при этом переключался → EC
  рассинхронизировался). Теперь `power-mode` при ошибке шлёт critical-уведомление, раздел Power пишет «EC is read-only».
- 2026-10-09 — задача 7: причина найдена (Chromium 151/Wayland: окно считает в (0,0), диалог вписывает в work_area дисплея
  в глобальных координатах → при eDP-1 в 3590x559 диалог за пределами окна). Обход: одиночный монитор → 0x0
  (`monitorctl.fix_origin`). Для нескольких мониторов не решено. Урок: `pkill -f` с шаблоном, который есть в тексте
  своей же команды, убивает собственный шелл — шаблон `[c]lass` не спасает, если строка встречается в heredoc.
- 2026-10-11 — после `yay -Syu` (waybar-git r173 → r1085, т. е. 0.16-dev) сломался waybar, Hyprland/smw в порядке.
  1) Апстрим убрал подхват persistent-ws из `workspacerules` (95664c76) → `active-only: true` стал прятать все ws,
  кроме активного; опция убрана (ws smw и так существуют всегда). 2) custom-модули переехали на AIconLabel:
  `#custom-…` теперь на box, а `* { font-size }` бьёт по вложенному label напрямую → иконки 14 px; в style.css
  размер продублирован на `#custom-… label`. Проверено скриншотами на 3 мониторах. «Отступы от края» —
  не воспроизвёл (gaps_out и слои баров как в конфиге), ждёт уточнения от пользователя. Не закоммичено.
  Заодно: hyprpm теперь отдельный пакет; awww-bin → awww 0.12.1; ядро 7.2.9 установлено, нужна перезагрузка.
  Старый waybar из кэша yay не запускается (libjsoncpp.so.26) — для сравнения нужен и старый jsoncpp.
- 2026-10-11 — после того же обновления каждое новое окно kitty открывалось maximized (`fullscreen 1`) поверх тайлов.
  Не Hyprland: kitty 0.49 при `remember_window_size yes` (дефолт) сохраняет в `~/.cache/kitty/main.json` ещё и
  `window-state` и восстанавливает его; раз закрыв maximized-окно, получаешь его навсегда. Фикс:
  `remember_window_size no` в kitty.conf. Проверено: 3 kitty подряд встают тайлами (alacritty не страдал). Не закоммичено.
  Приём: события `fullscreen>>` — `socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HIS/.socket2.sock -`.
- 2026-10-14 — OBS/Discord не захватывали экран: `Error selecting screencast source: … Unavailable cursor mode 1`.
  Фронтенд xdg-desktop-portal отдавал ScreenCast `AvailableCursorModes = 0`, `version = 0` (у xdph 3 и 6): при перелогине
  11.10 D-Bus поднял порталы раньше, чем uwsm передал окружение новой сессии, xdph упал («Couldn't connect to a wayland
  compositor»), фронтенд стартовал без бэкенда и закэшировал пустые свойства. Лечится перезапуском (сначала бэкенды,
  потом фронтенд). Новое: `binc/portals-restart` (ждёт HYPRLAND_INSTANCE_SIGNATURE в окружении systemd) в
  `hyprland.start`. Проверено: свойства 3/6, запрос с `cursor_mode=1` проходит до пикера. Не закоммичено.
  Пока открыт пикер xdph, портал больше ничего не обрабатывает (запросы по таймауту). Закрыть пикер: `pkill -x hyprland-share-`.
- 2026-10-16 — задача 4: интервью (решения — в плане), выбиралка на Quickshell + бэкенд `binc/walls`, обрезка под
  портретные мониторы (awww и hyprlock), разметка gemma (9 пробных). Не закоммичено. quickshell-git → quickshell.
  Урок: два раннера gemma4 при дефолтах ollama съели всю RAM — свой serve только с MAX_LOADED_MODELS=1.
  Урок: `ls | wc -l` в этом шелле даёт 0 (алиас) — считать через find.
- 2026-10-16 — задача 4: ollama на Vulkan (iGPU) — 10–11 с/картинка; фикс курсора сайдбара; замер памяти выбиралки.
- 2026-10-25 — Night light: расписание (21:00/7:00) убрано из `hyprsunset.conf`, только Super+N / CC. hyprsunset
  перезапущен, переключение 6000 ↔ 4500 проверено. Не закоммичено.
- 2026-10-31 — hyprglass 1.1.0 (Hyprland уже 0.57): конфиг «как iOS» в `hypr/lua/glass.lua` (вместо примера из README,
  вставленного в plugin.lua). Пресеты `ios` (на базе встроенного `pomme` + линзовый обод `edge_height`), `ios_small`
  (пилюли waybar, уведомления), `ios_panel` (rofi, центр уведомлений, walls), `ios_window` (окна: focus_light, frost).
  Слои по белому списку, `mask_mode = contour` (у каждой пилюли свой обод); waybar-неймспейсы = имена баров
  `full/medium/compact`. Стекло видно только сквозь прозрачное → wallust-шаблоны: пилюли waybar 0.35, rofi 0.45
  (+ `background-solid` для текста выделенных пунктов), swaync 0.45. Проверено: reload без configerrors, скриншот бара.
  Не закоммичено.
- 2026-10-31 — стекло: переключатель `binc/glass` (+ CC → Toggles): `off` возвращает исходный вид — шаблоны wallust
  снова сплошные, прозрачность только в надстройках `*/glass.{css,rasi}` через `~/.cache/glass/*`. Трей и колокольчик
  были темнее (свой фон поверх фона пилюли) → цвет `inner_pill`, в стекле прозрачный. Пресеты усилены (edge_height 40,
  отражение, тонировка почти прозрачная), серое кольцо вокруг пилюль убрано (fresnel 0.06, bevel 1.2 px без тени).
  rofi: скругление 10 px как у окон Hyprland. Проверено: on/off/on — reload без ошибок, скриншоты бара и CC.
- 2026-10-31 — swaync скруглён (раньше всё `border-radius: 0`): карточки и центр уведомлений 10 px как окна Hyprland,
  внутри 8 px, крестик и переключатель DND — пилюли; фокус группы `.notification-group:focus` (стандартный стиль
  swaync 0.12, GTK4) тоже скруглён. Проверено скриншотами. Добавлена задача 11 (адаптивная светлая/тёмная тема).
- 2026-11-05 — задача 11: обсуждение (решения — в задаче), `binc/theme`, светлые ветки шаблонов, GTK3-темы Wallust-*,
  libadwaita с двумя палитрами, Qt через `kde`/kdeglobals, иконки Adwaita-<цвет>, курсор, CC → Appearance (glass переехал
  из Toggles), `d` в выбиралке, yazi на ANSI, nvim по SIGUSR1, ghostty из wallust. Проверено вживую скриншотами, не закоммичено.
  Уроки: пользовательский CSS GTK3/GTK4 читается один раз — живое переключение только через смену имени темы (GTK3)
  и `@media (prefers-color-scheme)` (GTK4); в шаблонах wallust фильтры `red/green/blue` дают строки — нужен `|int`;
  `wallust cs` ставит `{{wallpaper}}` = путь схемы и `palette = dark` — режим в шаблонах только по цвету фона.
- 2026-11-05 — btop/nvim нечитаемы в светлой: мой ANSI-ремап (7/15 = светло-серые) против pywal-раскладки, которую ждут
  btop TTY и neopywal → kitty/ghostty снова pywal-раскладка, все цвета текста ≥ 4.5. Светлая палитра теперь в 4 вариантах
  (`light_scheme`: neutral/tinted/material(matugen)/paper; `~/.local/state/theme/light-variant` или `THEME_LIGHT_VARIANT`),
  по умолчанию neutral. Сравнение для пользователя: `~/Pictures/theme-variants/<N-обои>/{A..D}-*-{term-opaque,term-095,apps}.jpg`
  + `sheet.jpg`, стенд `~/.cache/theme-variants-work/run.py` (ws 7–9). Пользователь выбрал **C (material)** на всех обоях —
  теперь вариант по умолчанию. Окна без фокуса (`looknfeel.lua`, `inactive_opacity()`): тёмная 0.95, светлая 0.97 без стекла /
  0.8 со стеклом — **на тесте у пользователя**.
  Урок: прозрачность окон даёт Hyprland `inactive_opacity = 0.95`, а не kitty; правило через dispatch стирает `hyprctl reload`.
- 2026-11-05 — CC: убран пункт Snapper snapshot (System) и подписи-пояснения у кнопок (Utilities, System, Appearance,
  Power, «Arrange monitors»); оставлены только состояния (on/off, active, connected, сигнал и т. п.). Коммит 31ec204 (не запушено).
  Глобальный поиск строками подменю под разделами **отклонён**: rofi не прячет строки при пустом запросе — при прокрутке
  вылезали Wi-Fi-сети и BT-устройства. Откачено. Вместо этого — задача 13 (quickseek), решения утверждены grill-сессией,
  к реализации не приступали (пользователь: «пока не начинай»).
  Урок: в rofi строку можно искать по одному тексту, а показывать другой — свойство `\0display\x1f…` (поиск по
  pango-разметке иначе находит «span»); `rofi -filter X -dump` для проверки без окна, при запущенном rofi нужен свой `-pid`.
- 2026-11-05 — задача 13, quickseek v0.1 (см. задачу): демон на Quickshell, поиск по приложениям/CC/power/калькулятору/вебу,
  плагин CC, палитра из wallust, стекло, бинд и автостарт. Конвертация единиц без смешанных («3 mi + 188 yd») —
  `to|in X` переписывается в `to -X` (qalc читает `in` как дюймы). Закоммичено локально (97cdf62, b2e1866). Во время теста по ошибке дважды открылся
  поиск Google «do not disturb» в браузере (выделение уезжало на веб-строку — исправлено).
  Урок: проверять выделенный пункт (`titles[sel]`) перед тестовым запуском действия.
- 2026-11-05 — светлая тема, nvim и терминал. nvim был нечитаем всё время: neopywal при `background=light` считает палитру
  тёмной и **инвертирует** её (`utils/light.lua: convert_dark2light_theme`) → текст #181C20 становился #E7E3DF. Отключено через
  `package.preload` (в `plugins/neopywal.lua`; подмену функции стёр бы `neopywal.load()`). Середина lualine была чёрной (тема `auto`
  ищет `neopywal-light`, собирает из прозрачного фона) → `theme = "neopywal"` + пересборка на ColorScheme.
  Терминал: ANSI wallust не знают смысла («красный» синий, «зелёный» серо-фиолетовый, diff не различался). Теперь
  `binc/theme` → `ansi_scheme()`: оттенок по смыслу (LCh) со сдвигом ≤ 12° к тону обоев, хрома по цветности обоев,
  светлота подбирается под фон этих обоев до контраста (светлая 5.0/4.5, тёмная 7.0/9.5), color8 ≥ 4.5. Эта палитра
  рендерится только в kitty/ghostty/neopywal (`TERMINAL_TEMPLATES`, поверх обычного прогона), акценты интерфейса прежние.
  ghostty `cursor-color` → `{{cursor}}`. Проверено скриншотами (светлая — вживую, тёмная — образцы на 5 обоях).
  Фон терминала (и nvim — он прозрачный) с оттенком акцента: `ANSI_TINT` (светлая: L −1,5, хрома 12/15 у фона/color0;
  тёмная: хрома 9/12), цвета текста считаются уже от этого фона.
  swaync: встроенный стиль 0.12 (/etc/xdg/swaync/style.css) красит подписи через CSS-переменные `--text-color` (белый),
  а не `@define-color` → «Do Not Disturb» был невидим в светлой. В `swaync.css.j2` блок `:root` с `--text-color*`
  (+ в светлой `--noti-bg-focus`, был тёмно-серый ореол вокруг группы). Проверено скриншотами. Коммит ccf8f31, запушено.
- 2026-11-05 — quickseek терял фокус, курсор прыгал к правому краю при `hyprctl reload` (стекло, тема): monitors.lua ставил
  eDP-1 в 3590x559, а хук `fix_origin` возвращал в 0x0 — курсор прижимался к краю. Теперь monitors.lua грузит
  `monitorctl.load()`: одиночный подключённый монитор (`hl.get_monitors{all=true}`) сразу в 0x0. Проверено: курсор 500,400
  до и после reload и glass toggle. Фокус клавиатуры проверить пользователю (инжекта клавиш нет).
  hyprlock: liquid glass (см. «Карту конфигов»), текст всегда светлый. Проверено живой блокировкой (grim + USR1),
  перерисовкой часов в :00, кадрами HDMI/вертикального DP-1. Часы со стеклом — `%-I:%M` без AM/PM.
  Пользователь: открывалось с задержкой (кадр рисовался до exec hyprlock, ~0,5 с/монитор, с холодной базой 2–3 с) и
  «чёрная обводка» (тени надписей) → часы отдельной картинкой параллельно, тени убраны. Блокировка встаёт за ~0,47 с
  в обоих режимах (как без стекла), часы появляются через ~1–1,5 с.
  Урок: каждая тестовая разблокировка `pkill -USR1 hyprlock` = неудачная PAM-попытка → после 3 pam_faillock блокирует
  учётку на 10 мин (sudo, вход). После тестов: `faillock --user $USER --reset` (файл свой, root не нужен).
- 2026-11-07 — задача 6: обсуждение (решения — в задаче), Battery Monitor (`~/Apps/linux-battery-monitor`: сборщик +
  GTK4-окно, импорт истории upower/журнала), автопрофиль Balanced/Eco (`power-mode auto`, `power-auto.service`),
  пункт в CC → Power. Проверено: сборщик (события, сон-логика на тестовой БД, импорт 301 точки и 23 снов), все страницы
  скриншотами в тёмной и светлой теме, SIGUSR1-сброс. Не закоммичено (ни приложение, ни dotfiles).
  Находка: `/sys/power/suspend_stats/{last,total}_hw_sleep` — за boot 02.11–07.11 в S0ix 10,2 ч из 101 ч сна; последний
  сон 21 ч: S0ix ~1 ч, но расход всего 0,42 %/ч (0,37 Вт). В бодрствовании на батарее (по импорту) 6,8–10,3 Вт.
  Урок: окно GTK на скрытом special-ws получает только первый кадр — переключения страниц после него не рисуются.
- 2026-11-07 — задача 13, quickseek v0.2: поиск файлов (свой plocate-индекс + живой fd), Ctrl+P, пустой экран, настройки в окне
  (см. задачу). Разработка в отдельном worktree + dev-копия демона (`QUICKSEEK_APPID`, свои XDG_STATE/CACHE), затем перенесено
  в `~/Apps/quickseek`. `settings.json` после тестов возвращён `git checkout`. Пользователь: «Open settings file» ничего не делал —
  xdg-open запускал nvim без терминала → opener `gio open`. Закоммичено и запушено (3d46a97).
  Уроки: `plocate -b` не находит папки, записанные со слешем (так их выводит fd) — слеш срезать; Quickshell без
  `QT_QPA_PLATFORMTHEME=kde/gtk3` (с qt6ct) не видит тему иконок — помогает и `QS_ICON_THEME`; `grim -o` снимает весь монитор
  с личными окнами — снимать только слой (`hyprctl layers -j` → `grim -g`).
- 2026-11-07 — задача 6, эксперименты (на батарее, eDP 50 %, Eco, без внешних мониторов, статичный экран — замер
  в фоне, иначе анимация TUI Claude Code в kitty не даёт PSR и глубоких C-состояний; 5 мин, `battery-monitor bench`):
  исходно 8,02 Вт, пакет в простое **только PC2** (PC6–PC10 = 0). По очереди, накопительно:
  APST на лету (`pm_qos_latency_tolerance_us=100000`) → 7,58 (−0,45; появились PC6/PC8);
  docker+containerd остановлены (gungnir: 3 контейнера ≈ 27 % CPU на батарее) → 7,07 (−0,5);
  runtime PM `auto` у 10 PCI-устройств (кроме Wi-Fi) → 6,90 (−0,17, на грани шума);
  PSR (`i915_edp_psr_debug=0x3`, драйвер включил PSR1) → 6,52 (−0,38; PC8 42 %). Итого −1,5 Вт (−19 %).
  PSR отдельно, когда пакет не шёл глубже PC2, давал только −0,2. PC10 так и не появился (вероятно, Wi-Fi без
  энергосбережения — пользователь его не включает: «автономность от него не менялась»). Внешние мониторы на батарее
  ≈ +2,7 Вт. Все изменения на лету, после перезагрузки откатятся (кроме docker — он enabled и поднимется сам).
  Контроль после установки `nvme-apst` + udev runtime PM (до перезагрузки, PSR выкл, docker вкл): на пустом ws медиана
  7,03 Вт, среднее 8,44 (всплески до 13 Вт — контейнеры gungnir, 35 % CPU в простое). Прогон с kitty на экране — 11 Вт и
  только PC2: спиннер Claude Code в заголовке kitty перерисовывает экран → для замеров уводить экран на пустой ws
  (`hl.dsp.focus({ workspace = "9" })`). «Keep awake» — временный юнит: `systemd-run --user --unit cc-caffeine … systemd-inhibit
  --what=idle … sleep infinity`, иначе hypridle через 120 с тушит яркость. Ждёт: перезагрузка → замер с PSR.
  Заметка: Hyprland (`wayland-wm`) ~10 % ядра в простое даже на пустом ws — проверить отдельно.
- 2026-11-07 — «Hyprland ест 10 %»: нет. В простое на пустом ws Hyprland 0,1 % CPU, ~9 пробуждений/с. 10 % — это
  (1) учёт Battery Monitor: в cgroup `wayland-wm@hyprland.desktop.service` живёт всё, что бинды запускают без `uwsm app`
  (Chromium, kitty, waybar, wireguard-gui) — исправлено (ad39b0b: процессы в cgroup композитора делятся по верхнему
  предку под композитором, строки с одним именем приложения сливаются), старые данные остаются слитыми;
  (2) мой TUI в kitty перерисовывается, пока я работаю. В простое заметны: GPU-процесс Chromium 0,7 %, wireguard-gui
  (AppImage) 16 пробуждений/с + WebKit 0,4 %.
- 2026-11-07 — задача 6, замер после перезагрузки (APST + runtime PM постоянные, docker с gungnir работает, PSR не
  включился — grub.cfg не пересобран; батарея, eDP 50 %, Eco, пустой ws): **5,88 Вт среднее, 5,63 медиана** (4,86–10,21),
  CPU 1,0 %. Было исходно 8,02 / 7,87. Лучше прогона «всё на лету» (6,52), хотя тут docker включён, а PSR нет:
  в этот раз не был запущен Chromium (в прошлых прогонах его GPU-процесс ~0,7 % CPU) и система после перезагрузки «чистая» —
  сравнение не один к одному.
- 2026-11-07 — замер с PSR после перезагрузки (cmdline `xe.enable_psr=1` применился, «tainting kernel»): 7,66 Вт через 5 мин
  после загрузки и 7,73 через 15 мин (медианы 7,31 / 7,39) — стабильно, но на ~1,8 Вт хуже прогона 19:09 без PSR.
  Причина не ясна: CPU выше (1,7 % против 1,0 %), в простое gungnir-server ~8 %, WebKit (wireguard-gui) ~4 %, Xwayland 2 %.
  Не путать PSR с нагрузкой — нужен A/B на лету в одной загрузке. Dotfiles запушены (98a09c1).
- 2026-11-09 — hyprcapture на повёрнутом мониторе показывал экран боком и растянутым. Причина: Hyprland 0.57 рендерит
  FULL_FAKE-проход монитора в логической ориентации (`RPT_MONITOR` = `outputProjection(m_transformedSize, NORMAL)`),
  плагин же брал буфер `m_pixelSize` (1920×1080 для вертикального 1080×1920), а UI ещё и поворачивал на 90°.
  Патч в `~/Apps/HyprCapture` (ветка `local`): буферы монитора — `m_transformedSize`, доворот убран (оверлей, регион,
  запись, scroll, real background), в протоколе `transform = 0`. Проверено на headless-мониторе с transform 1
  (`hyprctl output create headless X` + `hl.monitor{…transform=1}`): кадр `export_pipe` совпал с `grim -o` в пределах шума,
  оверлей на нём вертикальный и без растяжения. Сейчас загружен вручную (`hyprctl plugin load` из scratchpad) —
  **ждёт пользователя:** установка через hyprpm (нужен sudo). Не проверено: запись видео и scroll-захват на повёрнутом мониторе.
  Урок: `hyprcapture-ui` не выходит по SIGTERM — закрывать `kill -INT`; `hyprctl plugin load` перечитывает конфиг и
  сбрасывает правила мониторов, заданные через `hyprctl eval`.
- 2026-11-09 — задача 13, quickseek v0.3: файлы только по префиксу `f` (решение пользователя), `refresh` у плагинов
  (открытие подешевело с ~1,4 с до ~0,1 с CPU), замеры в README, Super+Space → quickseek. В ветках, не слито.
  Приём: dev-копия `QUICKSEEK_APPID=… XDG_CONFIG_HOME=… XDG_STATE_HOME=… qs -p <worktree> -n` + IPC `rows`;
  горячая перезагрузка не подхватывает новые IPC-функции — перезапускать демон.
- 2026-11-11 — задача 12, quickdesk v0.1: сторона dotfiles сделана (не закоммичено): бинд Super+W, автостарт,
  `hypr/lua/quickdesk.lua` (хук «монитор занят окнами» → IPC), слой `quickdesk` в glass.lua, blur-правило слоя
  `quickdesk-overlay` (windowrules.lua), `quickdesk.json` в `binc/glass`, цель `quickdesk` в wallust.toml, пакет `quickdesk/`
  (застоуен). Подробности и что осталось проверить — в `~/Apps/quickdesk/CLAUDE.md`.
- 2026-11-11 — quickdesk: Super+W теперь `exec_cmd` (toggle по IPC, а если демон не запущен — старт сразу в редакторе),
  `quitWhenEmpty` в `quickdesk/settings.json` (без виджетов демон не висит). autostart.lua: на `monitor.added/removed`
  через 3 с `qs -p … -n` для quickseek и quickdesk — quickseek падал с ошибкой протокола Wayland при смене мониторов
  (01:19, тестовый headless), `-n` не трогает живой экземпляр. Не закоммичено.
- 2026-11-13 — задача 13, quickseek v0.4 (см. задачу): Esc по уровням + удержание окна до отпускания клавиш, rofi удалён
  (CC → пакет `cc/`, Session-папка), курсы валют, буфер clipse, меню действий, превью по Space, `>` команды, эмодзи.
  Worktree `.claude/` в обоих репо и слитые ветки (локально и на GitHub) удалены.
  Уроки: новый синглтон Quickshell hot reload не подхватывает — перезапуск демона; в `onItemChanged` производные
  привязки ещё старые — `Qt.callLater`; FileView после `setText` отдаёт старый `text()`; тестовое окно quickseek забирает
  клавиатуру — пользователь в это время печатает в него (держать открытым секунды); перед `key enter` смотреть `^>` в
  `rows` (по ошибке открыл Nautilus через «Show in folder»); скриншоты стеклянного окна захватывают фон под ним.
- 2026-11-16 — **headless-мониторы убивают клиентов.** Сессия-оркестратор в 14:00:35 создала `TEST-QS`/`TEST-QD`
  (`hyprctl output create headless`) для теста quickseek/quickdesk; в 14:00:49 Hyprland отключил kitty (pid 74882 — все окна
  kitty, single-instance), Telegram и ещё один kitty: `unknown object (N), message attach(?oii)` → `error in client
  communication`. Chromium выжил. Так же 11.11 падал quickseek. Урок: **headless-мониторы на живой сессии не создавать**
  (пользователь просил «виртуальный монитор, чтобы не мешать», но так нельзя). Вместо этого — **изолированный стенд**
  `/tmp/claude-1000/stand/stand` (не в репо): `kwin_wayland --virtual` (без D-Bus) → вложенный Hyprland в `bwrap` без
  `/dev/input` и `card0` (`LIBSEAT_BACKEND=noop`, `HYPRLAND_NO_SD_*`), клавиатуру пользователя не видит.
  `STAND_NAME=x stand start|run CMD|shot FILE|stop`, монитор WAYLAND-1 1280x720. Тестовые копии qs — из git worktree
  (живые демоны подхватывают правки ~/Apps/* на лету), IPC только `qs ipc --pid`. `pkill -f 'class standtest'` снова убил свой шелл.
- 2026-11-16 — оркестратор (субагенты Sonnet/Haiku, тесты на стенде): форки hymission/HyprCapture, воспроизводимость dotfiles
  (`dot units`, bootstrap клонирует ~/Apps, logind/snapper/bluetooth/pacman в system/, portals.conf в stow, pkgs save),
  quickseek v0.5, quickdesk-полировка, задача 7 закрыта, мусор из ~/.config — в корзину (`gio trash`). Всё запушено.
  Ждёт пользователя: sudo-команды hyprlock-delay/libvirtd (+ `dot units save`), GitHub MCP (`claude mcp add` заблокирован
  классификатором — токен в конфиг), откат `is_test()` в monitorctl.lua (откат заблокирован), `yay -Rns niri eww wayle`.
- 2026-11-16 — после оркестратора остались 4 вложенных Hyprland со стенда (`/tmp/claude-1000/stand/{,qs/,qd/,qd2/}test.lua`,
  родитель — systemd): kwin_wayland уже умер, и они крутились по ~100 % CPU каждый (~4 ядра, разряд ~40 Вт). Убиты по PID,
  настоящий Hyprland (`--watchdog-fd`) не тронут. Урок: после работы со стендом всегда `stand stop` и проверка
  `pgrep -fa 'stand/.*test.lua'` — пусто; без kwin вложенный Hyprland не выходит сам, а уходит в 100 %.
- 2026-11-16 — батарея −65 % за 3 ч (19,6 Вт в среднем): 14:40–15:15 — 31–38 Вт от брошенных вложенных Hyprland со стенда
  (`user:kitty` 4 ядра), 14:00–14:20 и 15:25–15:40 — Chromium ~2 ядра (звонок в Google Meet, у пользователя на звонках
  стабильно > 20 Вт). Тест WebRTC loopback (фейковая камера, отдельный профиль): декод на VA-API, **кодирование программное**
  (libvpx/libaom/OpenH264). С `AcceleratedVideoEncoder` VP9/AV1/H.264 L1T1 → `VaapiVideoEncodeAccelerator`, но SVC
  (L1T3, L3T3_KEY — то, что обычно шлёт Meet) остаётся программным, флагов VA-API SVC в сборке нет. Флаг добавлен в
  `chromium-flags.conf` (не закоммичено). Ждёт: замер на следующем звонке (`chrome://webrtc-internals` → encoderImplementation,
  scalabilityMode; `battery-monitor` по времени звонка).
- 2026-11-16 — закоммичено и запушено: sleep-hold (19a0f9c), AcceleratedVideoEncoder в chromium-flags (92d74b6).
  `pkg_install/pkg_aur_install/pkg_remove`: окно не закрывалось — `show_done.sh` был `gum spin -- bash` (клавиши уходили
  в bash, закрывал только Ctrl+D/exit) и звался по пути от `$HOME`. Теперь `show_done.sh КОД`: «Done»/«Failed», выход по
  любой клавише (`read -rsn1` из /dev/tty, клавиши, нажатые во время установки, выбрасываются), пакеты — массивом без xargs.
  Проверено в pty (`script`): x, стрелка, пробел, Enter — выход; ранний ввод не закрывает. Не закоммичено.

- 2026-11-19 — шрифт часов hyprlock без стекла: SF Pro Display установлен, но hyprgraphics 0.6.0
  после разбора `SF Pro Display Bold` задаёт weight=400, поэтому часы рисовались Regular.
  Шаблон теперь задаёт семейство `SF Pro Display`, жирность — разметкой `<b>…</b>`.
  Проверено через установленный CTextResource: до правки пиксели совпадали с Regular,
  после — с эталоном Bold (weight=700). wallust перегенерировал только шаблон hyprlock,
  `lock --prepare` собрал конфиг. Экран блокировки не запускался; итог вживую ждёт пользователя.
- 2026-11-21 — обновлены README, карта компонентов, сочетания клавиш и описание установки.
  На изолированном виртуальном дисплее Hyprland записан 17-секундный ролик: поиск, калькулятор,
  меню сессии, Kitty и добавление календаря quickdesk. Обложка взята из финальной сцены.
