#!/usr/bin/env python3
"""Управление Lua SMW без сборки и перезагрузки живой сессии."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SUBMODULE = 'hypr/.config/hypr/plugins'


def git(directory, *args):
    return subprocess.run(['git', '-C', str(directory), *args], check=True,
                          text=True, capture_output=True).stdout.strip()


class SMW:
    def __init__(self, root=ROOT, home=None):
        self.root = Path(root)
        self.path = self.root / SUBMODULE
        self.home = Path(home) if home is not None else Path.home()

    def links(self, repair=False):
        """Подключаем файлы пакета отдельно от локальных настроек экранов."""
        if not self.initialized() or not (self.path / 'init.lua').is_file():
            raise RuntimeError('SMW Lua package is missing. Run: dot smw restore')
        missing = []
        conflicts = []
        for name in git(self.path, 'ls-files', '--', '*.lua').splitlines():
            source = self.path / name
            target = self.home / '.config/hypr/plugins' / name
            if not source.is_file():
                raise RuntimeError(f'SMW source is missing: {source}')
            if target.is_file() and target.resolve() == source.resolve():
                continue
            if target.exists() or target.is_symlink():
                conflicts.append(str(target))
            else:
                missing.append((source, target))
        # Проверяем все конфликты до создания ссылок; чужие файлы не перезаписываем.
        if conflicts:
            raise RuntimeError('SMW link conflicts; local files preserved:\n' + '\n'.join(conflicts))
        if repair:
            for source, target in missing:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.symlink_to(source)
            print(f'SMW links ready ({len(missing)} added).')
        elif missing:
            print('Missing SMW links; run: dot smw restore\n' + '\n'.join(str(t) for _, t in missing))
        else:
            print('SMW links are healthy.')

    def recorded(self):
        entries = git(self.root, 'ls-files', '--stage', '--', SUBMODULE).splitlines()
        if len(entries) != 1 or not entries[0].startswith('160000 '):
            raise RuntimeError('SMW must be a registered, conflict-free submodule.')
        mode, commit, stage = entries[0].split('\t')[0].split()
        if stage != '0':
            raise RuntimeError('Resolve the SMW submodule conflict first.')
        return commit

    def initialized(self):
        # Без .git git -C может незаметно обратиться к родительскому репозиторию.
        return (self.path / '.git').exists()

    def clean(self):
        if git(self.path, 'status', '--porcelain', '--untracked-files=all'):
            raise RuntimeError('SMW has local changes. Save them before continuing.')

    def status(self):
        recorded = self.recorded()
        print(f'Recorded: {recorded}')
        if not self.initialized():
            print('SMW is not initialized. Run: dot smw restore')
            return
        current = git(self.path, 'rev-parse', 'HEAD')
        print(f'Checkout: {current}')
        print(git(self.path, 'log', '-1', '--format=%cs %s'))
        print('Matches recorded version.' if current == recorded else
              'Checkout differs. Review and commit the submodule, or run: dot smw restore')
        if git(self.path, 'status', '--porcelain', '--untracked-files=all'):
            print('Local changes are present.')
        self.links()

    def restore(self):
        self.recorded()
        if self.initialized():
            self.clean()
        elif self.path.exists() and any(self.path.iterdir()):
            raise RuntimeError('SMW directory is not empty and is not an initialized submodule.')
        subprocess.run(['git', '-C', str(self.root), 'submodule', 'update', '--init',
                        '--checkout', '--', SUBMODULE], check=True)
        self.links(repair=True)
        self.status()
        print('Hyprland was not reloaded.')

    def update(self, version=None, check=False):
        recorded = self.recorded()
        if not self.initialized():
            raise RuntimeError('Initialize SMW first: dot smw restore')
        self.clean()
        current = git(self.path, 'rev-parse', 'HEAD')
        if current != recorded:
            raise RuntimeError('SMW differs from the recorded version. Commit it or run: dot smw restore')
        if version is None:
            version = subprocess.run(['Hyprland', '--version'], check=True,
                                     capture_output=True, text=True).stdout
            match = re.search(r'Hyprland\s+(\d+\.\d+\.\d+)\b', version)
        else:
            match = re.fullmatch(r'v?(\d+\.\d+\.\d+)', version)
        if not match:
            raise RuntimeError('Cannot detect a release. Use --hyprland VERSION, for example 0.57.2.')
        release = match[1]
        branch = 'release/' + '.'.join(release.split('.')[:2]) + '.x'
        if shutil.which('luac') is None:
            raise RuntimeError('Lua syntax checker is missing. Install the lua package first.')
        print(f'Hyprland target: {release}; SMW branch: {branch}', flush=True)
        # Явный ref: нет подходящей ветки — ошибка, а не переход на main.
        git(self.path, 'fetch', '--no-tags', 'origin', f'refs/heads/{branch}')
        candidate = git(self.path, 'rev-parse', 'FETCH_HEAD^{commit}')
        subprocess.run(['git', '-C', str(self.path), 'merge-base', '--is-ancestor',
                        current, candidate], check=True, capture_output=True)
        files = git(self.path, 'ls-tree', '-r', '--name-only', candidate).splitlines()
        if 'init.lua' not in files:
            raise RuntimeError('The selected release does not contain the Lua package.')
        lua_files = [name for name in files if name.endswith('.lua')]
        for name in lua_files:
            source = git(self.path, 'show', f'{candidate}:{name}')
            subprocess.run(['luac', '-p', '-'], input=source, check=True,
                           capture_output=True, text=True)
        print(f'Lua syntax OK ({len(lua_files)} files).')
        print(f'Current: {current}\nCandidate: {candidate}')
        if current == candidate:
            if not check:
                self.links(repair=True)
            print('Already up to date.')
            return
        print(git(self.path, 'log', '--oneline', f'{current}..{candidate}'))
        if check:
            print('Preview only; Lua files and the dotfiles index are unchanged.')
            return
        # Повторная проверка после сети и валидации; checkout без --force сохраняет правки.
        self.clean()
        if git(self.path, 'rev-parse', 'HEAD') != current or self.recorded() != recorded:
            raise RuntimeError('SMW changed during the update. Retry after reviewing it.')
        git(self.path, 'checkout', '--detach', candidate)
        self.links(repair=True)
        print('SMW updated. Hyprland was not reloaded.')
        print('Review: git diff --submodule=log -- ' + SUBMODULE)
        print('After testing, commit the submodule in dotfiles to record this version.')
        print('Before committing, undo with: dot smw restore')


def main(argv=None):
    parser = argparse.ArgumentParser(description='Manage split-monitor-workspaces for Hyprland.')
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('status', help='Show checkout and recorded version (offline).')
    commands.add_parser('restore', help='Restore the version recorded in the dotfiles index.')
    update = commands.add_parser('update', help='Update from the matching Hyprland release branch.')
    update.add_argument('--check', action='store_true', help='Fetch and validate without changing Lua files.')
    update.add_argument('--hyprland', metavar='VERSION', help='Override the installed Hyprland target version.')
    args = parser.parse_args(argv)
    try:
        smw = SMW()
        if args.command == 'update':
            smw.update(args.hyprland, args.check)
        else:
            getattr(smw, args.command)()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        detail = error.stderr.strip() if isinstance(error, subprocess.CalledProcessError) and error.stderr else str(error)
        print(f'SMW: {detail}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
