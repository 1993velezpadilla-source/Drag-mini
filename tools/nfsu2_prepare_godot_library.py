#!/usr/bin/env python3
"""Prepare a PRIVATE Godot-ready vehicle library from the NFSU2 batch import.

Uses original asset paths and real exported GLBs only. No copyrighted data
or substitute meshes are packaged in this repository. Requires a user-owned
NFSU2 installation processed by tools/nfsu2_import_all.py.
"""
from __future__ import annotations

import argparse
import json
import struct
from collections import defaultdict
from pathlib import Path
from nfsu2_blender_export_all import SHARED_FAMILIES, part_slot

# Exact type overrides from the NFSU2 GLOBALB CarPartDatabase 0x34607 table.
# https://github.com/chrystianfarias/NFSU2Unity/blob/main/docs/re/car-parts.md
HATCH_SPOILER = frozenset(("PEUGOT", "FOCUS", "PEUGOT106", "CORSA", "GOLF", "A3"))
SUV_SPOILER = frozenset(("HUMMER", "NAVIGATOR", "ESCALADE"))
BODY_MIRRORS = frozenset(("MIATA", "TIBURON", "SUPRA", "TT", "3000GT", "RX7"))
SUV_MIRRORS = frozenset(("NAVIGATOR", "ESCALADE"))


def compatible_shared_families(xname: str) -> list[str]:
    name = xname.upper()
    families = ["WHEELS", "BRAKES", "AUDIO", "SPINNER", "PLATES", "EXHAUST"]
    families.append("SPOILER_HATCH" if name in HATCH_SPOILER else
                    "SPOILER_SUV" if name in SUV_SPOILER else "SPOILER")
    families.append("MIRRORS_HUMMER" if name == "HUMMER" else
                    "MIRRORS_SUV" if name in SUV_MIRRORS else
                    "MIRRORS_BODY" if name in BODY_MIRRORS else "MIRRORS_POST")
    return families

STAGES = ("stock", "street", "pro", "extreme")
SOUND_EXT = {".abk", ".gin", ".wav", ".ogg", ".ast", ".asf", ".sns", ".sng"}


