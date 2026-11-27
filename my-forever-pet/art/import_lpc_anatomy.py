#!/usr/bin/env python3
"""Import licensed upstream LPC anatomy strips without redrawing their frames."""
import argparse, hashlib, json, urllib.request
from pathlib import Path
from PIL import Image, ImageDraw
PIN = "86a3719ee4a7e2e9fb27c7c152e29a741d3e930a"
ROOT = "https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/"+PIN+"/"
PARTS = {
    "cat_tail": ("body/tails/tail_cat.json", "green", "CC-BY 3.0+"),
    "wolf_tail": ("body/tails/tail_wolf.json", "gray", "CC-BY 3.0+"),
    "bat_wings": ("body/wings/wings_bat.json", "black", "OGA-BY 3.0"),
    "feathered_wings": ("body/wings/wings_feathered.json", "white", "OGA-BY 3.0"),
}
ANIMS = {"idle":"idle", "walk":"walk", "attack":"slash", "cast":"spellcast", "hurt":"hurt", "jump":"jump"}
def download(path):
    req=urllib.request.Request(ROOT+path, headers={"User-Agent":"Kindria-licensed-art-import"})
    with urllib.request.urlopen(req,timeout=45) as res: return res.read()
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("output",type=Path)
    out=ap.parse_args().output
    out.mkdir(parents=True,exist_ok=True)
    manifest={"source_commit":PIN,"source":ROOT,"parts":{}}
    credits=[]
    for name,(definition,color,license_name) in PARTS.items():
        data=json.loads(download("sheet_definitions/"+definition))
        assert any(license_name in item["licenses"] for item in data["credits"]), name
        credits.extend(data["credits"])
        part={"definition":definition,"chosen_license":license_name,"credits":data["credits"],"clips":{}}
        for pose,anim in ANIMS.items():
            clip={}
            for layer,source_layer in (("front","layer_1"),("back","layer_2")):
                remote="spritesheets/"+data[source_layer]["male"]+anim+"/"+color+".png"
                raw=download(remote)
                path=out/name/pose/(layer+".png")
                path.parent.mkdir(parents=True,exist_ok=True)
                path.write_bytes(raw)
                im=Image.open(path).convert("RGBA")
                assert im.width%64==0 and im.height in (64,256), (remote,im.size)
                clip[layer]={"path":str(path.relative_to(out)),"source_path":remote,"sha256":hashlib.sha256(raw).hexdigest(),"frames":im.width//64,"rows":im.height//64}
            assert clip["front"]["frames"]==clip["back"]["frames"],(name,pose)
            part["clips"][pose]=clip
        manifest["parts"][name]=part
        # Contact sheet uses original RGBA cells on neutral background; no fabricated body.
        width=640
        height=len(ANIMS)*112
        sheet=Image.new("RGBA",(width,height),"#242a32")
        draw=ImageDraw.Draw(sheet)
        for i,(pose,clip) in enumerate(part["clips"].items()):
            draw.text((8,i*112+5),pose,fill="white")
            bg=Image.open(out/clip["back"]["path"]).convert("RGBA")
            fg=Image.open(out/clip["front"]["path"]).convert("RGBA")
            for j,row in enumerate((2,0,1,3) if bg.height==256 else (0,)):
                for k,frame in enumerate((0,bg.width//128,bg.width//64-1)):
                    cell=Image.new("RGBA",(64,64))
                    box=(frame*64,row*64,(frame+1)*64,(row+1)*64)
                    cell.alpha_composite(bg.crop(box))
                    cell.alpha_composite(fg.crop(box))
                    cell=cell.resize((48,48),Image.Resampling.NEAREST)
                    sheet.alpha_composite(cell,(8+(j*3+k)*52,i*112+28))
        sheet.save(out/(name+"_preview.png"))
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    (out/"credits.json").write_text(json.dumps(credits,indent=2)+"\n")
    print("KINDRIA_LPC_IMPORT_PASS parts=4 clips=24 layers=48")
if __name__=="__main__":main()
