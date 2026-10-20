#!/usr/bin/env python3
"""Capture the portal demonstration in an isolated copy of a Factorio save."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--save', type=Path, required=True)
parser.add_argument('--output', type=Path, default=ROOT/'portal/gallery/05-demonstration.gif')
parser.add_argument('--speed', type=float, default=1.5)
args = parser.parse_args()
if not args.save.is_file() or args.speed <= 0:
    parser.error('Provide an existing save and a positive playback speed')
binary = Path(os.environ.get('FACTORIO_BIN', Path.home()/'.steam/steam/steamapps/common/Factorio/bin/x64/factorio'))
work = Path(tempfile.mkdtemp(prefix='vld-portal-demo-'))
mods, write = work/'mods', work/'write'
mods.mkdir(); write.mkdir()
mod = mods/'vehicle-loading-dock'
mod.mkdir()
for name in ['info.json', 'data.lua', 'control.lua']:
    shutil.copy2(ROOT/name, mod/name)
for name in ['scripts', 'prototypes', 'graphics', 'locale']:
    shutil.copytree(ROOT/name, mod/name)
with (mod/'data.lua').open('a') as target:
    target.write('\ndata.raw["electric-energy-interface"]["electric-energy-interface"].picture={filename="__core__/graphics/empty.png",size=1}\n')
with (mod/'control.lua').open('a') as target:
    target.write('\n'+(ROOT/'tools/portal_demo.lua').read_text())
(mods/'mod-list.json').write_text(json.dumps({'mods': [{'name': name, 'enabled': name in ['base', 'vehicle-loading-dock']}
    for name in ['base', 'vehicle-loading-dock', 'space-age', 'quality', 'elevated-rails', 'recycler']]}))
shutil.copy2(args.save, work/'source.zip')
config = work/'config.ini'
config.write_text(f'[path]\nread-data={binary.parents[2]/"data"}\nwrite-data={write}\n[other]\ncheck-updates=false\n'
                  '[graphics]\nfull-screen=false\ngraphics-quality=normal\nmax-threads=4\n')
env = {**os.environ, 'SDL_VIDEODRIVER': 'offscreen', 'SteamAppId': '427520', 'SteamGameId': '427520'}
env.pop('DISPLAY', None); env.pop('WAYLAND_DISPLAY', None)
print(f'Profil isolé : {work}', flush=True)
marker = write/'script-output/demo-complete.json'
with (work/'render.log').open('w') as output:
    process = subprocess.Popen([str(binary), '--config', str(config), '--mod-directory', str(mods), '--disable-audio',
        '--window-size', '1000x700', '--force-graphics-preset', 'very-low', '--load-game', str(work/'source.zip')],
        env=env, stdout=output, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic()+300
        while time.monotonic() < deadline:
            if marker.exists():
                time.sleep(2)
                break
            log = (work/'render.log').read_text()
            if process.poll() is not None or 'Error while running event' in log or 'non-recoverable error' in log:
                break
            time.sleep(.25)
    finally:
        if process.poll() is None:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill(); process.wait()
log = (work/'render.log').read_text()
print('\n'.join(line for line in log.splitlines() if 'VLD DEMO' in line), flush=True)
if not marker.exists():
    raise SystemExit(log[-6000:])
result = json.loads(marker.read_text())
assert result['left_remaining'] == result['right_remaining'] == 0
frames = sorted((write/'script-output/frames').glob('frame-*.png'))
assert len(frames) == result['frames']
transparent = work/'transparent'
transparent.mkdir()
for frame in frames:
    rgb = np.asarray(Image.open(frame).convert('RGB')).astype(np.int16)
    mask = (np.minimum(rgb[:, :, 0], rgb[:, :, 2])-rgb[:, :, 1] > 10) & (np.abs(rgb[:, :, 0]-rgb[:, :, 2]) < 80)
    rgba = np.zeros((*rgb.shape[:2], 4), dtype=np.uint8)
    rgba[:, :, :3] = rgb
    rgba[:, :, 3] = np.where(mask, 0, 255)
    rgba[mask, :3] = 0
    Image.fromarray(rgba).save(transparent/frame.name)
print(f'{len(frames)} images détourées ; compression…', flush=True)
raw = work/'demo.gif'
subprocess.run(['ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-framerate', '10',
    '-i', str(transparent/'frame-%04d.png'), '-filter_complex',
    f'[0:v]setpts=PTS/{args.speed},fps=8,scale=880:-1:flags=lanczos,split[a][b];'
    '[a]palettegen=max_colors=128:reserve_transparent=1:stats_mode=diff[p];'
    '[b][p]paletteuse=dither=bayer:bayer_scale=3:alpha_threshold=128:diff_mode=rectangle',
    '-loop', '0', str(raw)], check=True)
selected = raw
if shutil.which('convert'):
    optimized = work/'optimized.gif'
    run = subprocess.run(['convert', str(raw), '-layers', 'Optimize', str(optimized)],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    if run.returncode == 0 and optimized.stat().st_size < raw.stat().st_size:
        original, candidate = Image.open(raw), Image.open(optimized)
        identical = original.n_frames == candidate.n_frames
        if identical:
            for i in range(original.n_frames):
                original.seek(i); candidate.seek(i)
                a = np.asarray(original.convert('RGBA'))
                b = np.asarray(candidate.convert('RGBA'))
                visible = (a[:, :, 3] > 0) | (b[:, :, 3] > 0)
                if not np.array_equal(a[visible], b[visible]) or original.info.get('duration') != candidate.info.get('duration'):
                    identical = False
                    break
        if identical: selected = optimized
image = Image.open(selected)
assert image.info.get('loop') == 0 and image.size == (880, 704)
duration = 0
for index in range(image.n_frames):
    image.seek(index)
    assert image.convert('RGBA').getextrema()[3] == (0, 255)
    duration += image.info['duration']
args.output.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(selected, args.output)
print(f'GIF : {args.output}\nDurée : {duration/1000:.2f} s ; taille : {selected.stat().st_size/1e6:.2f} Mo', flush=True)
