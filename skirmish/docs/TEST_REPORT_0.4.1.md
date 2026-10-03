# 0.4.1 crash regression evidence

The user reported menu crashes on Vita after installing 0.4 and startup failure after resetting data. The menu defect is confirmed; the precise cause of the later device startup failure is not independently confirmed. Missing base assets are a plausible contributor because 0.4 was distributed as an incremental overlay.

## Reproduction and fix

The 0.4 Offline Multiplayer menu draws twelve buttons (indices 0–11). MAX_MENU_BUTTONS was 11, and Menu_DrawButton accessed slot 11 without checking bounds. The real rendered desktop menu, compiled with AddressSanitizer, reports global-buffer-overflow exactly after current_menu_buttons. Symbolized call chain:

- Menu_DrawButton, menu_helper.c:557
- Menu_Skirmish_Draw, menu_skirmish.c:222
- Menu_Draw, menu.c:231

See menu-crash-before-0.4.1.log and menu-crash-symbols-0.4.1.txt. The fix expands capacity to sixteen and guards registration, drawing and slider setup before indexing. Class-menu return paths now preserve Main / Offline Multiplayer / Pause parents.

## Checks passed

- AddressSanitizer after the fix: 20 rendered entry/Back/navigation cycles. Every cycle checks all 12 match buttons, wraparound to/from Back, actual callbacks, controller/keyboard Back handling, Bot Perks, Create a Class from Main and match setup, and pause/class return.
- Negative and out-of-range button/slider indices rejected without state mutation.
- Same 20-cycle test with no saved config and the Vita asset tree.
- Six-bot Supply Depot startup through the real engine and release game logic with the Vita assets; map-boot suite passed under AddressSanitizer.
- Vita built into a new output directory; final serial build and link successful. VPK CRC valid; embedded executable is byte-identical to fresh eboot.bin and has SCE magic. App ID NZPSK0001 preserved.
- Vita executable includes the bounds guard and excludes the test fixture. Game logic is byte-identical to the released 0.4 progs.dat; this is an engine/menu hotfix.

LeakSanitizer is disabled for the test fixture because the execution sandbox has no usable /proc thread enumeration. AddressSanitizer's invalid-access detection remains active. Rendering/audio limitations: offscreen desktop OpenGL, sound disabled, no physical Vita measurement.

## Recovery archive

Contains the VPK, complete common and Vita asset overlays, both maps, generated faction/weapon models, release game logic, fresh Vita configuration and licenses. File bytes and ZIP CRCs are verified before upload; SHA-256 hashes accompany the files. The complete data folder avoids requiring any prior installation assets. It does not include the device's proprietary system shader module.

Hardware confirmation remains necessary. If the recovery still fails, request the Vita error code and active-drive log, and identify whether failure is at startup, a menu action, or match loading.
