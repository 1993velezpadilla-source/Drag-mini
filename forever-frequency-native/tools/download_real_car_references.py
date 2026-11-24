#!/usr/bin/env python3
"""Download genuine licensed photographs from Wikimedia Commons to a CI artifact.

Images are for authored geometry inspection; do not package into the Android APK.
Each image has per-file original author/license/source, a 1600px research copy,
SHA256 and pixel verification. FAIL closed on missing/mislicensed references.
"""
import hashlib
import json
import re
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageOps, ImageFont
from io import BytesIO

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"data"/"real_vehicle_photo_references.json"
OUT=ROOT/"real_car_photo_references"
OUT.mkdir(parents=True,exist_ok=True)
DATA=json.loads(MANIFEST.read_text(encoding="utf-8"))
API="https://commons.wikimedia.org/w/api.php"
HEADERS={"User-Agent":"CityZeroAutomotiveReferenceResearch/1.0 (github.com/1993velezpadilla-source/Drag-mini; Wikimedia Commons attribution QC)"}
session=requests.Session()
session.headers.update(HEADERS)

def fetch_photo(title):
    params={"action":"query","format":"json","formatversion":2,
        "prop":"imageinfo","titles":"File:"+title,
        "iiprop":"url|size|sha1|extmetadata","iiurlwidth":1600}
    response=session.get(API,params=params,timeout=50)
    response.raise_for_status()
    payload=response.json()
    pages=payload["query"]["pages"]
    if len(pages)!=1 or "imageinfo" not in pages[0]:
        raise RuntimeError("Missing real Commons image: "+title)
    info=pages[0]["imageinfo"][0]
    url=info.get("thumburl") or info["url"]
    blob=session.get(url,timeout=80)
    blob.raise_for_status()
    if not blob.headers.get("Content-Type","").lower().startswith("image/"):
        raise RuntimeError("Not a genuine image: "+title)
    image=Image.open(BytesIO(blob.content))
    image.load()
    if image.width<700 or image.height<400:
        raise RuntimeError("Reference is too small: "+title)
    return info, image.convert("RGB"), url, blob.content

def verify_license(expected,info,title):
    metadata=info.get("extmetadata",{})
    short=re.sub(r"<[^>]+>","",str(metadata.get("LicenseShortName",{}).get("value",""))).lower()
    usage=re.sub(r"<[^>]+>","",str(metadata.get("UsageTerms",{}).get("value",""))).lower()
    text=short+" "+usage
    if expected=="CC0" and "cc0" not in text and "cc-zero" not in text:
        raise RuntimeError("CC0 license inconsistent: "+title+" "+short)
    if expected=="CC BY-SA 4.0" and not ("by-sa" in text and "4.0" in text):
        raise RuntimeError("Attribution license inconsistent: "+title+" "+short)
    if expected=="public domain" and "public domain" not in text and "pd" not in short:
        raise RuntimeError("PD license inconsistent: "+title+" "+short)
    return short

def card(photo,label):
    tile=ImageOps.pad(photo,(560,340),method=Image.Resampling.LANCZOS,
        color=(235,238,242))
    panel=Image.new("RGB",(600,405),"#161b24")
    panel.paste(tile,(20,16))
    draw=ImageDraw.Draw(panel)
    draw.text((20,363),label[:76],fill="#ffffff")
    return panel

evidence=[]
for vehicle in DATA["vehicle_references"]:
    directory=OUT/vehicle["id"]
    directory.mkdir(parents=True,exist_ok=True)
    for reference in vehicle["photos"]:
        title=reference["file"]
        info,img,url,raw=fetch_photo(title)
        verified=verify_license(reference["license"],info,title)
        target=directory/(reference["view"]+".jpg")
        img.thumbnail((1600,1400),Image.Resampling.LANCZOS)
        img.save(target,format="JPEG",quality=89,subsampling=0,optimize=True)
        row={"vehicle":vehicle["id"],"real_car":vehicle["real_reference"],
            "view":reference["view"],"filename":str(target.relative_to(OUT)),
            "file_title":title,"author":reference["author"],
            "expected_license":reference["license"],"verified_license":verified,
            "description_url":info.get("descriptionurl"),
            "download_url":url,"image_sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
            "original_sha1":info.get("sha1"),"bytes":target.stat().st_size,
            "resolution":list(img.size)}
        evidence.append(row)
        print("REAL CAR PHOTO SAVED",row["vehicle"],row["view"],row["bytes"],
            row["verified_license"],flush=True)
    rows=[x for x in evidence if x["vehicle"]==vehicle["id"]]
    montage=Image.new("RGB",(600*len(rows),405),"#10151f")
    for i,entry in enumerate(rows):
        im=Image.open(OUT/entry["filename"])
        montage.paste(card(im,vehicle["real_reference"]+" - "+entry["view"]), (600*i,0))
    montage.save(directory/"actual_reference_contact_sheet.jpg",quality=88)
assert len(evidence)==12
(OUT/"credits_and_hashes.json").write_text(json.dumps(evidence,indent=2)+"\n",encoding="utf-8")
print("12 AUTHENTIC LICENSED AUTOMOTIVE PHOTOGRAPHS SAVED FOR BLENDER REFERENCE - NOT CAR APPROVAL",flush=True)
