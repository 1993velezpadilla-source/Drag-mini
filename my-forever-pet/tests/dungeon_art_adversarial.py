"""Independent GLB geometry regression; run against production ZIP or GLB directory.
No Blender exporter statistics trusted. A changed material alone cannot pass.
Exit 1 on geometry/footprint failures. Never grants artistic approval.
"""
import argparse, hashlib, json, math, struct, sys, zipfile
from pathlib import Path
BIOMES=('forest','reef','star')
PARTS=('wall','rock_0','rock_1','rock_2','span','corner')

def read_catalog(path):
    path=Path(path)
    if path.is_file():
        with zipfile.ZipFile(path) as z:
            return {Path(n).stem:z.read(n) for n in z.namelist() if Path(n).name.startswith('dungeon_') and n.endswith('.glb')}
    return {p.stem:p.read_bytes() for p in path.glob('dungeon_*.glb')}

def inspect_glb(blob):
    magic,version,length=struct.unpack_from('<4sII',blob)
    if magic!=b'glTF' or version!=2 or length!=len(blob):raise ValueError('invalid GLB header')
    size,kind=struct.unpack_from('<I4s',blob,12)
    if kind!=b'JSON':raise ValueError('missing JSON')
    doc=json.loads(blob[20:20+size]);offset=20+size
    bin_size,kind=struct.unpack_from('<I4s',blob,offset)
    if kind!=b'BIN\0':raise ValueError('missing BIN')
    data=memoryview(blob)[offset+8:offset+8+bin_size]
    lo=[math.inf]*3;hi=[-math.inf]*3;points=set();tris=0
    for node in doc['nodes']:
        if any(k in node for k in ('matrix','rotation','translation','scale','children')):raise ValueError('unbaked node transform or hierarchy')
        if 'mesh' not in node:continue
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            a=doc['accessors'][primitive['attributes']['POSITION']];view=doc['bufferViews'][a['bufferView']]
            if a['componentType']!=5126 or a['type']!='VEC3' or 'sparse' in a:raise ValueError('unsupported POSITION accessor')
            start=view.get('byteOffset',0)+a.get('byteOffset',0);stride=view.get('byteStride',12)
            for i in range(a['count']):
                xyz=struct.unpack_from('<3f',data,start+i*stride)
                if not all(math.isfinite(v) for v in xyz):raise ValueError('non-finite vertex')
                for k,v in enumerate(xyz):lo[k]=min(lo[k],v);hi[k]=max(hi[k],v)
                points.add(tuple(round(v,5) for v in xyz))
            if primitive.get('mode',4)!=4:raise ValueError('non-triangle primitive')
            tris+=doc['accessors'][primitive['indices']]['count']//3 if 'indices' in primitive else a['count']//3
    if not points:raise ValueError('empty geometry')
    def digest(coords):
        return hashlib.sha256(json.dumps(sorted(coords),separators=(',',':')).encode()).hexdigest()
    # Reject a cosmetic move or resize of the same mesh. Quantization removes
    # harmless exporter float noise and ignores duplicated UV seam vertices.
    center=[(lo[k]+hi[k])*.5 for k in range(3)]
    size=[hi[k]-lo[k] for k in range(3)]
    if min(size)<=1e-7:raise ValueError('collapsed wall axis')
    shape={tuple(round((p[k]-center[k])/size[k],3) for k in range(3)) for p in points}
    return {'geometry_sha256':digest(points),'normalized_shape_sha256':digest(shape),'bounds':[lo,hi],'triangles':tris,'unique_vertices':len(points)}

def evaluate(candidate,baseline=None):
    results={};failures=[]
    for biome in BIOMES:
        for part in PARTS:
            name=f'dungeon_{biome}_{part}'
            if name not in candidate:failures.append(f'{name}: missing');continue
            try:r=inspect_glb(candidate[name])
            except (ValueError,KeyError,struct.error) as exc:failures.append(f'{name}: {exc}');continue
            results[name]=r
            if baseline is not None:
                if name not in baseline:failures.append(f'{name}: missing baseline')
                else:
                    try:old=inspect_glb(baseline[name])
                    except (ValueError,KeyError,struct.error) as exc:failures.append(f'{name}: invalid baseline: {exc}');continue
                    if r['geometry_sha256']==old['geometry_sha256']:failures.append(f'{name}: geometry unchanged (material changes do not count)')
                    elif r['normalized_shape_sha256']==old['normalized_shape_sha256']:failures.append(f'{name}: normalized shape unchanged (translation or resize does not count)')
            lo,hi=r['bounds'];half_x=1.4 if part=='span' else .7
            # 3 cm tolerance for bevels; this is a conservative geometry bound, not collision proof.
            if max(-lo[0],hi[0])>half_x+.03 or max(-lo[2],hi[2])>.73:
                failures.append(f'{name}: exceeds {2*half_x:.1f} x 1.4 wall footprint; bounds={[[round(v,3) for v in x] for x in (lo,hi)]}')
    return {'checked':len(results),'baseline_compared':baseline is not None,'failures':failures,'assets':results,'art_approved':False,
            'limitations':'Coordinate fingerprints detect exact reuse and many resizes, not semantic or artistic similarity. Review actual renders separately.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('candidate');parser.add_argument('--baseline');args=parser.parse_args()
    report=evaluate(read_catalog(args.candidate),read_catalog(args.baseline) if args.baseline else None)
    print(json.dumps(report,indent=2));sys.exit(bool(report['failures']))
