"""Native Quake MDL parsing helpers for model build and geometry inspection."""
import struct
from pathlib import Path
import numpy as np

def read_mdl(path):
 b=Path(path).read_bytes();h=struct.unpack_from('<ii3f3ff3f8if',b);ns,w,ht,nv,nt,nf=h[12:18];off=84;skins=[]
 for _ in range(ns):
  assert struct.unpack_from('<i',b,off)[0]==0
  off+=4;skins.append(b[off:off+w*ht]);off+=w*ht
 uv=np.array([struct.unpack_from('<3i',b,off+i*12) for i in range(nv)]);off+=nv*12
 tris=np.array([struct.unpack_from('<4i',b,off+i*16) for i in range(nt)]);off+=nt*16
 frames=[];normals=[];names=[]
 for _ in range(nf):
  assert struct.unpack_from('<i',b,off)[0]==0
  names.append(b[off+12:off+28].split(b'\0')[0].decode());off+=28
  raw=np.frombuffer(b[off:off+nv*4],np.uint8).reshape(nv,4);off+=nv*4
  frames.append(raw[:,:3]*np.array(h[2:5])+np.array(h[5:8]));normals.append(raw[:,3])
 return dict(header=h,skins=skins,uv=uv,tris=tris,frames=np.array(frames),normals=np.array(normals),names=names)

if __name__=='__main__':
 import matplotlib;matplotlib.use('Agg')
 import matplotlib.pyplot as plt
 from mpl_toolkits.mplot3d.art3d import Poly3DCollection
 d=read_mdl('assets/common/models/player.mdl');fig=plt.figure(figsize=(14,7))
 for i,frame in enumerate([0,4,9,15,24,38]):
  ax=fig.add_subplot(2,3,i+1,projection='3d');v=d['frames'][frame]
  ax.add_collection3d(Poly3DCollection(v[d['tris'][:,1:]],facecolor='#9caa88',edgecolor='#333333',linewidth=.12))
  ax.set(xlim=(-40,50),ylim=(-45,45),zlim=(-45,50),title=f'frame {frame}');ax.view_init(10,-50);ax.set_box_aspect((1,1,1))
 fig.tight_layout();fig.savefig('skirmish/preview/base-poses.png')

def write_mdl(path, model):
 frames=np.asarray(model['frames']);nf,nv,_=frames.shape;lo=frames.min(axis=(0,1));hi=frames.max(axis=(0,1));scale=np.maximum((hi-lo)/255,.0001)
 h=list(model['header']);h[2:5]=scale;h[5:8]=lo;h[8]=float(np.max(np.linalg.norm(frames,axis=2)));h[12]=len(model['skins']);h[15]=nv;h[16]=len(model['tris']);h[17]=nf;h[18]=0;h[19]=0
 b=bytearray(struct.pack('<ii3f3ff3f8if',*h))
 for skin in model['skins']: b.extend(struct.pack('<i',0));b.extend(skin)
 b.extend(np.asarray(model['uv'],dtype='<i4').tobytes());b.extend(np.asarray(model['tris'],dtype='<i4').tobytes())
 for f,v in enumerate(frames):
  q=np.clip(np.rint((v-lo)/scale),0,255).astype(np.uint8);normal=model['normals'][f] if len(model['normals'])==nf else model['normals'][0]
  b.extend(struct.pack('<i',0));b.extend(bytes(q.min(0))+b'\0'+bytes(q.max(0))+b'\0');b.extend(f'pose_{f}'.encode().ljust(16,b'\0'));b.extend(np.column_stack([q,normal]).astype(np.uint8).tobytes())
 Path(path).parent.mkdir(parents=True,exist_ok=True);Path(path).write_bytes(b)
