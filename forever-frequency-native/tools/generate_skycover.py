"""Equirectangular alpha-cloud layer for Godot ProceduralSkyMaterial.
Lightweight procedural original image, deterministic, editable parameters.
Uses Pillow only, no generative-image model, no third-party texture rights.
"""
from PIL import Image,ImageFilter
from pathlib import Path
import random, math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets';OUT.mkdir(exist_ok=True)
W,H=1024,512
random.seed(20261124)
def layer(w,h,scale):
    im=Image.new('L',(w,h))
    im.putdata([random.randrange(256) for _ in range(w*h)])
    return im.resize((W,H),Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(scale))
rough=layer(18,9,7)
detail=layer(64,32,3)
fine=layer(152,76,1)
im=Image.new('RGBA',(W,H))
out=[]
for y in range(H):
    v=y/(H-1)
    # Concentrate cirrus/cumulus in the upper half of visible sky,
    # fading towards the street horizon and leaving clear gaps.
    latmask=max(0.0,min(1.0,(v-.08)/.25))*max(0.0,min(1.0,(.73-v)/.30))
    for x in range(W):
        a=(rough.getpixel((x,y))*.57+detail.getpixel((x,y))*.31+fine.getpixel((x,y))*.12)/255
        fog=max(0.0,min(1.0,(a-.42)/.23))
        alpha=int((fog**1.55)*latmask*135)
        # Warm pink cloud edge with lavender shade.
        c=int(max(0,min(255,210+25*(1-v))))
        out.append((c,int(142+29*v),int(167+35*v),alpha))
im.putdata(out)
im.save(OUT/'cloud_cover.png',optimize=True)
assert (OUT/'cloud_cover.png').stat().st_size>20000
print('DUSK SKY ART PASS GREEN',OUT/'cloud_cover.png',flush=True)
