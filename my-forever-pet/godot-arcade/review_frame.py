"""Detect gross render failures; these thresholds are not a visual parity score."""
import json,sys
from PIL import Image
im=Image.open(sys.argv[1]).convert("RGB")
w,h=im.size
assert h>w and w>=480,(w,h)
# Restrict to road/character band, excluding HUD and sky.
roi=im.crop((int(w*.10),int(h*.55),int(w*.90),int(h*.83)))
pixels=list(roi.getdata())
n=len(pixels)
white=sum(min(p)>=230 for p in pixels)/n
bright=sum(max(p)>=250 and min(p)>=185 for p in pixels)/n
dark=sum(max(p)<35 for p in pixels)/n
mean=sum(.2126*r+.7152*g+.0722*b for r,g,b in pixels)/n
result={"width":w,"height":h,"road_near_white_fraction":white,"road_bright_fraction":bright,"road_dark_fraction":dark,"road_mean_luma":mean,"scope":"gross clipping and black-frame guard only; not artistic approval"}
with open(sys.argv[2],"w") as out:json.dump(result,out,indent=2)
assert white<.48 and bright<.72 and dark<.75 and 35<mean<231,result
