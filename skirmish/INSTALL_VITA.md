# NZP Skirmish on PS Vita

This is a homebrew prototype. The user confirmed version 0.1 works on physical Vita hardware. This 0.2 update is cross-compiled and desktop-regression-tested; its changes still need a device check.

## Updating from 0.1

Use the 0.2 Vita update ZIP with your existing 0.1 data. Close the game, install its replacement VPK through VitaShell, and merge its `data` folder into `ux0:/data`, replacing `progs.dat` and `version.txt`. If your active data is on `uma0:`, update that copy instead. The update contains no configuration file, so existing settings and classes are preserved. Both the VPK and game logic must be updated.

## Full installation

1. Extract the Vita package on your computer.
2. Copy its `data/nzp-skirmish` folder to `ux0:/data/nzp-skirmish` on the Vita. For example, the game logic must end up at `ux0:/data/nzp-skirmish/nzp/progs.dat`, and the map at `ux0:/data/nzp-skirmish/nzp/maps/mp_test.bsp`.
3. Transfer and install `NZP-Skirmish.vpk` through VitaShell, then launch **NZP Skirmish**.
4. Choose **Offline Multiplayer → Start Match**. Start with the default six bots.

The application uses title ID **NZPSK0001** and a separate data directory. It can coexist with ordinary NZP. A complete data tree on `uma0:` is also detected by `nzp/progs.dat`; if present, it takes precedence over `ux0:`.

As with the underlying vitaGL-based NZP port, the console needs a working homebrew environment and its extracted/decrypted `libshacccg.suprx` shader compiler. Follow the prerequisites linked by the [official vitaGL README](https://github.com/Rinnegatamante/vitaGL#prerequisites). The Sony shader module is not included in this package.

## Controls

| Action | Default Vita control |
| --- | --- |
| Move / look | Left / right stick |
| Aim / fire | L / R |
| Reload / use | Square / hold Square |
| Jump / change weapon | Cross / Triangle |
| Crouch / prone | Circle / hold Circle |
| Sprint | D-pad down |
| Frag grenade / knife | D-pad left / right |
| Scoreboard / pause | Select / Start |

Select a class before starting, or open **Pause → Create a Class** during a match. Loadout changes take effect on the next spawn. Edited classes and settings are saved when the game exits normally.

## First hardware test

Check that the main menu, match setup and class menu respond to buttons. Start a six-bot Team Deathmatch. Move, fire, reload, switch weapons, use a grenade, die and wait for the five-second respawn. Confirm ally labels, scores and the scoreboard. Change class in Pause, then verify the next spawn. Restart and finish a match before trying nine or twelve bots.

Record device model, active plugins, bot count, graphics settings and observed frame rate if reporting a problem. The engine's log is under `ux0:/data/nzp-skirmish/log.txt` (or the corresponding `uma0:` path). This build does not establish a measured Vita frame-rate target.

## Rebuilding the VPK

The source archive contains both modified repositories and the arena source. Vita needs [VitaSDK](https://vitasdk.org/), the libraries listed in `vril-engine/Makefile.psp2`, and vitaGL built at the revision/flags recorded in `upstream.json` and `tools/setup_vita.py`.

```sh
# Optional Linux x86-64 helper: downloads verified SDK/dependency archives
# into a NEW directory, then builds the pinned vitaGL revision.
python3 skirmish/tools/setup_vita.py --out "$PWD/.toolchains/vita"
export VITASDK="$PWD/.toolchains/vita/vitasdk"
export PATH="$VITASDK/bin:$PATH"

python3 skirmish/tools/build.py qc
python3 skirmish/tools/build.py vita
python3 skirmish/tools/build.py stage --platform vita --out build/nzp-skirmish --assets /path/to/assets
```

The engine outputs `vril-engine/build/psp2/nzportable.vpk`; rename it to `NZP-Skirmish.vpk` for distribution. Copy the freshly staged `build/nzp-skirmish` folder to the console's `data` folder. Stage into a new directory; the helper deliberately refuses to overwrite saved configurations.
