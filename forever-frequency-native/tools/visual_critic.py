"""Strict reproducible VISUAL CRITIC for actual Godot framebuffer outputs.

This gate cannot declare art 'premium' from numerical stats. It rejects obvious
failures (blank camera, clipped/washed exposure, same view, missing scene, bad
frame size). A human must still inspect all 4 viewpoints.
"""
from PIL import Image, ImageStat, ImageFilter
from pathlib import Path
import math, json, sys
root=Path(__file__).resolve().parents[1]
names=["preview_real_godot.png","preview_city_aerial.png",
       "preview_market_street.png","preview_studio_closeup.png"]
failures=[]
reports={}
thumbs=[]
def fail(desc):
    failures.append(desc)
    print("VISUAL-RED:",desc,flush=True)
for name in names:
    f=root/name
    if not f.is_file() or f.stat().st_size<45000:
        fail(name+": real camera PNG missing or suspiciously tiny")
        continue
    with Image.open(f) as source:
        rgb=source.convert('RGB')
        w,h=rgb.size
        if w<1000 or h<550:fail(name+": screenshot resolution too small")
        reduced=rgb.resize((256,144))
        px=list(reduced.getdata())
        total=len(px)
        luminance=[(0.2126*r+0.7152*g+0.0722*b)/255.0 for r,g,b in px]
        mean=sum(luminance)/total
        variance=sum((p-mean)**2 for p in luminance)/total
        dark=sum(1 for p in luminance if p<.035)/total
        white=sum(1 for p in luminance if p>.96)/total
        hist=rgb.convert('L').histogram()
        ent=0.0
        for count in hist:
            if count:
                p=count/(w*h)
                ent-=p*math.log2(p)
        edges=reduced.filter(ImageFilter.FIND_EDGES).convert('L')
        edge_fraction=sum(1 for v in edges.getdata() if v>50)/total
        report=dict(width=w,height=h,bytes=f.stat().st_size,
                    luminance=round(mean,3),contrast=round(math.sqrt(variance),3),
                    very_dark_fraction=round(dark,3),clipped_white_fraction=round(white,3),
                    entropy_bits=round(ent,2),edge_fraction=round(edge_fraction,3))
        reports[name]=report
        print("VISUAL CRITIC",name,report,flush=True)
        if mean<.09 or mean>.89:fail(name+": gross under/overexposure")
        if math.sqrt(variance)<.09:fail(name+": scene lacks measurable contrast")
        if white>.15:fail(name+": excessively blown highlights")
        if dark>.58:fail(name+": excessive crushed black")
        if ent<5.3:fail(name+": looks flat/blank at screenshot scale")
        if edge_fraction<.022:fail(name+": almost no readable model detail")
        thumbs.append((name,list(reduced.resize((32,18)).getdata())))
for i in range(len(thumbs)):
    for j in range(i):
        n1,p1=thumbs[i];n2,p2=thumbs[j]
        delta=sum(abs(a-b) for c1,c2 in zip(p1,p2) for a,b in zip(c1,c2))/(len(p1)*3*255)
        if delta<.028:fail(n1+" and "+n2+" almost identical: multi-angle audit is fake")
out=root/"visual_critic_report.json"
out.write_text(json.dumps(dict(photos=reports,failures=failures),indent=2))
if failures:
    print("VISUAL GAUNTLET RED",len(failures),"issues",flush=True)
    sys.exit(1)
if len(reports)!=4:
    sys.exit(1)
print("VISUAL GAUNTLET GREEN — four independently reviewed raw Godot renders",flush=True)
