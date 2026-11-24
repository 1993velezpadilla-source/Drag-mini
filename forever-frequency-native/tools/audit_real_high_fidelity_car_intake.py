"""City Zero legal, high-fidelity REAL-MESH car intake (fail closed).

Does not download protected assets, generate box cars, or approve screenshots.
Reviews optional local assets/pending_real_cars/<id>.glb plus separate
<id>.license.json rightsholder/attribution receipts before ANY distribution.
Output contains truthful "not imported" statuses for missing assets.
"""
from pathlib import Path
import hashlib,json,struct,re

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'data'/'high_fidelity_real_car_candidates.json'
PENDING=ROOT/'assets'/'pending_real_cars'
OUT=ROOT/'artifacts'/'high_fidelity_car_intake'
OUT.mkdir(parents=True,exist_ok=True)
data=json.loads(MANIFEST.read_text())
assert data['schema_version']==1
assert data['candidate_count']==len(data['candidates'])>=15
ids=set();uids=set();results=[]
MAX_LOD1_TRIANGLES=65000
for car in data['candidates']:
    name=car['id'];uid=car['sketchfab_uid']
    assert re.fullmatch(r'[a-z0-9_]{5,60}',name),name
    assert re.fullmatch(r'[0-9a-f]{32}',uid),name
    assert name not in ids and uid not in uids
    ids.add(name);uids.add(uid)
    assert car['source_url'].startswith('https://sketchfab.com/3d-models/')
    assert uid in car['source_url']
    if 'NC' in car['public_search_result_license'].upper().split():
        raise RuntimeError('Noncommercial candidate not permitted: '+name)
    path=PENDING/(name+'.glb')
    result={'id':name,'make':car['make'],'model':car['model'],
            'creator_claimed':car['creator_claimed'],
            'source_url':car['source_url'],
            'status':'NOT_DOWNLOADED_NOT_IMPORTED',
            'art_approved':False,'godot_approved':False}
    if not path.exists():
        results.append(result)
        continue
    receipt=PENDING/(name+'.license.json')
    if not receipt.is_file():
        raise RuntimeError('Real binary exists but ORIGINAL CREATOR LICENSE RECEIPT is missing: '+name)
    provenance=json.loads(receipt.read_text())
    assert provenance.get('source_uid')==uid
    assert provenance.get('source_page')==car['source_url']
    assert provenance.get('license') in ('CC0','CC BY 4.0','CC BY 3.0')
    assert provenance.get('creator_rights_verified') is True
    assert provenance.get('downloaded_using_permitted_account') is True
    assert provenance.get('source_file_sha256')
    blob=path.read_bytes()
    assert hashlib.sha256(blob).hexdigest()==provenance['source_file_sha256']
    if len(blob)<100000 or blob[:4]!=b'glTF':
        raise RuntimeError('Not a real binary GLB: '+name)
    version,length=struct.unpack_from('<II',blob,4)
    if version!=2 or length!=len(blob):
        raise RuntimeError('Malformed GLB v2: '+name)
    length_json,magic=struct.unpack_from('<I4s',blob,12)
    if magic!=b'JSON':raise RuntimeError('Missing GLB JSON '+name)
    doc=json.loads(blob[20:20+length_json])
    if not doc.get('meshes') or not doc.get('nodes') or not doc.get('materials'):
        raise RuntimeError('Not textured 3D authored car model '+name)
    faces=0;materials=set();primitives=0
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            primitives+=1
            if p.get('mode',4)!=4 or p.get('indices') is None:
                raise RuntimeError('Nontriangular/incomplete source mesh '+name)
            acc=doc['accessors'][p['indices']]
            if acc['count']%3:raise RuntimeError('Broken triangle accessor '+name)
            faces+=acc['count']//3
            if 'material' in p:materials.add(p['material'])
    if faces<25000:
        raise RuntimeError('Model too low-detail for Lamborghini-quality acceptance '+name)
    if len(materials)<3:
        raise RuntimeError('Insufficient real exterior/glass/tire material separation '+name)
    result.update(status='SOURCE_GLB_LOADED_PENDING_BLENDER_GODOT_VISUAL_REVIEW',
                  source_triangles=faces,mesh_count=len(doc['meshes']),
                  material_count=len(materials),scene_node_count=len(doc['nodes']),
                  downloaded_sha256=provenance['source_file_sha256'],
                  lod1_needs_retopology=faces>MAX_LOD1_TRIANGLES)
    results.append(result)
status={'schema_version':1,'candidate_count':len(results),
        'real_assets_present':sum(x['status'].startswith('SOURCE_GLB_LOADED') for x in results),
        'game_ready_count':0,'claim':'SOURCE REVIEW ONLY, NO GAME-READY CARS WITHOUT REAL 3D VISUAL+HINGE+GODOT REVIEW',
        'vehicles':results}
(OUT/'intake_report.json').write_text(json.dumps(status,indent=2)+'\n')
print('CITY ZERO REAL CAR LICENSE-AWARE INTAKE',len(results),'candidates',
      status['real_assets_present'],'actual licensed GLBs present; ZERO falsely approved',flush=True)
