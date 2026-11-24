#!/usr/bin/env python3
"""Blender headless export for real NFSU2 vehicle models: every body-kit and part.

Each car produces stock.glb and independent GLBs of all unique kit + family
variants. Optional --every-lod also exports lower-detail LODs. Uses only the
user's original GEOMETRY.BIN / TEXTURES.BIN; it never generates fake car shapes.
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

def best_variants(parts, every_lod=False):
    order = {"A": 0, "B": 1, "C": 2, "D": 3, None: 4}
    if every_lod:
        return sorted(parts, key=lambda p: (str(p.kit), str(p.family), str(p.lod), p.name))
    best = {}
    for p in parts:
        group = (p.kit or "BASE", p.family)
        old = best.get(group)
        if old is None or (order.get(p.lod, 5), -p.nverts) < (order.get(old.lod, 5), -old.nverts):
            best[group] = p
    return sorted(best.values(), key=lambda p: (str(p.kit), str(p.family), p.name))

def safe_name(s):
    return re.sub(r"[^a-zA-Z0-9._-]+", "_", s).strip("._")[:90] or "part"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--car", type=Path, required=True)
    parser.add_argument("--converter-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--kit", default="KIT00")
    parser.add_argument("--lod", default="A")
    parser.add_argument("--every-lod", action="store_true")
    parser.add_argument("--max-parts", type=int, default=0)
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    a = parser.parse_args(argv)
    repo = a.converter_dir.resolve()
    if not (repo / "nfsu2_world_editor" / "blender" / "car_importer.py").is_file():
        parser.error("NFSU2-World-Editor checkout not found")
    sys.path.insert(0, str(repo))
    import bpy
    from nfsu2_world_editor.blender import car_importer, importer
    from nfsu2_world_editor.core import cars

    a.out.mkdir(parents=True, exist_ok=True)
    importer.clear_scene()
    geometry_path, texture_path, folder = cars.car_files(a.car)
    global_dir = cars.default_global_dir(folder)
    car_importer.import_car(str(a.car), kit=a.kit, lod=a.lod,
                            global_dir=str(global_dir) if global_dir else None,
                            textures=True)
    model = cars.CarGeometry.open(geometry_path)
    stock = a.out / "stock.glb"
    bpy.ops.export_scene.gltf(filepath=str(stock), export_format="GLB",
                              export_extras=True, use_selection=False)

    lib = None
    if texture_path:
        global_packs = []
        if global_dir and Path(global_dir).is_dir():
            global_packs = [str(f) for f in Path(global_dir).iterdir()
                            if f.is_file() and f.suffix.lower() in (".bin", ".bun")]
        packs = cars.load_car_textures(texture_path, global_packs)
        lib = car_importer._HashLib(cars.texture_lookup(packs))
    material_cache = {}
    rows = []
    parts = best_variants(model.parts, a.every_lod)
    if a.max_parts:
        parts = parts[:max(0, a.max_parts)]
    for idx, part in enumerate(parts, start=1):
        kit = safe_name(part.kit or "BASE")
        family = safe_name(part.family)
        destination = (a.out / "parts" / kit / family /
                       (safe_name(part.name) + "_" + f"{part.hash:08X}.glb"))
        destination.parent.mkdir(parents=True, exist_ok=True)
        mesh = car_importer._build_car_mesh(part, lib, (0.75, 0.06, 0.07, 1.0), material_cache)
        obj = bpy.data.objects.new(part.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.matrix_basis = car_importer._part_basis(part)
        obj["nfs_hash"] = f"{part.hash:08X}"
        obj["nfs_kit"] = part.kit or "BASE"
        obj["nfs_family"] = part.family
        obj["nfs_lod"] = part.lod or ""
        obj["cityzero_source"] = "genuine_nfsu2_own_install"
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.gltf(filepath=str(destination), export_format="GLB",
                                  export_extras=True, use_selection=True)
        rows.append({"name": part.name, "kit": part.kit, "family": part.family,
                     "lod": part.lod, "hash": f"{part.hash:08X}", "triangles": part.nfaces,
                     "glb": destination.relative_to(a.out).as_posix()})
        bpy.data.objects.remove(obj, do_unlink=True)
        if idx % 50 == 0:
            print(f"[City Zero] {model.name}: {idx}/{len(parts)} physical parts exported")
    report = {"car": model.name, "stock": "stock.glb", "parts": rows,
              "source_path": str(a.car), "private_use_only": True,
              "animation_limitation": "PARTS_ANIMATIONS.BIN keyframes not yet imported"}
    (a.out / "models.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("[City Zero] EXPORTED:", model.name, len(rows), "authentic GLB part variants")

if __name__ == "__main__":
    main()
