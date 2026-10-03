# Extension notes

## Boundaries

`sv_skirmish` selects the mode. `worldspawn` initializes it after NZP's game modifiers; the match bypasses the zombie `StartFrame` loop and zombie spawn/death paths. Existing weapon handling is reused with explicit soldier damage hooks. The offline menu queues `maxplayers 1`, `listen 0`, `deathmatch 0`, `coop 0` and `map mp_test`.

There is exactly one real local client. Bots are ordinary server entities with `MOVETYPE_STEP`, `FL_MONSTER` and Skirmish-specific fields, not fake network clients. Match state lives in QuakeC. The C HUD consumes local, non-archived `mp_hud_*` cvars at five updates per second; this interface is intentionally for local play.

## Code locations

| Component | File |
| --- | --- |
| Match rules, spawn selection, classes, bot AI | `quakec/source/server/skirmish/core.qc` |
| Limits and actor fields | `quakec/source/server/skirmish/defs.qc` |
| Real-VM regression scenarios | `quakec/source/server/skirmish/tests.qc` |
| Class and match menus, archived settings | `vril-engine/source/menu/menu_skirmish.c` |
| Match HUD and visible ally labels | `vril-engine/source/render/r_hud.c` |
| Vita identity and data path | `vril-engine/Makefile.psp2`, `source/platform/psp2/sys_psp2.c` |
| Arena and textures | `skirmish/tools/generate_arena.py`, `skirmish/maps/` |

## Bot budget

The limits are 13 actors including the player and 48 navigation nodes. Bot movement/navigation is staggered at 10 Hz; fire deadlines may run between ticks to preserve Double Tap cadence; target acquisition runs every 0.3 seconds. Navigation uses a fixed 48×48 adjacency matrix and bounded breadth-first search. No bot allocates a path dynamically. Nodes connect when close enough and both shoulder traces are unobstructed. This is suitable for the flat test arena, not a general navigation mesh.

Bots prefer enemies they see in a broad forward arc; nearby soldiers may be noticed outside it. Incoming damage supplies the attacker's last location, not permission to shoot through walls. After losing sight, bots remember a position for two seconds. Reaction delay, spread and burst length vary by difficulty. Magazines and reload times come from NZP weapon definitions. Reloading bots try a hidden nearby waypoint. Ordinary obstacle recovery changes direction and eventually abandons a blocked pursuit.

Team presets choose among Rifleman (Garand), Assault (Thompson), Support (BAR), Breacher (Trench Gun) and Scout (scoped Kar). Presets describe weapon roles, not historically exact faction arsenals. Randomized bots use base period ballistic weapons. Overkill bots can switch primaries based on range, saving separate magazine counts. Parting Shot equips the secondary with no reload.

## Settings

| Cvar | Default | Meaning |
| --- | --- | --- |
| `mp_mode` | 1 | 1 = Team Deathmatch, 0 = Free-for-All |
| `mp_bots` | 6 | Bot count, clamped to 6–12 |
| `mp_loadouts` | 0 | 0 = soldier presets, 1 = randomized period primaries |
| `mp_skill` | 1 | 0 recruit, 1 regular, 2 veteran |
| `mp_respawn` | 5 | Seconds, clamped to 1–30 |
| `mp_scorelimit` | 50 | Match score limit, clamped to 5–200 |
| `mp_minutes` | 10 | Time limit, clamped to 1–30 minutes |
| `mp_class` | 0 | Active class index, 0–4 |
| `mp_class1_primary` … `mp_class5_primary` | role dependent | Explicitly validated base weapon ID |
| `mp_class1_secondary` … `mp_class5_secondary` | 1,1,4,1,1 | Colt 1, Magnum 4, Dual M1911 28 or Ballistic Knife 6; Overkill permits primary IDs |

The menu weapon IDs, `MP_AllowedPrimary` and `weapons.json` must agree when expanding the pool. Do not replace the explicit allowlist with a broad numeric range: upgraded and special IDs are interleaved.

## Adding maps

Use BSP30, with `info_mp_spawn` entities (team 1 Allies, team 2 Axis, or 0 universal) and `info_mp_node` entities. Place spawn and node origins at standing-player origin height above the floor. Supply enough unoccupied spawn locations; a blocked spawn is retried after 0.5 seconds. Keep the node count at or below 48 and check all routes before distributing a map. The setup menu now selects mp_test or mp_depot via archived mp_map (0 or 1).

Proving Ground has 18 team spawns and 35 nodes; Supply Depot has 18 spawns and 41 nodes; its textures are embedded into the BSP. No stock zombie map is claimed to support this navigation or spawn schema.

## Next work

First collect hardware results for six and twelve bots, including memory and worst-case frame time during firefights and explosions. Then improve enemy silhouettes/faction uniforms, visible weapon animations, sidearm and grenade use, cover selection, reload feedback and class editing. Future killstreaks and perk point penalties should use the reserved score policy after the combat loop is balanced.

## 0.3 model pipeline

`tools/build_soldiers.py` reads native MDLs with `mdl_tools.py`, preserves skin/face detail while adapting uniform materials, adjusts Axis helmet proportions, and exports 41-pose bot variants. `generated/models/skirmish/` contains the ready-to-use assets. It bakes 22 bot weapon meshes, including single and dual sidearms to the right-hand vertex cluster, using rigid transforms calculated offline. External weapon skins are copied unchanged when present. Runtime code uses a static model-path allowlist and reuses one non-solid held-weapon entity per bot. The body and weapon share origins, angles and pose indices.

Pose priorities: death, downed (frame 40), reload, recent fire, walk, idle. Death uses an eight-frame fall ending in a ground pose. Reload remains a shared animation, not a unique magazine manipulation for each firearm. Body hitboxes are explicitly reset after assigning visual models. The first-person player model/weapon handling remains upstream.

`SKIRMISH_PREVIEW` enables deterministic posed screenshot fixtures only in a separate QA compilation; release/test scripts do not define it.

## 0.4 perk and damage boundaries

`mp_class1_perk` through `mp_class5_perk` are archived single selections: none 0, Double Tap 1, Sleight of Hand 2, Juggernaut 3, Parting Shot 4, Steady Aim 5, Flak Jacket 6, Overkill 7, Marathon 8. `mp_botperk` uses the same IDs, with -1 for random. Defaults are zero. The per-life selection is copied into `.mp_perk`; `.perks` stays zero to avoid upstream revive, damage duplication, flop, and third-slot effects.

`MP_SetPerk` initializes maximum health and the reserved `.mp_score_scale`. `MP_ScoreScale` returns 1 for every perk; no score economics are implemented. Keep kill counts separate from any future earned-point event.

`MP_BeginLastStand` and `MP_FinalDeath` form a separate Parting Shot lifecycle. Lethal damage sets one health, a five-second deadline, a half-second protection deadline and a stored downing attacker. Any later positive allowed damage finalizes death. The player think path exposes only weapon animation and firearm inputs. PostThink regeneration is bypassed. Bots have a separate stationary firing path with an empty-magazine stop. Final death alone increments deaths/kills and starts the respawn timer.

Shared weapon definitions condition the ID 28 conversion on server `mp_active`: normal Colt bullet behavior and eight-round magazines, with existing dual viewmodels. Zombie mode retains original Mustang & Sally behavior. Server hooks implement fire/reload/spread/sprint changes without using the zombie perk bitmask.

`perk_tests.qc` is included only through the `SKIRMISH_TEST` suite. Tests are spread over separate frames to stay below the VM instruction budget with twelve bots.
