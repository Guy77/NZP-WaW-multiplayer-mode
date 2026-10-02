"""Render native model geometry/material previews; not a gameplay screenshot."""
from pathlib import Path
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from mdl_tools import read_mdl
r=Path(__file__).resolve().parents[2];p=r/'skirmish/generated/models/skirmish';pal=np.frombuffer((r/'assets/common/gfx/palette.lmp').read_bytes(),np.uint8).reshape(256,3)/255
fig=plt.figure(figsize=(12,6),facecolor='#171e25')
for col,team in enumerate(['allies','axis']):
 ax=fig.add_subplot(1,2,col+1,projection='3d',facecolor='#171e25')
 for name in [team,'w12' if col==0 else 'w15']:
  d=read_mdl(p/(name+'.mdl'));v=d['frames'][0];uv=d['uv'][:,1:].copy();colors=[];skin=np.frombuffer(d['skins'][0],np.uint8).reshape(d['header'][14],d['header'][13])
  for tr in d['tris']:
   st=uv[tr[1:]].copy()
   for j,idx in enumerate(tr[1:]):
    if not tr[0] and d['uv'][idx,0]:st[j,0]+=d['header'][13]//2
   st=np.rint(st.mean(0)).astype(int);colors.append(pal[skin[st[1]%skin.shape[0],st[0]%skin.shape[1]]])
  ax.add_collection3d(Poly3DCollection(v[d['tris'][:,1:]],facecolors=colors,edgecolor='none'))
 ax.set(xlim=(-20,60),ylim=(-40,40),zlim=(-37,43));ax.set_box_aspect((1,1,1));ax.view_init(5,-45);ax.set_axis_off();ax.set_title(team.upper(),color='white',fontsize=18)
fig.savefig(r/'skirmish/preview/factions.png',facecolor=fig.get_facecolor(),bbox_inches='tight')
