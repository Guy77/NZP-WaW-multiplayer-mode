# 0.3 validation — 2026-10-02

Release and regression QuakeC: zero warnings. Linux and Vita engine builds completed.

| Map | Mode / bots | Moved | Bot kills | Result |
| --- | --- | --- | --- | --- |
| Proving Ground | TDM / 6 | 6/6 | 10 | Pass |
| Proving Ground | FFA / 12 | 12/12 | 33 | Pass |
| Supply Depot | TDM / 6 | 6/6 | 8 | Pass |
| Supply Depot | FFA / 12 | 12/12 | 34 | Pass |

These are regression activity counts, not controlled balance measurements.

Assertions cover existing rules, allowed/forbidden equipment, old knife-class migration, friendly fire, spawn protection, cover, navigation connectivity, actual rifle shots, respawn, scoring and match limits. New assertions cover faction model assignment, correct equipped weapon model, non-solid attachments, attachment reuse on repeated respawns, synchronized reload/fire/corpse frames, and retained 0.2 aim penalties.

Native model generation exports two 801-vertex / 940-triangle body variants with 40 poses and 19 held-weapon models. Asset files total 790,811 bytes. This does not measure runtime graphics memory or device performance.

Rendered desktop QA uses software OpenGL at 960x544. Posed faction and reload screenshots use the SKIRMISH_PREVIEW test-only fixture; they are not spontaneous combat screenshots. Menus were inspected for map-row layout and removal of Character Bios. The final release depot is also boot-smoke-tested with twelve bots and a 64 MB engine heap. No Vita performance claim follows from that desktop check.

0.1 and 0.2: user-confirmed physical Vita operation. 0.3: cross-compiled only; needs physical Vita testing. Shared reload/grip poses and lightly differentiated model silhouettes remain prototype art.
