#!/usr/bin/env python3
"""Build a complete Vita recovery package, matching source and hashes."""
from pathlib import Path
from contextlib import contextmanager
import zipfile,hashlib,json
r=Path(__file__).resolve().parents[2];s=r/'skirmish';out=r/'deliverables';out.mkdir(exist_ok=True)
data=s/'recovery-0.4.1';binary=r/'vril-engine/build/psp2-0.4.1';version='0.4.1'
@contextmanager
def archive(name):
 final=out/name;tmp=out/(name+'.tmp')
 with zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED) as z:yield z
 with zipfile.ZipFile(tmp) as z:assert z.testzip() is None
 tmp.replace(final)
with zipfile.ZipFile(binary/'nzportable.vpk') as z:
 assert z.testzip() is None
 assert z.read('eboot.bin')==(binary/'eboot.bin').read_bytes()
 assert z.read('nzp.bin')==z.read('eboot.bin')
 assert z.read('eboot.bin').startswith(b'SCE\0')
 assert b'NZPSK0001' in z.read('sce_sys/param.sfo')
assert b'SKIRMISH TEST: starting' not in (data/'nzp/progs.dat').read_bytes()
for name in ['nzp.rc','default.cfg','config.cfg','gfx/palette.lmp','models/player.mdl','models/skirmish/w28.mdl','maps/mp_test.bsp','maps/mp_depot.bsp']:
 assert (data/'nzp'/name).is_file(),name
manifest={str(p.relative_to(data/'nzp')):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((data/'nzp').rglob('*')) if p.is_file()}
with archive('NZP-Skirmish-0.4.1-vita-full-recovery.zip') as z:
 z.write(binary/'nzportable.vpk','NZP-Skirmish.vpk')
 for p in sorted((data/'nzp').rglob('*')):
  if p.is_file():z.write(p,'data/nzp-skirmish/nzp/'+str(p.relative_to(data/'nzp')))
 for name in ['README.md','INSTALL_VITA.md','CREDITS.md']:z.write(s/name,name)
 for name in ['UPDATE_0.4.1.md','UPDATE_0.4.md','TEST_REPORT_0.4.1.md']:z.write(s/'docs'/name,name)
 for p in sorted((data/'licenses').rglob('*')):
  if p.is_file():z.write(p,str(p.relative_to(data)))
 z.writestr('DATA-SHA256.json',json.dumps(manifest,indent=2)+'\n')
with archive('NZP-Skirmish-0.4.1-source.zip') as z:
 for repo in ['quakec','vril-engine']:
  for p in sorted((r/repo).rglob('*')):
   rel=p.relative_to(r/repo)
   if any(t in {'.git','build','__pycache__'} for t in rel.parts):continue
   if p.is_file() and p.suffix not in {'.log','.s','.o'}:z.write(p,p.relative_to(r))
 for n in ['README.md','INSTALL_VITA.md','CREDITS.md','upstream.json','vita-dependencies.json','weapons.json']:z.write(s/n,'skirmish/'+n)
 for folder in ['tools','docs','maps','dist','generated','preview']:
  for p in sorted((s/folder).rglob('*')):
   if not p.is_file() or '__pycache__' in p.parts:continue
   if folder=='maps' and p.suffix not in {'.map','.bsp','.wad','.txt'}:continue
   if folder=='dist' and p.name not in {'progs.dat','compile-release.log'}:continue
   if folder=='preview' and not p.name.endswith('.png'):continue
   if p.name=='vita-assets-preview-old.png':continue
   z.write(p,p.relative_to(r))
with zipfile.ZipFile(out/'NZP-Skirmish-0.4.1-vita-full-recovery.zip') as z:
 for name,sha in manifest.items():assert hashlib.sha256(z.read('data/nzp-skirmish/nzp/'+name)).hexdigest()==sha
checks=[]
for name in ['NZP-Skirmish-0.4.1-vita-full-recovery.zip','NZP-Skirmish-0.4.1-source.zip']:
 p=out/name;checks.append(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+name)
 print(name,p.stat().st_size,flush=True)
(out/'NZP-Skirmish-0.4.1-SHA256SUMS.txt').write_text('\n'.join(checks)+'\n')
print('Verified complete recovery data:',len(manifest),'files')
