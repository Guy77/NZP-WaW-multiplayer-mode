// NZP Skirmish prototype. GPL-2.0-or-later; see repository LICENSE.
// Bounded navigation and staggered 10 Hz bots for Vril (desktop and Vita).

float(float a, float b) MP_Min = { return a < b ? a : b; };
float(float a, float b) MP_Max = { return a > b ? a : b; };

void() info_mp_spawn = {};
void() info_mp_node = {};

float(float weapon) MP_AllowedPrimary =
{
    // Explicit allowlist: no upgraded IDs, either Ray Gun, or custom weapons.
    switch (weapon) {
        case W_KAR: case W_THOMPSON: case W_BAR: case W_BROWNING:
        case W_DB: case W_FG: case W_GEWEHR: case W_KAR_SCOPE:
        case W_M1: case W_M1A1: case W_MP40: case W_MG:
        case W_PANZER: case W_PPSH: case W_PTRS: case W_SAWNOFF:
        case W_STG: case W_TRENCH: case W_TYPE: case W_SPRING:
        case W_MP5K: return true;
    }
    return false;
};

float(float weapon) MP_AllowedSecondary = { return weapon == W_COLT || weapon == W_357 || weapon == W_BK || weapon == W_BIATCH; };
float(float skill, float distance, float speed) MP_AimSpread =
{
    float range = clamp((distance - 256) / 1024, 0, 1);
    return (0.09 - skill * 0.022) * (1 + range * 1.5)
        + clamp(speed / 240, 0, 1) * (0.025 - skill * 0.006);
};

float(float perk) MP_ValidPerk = { if (perk != floor(perk) || perk < 0 || perk > 8) return 0; return perk; };
float(entity actor, float delay) MP_FireDelay = { return actor.mp_perk == MP_PERK_DOUBLE ? delay / 1.33 : delay; };
float(entity actor, float delay) MP_ReloadDelay = { return actor.mp_perk == MP_PERK_SLEIGHT ? delay * 0.5 : delay; };
float(entity actor) MP_SpreadScale = { return actor.mp_perk == MP_PERK_STEADY ? 0.65 : 1; };
float(entity actor, float duration) MP_SprintLimit = { return actor.mp_perk == MP_PERK_MARATHON ? duration * 2 : duration; };
float(entity actor) MP_MoveScale = { return actor.mp_perk == MP_PERK_MARATHON ? 1.1 : 1; };
// Reserved policy: no currency or perk scoring penalties enabled yet.
float(float perk) MP_ScoreScale = { return 1; };
void(entity actor, float perk) MP_SetPerk =
{
    actor.mp_perk = MP_ValidPerk(perk);
    actor.mp_score_scale = MP_ScoreScale(actor.mp_perk);
    actor.max_health = actor.mp_perk == MP_PERK_JUGGERNAUT ? 150 : 100;
    actor.health = actor.max_health;
    actor.perks = 0;
};
float(float perk, float weapon) MP_SecondaryAllowed =
{
    return perk == MP_PERK_OVERKILL ? MP_AllowedPrimary(weapon) : MP_AllowedSecondary(weapon);
};
string(float perk) MP_PerkName =
{
    switch (perk) {
        case 1: return "Double Tap";
        case 2: return "Sleight of Hand";
        case 3: return "Juggernaut";
        case 4: return "Parting Shot";
        case 5: return "Steady Aim";
        case 6: return "Flak Jacket";
        case 7: return "Overkill";
        case 8: return "Marathon";
    }
    return "No perk";
};
float(float weapon) MP_RangeGroup =
{
    switch (weapon) {
        case W_KAR: case W_KAR_SCOPE: case W_SPRING: case W_PTRS: return 2;
        case W_DB: case W_SAWNOFF: case W_TRENCH:
        case W_COLT: case W_357: case W_BIATCH: case W_BK:
        case W_THOMPSON: case W_MP40: case W_PPSH: case W_TYPE: case W_MP5K: return 0;
    }
    return 1;
};
float(float weapon, float skill, float distance, float speed) MP_WeaponSpread =
{
    float group = MP_RangeGroup(weapon), spread;
    // Sniper target-plane error shrinks from 55 to 26 units with range.
    // This reduces close-range hit probability, not only angular precision.
    if (group == 2) spread = (55 - 29 * clamp((distance - 128) / 896, 0, 1)) / MP_Max(64, distance);
    else if (group == 0) spread = 0.035 + 0.14 * clamp((distance - 192) / 640, 0, 1)
        + 0.08 * clamp((distance - 832) / 768, 0, 1);
    else spread = 0.05 + 0.035 * clamp((distance - 256) / 512, 0, 1)
        + 0.13 * clamp((distance - 768) / 832, 0, 1);
    return spread * (1.35 - clamp(skill, 0, 2) * 0.35)
        + clamp(speed / 240, 0, 1) * (0.025 - clamp(skill, 0, 2) * 0.006);
};

