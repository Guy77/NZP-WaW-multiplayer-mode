# NZP Skirmish 0.4 validation

Completed 2026-10-03 UTC. The user confirmed version 0.3 on physical Vita hardware; version 0.4 still needs a device check.

## Builds

- Release and SKIRMISH_TEST QuakeC: zero warnings, included FTEQCC, optimized standard VM target.
- Linux SDL engine: successful compile and link.
- Vita ARM engine: successful cross-compile, SELF and VPK generation. App identity remains NZPSK0001.
- Release archives contain release game logic only. No test/preview build or config.cfg is shipped in update data.

## Real-engine regressions

The final run used the actual Linux engine with isolated data/config folders and the test VM. Navigation, player weapon traces, class allowlists, blocked spawns, friendly fire, damage, kills, respawns, model synchronization, attachment reuse and match endings passed.

| Map | Match | Bot perk combat setting | Bots moved >50 units | Bot kills during combat sample | Result |
| --- | --- | --- | --- | --- | --- |
| Proving Ground | 6-bot TDM | Parting Shot | 6/6 | 12 | Pass |
| Proving Ground | 12-bot FFA | Random per spawn | 12/12 | 35 | Pass |
| Supply Depot | 6-bot TDM | Parting Shot | 6/6 | 7 | Pass |
| Supply Depot | 12-bot FFA | Random per spawn | 12/12 | 29 | Pass |

Kills are regression observations, not a balance or performance benchmark. Each run also exercises the complete perk checks before the combat sample:

- One perk or none, invalid/fractional selection sanitization, maximum health, no zombie perk bits, no third slot and future score scale fixed at 1.
- Overkill second primary and M1911 fallback when removed. Bot near/far switches preserve both magazines and update the visible model without new attachment entities.
- Dual M1911 uses semi-auto hitscan, Colt soldier damage, eight rounds per hand, 80 reserve, no upgraded flag, and consumes one round from the correct magazine for each trigger.
- Actual player fire/reload timers for Double Tap and Sleight of Hand. Double Tap bot firing is scheduled between movement ticks. No doubled damage or shot count.
- Juggernaut health/regen cap; Flak explosive reduction with unchanged bullet damage and no flop bit; Steady Aim spread multiplier; Marathon sprint limit.
- Accuracy ordering across difficulties for the complete weapon pool; moving-target penalty; short-range weapon falloff; sniper target-plane error improves with distance.
- Bot emitted sound path follows the equipped weapon, including after switches. The packaged firing recordings are verified present for both platform asset sets. Perceived audio identity/volume has not been listened to on Vita.
- Parting Shot preserves pistol/dual secondary, uses a single M1911 for knife or primary fallback, strips primary/grenades, loads only one magazine per hand and sets reserve to zero.
- Half-second protection, any subsequent positive allowed damage finalizing death, no reload/swap/regen, one kill/death award, finishing-attacker versus bleedout attribution, and respawn timing from final death.
- Five actual simulated seconds of downed player and bot thinking, with no early expiry and terminal death at the deadline within the engine tick tolerance.

Detailed evidence: `regression-run-0.4.log`, `tests-mp_test-6.log`, `tests-mp_test-12.log`, `tests-mp_depot-6.log`, `tests-mp_depot-12.log`.

## Visual checks

Rendered at 960×544 through SDL offscreen OpenGL: match settings, Overkill class menu, Parting Shot/dual-secondary class menu, and a posed downed scene. Checked menu fit, perk labels, two first-person pistols, 8/8 ammunition with no reserve, countdown, seated faction models and held sidearms. Preview fixtures are compile-time gated and excluded from release. Screenshots are in `skirmish/preview/*-0.4.png` in the source archive.

Rendering used software GL and disabled audio. It does not establish Vita frame rate, battery use, memory pressure, or audio mixing quality. Test the new version on hardware with six bots before comparing twelve.

## Packaging

The package builder validates ZIP CRCs, VPK title ID and embedded eboot identity, required models/map/audio, release/test separation, and absence of config.cfg. Archives are completed under temporary filenames and atomically renamed before checksums or upload. SHA-256 hashes accompany the downloads.
