#!/usr/bin/env python3
"""Verify a native 50-slot save upgrades to 100 slots at the same mod version."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get('FACTORIO_BIN', Path.home() / '.steam/steam/steamapps/common/Factorio/bin/x64/factorio'))
DATA = BINARY.parents[2] / 'data'
info = json.loads((ROOT / 'info.json').read_text())
archive = ROOT / 'dist' / f"{info['name']}_{info['version']}.zip"
with tempfile.TemporaryDirectory(prefix='vld-migration-') as directory:
    work = Path(directory)
    mods, write = work / 'mods', work / 'write'
    mods.mkdir()
    write.mkdir()
    with zipfile.ZipFile(archive) as package:
        package.extractall(mods)
    source = mods / f"{info['name']}_{info['version']}"
    prototype = source / 'prototypes/dock.lua'
    current = prototype.read_text()
    old = current.replace('inventory_size = C.inventory_size,', 'inventory_size = C.legacy_inventory_size,')
    assert old != current, 'Inventory prototype replacement did not match'
    prototype.write_text(old)
    control = source / 'control.lua'
    control.write_text(control.read_text() + '\n' + (ROOT / 'tests/migration_engine.lua').read_text())
    (mods / 'mod-list.json').write_text(json.dumps({'mods': [{'name': name, 'enabled': True}
        for name in ['base', 'vehicle-loading-dock']]}))
    config = work / 'config.ini'
    config.write_text(f'[path]\nread-data={DATA}\nwrite-data={write}\n[other]\ncheck-updates=false\n')
    base = [str(BINARY), '--config', str(config), '--mod-directory', str(mods), '--disable-audio']
    save = work / 'legacy.zip'
    output = []
    for stage, args in enumerate([['--create', str(save)],
                                ['--benchmark', str(save), '--benchmark-ticks', '40', '--benchmark-runs', '1']]):
        if stage:
            prototype.write_text(current)
        run = subprocess.run(base + args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
        output.append(run.stdout)
        print('\n'.join(line for line in run.stdout.splitlines() if 'VLD MIGRATION' in line), flush=True)
        if run.returncode:
            print(run.stdout[-9000:])
            raise SystemExit(run.returncode)
    marker = write / 'script-output/vld-migration-result.txt'
    assert marker.exists() and marker.read_text() == 'VLD MIGRATION OK\n', 'Native migration did not finish'
    print('Factorio : migration native 50 → 100 sans changement de version ni initialisation de configuration OK')