string(float weapon) MP_HeldModel =
{
    switch (weapon) {
        case 1: return "models/skirmish/w1.mdl";
        case 4: return "models/skirmish/w4.mdl";
        case 28: return "models/skirmish/w28.mdl";
        case 2: return "models/skirmish/w2.mdl";
        case 3: return "models/skirmish/w3.mdl";
        case 5: return "models/skirmish/w5.mdl";
        case 7: return "models/skirmish/w7.mdl";
        case 8: return "models/skirmish/w8.mdl";
        case 9: return "models/skirmish/w9.mdl";
        case 10: return "models/skirmish/w10.mdl";
        case 11: return "models/skirmish/w11.mdl";
        case 12: return "models/skirmish/w12.mdl";
        case 13: return "models/skirmish/w13.mdl";
        case 15: return "models/skirmish/w15.mdl";
        case 16: return "models/skirmish/w16.mdl";
        case 18: return "models/skirmish/w18.mdl";
        case 19: return "models/skirmish/w19.mdl";
        case 21: return "models/skirmish/w21.mdl";
        case 22: return "models/skirmish/w22.mdl";
        case 23: return "models/skirmish/w23.mdl";
        case 24: return "models/skirmish/w24.mdl";
        case 58: return "models/skirmish/w58.mdl";
    }
    return "models/skirmish/w12.mdl";
};

float(float role) MP_Preset =
{
    switch (role) {
        case 0: return W_M1;
        case 1: return W_THOMPSON;
        case 2: return W_BAR;
        case 3: return W_TRENCH;
        case 4: return W_KAR_SCOPE;
    }
    return W_GEWEHR;
};

float(float weapon) MP_ShotDamage =
{
    // Shared soldier balance for player and bots; zombie health scales differ.
    switch (weapon) {
        case W_KAR: case W_KAR_SCOPE: case W_SPRING: case W_PTRS: return 75;
        case W_M1: case W_GEWEHR: return 40;
        case W_M1A1: return 32;
        case W_BAR: case W_FG: case W_STG: return 34;
        case W_BROWNING: case W_MG: return 30;
        case W_DB: case W_SAWNOFF: case W_TRENCH: return 12; // per pellet
        case W_357: return 45;
        case W_COLT: case W_BIATCH: return 28;
        default: return 25;
    }
};

float(entity a, entity b) MP_Hostile =
{
    if (!a.mp_actor || !b.mp_actor || a == b || b.health <= 0)
        return false;
    return !mp_mode || a.team != b.team;
};

float(entity a, entity b) MP_Visible =
{
    traceline(a.origin + a.view_ofs, b.origin + b.view_ofs * 0.7, false, a);
    return trace_ent == b || trace_fraction == 1;
};

float(vector org) MP_NearestNode =
{
    float best = -1, distance = 100000;
    for (float i = 0; i < mp_nodecount; i++) {
        float d = vlen(org - mp_nodes[i].origin);
        if (d < distance) {
            traceline(org, mp_nodes[i].origin, true, self);
            if (trace_fraction == 1) { best = i; distance = d; }
        }
    }
    return best;
};

void() MP_BuildNavigation =
{
    entity node = find(world, classname, "info_mp_node");
    while (node != world && mp_nodecount < MP_MAX_NODES) {
        mp_nodes[mp_nodecount] = node;
        mp_nodecount++;
        node = find(node, classname, "info_mp_node");
    }
    if (mp_nodecount < 2)
        error("Skirmish requires at least two info_mp_node entities. Use mp_test.\n");
    // Check both shoulders; point-only traces can link paths too narrow to walk.
    for (float i = 0; i < mp_nodecount; i++) {
        for (float j = i + 1; j < mp_nodecount; j++) {
            vector delta = mp_nodes[j].origin - mp_nodes[i].origin;
            if (vlen(delta) > 410 || fabs(delta_z) > 16) continue;
            vector side = normalize([-delta_y, delta_x, 0]) * 20;
            traceline(mp_nodes[i].origin + side, mp_nodes[j].origin + side, true, world);
            if (trace_fraction != 1) continue;
            traceline(mp_nodes[i].origin - side, mp_nodes[j].origin - side, true, world);
            if (trace_fraction != 1) continue;
            mp_links[i * MP_MAX_NODES + j] = 1;
            mp_links[j * MP_MAX_NODES + i] = 1;
        }
    }
};

// Returns the next node along a breadth-first route; no per-bot allocations.
float(float start, float goal) MP_Route =
{
    if (start < 0 || goal < 0 || start >= mp_nodecount || goal >= mp_nodecount) return -1;
    if (start == goal) return goal;
    for (float i = 0; i < mp_nodecount; i++) mp_parent[i] = -1;
    float head = 0, tail = 1;
    mp_queue[0] = start;
    mp_parent[start] = start;
    while (head < tail && tail <= MP_MAX_NODES) {
        float node = mp_queue[head]; head++;
        for (float n = 0; n < mp_nodecount; n++) {
            if (!mp_links[node * MP_MAX_NODES + n] || mp_parent[n] != -1) continue;
            mp_parent[n] = node;
            if (n == goal) {
                float next = n;
                for (float guard = 0; guard < MP_MAX_NODES; guard++) {
                    if (mp_parent[next] == start) return next;
                    next = mp_parent[next];
                }
                return -1;
            }
            mp_queue[tail] = n; tail++;
        }
    }
    return -1;
};

