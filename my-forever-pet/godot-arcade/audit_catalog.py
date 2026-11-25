"""Independent glTF technical inventory, never equivalent to artistic approval."""
import json, hashlib, struct, math, sys
from pathlib import Path
root=Path(sys.argv[1]); metrics=json.loads((root/'mesh-metrics.json').read_text())
out={}
assert set(metrics)=={p.stem for p in root.glob('*.glb')}
for name,m in sorted(metrics.items()):
 p=root/(name+'.glb');data=p.read_bytes()
 assert struct.unpack('<4sII',data[:12])==(b'glTF',2,len(data)),name
 size,kind=struct.unpack_from('<I4s',data,12);assert kind==b'JSON',name
 g=json.loads(data[20:20+size])
 access=g['accessors']; mats=g.get('materials',[]);count=0;bounds=[]
 assert mats and g.get('meshes'),name
 for mesh in g['meshes']:
  for prim in mesh['primitives']:
   assert prim.get('mode',4)==4 and 0<=prim.get('material',-1)<len(mats),name
   pos=access[prim['attributes']['POSITION']]
   assert pos['type']=='VEC3' and pos['count']>0,name
   lo,hi=pos['min'],pos['max']
   assert all(math.isfinite(v) for v in lo+hi) and all(a<=b for a,b in zip(lo,hi)),name
   bounds.append((lo,hi))
   n=access[prim['indices']]['count'] if 'indices' in prim else pos['count']
   assert n%3==0 and n>0,name
   count+=n//3
 assert count==m['triangles'] and count<=m['triangle_cap'],(name,count,m)
 assert len(data)==m['bytes'] and len(data)<24_000_000,name
 for im in g.get('images',[]):
  assert 'bufferView' in im and 0<=im['bufferView']<len(g['bufferViews']),name
 for buf in g.get('buffers',[]): assert 'uri' not in buf,name
 low=[min(b[0][i] for b in bounds) for i in range(3)]
 high=[max(b[1][i] for b in bounds) for i in range(3)]
 out[name]={'sha256':hashlib.sha256(data).hexdigest(),'triangles':count,'cap':m['triangle_cap'],'materials':len(mats),'images':len(g.get('images',[])),'mesh_local_bounds':[low,high],'technical_pass':True,'art_approved':False,'android_approved':False}
 print('PET_GLTF_AUDIT_PASS',name,count,len(mats))
(root/'catalog-audit.json').write_text(json.dumps({'assets':out,'count':len(out),'scope':'technical validation only; no visual or device approval'},indent=2))
