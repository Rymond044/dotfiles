#!/usr/bin/env python3
"""Установка выбранных компонентов. Построение плана не имеет побочных эффектов."""
from __future__ import annotations

import argparse
import configparser
import datetime
import difflib
import json
import os
from pathlib import Path
import pwd
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'packages/scopes.json'
# Эти файлы устанавливаются отдельно: выбор зависит от hardware/MIME и локальных данных.
IGNORE = r'(^|/)(mimeapps\.list|wallust\.toml|\.gtkrc-2\.0|chromium-flags\.conf|electron-flags\.conf|MControlCenter\.conf|ec-sync\.service|cameractrlsd\.service|hyprlock\.conf|user-dirs\.(dirs|locale)|clipboard_history\.json|clipse\.log|tmp_files|bookmarks|myvpn|libadwaita\.css)$|^\.config/hypr/monitors\.(lua|conf)$'
ELECTRON_APPS = {'discord', 'chatgpt-bin', 'claude-desktop', 'visual-studio-code-bin', 'github-desktop', 'escrcpy-bin'}
DESKTOP_PACKAGES = {
    'org.gnome.Nautilus.desktop': 'nautilus', 'chromium.desktop': 'chromium',
    'org.gnome.eog.desktop': 'eog', 'gimp.desktop': 'gimp',
    'org.gnome.Papers.desktop': 'papers', 'org.gnome.Evince.desktop': 'evince',
    'com.github.babluboy.bookworm.desktop': 'bookworm', 'FBReader.desktop': 'fbreader',
    'mpv.desktop': 'mpv', 'nvim.desktop': 'neovim', 'org.kde.ark.desktop': 'ark',
    'org.kde.kfontview.desktop': 'plasma-workspace', 'swappy.desktop': 'swappy',
    'org.keepassxc.KeePassXC.desktop': 'keepassxc',
    'org.qbittorrent.qBittorrent.desktop': 'qbittorrent',
    'com.anthropic.Claude.desktop': 'claude-desktop',
    'claude-code-url-handler.desktop': 'claude-code', 'chatgpt.desktop': 'chatgpt-bin',
}


def catalog():
    return json.loads(CATALOG.read_text())


def csv_ids(value):
    return [] if value in ('', 'none') else value.split(',')


def make_plan(users=(), hardware=(), features=(), data=None):
    data = data or catalog()
    by_id = {x['id']: x for x in data['user']}
    for selected, known in [(users, by_id), (hardware, data['hardware']), (features, data['features'])]:
        unknown = set(selected) - set(known)
        if unknown:
            raise ValueError('Unknown selection: ' + ', '.join(sorted(unknown)))
    system = data['system']
    plan = {k: set(system.get(k, [])) for k in ('repo', 'aur', 'configs', 'units_system', 'units_user')}
    for item in [by_id[x] for x in users]:
        plan[item['source']].add(item['id'])
        plan['configs'].update(item.get('configs', []))
    for item in [data['hardware'][x] for x in hardware] + [data['features'][x] for x in features]:
        for key in ('repo', 'aur', 'units_system', 'units_user'):
            plan[key].update(item.get(key, []))
    if 'msi' not in hardware:
        plan['configs'].discard('nwg-displays')
    if 'docker' in users:
        plan['units_system'].add('docker.socket')
    if 'libvirt' in users or 'virt-manager' in users:
        plan['units_system'].update(['libvirtd.socket', 'libvirtd-ro.socket', 'libvirtd-admin.socket'])
    plan = {k: sorted(v) for k, v in plan.items()}
    plan.update(user=sorted(set(users)), hardware=sorted(set(hardware)), features=sorted(set(features)))
    plan['projects'] = json.loads((ROOT / 'install/projects.json').read_text())['apps']
    return plan


def run(args, *, capture=False, check=True, log_path=None, **kwargs):
    print('+ ' + shlex.join(map(str, args)), flush=True)
    command = list(map(str, args))
    if log_path is not None:
        Path(log_path).parent.mkdir(parents=True, exist_ok=True)
        # Сохраняем только вывод PTY: скрытый ввод пароля sudo в лог не записывается.
        command = ['script', '--quiet', '--return', '--flush', '--append', '--log-out', str(log_path), '--command', shlex.join(command)]
    return subprocess.run(command, check=check, text=True, capture_output=capture, **kwargs)


def confirm(question):
    if not sys.stdin.isatty():
        raise RuntimeError('Interactive confirmation is required; use --plan for unattended inspection.')
    return input(question + ' [y/N] ').strip().lower() == 'y'


def choose(title, items, defaults=()):
    """gum отображает настоящие чекбоксы; без него доступен простой выбор номеров."""
    if not sys.stdin.isatty():
        raise RuntimeError('Choose explicitly with --user/--hardware/--features, or run in a terminal.')
    labels = {f'{key} — {label.replace(chr(10), " ").replace(",", ";")}': key for key, label in items}
    if shutil.which('gum'):
        selected = [label for label, key in labels.items() if key in defaults]
        args = ['gum', 'choose', '--no-limit', '--header', title, '--height', '18']
        if selected:
            args += ['--selected', ','.join(selected)]
        result = subprocess.run(args + list(labels), text=True, stdout=subprocess.PIPE)
        if result.returncode:
            raise KeyboardInterrupt
        return [labels[x] for x in result.stdout.splitlines() if x in labels]
    print('\n' + title)
    entries = list(items)
    selected = set(defaults)
    while True:
        for i, (key, label) in enumerate(entries, 1):
            print(f' {i:3}. [{"x" if key in selected else " "}] {key} — {label}')
        answer = input('Toggle numbers (e.g. 1 3), all, none; Enter accepts: ').strip()
        if not answer:
            return sorted(selected)
        if answer in ('all', 'none'):
            selected = {x[0] for x in entries} if answer == 'all' else set()
            continue
        try:
            numbers = [int(x) for x in answer.split()]
            if any(n < 1 or n > len(entries) for n in numbers):
                raise ValueError
            for n in numbers:
                selected.symmetric_difference_update({entries[n - 1][0]})
        except ValueError:
            print('Invalid selection.')


