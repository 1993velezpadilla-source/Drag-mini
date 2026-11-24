#!/usr/bin/env python3
"""PS2-era vehicle specialist gate for reference-led Blender assets.

A car is NOT approved merely because Blender exported a GLB or a door pivot moves.
An independent external automotive Blender skill authors the geometry; this
tool refuses a release unless actual shape reference, panel motion, imported
GLB, and explicit human close-up approval all exist. Reference masks/photos
are PRIVATE -- never automatically uploaded into this public repository.

Usage:
 python3 tools/vehicle_specialist_gate.py --self-test
 python3 tools/vehicle_specialist_gate.py --run runs/aura_city_c_2025 --refs /private/vehicle_references/aura_city_c_2025
"""
import argparse
import json
import sys
from pathlib import Path

ORTHO=("side_left","front","rear")
PHOTO=("front34","rear34")
MASKS=ORTHO+PHOTO
QUALITY=["silhouette","front_lighting_detail","rear_lighting_detail",
         "wheel_placement","body_surface","panel_gaps","glazing","door_motion",
         "interior","game_art_style"]

def mask_iou(reference,render):
    from PIL import Image
    a=Image.open(reference).convert("L")
    b=Image.open(render).convert("L")
    if a.size!=b.size or min(a.size)<(128,128):
        raise ValueError("Reference and Blender mask must have identical >=128px dimensions")
    pa=list(a.getdata())
    pb=list(b.getdata())
    both=sum(x>=128 and y>=128 for x,y in zip(pa,pb))
    either=sum(x>=128 or y>=128 for x,y in zip(pa,pb))
    if either==0:
        raise ValueError("Blank reference and/or renderer masks")
    return both/either

def inspect(run,refs,vehicle_id):
    issues=[];proof={};score={}
    for view in MASKS:
        ref=refs/(view+".reference-mask.png")
        render=run/"renders"/(view+".render-mask.png")
        if not ref.exists() or not render.exists():
            issues.append("Missing real reference/matched render: "+view)
            continue
        try:
            val=mask_iou(ref,render)
            score[view]=round(val,5)
            threshold=.95 if view in ORTHO else .90
            if val<threshold:
                issues.append(f"{view}: silhouette mismatch IoU {val:.3f}, required {threshold:.2f}")
        except Exception as e:
            issues.append(view+": "+str(e))
    for filename,place in [
      ("build.json","checks"),("doors.json","checks"),
      ("doors-reimport.json","checks")]:
        p=run/place/filename
        if not p.exists():
            issues.append("Missing mandatory mesh/hinge proof "+filename)
            continue
        try:
            d=json.loads(p.read_text())
            proof[filename]=d
            if d.get("pass") is not True:
                issues.append(filename+": substantive validation did not pass")
        except (OSError,ValueError) as e:
            issues.append(filename+": malformed JSON "+str(e))
    # Avoid confusing an exported placeholder with a real Blender-built file.
    for name in [vehicle_id+".blend",vehicle_id+".glb"]:
        p=run/name
        if not p.exists() or p.stat().st_size<30000:
            issues.append("Missing or undersized actual Blender deliverable "+name)
    # Human review requires EVERY named property rated >= 4/5. This is never
    # inferred from automated tests and no workflow can write it as success.
    approval=run/"human_visual_review.json"
    if not approval.is_file():
        issues.append("Human full-angle visual review not performed")
    else:
        try:
            d=json.loads(approval.read_text())
            if d.get("decision")!="APPROVE":
                issues.append("Human visual review explicitly REJECTED")
            marks=d.get("marks",{})
            for name in QUALITY:
                if not isinstance(marks.get(name),int) or marks[name]<4 or marks[name]>5:
                    issues.append("Visual rating not >=4/5: "+name)
            if not d.get("reviewer") or not d.get("notes"):
                issues.append("Visual critic attribution and notes missing")
        except (OSError,ValueError) as e:
            issues.append("Invalid visual review: "+str(e))
    return {"vehicle":vehicle_id,"status":"APPROVED" if not issues else "REJECTED",
            "shape_iou":score,"missing_or_failed_gates":issues,
            "is_shippable":not bool(issues)}

def self_test():
    from PIL import Image,ImageDraw
    from tempfile import TemporaryDirectory
    with TemporaryDirectory() as temp:
        d=Path(temp)
        a=Image.new("L",(256,256),0)
        ImageDraw.Draw(a).rectangle([40,55,185,160],fill=255)
        b=a.copy()
        a.save(d/"a.png")
        b.save(d/"b.png")
        assert mask_iou(d/"a.png",d/"b.png")==1
        b=Image.new("L",(256,256),0)
        ImageDraw.Draw(b).rectangle([122,120,220,220],fill=255)
        b.save(d/"b.png")
        assert mask_iou(d/"a.png",d/"b.png")<.2
        report=inspect(d,d,"no_real_vehicle")
        assert report["status"]=="REJECTED"
        assert any("Human" in v for v in report["missing_or_failed_gates"])
    print("SPECIALIST QUALITY GATE SELF-TEST GREEN (incomplete cars are rejected)")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--run",type=Path)
    p.add_argument("--refs",type=Path)
    p.add_argument("--self-test",action="store_true")
    a=p.parse_args()
    if a.self_test:
        self_test();return 0
    if not a.run or not a.refs:
        p.error("--run and --refs are both required for real car acceptance")
    report=inspect(a.run,a.refs,a.run.name)
    target=a.run/"checks"/"ps2_vehicle_quality_gate.json"
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(report,indent=2)+"\n")
    print("CITY ZERO SPECIALIST VEHICLE:",report["status"])
    for v in report["missing_or_failed_gates"]:print("  RED:",v)
    return 0 if report["is_shippable"] else 1
if __name__=="__main__":
    sys.exit(main())
