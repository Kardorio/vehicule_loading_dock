#!/usr/bin/env python3
"""Validate the installed Pyanodon pack in an isolated Factorio profile."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get('FACTORIO_BIN', Path.home() / '.steam/steam/steamapps/common/Factorio/bin/x64/factorio'))
SOURCE = Path(os.environ.get('PY_MODS_DIR', Path.home() / '.factorio/mods'))
work = Path(tempfile.mkdtemp(prefix='vld-pyanodon-'))
mods, write = work/'mods', work/'write'
mods.mkdir()
write.mkdir()
selected = {}
for archive in SOURCE.glob('*.zip'):
    if not archive.name.startswith(('py', 'enable-all-feature-flags_', 'cargo-bays-and-unloaders_')):
        continue
    with zipfile.ZipFile(archive) as package:
        metadata = json.loads(package.read(next(n for n in package.namelist() if n.endswith('/info.json'))))
    version = tuple(map(int, metadata['version'].split('.')))
    name = metadata['name']
    if name not in selected or version > selected[name][0]:
        selected[name] = (version, archive)
assert 'pymodpack' in selected, 'Install the Pyanodon pack before running this scenario'
for _, archive in selected.values():
    (mods/archive.name).symlink_to(archive)
subprocess.run([str(ROOT/'build.sh'), 'package'], check=True, stdout=subprocess.PIPE)
info = json.loads((ROOT/'info.json').read_text())
with zipfile.ZipFile(ROOT/'dist'/f"{info['name']}_{info['version']}.zip") as package:
    package.extractall(mods)
control = mods/f"{info['name']}_{info['version']}"/'control.lua'
with control.open('a') as target:
    target.write('''
script.on_init(function()
  initialize()
  local recipe = game.forces.player.recipes['vehicle-loading-dock']
  local ingredients = {}
  for _, ingredient in pairs(recipe.ingredients) do ingredients[ingredient.name] = ingredient.amount end
  assert(ingredients['iron-plate'] == 20 and ingredients['small-parts-01'] == 20)
  assert(ingredients['engine-unit'] == 5 and ingredients['iron-chest'] == 2)
  assert(not ingredients['electronic-circuit'], 'The early dock must not require circuits')
  local car_uses_engine = false
  for _, ingredient in pairs(game.forces.player.recipes.car.ingredients) do
    if ingredient.name == 'engine-unit' then car_uses_engine = true end
  end
  assert(car_uses_engine, 'The dock must use the same engines as the car')
  assert(not ingredients['steel-plate'] and not ingredients['iron-gear-wheel'])
  local unlock = false
  for _, effect in pairs(prototypes.technology.automobilism.effects) do
    if effect.type == 'unlock-recipe' and effect.recipe == 'vehicle-loading-dock' then unlock = true end
  end
  assert(unlock, 'Automobilism must unlock the dock')
  log('VLD PYANODON PASS recipe and Automobilism unlock')
end)
''')
(mods/'mod-list.json').write_text(json.dumps({'mods': [{'name': n, 'enabled': True}
    for n in ['base', *selected, info['name']]] + [
        {'name': n, 'enabled': False} for n in ['space-age', 'elevated-rails', 'quality', 'recycler']]}))
config = work/'config.ini'
config.write_text(f'[path]\nread-data={BINARY.parents[2] / "data"}\nwrite-data={write}\n[other]\ncheck-updates=false\n')
print(f'Profil isolé : {work}', flush=True)
run = subprocess.run([str(BINARY), '--config', str(config), '--mod-directory', str(mods),
    '--disable-audio', '--create', str(work/'test.zip')], text=True,
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
(work/'validation.log').write_text(run.stdout)
print('\n'.join(line for line in run.stdout.splitlines() if 'VLD PYANODON' in line))
if run.returncode or 'VLD PYANODON PASS' not in run.stdout:
    print(run.stdout[-7000:])
    raise SystemExit(run.returncode or 1)
print('Factorio : chargement du pack Pyanodon complet, recette et déblocage OK')
