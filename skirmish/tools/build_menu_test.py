#!/usr/bin/env python3
"""Build the rendered menu regression fixture with AddressSanitizer in this workspace."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[2];inc=r/'.deps/sysroot/usr/include';lib=r/'.deps/sysroot/usr/lib/x86_64-linux-gnu'
cflags=f'-O1 -g -pipe -std=gnu99 -fsanitize=address -fno-omit-frame-pointer -DSKIRMISH_MENU_TEST -I{inc} -I{inc}/SDL2 -I{inc}/x86_64-linux-gnu'
libs=f'-fsanitize=address -L{lib} -Wl,-rpath-link,{lib} -lSDL2_mixer -l:libSDL2-2.0.so.0 -l:libGL.so.1 -l:libGLU.so.1 -lm'
p=subprocess.run(['make','-C',str(r/'vril-engine'),'-f','Makefile.sdl','BUILD=build/menu-asan','PKG_CONFIG=true','-j4','CFLAGS='+cflags,'LDLIBS='+libs],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
(r/'skirmish/docs/build-menu-asan.log').write_text(p.stdout)
print('Menu ASan build exit:',p.returncode)
if p.returncode:print(p.stdout[-3500:])
raise SystemExit(p.returncode)
