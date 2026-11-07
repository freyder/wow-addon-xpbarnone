"""Run tests/forever_sim.lua against Core.lua under Lua 5.1 (no WoW client needed).

    python3 -m venv /tmp/luatest && /tmp/luatest/bin/pip install lupa
    /tmp/luatest/bin/python tests/run_forever_sim.py [path/to/Core.lua] [fallback]
"""
import pathlib
import sys

from lupa.lua51 import LuaRuntime

here = pathlib.Path(__file__).resolve().parent
core = sys.argv[1] if len(sys.argv) > 1 else str(here.parent / "Core.lua")
mode = sys.argv[2] if len(sys.argv) > 2 else None
LuaRuntime().eval("function(p, c, m) return assert(loadfile(p))(c, m) end")(str(here / "forever_sim.lua"), core, mode)
