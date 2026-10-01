# NZP Skirmish 0.2 update

Requires the existing 0.1 installation and assets.

## Changes

- Removed Wunderwaffe and flamethrower from player classes.
- Moved Ballistic Knife to secondary: Colt -> Magnum -> Ballistic Knife.
- Migrates saved knife-primary classes to a preset primary plus knife secondary at spawn. Retired/invalid weapons fall back to valid equipment.
- Increased bot angular aim error, with an additional distance penalty beyond 256 units and moving-target tracking error. Regular stationary-target spread grows from 0.068 close up to 0.170 at 1280 units (previously 0.048 at all distances). These are spread parameters, not measured hit percentages.
- Distant targets take longer to acquire; bursts are shorter with longer pauses. Recruit remains less accurate and Veteran more accurate than Regular.

## Install on Vita

Close the game. Install NZP-Skirmish.vpk through VitaShell over the existing app. Merge the update's data folder into ux0:/data, replacing progs.dat and version.txt. If using uma0: data, update that copy instead. Both VPK and game logic are required. No config.cfg is supplied, preserving saved controls/settings/classes.

## Install on Linux

Extract the Linux update over the existing 0.1 folder, replacing nzp-skirmish and nzp/progs.dat. Retain executable permission on nzp-skirmish (chmod +x nzp-skirmish if needed).

## Verification

Release/test QuakeC builds: zero warnings. Six- and twelve-bot real-engine regression tests passed; every bot moved and both matches recorded kills. Tests include new roster exclusions, knife secondary equipment and old-save migration, invalid-secondary fallback, distance/movement aim penalties and difficulty ordering, plus existing combat/respawn/match-end checks. Knife projectile firing still needs focused playtesting.

The user reports that 0.1 works on physical Vita. This 0.2 update has not yet been tested there. Bot tuning needs subjective feedback from actual play.

## Next visual work

The current player MDL has one 256x256 skin and 212 frames. Team-specific soldier art, weapon-in-hand models with matching animation poses, and additional authored maps remain future work. No new model art, animation changes or maps are included in 0.2.
