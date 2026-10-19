#!/usr/bin/env python3
"""Run the Lua checks using the system liblua, without installing dependencies."""
import ctypes
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
lua = ctypes.CDLL('liblua5.4.so.0')
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]


def check(path, execute=False):
    state = lua.luaL_newstate()
    try:
        lua.luaL_openlibs(state)
        content = path.read_bytes()
        code = lua.luaL_loadbufferx(state, content, len(content), str(path).encode(), None)
        if code == 0 and execute:
            code = lua.lua_pcallk(state, 0, -1, 0, None, None)
        if code:
            raise SystemExit(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)


for path in sorted(ROOT.rglob('*.lua')):
    if 'dist' not in path.parts:
        check(path)
print('Syntaxe Lua : OK')
json.loads((ROOT / 'info.json').read_text())
locales = []
for language in ('fr', 'en'):
    keys, section = set(), ''
    for line in (ROOT / 'locale' / language / 'locale.cfg').read_text().splitlines():
        if line.startswith('['):
            section = line.strip('[]')
        elif '=' in line:
            key = section + '.' + line.split('=', 1)[0]
            assert key not in keys, key
            keys.add(key)
    locales.append(keys)
assert locales[0] == locales[1], locales
print('Locales français/anglais : OK')
if '--lint' not in sys.argv:
    import os
    os.chdir(ROOT)
    for path in sorted((ROOT / 'tests').glob('test_*.lua')):
        check(path, execute=True)
