"""Non-mutating Audi R8 panel discovery from an already verified source master.

Run with Blender --background --python this_file -- --source path.glb
--receipt receipt.json --output inventory.json. This identifies original
mesh components, not semantic doors or approval. Do not cut or rig anything
until the actual original parts are independently visually identified.
"""
import argparse
import hashlib
import json
import math
import sys
from collections import Counter
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:])

def vector(v):
    return [round(float(x), 7) for x in v]

def tri(obj):
    return sum(len(p.vertices)-2 for p in obj.data.polygons)

def inspect_components(obj):
    bm = bmesh.new()
    try:
        bm.from_mesh(obj.data)
        bm.faces.ensure_lookup_table()
        bm.faces.index_update()
        world = obj.matrix_world.copy()
        remaining = set(bm.faces)
        found = []
        while remaining:
            seed = remaining.pop()
            stack = [seed]
            faces = []
            while stack:
                face = stack.pop()
                faces.append(face)
                for edge in face.edges:
                    for other in edge.link_faces:
                        if other in remaining:
                            remaining.remove(other)
                            stack.append(other)
            vertices = {v for f in faces for v in f.verts}
            points = [world @ v.co for v in vertices]
            low = Vector(min(p[i] for p in points) for i in range(3))
            high = Vector(max(p[i] for p in points) for i in range(3))
            assert all(math.isfinite(float(x)) for x in (*low, *high))
            mats = Counter()
            for face in faces:
                mats[face.material_index] += len(face.verts)-2
            indices = sorted(f.index for f in faces)
            fingerprint = hashlib.sha256(",".join(map(str, indices)).encode()).hexdigest()
            edges = {e for f in faces for e in f.edges}
            record = {
                "first_polygon_index": indices[0],
                "polygon_index_sha256": fingerprint,
                "triangles": sum(mats.values()),
                "polygons": len(faces),
                "vertices": len(vertices),
                "bounds_low": vector(low),
                "bounds_high": vector(high),
                "bounds_center": vector((low+high)*.5),
                "dimensions": vector(high-low),
                "boundary_edges": sum(e.is_boundary for e in edges),
                "non_manifold_edges": sum(not e.is_manifold for e in edges),
                "material_triangles": [
                    {"slot": k, "name": obj.data.materials[k].name
                     if k<len(obj.data.materials) and obj.data.materials[k] else None,
                     "triangles": v} for k,v in sorted(mats.items())
                ]
            }
            found.append(record)
        assert sum(c["triangles"] for c in found)==tri(obj)
        return sorted(found,key=lambda c:(-c["triangles"],c["first_polygon_index"]))
    finally:
        bm.free()

def main():
    args=parse_args()
    receipt=json.loads(args.receipt.read_text())
    assert receipt["license"]=="CC BY 4.0" and receipt["artist"]
    assert receipt["source_uid"] in {"d10f75f74355452f8e417cc36f253841","2dee503c05f940739ff6f9e2b3562337","e17e438f076f4427a58d93aa779edaed"}
    digest=hashlib.sha256(args.source.read_bytes()).hexdigest()
    if digest != receipt["sha256"]:
        raise RuntimeError("Source must be the exact archive GLB, not a converted export")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(args.source))
    bpy.context.view_layer.update()
    meshes=sorted((o for o in bpy.data.objects if o.type=="MESH"),key=lambda o:o.name)
    assert meshes and sum(map(tri,meshes))==receipt["source_triangles"]
    inventory=[]
    for obj in meshes:
        if not obj.data.polygons:
            continue
        components=inspect_components(obj)
        inventory.append({"object":obj.name,"mesh":obj.data.name,
                          "triangles":tri(obj),"components":components})
    assert sum(o["triangles"] for o in inventory)==receipt["source_triangles"]
    report={"source_sha256":digest,"source_uid":receipt["source_uid"],
            "artist":receipt["artist"],"source_triangles":receipt["source_triangles"],
            "objects":inventory,"total_components":sum(len(o["components"]) for o in inventory),
            "source_geometry_modified":False,"semantic_panel_identity_verified":False,
            "interior_verified":False,"shipping_approved":False}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+"\n")
    print("AUDI_R8_SOURCE_CONNECTED_COMPONENT_FORENSICS_COMPLETE_NOT_APPROVED",
          json.dumps({k:v for k,v in report.items() if k!="objects"}),flush=True)

if __name__=="__main__":
    main()