// Prefer unoccupied team spawns with distance and cover from living opponents.
// When all are blocked, leave the actor dead and retry instead of telefragging.
float() MP_Place =
{
    entity spot = find(world, classname, "info_mp_spawn"), best = world;
    float bestscore = -100000;
    while (spot != world) {
        if (!mp_mode || !spot.team || spot.team == self.team) {
            float nearest = 2000, exposed = 0, blocked = false;
            for (float i = 0; i <= mp_botcount; i++) {
                entity actor = mp_actors[i];
                if (actor == world || actor == self || actor.health <= 0) continue;
                float d = vlen(actor.origin - spot.origin);
                if (d < 72) blocked = true;
                if (MP_Hostile(self, actor)) {
                    nearest = MP_Min(nearest, d);
                    traceline(spot.origin, actor.origin + actor.view_ofs, true, self);
                    if (trace_fraction == 1) exposed++;
                }
            }
            float score = nearest - exposed * 250 + random() * 90;
            if (!blocked && score > bestscore) { bestscore = score; best = spot; }
        }
        spot = find(spot, classname, "info_mp_spawn");
    }
    if (best == world) return false;
    setorigin(self, best.origin);
    self.angles = best.angles;
    self.v_angle = best.angles;
    self.velocity = '0 0 0';
    self.fixangle = true;
    return true;
};

void() MP_ResetActor =
{
    self.health = self.max_health = 100;
    self.frame = 0;
    self.deadflag = DEAD_NO;
    self.takedamage = DAMAGE_AIM;
    self.solid = SOLID_SLIDEBOX;
    self.downed = false;
    self.mp_laststand = self.mp_bleedout_at = 0;
    self.mp_down_attacker = world;
    self.mp_burst = self.mp_ai_at = 0;
    self.is_spectator = false;
    self.mp_respawn_at = 0;
    self.mp_protected = time + 1.5;
    self.health_delay = time + 3;
    self.enemy = world;
    self.mp_goal = -1;
    self.mp_memory_until = 0;
    self.mp_reload_at = 0;
    self.mp_stuck = 0;
    self.view_ofs = VIEW_OFS_HL;
    setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
    if (self.mp_bot) setmodel(self, self.team == 1 ? "models/skirmish/allies.mdl" : "models/skirmish/axis.mdl");
    else setmodel(self, "models/player.mdl");
    setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
    self.mp_anim_until = self.mp_reload_start = self.mp_died_at = 0;
};

// One reused, non-solid visual entity per bot. Frames are baked to the body's
// right-hand motion, so Vita needs no skeletal mesh or per-frame attachment math.
void() MP_UpdateVisual =
{
    if (self.health <= 0) self.frame = 32 + clamp(floor((time - self.mp_died_at) * 10), 0, 7);
    else if (self.mp_laststand) self.frame = 40;
    else if (self.mp_reload_at) self.frame = 11 + clamp(floor((time - self.mp_reload_start) /
        MP_Max(0.1, self.mp_reload_at - self.mp_reload_start) * 14), 0, 13);
    else if (self.mp_anim_until > time) self.frame = time > self.mp_anim_until - 0.1 ? 10 : 9;
    else if (vlen(self.origin - self.mp_visual_origin) > 1) self.frame = 1 + floor(time * 10 + self.mp_index) % 8;
    else self.frame = 0;
    self.mp_visual_origin = self.origin;
    if (self.mp_held != world) {
        setorigin(self.mp_held, self.origin);
        self.mp_held.angles = self.angles;
        self.mp_held.frame = self.frame;
    }
};

void() MP_PlayerSpawn =
{
    self.mp_actor = true;
    self.mp_index = 0;
    self.team = 1;
    mp_actors[0] = self;
    MP_ResetActor();
    self.classname = "player";
    self.flags = FL_CLIENT;
    self.movetype = MOVETYPE_WALK;
    self.playernum = 1;
    local_client = self;
    if (!MP_Place()) {
        self.health = 0; self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_NONE; self.mp_respawn_at = time + 0.5;
        return;
    }
    self.stance = PLAYER_STANCE_STAND;
    self.new_ofs_z = self.view_ofs_z;
    self.oldz = self.origin_z;
    self.stamina = 4;
    self.perks = self.reviving = self.downedloop = 0;
    self.sprinting = self.zoom = self.semi_actions = 0;
    self.weapon_burst_count = 0;
    self.isBuying = false;
    self.pri_grenade_state = 0;
    self.primary_grenades = 2;
    self.secondary_grenades = -1;
    self.grenades = 1;
    self.onfire = false;
    self.has_bowie_knife = false;
    self.think = SUB_Null;
    self.nextthink = -1;
    self.weapon2model = "";
    for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
        self.weapons[i].weapon_id = 0;
        self.weapons[i].is_mulekick_weapon = false;
    }
    float slot = floor(clamp(cvar("mp_class"), 0, 4));
    float primary = cvar(sprintf("mp_class%d_primary", slot + 1));
    float secondary = cvar(sprintf("mp_class%d_secondary", slot + 1));
    if (primary == W_BK) secondary = W_BK;
    if (!MP_AllowedPrimary(primary)) primary = MP_Preset(slot);
    MP_SetPerk(self, cvar(sprintf("mp_class%d_perk", slot + 1)));
    if (!MP_SecondaryAllowed(self.mp_perk, secondary))
        secondary = self.mp_perk == MP_PERK_OVERKILL ? MP_Preset((slot + 1) % 5) : W_COLT;
    self.mp_primary = primary; self.mp_secondary = secondary;
    cvar_set(sprintf("mp_class%d_perk", slot + 1), ftos(self.mp_perk));
    cvar_set(sprintf("mp_class%d_primary", slot + 1), ftos(primary));
    cvar_set(sprintf("mp_class%d_secondary", slot + 1), ftos(secondary));
    Weapon_AssignWeapon(0, secondary, 0, 0, 0);
    Weapon_AssignWeapon(1, primary, 0, 0, 0); // active weapon is swapped to slot 0
    self.fire_delay = self.fire_delay2 = self.reload_delay = self.reload_delay2 = time + 0.6;
    self.knife_delay = self.switch_delay = time + 0.6;
    nzp_setclientmode(GAMEMODE_CLASSIC);
    nzp_screenflash(self, SCREENFLASH_COLOR_BLACK, 0.3, SCREENFLASH_FADE_OUT);
};

