/* Compile-only regression fixture. Not included in release binaries. */
#ifdef SKIRMISH_MENU_TEST
#include "../nzportable_def.h"
#include "menu_defs.h"
// This suite checks invalid memory accesses, not upstream engine leak cleanup.
// LeakSanitizer cannot scan threads in this sandbox's /proc-less runtime.
#ifdef __SANITIZE_ADDRESS__
int __lsan_is_turned_off(void) { return 1; }
#endif
static int test_step, test_round;
static qboolean testing_menus;
static void Check(qboolean ok, const char *message)
{
    if (!ok) Sys_Error("SKIRMISH MENU TEST FAILED: %s (step %d)", message, test_step);
}
static void Confirm(int index)
{
    current_menu.cursor = index;
    Menu_KeyInput(MENU_KEY_CONFIRM);
}
void Menu_SkirmishTestStart(void)
{
    test_step = test_round = 0;
    testing_menus = true;
    Cvar_SetValue("sv_skirmish", 1);
    Menu_Main_Set();
}
void Menu_SkirmishTestFrame(void)
{
    if (!testing_menus) return;
    switch (test_step++) {
    case 0:
        Check(m_state == m_main, "startup main menu"); Confirm(0); break;
    case 1:
        Check(m_state == m_skirmish, "enter offline multiplayer");
        Check(Menu_GetActiveMenuButtons() == 12, "all twelve match buttons registered");
        current_menu.cursor = 0; Menu_IncreaseCursor(); Check(current_menu.cursor == 11, "navigate to Back");
        Menu_DecreaseCursor(); Check(current_menu.cursor == 0, "wrap cursor from Back");
        Confirm(11); break;
    case 2:
        Check(m_state == m_main, "match Back callback"); Confirm(1); break;
    case 3:
        Check(m_state == m_classes, "main to class"); Menu_KeyInput(MENU_KEY_BACK); break;
    case 4:
        Check(m_state == m_main, "class Back key returns to main"); Confirm(0); break;
    case 5:
        Check(m_state == m_skirmish, "reenter match menu"); Confirm(1); break;
    case 6:
        Check(m_state == m_classes, "match to class"); Confirm(5); break;
    case 7:
        Check(m_state == m_skirmish, "class Back button returns to match");
        Confirm(10); break;
    case 8:
        Check(m_state == m_skirmish && Cvar_VariableValue("mp_botperk") != 0, "new bot perk button");
        Menu_KeyInput(MENU_KEY_BACK); break;
    case 9:
        Check(m_state == m_main, "match Back key returns to main");
        Menu_Pause_Set(); break;
    case 10:
        Check(m_state == m_pause, "pause menu"); Confirm(4); break;
    case 11:
        Check(m_state == m_classes && key_dest == key_menu_pause, "pause to class"); Confirm(5); break;
    case 12:
        Check(m_state == m_pause && key_dest == key_menu_pause, "class returns to pause");
        if (test_round == 0) {
            int count = Menu_GetActiveMenuButtons();
            cvar_t dummy = {"menu_test_dummy", "0"};
            Menu_DrawButton(1, -1, "INVALID", "", NULL);
            Menu_DrawButton(1, MAX_MENU_BUTTONS, "INVALID", "", NULL);
            Menu_DrawOptionSlider(1, MAX_MENU_BUTTONS, 0, 1, dummy, "menu_test_dummy", false, false, 1);
            Check(Menu_GetActiveMenuButtons() == count, "invalid indices do not mutate buttons");
        }
        Cvar_SetValue("mp_botperk", 0); Menu_Main_Set(); test_step = 0;
        if (++test_round == 20) {
            Con_Printf("SKIRMISH MENU TESTS PASS: 20 entry/back/navigation cycles\n");
            Sys_Quit();
        }
        break;
    }
}
#endif
