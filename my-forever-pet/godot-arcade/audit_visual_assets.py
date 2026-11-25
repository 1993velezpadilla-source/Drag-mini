import json, pathlib, struct, sys
from PIL import Image, ImageChops
root=pathlib.Path(sys.argv[1])
def inspect(path):
 data=path.read_bytes()
 magic,version,size=struct.unpack_from('<4sII',data)
 assert magic==b'glTF' and version==2 and size==len(data),path
 length,kind=struct.unpack_from('<II',data,12)
 doc=json.loads(data[20:20+length])
 tris=0
 for mesh in doc['meshes']:
  for prim in mesh['primitives']:
   assert prim.get('mode',4)==4,path
   tris+=doc['accessors'][prim['indices']]['count']//3
 return {'bytes':len(data),'triangles':tris,'materials':len(doc.get('materials',[]))}
report={}
# Use the approved 3980-triangle Mosskit as the actual mobile baseline.
reference=inspect(root/'mosskit.glb')
for p in sorted((root/'creatures').glob('*.glb')):
 m=inspect(p);assert reference['triangles']*.5<=m['triangles']<=42000,(p,m);assert m['materials']>=3,(p,m)
 report[p.name]=m
assert len(report)==23
for p in sorted((root/'rooms').glob('*.glb')):
 m=inspect(p);assert 5000<=m['triangles']<=260000,(p,m);assert m['materials']>=8,(p,m)
 report[p.name]=m
assert len(report)==29
for i in range(24):
 p=root/('pet_%d.png'%i)
 im=Image.open(p).convert('RGBA');a=im.getchannel('A');b=a.getbbox()
 assert b and b[0]>0 and b[1]>0 and b[2]<im.width and b[3]<im.height,(p,b)
 assert (b[2]-b[0])>=im.width*.25 and (b[3]-b[1])>=im.height*.25,(p,b)
 report[p.name]={'alpha_bounds':b}
(root/'visual-asset-audit.json').write_text(json.dumps(report,indent=2))
print('VISUAL_ASSET_AUDIT_PASS',len(report))