void() MP_BotSpawn =
{
    if (!MP_Place()) { self.mp_respawn_at = time + 0.5; return; }
    MP_ResetActor();
    self.classname = "mp_bot";
    self.flags = FL_MONSTER;
    self.movetype = MOVETYPE_STEP;
    self.mp_primary = MP_Preset(floor(random() * 5));
    if (mp_loadouts) {
        // Period, ballistic weapons only. Special weapons use different AI.
        float weapons[20] = {W_KAR, W_THOMPSON, W_BAR, W_BROWNING, W_DB,
            W_FG, W_GEWEHR, W_KAR_SCOPE, W_M1, W_M1A1, W_MP40, W_MG,
            W_PPSH, W_PTRS, W_SAWNOFF, W_STG, W_TRENCH, W_TYPE, W_SPRING, W_GEWEHR};
        self.mp_primary = weapons[floor(random() * 20)];
    }
    float selection = cvar("mp_botperk");
    MP_SetPerk(self, selection == -1 ? floor(random() * 9) : selection);
    self.mp_secondary = random() < 0.25 ? W_BIATCH : random() < 0.33 ? W_357 : W_COLT;
    if (self.mp_perk == MP_PERK_OVERKILL) {
        self.mp_secondary = MP_Preset(floor(random() * 5));
        if (self.mp_secondary == self.mp_primary) self.mp_secondary = self.mp_primary == W_TRENCH ? W_KAR_SCOPE : W_TRENCH;
    }
    self.mp_other_clip = getWeaponMag(self.mp_secondary);
    self.mp_switch_at = time + 1;
    self.weapon = self.mp_primary;
    self.mp_clip = getWeaponMag(self.weapon);
    self.mp_fire_at = time + 1;
    self.mp_scan_at = time + self.mp_index * 0.02;
    if (self.mp_held == world) {
        self.mp_held = spawn();
        self.mp_held.classname = "mp_held_weapon";
        self.mp_held.owner = self;
        self.mp_held.solid = SOLID_NOT;
        self.mp_held.movetype = MOVETYPE_NONE;
    }
    setmodel(self.mp_held, MP_HeldModel(self.weapon));
    self.mp_visual_origin = self.origin;
    MP_UpdateVisual();
};

void(entity victim, entity attacker) MP_FinalDeath =
{
    if (victim.deadflag == DEAD_DEAD) return;
    victim.mp_laststand = 0;
    victim.health = 0;
    victim.mp_deaths++;
    victim.deadflag = DEAD_DEAD;
    victim.takedamage = DAMAGE_NO;
    victim.solid = SOLID_NOT;
    victim.movetype = MOVETYPE_NONE;
    victim.velocity = '0 0 0';
    victim.weaponmodel = victim.weapon2model = "";
    victim.mp_died_at = time;
    victim.frame = victim.mp_bot ? 32 : 38;
    victim.mp_respawn_at = time + mp_respawn;
    if (!victim.mp_bot) {
        victim.think = SUB_Null;
        victim.nextthink = -1;
        victim.zoom = victim.sprinting = 0;
    }
    if (attacker.mp_actor && attacker != victim) {
        attacker.kills++;
        attacker.frags++;
        if (attacker.team == 1) mp_blue++; else mp_red++;
    } else {
        victim.frags = MP_Max(0, victim.frags - 1);
    }
};

