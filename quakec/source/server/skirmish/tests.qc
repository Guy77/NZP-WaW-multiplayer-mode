// Real-VM regression checks. Only included by -DSKIRMISH_TEST.
float mp_tests_phase, mp_tests_until, mp_test_item;
vector mp_tests_start[MP_MAX_ACTORS];

void(float condition, string message) MP_Assert =
{
    if (!condition) error(strcat("SKIRMISH TEST FAILED: ", message));
};

#include "perk_tests.qc"

void() MP_TestFrame =
{
    if (!mp_started) return;
    entity oldself = self;
    entity player = mp_actors[0];
    entity enemy = mp_actors[1];
    entity ally = mp_actors[2];
    float clients_before = player_count;
    if (!mp_tests_phase) {
        mp_tests_phase = 1;
        print("SKIRMISH TEST: starting real-engine regression checks\n");
        MP_Assert(mp_botcount >= 6 && mp_botcount <= 12, "bot count bounds");
        MP_Assert(mp_respawn == clamp(cvar("mp_respawn"), 1, 30), "respawn setting");
        MP_Assert(!MP_AllowedPrimary(W_RAY) && !MP_AllowedPrimary(W_RAYMK2) &&
            !MP_AllowedPrimary(W_BIATCH) && !MP_AllowedPrimary(W_AFTERBURNER) &&
            !MP_AllowedPrimary(W_CUSTOM1) && !MP_AllowedPrimary(W_TESLA) && !MP_AllowedPrimary(W_M2) && !MP_AllowedPrimary(W_BK), "forbidden weapons");
        MP_Assert(player.weapon == cvar("mp_class1_primary"), "selected class primary");
        for (float i = 1; i <= mp_botcount; i++) {
            MP_Assert(mp_actors[i] != world && mp_actors[i].mp_bot, "actor creation");
            MP_Assert(!(mp_actors[i].flags & FL_CLIENT), "bot used a client slot");
            MP_Assert(mp_actors[i].health == 100, "bot spawn health");
            MP_Assert(mp_actors[i].model == (mp_actors[i].team == 1 ? "models/skirmish/allies.mdl" : "models/skirmish/axis.mdl"), "faction model");
            MP_Assert(mp_actors[i].mp_held != world && mp_actors[i].mp_held.solid == SOLID_NOT, "held weapon creation");
            MP_Assert(mp_actors[i].mp_held.model == sprintf("models/skirmish/w%d.mdl", mp_actors[i].weapon), "held weapon matches loadout");
        }
        print(sprintf("SKIRMISH TEST: initial clients=%g actors=%g\n", player_count, mp_botcount + 1));

        MP_Assert(MP_AllowedSecondary(W_BK) && !MP_AllowedSecondary(W_TESLA) && !MP_AllowedSecondary(W_M2), "secondary allowlist");
        MP_Assert(MP_AimSpread(1, 1200, 0) > MP_AimSpread(1, 256, 0) * 2, "distance aim penalty");
        MP_Assert(MP_AimSpread(0, 900, 0) > MP_AimSpread(1, 900, 0) && MP_AimSpread(1, 900, 0) > MP_AimSpread(2, 900, 0), "difficulty ordering");
        float original_mode = mp_mode;
        mp_mode = 1;
        enemy.mp_protected = time + 1;
        MP_Damage(enemy, player, 200, DMG_TYPE_UPPERTORSO);
        MP_Assert(enemy.health == 100, "spawn protection failed");
        ally.mp_protected = 0;
        MP_Damage(ally, player, 25, DMG_TYPE_UPPERTORSO);
        MP_Assert(ally.health == 100, "friendly fire was enabled");
        enemy.mp_protected = 0;
        MP_Damage(enemy, player, 34, DMG_TYPE_UPPERTORSO);
        MP_Assert(enemy.health == 66, "damage amount");
        MP_Damage(enemy, player, 80, DMG_TYPE_UPPERTORSO);
        MP_Assert(enemy.health == 0 && enemy.mp_deaths == 1 && player.frags == 1, "kill and score");
        MP_Assert(enemy.mp_respawn_at == time + mp_respawn, "bot respawn deadline");
        MP_Damage(enemy, player, 200, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.frags == 1, "double kill scored");
        mp_mode = 0;
        MP_Damage(ally, player, 25, DMG_TYPE_UPPERTORSO);
        MP_Assert(ally.health == 75, "FFA blocked same-color damage");
        mp_mode = original_mode;

        // A wall blocks both vision and explosive damage.
        vector ppos = player.origin, apos = ally.origin;
        if (mapname == "mp_depot") {
            setorigin(player, '-500 240 32'); setorigin(ally, '-500 -240 32');
        } else {
            setorigin(player, '-500 120 32'); setorigin(ally, '-260 120 32');
        }
        MP_Assert(!MP_Visible(player, ally), "vision passed through cover");
        float savedhealth = ally.health;
        MP_Explosion(player, player, 150, 0, 400);
        MP_Assert(ally.health == savedhealth, "explosion passed through cover");
        setorigin(player, ppos); setorigin(ally, apos);

        player.mp_protected = 0;
        MP_Damage(player, enemy, 200, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.health == 0 && player.mp_respawn_at == time + mp_respawn, "player death timer");
        self = player;
        MP_PlayerThink();
        MP_Assert(player.health == 0, "player respawned before deadline");
        player.mp_respawn_at = time;
        MP_PlayerThink();
        MP_Assert(player.health == 100 && !player.deadflag && !player.downed, "player did not respawn");
        MP_Assert(player.primary_grenades == 2 && player.weapons[2].weapon_id == 0, "respawn inventory");
        MP_Assert(player_count == clients_before, sprintf("respawn changed connected player count: %g -> %g", clients_before, player_count));

        mp_tests_phase = 10;
        mp_test_item = 0;
    } else if (mp_tests_phase == 10) {
        MP_Assert(MP_Route(0, mp_test_item) >= 0, "disconnected navigation graph");
        mp_test_item++;
        if (mp_test_item >= mp_nodecount) { mp_tests_phase = 11; mp_test_item = 1; }
    } else if (mp_tests_phase == 11) {
        self = player;
        if (MP_AllowedPrimary(mp_test_item)) {
            cvar_set("mp_class1_primary", ftos(mp_test_item));
            MP_PlayerSpawn();
            MP_Assert(player.weapon == mp_test_item, "class weapon assignment failed");
        }
        mp_test_item++;
        if (mp_test_item > W_RAYMK2) mp_tests_phase = 12;
    } else if (mp_tests_phase == 12) {
        self = player;
        cvar_set("mp_class1_primary", ftos(W_BK));
        MP_PlayerSpawn();
        MP_Assert(player.weapon == W_M1 && player.weapons[1].weapon_id == W_BK, "old knife class migration");
        cvar_set("mp_class1_secondary", ftos(W_M2)); MP_PlayerSpawn();
        MP_Assert(player.weapons[1].weapon_id == W_COLT, "invalid secondary fallback");
        cvar_set("mp_class1_primary", ftos(W_RAY));
        MP_PlayerSpawn();
        MP_Assert(player.weapon == W_M1, "invalid class was not sanitized");
        cvar_set("mp_class1_primary", ftos(W_M1));
        MP_PlayerSpawn();
        // Visual state must track without allocating new attachments on respawn.
        self = enemy;
        entity held_before = enemy.mp_held;
        MP_BotSpawn(); MP_BotSpawn();
        MP_Assert(enemy.mp_held == held_before, "respawn leaked weapon attachment");
        enemy.mp_reload_start = time - 0.75; enemy.mp_reload_at = time + 0.75;
        MP_UpdateVisual();
        MP_Assert(enemy.frame == 18 && enemy.mp_held.frame == enemy.frame, "reload pose synchronization");
        enemy.mp_reload_at = 0; enemy.mp_anim_until = time + 0.2;
        MP_UpdateVisual(); MP_Assert(enemy.frame == 9, "firing pose");
        enemy.health = 0; enemy.mp_died_at = time - 2; MP_UpdateVisual();
        MP_Assert(enemy.frame == 39 && enemy.mp_held.frame == 39, "corpse pose");
        MP_BotSpawn();
        mp_tests_phase = 13;
    } else if (mp_tests_phase == 13) {
        // Exercise the actual player weapon firing path, including ammo and
        // hit traces, rather than only calling the match damage function.
        self = enemy;
        MP_BotSpawn();
        enemy.mp_protected = 0;
        setorigin(enemy, '0 -280 32');
        self = player;
        setorigin(player, '0 -520 32');
        player.v_angle = '3 90 0'; // aim inside the body, below the bbox's top edge
        player.zoom = 1;
        player.fire_delay = player.reload_delay = 0;
        player.new_anim_stop = player.NeedLoad = 0;
        float magazine_before = player.weapons[0].weapon_magazine;
        W_Fire(S_RIGHT);
        MP_Assert(player.weapons[0].weapon_magazine == magazine_before - 1, "player firing did not consume ammunition");
        MP_Assert(enemy.health < 100, "player weapon trace did not damage soldier");
        MP_PlayerSpawn(); mp_perk_test_stage = 0; mp_tests_phase = 14;
    } else if (mp_tests_phase == 14) {
        MP_TestPerks(); mp_perk_test_stage++;
        if (mp_perk_test_stage >= 5) {
            self = player; MP_SetPerk(player, MP_PERK_PARTING); player.mp_secondary = W_COLT;
            MP_BeginLastStand(player, enemy); player.flags |= FL_GODMODE;
            self = enemy; MP_SetPerk(enemy, MP_PERK_PARTING); enemy.mp_secondary = W_COLT;
            MP_BeginLastStand(enemy, player); enemy.flags |= FL_GODMODE;
            mp_tests_until = time + 5; mp_tests_phase = 15;
        }
    } else if (mp_tests_phase == 15) {
        if (time < mp_tests_until) MP_Assert(player.health == 1 && enemy.health == 1, "Parting ended before five seconds");
        else if (time >= mp_tests_until + 0.15) {
            MP_Assert(player.health == 0 && enemy.health == 0, "Parting exceeded five seconds");
            print("SKIRMISH TEST: five-second player and bot Parting Shot lifecycle passed\n");
            mp_tests_phase = 16;
        }
    } else if (mp_tests_phase == 16) {
        self = player; MP_PlayerSpawn();
        cvar_set("mp_botperk", mp_botcount == 6 ? "4" : "-1");
        for (float k = 0; k <= mp_botcount; k++) {
            self = mp_actors[k];
            if (k) MP_BotSpawn();
            self.kills = self.frags = self.mp_deaths = 0;
            mp_tests_start[k] = self.origin;
        }
        mp_tests_phase = 1;
        mp_blue = mp_red = 0;
        mp_limit = 200;
        mp_endtime = time + 180;
        mp_tests_until = time + 35;
        print("SKIRMISH TEST: rules, classes, collision, navigation, respawn passed\n");
    } else if (mp_tests_phase == 1 && time > mp_tests_until) {
        float moved = 0, total_kills = 0;
        for (float i = 1; i <= mp_botcount; i++) {
            if (vlen(mp_actors[i].origin - mp_tests_start[i]) > 50) moved++;
            total_kills += mp_actors[i].kills;
        }
        print(sprintf("SKIRMISH TEST: moved=%d/%d, bot kills=%d\n", moved, mp_botcount, total_kills));
        MP_Assert(moved >= mp_botcount - 1, "bots did not navigate");
        MP_Assert(total_kills > 0, "bots did not fight");
        MP_Assert(rounds == 0 && find(world, classname, "gameover_watcher") == world, "zombie loop leaked into skirmish");
        mp_endtime = time - 1;
        mp_tests_phase = 2;
    } else if (mp_tests_phase == 2) {
        MP_Assert(mp_finished, "time limit failed to finish match");
        self = player;
        MP_PlayerThink();
        float health_before = player.health;
        MP_Damage(player, enemy, 1000, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.health == health_before, "damage after match end");
        mp_finished = false;
        mp_endtime = time + 100;
        mp_mode = 1;
        mp_limit = 5;
        mp_blue = 5;
        mp_red = 0;
        mp_tests_phase = 3;
    } else if (mp_tests_phase == 3) {
        MP_Assert(mp_finished, "TDM kill limit failed");
        mp_finished = false;
        mp_mode = 0;
        player.frags = 5;
        mp_tests_phase = 4;
    } else if (mp_tests_phase == 4) {
        MP_Assert(mp_finished, "FFA kill limit failed");
        print("SKIRMISH TESTS PASS\n");
        localcmd("quit\n");
        mp_tests_phase = 5;
    }
    self = oldself;
};
