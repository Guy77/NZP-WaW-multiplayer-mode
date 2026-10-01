#!/usr/bin/env python3
"""Install the recorded Linux x86-64 Vita toolchain in a new local directory.
Requires Python 3.12+, git, GNU make and the host libraries needed by VitaSDK.
Downloads are checksum verified. Nothing is installed to system directories.
GPL-2.0-or-later.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import tarfile
import urllib.request

MOD = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--jobs", type=int, default=2)
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        parser.error("This pinned SDK archive targets Linux x86-64. Install VitaSDK separately on other hosts.")
    out = args.out.resolve()
    if out.exists():
        parser.error("--out must name a new directory")
    upstream = json.loads((MOD / "upstream.json").read_text())
    packages = json.loads((MOD / "vita-dependencies.json").read_text())
    cache = out / "downloads"
    cache.mkdir(parents=True)

    def fetch(record):
        name = record.get("name", record["url"].rsplit("/", 1)[-1])
        path = cache / name
        digest = hashlib.sha256()
        with urllib.request.urlopen(record["url"], timeout=90) as response, path.open("wb") as dest:
            while chunk := response.read(1024 * 1024):
                dest.write(chunk)
                digest.update(chunk)
        if digest.hexdigest() != record["sha256"]:
            path.unlink()
            raise RuntimeError("SHA-256 mismatch: " + name)
        print("Verified", name, flush=True)
        return path

    sdk_archive = fetch(upstream["VitaSDK"])
    with tarfile.open(sdk_archive) as archive:
        archive.extractall(out, filter="data")
    sdk = out / "vitasdk"
    with ThreadPoolExecutor(max_workers=4) as pool:
        archives = list(pool.map(fetch, packages))
    for path in archives:
        with tarfile.open(path) as archive:
            archive.extractall(sdk / "arm-vita-eabi", filter="data")

    env = os.environ.copy()
    env["VITASDK"] = str(sdk)
    env["PATH"] = str(sdk / "bin") + os.pathsep + env["PATH"]
    (out / "tmp").mkdir()
    env["TMPDIR"] = str(out / "tmp")
    gl = out / "vitaGL"
    subprocess.run(["git", "clone", "--depth", "1", upstream["vitaGL"]["url"], str(gl)], check=True)
    for command in (["git", "fetch", "--depth", "1", "origin", upstream["vitaGL"]["revision"]],
                    ["git", "checkout", "--detach", upstream["vitaGL"]["revision"]],
                    ["make", *upstream["vitaGL"]["flags"], "-j", str(args.jobs)],
                    ["make", "install"]):
        subprocess.run(command, cwd=gl, env=env, check=True)
    print("VITASDK=" + str(sdk))
    print("Add the SDK bin directory to PATH, then run build.py vita.")


if __name__ == "__main__":
    main()