void(entity victim, entity attacker) MP_BeginLastStand =
{
    entity savedself = self;
    self = victim;
    self.mp_laststand = true;
    self.mp_bleedout_at = time + 5;
    self.mp_protected = time + 0.5;
    self.mp_down_attacker = attacker;
    self.health = 1;
    self.mp_reload_at = self.mp_anim_until = 0;
    self.velocity = '0 0 0'; self.movetype = MOVETYPE_NONE; self.maxspeed = 0;
    self.view_ofs = '0 0 8'; self.new_ofs_z = 8;
    setsize(self, PLAYER_MINS_STANDING, '16 16 16');
    float sidearm = self.mp_secondary;
    if (!MP_AllowedSecondary(sidearm) || sidearm == W_BK) sidearm = W_COLT;
    if (self.mp_bot) {
        self.weapon = sidearm;
        self.mp_clip = getWeaponMag(sidearm) * (IsDualWeapon(sidearm) ? 2 : 1);
        self.mp_fire_at = time + 0.5;
        setmodel(self.mp_held, MP_HeldModel(sidearm));
        MP_UpdateVisual();
    } else {
        self.zoom = self.sprinting = self.semi_actions = self.NeedLoad = 0;
        self.dive = self.ads_release = self.has_ads_toggle = self.scopetime = 0;
        self.stance = PLAYER_STANCE_CROUCH;
        self.new_anim_stop = self.new_anim2_stop = 0;
        self.weapon_burst_count = self.pri_grenade_state = 0;
        self.primary_grenades = 0; self.secondary_grenades = -1;
        self.isBuying = false;
        for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) self.weapons[i].weapon_id = 0;
        self.weapon2model = "";
        Weapon_AssignWeapon(0, sidearm, 0, 0, 0);
        self.weapons[0].weapon_reserve = 0;
        self.fire_delay = self.fire_delay2 = self.reload_delay = self.reload_delay2 = time + 0.5;
        ReturnWeaponModel();
        self.new_anim_stop = self.new_anim2_stop = 0;
        self.knife_delay = self.switch_delay = time + 6;
        self.think = SUB_Null; self.nextthink = -1;
        self.frame = 38;
    }
    self = savedself;
};

void(entity victim, entity attacker, float damage, float style) MP_Damage =
{
    if (!victim.mp_actor || victim.health <= 0 || mp_finished || damage <= 0) return;
    if (victim.flags & FL_GODMODE || victim.mp_protected > time) return;
    if (attacker != victim && attacker.mp_actor && mp_mode && victim.team == attacker.team) return;
    if (victim.mp_laststand) { MP_FinalDeath(victim, attacker); return; }
    if (victim.mp_perk == MP_PERK_FLAK && (style == DMG_TYPE_GRENADE || style == DMG_TYPE_EXPLOSIVE)) damage *= 0.5;
    victim.health -= damage;
    victim.health_delay = time + 4;
    victim.health_was_very_low = true;
    if (!victim.mp_bot) {
        victim.punchangle_x = -3;
        victim.dmg_inflictor = attacker;
    }
    if (attacker.mp_actor && attacker != victim) {
        victim.mp_lastseen = attacker.origin;
        victim.mp_memory_until = time + 2;
        // Incoming fire is audible information; aiming still requires sight.
        if (victim.mp_bot && victim.enemy == world) {
            victim.enemy = attacker;
            victim.mp_react_at = time + 0.35;
        }
        if (!attacker.mp_bot) nzp_hitmarker(attacker, victim.health <= 0 && victim.mp_perk != MP_PERK_PARTING);
    }
    if (victim.health > 0) return;
    if (victim.mp_perk == MP_PERK_PARTING && !victim.mp_laststand) MP_BeginLastStand(victim, attacker);
    else MP_FinalDeath(victim, attacker);
};

void(entity inflictor, entity attacker, float damage, float minimum, float radius) MP_Explosion =
{
    for (float i = 0; i <= mp_botcount; i++) {
        entity actor = mp_actors[i];
        if (actor == world || actor.health <= 0) continue;
        float distance = vlen(actor.origin - inflictor.origin);
        if (distance >= radius) continue;
        traceline(inflictor.origin, actor.origin, true, inflictor);
        if (trace_fraction != 1) continue;
        MP_Damage(actor, attacker, MP_Min(150, damage) * (1 - distance / radius), DMG_TYPE_GRENADE);
    }
};

void() MP_Acquire =
{
    entity best = world;
    float distance = 1600;
    makevectors(self.angles);
    vector facing = v_forward;
    for (float i = 0; i <= mp_botcount; i++) {
        entity actor = mp_actors[i];
        if (!MP_Hostile(self, actor) || actor.mp_protected > time) continue;
        float d = vlen(actor.origin - self.origin);
        if (d >= distance) continue;
        // Near opponents can be heard; farther ones must be in the forward arc.
        if (d > 240 && normalize(actor.origin - self.origin) * facing < -0.15) continue;
        if (!MP_Visible(self, actor)) continue;
        best = actor; distance = d;
    }
    if (best != world) {
        if (self.enemy != best) self.mp_react_at = time + 0.75 - mp_skill * 0.18 + clamp(distance / 1600, 0, 1) * 0.35 + random() * 0.15;
        self.enemy = best;
        self.mp_lastseen = best.origin;
        self.mp_memory_until = time + 2;
    } else if (self.mp_memory_until < time || self.enemy.health <= 0) {
        self.enemy = world;
    }
    self.mp_scan_at = time + 0.3;
};

