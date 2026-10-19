#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
MODS_DIR="${MODS_DIR:-$HOME/.factorio/mods}"
readarray -t METADATA < <(python3 - <<'PY'
import json
with open("info.json", encoding="utf-8") as source:
    metadata = json.load(source)
print(metadata["name"])
print(metadata["version"])
PY
)
NAME="${METADATA[0]}"
VERSION="${METADATA[1]}"

case "${1:-}" in
  package)
    python3 - "$ROOT" "$NAME" "$VERSION" <<'PY'
import pathlib
import shutil
import sys
import zipfile

root = pathlib.Path(sys.argv[1])
name, version = sys.argv[2:]
dist = root / "dist"
if dist.exists():
    shutil.rmtree(dist)
dist.mkdir()
archive_path = dist / f"{name}_{version}.zip"
files = ["info.json", "data.lua", "control.lua", "README.md", "LICENSE", "thumbnail.png"]
directories = ["prototypes", "scripts", "graphics", "locale"]
if (root / "changelog.txt").is_file():
    files.append("changelog.txt")
with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
    for entry in files:
        path = root / entry
        if not path.is_file():
            raise SystemExit(f"Missing package file: {entry}")
        archive.write(path, f"{name}_{version}/{entry}")
    for directory in directories:
        for path in sorted((root / directory).rglob("*")):
            if path.is_file() and path.suffix in {".lua", ".png", ".cfg"}:
                archive.write(path, f"{name}_{version}/{path.relative_to(root)}")
print(archive_path)
PY
    ;;
  link|devlink)
    python3 - "$ROOT" "$MODS_DIR" "$NAME" <<'PY'
import pathlib
import re
import sys

root, mods = map(pathlib.Path, sys.argv[1:3])
name = sys.argv[3]
mods.mkdir(parents=True, exist_ok=True)
target = mods / name
if target.is_symlink():
    if target.resolve() != root:
        raise SystemExit(f"Existing link points elsewhere: {target}")
elif target.exists():
    raise SystemExit(f"Existing directory must be handled manually: {target}")
else:
    target.symlink_to(root, target_is_directory=True)
for path in mods.iterdir():
    if re.fullmatch(re.escape(name) + r"_\d+\.\d+\.\d+\.zip", path.name) and path.is_file():
        path.unlink()
        print(f"Removed shadowing package: {path}")
print(f"{target} -> {root}")
PY
    ;;
  unlink)
    python3 - "$ROOT" "$MODS_DIR" "$NAME" <<'PY'
import pathlib
import sys

root, mods = map(pathlib.Path, sys.argv[1:3])
target = mods / sys.argv[3]
if target.is_symlink() and target.resolve() == root:
    target.unlink()
    print(f"Removed link: {target}")
elif target.exists() or target.is_symlink():
    raise SystemExit(f"Refusing to remove an unrelated installation: {target}")
PY
    ;;
  clean)
    python3 - <<'PY'
import shutil
shutil.rmtree("dist", ignore_errors=True)
PY
    ;;
  test)
    python3 tests/run.py
    ;;
  lint)
    bash -n build.sh
    python3 -m json.tool info.json >/dev/null
    python3 tests/run.py --lint
    ;;
  *)
    printf '%s\n' \
      'Usage: ./build.sh {package|link|devlink|unlink|clean|test|lint}' \
      'MODS_DIR selects the installation directory (default: ~/.factorio/mods).'
    [[ $# -eq 0 ]] || exit 1
    ;;
esac
