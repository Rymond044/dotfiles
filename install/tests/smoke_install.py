#!/usr/bin/env python3
"""Полный файловый проход в bwrap. Pacman/git/systemd заменены, остальная ФС read-only."""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = r'''#!/usr/bin/python3
import json, os
from pathlib import Path
import shutil, subprocess, sys
name=Path(sys.argv[0]).name
args=sys.argv[1:]
with open('/tmp/commands.jsonl','a') as log: log.write(json.dumps([name]+args)+'\n')
db=Path('/tmp/package-db.json')
installed=set(json.loads(db.read_text())) if db.exists() else set()
def install_packages(arguments):
    installed.update(a for a in arguments if not a.startswith('-'))
    db.write_text(json.dumps(sorted(installed)))
if name=='pacman':
    if args[0]=='-Qq': sys.exit(0 if args[-1] in installed else 1)
    if args[0]=='-Si':
        native=json.loads(Path('/mnt/packages/scopes.json').read_text())['system']['repo']
        sys.exit(0 if args[-1] in native else 1)
    raise SystemExit('Unexpected pacman query')
if name=='yay' and args[0]=='-S':
    if args[-1]==os.environ.get('DOTFILES_FAIL_AUR'): sys.exit(1)
    install_packages(args[1:]);sys.exit(0)
if name == 'sudo':
    command=args.pop(0)
    if command=='pacman':
        install_packages(args[1:]);sys.exit(0)
    if command == 'install':
        clean=[]
        while args:
            arg=args.pop(0)
            if arg in ('-o','-g'): args.pop(0)
            else: clean.append(arg)
        sys.exit(subprocess.call(['/usr/bin/install']+clean))
    if command == 'cp': sys.exit(subprocess.call(['/usr/bin/cp']+args))
    if command not in ('pacman','pacman-key','systemctl','udevadm','mkinitcpio','grub-mkconfig','snapper'):
        raise SystemExit('Unexpected root command: '+command)
    sys.exit(0)
if name == 'git':
    if args[0] == 'clone':
        dest=Path(args[-1]); dest.mkdir(parents=True); (dest/'.git').mkdir()
        if 'linux-battery-monitor' in args[-2]: shutil.copytree('/tmp/battery',dest/'data')
    elif args[0] == '-C' and args[2] == 'checkout': (Path(args[1])/'REV').write_text(args[-1])
    elif args[0] == '-C' and args[2:4] == ['rev-parse','HEAD']: print((Path(args[1])/'REV').read_text())
    sys.exit(0)
if name in ('yay','systemctl','chsh'): sys.exit(0)
raise SystemExit('Unknown test command: '+name)
'''


def drive(args, expected=0):
    master, slave=pty.openpty()
    fcntl.ioctl(slave,termios.TIOCSWINSZ,struct.pack('HHHH',32,160,0,0))
    proc=subprocess.Popen(args,stdin=slave,stdout=slave,stderr=slave,start_new_session=True)
    os.close(slave)
    output=b''; replied=0; deadline=time.monotonic()+100
    try:
        while proc.poll() is None and time.monotonic()<deadline:
            if select.select([master],[],[],0.1)[0]:
                try: chunk=os.read(master,65536)
                except OSError: break
                output+=chunk
                count=output.count(b'[y/N] ')
                while replied<count:
                    os.write(master,b'y\n'); replied+=1
        if proc.poll() is None:
            proc.wait(timeout=3)
        if proc.returncode != expected:
            raise AssertionError(output.decode(errors='replace')[-7000:])
        return output
    finally:
        if proc.poll() is None:
            os.killpg(proc.pid,signal.SIGKILL);proc.wait()
        os.close(master)


