#!/usr/bin/env python3
"""Screen existing LPC parts for placement issues. No production approval or new art."""
import argparse, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageFilter
POSES = ("idle", "walk", "attack", "cast", "hurt", "jump")
DIR_ROWS = (2,0,1,3)
TIMES = (0,.5,.999)
CANDIDATES = (("mosky","cat_tail",32),("bramble_pup","wolf_tail",32),
              ("nebulwing","bat_wings",40),("sylphowl","feathered_wings",40))
def count(mask):
    return sum(mask.histogram()[1:])
def cell(sheet,direction,phase,size,pose):
    n=sheet.width//64
    frame=min(n-1,int(TIMES[phase]*n))
    row=DIR_ROWS[direction] if sheet.height==256 else 0
    return sheet.crop((frame*64,row*64,frame*64+64,row*64+64)).resize((size,size),Image.Resampling.NEAREST)
def canvas(image,xy):
    result=Image.new("RGBA",(96,96))
    result.alpha_composite(image,xy)
    return result
def mask(im):
    return im.getchannel("A").point(lambda a:255 if a>12 else 0)
def evaluate(body,back,front,dx,dy):
    x=(96-back.width)//2+dx
    y=(96-back.height)//2+dy
    bg=canvas(back,(x,y)); fg=canvas(front,(x,y))
    part=Image.alpha_composite(bg,fg)
    bm=mask(body); pm=mask(part); fm=mask(fg)
    # Touch includes a 2px tolerance; assess clipping on the padded canvas.
    contact=count(ImageChops.multiply(pm,bm.filter(ImageFilter.MaxFilter(5))))
    pixels=count(pm)
    front_overlap=count(ImageChops.multiply(fm,bm))
    outside=pixels-count(pm.crop((24,24,72,72)))
    visible=count(ImageChops.subtract(pm,bm))
    result=Image.alpha_composite(Image.alpha_composite(bg,body),fg)
    score=outside*12 + (40 if pixels and not contact else 0) + front_overlap*1.5
    if pixels and visible==0:score+=35
    if pixels:score+=max(0,4-contact)*5
    return score,{"part_pixels":pixels,"contact_pixels":contact,"outside_pixels":outside,
                  "front_overlap_pixels":front_overlap,"exterior_pixels":visible},result.crop((24,24,72,72))
def main():
    ap=argparse.ArgumentParser();ap.add_argument("root",type=Path);root=ap.parse_args().root
    manifest=json.loads((root/"manifest.json").read_text())
    output=root/"fitting"; reports=[]
    for creature,part,nominal in CANDIDATES:
        sources=manifest["parts"][part]["clips"]
        images={(pose,layer):Image.open(root/sources[pose][layer]["path"]).convert("RGBA")
                for pose in POSES for layer in ("back","front")}
        bodies={(pose,d,k):canvas(Image.open(output/"body"/creature/f"{pose}-{d}-{k}.png").convert("RGBA"),(24,24))
                for pose in POSES for d in range(4) for k in range(3)}
        choices=[]; sheet=Image.new("RGBA",(1152,576),"#252c34")
        for direction in range(4):
            options=[]
            for size in (nominal-8,nominal,nominal+8):
                # Fit on idle, attack, walk representative samples; audit all 18 later.
                samples=[(pose,k,bodies[pose,direction,k],
                          cell(images[pose,"back"],direction,k,size,pose),
                          cell(images[pose,"front"],direction,k,size,pose))
                         for pose in ("idle","walk","attack") for k in (0,2)]
                for dx in (-8,-4,0,4,8):
                    for dy in (-8,-4,0,4,8):
                        stats=[evaluate(b,bg,fg,dx,dy) for _,_,b,bg,fg in samples]
                        score=sum(x[0] for x in stats)+.35*(abs(dx)+abs(dy))+.5*abs(size-nominal)
                        options.append((score,size,dx,dy))
            score,size,dx,dy=min(options)
            records=[]
            for i,pose in enumerate(POSES):
                for k in range(3):
                    body=bodies[pose,direction,k]
                    _,stats,result=evaluate(body,cell(images[pose,"back"],direction,k,size,pose),
                        cell(images[pose,"front"],direction,k,size,pose),dx,dy)
                    records.append({"pose":pose,"phase":k,**stats})
                    x=(direction*3+k)*96;y=i*96+24
                    sheet.alpha_composite(body.crop((24,24,72,72)),(x,y))
                    sheet.alpha_composite(result,(x+48,y))
            choices.append({"direction":direction,"size":size,"offset":[dx,dy],"score":score,
                "samples":records,"clipped":sum(r["outside_pixels"]>0 for r in records),
                "detached":sum(r["part_pixels"]>0 and r["contact_pixels"]==0 for r in records)})
        sheet.save(output/f"{creature}-{part}-screened.png")
        report={"creature":creature,"source_part":part,"approved":False,"directions":choices}
        reports.append(report)
        print("KINDRIA_FIT_SCREEN",creature,"clipped",sum(c["clipped"] for c in choices),
              "detached",sum(c["detached"] for c in choices),
              "placements",[(c["direction"],c["size"],c["offset"]) for c in choices])
    (output/"placement-screen.json").write_text(json.dumps({"candidates":reports,"approved":False},indent=2)+"\n")
    print("KINDRIA_FIT_SCREEN_PASS candidates=4 samples=288")
if __name__=="__main__":main()
