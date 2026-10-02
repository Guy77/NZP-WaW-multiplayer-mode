// NZP Skirmish prototype. GPL-2.0-or-later; see repository LICENSE.
// Local actors deliberately do not use FL_CLIENT or network client slots.
#define MP_MAX_ACTORS 13
#define MP_MAX_NODES 48
float mp_active, mp_started, mp_finished, mp_endtime, mp_hudtime;
float mp_botcount, mp_mode, mp_skill, mp_respawn, mp_limit, mp_loadouts;
float mp_blue, mp_red, mp_finish_time, mp_nodecount;
entity mp_actors[MP_MAX_ACTORS];
entity mp_nodes[MP_MAX_NODES];
float mp_links[2304];
float mp_queue[MP_MAX_NODES], mp_parent[MP_MAX_NODES];
.float mp_actor, mp_bot, mp_index, mp_deaths, mp_protected;
.float mp_respawn_at, mp_scan_at, mp_react_at, mp_fire_at, mp_reload_at;
.float mp_clip, mp_primary, mp_secondary, mp_goal, mp_repath_at;
.float mp_memory_until, mp_strafe, mp_strafe_at, mp_burst, mp_stuck;
.vector mp_lastseen;
void() MP_Init;
void() MP_Frame;
void() MP_PlayerSpawn;
float() MP_PlayerThink;
void(entity victim, entity attacker, float damage, float style) MP_Damage;
float(float weapon) MP_AllowedPrimary;
void(entity inflictor, entity attacker, float damage, float minimum, float radius) MP_Explosion;

float(float weapon) MP_ShotDamage;

#ifdef SKIRMISH_TEST
void() MP_TestFrame;
#endif

.entity mp_held;
.float mp_anim_until, mp_reload_start, mp_died_at;
.vector mp_visual_origin;
