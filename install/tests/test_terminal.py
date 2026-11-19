"""Реальные чекбоксы gum в отдельном PTY, без запуска установки."""
import errno
import json
import os
from pathlib import Path
import select
import shutil
import signal
import struct
import sys
import tempfile
import time
import unittest


@unittest.skipUnless(shutil.which('gum') and sys.platform == 'linux', 'requires gum and a Linux PTY')
class CheckboxTests(unittest.TestCase):
    def check_selection(self, keys, expected):
        import fcntl
        import pty
        import termios
        root = Path(__file__).resolve().parents[2]
        code = f'''import json, runpy
m=runpy.run_path({str(root / 'install/installer.py')!r})
result=m['choose']('Installer checkbox test', [('a','Alpha, with comma'),('b','Beta'),('c','Gamma')], ['a','b'])
print('RESULT='+json.dumps(result))
'''
        with tempfile.TemporaryDirectory(prefix='dotfiles-terminal-') as temp:
            pid, fd = pty.fork()
            if pid == 0:
                os.environ.update(HOME=temp, XDG_CONFIG_HOME=temp+'/.config', TERM='xterm-256color')
                os.execv(sys.executable, [sys.executable, '-c', code])
            fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 30, 140, 0, 0))
            output = b''
            sent = False
            reaped = False
            start = time.monotonic()
            try:
                while time.monotonic() - start < 8:
                    if select.select([fd], [], [], 0.05)[0]:
                        try:
                            chunk = os.read(fd, 65536)
                        except OSError as error:
                            if error.errno == errno.EIO:
                                break
                            raise
                        if not chunk:
                            break
                        output += chunk
                        if b'\x1b[6n' in chunk:
                            os.write(fd, b'\x1b[1;1R')
                        if b'\x1b]11;?' in chunk:
                            os.write(fd, b'\x1b]11;rgb:0000/0000/0000\x1b\\')
                        if b'\x1b]10;?' in chunk:
                            os.write(fd, b'\x1b]10;rgb:ffff/ffff/ffff\x1b\\')
                    if not sent and b'Installer checkbox test' in output and time.monotonic() - start > 0.4:
                        for key in keys:
                            os.write(fd, (b'x' if b'x toggle' in output else b' ') if key == b'<toggle>' else key)
                            time.sleep(0.06)
                        sent = True
                    if b'RESULT=' in output:
                        break
                self.assertIn(b'RESULT=', output, output[-1600:].decode(errors='replace'))
                line = output.split(b'RESULT=',1)[1].splitlines()[0]
                self.assertEqual(json.loads(line), expected, output[-4000:].decode(errors="replace"))
                done, _ = os.waitpid(pid, 0)
                reaped = done == pid
            finally:
                if not reaped:
                    try:
                        os.kill(pid, signal.SIGKILL)
                        os.waitpid(pid, 0)
                    except ProcessLookupError:
                        pass
                os.close(fd)

    def test_preselected_options_including_comma_label(self):
        self.check_selection([b'\r'], ['a', 'b'])

    def test_toggle_and_arrows_change_checkboxes(self):
        self.check_selection([b'<toggle>',b'\x1b[B',b'<toggle>',b'\x1b[B',b'<toggle>',b'\r'], ['c'])


if __name__ == '__main__':
    unittest.main()
