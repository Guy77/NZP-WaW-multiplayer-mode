#!/usr/bin/env python3
"""Create an original, sealed BSP30 test arena and small procedural WAD3.
Run from any directory. Compile with the NZP VHLT toolchain, not Quake qbsp.
"""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "maps"
OUT.mkdir(exist_ok=True)

def texture(name, color):
    palette = bytes(c for i in range(256) for c in (i, i, i))
    # Muted palette accents, all source generated here.
    palette = palette[:128*3] + bytes(color) + palette[129*3:]
    levels = []
    for size in (64, 32, 16, 8):
        # One grid line per tile on floor/cover; flat walls keep the barren
        # arena readable and avoid dense high-frequency aliasing on Vita.
        grid = name in ('mp_floor', 'mp_cover')
        levels.append(bytes(55 if grid and (x == 0 or y == 0) else 128
                            for y in range(size) for x in range(size)))
    offsets = (40, 40+4096, 40+4096+1024, 40+4096+1024+256)
    return struct.pack('<16s6I',name.encode(),64,64,*offsets) + b''.join(levels) + struct.pack('<H',256) + palette + b'\0\0'

textures = [('mp_floor',(111,109,99)),('mp_wall',(86,93,87)),
            ('mp_cover',(120,88,54)),('mp_allies',(58,108,143)),('mp_axis',(145,63,50))]
data = bytearray(b'WAD3' + b'\0'*8)
directory = []
for name,color in textures:
    tex = texture(name,color)
    directory.append(struct.pack('<iiiBBBB16s',len(data),len(tex),len(tex),67,0,0,0,name.encode()))
    data.extend(tex)
struct.pack_into('<ii',data,4,len(textures),len(data))
data.extend(b''.join(directory))
(OUT/'mp_test.wad').write_bytes(data)

def brush(x0,y0,z0,x1,y1,z1,tex):
    planes = [
        ((x0,y0,z0),(x0,y1,z0),(x0,y1,z1)),
        ((x1,y1,z0),(x1,y0,z0),(x1,y0,z1)),
        ((x1,y0,z0),(x0,y0,z0),(x0,y0,z1)),
        ((x0,y1,z0),(x1,y1,z0),(x1,y1,z1)),
        ((x0,y1,z0),(x0,y0,z0),(x1,y0,z0)),
        ((x0,y0,z1),(x0,y1,z1),(x1,y1,z1)),
    ]
    lines=['{']
    for a,b,c in planes:
        normal_axis = 0 if a[0]==b[0]==c[0] else 1 if a[1]==b[1]==c[1] else 2
        axes = '[ 0 1 0 0 ] [ 0 0 -1 0 ]' if normal_axis==0 else '[ 1 0 0 0 ] [ 0 0 -1 0 ]' if normal_axis==1 else '[ 1 0 0 0 ] [ 0 -1 0 0 ]'
        points=' '.join('( %s )' % ' '.join(map(str,p)) for p in (a,b,c))
        lines.append(f'{points} {tex} {axes} 0 1 1')
    return '\n'.join(lines+['}'])

world=['{','"classname" "worldspawn"','"mapversion" "220"','"wad" "mp_test.wad"',
       '"message" "Proving Ground - NZP Skirmish"','"light" "120"']
world += [brush(-928,-672,-32,928,672,0,'mp_floor'),
          brush(-928,-672,0,-896,672,384,'mp_wall'),
          brush(896,-672,0,928,672,384,'mp_wall'),
          brush(-896,-672,0,896,-640,384,'mp_wall'),
          brush(-896,640,0,896,672,384,'mp_wall'),
          brush(-928,-672,384,928,672,416,'mp_wall')]
for x in (-384,128):
    for y in (-360,120):
        world.append(brush(x-64,y-48,0,x+64,y+48,96,'mp_cover'))
for x in (-128,384):
    for y in (-120,360):
        world.append(brush(x-64,y-48,0,x+64,y+48,96,'mp_cover'))
# Color panels distinguish the two ends without borrowed map content.
world += [brush(-895,-180,80,-888,180,200,'mp_allies'),
          brush(888,-180,80,895,180,200,'mp_axis'),'}']

def entity(classname, origin, **keys):
    keys={'classname':classname,'origin':' '.join(map(str,origin)),**keys}
    return '{\n'+'\n'.join(f'"{k}" "{v}"' for k,v in keys.items())+'\n}'

world.append(entity('info_player_start',(-768,0,40),angle=0))
for team,x,angle in ((1,-784,0),(2,784,180)):
    for y in range(-480,481,120):
        world.append(entity('info_mp_spawn',(x,y,40),team=team,angle=angle))
for x in (-768,-512,-256,0,256,512,768):
    for y in (-480,-240,0,240,480):
        world.append(entity('info_mp_node',(x,y,40)))
for x in (-640,0,640):
    for y in (-400,0,400):
        world.append(entity('light',(x,y,300),light='235 226 202 550'))
(OUT/'mp_test.map').write_text('\n'.join(world)+'\n')
(OUT/'mp_test.txt').write_text('Proving Ground\nNZP Skirmish\nOffline soldier combat test arena\n')
print(OUT/'mp_test.map')
