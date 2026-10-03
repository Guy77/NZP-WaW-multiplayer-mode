# NZP Skirmish 0.4 — weapons and single-perk classes

Cumulative update for an existing NZP Skirmish 0.1, 0.2 or 0.3 installation. The user confirmed 0.3 works on Vita. Version 0.4 is cross-compiled and desktop-tested; hardware testing of this update is still needed.

## Install on Vita

Close the game. Install `NZP-Skirmish.vpk` through VitaShell over the existing app. Merge the included `data` folder into `ux0:/data`, replacing its files. If the active installation is on `uma0:`, update that copy instead. Install both the VPK and data. Keep the existing base assets. This archive contains no `config.cfg`, so saved controls and classes are preserved.

## Added

- Bots use the equipped weapon's NZP firing sound, on their own weapon channel. Switching guns updates sound and visible model together. Some NZP weapon families intentionally share a source recording.
- **Dual M1911** secondary: the Mustang & Sally viewmodels, converted to ordinary semi-automatic bullets with Colt damage, eight rounds per hand and 80 reserve rounds. L/R fire the respective hand on Vita.
- Weapon-specific bot accuracy. Scoped and bolt-action rifles favor long range and have more aiming error at close range. Shotguns, SMGs and every secondary favor close range and lose accuracy sharply with distance. Other rifles and machine guns suit short/medium range and lose accuracy at long range. Difficulty, moving targets, reaction delays and bursts still matter.
- **Create a Class → Perk** selects one perk or no perk. Changes apply at the next spawn. **Offline Multiplayer → Bot Perks** offers none, a random selection on each spawn (including none), or one fixed perk for all bots.

| Perk | Effect |
| --- | --- |
| No perk | Standard stats. Reserved future score multiplier is 1.0. |
| Double Tap | 33% higher fire rate; no damage or pellet-count increase. |
| Sleight of Hand | Reloads take half the normal time. |
| Juggernaut | 150 maximum health instead of 100; regeneration respects this maximum. |
| Parting Shot | Five seconds downed, with 0.5 seconds of protection during the transition. Any positive damage afterward kills; team friendly-fire rules still apply. Secondary only, one full magazine per hand, zero reserve. Ballistic Knife or a primary falls back to a single M1911. No revival or upgraded weapon. |
| Steady Aim | 35% less player hip-fire spread and bot aiming spread. |
| Flak Jacket | 50% less explosive damage. No explosive flop. |
| Overkill | A second primary replaces the secondary. Removing it restores the M1911 secondary. Bots switch between primaries according to range and keep separate magazines. |
| Marathon | Double player sprint duration; bots move 10% faster. |

Parting Shot awards the kill only on final death. A finishing attacker receives the kill; a bleedout credits the original attacker. Respawn delay starts at final death. Downed actors cannot reload, regenerate health, switch weapons, use grenades or melee. Standing bots still have unlimited reserve ammunition; downed bots cannot refill their magazine.

The HUD displays the selected perk and the Parting Shot countdown. Downed bots use a seated pose and visible sidearm. Generated bodies and held weapons now have 41 poses. Weapon grips and reloads continue to use shared animations.

## Points and future work

The single perk ID is separate from the original zombie perk bitmask. A dedicated score-scale policy is reserved internally and currently returns 1.0 for every selection. Currency, perk penalties and killstreaks are not enabled. Existing kill counts and match limits remain ordinary kill counts.

## Validation and suggested hardware check

Release and test game logic compile with zero warnings. Linux and Vita engines build successfully. Real-engine tests cover both maps with six-bot TDM and twelve-bot FFA, perk effects, dual triggers, weapon/sound identity, range profiles, Overkill magazines, transition protection, final damage, score attribution and actual five-second downed lifetimes. See `TEST_REPORT.md`.

On Vita, try Dual M1911 with both triggers, each perk through Create a Class, Parting Shot while firing/reloading, Overkill removal, and random bot perks. Check the gun sounds and six/twelve-bot performance on your device.

## Linux

Extract the Linux update over the existing desktop installation. Keep `nzp-skirmish` executable (`chmod +x nzp-skirmish` if needed) and use the existing launcher.
