#!/usr/bin/env python3
"""Package the 0.2 update over an existing 0.1 installation."""
from pathlib import Path
import zipfile
r=Path(__file__).resolve().parents[2]; s=r/'skirmish'; out=r/'deliverables'
out.mkdir(exist_ok=True)
with zipfile.ZipFile(r/'vril-engine/build/psp2/nzportable.vpk') as z:
    assert z.testzip() is None
    assert b'NZPSK0001' in z.read('sce_sys/param.sfo')
    assert z.read('eboot.bin')==(r/'vril-engine/build/psp2/eboot.bin').read_bytes()
for platform in ['vita','linux']:
    with zipfile.ZipFile(out/f'NZP-Skirmish-0.2-{platform}-update.zip','w',zipfile.ZIP_DEFLATED) as z:
        prefix='data/nzp-skirmish/' if platform=='vita' else ''
        binary=r/('vril-engine/build/psp2/nzportable.vpk' if platform=='vita' else 'vril-engine/build/sdl/nzportable')
        z.write(binary,'NZP-Skirmish.vpk' if platform=='vita' else 'nzp-skirmish')
        z.write(s/'dist/progs.dat',prefix+'nzp/progs.dat')
        z.writestr(prefix+'nzp/version.txt','NZP Skirmish prototype 0.2\n')
        z.write(s/'docs/UPDATE_0.2.md','UPDATE_0.2.md')
        z.write(s/'CREDITS.md','CREDITS.md')
        for repo in ['quakec','vril-engine']: z.write(r/repo/'LICENSE','licenses/'+repo+'-GPL.txt')
with zipfile.ZipFile(out/'NZP-Skirmish-0.2-source.zip','w',zipfile.ZIP_DEFLATED) as z:
    for repo in ['quakec','vril-engine']:
        for p in sorted((r/repo).rglob('*')):
            rel=p.relative_to(r/repo)
            if any(t in {'.git','build','__pycache__'} for t in rel.parts): continue
            if p.is_file() and p.suffix not in {'.log','.s','.o'}: z.write(p,p.relative_to(r))
    for n in ['README.md','INSTALL_VITA.md','CREDITS.md','upstream.json','vita-dependencies.json','weapons.json']: z.write(s/n,'skirmish/'+n)
    for folder in ['tools','docs','maps','dist']:
        for p in sorted((s/folder).rglob('*')):
            if not p.is_file() or '__pycache__' in p.parts: continue
            if folder=='maps' and p.suffix not in {'.map','.bsp','.wad','.txt'}: continue
            if folder=='dist' and p.name not in {'progs.dat','compile-release.log'}: continue
            if p.name=='vita-assets-preview-old.png': continue
            z.write(p,p.relative_to(r))
for p in sorted(out.glob('*0.2*.zip')):
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None
        if 'update' in p.name: assert not any(n.endswith('config.cfg') for n in z.namelist())
    print(p.name,p.stat().st_size)
