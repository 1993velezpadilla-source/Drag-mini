"""Import genuinely artist-made premium CC-BY supercar GLBs with pinned Git blobs.

The orange City Zero Lamborghini is a SEPARATE user-approved SHA-locked GLB.
These six DISTINCT cars are inspection-only models, not gameplay-approved and
NOT commercial-cleared by merely reading a third-party GitHub license notice.
Source mesh geometry is never substituted with invented procedural bodies.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import struct
from urllib.request import Request, urlopen

ROOT=Path(__file__).resolve().parents[1]
META=ROOT/"data"/"pinned_artist_licensed_premium_car_sources.json"
SRC=ROOT/"assets"/"tevy_cc0_original_sources"
DECODED=ROOT/"assets"/"tevy_cc0_decoded_sources"
AUDIT=ROOT/"real_cc0_source_vehicle_audit"
for target in (SRC,DECODED,AUDIT):target.mkdir(parents=True,exist_ok=True)
data=json.loads(META.read_text())
assert data["schema_version"]==1 and data["production_approved"] is False
assert data["repository"]=="supercar3d/supercar_3D_asssets"
pinned=data["pinned_commit"]
assert re.fullmatch(r"[0-9a-f]{40}",pinned)
batch=int(os.getenv("CITYZERO_ARTIST_PREMIUM_BATCH_INDEX","0"))
batch_size=int(os.getenv("CITYZERO_ARTIST_PREMIUM_BATCH_SIZE","6"))
assert 0<=batch<=100 and 1<=batch_size<=6
inventory=data["records"]
assert len(inventory)>=6 and len({x["id"] for x in inventory})==len(inventory)
selected=inventory[batch*batch_size:(batch+1)*batch_size]
if not selected:raise RuntimeError("No genuine art sources in requested batch")

def pinned_raw(path):
    if not re.fullmatch(r"[A-Za-z0-9_./-]+",path) or ".." in path:
        raise RuntimeError("Unsafe upstream path "+path)
    url="https://raw.githubusercontent.com/"+data["repository"]+"/"+pinned+"/"+path
    request=Request(url,headers={"User-Agent":"CityZero-Clean-Source-Blender-Audit/1.0"})
    with urlopen(request,timeout=120) as result:
        blob=result.read(50_000_001)
    if len(blob)>50_000_000:raise RuntimeError("Original source exceeds size cap "+path)
    return blob,url

out=[]
for spec in selected:
    name=spec["id"]
    if not re.fullmatch(r"[a-z][a-z0-9_]{5,65}",name):raise RuntimeError("Invalid source model id")
    binary,source_url=pinned_raw(spec["path"])
    git_blob=hashlib.sha1(b"blob "+str(len(binary)).encode()+b"\0"+binary).hexdigest()
    if git_blob!=spec["git_blob_sha1"]:
        raise RuntimeError("UNTRUSTED MODIFIED CAR BINARY "+name)
    if binary[:4]!=b"glTF" or len(binary)<500_000:
        raise RuntimeError("Real high-quality model is missing "+name)
    magic,version,total=struct.unpack_from("<4sII",binary)
    if magic!=b"glTF" or version!=2 or total!=len(binary):
        raise RuntimeError("Not a full original glTF2 source "+name)
    header_len,header_type=struct.unpack_from("<I4s",binary,12)
    if header_type!=b"JSON":raise RuntimeError("Missing authentic glTF JSON chunk "+name)
    gltf=json.loads(binary[20:20+header_len])
    if not gltf.get("meshes") or not gltf.get("materials"):
        raise RuntimeError("Original mesh lacks body/material geometry "+name)
    triangles=0
    for mesh in gltf["meshes"]:
        for face in mesh.get("primitives",[]):
            if face.get("mode",4)!=4:continue
            if "indices" in face:
                count=gltf["accessors"][face["indices"]]["count"]
            else:
                count=gltf["accessors"][face["attributes"]["POSITION"]]["count"]
            triangles+=int(count/3)
    if triangles<spec["expected_min_triangles"]:
        raise RuntimeError("Model below independent high-detail triangle floor "+name+": "+str(triangles))

    license_binary,license_url=pinned_raw(spec["license"])
    license_text=license_binary.decode("utf-8-sig","replace")
    if not ("Creative Commons Attribution" in license_text
            and "creativecommons.org/licenses/by/4.0/" in license_text):
        raise RuntimeError("Model lacks its individual original artist CC-BY notice "+name)
    if any(x in license_text.lower() for x in
           ("noncommercial","non-commercial","not for commercial","by-nc/","by-sa/")):
        raise RuntimeError("Noncommercial or different license disallowed pending review "+name)
    if spec["artist"].casefold() not in license_text.casefold():
        raise RuntimeError("Model artist notice does not match pinned metadata "+name)
    creator_links=re.findall(r"https://skfb\.ly/[A-Za-z0-9]+",license_text)
    if not creator_links:raise RuntimeError("Artist original model page missing "+name)

    target=SRC/(name+".glb")
    target.write_bytes(binary)
    shutil.copyfile(target,DECODED/target.name)
    (AUDIT/(name+"_origin_license.txt")).write_text(license_text)
    sha256=hashlib.sha256(binary).hexdigest()
    original={
        "id":name,"name":spec["label"],"description":"Artist-authored original 3D source; third-party CC-BY 4.0 notice, commercial rights unverified",
        "source_glb":source_url,
        "source_page":creator_links[0],
        "license":"CC BY 4.0 THIRD_PARTY_NOTICE, RIGHTS_CLEARANCE_PENDING",
        "license_url":license_url,"source_artist":spec["artist"],
        "sha256":sha256,"bytes":len(binary),
        "git_blob_sha1":git_blob,
        "author_declared_triangles_lod0":triangles,
        "target_longest_extent_m":float(spec["expected_longest_extent_m"]),
        "physical_length_reference":spec["length_source"],
        "preserve_original_source_unchanged":True,
        "dimensions":None,
        "parts":[],
        "visual_rights_review_pending":True,
        "source_identity_verified":True,
        "game_ready":False,"user_approved":False,
    }
    out.append(original)
    print("CITYZERO_REAL_PREMIUM_ARTIST_SOURCE_HASH_GREEN",name,triangles,len(binary),flush=True)

manifest={"batch_index":batch,"batch_size":batch_size,"models":out,
          "source_catalog_count":len(inventory),
          "status":"SIX_AUTHENTIC_ARTIST_MODELS_HASH_VERIFIED__NOT_COMMERCIAL_OR_GAMEPLAY_APPROVED",
          "licensing_note":"Original artist attribution provided. DO NOT ship brand names, original logos or meshes in a paid game until independent rights review.",
          "approved_orange_lamborghini_is_different_asset":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"}
(AUDIT/"downloaded_original_cc0_vehicle_batch.json").write_text(json.dumps(manifest,indent=2)+"\n")
(AUDIT/"pinned_artist_original_licensed_source_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("CITYZERO_SIX_AUTHENTIC_PREMIUM_ARTIST_CAR_SOURCES_GREEN",len(out),flush=True)