def read_json(path: Path) -> dict:
    obj = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(obj, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return obj


def private_path(root: Path, name: str) -> Path:
    """Reject rooted and traversing paths from imported metadata."""
    p = Path(name)
    if p.is_absolute() or not name or any(part == ".." for part in p.parts):
        raise ValueError(f"Unsafe private asset path: {name!r}")
    resolved = (root / p).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise ValueError(f"Asset escapes private import root: {name!r}")
    return resolved


def glb_facts(path: Path) -> dict:
    with path.open("rb") as f:
        data = f.read(20)
    if len(data) != 20:
        raise ValueError("Incomplete GLB header")
    magic, ver, length, json_length, chunk = struct.unpack("<4sIII4s", data)
    if magic != b"glTF" or ver != 2 or chunk != b"JSON":
        raise ValueError("Not a glTF 2.0 binary")
    if length != path.stat().st_size or json_length > length - 20:
        raise ValueError("GLB length mismatch")
    return {"bytes": length, "glb_version": 2}


def _sound_index(records: list[dict]) -> dict[str, list[dict]]:
    by_name: dict[str, list[dict]] = defaultdict(list)
    for r in records:
        source = str(r.get("path", ""))
        suffix = Path(source).suffix.lower()
        if suffix in SOUND_EXT:
            by_name[Path(source).name.casefold()].append(r)
    return dict(by_name)


def _source_sounds(item: object) -> set[str]:
    """Identify actual ABK/GIN names in mappings, not guessed sample numbers."""
    names: set[str] = set()
    if isinstance(item, dict):
        for val in item.values():
            names.update(_source_sounds(val))
    elif isinstance(item, list):
        for val in item:
            names.update(_source_sounds(val))
    elif isinstance(item, str):
        stripped = item.strip().strip('"')
        if Path(stripped).suffix.lower() in SOUND_EXT:
            names.add(Path(stripped).name)
    return names


def _audio_refs(stage: dict, index: dict[str, list[dict]], root: Path) -> dict:
    result = {}
    for name in sorted(_source_sounds(stage)):
        choices = index.get(name.casefold(), [])
        if len(choices) != 1:
            result[name] = {"status": "ambiguous" if choices else "source_not_found",
                            "matches": [c.get("path") for c in choices]}
            continue
        rec = choices[0]
        wavs = []
        for original in rec.get("private_wavs", []):
            try:
                path = Path(original)
                if path.is_absolute():
                    if not path.resolve().is_relative_to(root.resolve()):
                        continue
                else:
                    path = private_path(root, original)
                if path.is_file() and path.suffix.lower() in {".wav", ".ogg"}:
                    wavs.append(path.relative_to(root).as_posix())
            except (ValueError, OSError):
                continue
        result[name] = {
            "status": "decoded_audio_available" if wavs else "source_only",
            "game_source_path": rec.get("path"),
            "decoded_private_audio": sorted(set(wavs)),
        }
    return result


def _model_parts(root: Path, car: str, is_shared: bool = False) -> dict:
    car_folder = private_path(root, f"local_assets/models/{car}")
    manifest_path = car_folder / "models.json"
    if not manifest_path.is_file():
        return {"status": "no_model_exports", "stock": None, "parts": [], "errors": []}
    src = read_json(manifest_path)
    errors = []
    stock = None
    stock_rel = src.get("stock")
    if stock_rel:
        try:
            p = private_path(car_folder, str(stock_rel))
            facts = glb_facts(p)
            stock = {"glb": p.relative_to(root).as_posix(), **facts}
        except (OSError, ValueError) as e:
            errors.append("stock: " + str(e))
    elif not is_shared:
        errors.append("stock: no original car body exported")
    parts = []
    for entry in src.get("parts", []):
        try:
            if not isinstance(entry, dict):
                raise ValueError("part is not a dictionary")
            p = private_path(car_folder, str(entry["glb"]))
            facts = glb_facts(p)
            parts.append({
                "source_name": str(entry["name"]),
                "part_hash": str(entry["hash"]),
                "family": str(entry.get("family", "")),
                "slot": str(entry.get("slot") or part_slot(
                    str(entry.get("family", "")) + "_" + str(entry["name"]))),
                "mount_space": str(entry.get("mount_space") or "car_local"),
                "owner_xname": car,
                "part_key": car + ":" + str(entry["hash"]),
                "kit": str(entry.get("kit", "BASE")),
                "lod": entry.get("lod"),
                "triangles_reported": int(entry.get("triangles", 0)),
                "glb": p.relative_to(root).as_posix(),
                **facts,
            })
        except (KeyError, ValueError, OSError, TypeError) as e:
            errors.append("part: " + str(e))
    ready = (is_shared and len(parts) > 0 or stock is not None) and not errors
    return {"status": "usable" if ready else "incomplete",
            "stock": stock, "parts": parts, "errors": errors,
            "shared_family": car if is_shared else None}


def build_library(batch: dict, output_root: Path) -> dict:
    if not isinstance(batch.get("cars"), dict):
        raise ValueError("Batch manifest must contain car records")
    sound_index = _sound_index(batch.get("audio_files", []))
    result = {
        "schema": "cityzero.nfsu2.private-godot-library.v1",
        "private_game_assets_only": True,
        "ready_for_public_distribution": False,
        "root": str(output_root.resolve()),
        "vehicles": {},
        "shared_families": {},
        "summary": {},
    }
    for xname, info in sorted(batch["cars"].items()):
        if xname.upper() in SHARED_FAMILIES:
            model = _model_parts(output_root, xname, is_shared=True)
            result["shared_families"][xname.upper()] = model
            continue
        model = _model_parts(output_root, xname)
        sound = info.get("sound", {})
        stage_mapping = sound.get("stages", {})
        stages = {}
        for stage_name in STAGES:
            entry = stage_mapping.get(stage_name, {})
            stages[stage_name] = {
                "source_mapping": entry,
                "referenced_audio": _audio_refs(entry, sound_index, output_root),
                "status": "source_mapped" if entry else "unmapped",
            }
        unlimiter = info.get("unlimiter", {})
        perf = next((values for key, values in unlimiter.items()
                     if key.casefold() == "performance" and isinstance(values, dict)), {})
        geometry = info.get("geometry", {})
        result["vehicles"][xname] = {
            "xname": xname,
            "model_name": geometry.get("model_name", xname),
            "source_part_count": geometry.get("part_count", 0),
            "source_categories": geometry.get("slots", {}),
            "wheel_layout": geometry.get("wheel_layout"),
            "wheel_layout_source": geometry.get("wheel_layout_source", "unavailable"),
            "model_assets": model,
            "compatible_shared_families": compatible_shared_families(xname),
            "sound_stages": stages,
            "sound_source_status": sound.get("status", "not_mapped"),
            "performance_categories": perf,
            "original_physics": info.get("physics", {"status": "not_available"}),
            "performance_numeric_status": (
                "original_targets_extracted_packages_not_applied"
                if "factory_physics" in info.get("physics", {})
                else "original_data_not_available"
            ),
            "vinyls": info.get("vinyls", {}),
            "animation": info.get("animation", {"status": "not_available"}),
        }
    vehicles = list(result["vehicles"].values())
    shared = list(result["shared_families"].values())
    result["summary"] = {
        "cars_seen": len(vehicles),
        "cars_with_valid_stock_glb": sum(v["model_assets"]["stock"] is not None for v in vehicles),
        "cars_with_all_model_files_valid": sum(v["model_assets"]["status"] == "usable" for v in vehicles),
        "source_part_variants": sum(v["source_part_count"] for v in vehicles),
        "glb_part_exports_valid": sum(len(v["model_assets"]["parts"]) for v in vehicles),
        "shared_families_seen": len(shared),
        "shared_generic_parts_valid": sum(len(v["parts"]) for v in shared),
        "car_sound_stages_with_source": sum(s["status"] == "source_mapped"
            for v in vehicles for s in v["sound_stages"].values()),
        "missing_or_invalid_model_files": sum(len(v["model_assets"]["errors"])
            for v in vehicles),
    }
    return result


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--import-root", type=Path, required=True,
                    help="PRIVATE folder from nfsu2_import_all.py --out")
    ap.add_argument("--manifest", type=Path,
                    help="Defaults to --import-root/nfsu2_all_manifest.json")
    ap.add_argument("--strict-models", action="store_true",
                    help="Exit failure if any selected car lacks a complete GLB export")
    args = ap.parse_args(argv)
    root = args.import_root.resolve()
    manifest = args.manifest or root / "nfsu2_all_manifest.json"
    library = build_library(read_json(manifest), root)
    path = root / "cityzero_godot_library.json"
    path.write_text(json.dumps(library, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8")
    print(json.dumps({"library": str(path), **library["summary"]}, indent=2))
    if args.strict_models and library["summary"]["cars_with_all_model_files_valid"] != library["summary"]["cars_seen"]:
        raise SystemExit("Some source vehicles have missing/invalid GLBs; see report.")


if __name__ == "__main__":
    main()
