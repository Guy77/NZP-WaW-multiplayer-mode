# NZP Skirmish 0.3 — visual and map update

Requires an existing 0.1 or 0.2 installation. Retains all 0.2 weapon exclusions, knife-secondary support and bot balance.

## Included

- Khaki Allies and field-grey Axis uniforms; differentiated helmet proportions.
- Visible primary weapons for all 19 weapon IDs used by bots.
- Synchronized walking, firing, reloading and falling/corpse poses. Attachments are reused on respawn.
- Supply Depot: two storage buildings, flanking lanes, central passage, crates and original brick/metal/timber materials; 18 spawns and 41 navigation nodes.
- Map selection in Offline Multiplayer. Proving Ground remains available.
- Character Bios removed from the main menu.

This is a first art/animation pass using adapted NZP assets, not final historical faction models. Grips and reload motion are shared rather than weapon-specific. No new bot grenade/sidearm behaviors or objective modes are introduced.

## Vita update

Close the game. Install NZP-Skirmish.vpk over the existing app through VitaShell. Merge the included data folder into ux0:/data (or your active uma0: copy), allowing file replacement. Install both components. Keep the existing base assets. No config.cfg is included; controls, settings and classes are preserved.

Test six bots first, then twelve. Check team recognition, moving/reloading weapons, deaths and respawns, both maps, and performance during firefights. In FFA all bots are hostile regardless of uniform. The user has confirmed 0.2 on Vita; 0.3 has not yet been device-tested.

## Linux update

Extract the Linux update over the existing desktop folder. Keep nzp-skirmish executable (chmod +x nzp-skirmish if needed). Use the existing start-skirmish.sh.

## Source

The separate source archive contains modified engine/game sources, generated model assets, generator scripts, map source/WADs/BSPs, build instructions and validation evidence. Python numpy/Pillow are needed only to regenerate models; matplotlib is needed only for the geometry preview helper.
