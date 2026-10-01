# NZP Skirmish — prototype 0.2

A standalone, offline soldier-combat variant of **Nazi Zombies: Portable**, inspired by World at War's multiplayer. One local player fights alongside or against 6–12 bots. This is an early playable foundation, not a complete recreation of World at War.

## Included

- Separate **Offline Multiplayer** setup menu and **Create a Class** menu.
- Team Deathmatch (Allies versus Axis, friendly fire off) and Free-for-All.
- 6–12 bots, three skill levels, soldier presets or randomized period weapon loadouts on each respawn.
- Five saved player classes, 21 base primary weapons and three secondary choices (Colt, Magnum, Ballistic Knife). No Pack-a-Punch weapons, Ray Guns, Wunderwaffe or flamethrower.
- Two frag grenades and a knife for the player; existing NZP weapon handling, reloading, aiming and movement.
- Configurable respawn delay: **5 seconds by default**, adjustable from 1–30 seconds for both player and bots.
- Kill limit, time limit, scores, deaths, match results and pause/restart flow.
- Original **Proving Ground** test arena, with cover, 18 spawn points and 35 navigation nodes.
- A separate Vita application identity (`NZPSK0001`) and data folder (`data/nzp-skirmish`).

## Playing

Open **Offline Multiplayer**, choose settings, edit/select a class, then **Start Match**. On death, respawning is automatic. Use **Pause → Create a Class** to change the class used at your next spawn. At the result screen, use Pause to restart or return to the main menu.

In Team Deathmatch you play for the Allies. Blue panels mark the Allies' end; red panels mark the Axis end. Visible teammates have an **ALLY** label. Crosshair target text also identifies allies and enemies. With an even number of bots there is one extra soldier on the human player's team; odd bot counts allow equal teams.

Spawn protection lasts 1.5 seconds and ends when firing. Health regenerates after avoiding damage. Neither game mode starts the zombie round loop.

### Linux desktop package

Extract the package and run `./start-skirmish.sh`. The executable is for x86-64 Linux and needs SDL2, SDL2_mixer, OpenGL and GLU. On Debian/Ubuntu the relevant runtime packages are commonly `libsdl2-2.0-0`, `libsdl2-mixer-2.0-0`, `libgl1` and `libglu1-mesa`.

| Action | Default key |
| --- | --- |
| Move / look | WASD / mouse |
| Fire / aim | Left / right mouse button |
| Reload / switch weapon | R / Q |
| Jump / sprint | Space / Shift |
| Grenade / knife | G / V |
| Crouch / prone | Alt / hold Alt |
| Scoreboard / pause | Tab / Escape |

For Vita installation and controls, read **INSTALL_VITA.md**.

## Scope of this prototype

The bots navigate a small authored waypoint graph, use line of sight and a limited memory of enemies, react with a delay, strafe, fire bursts, reload and attempt to take cover when reloading. They do not yet use grenades, knives or sidearm switching, coordinate squads, mantle, or navigate arbitrary zombie maps. Their reserve ammunition is unlimited, but magazines and reload delays are enforced. They reuse the existing NZP soldier model and generic third-person animations rather than separate weapon models and faction uniforms.

Player classes retain MP5K as a non-period primary and Ballistic Knife as a non-period secondary. Bot random loadouts use period ballistic weapons only. Saved knife-primary classes migrate to a role primary plus knife secondary at spawn. Removed weapons fall back to a role primary or Colt secondary. Specials still need further playtesting; regression tests cover class equipment and the rifle firing path, not every weapon firing mode.

Killstreaks, class perks, progression, objective modes, custom class names, match history, polished faction art and additional maps are deferred. There is no network multiplayer. The engine retains its internal local client/server simulation and upstream networking code, but this menu starts one local client with listening disabled; bots do not occupy network slots.

Desktop gameplay and rendered menus have been tested. The user confirmed that version 0.1 launches and plays on physical Vita hardware. Version 0.2 needs a follow-up hardware check; no measured frame-rate or memory results are available. Six bots is the initial Vita default; twelve is a supported setting, not a promise of twelve-bot performance on the device.

## Source layout and builds

The source archive has sibling folders `quakec/`, `vril-engine/` and `skirmish/`. Engine and QuakeC sources are already patched. The original zombie code remains in the sources; this packaged sister game exposes Skirmish and contains only its test arena.

From the source archive's root:

```sh
# Compile the game logic with the included FTEQCC binary.
python3 skirmish/tools/build.py qc

# Linux engine: GCC/Clang, make, pkg-config and SDL2/OpenGL development packages.
python3 skirmish/tools/build.py linux

# Optional: regenerate the map with NZP VHLT installed.
python3 skirmish/tools/build.py map --vhlt /path/to/vhlt

# Supply the NZP assets checkout pinned in upstream.json, then stage fresh data.
python3 skirmish/tools/build.py stage --platform linux --out build/linux-data --assets /path/to/assets

# Run the real-engine match regressions. Test builds are kept out of release data.
python3 skirmish/tools/test_matches.py --runtime build/linux-data
```

The generated asset hash table is included. To regenerate it after changing the conversion CSV, install Python `pandas`, `fastcrc` and `colorama`, then run `build.py qc --regenerate-hashes`. Python 3.12 is recommended for the toolchain setup helper.

The compiled `skirmish/dist/progs.dat` and `skirmish/maps/mp_test.bsp` are also included. Both the modified engine and modified game logic are required; copying only `progs.dat` into an ordinary NZP installation will not supply the new menus and HUD.

See `docs/ARCHITECTURE.md` for extension points, `docs/TEST_REPORT.md` for validation, and `CREDITS.md` for attribution and licenses.