void() MP_BotFire =
{
    if (time < self.mp_fire_at || time < self.mp_react_at || self.mp_reload_at) return;
    if (self.mp_clip <= 0) {
        if (self.mp_laststand) return;
        self.mp_reload_start = time;
        self.mp_reload_at = time + MP_ReloadDelay(self, MP_Max(1.5, getWeaponDelay(self.weapon, RELOAD)));
        return;
    }
    if (!self.mp_laststand) self.mp_protected = 0;
    self.mp_clip--;
    self.mp_burst++;
    self.mp_fire_at = time + MP_FireDelay(self, MP_Max(0.10, getWeaponDelay(self.weapon, FIRE)));
    if (self.mp_burst >= 2 + mp_skill * 2) {
        self.mp_burst = 0;
        self.mp_fire_at += 0.4 + random() * 0.45;
    }
    self.mp_anim_until = time + 0.2;
    self.effects = self.effects | EF_MUZZLEFLASH;
    // Match the equipped weapon, using this bot's dedicated weapon channel.
    self.mp_shot_sound = GetWeaponSound(self.weapon);
    sound(self, CHAN_WEAPON, self.mp_shot_sound, 0.8, 1);
    vector start = self.origin + self.view_ofs;
    vector aim = normalize(self.enemy.origin + self.enemy.view_ofs * 0.7 - start);
    self.angles_y = vectoyaw(aim);
    makevectors(vectoangles(aim));
    vector aimright = v_right, aimup = v_up;
    float pellets = 1;
    float spread = MP_WeaponSpread(self.weapon, mp_skill, vlen(self.enemy.origin - self.origin), vlen(self.enemy.velocity));
    if (self.weapon == W_DB || self.weapon == W_SAWNOFF || self.weapon == W_TRENCH) {
        pellets = 8; spread += 0.055;
    }
    spread *= MP_SpreadScale(self);
    for (float p = 0; p < pellets; p++) {
        vector dir = normalize(aim + aimright * crandom() * spread + aimup * crandom() * spread);
        traceline(start, start + dir * 1800, false, self);
        if (trace_ent.mp_actor) {
            float damage = MP_ShotDamage(self.weapon);
            if (pellets == 8) damage *= clamp(1 - vlen(trace_endpos - start) / 800, 0.15, 1);
            MP_Damage(trace_ent, self, damage, DMG_TYPE_UPPERTORSO);
        }
    }
};

void(float distance) MP_BotSelectWeapon =
{
    if (self.mp_perk != MP_PERK_OVERKILL || self.mp_laststand || self.mp_reload_at || time < self.mp_switch_at) return;
    float other = self.weapon == self.mp_primary ? self.mp_secondary : self.mp_primary;
    if (MP_WeaponSpread(other, mp_skill, distance, 0) >= MP_WeaponSpread(self.weapon, mp_skill, distance, 0) * 0.8) return;
    float clip = self.mp_clip;
    self.mp_clip = self.mp_other_clip; self.mp_other_clip = clip;
    self.weapon = other;
    self.mp_burst = 0; self.mp_fire_at = time + 0.4; self.mp_switch_at = time + 1.5;
    setmodel(self.mp_held, MP_HeldModel(other));
};

void() MP_Navigate =
{
    if (self.mp_goal < 0 || self.mp_repath_at <= time) {
        float from = MP_NearestNode(self.origin);
        float goal = floor(random() * mp_nodecount);
        if (self.mp_memory_until > time) goal = MP_NearestNode(self.mp_lastseen);
        // Reload behind cover if a reachable hidden waypoint is close enough.
        if (self.mp_reload_at && self.enemy != world) {
            float nearest = 1000;
            for (float i = 0; i < mp_nodecount; i++) {
                float d = vlen(mp_nodes[i].origin - self.origin);
                if (d >= nearest) continue;
                traceline(self.enemy.origin + self.enemy.view_ofs, mp_nodes[i].origin, true, self);
                if (trace_fraction != 1) { goal = i; nearest = d; }
            }
        }
        self.mp_goal = MP_Route(from, goal);
        self.mp_repath_at = time + 1.1 + random() * 0.5;
    }
    if (self.mp_goal < 0) return;
    vector delta = mp_nodes[self.mp_goal].origin - self.origin;
    if (vlen(delta) < 36) { self.mp_goal = -1; return; }
    float yaw = vectoyaw(delta);
    self.angles_y = yaw;
    if (!walkmove(yaw, 19 * MP_MoveScale(self))) {
        self.mp_stuck++;
        walkmove(yaw + ((self.mp_index & 1) ? 70 : -70), 16);
        if (self.mp_stuck >= 8) {
            self.mp_memory_until = 0;
            self.mp_goal = -1;
            self.mp_stuck = 0;
        }
    } else self.mp_stuck = 0;

};

// Keep navigation at 10 Hz, but allow fire deadlines between movement ticks.
void() MP_BotSchedule =
{
    self.nextthink = MP_Max(time + 0.001, self.mp_ai_at);
    if (self.enemy != world && !self.mp_reload_at && self.mp_clip > 0) {
        float shot = MP_Max(self.mp_fire_at, self.mp_react_at);
        if (shot > time) self.nextthink = MP_Min(self.nextthink, shot);
    }
};

