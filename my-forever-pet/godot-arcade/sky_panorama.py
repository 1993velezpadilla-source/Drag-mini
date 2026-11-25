"""Original layered equirectangular skies: shaped cumulus clouds, sun and stars."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
w,h=2048,1024
rng=np.random.default_rng(1961)
lon=np.linspace(-np.pi,np.pi,w,endpoint=False)[None,:]
lat=np.linspace(np.pi/2,-np.pi/2,h)[:,None]
def wrap(x):return (x+np.pi)%(2*np.pi)-np.pi
def noise(cols,rows):
 a=rng.random((rows,cols))
 a=np.concatenate([a,a[:,:1]],axis=1)
 return np.asarray(Image.fromarray(np.uint8(a*255)).resize((w+max(1,w//cols),h),Image.Resampling.BICUBIC),dtype=np.float32)[:,:w]/255
n=.52*noise(48,24)+.30*noise(110,55)+.18*noise(240,120)
cloud=np.zeros((h,w),np.float32)
for i in range(52):
 cx=rng.uniform(-np.pi,np.pi);cy=rng.uniform(-.48,.69)
 sx=rng.uniform(.10,.30);sy=rng.uniform(.055,.16)
 for j in range(5):
  dx=wrap(lon-cx-(j-1.5)*sx*.38)
  dy=lat-cy-rng.uniform(-.05,.06)
  q=(dx/sx)**2+(dy/sy)**2
  cloud=np.maximum(cloud,np.clip((1-q)*2.5,0,1))
cloud=np.clip(cloud+(n-.48)*1.2,0,1)*np.clip(cloud*5,0,1)
shade=np.clip(.61+lat*.40+(n-.45)*1.2,0,1)
def make(name,top,horizon,below,light,dark,night=False):
 t=np.clip(lat/(np.pi/2),0,1)**.65
 rgb=np.broadcast_to(np.array(horizon)+(np.array(top)-horizon)*t[...,None],(h,w,3)).copy()
 under=np.clip(-lat*1.1,0,1)
 rgb=rgb*(1-under[...,None])+np.array(below)*under[...,None]
 d=(wrap(lon-.6)*np.cos(lat))**2+(lat-.47)**2
 glow=np.exp(-d/(.15 if night else .24))
 rgb=rgb*(1-glow[...,None]*.24)+np.array(light)*glow[...,None]*.24
 sun=np.clip((.045-np.sqrt(d))/.012,0,1)
 rgb=rgb*(1-sun[...,None])+np.array(light)*sun[...,None]
 if night:
  rr=np.random.default_rng(91)
  for i in range(750):
   yy=rr.integers(0,h//2);xx=rr.integers(0,w)
   rgb[yy,xx]=[215,228,255]
   if i%13==0 and yy+1<h:rgb[yy+1,xx]=[150,180,240]
 cr=np.array(dark)+(np.array(light)-dark)*shade[...,None]
 a=cloud*(.80 if night else .97)
 rgb=rgb*(1-a[...,None])+cr*a[...,None]
 for i in range(24):
  blend=(1-i/24)
  avg=(rgb[:,i]+rgb[:,-1-i])*.5
  rgb[:,i]=rgb[:,i]*(1-blend)+avg*blend
  rgb[:,-1-i]=rgb[:,-1-i]*(1-blend)+avg*blend
 Image.fromarray(np.uint8(np.clip(rgb,0,255))).save(name)
p=Path(sys.argv[1])
make(p,[13,75,191],[57,157,232],[103,165,226],[255,251,239],[130,165,211])
make(p.with_name('sky-crystal.png'),[43,75,163],[109,221,224],[99,133,181],[221,255,250],[112,158,206])
make(p.with_name('sky-moon.png'),[14,19,65],[85,76,139],[53,51,100],[218,228,255],[72,87,151],True)
