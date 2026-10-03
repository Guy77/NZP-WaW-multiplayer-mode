#!/usr/bin/env python3
"""Build Vita in a fresh output directory and verify the packaged executable."""
from pathlib import Path
import subprocess,os,zipfile
r=Path(__file__).resolve().parents[2];env=os.environ.copy()
env['VITASDK']=str(r/'.deps/sdk-unpack/vitasdk');env['PATH']=env['VITASDK']+'/bin:'+env['PATH']
p=subprocess.run(['make','-C',str(r/'vril-engine'),'-f','Makefile.psp2','BUILD=build/psp2-0.4.1','-j1','CC=arm-vita-eabi-gcc -pipe','CXX=arm-vita-eabi-g++ -pipe'],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
(r/'skirmish/docs/build-vita-0.4.1.log').write_text(p.stdout)
print('Vita build exit:',p.returncode,flush=True)
if p.returncode:print(p.stdout[-4000:]);raise SystemExit(p.returncode)
b=r/'vril-engine/build/psp2-0.4.1'
with zipfile.ZipFile(b/'nzportable.vpk') as z:
 assert z.testzip() is None
 assert z.read('eboot.bin')==(b/'eboot.bin').read_bytes()
 assert z.read('eboot.bin').startswith(b'SCE\0')
 assert b'NZPSK0001' in z.read('sce_sys/param.sfo')
 print('Verified Vita 0.4.1 VPK against fresh executable',flush=True)
