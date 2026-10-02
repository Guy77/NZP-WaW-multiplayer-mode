#!/usr/bin/env python3
"""NZP Skirmish build/staging helper. Python 3.10+, GPL-2.0-or-later."""
import argparse
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

MOD = Path(__file__).resolve().parents[1]
ROOT = MOD.parent
QC = ROOT / "quakec"
ENGINE = ROOT / "vril-engine"
DIST = MOD / "dist"


def run(command, cwd=ROOT):
    print("+", " ".join(map(str, command)), flush=True)
    subprocess.run(list(map(str, command)), cwd=cwd, check=True)


def compile_qc(tests=False, regenerate=False):
    DIST.mkdir(exist_ok=True)
    (QC / "build/standard").mkdir(parents=True, exist_ok=True)
    if regenerate or not (QC / "source/server/hash_table.qc").exists():
        run([sys.executable, "bin/qc_hash_generator.py", "-i",
             "tools/asset_conversion_table.csv", "-o", "source/server/hash_table.qc"], QC)
    suffix = {"Linux": "lin", "Darwin": "mac", "Windows": "win.exe"}[platform.system()]
    compiler = QC / "bin" / ("fteqcc-cli-" + suffix)
    if os.name != "nt":
        compiler.chmod(compiler.stat().st_mode | 0o111)
    command = [compiler, "-O3", "-Ono-compound_jumps", "-Wall"]
    if tests:
        command += ["-DSKIRMISH_TEST"]
    command += ["-srcfile", "progs/ssqc.src"]
    result = subprocess.run(list(map(str, command)), cwd=QC,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log = result.stdout
    (DIST / ("compile-test.log" if tests else "compile-release.log")).write_text(log)
    if result.returncode or "0 warnings" not in log or "Compile finished:" not in log:
        print(log)
        raise RuntimeError("QuakeC compile failed or produced warnings; see dist/compile-*.log")
    out = DIST / ("progs-test.dat" if tests else "progs.dat")
    shutil.copy2(QC / "build/standard/progs.dat", out)
    print("Compiled", out)
    return out


def compile_map(tool_dir):
    run([sys.executable, MOD / "tools/generate_arena.py"])
    def tool(name):
        return Path(tool_dir).resolve() / name if tool_dir else name
    for name, args in (("hlcsg", ["-nowadtextures", "mp_test.map"]),
                       ("hlbsp", ["mp_test"]), ("hlvis", ["mp_test"]),
                       ("hlrad", ["-ambient", "0.3", "0.3", "0.3", "mp_test"])):
        run([tool(name), "-threads", "2", *args], MOD / "maps")


def stage(target, destination, asset_dir):
    """Assemble fresh data; never overwrite a user's existing configuration."""
    dest = Path(destination).resolve()
    if dest.exists():
        raise RuntimeError(f"Destination already exists; choose a new staging folder: {dest}")
    asset_dir = Path(asset_dir).resolve()
    overlay = asset_dir / ("vita/data/nzp/nzp" if target == "vita" else "pc/nzp")
    for required in (asset_dir / "common/models/player.mdl", overlay / "nzp.rc",
                     DIST / "progs.dat", MOD / "maps/mp_test.bsp"):
        if not required.exists():
            raise FileNotFoundError(required)
    game = dest / "nzp"
    shutil.copytree(asset_dir / "common", game)
    shutil.copytree(overlay, game, dirs_exist_ok=True)
    # This sister game ships the original proving ground, not zombie maps.
    shutil.rmtree(game / "maps")
    (game / "maps").mkdir()
    for name in ("mp_test.bsp", "mp_test.txt", "mp_depot.bsp", "mp_depot.txt"):
        shutil.copy2(MOD / "maps" / name, game / "maps" / name)
    shutil.copy2(DIST / "progs.dat", game / "progs.dat")
    shutil.copytree(MOD / "generated/models/skirmish", game / "models/skirmish", dirs_exist_ok=True)
    (game / "version.txt").write_text("NZP Skirmish prototype 0.3\n")
    # Defaults are written once, so future launches preserve archived classes.
    with (game / "config.cfg").open("a") as config:
        config.write('\n// NZP Skirmish initial settings\n'
                     'mp_bots "6"\nmp_mode "1"\nmp_loadouts "0"\nmp_skill "1"\n'
                     'mp_respawn "5"\nmp_scorelimit "50"\nmp_minutes "10"\n'
                     'mp_class "0"\ncrosshair "1"\ncl_maxfps "60"\ncl_textopacity "0.6"\n')
        if target == "vita":
            config.write('bind "SELECT" "+showscores"\n')
        else:
            config.write('vid_width "960"\nvid_height "544"\nvid_fullscreen "0"\n')
    notices = dest / "licenses"
    notices.mkdir()
    shutil.copy2(asset_dir / "LICENSE.md", notices / "NZP-ASSETS-CC-BY-SA-4.0.md")
    for repository, label in ((QC, "QUAKEC"), (ENGINE, "ENGINE")):
        candidates = list(repository.glob("LICENSE*")) + list(repository.glob("COPYING*"))
        if candidates:
            shutil.copy2(candidates[0], notices / (label + "-GPL.txt"))
    for name in ("README.md", "CREDITS.md", "INSTALL_VITA.md"):
        if (MOD / name).exists():
            shutil.copy2(MOD / name, dest / name)
    print("Staged", dest)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    qc = commands.add_parser("qc")
    qc.add_argument("--tests", action="store_true")
    qc.add_argument("--regenerate-hashes", action="store_true")
    arena = commands.add_parser("map")
    arena.add_argument("--vhlt", default=os.environ.get("VHLT_DIR"))
    for name in ("linux", "vita"):
        p = commands.add_parser(name)
        p.add_argument("--jobs", default=2, type=int)
    data = commands.add_parser("stage")
    data.add_argument("--platform", choices=["linux", "vita"], required=True)
    data.add_argument("--out", required=True)
    data.add_argument("--assets", default=str(ROOT / "assets"))
    args = parser.parse_args()
    if args.command == "qc":
        compile_qc(args.tests, args.regenerate_hashes)
    elif args.command == "map":
        compile_map(args.vhlt)
    elif args.command in ("linux", "vita"):
        if args.command == "vita" and not shutil.which("arm-vita-eabi-gcc"):
            parser.error("Set VITASDK and add $VITASDK/bin to PATH first")
        run(["make", "-f", "Makefile.psp2" if args.command == "vita" else "Makefile.sdl",
             "-j", str(args.jobs)], ENGINE)
    else:
        stage(args.platform, args.out, args.assets)


if __name__ == "__main__":
    main()
