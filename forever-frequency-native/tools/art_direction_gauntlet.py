"""A deliberately STRICT art-direction gate for City Zero 2026.

Targets are measured from TWO user-provided visual REFERENCE paintings, not from
existing Godot output. This does not test gameplay or prove photorealism; it
rejects the previously flat grey/low-detail visual signature automatically.
Screenshots are always published even if this gate rejects them for human audit.
"""
from pathlib import Path
from PIL import Image,ImageFilter
import json,numpy as np,sys
R=Path(__file__).resolve().parents[1]
files=["preview_real_godot.png","preview_city_aerial.png","preview_market_street.png","preview_studio_closeup.png"]
# Target refs, sampled at 512x288:
# reference 1: sat .356, color_range .180, edge .240
# reference 2: sat .384, color_range .199, edge .268
# The first pass requires only ~80% of reference color richness / ~65% of
# reference detail; progressively tighten once multiple angles pass.
minimum={
    "preview_real_godot.png":(.285,.145,.160),
    "preview_city_aerial.png":(.290,.145,.150),
    "preview_market_street.png":(.290,.145,.160),
    "preview_studio_closeup.png":(.285,.145,.155),
}
errors=[];results={}
for file in files:
    p=R/file
    if not p.exists():
        errors.append(file+": MISSING REAL GODOT FRAME")
        continue
    im=Image.open(p).convert("RGB").resize((512,288))
    a=np.asarray(im,dtype=np.float32)/255
    mx=a.max(axis=2);mn=a.min(axis=2)
    sat=float(np.mean((mx-mn)/np.maximum(mx,1e-5)))
    color=float(np.mean(mx-mn))
    edges=np.asarray(im.filter(ImageFilter.FIND_EDGES).convert("L"),dtype=np.float32)/255
    detail=float((edges>.22).mean())
    scores=(sat,color,detail)
    goals=minimum[file]
    results[file]={k:round(v,4) for k,v in zip(["saturation","color_spread","edge_density"],scores)}
    for metric,value,target in zip(["color saturation","scene color variation","geometry detail"],scores,goals):
        if value<target:
            errors.append("%s %s %.3f < %.3f TARGET — REJECT"%(file,metric,value,target))
(R/"art_direction_report.json").write_text(json.dumps({"reference":"two user-provided 2026 City Zero target images","metrics":results,"rejected_for":errors},indent=2))
for err in errors:print("ART DIRECTION RED",err,flush=True)
if errors:sys.exit(1)
print("ART DIRECTION GAUNTLET GREEN — four scenes passed strict reference-inspired color/detail thresholds",flush=True)
