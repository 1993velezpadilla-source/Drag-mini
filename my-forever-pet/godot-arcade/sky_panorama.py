"""Original deterministic equirectangular cloud texture, no external assets."""
import sys
import numpy as np
from PIL import Image
w,h=2048,1024
rng=np.random.default_rng(1961)
x=np.linspace(0,2*np.pi,w,endpoint=False)[None,:]
lat=np.linspace(np.pi/2,-np.pi/2,h)[:,None]
def noise(cols,rows):
 a=rng.random((rows,cols))
 # wrap horizontally for a seamless panorama
 a=np.concatenate([a,a[:,:1]],axis=1)
 im=Image.fromarray(np.uint8(a*255)).resize((w+max(1,w//cols),h),Image.Resampling.BICUBIC)
 return np.asarray(im,dtype=np.float32)[:,:w]/255
n=.58*noise(16,9)+.26*noise(34,17)+.11*noise(75,37)+.05*noise(150,75)
sky_t=np.clip(lat/(np.pi/2),0,1)
horizon=np.array([108,181,241],dtype=np.float32)
zenith=np.array([18,76,193],dtype=np.float32)
rgb=np.broadcast_to(horizon+(zenith-horizon)*sky_t[...,None],(h,w,3)).copy()
# Layer broad cumulus banks around the horizon and wisps above.
band=np.exp(-((lat-.23)/.46)**2)
coverage=np.clip((n-.49)*6.0,0,1)*band
coverage*=np.clip((lat+.10)*10,0,1)
shadow=np.clip((n-.43)*3.2,0,1)
cloud=np.stack([205+50*shadow,222+33*shadow,241+14*shadow],axis=-1)
rgb=rgb*(1-coverage[...,None])+cloud*coverage[...,None]
below=np.clip(-lat*1.6,0,1)
rgb=rgb*(1-below[...,None])+np.array([105,153,214])*below[...,None]
blend=64
for i in range(blend):
 t=(1-i/blend)*.5
 avg=(rgb[:,i]+rgb[:,-1-i])*.5
 rgb[:,i]=rgb[:,i]*(1-t*2)+avg*t*2
 rgb[:,-1-i]=rgb[:,-1-i]*(1-t*2)+avg*t*2
Image.fromarray(np.uint8(np.clip(rgb,0,255))).save(sys.argv[1])
