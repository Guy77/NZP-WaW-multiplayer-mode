// VM regressions; compiled only with SKIRMISH_TEST.
float mp_perk_test_stage;
void() MP_TestPerks =
{
    entity player = mp_actors[0], bot = mp_actors[1], ally = mp_actors[2];
    float mode = mp_mode, savedbotperk = cvar("mp_botperk");
    mp_mode = 0; self = player;
    if (mp_perk_test_stage == 0) {
        cvar_set("mp_class1_primary", ftos(W_M1)); cvar_set("mp_class1_secondary", ftos(W_COLT));
        for (float p = 0; p <= 8; p++) {
            cvar_set("mp_class1_perk", ftos(p)); MP_PlayerSpawn();
            MP_Assert(player.mp_perk == p && player.perks == 0, "single separate perk selection");
            MP_Assert(player.health == (p == 3 ? 150 : 100), "perk spawn health");
            MP_Assert(player.mp_score_scale == 1 && player.weapons[2].weapon_id == 0, "no scoring penalties or third weapon");
        }
        cvar_set("mp_class1_perk", "7"); cvar_set("mp_class1_secondary", ftos(W_KAR_SCOPE)); MP_PlayerSpawn();
        MP_Assert(player.weapons[1].weapon_id == W_KAR_SCOPE, "Overkill second primary");
        cvar_set("mp_class1_perk", "0"); MP_PlayerSpawn();
        MP_Assert(player.weapons[1].weapon_id == W_COLT, "removed Overkill resets secondary");
        cvar_set("mp_class1_perk", "99"); MP_PlayerSpawn(); MP_Assert(player.mp_perk == 0, "invalid perk");
        cvar_set("mp_class1_perk", "0.5"); MP_PlayerSpawn(); MP_Assert(player.mp_perk == 0, "fractional perk");
    } else if (mp_perk_test_stage == 1) {
        MP_Assert(MP_AllowedSecondary(W_BIATCH) && !MP_AllowedPrimary(W_BIATCH), "dual secondary allowlist");
        MP_Assert(GetFiretype(W_BIATCH) == FIRETYPE_SEMIAUTO && Weapon_FiresTraceshot(W_BIATCH), "dual bullets not grenades");
        MP_Assert(!IsPapWeapon(W_BIATCH) && GetWeaponShotcount(W_BIATCH) == 1, "dual not upgraded");
        MP_Assert(getWeaponMag(W_BIATCH) == 8 && MP_ShotDamage(W_BIATCH) == MP_ShotDamage(W_COLT), "dual Colt balance");
        cvar_set("mp_class1_secondary", ftos(W_BIATCH)); MP_PlayerSpawn();
        MP_Assert(player.weapons[1].weapon_id == W_BIATCH, "dual class inventory");
        Weapon_SetActiveInSlot(1, false);
        player.fire_delay = player.fire_delay2 = player.reload_delay = player.reload_delay2 = 0;
        player.new_anim_stop = player.new_anim2_stop = player.semi_actions = 0;
        W_Fire(S_RIGHT); W_Fire(S_LEFT);
        MP_Assert(player.weapons[0].weapon_magazine == 7 && player.weapons[0].weapon_magazine_left == 7 && player.weapons[0].weapon_reserve == 80, "dual two trigger ammo");
        cvar_set("mp_class1_primary", ftos(W_THOMPSON)); cvar_set("mp_class1_perk", "1"); MP_PlayerSpawn();
        player.fire_delay = player.reload_delay = player.new_anim_stop = 0; W_Fire(S_RIGHT);
        MP_Assert(fabs(player.fire_delay - time - getWeaponDelay(W_THOMPSON, FIRE) / 1.33) < 0.001, "Double Tap fire interval");
        MP_Assert(player.weapons[0].weapon_magazine == getWeaponMag(W_THOMPSON) - 1 && MP_ShotDamage(W_THOMPSON) == 25, "Double Tap no extra shot or damage");
        MP_SetPerk(player, MP_PERK_SLEIGHT); player.weapons[0].weapon_magazine = 1;
        player.reload_delay = player.fire_delay = player.new_anim_stop = 0; W_Reload(S_RIGHT);
        MP_Assert(fabs(player.reload_delay - time - getWeaponDelay(W_THOMPSON, RELOAD) * 0.5) < 0.001, "Sleight reload interval");
        MP_SetPerk(player, MP_PERK_STEADY); MP_Assert(MP_SpreadScale(player) == 0.65, "Steady spread");
        MP_SetPerk(player, MP_PERK_MARATHON); MP_Assert(MP_SprintLimit(player, 4) == 8, "Marathon duration");
        MP_SetPerk(player, MP_PERK_FLAK); player.mp_protected = 0;
        MP_Damage(player, bot, 50, DMG_TYPE_GRENADE); MP_Assert(player.health == 75 && !(player.perks & P_FLOP), "Flak reduction without flop");
        MP_Damage(player, bot, 20, DMG_TYPE_EXPLOSIVE); MP_Assert(player.health == 65, "Flak rocket reduction");
        MP_Damage(player, bot, 20, DMG_TYPE_UPPERTORSO); MP_Assert(player.health == 45, "Flak bullets unchanged");
        for (float w = 1; w <= W_RAYMK2; w++) {
            if (!MP_AllowedPrimary(w) && !MP_AllowedSecondary(w)) continue;
            MP_Assert(MP_WeaponSpread(w, 0, 900, 0) > MP_WeaponSpread(w, 1, 900, 0) && MP_WeaponSpread(w, 1, 900, 0) > MP_WeaponSpread(w, 2, 900, 0), "accuracy difficulty ordering");
            MP_Assert(MP_WeaponSpread(w, 1, 900, 240) > MP_WeaponSpread(w, 1, 900, 0), "moving target penalty");
        }
        MP_Assert(MP_WeaponSpread(W_PTRS, 1, 1200, 0) * 1200 < MP_WeaponSpread(W_PTRS, 1, 128, 0) * 128, "sniper hit error improves at range");
        MP_Assert(MP_WeaponSpread(W_TRENCH, 1, 1200, 0) > MP_WeaponSpread(W_TRENCH, 1, 128, 0) * 5, "shotgun range penalty");
        MP_Assert(MP_WeaponSpread(W_BIATCH, 1, 1200, 0) > MP_WeaponSpread(W_BIATCH, 1, 128, 0) * 5, "secondary range penalty");
        MP_Assert(MP_WeaponSpread(W_M1, 1, 1200, 0) > MP_WeaponSpread(W_M1, 1, 500, 0), "rifle range penalty");
    } else if (mp_perk_test_stage == 2) {
        cvar_set("mp_botperk", "7"); self = bot; MP_BotSpawn();
        MP_Assert(bot.mp_perk == 7 && MP_AllowedPrimary(bot.mp_secondary), "bot Overkill spawn");
        entity held = bot.mp_held;
        bot.mp_primary = W_KAR_SCOPE; bot.mp_secondary = W_TRENCH;
        bot.weapon = W_KAR_SCOPE; bot.mp_clip = 3; bot.mp_other_clip = 5;
        bot.mp_switch_at = 0; MP_BotSelectWeapon(100);
        MP_Assert(bot.weapon == W_TRENCH && bot.mp_clip == 5 && bot.mp_other_clip == 3, "bot close switch saves ammo");
        bot.mp_switch_at = 0; MP_BotSelectWeapon(1200);
        MP_Assert(bot.weapon == W_KAR_SCOPE && bot.mp_clip == 3 && bot.mp_other_clip == 5 && bot.mp_held == held, "bot far switch restores ammo");
        MP_Assert(bot.mp_held.model == MP_HeldModel(bot.weapon), "switched held model");
        bot.enemy = player;
        float samples[5] = {W_KAR_SCOPE, W_THOMPSON, W_BAR, W_357, W_BIATCH};
        for (float n = 0; n < 5; n++) {
            bot.weapon = samples[n]; bot.mp_clip = 2;
            bot.mp_fire_at = bot.mp_react_at = bot.mp_reload_at = 0; MP_BotFire();
            MP_Assert(bot.mp_shot_sound == GetWeaponSound(samples[n]), "bot sound matches gun");
        }
        MP_SetPerk(bot, MP_PERK_SLEIGHT); bot.mp_clip = 0; bot.mp_fire_at = 0; MP_BotFire();
        MP_Assert(fabs(bot.mp_reload_at - time - MP_Max(1.5, getWeaponDelay(bot.weapon, RELOAD)) * 0.5) < 0.001, "bot Sleight reload");
        MP_SetPerk(bot, MP_PERK_DOUBLE); bot.mp_clip = 2; bot.mp_fire_at = bot.mp_reload_at = 0;
        bot.mp_burst = 0; bot.mp_ai_at = time + 0.1; MP_BotFire(); MP_BotSchedule();
        MP_Assert(fabs(bot.mp_fire_at - time - 0.1 / 1.33) < 0.001 && bot.nextthink < time + 0.1, "bot Double Tap sub-tick cadence");
        cvar_set("mp_botperk", "3"); MP_BotSpawn(); MP_Assert(bot.health == 150 && bot.mp_perk == 3, "bot Juggernaut");
        bot.health = 149; bot.health_delay = bot.mp_ai_at = 0; bot.enemy = world; MP_BotThink();
        MP_Assert(bot.health == 150, "bot perk regeneration cap");
        cvar_set("mp_botperk", "-1"); MP_BotSpawn(); MP_Assert(bot.mp_perk == MP_ValidPerk(bot.mp_perk), "random perk bounds");
        cvar_set("mp_botperk", ftos(savedbotperk));
    } else if (mp_perk_test_stage == 3) {
        cvar_set("mp_class1_perk", "4"); cvar_set("mp_class1_secondary", ftos(W_BIATCH)); MP_PlayerSpawn();
        player.mp_protected = 0;
        float deaths = player.mp_deaths, downer_kills = bot.kills;
        MP_Damage(player, bot, 1000, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.mp_laststand && player.health == 1 && player.mp_deaths == deaths && bot.kills == downer_kills, "Parting transition no score");
        MP_Assert(fabs(player.mp_bleedout_at - time - 5) < 0.001 && fabs(player.mp_protected - time - 0.5) < 0.001, "Parting exact deadlines");
        MP_Assert(player.weapon == W_BIATCH && player.weapons[0].weapon_magazine == 8 && player.weapons[0].weapon_magazine_left == 8 && player.weapons[0].weapon_reserve == 0, "Parting loaded dual secondary");
        MP_Assert(player.weapons[1].weapon_id == 0 && player.primary_grenades == 0 && !player.downed, "Parting no primary grenade or revive state");
        MP_Damage(player, bot, 1000, DMG_TYPE_UPPERTORSO); MP_Assert(player.health == 1, "Parting transition protection");
        player.health_delay = 0; PlayerPostThink(); MP_Assert(player.health == 1, "Parting no regeneration");
        player.reload_delay = player.reload_delay2 = player.switch_delay = 0;
        player.weapons[0].weapon_magazine = player.weapons[0].weapon_magazine_left = 0;
        W_Reload(S_BOTH); W_PutOut();
        MP_Assert(player.weapons[0].weapon_magazine == 0 && player.weapons[0].weapon_magazine_left == 0 && player.weapon == W_BIATCH, "Parting no reload or switch");
        player.mp_protected = 0; MP_Damage(player, bot, 0.1, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.health == 0 && player.mp_deaths == deaths + 1 && bot.kills == downer_kills + 1, "Parting any positive damage kills");
        MP_Damage(player, bot, 1000, DMG_TYPE_UPPERTORSO);
        MP_Assert(bot.kills == downer_kills + 1 && player.mp_respawn_at == time + mp_respawn, "Parting score once and respawn deadline");
        cvar_set("mp_class1_secondary", ftos(W_BK)); MP_PlayerSpawn(); player.mp_protected = 0;
        MP_Damage(player, bot, 1000, DMG_TYPE_UPPERTORSO);
        MP_Assert(player.weapon == W_COLT && player.weapons[0].weapon_reserve == 0, "Parting knife fallback");
        player.mp_bleedout_at = time; MP_PlayerThink();
        MP_Assert(player.health == 0 && bot.kills == downer_kills + 2, "Parting bleedout attribution");
        MP_PlayerSpawn(); player.mp_secondary = W_M1; player.mp_protected = 0;
        MP_Damage(player, bot, 1000, DMG_TYPE_UPPERTORSO); MP_Assert(player.weapon == W_COLT, "Parting primary fallback");
        player.mp_protected = 0; float finisher = ally.kills; MP_Damage(player, ally, 1, DMG_TYPE_UPPERTORSO);
        MP_Assert(ally.kills == finisher + 1 && bot.kills == downer_kills + 2, "Parting finisher attribution");
    } else if (mp_perk_test_stage == 4) {
        self = bot; MP_BotSpawn(); MP_SetPerk(bot, MP_PERK_PARTING);
        bot.mp_secondary = W_357; bot.mp_protected = 0; bot.enemy = player;
        MP_Damage(bot, player, 1000, DMG_TYPE_UPPERTORSO);
        MP_Assert(bot.mp_laststand && bot.weapon == W_357 && bot.mp_clip == getWeaponMag(W_357) && bot.mp_held.frame == 40, "bot Parting secondary and pose");
        bot.mp_clip = 0; bot.mp_fire_at = bot.mp_react_at = 0; MP_BotFire();
        MP_Assert(bot.mp_reload_at == 0 && bot.mp_clip == 0, "bot Parting no reload");
        bot.health_delay = 0; MP_BotThink(); MP_Assert(bot.health == 1, "bot Parting no regeneration");
        bot.mp_bleedout_at = time; float score = player.kills; MP_BotThink();
        MP_Assert(bot.health == 0 && player.kills == score + 1, "bot Parting timeout");
        cvar_set("mp_class1_perk", "0"); cvar_set("mp_class1_primary", ftos(W_M1)); cvar_set("mp_class1_secondary", ftos(W_COLT));
        self = player; MP_PlayerSpawn();
        MP_Assert(!player.mp_laststand && player.health == 100 && player.max_health == 100, "spawn resets perk state");
        self = bot; MP_BotSpawn(); self = player;
        print("SKIRMISH TEST: perks, dual fire, sound identity, range profiles and Parting Shot passed\n");
    }
    mp_mode = mode;
};