def scenario(name, users, hardware, failed_package=None):
    with tempfile.TemporaryDirectory(prefix='dotfiles-full-smoke-') as temp:
        temp = Path(temp)
        for path in ['bin','home','run','etc/default','etc/systemd/system','var-backups','battery','boot']:
            (temp/path).mkdir(parents=True, exist_ok=True)
        (temp/'run').chmod(0o700)
        uid, gid = os.getuid(), os.getgid()
        (temp/'etc/passwd').write_text(f'tester:x:{uid}:{gid}:Test:/tmp/home:/usr/bin/zsh\n')
        (temp/'etc/group').write_text(f'tester:x:{gid}:\nroot:x:0:\n')
        (temp/'etc/nsswitch.conf').write_text('passwd: files\ngroup: files\n')
        (temp/'etc/arch-release').touch()
        (temp/'etc/xdg').mkdir()
        for filename in ['user-dirs.defaults','user-dirs.conf']:
            if Path('/etc/xdg',filename).exists():
                shutil.copyfile(Path('/etc/xdg',filename),temp/'etc/xdg'/filename)
        (temp/'etc/pacman.conf').write_text('[options]\n[core]\nInclude = /etc/pacman.d/mirrorlist\n[extra]\nInclude = /etc/pacman.d/mirrorlist\n')
        (temp/'etc/default/grub').write_text('GRUB_TIMEOUT=5\nGRUB_CMDLINE_LINUX_DEFAULT="quiet cryptdevice=UUID=test:root root=/dev/mapper/root"\n')
        (temp/'etc/mkinitcpio.conf').write_text('MODULES=()\nHOOKS=(base systemd autodetect modconf block sd-encrypt filesystems)\n')
        # Только публичные data-шаблоны приложения; личные данные не копируются.
        source = ROOT / 'install/tests/fixtures/battery'
        for filename in ['battery-monitor.service','io.github.rymond044.BatteryMonitor.desktop','io.github.rymond044.BatteryMonitor.svg']:
            shutil.copyfile(source/filename, temp/'battery'/filename)
        for command in ['sudo','git','yay','pacman','systemctl','chsh']:
            path=temp/'bin'/command; path.write_text(WRAPPER); path.chmod(0o755)
        affinity=','.join(str(x) for x in sorted(os.sched_getaffinity(0))[:2])
        args=['nice','-n','10','taskset','-c',affinity,'bwrap','--die-with-parent','--new-session','--unshare-all',
              '--ro-bind','/','/','--ro-bind',str(ROOT),'/mnt','--tmpfs','/home','--dev','/dev','--proc','/proc',
              '--tmpfs','/run','--tmpfs','/var','--dir','/var/backups','--bind',str(temp),'/tmp','--bind',str(temp/'etc'),'/etc',
              '--bind',str(temp/'var-backups'),'/var/backups','--bind',str(temp/'boot'),'/boot',
              '--clearenv','--setenv','PATH','/tmp/bin:/usr/bin:/bin','--setenv','HOME','/tmp/home',
              '--setenv','XDG_CONFIG_HOME','/tmp/home/.config','--setenv','XDG_CACHE_HOME','/tmp/home/.cache',
              '--setenv','XDG_STATE_HOME','/tmp/home/.local/state','--setenv','XDG_RUNTIME_DIR','/tmp/run',
              '--setenv','DBUS_SESSION_BUS_ADDRESS','unix:path=/tmp/no-session-bus',
              '--setenv','OPENBLAS_NUM_THREADS','1','--setenv','OMP_NUM_THREADS','1',
              '--setenv','VIPS_CONCURRENCY','1','--setenv','RAYON_NUM_THREADS','2',
              '--setenv','TERM','xterm-256color','--setenv','LANG','C.UTF-8','--chdir','/mnt',
              '/usr/bin/python3','/mnt/install/installer.py','--user',users,'--hardware',hardware,'--features','none']
        if failed_package:
            args[args.index('--clearenv')+1:args.index('--clearenv')+1] = ['--setenv','DOTFILES_FAIL_AUR',failed_package]
        drive(args,expected=2 if failed_package else 0)
        log=[json.loads(line) for line in (temp/'commands.jsonl').read_text().splitlines()]
        home=temp/'home'
        assert (home/'.config/kitty/kitty.conf').is_symlink()
        assert not (home/'.codex').exists()
        assert not (home/'.cache/wallust/ghostty').exists()
        assert '/home/rymond044/' not in (home/'.gtkrc-2.0').read_text()
        assert (home/'.config/dotfiles/.env').stat().st_mode & 0o777 == 0o600
        assert (home/'Pictures/pfp/current_pfp.jpg').is_file()
        assert (home/'Wallpapers/current').is_file()
        assert (home/'.cache/wallust/hyprland.lua').is_file() == (failed_package is None)
        assert (home/'.cache/wallust/hyprlock.conf').is_file() == (failed_package is None)
        report=json.loads((home/'.local/state/dotfiles/install-report.json').read_text())
        assert report['complete'] == (failed_package is None)
        if failed_package:
            assert failed_package in report['missing_packages']
            assert not (temp/'etc/systemd/system/getty@tty1.service.d/zz-dotfiles.conf').exists()
        assert (home/'.config/systemd/user/dotfiles-first-login.service').is_file()
        assert not (home/'.local/state/dotfiles/first-login-complete').exists()
        assert not any('remove' in c or '--now' in c or 'disable' in c for c in log)
        assert not any(c[0] == 'hyprpm' or c[:2] == ['sudo','hyprpm'] for c in log)
        assert 'cryptdevice=UUID=test:root' in (temp/'etc/default/grub').read_text()
        assert 'sd-encrypt' in (temp/'etc/mkinitcpio.conf').read_text()
        if hardware == 'msi':
            assert '--ignore-gpu-blocklist' in (home/'.config/chromium-flags.conf').read_text()
            assert (temp/'etc/modprobe.d/msi-ec.conf').is_file()
            assert 'xe.force_probe=7d55' in (temp/'etc/default/grub').read_text()
            assert (home/'.config/systemd/user/ec-sync.service').is_symlink()
        else:
            assert '--ignore-gpu-blocklist' not in (home/'.config/chromium-flags.conf').read_text()
            assert not (temp/'etc/modprobe.d/msi-ec.conf').exists()
            assert not (home/'.config/systemd/user/ec-sync.service').exists()
            assert 'force_probe' not in (temp/'etc/default/grub').read_text()
        assert (home/'.config/electron-flags.conf').exists() == any(p in users.split(',') for p in ['discord','chatgpt-bin'])
        if 'chatgpt-bin' in users:
            assert (temp/'etc/pacman.d/openai-chatgpt.conf').is_file()
            assert '[multilib]' in (temp/'etc/pacman.conf').read_text()
            assert any('pacman-key' in c and '--lsign-key' in c for c in log)
        else:
            assert not (temp/'etc/pacman.d/openai-chatgpt.conf').exists()
        retained = {
            home/'Wallpapers/current': b'existing wallpaper',
            home/'Pictures/pfp/current_pfp.jpg': b'existing avatar',
            home/'.config/dotfiles/.env': b'LOCAL_SECRET=preserved\n',
        }
        for path, data in retained.items(): path.write_bytes(data)
        drive(args,expected=2 if failed_package else 0)
        for path, data in retained.items(): assert path.read_bytes() == data
        print(f'PASS {name}: install + repeat; actual stow/theme/files; package/git/unit operations simulated.')


if __name__=='__main__':
    scenario('base','none','none')
    scenario('MSI + default optional apps','telegram-desktop,discord,keepassxc,qbittorrent','msi')
    scenario('optional repositories','chatgpt-bin,steam','none')

    scenario('failed AUR package continues setup','none','none',failed_package='wallust')