def render_mime(text, packages):
    """Основные и дополнительные ассоциации ограничены выбранными приложениями."""
    result = []
    for line in text.splitlines():
        if not line or line.startswith(('#', '[')) or '=' not in line:
            result.append(line)
            continue
        key, value = line.split('=', 1)
        values = []
        for desktop in value.split(';'):
            package = 'libreoffice-still' if desktop.startswith('libreoffice-') else DESKTOP_PACKAGES.get(desktop)
            if package in packages:
                values.append(desktop)
        # Нынешнее назначение vesktop устарело; владелец выбрал обычный Discord.
        if key == 'x-scheme-handler/discord' and 'discord' in packages:
            values = ['discord.desktop']
        if values:
            result.append(key + '=' + ';'.join(values) + (';' if value.endswith(';') else ''))
    return '\n'.join(result) + '\n'


def render_wallust(text, packages):
    """Не создаём файлы настройки личных программ только из-за общей темы."""
    optional = {'codex': 'openai-codex', 'ghostty': 'ghostty'}
    lines = []
    for line in text.splitlines():
        match = re.match(r'^\s*(codex|ghostty)\s*=', line)
        if match and optional[match.group(1)] not in packages:
            continue
        lines.append(line)
    return '\n'.join(lines) + '\n'


def merge_grub(text, additions):
    """Добавляем параметры по ключу, сохраняя cryptdevice/root и остальные настройки."""
    key = 'GRUB_CMDLINE_LINUX_DEFAULT'
    match = re.search(rf'^{key}=(.*)$', text, re.M)
    if match:
        if '$' in match.group(1) or '`' in match.group(1):
            raise RuntimeError('GRUB cmdline contains shell expansion; merge the hardware parameters manually.')
        parsed = shlex.split(match.group(1))
        current = shlex.split(parsed[0]) if parsed else []
    else:
        current = []
    replacements = {x.split('=', 1)[0]: x for x in additions}
    current = [x for x in current if x.split('=', 1)[0] not in replacements]
    current += additions
    # Не допускаем интерпретации shell-метасимволов при чтении GRUB.
    value = shlex.quote(' '.join(current))
    line = f'{key}={value}'
    return text[:match.start()] + line + text[match.end():] if match else text.rstrip() + '\n' + line + '\n'


def merge_mime(existing, generated, available):
    """Сохраняем рабочие локальные назначения невыбранных приложений; новых не добавляем."""
    old = configparser.ConfigParser(interpolation=None, strict=False)
    new = configparser.ConfigParser(interpolation=None, strict=False)
    old.optionxform = new.optionxform = str
    old.read_string(existing)
    new.read_string(generated)
    for section in old.sections():
        for key, value in list(old[section].items()):
            valid = [x for x in value.split(';') if x in available]
            if valid:
                old[section][key] = ';'.join(valid) + (';' if value.endswith(';') else '')
            else:
                del old[section][key]
    for section in new.sections():
        if not old.has_section(section):
            old.add_section(section)
        for key, value in new[section].items():
            old[section][key] = value
    import io
    output = io.StringIO()
    old.write(output, space_around_delimiters=False)
    return output.getvalue()