void() MP_BotThink =
{
    self.nextthink = time + 0.1;
    if (mp_finished) return;
    if (self.health <= 0) {
        if (self.mp_respawn_at <= time) MP_BotSpawn();
        MP_UpdateVisual();
        return;
    }
    if (self.mp_laststand) {
        if (time >= self.mp_bleedout_at) MP_FinalDeath(self, self.mp_down_attacker);
        else {
            if (self.mp_scan_at <= time) MP_Acquire();
            if (self.enemy != world && MP_Hostile(self, self.enemy) && MP_Visible(self, self.enemy)) MP_BotFire();
        }
        MP_UpdateVisual(); return;
    }
    if (self.mp_ai_at > time) {
        if (self.enemy != world && MP_Hostile(self, self.enemy) && MP_Visible(self, self.enemy)) MP_BotFire();
        MP_UpdateVisual(); MP_BotSchedule(); return;
    }
    self.mp_ai_at = time + 0.1;
    if (self.health_delay < time) self.health = MP_Min(self.max_health, self.health + 3);
    if (self.mp_reload_at && time >= self.mp_reload_at) {
        self.mp_reload_at = 0;
        self.mp_clip = getWeaponMag(self.weapon);
    }
    if (self.mp_scan_at <= time) MP_Acquire();
    if (self.enemy != world && self.enemy.health > 0 && MP_Visible(self, self.enemy)) {
        self.mp_lastseen = self.enemy.origin;
        self.mp_memory_until = time + 2;
        float distance = vlen(self.enemy.origin - self.origin);
        MP_BotSelectWeapon(distance);
        float yaw = vectoyaw(self.enemy.origin - self.origin);
        self.angles_y = yaw;
        if (self.mp_reload_at) { MP_Navigate(); MP_UpdateVisual(); return; }
        if (self.mp_strafe_at < time) {
            self.mp_strafe = random() < 0.5 ? -1 : 1;
            self.mp_strafe_at = time + 0.8 + random();
        }
        if (distance > 600) walkmove(yaw, 16 * MP_MoveScale(self));
        else if (distance < 150) walkmove(yaw + 180, 12 * MP_MoveScale(self));
        else if (!walkmove(yaw + self.mp_strafe * 90, 10 * MP_MoveScale(self))) self.mp_strafe *= -1;
        if (distance < 1600) MP_BotFire();
    } else MP_Navigate();
    MP_UpdateVisual();
    MP_BotSchedule();
};

float() MP_PlayerThink =
{
    if (mp_finished) {
        self.maxspeed = 0; self.velocity = '0 0 0'; self.movetype = MOVETYPE_NONE;
        return true;
    }
    if (self.health <= 0) {
        self.maxspeed = 0;
        if (self.mp_respawn_at <= time) MP_PlayerSpawn();
        return true;
    }
    if (self.mp_laststand) {
        if (time >= self.mp_bleedout_at) { MP_FinalDeath(self, self.mp_down_attacker); return true; }
        self.impulse = 0; self.maxspeed = 0; self.velocity = '0 0 0';
        WeaponCore_UpdateViewModels(); WeaponCore_UpdateRecoilAndSpread();
        if (self.button0) WeaponCore_FireButtonPressed(); else WeaponCore_FireButtonReleased();
        if (self.button8 && IsDualWeapon(self.weapon)) WeaponCore_AimButtonPressed(); else WeaponCore_AimButtonReleased();
        WeaponCore_UpdateWeaponStats();
        self.frame = 38; self.think = SUB_Null; self.nextthink = -1;
        return true;
    }
    if (self.button0 || (self.button8 && IsDualWeapon(self.weapon))) self.mp_protected = 0;
    return false;
};

void() MP_PublishHUD =
{
    entity player = mp_actors[0];
    string targetname = "";
    if (player.health > 0) {
        makevectors(player.v_angle);
        traceline(player.origin + player.view_ofs, player.origin + player.view_ofs + v_forward * 1800, false, player);
        if (trace_ent.mp_actor && trace_ent.health > 0)
            targetname = sprintf("%s - BOT %02d", MP_Hostile(player, trace_ent) ? "ENEMY" : "ALLY", trace_ent.mp_index);
    }
    cvar_set("mp_hud_perk", MP_PerkName(player.mp_perk));
    cvar_set("mp_hud_downed", ftos(player.mp_laststand ? MP_Max(0, ceil(player.mp_bleedout_at - time)) : 0));
    cvar_set("mp_hud_target", targetname);
    cvar_set("mp_hud_blue", ftos(mp_blue));
    cvar_set("mp_hud_red", ftos(mp_red));
    cvar_set("mp_hud_time", ftos(MP_Max(0, ceil(mp_endtime - time))));
    cvar_set("mp_hud_respawn", ftos(player.health <= 0 ? MP_Max(0, ceil(player.mp_respawn_at - time)) : 0));
    cvar_set("mp_hud_finished", ftos(mp_finished));
    cvar_set("mp_hud_protected", ftos(player.mp_protected > time));
    string board = "SOLDIER                 K   D\n";
    float leader = 0;
    for (float i = 0; i <= mp_botcount; i++) {
        entity a = mp_actors[i];
        if (a == world) continue;
        leader = MP_Max(leader, a.frags);
        string label = i == 0 ? "YOU" : sprintf("BOT %02d", i);
        string teamname = !mp_mode ? "" : a.team == 1 ? " [ALLIES]" : " [AXIS]";
        board = sprintf("%s%s%s   %d / %d\n", board, label, teamname, a.kills, a.mp_deaths);
    }
    cvar_set("mp_hud_board", board);
    cvar_set("mp_hud_kills", ftos(player.kills));
    cvar_set("mp_hud_deaths", ftos(player.mp_deaths));
    cvar_set("mp_hud_leader", ftos(leader));
};

