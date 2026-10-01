/* NZP Skirmish. GPL-2.0-or-later; see LICENSE. */
#include "../nzportable_def.h"
#include "menu_defs.h"

static cvar_t mp_enabled = {"sv_skirmish", "0"};
static cvar_t mp_bots = {"mp_bots", "6", true};
static cvar_t mp_mode = {"mp_mode", "1", true};
static cvar_t mp_respawn = {"mp_respawn", "5", true};
static cvar_t mp_loadouts = {"mp_loadouts", "0", true};
static cvar_t mp_skill = {"mp_skill", "1", true};
static cvar_t mp_scorelimit = {"mp_scorelimit", "50", true};
static cvar_t mp_minutes = {"mp_minutes", "10", true};
static cvar_t mp_class = {"mp_class", "0", true};
static cvar_t mp_primary[5] = {
    {"mp_class1_primary", "12", true}, {"mp_class2_primary", "3", true},
    {"mp_class3_primary", "5", true}, {"mp_class4_primary", "23", true},
    {"mp_class5_primary", "11", true}
};
static cvar_t mp_secondary[5] = {
    {"mp_class1_secondary", "1", true}, {"mp_class2_secondary", "1", true},
    {"mp_class3_secondary", "4", true}, {"mp_class4_secondary", "1", true},
    {"mp_class5_secondary", "1", true}
};
static cvar_t mp_hud[] = {
    {"mp_hud_blue", "0"}, {"mp_hud_red", "0"}, {"mp_hud_time", "0"},
    {"mp_hud_respawn", "0"}, {"mp_hud_finished", "0"}, {"mp_hud_result", ""},
    {"mp_hud_board", ""}, {"mp_hud_kills", "0"}, {"mp_hud_deaths", "0"},
    {"mp_hud_protected", "0"}, {"mp_hud_leader", "0"}, {"mp_hud_target", ""}
};
static const struct { int id; const char *name; } mp_weapons[] = {
    {2,"Kar 98k"}, {3,"Thompson"}, {5,"BAR"}, {7,"Browning M1919"},
    {8,"Double barrel"}, {9,"FG42"}, {10,"Gewehr 43"}, {11,"Scoped Kar 98k"},
    {12,"M1 Garand"}, {13,"M1A1 Carbine"}, {15,"MP40"},
    {16,"MG42"}, {17,"Panzerschreck"}, {18,"PPSh-41"}, {19,"PTRS-41"},
    {21,"Sawn off"}, {22,"STG-44"}, {23,"Trench Gun"}, {24,"Type 100"},
    {58,"Springfield"}, {54,"MP5K (extra)"}
};
static const int mp_defaults[] = {12, 3, 5, 23, 11};
static const char *mp_roles[] = {"RIFLEMAN", "ASSAULT", "SUPPORT", "BREACHER", "SCOUT"};
static int mp_classes_parent = m_skirmish;

void Menu_Skirmish_Init(void)
{
    unsigned i;
    Cvar_RegisterVariable(&mp_enabled);
    Cvar_RegisterVariable(&mp_bots);
    Cvar_RegisterVariable(&mp_mode);
    Cvar_RegisterVariable(&mp_respawn);
    Cvar_RegisterVariable(&mp_loadouts);
    Cvar_RegisterVariable(&mp_skill);
    Cvar_RegisterVariable(&mp_scorelimit);
    Cvar_RegisterVariable(&mp_minutes);
    Cvar_RegisterVariable(&mp_class);
    for (i = 0; i < 5; ++i) {
        Cvar_RegisterVariable(&mp_primary[i]);
        Cvar_RegisterVariable(&mp_secondary[i]);
    }
    for (i = 0; i < sizeof(mp_hud)/sizeof(mp_hud[0]); ++i)
        Cvar_RegisterVariable(&mp_hud[i]);
}

static void MP_ToggleMode(void) { Cvar_SetValue("mp_mode", !mp_mode.value); }
static void MP_ToggleLoadouts(void) { Cvar_SetValue("mp_loadouts", !mp_loadouts.value); }
static void MP_Skill(void) { Cvar_SetValue("mp_skill", ((int)mp_skill.value + 1) % 3); }
static int MP_ClassIndex(void) { return bound(0, (int)mp_class.value, 4); }
static void MP_ClassNext(void) { Cvar_SetValue("mp_class", (MP_ClassIndex() + 1) % 5); }

static void MP_PrimaryNext(void)
{
    unsigned i, count = sizeof(mp_weapons)/sizeof(mp_weapons[0]);
    int slot = MP_ClassIndex();
    for (i = 0; i < count; ++i) if (mp_primary[slot].value == mp_weapons[i].id) break;
    Cvar_SetValue(mp_primary[slot].name, mp_weapons[(i + 1) % count].id);
}
static void MP_SecondaryNext(void)
{
    int slot = MP_ClassIndex();
    Cvar_SetValue(mp_secondary[slot].name, mp_secondary[slot].value == 1 ? 4 : (mp_secondary[slot].value == 4 ? 6 : 1));
}
static void MP_RestoreClass(void)
{
    int slot = MP_ClassIndex();
    Cvar_SetValue(mp_primary[slot].name, mp_defaults[slot]);
    Cvar_SetValue(mp_secondary[slot].name, slot == 2 ? 4 : 1);
}
static void MP_ClassesBack(void)
{
    if (mp_classes_parent == m_pause) Menu_Pause_Set();
    else Menu_Skirmish_Set();
}

