"""Contact sheets: LEFT real licensed photograph / RIGHT real Blender GLB render."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps
import json

R=Path(__file__).resolve().parents[1]
cfg=json.loads((R/"data"/"real_vehicle_photo_references.json").read_text())
source=R/"real_car_photo_references"
out=R/"real_car_comparison"
out.mkdir(exist_ok=True)
for rec in cfg["vehicle_references"]:
    panels=[]
    for item in rec["photos"]:
        picture=source/rec["id"]/(item["view"]+".jpg")
        render=out/(rec["id"]+"-"+item["view"]+"-blender.png")
        assert picture.is_file() and render.is_file(),(picture,render)
        tile=Image.new("RGB",(1440,485),"#10141a")
        photo=ImageOps.pad(Image.open(picture).convert("RGB"),(700,400),color=(225,229,232))
        model=ImageOps.pad(Image.open(render).convert("RGB"),(700,400),color=(225,229,232))
        tile.paste(photo,(10,48));tile.paste(model,(730,48))
        d=ImageDraw.Draw(tile)
        d.text((12,10),"REAL PHOTO - "+rec["real_reference"]+" / "+item["view"],fill="white")
        d.text((731,10),"CITY ZERO - actual Blender GLB",fill="white")
        d.text((12,460),item["author"]+" / "+item["license"],fill="#cccfd4")
        d.text((731,460),"NOT YET SHAPE APPROVED; not matched camera perspective",fill="#f2bb73")
        panels.append(tile)
    contact=Image.new("RGB",(1440,485*len(panels)),"#141923")
    for i,tile in enumerate(panels):contact.paste(tile,(0,485*i))
    output=out/(rec["id"]+"-real-vs-blender.jpg")
    contact.save(output,quality=90,optimize=True)
    assert output.stat().st_size>40000
    print("REAL PHOTO VS REAL BLENDER CONTACT SHEET",output,flush=True)
assert len(list(out.glob("*-real-vs-blender.jpg")))==4
