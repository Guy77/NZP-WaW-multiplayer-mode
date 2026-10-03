# NZP Skirmish 0.4.1 — Vita menu crash fix and full recovery

## What caused the menu crash

Version 0.4 added a twelfth Offline Multiplayer button while the engine still allocated eleven button slots. Drawing Back indexed past the array. AddressSanitizer reproduces a global-buffer-overflow in `Menu_DrawButton`, called by `Menu_Skirmish_Draw`. This could corrupt adjacent menu state when opening Offline Multiplayer or returning there from Create a Class.

0.4.1 expands the array to sixteen slots and checks button indices before drawing, registering or configuring sliders. Create a Class also remembers whether it was opened from Main, Offline Multiplayer or Pause and returns to that menu.

The 0.4 gameplay additions remain: dual normal-bullet M1911s, weapon-dependent bot accuracy and sounds, and one optional perk for players/bots.

## Full recovery installation

This is a COMPLETE DATA package, not an update-only overlay. Use it if data was deleted, reset, or is incomplete.

1. Close the game. Keep the existing app installed.
2. Rename the existing `ux0:/data/nzp-skirmish` folder to `nzp-skirmish-backup` if present. This preserves old logs and settings while preventing mixed files.
3. Extract the archive and copy its complete `data/nzp-skirmish` folder into `ux0:/data`. For example, game logic must be at `ux0:/data/nzp-skirmish/nzp/progs.dat`; `gfx`, `models`, `sounds`, maps and configuration files must also be present under that `nzp` folder.
4. Install the included `NZP-Skirmish.vpk` through VitaShell over the existing application, then launch it.
5. Initially use the supplied fresh configuration. Test Main → Create a Class → Back, Offline Multiplayer → Create a Class → Back, and then a six-bot match before restoring any old configuration.

If you previously used `uma0:`, perform the same folder replacement there instead. The app prefers `uma0:/data/nzp-skirmish/nzp/progs.dat` when present. A stale partial installation there can therefore take precedence over a fresh `ux0:` copy; rename that stale folder if you are switching back to `ux0:`.

The application ID remains `NZPSK0001`. The normal Vita homebrew prerequisites remain unchanged, including your existing `libshacccg.suprx`. That Sony system module is not distributed here.

## Validation

- Reproduced the original 0.4 out-of-bounds access using AddressSanitizer and the real rendered menus.
- Passed 20 repeated menu-navigation cycles after the fix, including the twelfth button, cursor wrapping, Bot Perks, class return via Back key and Back button, and pause/class return.
- Confirmed negative/out-of-range button and slider indices are rejected without changing menu state.
- Repeated the menu test with no saved config using the Vita asset tree.
- Fresh Vita build directory, executable/VPK identity checks, and ZIP CRC and SHA-256 checks.

These are desktop/sanitizer checks and a Vita cross-build. The fix still needs confirmation on the physical Vita. If it still crashes, retain the crash message/code and attach `data/nzp-skirmish/log.txt` from the active drive (if created); specify whether the failure is before Main or at a particular menu action.
