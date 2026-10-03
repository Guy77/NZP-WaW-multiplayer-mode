#!/usr/bin/env python3
"""Build native MDL faction variants and frame-matched held weapons.
Derived from the pinned NZP CC BY-SA models. No runtime skeletal attachment needed.
Requires numpy; edits mesh/material data in the native model format.
"""
from pathlib import Path
import sys,copy,json,re
import numpy as np
from mdl_tools import read_mdl,write_mdl
ROOT=Path(__file__).resolve().parents[2];ASSETS=ROOT/'assets/common';OUT=ROOT/'skirmish/generated/models/skirmish';OUT.mkdir(parents=True,exist_ok=True)
base=read_mdl(ASSETS/'models/player.mdl');reference=base['frames'][0]
# Compact bot animation set: 0 idle, 1-8 walk, 9-10 fire, 11-24 reload,
# 25-31 sprint (reserved), 32-39 falling and corpse.
frames=np.concatenate([base['frames'][:40],base['frames'][38:39]]);normals=np.concatenate([base['normals'][:40],base['normals'][38:39]])
for i in range(8):
 theta=(i+1)/8*np.pi/2;rot=np.array([[np.cos(theta),0,-np.sin(theta)],[0,1,0],[np.sin(theta),0,np.cos(theta)]])
 frames[32+i]=(reference-[0,0,-34])@rot.T+[0,0,-34]
 normals[32+i]=base['normals'][0]
palette=np.frombuffer((ASSETS/'gfx/palette.lmp').read_bytes(),np.uint8).reshape(256,3).astype(float)
# Material regions are determined from the source mesh UVs. Preserve exposed face/hands.
from PIL import Image,ImageDraw
mask=Image.new('1',(256,256));draw=ImageDraw.Draw(mask)
for tri in base['tris']:
 pts=reference[tri[1:]];c=pts.mean(0)
 uniform=(c[2]<29 and not (c[0]>18 and c[2]>10)) or c[2]>33
 if not uniform: continue
 uv=base['uv'][tri[1:],1:].copy()
 for j,idx in enumerate(tri[1:]):
  if not tri[0] and base['uv'][idx,0]:uv[j,0]+=128
 draw.polygon([tuple(x) for x in uv],fill=1)
mask=np.asarray(mask).reshape(-1);skin=np.frombuffer(base['skins'][0],np.uint8).copy()
for faction,color in [('allies',(98,112,65)),('axis',(98,104,106))]:
 d=copy.deepcopy(base);d['frames']=frames.copy();d['normals']=normals.copy()
 lum=palette[skin].mean(1);target=np.array(color)[None,:]*np.clip(lum[:,None]/105,.23,1.65)
 nearest=np.argmin(((target[:,None,:]-palette[None,:224,:])**2).sum(2),axis=1).astype(np.uint8)
 material=skin.copy();material[mask]=nearest[mask];d['skins']=[material.tobytes()]
 if faction=='axis':
  # Wider, lower helmet silhouette; deformation follows the existing helmet vertices.
  helmet=np.where(reference[:,2]>33)[0]
  for f in range(32):
   center=d['frames'][f,helmet].mean(0);d['frames'][f,helmet]=(d['frames'][f,helmet]-center)*[1.15,1.18,.72]+center
  for i in range(8):
   theta=(i+1)/8*np.pi/2;rot=np.array([[np.cos(theta),0,-np.sin(theta)],[0,1,0],[np.sin(theta),0,np.cos(theta)]])
   d['frames'][32+i]=(d['frames'][0]-[0,0,-34])@rot.T+[0,0,-34]
 write_mdl(OUT/f'{faction}.mdl',d)
# Source weapon mapping, explicitly covering the bot roster.
weapons={1:'m1911/g_colt',4:'357/g_357',28:'m1911/g_colt',2:'kar/g_kar',3:'thomp/g_thomp',5:'bar/g_bar',7:'browning/g_browning',8:'db/g_db',9:'fg42/g_fg',10:'gewehr/g_gewehr',11:'kar/g_kars',12:'garand/g_m1',13:'m1carbine/g_m1a1',15:'mp40/g_mp40',16:'mg/g_mg',18:'ppsh/g_ppsh',19:'ptrs/g_ptrs',21:'sawnoff/g_sawnoff',22:'stg/g_stg',23:'trench/g_trench',24:'type/g_type',58:'spring/g_spring'}
# Right-hand vertex cluster retains the weapon while the left hand reloads.
anchors=np.arange(335,354);a=reference[anchors];center=a.mean(0)
transforms=[]
for f in range(41):
 b=frames[f,anchors];u,_,vt=np.linalg.svd((a-center).T@(b-b.mean(0)));rot=vt.T@u.T
 if np.linalg.det(rot)<0:vt[-1]*=-1;rot=vt.T@u.T
 transforms.append((rot,b.mean(0)))
for wid,source in weapons.items():
 path=ASSETS/'models/weapons'/f'{source}.mdl'
 if not path.exists():raise FileNotFoundError(path)
 d=read_mdl(path);v=d['frames'][0]+[26,-6,23]
 if wid==28:
  count=len(v);v=np.concatenate([v,v+[0,13,0]])
  second=d['tris'].copy();second[:,1:]+=count
  d['tris']=np.concatenate([d['tris'],second]);d['uv']=np.concatenate([d['uv'],d['uv']])
  d['normals']=np.concatenate([d['normals'],d['normals']],axis=1)
 d['frames']=np.array([(v-center)@rot.T+c for rot,c in transforms]);d['normals']=np.tile(d['normals'][0],(41,1))
 write_mdl(OUT/f'w{wid}.mdl',d)
 # Preserve upstream external skin overrides, when present, without modifying them.
 import shutil
 for ext in ['pcx','tga']:
  src=Path(str(path)+'_0.'+ext)
  if src.exists():shutil.copy2(src,OUT/f'w{wid}.mdl_0.{ext}')
(OUT/'manifest.json').write_text(json.dumps({'frames':41,'weapons':weapons,'body_vertices':801,'body_triangles':940,'attachment':'one non-solid entity per bot; same pose index and origin as body'},indent=2))
print('Built',len(weapons),'held weapons and two faction models:',sum(p.stat().st_size for p in OUT.iterdir()),'bytes')
