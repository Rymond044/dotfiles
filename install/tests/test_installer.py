"""Проверяем границы установки на временном HOME; системные команды перехватываются."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'install/installer.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class PlanTests(unittest.TestCase):
    def test_base_has_no_optional_or_msi_dependencies(self):
        plan = m.make_plan()
        packages = set(plan['repo'] + plan['aur'])
        self.assertFalse(packages & {'discord', 'telegram-desktop', 'steam', 'chatgpt-bin', 'ollama', 'ollama-vulkan', 'msi-ec-git', 'mcontrolcenter-bin', 'howdy', 'fprintd', 'xpadneo-dkms'})
        self.assertTrue({'chromium', 'kitty', 'nautilus', 'neovim', 'gimp', 'libreoffice-still', 'bookworm', 'papers', 'evince', 'libqalculate', 'libvips', 'python-numpy', 'python-pillow', 'playerctl', 'plasma-workspace'} <= packages)
        self.assertNotIn('docker.service', plan['units_system'])
        self.assertNotIn('ec-sync.service', plan['units_user'])
        self.assertNotIn('nwg-displays', plan['configs'])

    def test_defaults_and_scopes(self):
        data = m.catalog()
        self.assertEqual({x['id'] for x in data['user'] if x['default']}, {'telegram-desktop', 'discord', 'keepassxc', 'qbittorrent'})
        p = m.make_plan(['discord', 'docker', 'ghostty'], ['msi'], ['ai-tags'])
        self.assertIn('ghostty', p['configs'])
        self.assertIn('msi-ec-git', p['aur'])
        self.assertIn('ec-sync.service', p['units_user'])
        self.assertIn('docker.socket', p['units_system'])
        self.assertNotIn('docker.service', p['units_system'])
        self.assertIn('ollama', p['repo'])
        self.assertNotIn('cups', p['repo'])
        self.assertNotIn('fprintd', p['repo'])

    def test_every_selection_resolves_to_valid_configs(self):
        data = m.catalog()
        plan = m.make_plan([x['id'] for x in data['user']], list(data['hardware']), list(data['features']))
        for package in plan['configs']:
            self.assertTrue((ROOT / package).is_dir(), package)
        self.assertEqual(len(plan['repo']), len(set(plan['repo'])))
        self.assertFalse(set(plan['repo']) & set(plan['aur']))
        for item in plan['projects']:
            self.assertRegex(item['rev'], r'^[a-f0-9]{40}$')

    def test_invalid_selection_rejected_before_mutation(self):
        with self.assertRaises(ValueError):
            m.make_plan(['not-a-package'])

    def test_mime_only_selected_apps(self):
        template = (ROOT / 'session/.config/mimeapps.list').read_text()
        basic = m.render_mime(template, set(m.make_plan()['repo']))
        self.assertIn('application/pdf=org.gnome.Papers.desktop', basic)
        self.assertNotIn('qbittorrent', basic)
        self.assertNotIn('keepassxc', basic)
        self.assertNotIn('chatgpt.desktop', basic)
        self.assertNotIn('vesktop.desktop', basic)
        self.assertNotIn('kando.desktop', basic)
        selected = m.render_mime(template, {'discord', 'qbittorrent', 'chatgpt-bin'})
        self.assertIn('x-scheme-handler/discord=discord.desktop', selected)
        self.assertIn('x-scheme-handler/magnet=org.qbittorrent.qBittorrent.desktop', selected)
        self.assertIn('x-scheme-handler/codex=chatgpt.desktop', selected)

    def test_existing_valid_unselected_associations_survive(self):
        old = '[Default Applications]\nx-scheme-handler/custom=custom.desktop\nx-scheme-handler/stale=missing.desktop\n'
        merged = m.merge_mime(old, '[Default Applications]\napplication/pdf=org.gnome.Papers.desktop\n', {'custom.desktop'})
        self.assertIn('custom.desktop', merged)
        self.assertNotIn('missing.desktop', merged)

    def test_grub_merge_preserves_encryption_and_is_idempotent(self):
        original = 'GRUB_TIMEOUT=5\nGRUB_CMDLINE_LINUX_DEFAULT="quiet cryptdevice=UUID=abc:root root=/dev/mapper/root xe.enable_psr=0"\n'
        additions = ['xe.enable_psr=1', 'nvme_core.default_ps_max_latency_us=0']
        merged = m.merge_grub(original, additions)
        self.assertIn('cryptdevice=UUID=abc:root', merged)
        self.assertIn('root=/dev/mapper/root', merged)
        self.assertIn('GRUB_TIMEOUT=5', merged)
        self.assertNotIn('xe.enable_psr=0', merged)
        self.assertEqual(merged, m.merge_grub(merged, additions))

    def test_dynamic_grub_assignments_are_not_rewritten(self):
        with self.assertRaisesRegex(RuntimeError, 'shell expansion'):
            m.merge_grub('GRUB_CMDLINE_LINUX_DEFAULT="$CUSTOM_ARGS quiet"\n', ['xe.enable_psr=1'])

    def test_plan_cli_performs_no_commands(self):
        with patch.object(m, 'run', side_effect=AssertionError('unexpected command')):
            with contextlib.redirect_stdout(io.StringIO()) as output:
                m.main(['--plan', '--user', 'none', '--hardware', 'none', '--features', 'none'])
            self.assertEqual(json.loads(output.getvalue())['user'], [])

    def test_exported_lists_match_catalog(self):
        d = m.catalog()['system']
        for field, name in [('repo', 'pkglist.txt'), ('aur', 'aurlist.txt'), ('units_system', 'units-system.txt'), ('units_user', 'units-user.txt')]:
            self.assertEqual((ROOT / 'packages' / name).read_text().split(), d[field])


class HomeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-install-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.installer = m.Installer(m.make_plan(), home=self.home)

    def test_secrets_are_private_and_existing_values_are_preserved(self):
        target = self.home / '.config/dotfiles/.env'
        self.installer.write(target, b'TOKEN=first\n', mode=0o600, preserve=True)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        self.installer.write(target, b'TOKEN=second\n', mode=0o600, preserve=True)
        self.assertEqual(target.read_bytes(), b'TOKEN=first\n')

    def test_replacing_symlink_never_overwrites_source(self):
        source = self.home / 'source'
        source.write_text('original')
        target = self.home / 'target'
        target.symlink_to(source)
        self.installer.write(target, b'new')
        self.assertEqual(source.read_text(), 'original')
        self.assertFalse(target.is_symlink())
        self.assertTrue((self.installer.backup / 'target.symlink').is_symlink())

    def test_local_writes_unfold_stow_parents_without_editing_repo(self):
        fake_repo = self.home / 'repo'
        source = fake_repo / 'session/.config'
        source.mkdir(parents=True)
        (source / 'existing').write_text('source stays intact')
        (self.home / '.config').symlink_to(source)
        with patch.object(m, 'ROOT', fake_repo):
            self.installer.write(self.home / '.config/new-local-file', b'local')
            self.installer.write(self.home / '.config/existing', b'local replacement')
        self.assertFalse((self.home / '.config').is_symlink())
        self.assertFalse((self.home / '.config/existing').is_symlink())
        self.assertEqual((source / 'existing').read_text(), 'source stays intact')
        self.assertFalse((source / 'new-local-file').exists())

    def test_defaults_include_five_unique_images_and_preserve_current(self):
        with patch.object(m, 'run') as commands:
            self.installer.defaults()
            self.assertEqual(commands.call_count, 2)
        files = list((self.home / 'Wallpapers').glob('*.jpg'))
        self.assertEqual(len(files), 5)
        hashes = {hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
        self.assertEqual(len(hashes), 5)
        current = self.home / 'Wallpapers/current'
        self.assertIn(hashlib.sha256(current.read_bytes()).hexdigest(), hashes)
        current.write_bytes(b'existing wallpaper')
        avatar = self.home / 'Pictures/pfp/current_pfp.jpg'
        avatar.write_bytes(b'existing avatar')
        cache = self.home / '.cache/wallust/hyprland.lua'
        cache.parent.mkdir(parents=True)
        cache.write_text('existing theme')
        with patch.object(m, 'run') as commands:
            self.installer.defaults()
            commands.assert_not_called()
        self.assertEqual(current.read_bytes(), b'existing wallpaper')
        self.assertEqual(avatar.read_bytes(), b'existing avatar')

    def test_stow_integration_excludes_optional_and_machine_configs(self):
        real_run = subprocess.run
        def controlled(args, **kwargs):
            if str(args[0]) == 'stow':
                result = real_run(list(map(str,args)), text=True, capture_output=True)
                if result.returncode:
                    raise RuntimeError(result.stderr)
                return result
            return subprocess.CompletedProcess(args, 0, stdout='')
        env = {'HOME': str(self.home), 'XDG_CONFIG_HOME': str(self.home / '.config'), 'XDG_CACHE_HOME': str(self.home / '.cache')}
        with patch.dict(os.environ, env), patch.object(m, 'run', side_effect=controlled), patch.object(m, 'confirm', return_value=True):
            self.installer.configs()
            # Повторный запуск тоже должен пройти без конфликтов и потери данных.
            self.installer.configs()
        self.assertTrue((self.home / '.zshrc').is_symlink())
        self.assertTrue((self.home / '.config/kitty/kitty.conf').is_symlink())
        self.assertFalse((self.home / '.config/ghostty').exists())
        self.assertFalse((self.home / '.config/yazi').exists())
        self.assertFalse((self.home / '.config/MControlCenter.conf').exists())
        self.assertFalse((self.home / '.config/systemd/user/ec-sync.service').exists())
        self.assertFalse((self.home / '.config/electron-flags.conf').exists())
        self.assertNotIn('--ignore-gpu-blocklist', (self.home / '.config/chromium-flags.conf').read_text())
        self.assertNotIn('eDP-1', (self.home / '.config/hypr/monitors.lua').read_text())
        self.assertNotIn('xe.force_probe', (self.home / '.config/uwsm/env').read_text())
        self.assertEqual((self.home / '.config/dotfiles/.env').stat().st_mode & 0o777, 0o600)
        self.assertFalse((self.home / '.local/state/dotfiles').exists())

    def test_upgrade_from_folded_stow_keeps_generated_files_out_of_repo(self):
        repo = self.home / 'repo'
        repo.mkdir()
        shutil.copytree(ROOT / 'session', repo / 'session', symlinks=True)
        shutil.copytree(ROOT / 'install/templates', repo / 'install/templates')
        before = (repo / 'session/.config/mimeapps.list').read_bytes()
        real_run = subprocess.run
        real_run(['stow', '-d', str(repo), '-t', str(self.home), 'session'], check=True, capture_output=True)
        self.assertTrue((self.home / '.config').is_symlink())
        def controlled(args, **kwargs):
            if str(args[0]) == 'stow':
                return real_run(list(map(str,args)), check=True, capture_output=True, text=True)
            return subprocess.CompletedProcess(args, 0, stdout='')
        plan = m.make_plan()
        plan['configs'] = ['session']
        with patch.object(m, 'ROOT', repo), patch.object(m, 'run', side_effect=controlled), patch.object(m, 'confirm', return_value=True):
            installed = m.Installer(plan, home=self.home)
            installed.configs()
            installed.write(self.home / '.config/systemd/user/generated.service', b'[Unit]\n')
        self.assertEqual((repo / 'session/.config/mimeapps.list').read_bytes(), before)
        self.assertFalse((repo / 'session/.config/dotfiles/.env').exists())
        self.assertFalse((repo / 'session/.config/systemd/user/generated.service').exists())

    def test_plugin_setup_is_queued_not_started(self):
        with patch.object(m, 'run') as commands:
            self.installer.first_login()
            commands.assert_not_called()
        unit = (self.home / '.config/systemd/user/dotfiles-first-login.service').read_text()
        self.assertIn('ConditionPathExists=!', unit)
        self.assertIn('--first-login', unit)
        self.assertIn('dotfiles-first-login.service', self.installer.plan['units_user'])


class FirstLoginTests(unittest.TestCase):
    def exercise(self, legacy=False, failed=False):
        with tempfile.TemporaryDirectory(prefix='dotfiles-first-login-test-') as temp:
            home = Path(temp)
            cache = home / 'cache'
            cache.mkdir()
            projects = [p for p in json.loads((ROOT/'install/projects.json').read_text())['apps'] if p.get('plugin')]
            def state(item, bad=False):
                folder = cache/item['name']
                folder.mkdir(exist_ok=True)
                rev = 'local' if legacy else item['rev']
                (folder/'state.toml').write_text(f'[{item["plugin"]}]\nfailed = {str(bad).lower()}\n[repository]\nhash = "{item["rev"]}"\nrev = "{rev}"\n')
            for name in ['hymission-search-input','hyprcapture-ui']:
                file = home/'.local/bin'/name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text('#!/bin/sh\nexit 0\n')
                file.chmod(0o755)
            if legacy or failed:
                for i, item in enumerate(projects):
                    state(item, bad=failed and i==0)
            commands = []
            def controlled(args, **kwargs):
                args = list(map(str,args))
                commands.append(args)
                if args[:2] == ['hyprpm','add']:
                    state(next(p for p in projects if p['name']==Path(args[2]).name))
                return subprocess.CompletedProcess(args,0,stdout='')
            env = {'DOTFILES_FIRST_LOGIN':'1','HYPRLAND_INSTANCE_SIGNATURE':'isolated-test'}
            with patch.dict(os.environ,env), patch.object(m,'run',side_effect=controlled):
                if failed:
                    with self.assertRaisesRegex(RuntimeError,'Plugin build failed'):
                        m.finish_first_login(home=home,cache=cache)
                else:
                    m.finish_first_login(home=home,cache=cache)
            marker = home/'.local/state/dotfiles/first-login-complete'
            self.assertEqual(marker.exists(),not failed)
            if failed:
                self.assertNotIn(['hyprctl','reload'],commands)
            elif legacy:
                self.assertNotIn(['hyprpm','update'],commands)
                self.assertFalse(any(c[:2]==['hyprpm','add'] for c in commands))
            else:
                self.assertIn(['hyprpm','update'],commands)
                self.assertEqual(sum(c[:2]==['hyprpm','add'] for c in commands),3)
                self.assertIn(['hyprctl','reload'],commands)

    def test_fresh_first_login_marks_complete_only_after_plugins_and_helpers(self):
        self.exercise()

    def test_matching_legacy_cache_does_not_trigger_updates(self):
        self.exercise(legacy=True)

    def test_failed_plugin_does_not_mark_setup_complete(self):
        self.exercise(failed=True)


class TaggingTests(unittest.TestCase):
    def test_actual_tag_command_without_ollama_keeps_gallery_data(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-tag-command-') as temp:
            home = Path(temp)
            cache = home / '.cache/walls'
            cache.mkdir(parents=True)
            (home / 'run').mkdir()
            binary = home / 'bin'
            binary.mkdir()
            notification = binary / 'notify-send'
            notification.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/notification"\n')
            notification.chmod(0o755)
            auto = dict(w=10, h=10, palette=[], hues=[], tone='dark', lightness=20, rainbow=False, attention_x=0.5)
            index = dict(version=1, files={'test.jpg': {'hash':'sample'}}, items={'sample':auto})
            (cache / 'index.json').write_text(json.dumps(index))
            env = dict(os.environ, HOME=temp, XDG_CACHE_HOME=temp+'/.cache', XDG_RUNTIME_DIR=temp+'/run', OLLAMA_HOST='http://127.0.0.1:1', PATH=str(binary))
            result = subprocess.run([sys.executable, ROOT / 'binc/.config/binc/walls', 'tag'], env=env, text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('AI tagging is not installed', (home / 'notification').read_text())
            view = json.loads((cache / 'view.json').read_text())
            self.assertIsNone(view['tagging'])
            self.assertEqual(view['items'][0]['file'], 'test.jpg')
            self.assertFalse((home / 'run/walls-tag.json').exists())

    def test_missing_ollama_fails_cleanly_without_starting_process(self):
        from importlib.machinery import SourceFileLoader
        with tempfile.TemporaryDirectory(prefix='dotfiles-tag-test-') as temp, patch.dict(os.environ, {'HOME':temp,'XDG_CACHE_HOME':temp+'/cache'}):
            loader = SourceFileLoader('walls_test', str(ROOT / 'binc/.config/binc/walls'))
            spec = importlib.util.spec_from_loader(loader.name, loader)
            walls = importlib.util.module_from_spec(spec)
            loader.exec_module(walls)
            with patch.object(walls, 'ollama', side_effect=OSError('no server')), patch.object(walls.shutil, 'which', return_value=None), patch.object(walls.subprocess, 'Popen') as spawn:
                with self.assertRaisesRegex(RuntimeError, 'AI tagging is not installed'):
                    walls.ensure_ollama()
                spawn.assert_not_called()


if __name__ == '__main__':
    unittest.main()