class Installer:
    def __init__(self, plan, home=None):
        self.plan = plan
        self.home = Path(home or Path.home())
        self.config = self.home / '.config'
        self.backup = self.home / '.dotfiles-backup' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
        self.selected = set(plan['repo'] + plan['aur'])
        self.package_failures = {}
        self.deferred = []
        self.package_logs = self.home / '.local/state/dotfiles/install-logs' / self.backup.name

    def local_parents(self, target):
        """Новые локальные файлы не должны попадать в репо через folded-папки stow."""
        relative = target.relative_to(self.home)
        current = self.home
        for component in relative.parts[:-1]:
            current /= component
            if current.is_symlink() and current.resolve().is_relative_to(ROOT):
                original = current.resolve()
                if not original.is_dir():
                    raise RuntimeError(f'Config parent is not a directory: {current}')
                self.backup_file(current)
                current.mkdir()
                for child in original.iterdir():
                    (current / child.name).symlink_to(child)

    def backup_file(self, target):
        self.local_parents(target)
        relative = target.relative_to(self.home)
        backup = self.backup / relative
        # Ссылка на папку в бэкапе не должна стать родителем последующих бэкапов.
        if target.is_symlink():
            backup = backup.with_name(backup.name + '.symlink')
        backup.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            backup.symlink_to(os.readlink(target))
        elif target.is_dir():
            shutil.move(target, backup)
            print(f'Backed up: {target} -> {backup}')
            return
        else:
            shutil.copy2(target, backup)
        target.unlink()
        print(f'Backed up: {target} -> {backup}')

    def write(self, target, content, *, mode=0o644, preserve=False):
        target = Path(target)
        if preserve and (target.exists() or target.is_symlink()):
            return False
        self.local_parents(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            if preserve or (target.is_file() and target.read_bytes() == content):
                return False
            self.backup_file(target)
        # Создаём секреты сразу с закрытыми правами, не chmod после записи.
        fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
        with os.fdopen(fd, 'wb') as stream:
            stream.write(content)
        return True

    def link(self, source, target):
        self.local_parents(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink() and target.resolve() == source.resolve():
            return
        if target.exists() or target.is_symlink():
            self.backup_file(target)
        target.symlink_to(source)

    def packages(self):
        # Сначала обновляем pacman/libalpm, и только затем собираем/проверяем yay.
        run(['sudo', 'pacman', '-Syu', '--needed', 'git', 'stow', 'base-devel', 'gum', 'util-linux'])
        self.repositories()
        # Полное обновление избегает частичного обновления Arch после синхронизации баз.
        run(['sudo', 'pacman', '-Syu', '--needed', *self.plan['repo']])
        missing = [name for name in self.plan['aur'] if not self.package_installed(name)]
        yay_ready = self.ensure_yay() if self.plan['aur'] else True
        if not yay_ready:
            self.deferred.append('AUR helper yay is unavailable; see the installer output and yay.log.')
        if not missing:
            return
        for name in missing:
            self.install_extra_package(name, yay_ready)
        # Единственный повтор только неустановленных целей: сетевой сбой не пересобирает весь набор.
        for name in list(self.package_failures):
            self.install_extra_package(name, yay_ready)

    def package_installed(self, name):
        return run(['pacman', '-Qq', name], capture=True, check=False).returncode == 0

    def ensure_yay(self):
        if shutil.which('yay') and run(['yay', '--version'], capture=True, check=False).returncode == 0:
            return True
        try:
            with tempfile.TemporaryDirectory(prefix='dotfiles-yay-') as temp:
                run(['git', 'clone', 'https://aur.archlinux.org/yay-bin.git', temp + '/yay'])
                log = self.package_logs / 'yay.log'
                self.local_parents(log)
                result = run(['makepkg', '-si'], cwd=temp + '/yay', check=False, log_path=log)
                if result.returncode in (130, -2):
                    raise KeyboardInterrupt
                if result.returncode:
                    return False
            return run(['yay', '--version'], capture=True, check=False).returncode == 0
        except (OSError, subprocess.CalledProcessError) as error:
            print(f'AUR helper unavailable: {error}. Continuing other setup steps.')
            return False

    def install_extra_package(self, name, yay_ready):
        if self.package_installed(name):
            self.package_failures.pop(name, None)
            return
        log = self.package_logs / f'{name}.log'
        self.local_parents(log)
        status = 1
        try:
            # Пакет мог переехать в официальный репозиторий после создания каталога.
            native = run(['pacman', '-Si', name], capture=True, check=False).returncode == 0
            if native or yay_ready:
                command = ['sudo', 'pacman', '-S', '--needed', name] if native else ['yay', '-S', '--needed', name]
                status = run(command, check=False, log_path=log).returncode
                if status in (130, -2):
                    raise KeyboardInterrupt
            # yay может сообщить ошибку после частично успешной транзакции. Проверяем БД.
            if not self.package_installed(name) and name == 'apple-fonts':
                status = self.repair_apple_fonts(log)
        except (OSError, subprocess.CalledProcessError) as error:
            print(f'{name}: {error}')
        if self.package_installed(name):
            self.package_failures.pop(name, None)
            print(f'Installed: {name}')
        else:
            self.package_failures[name] = {'status': status or 1, 'log': str(log)}
            print(f'Pending package: {name}. Continuing; build output: {log}')

    def repair_apple_fonts(self, log):
        print('Building apple-fonts from the corrected, checksum-verified recipe.')
        directory = self.home / '.cache/dotfiles/build/apple-fonts'
        self.write(directory / 'PKGBUILD', (ROOT / 'install/aur/apple-fonts/PKGBUILD').read_bytes())
        self.write(directory / 'makepkg.conf', b'source /etc/makepkg.conf\nCOMPRESSZST=(zstd -c -T2 -3 -)\n')
        sources = directory / 'sources'
        sources.mkdir(exist_ok=True)
        result = run(['makepkg', '--config', directory / 'makepkg.conf', '-si', '--needed', '--cleanbuild'], cwd=directory,
                     env=dict(os.environ, SRCDEST=str(sources), MAKEFLAGS='-j2'), check=False, log_path=log)
        if result.returncode in (130, -2):
            raise KeyboardInterrupt
        return result.returncode

    def installation_report(self):
        complete = not self.package_failures and not self.deferred
        report = self.home / '.local/state/dotfiles/install-report.json'
        self.write(report, (json.dumps({'complete': complete, 'missing_packages': self.package_failures,
                                      'deferred_steps': self.deferred}, indent=2) + '\n').encode())
        if not complete:
            print('Setup continued, but some components still need attention:')
            for name, details in self.package_failures.items():
                print(f'  {name}: {details["log"]}')
            for step in self.deferred:
                print('  ' + step)
            print(f'Status report: {report}\nRerun bootstrap after resolving the listed errors; installed packages are skipped.')
        return complete

    def clone(self, project, destination):
        if destination.exists():
            if not (destination / '.git').exists():
                raise RuntimeError(f'{destination} is not a git checkout; nothing was overwritten.')
            actual = run(['git', '-C', destination, 'rev-parse', 'HEAD'], capture=True).stdout.strip()
            if actual != project['rev']:
                print(f'Local checkout preserved: {destination} ({actual}; published lock {project["rev"]}).')
            if run(['git', '-C', destination, 'diff', '--quiet', 'HEAD', '--'], check=False).returncode:
                print(f'Local changes preserved: {destination}. This installation uses local overrides.')
            return
        destination.parent.mkdir(parents=True, exist_ok=True)
        # Транзакционный клон: не оставляем полусобранную целевую папку при сетевом сбое.
        with tempfile.TemporaryDirectory(dir=destination.parent, prefix='.dotfiles-clone-') as temp:
            checkout = Path(temp) / 'repo'
            run(['git', 'clone', '--no-checkout', project['url'], checkout])
            run(['git', '-C', checkout, 'checkout', '--detach', project['rev']])
            run(['git', '-C', checkout, 'submodule', 'update', '--init', '--recursive'])
            checkout.rename(destination)

    def projects(self):
        projects = json.loads((ROOT / 'install/projects.json').read_text())
        for item in projects['apps']:
            self.clone(item, self.home / 'Apps' / item['name'])
        for item in projects['shell']:
            destination = self.home / '.oh-my-zsh'
            if item['name'] != 'oh-my-zsh':
                destination /= 'custom/plugins/' + item['name']
            self.clone(item, destination)
        app = self.home / 'Apps/linux-battery-monitor'
        binary = self.home / '.local/bin/battery-monitor'
        self.link(app / 'bin/battery-monitor', binary)
        for source, relative in [
            ('data/battery-monitor.service', '.config/systemd/user/battery-monitor.service'),
            ('data/io.github.rymond044.BatteryMonitor.desktop', '.local/share/applications/io.github.rymond044.BatteryMonitor.desktop'),
        ]:
            self.write(self.home / relative, (app / source).read_text().replace('@BIN@', str(binary)).encode())
        self.link(app / 'data/io.github.rymond044.BatteryMonitor.svg', self.home / '.local/share/icons/hicolor/scalable/apps/io.github.rymond044.BatteryMonitor.svg')

    def configs(self):
        run(['git', '-C', ROOT, 'submodule', 'update', '--init', '--recursive'])
        # Проверяем конфликты до изменений. Не забираем локальные файлы в публичный репозиторий.
        conflicts = []
        for package in self.plan['configs']:
            directory = ROOT / package
            if not directory.is_dir():
                raise RuntimeError(f'Missing config package: {package}')
            for source in directory.rglob('*'):
                relative = source.relative_to(directory)
                if not source.is_file() or '.git' in relative.parts or re.search(IGNORE, relative.as_posix()):
                    continue
                target = self.home / relative
                if target.resolve() == source.resolve():
                    continue
                if target.exists() or target.is_symlink():
                    if target.is_dir():
                        raise RuntimeError(f'Config file conflicts with a directory: {target}')
                    conflicts.append(target)
        if conflicts:
            print('Existing config files will be backed up:\n' + '\n'.join(map(str, conflicts)))
            if not confirm('Back up these files and install the selected configs?'):
                raise RuntimeError('Config installation cancelled.')
            for target in conflicts:
                self.backup_file(target)
        for package in self.plan['configs']:
            directory = ROOT / package
            absolute_links = [p for p in directory.rglob('*') if p.is_symlink() and os.path.isabs(os.readlink(p))]
            extra = ['^' + re.escape(p.relative_to(directory).as_posix()) + '$' for p in absolute_links]
            ignore = '|'.join([IGNORE] + extra)
            run(['stow', '-d', ROOT, '-t', self.home, '--no-folding', '--restow', '--ignore', ignore, package])
            # stow не разворачивает абсолютные source-ссылки при --no-folding.
            for source in absolute_links:
                self.link(Path(os.readlink(source)), self.home / source.relative_to(directory))
        mime = self.config / 'mimeapps.list'
        generated = render_mime((ROOT / 'session/.config/mimeapps.list').read_text(), self.selected)
        available = {p.name for directory in [Path('/usr/share/applications'), self.home / '.local/share/applications'] for p in directory.glob('*.desktop')}
        content = merge_mime(mime.read_text() if mime.exists() else '', generated, available)
        self.write(mime, content.encode())
        if 'wallust' in self.plan['configs']:
            source = ROOT / 'wallust/.config/wallust/wallust.toml'
            self.write(self.config / 'wallust/wallust.toml', render_wallust(source.read_text(), self.selected).encode())
        if 'gtk' in self.plan['configs']:
            source = (ROOT / 'gtk/.gtkrc-2.0').read_text()
            content = re.sub(r'(?m)^(include\s+")/home/[^/]+/', lambda m: m.group(1) + str(self.home) + '/', source)
            self.write(self.home / '.gtkrc-2.0', content.encode())
            self.write(self.home / '.gtkrc-2.0.mine', b'', preserve=True)
        # Wayland — общий выбор; экспериментальные GPU-флаги принадлежат профилю MSI.
        for name in ['chromium-flags.conf', 'electron-flags.conf']:
            if name == 'electron-flags.conf' and not self.selected.intersection(ELECTRON_APPS):
                continue
            source = ROOT / 'install/templates' / name
            if 'msi' in self.plan['hardware']:
                source = ROOT / 'hardware/msi/home/.config' / name
            self.write(self.config / name, source.read_bytes())
        self.write(self.config / 'dotfiles/.env', (ROOT / 'install/templates/.env.example').read_bytes(), mode=0o600, preserve=True)
        self.write(self.home / '.zshenv', (ROOT / 'install/templates/.zshenv.example').read_bytes(), preserve=True)
        # Общая раскладка не зависит от имен/масштабов мониторов владельца репозитория.
        monitors = ROOT / 'install/templates/monitors.lua'
        if 'msi' not in self.plan['hardware']:
            self.write(self.config / 'hypr/monitors.lua', monitors.read_bytes(), preserve=True)
        if 'msi' in self.plan['hardware']:
            for source in (ROOT / 'hardware/msi/home').rglob('*'):
                if source.is_file():
                    if source.name in {'chromium-flags.conf', 'electron-flags.conf'}:
                        continue
                    target = self.home / source.relative_to(ROOT / 'hardware/msi/home')
                    # Уже настроенные мониторы не заменяем даже при выборе профиля.
                    self.write(target, source.read_bytes(), preserve=source.name.startswith('monitors.'))
            for relative in ['.config/MControlCenter.conf', '.config/systemd/user/ec-sync.service']:
                self.link(ROOT / 'session' / relative, self.home / relative)
            self.write(self.config / 'dotfiles/hardware/msi', b'Enabled\n', preserve=True)
        run(['xdg-user-dirs-update'])
        if 'fingerprint' in self.plan['hardware']:
            self.write(self.config / 'dotfiles/fingerprint.enabled', b'Enabled\n', preserve=True)
        # Не меняем login shell автоматически: выбор отображается отдельно и подтверждается.
        if pwd.getpwuid(os.getuid()).pw_shell != '/usr/bin/zsh' and confirm('Use zsh as your login shell?'):
            run(['chsh', '-s', '/usr/bin/zsh'])

    def root_files(self):
        result = {}
        for directory in [ROOT / 'system'] + [ROOT / 'hardware' / x / 'etc' for x in self.plan['hardware']]:
            if not directory.exists():
                continue
            for source in directory.rglob('*'):
                if source.is_file():
                    relative = source.relative_to(ROOT / 'system') if directory == ROOT / 'system' else Path('etc') / source.relative_to(directory)
                    result['/' + relative.as_posix()] = source.read_bytes()
        grub = Path('/etc/default/grub')
        if grub.exists():
            text = grub.read_text()
            for key, value in {'GRUB_DEFAULT': '0', 'GRUB_TIMEOUT': '0', 'GRUB_TIMEOUT_STYLE': 'hidden'}.items():
                line = f'{key}={value}'
                text = re.sub(rf'^{key}=.*$', line, text, flags=re.M) if re.search(rf'^{key}=', text, re.M) else text.rstrip() + '\n' + line + '\n'
            result[str(grub)] = text.encode()
        # Имя пользователя — параметр установки, не сохранённое имя владельца dotfiles.
        username = pwd.getpwuid(os.getuid()).pw_name
        if all((self.home / '.cache/wallust' / name).is_file() for name in ['hyprland.lua', 'hyprlock.conf']):
            result['/etc/systemd/system/getty@tty1.service.d/zz-dotfiles.conf'] = (
                '[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin ' + username + ' --noclear %I $TERM\n'
            ).encode()
        else:
            self.deferred.append('Console autologin deferred: the initial desktop/lock theme is not ready.')
        if 'msi' in self.plan['hardware']:
            target = Path('/etc/default/grub')
            if target.exists():
                additions = (ROOT / 'hardware/msi/grub-cmdline.txt').read_text().split()
                result[str(target)] = merge_grub(result.get(str(target), target.read_bytes()).decode(), additions).encode()
            init = Path('/etc/mkinitcpio.conf')
            if init.exists():
                text = init.read_text()
                match = re.search(r'^MODULES=\(([^)]*)\)', text, re.M)
                if not match:
                    raise RuntimeError('Cannot safely merge MODULES in /etc/mkinitcpio.conf')
                modules = shlex.split(match.group(1))
                for module in (ROOT / 'hardware/msi/modules.txt').read_text().split():
                    if module not in modules:
                        modules.append(module)
                text = text[:match.start()] + 'MODULES=(' + ' '.join(modules) + ')' + text[match.end():]
                result[str(init)] = text.encode()
        return result

    def system_files(self):
        files = self.root_files()
        changed = {name: content for name, content in files.items() if not Path(name).exists() or Path(name).read_bytes() != content}
        if not changed:
            return
        for name, content in changed.items():
            old = Path(name).read_text() if Path(name).exists() else ''
            print(''.join(difflib.unified_diff(old.splitlines(True), content.decode().splitlines(True), fromfile=name, tofile=name + ' (selected config)')))
        print('Create a Btrfs snapshot before applying boot, initramfs or hardware changes.')
        if not confirm('Apply these system config changes (with backups)?'):
            raise RuntimeError('System config installation cancelled.')
        if 'btrfs' in self.plan['hardware'] and not Path('/etc/snapper/configs/root').exists():
            print('+ sudo snapper -c root create-config /')
            if not confirm('Initialize Snapper for the existing Btrfs root filesystem?'):
                raise RuntimeError('Snapper initialization cancelled.')
            run(['sudo', 'snapper', '-c', 'root', 'create-config', '/'])
        self.install_root_files(changed)
        run(['sudo', 'systemctl', 'daemon-reload'])
        if any('/udev/' in name for name in changed):
            run(['sudo', 'udevadm', 'control', '--reload'])
        if '/etc/mkinitcpio.conf' in changed or any('/modprobe.d/' in name for name in changed):
            if confirm('Regenerate initramfs now?'):
                run(['sudo', 'mkinitcpio', '-P'])
        if '/etc/default/grub' in changed:
            if confirm('Regenerate /boot/grub/grub.cfg now?'):
                run(['sudo', 'grub-mkconfig', '-o', '/boot/grub/grub.cfg'])

    def install_root_files(self, changed):
        backup = '/var/backups/dotfiles/' + self.backup.name
        if not changed:
            return
        run(['sudo', 'install', '-d', '-m', '0700', backup])
        with tempfile.TemporaryDirectory(prefix='dotfiles-etc-') as temp:
            for i, (name, content) in enumerate(changed.items()):
                if Path(name).exists():
                    destination = backup + name
                    run(['sudo', 'install', '-d', '-m', '0700', str(Path(destination).parent)])
                    run(['sudo', 'cp', '-a', '--', name, destination])
                staging = Path(temp) / str(i)
                staging.write_bytes(content)
                run(['sudo', 'install', '-D', '-o', 'root', '-g', 'root', '-m', '0644', staging, name])

    def repositories(self):
        """Источники личных приложений подключаются только при их выборе."""
        target = Path('/etc/pacman.conf')
        text = original = target.read_text()
        files = {}
        chatgpt = 'chatgpt-bin' in self.plan['user']
        if chatgpt and not re.search(r'^\[openai-chatgpt\]', text, re.M) and 'Include = /etc/pacman.d/openai-chatgpt.conf' not in text:
            files['/etc/pacman.d/openai-chatgpt.conf'] = (ROOT / 'install/repositories/openai.conf').read_bytes()
            text = text.rstrip() + '\n\nInclude = /etc/pacman.d/openai-chatgpt.conf\n'
        if any(p == 'steam' or p.startswith('lib32-') for p in self.plan['user']) and not re.search(r'^\[multilib\]', text, re.M):
            text = text.rstrip() + '\n\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n'
        if text != original:
            files[str(target)] = text.encode()
        if not files and not chatgpt:
            return
        for name, content in files.items():
            old = Path(name).read_text() if Path(name).exists() else ''
            print(''.join(difflib.unified_diff(old.splitlines(True), content.decode().splitlines(True), fromfile=name, tofile=name + ' (selected sources)')))
        if chatgpt:
            print('Import and locally trust OpenAI signing key: 3BFA0E4AE8B8CC16A2D9BA684A3B4A566C4660E4')
            print('+ sudo pacman-key --init; sudo pacman-key --add <bundled OpenAI key>; sudo pacman-key --lsign-key <fingerprint>')
        if not confirm('Apply these package-source changes (with backups)?'):
            raise RuntimeError('Package-source changes cancelled.')
        if chatgpt:
            key = ROOT / 'install/repositories/openai.gpg'
            with tempfile.TemporaryDirectory(prefix='dotfiles-gpg-') as temp:
                result = run(['gpg', '--batch', '--show-keys', '--with-colons', key], capture=True, env=dict(os.environ, GNUPGHOME=temp))
            primary = re.search(r'^pub:.*\n(?:[^\n]*\n)*?fpr:([^\n]*)', result.stdout, re.M)
            fingerprint = primary.group(1).split(':')[8] if primary else ''
            if fingerprint != '3BFA0E4AE8B8CC16A2D9BA684A3B4A566C4660E4':
                raise RuntimeError('Bundled repository signing-key fingerprint mismatch.')
            run(['sudo', 'pacman-key', '--init'])
            run(['sudo', 'pacman-key', '--add', key])
            run(['sudo', 'pacman-key', '--lsign-key', fingerprint])
        self.install_root_files(files)

    def enable_units(self):
        print('Enable system units: ' + ', '.join(self.plan['units_system']))
        print('Enable user units: ' + ', '.join(self.plan['units_user']))
        if not confirm('Enable these units for future boots/logins (do not start them now)?'):
            raise RuntimeError('Unit activation cancelled.')
        run(['systemctl', '--user', 'daemon-reload'])
        for name in self.plan['units_user']:
            if name == 'ec-sync.service' and 'msi-ec-git' in self.package_failures:
                self.deferred.append('ec-sync.service awaits the msi-ec-git package.')
                continue
            run(['systemctl', '--user', 'enable', name])
        for name in self.plan['units_system']:
            run(['sudo', 'systemctl', 'enable', name])

    def defaults(self):
        assets = ROOT / 'wallust/.local/share/dotfiles/defaults'
        walls = self.home / 'Wallpapers'
        for source in sorted((assets / 'wallpapers').iterdir()):
            self.write(walls / source.name, source.read_bytes(), preserve=True)
        current = walls / 'current'
        new = self.write(current, secrets.choice(sorted((assets / 'wallpapers').iterdir())).read_bytes(), preserve=True)
        self.write(self.home / 'Pictures/pfp/current_pfp.jpg', (assets / 'avatar.jpg').read_bytes(), preserve=True)
        if new or not (self.home / '.cache/wallust/hyprland.lua').exists():
            missing = {'wallust', 'matugen-bin'}.intersection(self.package_failures)
            if missing:
                self.deferred.append('Initial wallpaper theme awaits: ' + ', '.join(sorted(missing)))
                print('Theme preparation deferred; continuing the installation.')
                return
            try:
                run([self.config / 'binc/walls', 'index'])
                run([self.config / 'binc/theme', 'apply', '--no-reload'])
            except (OSError, subprocess.CalledProcessError) as error:
                self.deferred.append(f'Initial wallpaper theme: {error}')
                print('Theme preparation deferred; continuing the installation.')

    def first_login(self):
        # hyprpm получает версию работающего Hyprland. Сборка выполняется автоматически
        # после следующего входа в kitty: sudo внутри hyprpm нужен настоящий терминал.
        # Текущую сессию установщик не перезагружает.
        unit = f'''[Unit]\nDescription=Finish dotfiles plugin and editor setup\nAfter=graphical-session.target\nPartOf=graphical-session.target\nConditionPathExists=!%h/.local/state/dotfiles/first-login-complete\n\n[Service]\nType=oneshot\nEnvironment=DOTFILES_FIRST_LOGIN=1\nEnvironment=CMAKE_BUILD_PARALLEL_LEVEL=2 MAKEFLAGS=-j2\nExecStart=/usr/bin/kitty --title "Desktop setup" /usr/bin/python3 "{ROOT}/install/installer.py" --first-login-terminal\nTimeoutStartSec=30min\nNice=10\nCPUWeight=20\nCPUQuota=200%\n\n[Install]\nWantedBy=graphical-session.target\n'''
        self.write(self.config / 'systemd/user/dotfiles-first-login.service', unit.encode())
        self.plan['units_user'].append('dotfiles-first-login.service')

    def ai_tags(self):
        if 'ai-tags' not in self.plan['features']:
            return
        if not confirm('Download Gemma for wallpaper tagging? This can be a large download.'):
            raise RuntimeError('AI tagging selected but model download cancelled; rerun without --features ai-tags.')
        # Свой временный сервер, с приватным каталогом моделей пользователя и без включения сервиса.
        env = dict(os.environ)
        import socket
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        env['OLLAMA_HOST'] = f'127.0.0.1:{port}'
        server = subprocess.Popen(['ollama', 'serve'], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            import time
            import urllib.request
            for _ in range(100):
                if server.poll() is not None:
                    raise RuntimeError('Temporary Ollama server failed to start.')
                try:
                    urllib.request.urlopen(f'http://127.0.0.1:{port}/api/tags', timeout=1).close()
                    break
                except OSError:
                    time.sleep(0.1)
            else:
                raise RuntimeError('Temporary Ollama server did not become ready.')
            run(['ollama', 'pull', catalog()['features']['ai-tags']['model']], env=env)
        finally:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()

    def apply(self, packages_only=False):
        if os.geteuid() == 0:
            raise RuntimeError('Run the installer as your normal user, not root.')
        if not Path('/etc/arch-release').exists():
            raise RuntimeError('Arch Linux is required.')
        if 'btrfs' in self.plan['hardware']:
            filesystem = run(['findmnt', '-n', '-o', 'FSTYPE', '/'], capture=True).stdout.strip()
            if filesystem != 'btrfs':
                raise RuntimeError('The Btrfs snapshot option requires an existing Btrfs root filesystem.')
            if not Path('/boot/grub/grub.cfg').is_file():
                raise RuntimeError('The Btrfs snapshot option requires an already configured GRUB bootloader.')
        self.packages()
        if packages_only:
            return self.installation_report()
        self.projects()
        self.configs()
        self.defaults()
        self.system_files()
        self.first_login()
        self.enable_units()
        self.ai_tags()
        complete = self.installation_report()
        if complete:
            print('Installation files are ready. Reboot to start enabled system services.\nPlugins and editor finish automatically at the next graphical login.')
        print('Existing unselected applications were not removed.')
        return complete


def first_login_terminal():
    # Пароль читает сам sudo с терминала kitty; установщик его не перехватывает.
    print('Desktop setup: plugin compilation may ask for your sudo password.', flush=True)
    try:
        finish_first_login()
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError, KeyboardInterrupt):
        import traceback
        traceback.print_exc()
        input('Desktop setup failed. Copy the error above, then press Enter to close. ')
        raise


def finish_first_login(*, home=None, cache=None):
    if os.environ.get('DOTFILES_FIRST_LOGIN') != '1' or not os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
        raise RuntimeError('First-login setup runs only through its user service in a fresh Hyprland session.')
    home = Path(home or Path.home())
    marker = home / '.local/state/dotfiles/first-login-complete'
    if marker.exists():
        return
    projects = json.loads((ROOT / 'install/projects.json').read_text())['apps']
    cache = Path(cache) if cache is not None else Path('/var/cache/hyprpm') / pwd.getpwuid(os.getuid()).pw_name
    def states():
        return [tomllib.loads(path.read_text()) for path in cache.glob('*/state.toml')]
    # Старые регистрации не удаляем и не переписываем. Проверяем коммит, а не имя ветки:
    # legacy-регистрация 'local' может уже содержать ровно нужную сборку.
    existing = states()
    for item in projects:
        cached = next((s for s in existing if item.get('plugin') in s), None)
        if cached and cached.get('repository', {}).get('hash') != item['rev']:
            raise RuntimeError(f'Existing {item["plugin"]} cache differs from the locked commit. Review the existing hyprpm registration manually.')
    # update обновляет также чужие плагины, поэтому используем его только для пустого кэша.
    # Для старых несовместимых заголовков hyprpm add/reload вернёт ошибку без смены регистраций.
    if not existing:
        run(['hyprpm', 'update'])
    for item in projects:
        if not item.get('plugin'):
            continue
        cached = next((s for s in states() if item['plugin'] in s), None)
        if cached:
            if cached[item['plugin']].get('failed'):
                raise RuntimeError(f'Plugin build failed: {item["plugin"]}')
            if cached.get('repository', {}).get('hash') != item['rev']:
                raise RuntimeError(f'Existing {item["plugin"]} cache differs from the locked revision. Review it manually; no repository was removed.')
        else:
            run(['hyprpm', 'add', home / 'Apps' / item['name'], item['rev']], input='y\n')
            cached = next((s for s in states() if item['plugin'] in s), None)
            if not cached or cached[item['plugin']].get('failed'):
                raise RuntimeError(f'Plugin build failed: {item["plugin"]}')
        run(['hyprpm', 'enable', item['plugin']])
    for helper in ['hymission-search-input', 'hyprcapture-ui']:
        path = home / '.local/bin' / helper
        if not os.access(path, os.X_OK):
            raise RuntimeError(f'Plugin helper is missing: {path}')
    run(['hyprpm', 'reload'])
    run(['hyprctl', 'reload'])
    run(['nvim', '--headless', '+Lazy! restore', '+qa'])
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text('Complete\n')
    run(['notify-send', 'Desktop setup', 'Plugins and editor are ready.'])


def audit():
    data = catalog()
    known = set(data['system']['repo'] + data['system']['aur'] + data['excluded'])
    known.update(x['id'] for x in data['user'])
    for item in list(data['hardware'].values()) + list(data['features'].values()):
        known.update(item.get('repo', []) + item.get('aur', []))
    installed = set(run(['pacman', '-Qqe'], capture=True).stdout.split())
    print('Unclassified explicit packages:\n' + '\n'.join(sorted(installed - known)))
    print('Scope assignments were preserved. Edit packages/scopes.json to classify new requirements.')


def export_lists():
    data = catalog()['system']
    for field, name in [('repo', 'pkglist.txt'), ('aur', 'aurlist.txt'), ('units_system', 'units-system.txt'), ('units_user', 'units-user.txt')]:
        (ROOT / 'packages' / name).write_text('\n'.join(data[field]) + '\n')


def check_configs(packages=None):
    home = Path.home()
    plan = make_plan(hardware=['msi'] if (home / '.config/dotfiles/hardware/msi').exists() else [])
    if packages is not None:
        known = {p.name for p in ROOT.iterdir() if p.is_dir() and not p.name.startswith('.') and p.name not in {'system', 'hardware', 'install', 'docs', 'packages'}}
        if set(packages) - known:
            raise ValueError('Unknown config package: ' + ', '.join(sorted(set(packages) - known)))
        plan['configs'] = packages
    bad = False
    for package in plan['configs']:
        if package == 'hypr':
            # Пустой сабмодуль не попадёт в rglob и иначе даст ложный успех.
            for name in ('init.lua', 'lua/split-monitor-workspaces.lua', 'lua/monitors.lua'):
                if not (ROOT / 'hypr/.config/hypr/plugins' / name).is_file():
                    print(f'MISSING SMW SOURCE: {name}; run: ./dot smw restore')
                    bad = True
        for source in (ROOT / package).rglob('*'):
            relative = source.relative_to(ROOT / package)
            if (not source.is_file() and not source.is_symlink()) or {'.git', '.gitignore'} & set(relative.parts) or re.search(IGNORE, relative.as_posix()):
                continue
            target = home / relative
            if not target.exists() or target.resolve() != source.resolve():
                print(f'MISSING/REPLACED: {target}')
                bad = True
    if bad:
        raise RuntimeError('Some required config links are missing or replaced. Generated/local config files were excluded.')
    print('Required config links are healthy. Generated files, optional configs and full system restoration are separate checks.')


def main(argv=None):
    parser = argparse.ArgumentParser(description='Install the desktop and selected optional applications.')
    parser.add_argument('--plan', action='store_true', help='Print JSON plan without changes; unspecified selections are empty')
    parser.add_argument('--user', help='Comma-separated optional package IDs, or none')
    parser.add_argument('--hardware', help='Comma-separated hardware IDs, or none')
    parser.add_argument('--features', help='Comma-separated feature IDs (ai-tags), or none')
    parser.add_argument('--packages-only', action='store_true')
    parser.add_argument('--audit', action='store_true')
    parser.add_argument('--export', action='store_true', help='Regenerate system lists from the scope catalog')
    parser.add_argument('--check', action='store_true', help='Check required config links, excluding generated/local files')
    parser.add_argument('--stow-ignore', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('--config-packages', help='Comma-separated config packages to check explicitly')
    parser.add_argument('--first-login', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('--first-login-terminal', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    if args.stow_ignore:
        print(IGNORE)
        return
    if args.first_login_terminal:
        first_login_terminal()
        return
    if args.first_login:
        finish_first_login()
        return
    if args.audit:
        audit()
        return
    if args.export:
        export_lists()
        return
    if args.check:
        check_configs(csv_ids(args.config_packages) if args.config_packages is not None else None)
        return
    data = catalog()
    selections = []
    for key, supplied in [('user', args.user), ('hardware', args.hardware), ('features', args.features)]:
        if supplied is not None or args.plan:
            selections.append(csv_ids(supplied or 'none'))
        elif key == 'user':
            selections.append(choose('Optional applications — follow key hints to toggle; Enter accepts; Ctrl+C cancels', [(x['id'], x['group'] + ': ' + x['label']) for x in data['user']], [x['id'] for x in data['user'] if x['default']]))
        else:
            entries = [(name, item['label']) for name, item in data[key].items()]
            if key == 'hardware':
                model = Path('/sys/class/dmi/id/product_name')
                print('Detected model: ' + (model.read_text().strip() if model.exists() else 'unknown'))
                if model.exists():
                    for name, item in data['hardware'].items():
                        if item.get('match', '').lower() in model.read_text().lower() and item.get('match'):
                            print(f'Suggested hardware profile: {name}')
                print('Hardware options require explicit selection; none are preselected.')
            selections.append(choose(key.title(), entries))
    plan = make_plan(*selections)
    if args.plan:
        print(json.dumps(plan, ensure_ascii=False, indent=2))
        return
    print(f'\nRequired packages: {len(data["system"]["repo"]) + len(data["system"]["aur"])}')
    print('Optional applications: ' + (', '.join(plan['user']) or 'none'))
    print('Hardware: ' + (', '.join(plan['hardware']) or 'none'))
    print('Extra features: ' + (', '.join(plan['features']) or 'none'))
    print('Local secrets and current wallpaper are preserved. System changes are reviewed separately.')
    if not confirm('Install this selection? Existing unselected applications will be kept.'):
        return
    if not Installer(plan).apply(args.packages_only):
        sys.exit(2)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(f'Installation stopped: {error}', file=sys.stderr)
        if os.environ.get('DOTFILES_FIRST_LOGIN') == '1' and shutil.which('notify-send'):
            subprocess.run(['notify-send', '-u', 'critical', 'Desktop setup incomplete', str(error)], check=False)
        sys.exit(1)
    except KeyboardInterrupt:
        print('\nCancelled.', file=sys.stderr)
        sys.exit(130)
