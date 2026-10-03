#!/usr/bin/env python3
"""Package cumulative 0.4 updates over an existing Skirmish installation."""
from pathlib import Path
from contextlib import contextmanager
import zipfile,hashlib,re
r=Path(__file__).resolve().parents[2];s=r/'skirmish';out=r/'deliverables';out.mkdir(exist_ok=True)
@contextmanager
def archive(name):
    final=out/name;temp=out/(name+'.tmp')
    with zipfile.ZipFile(temp,'w',zipfile.ZIP_DEFLATED) as z:yield z
    with zipfile.ZipFile(temp) as z:assert z.testzip() is None
    temp.replace(final)
with zipfile.ZipFile(r/'vril-engine/build/psp2/nzportable.vpk') as z:
    assert z.testzip() is None
    assert b'NZPSK0001' in z.read('sce_sys/param.sfo')
    assert z.read('eboot.bin')==(r/'vril-engine/build/psp2/eboot.bin').read_bytes()
release=(s/'dist/progs.dat').read_bytes()
assert b'SKIRMISH TEST: starting' not in release
assert b'mp_perk_test_stage' not in release
# Collect the source recordings for all allowed weapons, using the same mapping
# as player/bot firing. Keep each platform's original audio representation.
defs=(r/'quakec/source/shared/shared_defs.qc').read_text()
ids={n:int(v) for n,v in re.findall(r'#define\s+(W_\w+)\s+(\d+)',defs)}
import json
allowed={x[0] for x in json.loads((s/'weapons.json').read_text())}|{1,4,6,28}
source=(r/'quakec/source/shared/weapon_stats.qc').read_text().split('string(float wep) GetWeaponSound =',1)[1].split('float(float wep) IsDualWeapon',1)[0]
cases=[];sounds=set()
for line in source.splitlines():
    match=re.search(r'case (W_\w+):',line)
    if match:cases.append(match[1])
    match=re.search(r'return "(sounds/[^\"]+)";',line)
    if match:
        if any(ids.get(n) in allowed for n in cases):sounds.add(match[1])
        cases=[]
assert len(sounds)>=18
for platform in ['vita','linux']:
    with archive(f'NZP-Skirmish-0.4-{platform}-update.zip') as z:
        prefix='data/nzp-skirmish/' if platform=='vita' else ''
        binary=r/('vril-engine/build/psp2/nzportable.vpk' if platform=='vita' else 'vril-engine/build/sdl/nzportable')
        z.write(binary,'NZP-Skirmish.vpk' if platform=='vita' else 'nzp-skirmish')
        z.write(s/'dist/progs.dat',prefix+'nzp/progs.dat')
        z.writestr(prefix+'nzp/version.txt','NZP Skirmish prototype 0.4\n')
        for name in ['mp_depot.bsp','mp_depot.txt']:z.write(s/'maps'/name,prefix+'nzp/maps/'+name)
        for p in sorted((s/'generated').rglob('*')):
            if p.is_file():z.write(p,prefix+'nzp/'+str(p.relative_to(s/'generated')))
        overlay=r/'assets'/('vita/data/nzp/nzp' if platform=='vita' else 'pc/nzp')
        for name in sorted(sounds):
            p=overlay/name
            if not p.is_file():p=r/'assets/common'/name
            assert p.is_file(),name
            z.write(p,prefix+'nzp/'+name)
        for name in ['README.md','INSTALL_VITA.md','CREDITS.md']:z.write(s/name,name)
        for name in ['UPDATE_0.4.md','TEST_REPORT.md']:z.write(s/'docs'/name,name)
        for repo in ['quakec','vril-engine']:z.write(r/repo/'LICENSE','licenses/'+repo+'-GPL.txt')
        z.write(r/'assets/LICENSE.md','licenses/NZP-ASSETS-CC-BY-SA-4.0.md')
with archive('NZP-Skirmish-0.4-source.zip') as z:
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
            if folder=='preview' and not (p.name.endswith('-0.4.png') or p.name in ['factions-engine.png','reload-engine.png','depot-engine.png','match-menu.png','main-menu.png','class-menu.png']):continue
            if p.name=='vita-assets-preview-old.png':continue
            z.write(p,p.relative_to(r))
checks=[]
for p in sorted(out.glob('*0.4*.zip')):
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None
        if 'update' in p.name:
            assert not any(n.endswith('config.cfg') for n in z.namelist())
            assert any(n.endswith('models/skirmish/w28.mdl') for n in z.namelist())
            assert any(n.endswith('maps/mp_depot.bsp') for n in z.namelist())
            assert any(n.endswith('sounds/weapons/colt/shoot.wav') for n in z.namelist())
    checks.append(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name)
    print(p.name,p.stat().st_size,flush=True)
(out/'NZP-Skirmish-0.4-SHA256SUMS.txt').write_text('\n'.join(checks)+'\n')
print('Verified',len(sounds),'weapon firing recordings per platform')
