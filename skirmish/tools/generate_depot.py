#!/usr/bin/env python3
"""Original BSP30 depot: two storage buildings, flanking lanes and a central passage."""
from generate_arena import OUT,brush,entity
import struct, random
# Procedural native WAD materials: paving, brickwork, sheet metal and timber.
materials={'dp_ground':(64,67,61),'dp_brick':(67,53,43),'dp_metal':(44,51,57),'dp_crate':(75,55,34)}
data=bytearray(b'WAD3'+b'\0'*8);directory=[]
for name,color in materials.items():
 palette=bytearray(bytes(c for i in range(256) for c in (i,i,i)))
 for n,factor in [(128,1),(129,.68),(130,.85),(131,1.12)]:palette[n*3:n*3+3]=bytes(int(c*factor) for c in color)
 levels=[]
 for size in [64,32,16,8]:
  pixels=[]
  for y in range(size):
   for x in range(size):
    u=x*64//size;v=y*64//size
    if name=='dp_brick': seam=v%16<2 or (u+(16 if v//16%2 else 0))%32<2
    elif name=='dp_metal':seam=v%12<2
    elif name=='dp_crate':seam=u%16<2 or v in [2,3,59,60]
    else:seam=u==0 or v==0
    pixels.append(129 if seam else (130 if (u*13+v*7)%19==0 else 131 if (u*5+v*11)%31==0 else 128))
  levels.append(bytes(pixels))
 tex=struct.pack('<16s6I',name.encode(),64,64,40,4136,5160,5416)+b''.join(levels)+struct.pack('<H',256)+palette+b'\0\0'
 directory.append(struct.pack('<iiiBBBB16s',len(data),len(tex),len(tex),67,0,0,0,name.encode()));data.extend(tex)
# Include faction panels from the base WAD as an additional WAD reference.
struct.pack_into('<ii',data,4,len(materials),len(data));data.extend(b''.join(directory));(OUT/'mp_depot.wad').write_bytes(data)
world=['{','"classname" "worldspawn"','"mapversion" "220"','"wad" "mp_depot.wad;mp_test.wad"','"message" "Supply Depot - NZP Skirmish"','"light" "95"']
world += [brush(-1184,-800,-32,1184,800,0,'dp_ground'),brush(-1184,-800,0,-1152,800,384,'dp_brick'),brush(1152,-800,0,1184,800,384,'dp_brick'),brush(-1152,-800,0,1152,-768,384,'dp_brick'),brush(-1152,768,0,1152,800,384,'dp_brick'),brush(-1184,-800,384,1184,800,416,'dp_brick')]
for x in [-640,128]:
 world.append(brush(x,-160,0,x+512,160,160,'dp_brick'))
 world.append(brush(x-12,-172,160,x+524,172,176,'dp_metal'))
 # Broad door-shaped panels give each solid storehouse a readable facade.
 for y in [-164,160]:world.append(brush(x+160,y,0,x+352,y+4,100,'dp_metal'))
for x in [-896,-384,384,896]:
 for y in [-480,480]:
  world.append(brush(x-56,y-48,0,x+56,y+48,72,'dp_crate'))
  if abs(x)==384:world.append(brush(x-40,y-38,72,x+40,y+38,120,'dp_crate'))
world += [brush(-1151,-150,75,-1144,150,190,'mp_allies'),brush(1144,-150,75,1151,150,190,'mp_axis'),'}']
world.append(entity('info_player_start',(-1040,0,40),angle=0))
for team,x,angle in [(1,-1040,0),(2,1040,180)]:
 for y in range(-600,601,150):world.append(entity('info_mp_spawn',(x,y,40),team=team,angle=angle))
for x in range(-1024,1025,256):
 for y in [-640,-320,0,320,640]:
  if y==0 and 128<=abs(x)<=640:continue
  world.append(entity('info_mp_node',(x,y,40)))
for x in [-896,-448,0,448,896]:
 for y in [-560,0,560]:world.append(entity('light',(x,y,310),light='225 231 240 450'))
(OUT/'mp_depot.map').write_text('\n'.join(world)+'\n')
(OUT/'mp_depot.txt').write_text('Supply Depot\nNZP Skirmish\nStorage buildings, flanking lanes and a central passage\n')
print(OUT/'mp_depot.map')
