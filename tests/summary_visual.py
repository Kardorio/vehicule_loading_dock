#!/usr/bin/env python3
"""Verify the inventory sidebar with real driving and remote controllers."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get('FACTORIO_BIN', Path.home() / '.steam/steam/steamapps/common/Factorio/bin/x64/factorio'))
DATA = BINARY.parents[2] / 'data'
work = Path(tempfile.mkdtemp(prefix='vld-summary-'))
mods, write = work / 'mods', work / 'write'
mods.mkdir()
write.mkdir()
mod = mods / 'vehicle-loading-dock'
mod.mkdir()
for filename in ['info.json', 'data.lua', 'control.lua']:
    shutil.copy2(ROOT / filename, mod / filename)
for directory in ['scripts', 'prototypes', 'graphics', 'locale']:
    if (ROOT / directory).exists():
        shutil.copytree(ROOT / directory, mod / directory)
with (mod / 'control.lua').open('a') as control:
    control.write('\n' + (ROOT / 'tests/summary_engine.lua').read_text())
(mods / 'mod-list.json').write_text(json.dumps({'mods': [
    {'name': name, 'enabled': True} for name in ['base', 'vehicle-loading-dock']] + [
    {'name': name, 'enabled': False} for name in ['space-age', 'quality', 'elevated-rails']]}))
config = work / 'config.ini'
config.write_text(f'[path]\nread-data={DATA}\nwrite-data={write}\n[general]\nlocale=fr\n[other]\ncheck-updates=false\n'
                  '[graphics]\nfull-screen=false\ngraphics-quality=normal\nmax-threads=4\n')
env = {**os.environ, 'SDL_VIDEODRIVER': 'offscreen', 'SteamAppId': '427520', 'SteamGameId': '427520'}
env.pop('DISPLAY', None)
env.pop('WAYLAND_DISPLAY', None)
base = [str(BINARY), '--config', str(config), '--mod-directory', str(mods), '--disable-audio']
save = work / 'test.zip'
created = subprocess.run(base + ['--create', str(save)], env=env, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True, timeout=90)
(work / 'create.log').write_text(created.stdout)
if created.returncode:
    print(created.stdout[-8000:])
    raise SystemExit(created.returncode)
log_path = work / 'visual.log'
marker = write / 'script-output/vld-summary-result.txt'
preview = write / 'script-output/vld-summary.png'
with log_path.open('w') as output:
    process = subprocess.Popen(base + ['--window-size', '1280x900', '--force-graphics-preset', 'very-low', '--load-game', str(save)],
                               env=env, stdout=output, stderr=subprocess.STDOUT)
    deadline = time.monotonic() + 90
    try:
        while time.monotonic() < deadline:
            if marker.exists() and preview.exists() and preview.stat().st_size > 1000:
                break
            if process.poll() is not None or 'Error while running event' in log_path.read_text():
                break
            time.sleep(0.25)
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
log = log_path.read_text()
print('\n'.join(line for line in log.splitlines() if 'VLD SUMMARY' in line))
print(f'Profil et journaux : {work}')
if not (marker.exists() and marker.read_text() == 'VLD SUMMARY OK\n' and preview.exists()):
    print(log[-10000:])
    raise SystemExit('Validation graphique incomplète ; consulter le journal du profil temporaire.')
print(f'Aperçu : {preview}')
print('Factorio : vrais éléments GUI et capture offscreen OK')
