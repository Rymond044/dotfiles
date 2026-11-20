"""Проверки обновления на настоящих временных Git-репозиториях без живого Hyprland."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('smw', Path(__file__).resolve().parents[1] / 'smw.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


@unittest.skipUnless(shutil.which('git') and shutil.which('luac'), 'git and luac required')
class SMWTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'dotfiles'
        self.upstream = self.base / 'upstream'
        self.environment = patch.dict(os.environ, {
            'GIT_AUTHOR_NAME': 'Test', 'GIT_AUTHOR_EMAIL': 'test@example.invalid',
            'GIT_COMMITTER_NAME': 'Test', 'GIT_COMMITTER_EMAIL': 'test@example.invalid',
            'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': '/dev/null',
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)
        for path in (self.root, self.upstream):
            path.mkdir()
            self.git(path, 'init', '-b', 'main')
        (self.upstream / 'init.lua').write_text('return {}\n')
        self.commit(self.upstream, 'initial Lua')
        self.git(self.root, '-c', 'protocol.file.allow=always', 'submodule', 'add',
                 str(self.upstream), m.SUBMODULE)
        self.commit(self.root, 'record SMW')
        self.home = self.base / 'home'
        self.home.mkdir()
        self.smw = m.SMW(self.root, home=self.home)
        self.original = self.smw.recorded()
        self.git(self.upstream, 'checkout', '-b', 'release/0.57.x')
        (self.upstream / 'init.lua').write_text('return { updated = true }\n')
        self.commit(self.upstream, 'release update')
        self.candidate = self.git(self.upstream, 'rev-parse', 'HEAD')

    def git(self, path, *args):
        return m.git(path, *args)

    def commit(self, path, message):
        self.git(path, 'add', '.')
        self.git(path, 'commit', '-m', message)

    def update(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()):
            self.smw.update('0.57.2', **kwargs)

    def test_preview_then_update_then_restore_keeps_recorded_version(self):
        self.update(check=True)
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)
        self.update()
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.candidate)
        self.assertEqual(self.smw.recorded(), self.original)
        with contextlib.redirect_stdout(io.StringIO()):
            self.smw.restore()
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_dirty_and_untracked_files_survive_update_and_restore(self):
        for name in ('init.lua', 'personal.lua'):
            with self.subTest(name=name):
                file = self.smw.path / name
                file.write_text('-- personal changes\n')
                for action in (lambda: self.update(), self.smw.restore):
                    with self.assertRaisesRegex(RuntimeError, 'local changes'):
                        action()
                self.assertEqual(file.read_text(), '-- personal changes\n')
                if name == 'init.lua':
                    self.git(self.smw.path, 'restore', name)
                else:
                    file.unlink()

    def test_missing_release_does_not_fall_back_to_main(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.smw.update('0.99.1')
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_invalid_lua_rejected_before_checkout(self):
        (self.upstream / 'init.lua').write_text('local = invalid')
        self.commit(self.upstream, 'broken Lua')
        with self.assertRaises(subprocess.CalledProcessError):
            self.update()
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_missing_lua_package_rejected(self):
        (self.upstream / 'init.lua').unlink()
        self.commit(self.upstream, 'remove Lua')
        with self.assertRaisesRegex(RuntimeError, 'Lua package'):
            self.update()

    def test_unrecorded_checkout_is_preserved(self):
        self.update()
        with self.assertRaisesRegex(RuntimeError, 'differs from the recorded'):
            self.update()
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.candidate)

    def test_divergent_release_is_preserved(self):
        self.git(self.upstream, 'checkout', '--orphan', 'unrelated')
        (self.upstream / 'init.lua').write_text('return { unrelated = true }')
        self.commit(self.upstream, 'unrelated history')
        self.git(self.upstream, 'branch', '-f', 'release/0.57.x', 'HEAD')
        with self.assertRaises(subprocess.CalledProcessError):
            self.update()
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_restore_in_fresh_clone_uses_recorded_commit(self):
        clone = self.base / 'fresh'
        self.git(self.base, 'clone', str(self.root), str(clone))
        smw = m.SMW(clone, home=self.home)
        self.assertFalse(smw.initialized())
        # Разрешение file:// только для этого локального теста.
        with patch.dict(os.environ, {'GIT_ALLOW_PROTOCOL': 'file'}), contextlib.redirect_stdout(io.StringIO()):
            smw.restore()
        self.assertEqual(self.git(smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_detects_installed_hyprland(self):
        binary = self.base / 'bin'
        binary.mkdir()
        executable = binary / 'Hyprland'
        executable.write_text('#!/bin/sh\nprintf "Hyprland 0.57.2 built from branch v0.57.2\\n"\n')
        executable.chmod(0o755)
        with patch.dict(os.environ, {'PATH': str(binary) + os.pathsep + os.environ['PATH']}):
            with contextlib.redirect_stdout(io.StringIO()):
                self.smw.update(check=True)
        self.assertEqual(self.git(self.smw.path, 'rev-parse', 'HEAD'), self.original)

    def test_restore_repairs_missing_links_without_touching_monitor_settings(self):
        lua = self.upstream / 'lua'
        lua.mkdir()
        (lua / 'monitors.lua').write_text('return {}\n')
        self.commit(self.upstream, 'add monitors module')
        self.update()
        self.git(self.root, 'add', m.SUBMODULE)
        target = self.home / '.config/hypr'
        target.mkdir(parents=True, exist_ok=True)
        for name in ('monitors.lua', 'monitors.conf'):
            (target / name).write_text('personal monitor settings\n')
        link = target / 'plugins/lua/monitors.lua'
        self.assertTrue(link.is_file())
        link.unlink()
        with contextlib.redirect_stdout(io.StringIO()):
            self.smw.restore()
            self.smw.restore()
        self.assertEqual(link.resolve(), self.smw.path / 'lua/monitors.lua')
        for name in ('monitors.lua', 'monitors.conf'):
            self.assertEqual((target / name).read_text(), 'personal monitor settings\n')

    def test_preview_does_not_create_links(self):
        self.update(check=True)
        self.assertFalse((self.home / '.config').exists())

    def test_restore_preserves_conflicting_local_module(self):
        target = self.home / '.config/hypr/plugins/init.lua'
        target.parent.mkdir(parents=True)
        target.write_text('personal module\n')
        with self.assertRaisesRegex(RuntimeError, 'conflict'):
            self.smw.restore()
        self.assertEqual(target.read_text(), 'personal module\n')

    def test_restore_preserves_foreign_broken_symlink(self):
        target = self.home / '.config/hypr/plugins/init.lua'
        target.parent.mkdir(parents=True)
        target.symlink_to(self.home / 'missing-personal-module.lua')
        with self.assertRaisesRegex(RuntimeError, 'conflict'):
            self.smw.restore()
        self.assertEqual(os.readlink(target), str(self.home / 'missing-personal-module.lua'))

    def test_status_reports_missing_links_without_creating_them(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.smw.status()
        self.assertIn('Missing SMW links', output.getvalue())
        self.assertFalse((self.home / '.config').exists())

    def test_already_current_update_repairs_missing_link(self):
        self.update()
        self.git(self.root, 'add', m.SUBMODULE)
        target = self.home / '.config/hypr/plugins/init.lua'
        target.unlink()
        self.update()
        self.assertEqual(target.resolve(), self.smw.path / 'init.lua')


if __name__ == '__main__':
    unittest.main()
