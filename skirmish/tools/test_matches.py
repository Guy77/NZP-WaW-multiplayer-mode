#!/usr/bin/env python3
"""Run match regressions in the real desktop engine. GPL-2.0-or-later.
Usage: python3 skirmish/tools/test_matches.py --runtime path/to/staged-data
Uses an isolated config folder and restores release progs even after failure.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from build import MOD, ROOT, ENGINE, QC, DIST, compile_qc

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--runtime", required=True, type=Path)
parser.add_argument("--engine", type=Path, default=ENGINE / "build/sdl/nzportable")
args = parser.parse_args()
runtime = args.runtime.resolve() / "nzp"
engine = args.engine.resolve()
release = compile_qc()
test = compile_qc(tests=True)
try:
    for bots, mode, loadouts, respawn in ((6, 1, 0, 5), (12, 0, 1, 7)):
        with tempfile.TemporaryDirectory(prefix="match-test-", dir=MOD) as tmp:
            game = Path(tmp) / "nzp"
            game.mkdir()
            for item in runtime.iterdir():
                if item.name in ("progs.dat", "config.cfg", "autoexec.cfg", "nzp.rc", "default.cfg"):
                    continue
                if item.is_dir():
                    shutil.copytree(item, game / item.name)
                else:
                    shutil.copy2(item, game / item.name)
            shutil.copy2(test, game / "progs.dat")
            (game / "config.cfg").write_text("")
            (game / "default.cfg").write_text("")
            (game / "nzp.rc").write_text("stuffcmds\n")
            command = [str(engine), "-basedir", tmp, "-nosound", "+vid_renderer", "headless",
                       "+cl_maxfps", "500", "+host_framerate", "0.05", "+sv_skirmish", "1",
                       "+mp_class", "0", "+mp_class1_primary", "12", "+mp_bots", str(bots),
                       "+mp_mode", str(mode), "+mp_loadouts", str(loadouts), "+mp_respawn", str(respawn),
                       "+map", "mp_test"]
            result = subprocess.run(command, cwd=tmp, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, timeout=60)
            log = MOD / "docs" / f"tests-{bots}.log"
            log.write_text(result.stdout)
            if result.returncode or "SKIRMISH TESTS PASS" not in result.stdout:
                print(result.stdout)
                raise RuntimeError(f"Match regression failed; see {log}")
            for line in result.stdout.splitlines():
                if line.startswith("SKIRMISH TEST"):
                    print(line)
finally:
    shutil.copy2(release, QC / "build/standard/progs.dat")
