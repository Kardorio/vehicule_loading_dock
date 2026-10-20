#!/usr/bin/env python3
"""005-AC1 à 005-AC5 : vérifier les réseaux logiques dans le moteur réel."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get('FACTORIO_BIN', Path.home() / '.steam/steam/steamapps/common/Factorio/bin/x64/factorio'))
DATA = BINARY.parents[2] / 'data'
with tempfile.TemporaryDirectory(prefix='vld-circuit-') as directory:
    work = Path(directory)
    mods, write = work/'mods', work/'write'
    mods.mkdir();write.mkdir()
    subprocess.run([str(ROOT/'build.sh'),'package'],check=True,stdout=subprocess.PIPE)
    info=json.loads((ROOT/'info.json').read_text())
    with zipfile.ZipFile(ROOT/'dist'/f"{info['name']}_{info['version']}.zip") as package:
        package.extractall(mods)
    control=mods/f"{info['name']}_{info['version']}"/'control.lua'
    with control.open('a') as f:
        f.write('\n'+(ROOT/'tests/circuit_engine.lua').read_text())
    (mods/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True}
      for n in ['base','vehicle-loading-dock']]}))
    config=work/'config.ini'
    config.write_text(f'[path]\nread-data={DATA}\nwrite-data={write}\n[other]\ncheck-updates=false\n')
    base=[str(BINARY),'--config',str(config),'--mod-directory',str(mods),'--disable-audio']
    save=work/'test.zip'
    for args in [['--create',str(save)],['--benchmark',str(save),'--benchmark-ticks','120','--benchmark-runs','1']]:
        run=subprocess.run(base+args,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
        log_file=ROOT/'tests'/'last-circuit.log'
        with log_file.open('a' if args[0]=='--benchmark' else 'w') as f:f.write(run.stdout)
        lines=[line for line in run.stdout.splitlines() if 'VLD PASS' in line or 'VLD CIRCUIT OK' in line]
        print('\n'.join(lines),flush=True)
        if run.returncode:
            print(run.stdout[-9000:])
            raise SystemExit(run.returncode)
    marker=write/'script-output/vld-circuit-result.txt'
    assert marker.exists() and marker.read_text()=='VLD CIRCUIT OK\n', 'Runtime test did not finish'
    print('Factorio : réseau logique et rechargement OK')