void() MP_Frame =
{
    if (!mp_started) {
        if (mp_actors[0] == world) return;
        if (find(world, classname, "info_mp_spawn") == world)
            error("No Skirmish spawns. Start Offline Multiplayer on mp_test.\n");
        MP_BuildNavigation();
        entity oldself = self;
        for (float i = 1; i <= mp_botcount; i++) {
            self = spawn();
            mp_actors[i] = self;
            self.mp_actor = self.mp_bot = true;
            self.mp_index = i;
            self.team = (i & 1) ? 2 : 1;
            MP_BotSpawn();
            self.think = MP_BotThink;
            self.nextthink = time + 0.1 + i * 0.007;
        }
        self = oldself;
        mp_endtime = time + clamp(cvar("mp_minutes"), 1, 30) * 60;
        mp_started = true;
    }
    if (!mp_finished) {
        float limit_hit = mp_mode && (mp_blue >= mp_limit || mp_red >= mp_limit);
        if (!mp_mode) {
            for (float i = 0; i <= mp_botcount; i++)
                if (mp_actors[i].frags >= mp_limit) limit_hit = true;
        }
        if (time >= mp_endtime || limit_hit) {
            mp_finished = true;
            string result;
            if (mp_mode) result = mp_blue == mp_red ? "DRAW" : mp_blue > mp_red ? "ALLIES WIN" : "AXIS WIN";
            else {
                float best = -1, winner = 0, tied = false;
                for (float n = 0; n <= mp_botcount; n++) {
                    if (mp_actors[n].frags > best) { best = mp_actors[n].frags; winner = n; tied = false; }
                    else if (mp_actors[n].frags == best) tied = true;
                }
                result = tied ? "DRAW" : winner == 0 ? "YOU WIN" : sprintf("BOT %02d WINS", winner);
            }
            cvar_set("mp_hud_result", result);
        }
    }
#ifdef SKIRMISH_PREVIEW
    // Deterministic visual QA fixture, absent from release builds.
    entity preview_self = self;
    for (float pv = 1; pv <= mp_botcount; pv++) {
        self = mp_actors[pv]; self.think = SUB_Null; self.nextthink = -1;
        if (pv > 2) { setmodel(self, ""); setmodel(self.mp_held, ""); continue; }
        setorigin(self, [pv == 1 ? -43 : 43, -20, 36]); self.angles = '0 240 0';
        if (cvar("mp_class") == 1) {
            if (!self.mp_laststand) { self.mp_secondary = pv == 1 ? W_COLT : W_BIATCH; MP_BeginLastStand(self, world); }
            self.health = 1; self.mp_bleedout_at = time + 5; self.mp_protected = time + 5;
            MP_UpdateVisual();
        } else self.health = 10000;
        self.frame = cvar("mp_class") == 1 ? 40 : cvar("mp_class") == 3 ? 15 : cvar("mp_class") == 4 ? 39 : cvar("mp_class") == 2 ? 9 : 0;
        setorigin(self.mp_held, self.origin); self.mp_held.angles = self.angles; self.mp_held.frame = self.frame;
    }
    self = mp_actors[0]; self.health = 10000; setorigin(self, '0 -230 36');
    if (cvar("mp_class") == 1) {
        if (!self.mp_laststand) { self.mp_secondary = W_BIATCH; MP_BeginLastStand(self, world); }
        self.health = 1; self.mp_bleedout_at = time + 5; self.mp_protected = time + 5;
    }
    self.v_angle = '0 90 0'; self.angles = self.v_angle; self.fixangle = true;
    self = preview_self;
#endif
    if (time >= mp_hudtime) {
        MP_PublishHUD();
        mp_hudtime = time + 0.2;
    }
};

void() MP_Init =
{
    mp_active = cvar("sv_skirmish") != 0;
    if (!mp_active) return;
    mp_botcount = floor(clamp(cvar("mp_bots"), 6, 12));
    mp_mode = cvar("mp_mode") != 0;
    mp_skill = floor(clamp(cvar("mp_skill"), 0, 2));
    mp_respawn = clamp(cvar("mp_respawn"), 1, 30);
    mp_limit = floor(clamp(cvar("mp_scorelimit"), 5, 200));
    mp_loadouts = cvar("mp_loadouts") != 0;
    game_modifier_can_packapunch = false;
    precache_model("models/skirmish/allies.mdl");
    precache_model("models/skirmish/axis.mdl");
    float botweapons[22] = {W_COLT, W_357, W_BIATCH, W_KAR, W_THOMPSON, W_BAR, W_BROWNING, W_DB,
        W_FG, W_GEWEHR, W_KAR_SCOPE, W_M1, W_M1A1, W_MP40, W_MG,
        W_PPSH, W_PTRS, W_SAWNOFF, W_STG, W_TRENCH, W_TYPE, W_SPRING};
    for (float bw = 0; bw < 22; bw++)
        precache_model(MP_HeldModel(botweapons[bw]));
    for (float w = 1; w <= W_RAYMK2; w++) {
        if (MP_AllowedPrimary(w) || MP_AllowedSecondary(w)) {
            precache_model(GetWeaponModel(w, false));
            precache_extra(w);
            precache_sound(GetWeaponSound(w));
        }
    }
    cvar_set("mp_hud_finished", "0");
    cvar_set("mp_hud_result", "");
};