void Menu_Classes_Set(void)
{
    mp_classes_parent = (m_state == m_pause) ? m_pause : m_skirmish;
    Menu_ResetMenuButtons();
    m_previous_state = mp_classes_parent;
    m_state = m_classes;
    key_dest = mp_classes_parent == m_pause ? key_menu_pause : key_menu;
}

void Menu_Classes_Draw(void)
{
    unsigned i;
    int slot = MP_ClassIndex();
    char label[64];
    const char *name = "Default rifle";
    Menu_DrawCustomBackground(true);
    Menu_DrawTitle("CREATE A CLASS", MENU_COLOR_WHITE);
    snprintf(label, sizeof(label), "CLASS %d - %s", slot + 1, mp_roles[slot]);
    Menu_DrawButton(1, 0, "ACTIVE CLASS", "Select one of five saved slots. Changes apply on your next spawn.", MP_ClassNext);
    Menu_DrawOptionButton(1, label);
    for (i = 0; i < sizeof(mp_weapons)/sizeof(mp_weapons[0]); ++i)
        if (mp_weapons[i].id == (int)mp_primary[slot].value) name = mp_weapons[i].name;
    Menu_DrawButton(2, 1, "PRIMARY", "Cycle NZP's base weapons. No upgrades, Ray Guns, Wunderwaffe or flamethrower.", MP_PrimaryNext);
    Menu_DrawOptionButton(2, (char *)name);
    Menu_DrawButton(3, 2, "SECONDARY", "Choose a pistol or ballistic knife. Every class carries two frag grenades and a knife.", MP_SecondaryNext);
    Menu_DrawOptionButton(3, mp_secondary[slot].value == 6 ? "Ballistic Knife" : (mp_secondary[slot].value == 4 ? ".357 Magnum" : "Colt M1911"));
    Menu_DrawButton(5, 3, "RESTORE PRESET", "Restore this slot's soldier role loadout.", MP_RestoreClass);
    Menu_DrawButton(-1, 4, "BACK", "Your classes are saved with the game configuration.", MP_ClassesBack);
}

static void MP_Start(void)
{
    // Exactly one loopback player. Bots are ordinary server entities.
    Cvar_SetValue("sv_skirmish", 1);
    Cvar_SetValue("sv_gamemode", 0);
    Cvar_Set("sv_gameconfig", "");
    Cvar_SetValue("waypoint_mode", 0);
    Cbuf_AddText("disconnect\nmaxplayers 1\nlisten 0\ndeathmatch 0\ncoop 0\nmap mp_test\n");
    map_loadname = "mp_test";
    map_loadname_pretty = "Proving Ground";
    m_state = m_none;
    key_dest = key_game;
    LoadingScreen_Begin(map_loadname);
}

void Menu_Skirmish_Set(void)
{
    Menu_ResetMenuButtons();
    key_dest = key_menu;
    m_previous_state = m_main;
    m_state = m_skirmish;
}

void Menu_Skirmish_Draw(void)
{
    static const char *skills[] = {"RECRUIT", "REGULAR", "VETERAN"};
    Menu_DrawCustomBackground(true);
    Menu_DrawTitle("OFFLINE MULTIPLAYER", MENU_COLOR_WHITE);
    Menu_DrawButton(1, 0, "START MATCH", "Proving Ground: a compact test arena with cover and bot routes.", MP_Start);
    Menu_DrawButton(2, 1, "CREATE A CLASS", "Edit and select your five saved loadouts.", Menu_Classes_Set);
    Menu_DrawButton(3, 2, "GAME MODE", "Team Deathmatch: Allies versus Axis, friendly fire off. Or Free-for-All.", MP_ToggleMode);
    Menu_DrawOptionButton(3, mp_mode.value ? "TEAM DEATHMATCH" : "FREE-FOR-ALL");
    Menu_DrawButton(4, 3, "BOTS", "6 to 12 local bots. Start with 6 on Vita; measure before increasing.", NULL);
    Menu_DrawOptionSlider(4, 3, 6, 12, mp_bots, "mp_bots", false, true, 1);
    Menu_DrawButton(5, 4, "BOT LOADOUTS", "Soldier role presets or a new random period loadout on each spawn.", MP_ToggleLoadouts);
    Menu_DrawOptionButton(5, mp_loadouts.value ? "RANDOMIZED" : "SOLDIER PRESETS");
    Menu_DrawButton(6, 5, "BOT SKILL", "Changes reaction delay, aim spread and burst length.", MP_Skill);
    Menu_DrawOptionButton(6, (char *)skills[bound(0, (int)mp_skill.value, 2)]);
    Menu_DrawButton(7, 6, "RESPAWN SECONDS", "Respawn delay for you and bots. Default: 5 seconds.", NULL);
    Menu_DrawOptionSlider(7, 6, 1, 30, mp_respawn, "mp_respawn", false, true, 1);
    Menu_DrawButton(8, 7, "KILL LIMIT", "Match ends when a team or FFA player reaches this score.", NULL);
    Menu_DrawOptionSlider(8, 7, 5, 200, mp_scorelimit, "mp_scorelimit", false, true, 5);
    Menu_DrawButton(9, 8, "TIME LIMIT", "Match length in minutes. The result remains until you restart or leave.", NULL);
    Menu_DrawOptionSlider(9, 8, 1, 30, mp_minutes, "mp_minutes", false, true, 1);
    Menu_DrawButton(-1, 9, "BACK", "Return to the main menu.", Menu_Main_Set);
}
