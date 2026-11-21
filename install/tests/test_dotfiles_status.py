"""Ручной аудит не запускается при чтении списка; ошибки проверок сохраняются отдельно."""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('dotfiles_status', str(Path(__file__).resolve().parents[2] / 'binc/.config/binc/dotfiles-status'))
spec = importlib.util.spec_from_loader(loader.name, loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)


class StatusTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.patcher = patch.multiple(m, CACHE=self.root / 'cache', REPORT=self.root / 'cache/report.json', ROOT=self.root)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def listing(self):
        stream = io.StringIO()
        with contextlib.redirect_stdout(stream), patch.object(m, 'command', side_effect=AssertionError('list must not audit')):
            m.listing()
        return [json.loads(line) for line in stream.getvalue().splitlines()]

    def test_every_status_row_has_an_icon(self):
        with patch.object(m, 'check', return_value=dict(status='Healthy', text='Details')):
            m.refresh()
        missing = [row['id'] for row in self.listing() if not row.get('icon')]
        self.assertEqual(missing, [])

    def test_first_list_is_read_only(self):
        self.assertEqual([r['id'] for r in self.listing()], ['refresh', 'checked'])
        self.assertFalse(m.CACHE.exists())

    def test_refresh_preserves_individual_unavailable_results(self):
        def result(key):
            return dict(status='Unavailable' if key == 'failed' else 'Healthy', text='Sample ' + key)
        with patch.object(m, 'check', side_effect=result):
            m.refresh()
        before = m.REPORT.read_bytes()
        rows = self.listing()
        self.assertEqual(next(r['status'] for r in rows if r['id'] == 'failed'), 'Unavailable')
        self.assertEqual(m.REPORT.read_bytes(), before)
        self.assertEqual(m.REPORT.stat().st_mode & 0o777, 0o600)

    def test_corrupt_report_offers_refresh(self):
        m.CACHE.mkdir()
        m.REPORT.write_text('{broken')
        self.assertIn('Never', self.listing()[1]['status'])

    def test_package_count_excludes_command_log_and_footer(self):
        text = '+ pacman -Qqe\nUnclassified explicit packages:\none\ntwo\nScope assignments were preserved. Edit packages/scopes.json to classify new requirements.'
        with patch.object(m, 'command', return_value=(0, text)):
            self.assertEqual(m.check('packages')['status'], '2 unclassified')

    def test_system_difference_does_not_expose_config_contents(self):
        config = self.root / 'system/etc/example-config'
        config.parent.mkdir(parents=True)
        config.write_text('private-content')
        result = m.check('system')
        self.assertIn('Missing: /etc/example-config', result['text'])
        self.assertNotIn('private-content', result['text'])

    def test_failed_check_is_unavailable_not_healthy(self):
        with patch.object(m, 'command', return_value=(-1, 'Timed out')):
            self.assertEqual(m.check('failed')['status'], 'Unavailable')


if __name__ == '__main__':
    unittest.main()
