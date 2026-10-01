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

The limits are 13 actors including the player and 48 navigation nodes. Bot thinking is staggered at 10 Hz; target acquisition runs every 0.3 seconds. Navigation uses a fixed 48×48 adjacency matrix and bounded breadth-first search. No bot allocates a path dynamically. Nodes connect when close enough and both shoulder traces are unobstructed. This is suitable for the flat test arena, not a general navigation mesh.

Bots prefer enemies they see in a broad forward arc; nearby soldiers may be noticed outside it. Incoming damage supplies the attacker's last location, not permission to shoot through walls. After losing sight, bots remember a position for two seconds. Reaction delay, spread and burst length vary by difficulty. Magazines and reload times come from NZP weapon definitions. Reloading bots try a hidden nearby waypoint. Ordinary obstacle recovery changes direction and eventually abandons a blocked pursuit.

Team presets choose among Rifleman (Garand), Assault (Thompson), Support (BAR), Breacher (Trench Gun) and Scout (scoped Kar). Presets describe weapon roles, not historically exact faction arsenals. Randomized bots use base period ballistic weapons. The current AI fires its primary only.

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
| `mp_class1_secondary` … `mp_class5_secondary` | 1,1,4,1,1 | Colt 1 or Magnum 4 |

The menu weapon IDs, `MP_AllowedPrimary` and `weapons.json` must agree when expanding the pool. Do not replace the explicit allowlist with a broad numeric range: upgraded and special IDs are interleaved.

## Adding maps

Use BSP30, with `info_mp_spawn` entities (team 1 Allies, team 2 Axis, or 0 universal) and `info_mp_node` entities. Place spawn and node origins at standing-player origin height above the floor. Supply enough unoccupied spawn locations; a blocked spawn is retried after 0.5 seconds. Keep the node count at or below 48 and check all routes before distributing a map. Add map selection to the setup menu when a second arena is ready.

The included map has 18 team spawns and 35 nodes; its textures are embedded into the BSP. No stock zombie map is claimed to support this navigation or spawn schema.

## Next work

First collect hardware results for six and twelve bots, including memory and worst-case frame time during firefights and explosions. Then improve enemy silhouettes/faction uniforms, visible weapon animations, sidearm and grenade use, cover selection, reload feedback and class editing. Killstreaks and perks should build on verified death/score events after the core combat loop is balanced.
