#!/usr/bin/env python3
"""City Zero read-only NFSU2 source inventory + GLB node/parts audit (stdlib only).

No proprietary models, textures, sound or archive payloads are exported.
"""
import argparse
import json
import re
import struct
from pathlib import Path

SOURCE = ("GEOMETRY.BIN", "TEXTURES.BIN", "VINYLS.BIN", "PARTS_ANIMATIONS.BIN")
PARTS = {
    "hood_under": ("_HOOD_UNDER",), "trunk_under": ("_TRUNK_UNDER",),
    "trunk_audio": ("_TRUNK_AUDIO",), "front_bumper": ("_FRONT_BUMPER",),
    "rear_bumper": ("_REAR_BUMPER",), "door_left": ("_DOOR_LEFT",),
    "door_right": ("_DOOR_RIGHT",), "headlight": ("_HEADLIGHT",),
    "taillight": ("_BRAKELIGHT",), "skirt": ("_SKIRT",),
    "spoiler": ("_SPOILER",), "engine": ("_ENGINE",),
    "hood": ("_HOOD",), "trunk": ("_TRUNK",),
    "wheel": ("_WHEEL",), "rim": ("_RIM",),
    "exhaust": ("_EXHAUST",), "mirror": ("_SIDE_MIRROR", "_WING_MIRROR"),
    "interior": ("_INTERIOR", "_BASE"), "body": ("_BODY_", "_BODY")
}
PIVOT_MARKERS = ("_ZAM_HOOD_", "_ZAM_TRUNK_", "_ZAM_LEFT_DOOR_", "_ZAM_RIGHT_DOOR_")

def classify(name):
    name = name.upper()
    if name.startswith("MARKER_") or name.startswith("_ZAM_"):
        return None
    for kind, patterns in PARTS.items():
        if any(pattern in name for pattern in patterns):
            return kind
    return None

def read_glb(path):
    """Read only the bounded glTF JSON header. Mesh binary data is never extracted."""
    path = Path(path)
    with path.open("rb") as stream:
        header = stream.read(12)
        if len(header) != 12:
            raise ValueError("Truncated GLB header")
        magic, version, declared = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2:
            raise ValueError("Expected glTF 2.0 GLB")
        if declared != path.stat().st_size or declared < 20:
            raise ValueError("GLB declared length mismatch")
        chunk = stream.read(8)
        if len(chunk) != 8:
            raise ValueError("Missing JSON chunk header")
        size, kind = struct.unpack("<I4s", chunk)
        if kind != b"JSON" or size > 64_000_000 or size + 20 > declared:
            raise ValueError("Invalid GLB JSON chunk")
        payload = stream.read(size)
        if len(payload) != size:
            raise ValueError("Truncated GLB JSON")
    data = json.loads(payload)
    if not isinstance(data, dict) or not isinstance(data.get("nodes", []), list):
        raise ValueError("Invalid glTF root or node list")
    return data

def inspect_glb(path):
    doc = read_glb(path)
    nodes, meshes = doc.get("nodes", []), doc.get("meshes", [])
    accessors = doc.get("accessors", [])
    groups, pivots, audio, trunk_neon, unmatched = {}, [], [], [], []
    total_triangles = 0
    mesh_nodes = 0
    for index, node in enumerate(nodes):
        if not isinstance(node, dict):
            continue
        name = str(node.get("name", "node_" + str(index)))
        upper = name.upper()
        if any(p in upper for p in PIVOT_MARKERS):
            pivots.append(name)
        if re.search(r"MARKER_AUDIO_COMP_(?:[0-9]|1[01])(?:$|\b)", upper):
            audio.append(name)
        if "MARKER_TRUNK_NEON_" in upper:
            trunk_neon.append(name)
        mesh_id = node.get("mesh")
        if not isinstance(mesh_id, int) or mesh_id < 0 or mesh_id >= len(meshes):
            continue
        mesh_nodes += 1
        group = classify(name)
        (groups.setdefault(group, []) if group else unmatched).append(name)
        mesh = meshes[mesh_id]
        if not isinstance(mesh, dict):
            continue
        for primitive in mesh.get("primitives", []):
            if not isinstance(primitive, dict) or primitive.get("mode", 4) != 4:
                continue
            position = primitive.get("attributes", {}).get("POSITION")
            accession = primitive.get("indices", position)
            if isinstance(accession, int) and 0 <= accession < len(accessors):
                accessor = accessors[accession]
                if isinstance(accessor, dict):
                    total_triangles += max(0, int(accessor.get("count", 0)) // 3)
    warnings = []
    if mesh_nodes == 0:
        warnings.append("No renderable mesh nodes")
    for part in ("hood", "trunk"):
        if part in groups and not any(part.upper() in name.upper() for name in pivots):
            warnings.append(part + " has no explicitly named hinge pivot")
    if "trunk_audio" in groups and not audio:
        warnings.append("Trunk audio mesh without MARKER_AUDIO_COMP sockets")
    if "trunk_audio" not in groups:
        warnings.append("Trunk audio absent (may be supplied as separate authorized GLB)")
    return {
        "file": str(path), "node_count": len(nodes), "mesh_nodes": mesh_nodes,
        "mesh_definitions": len(meshes), "material_count": len(doc.get("materials", [])),
        "estimated_triangles": total_triangles,
        "part_groups": {key: sorted(values) for key, values in sorted(groups.items())},
        "hinge_nodes": sorted(pivots), "speaker_mounts": sorted(audio),
        "trunk_neon_mounts": sorted(trunk_neon),
        "unclassified_mesh_nodes": unmatched[:80], "warnings": warnings
    }

def inspect_game_root(root):
    root = Path(root)
    cars = root / "CARS" if (root / "CARS").is_dir() else root
    if not cars.is_dir():
        raise FileNotFoundError("Missing CARS folder: " + str(cars))
    found = []
    for folder in sorted(p for p in cars.iterdir() if p.is_dir()):
        entries = {p.name.upper(): p for p in folder.iterdir() if p.is_file()}
        if "GEOMETRY.BIN" not in entries:
            continue
        files = {name: {"present": name in entries,
                        "bytes": entries[name].stat().st_size if name in entries else 0}
                 for name in SOURCE}
        found.append({
            "xname": folder.name, "files": files,
            "missing_required": [name for name in SOURCE[:2] if name not in entries],
            "animated_parts_file_available": files["PARTS_ANIMATIONS.BIN"]["present"]
        })
    return {
        "cars_folder": str(cars), "car_count": len(found), "cars": found,
        "note": "File presence is not proof the vehicle meshes, pivots or animations work."
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-root", type=Path, help="A personally owned game folder or CARS")
    parser.add_argument("--glb-root", type=Path, help="Authorized Blender-exported GLB directory")
    parser.add_argument("--out", type=Path, default=Path("vehicle-audit.json"))
    args = parser.parse_args()
    if not args.game_root and not args.glb_root:
        parser.error("Provide --game-root and/or --glb-root")
    report = {"schema": "cityzero.vehicle-audit.v1", "copyrighted_assets_included": False}
    if args.game_root:
        report["source_inventory"] = inspect_game_root(args.game_root)
    if args.glb_root:
        if not args.glb_root.is_dir():
            parser.error("--glb-root must be a directory")
        report["exported_models"] = []
        for path in sorted(args.glb_root.rglob("*.glb")):
            try:
                report["exported_models"].append(inspect_glb(path))
            except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as err:
                report["exported_models"].append({"file": str(path), "error": str(err)})
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("Wrote " + str(args.out))
    if any("error" in model for model in report.get("exported_models", [])):
        raise SystemExit(2)

if __name__ == "__main__":
    main()
