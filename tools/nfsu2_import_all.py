#!/usr/bin/env python3
"""City Zero local-only NFSU2 all-car, all-part, all-vinyl, all-sound import.

Requires user-owned NFSU2 files and the open-source NFSU2-World-Editor parser.
No EA game media is bundled or pushed to the City Zero public repository.
"""
from __future__ import annotations
import argparse
import configparser
import json
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path
from nfsu2_parts_animation import inspect as inspect_animation
from nfsu2_physics_catalog import catalog as read_original_physics
from nfsu2_prepare_godot_library import build_library as build_godot_private_library
from nfsu2_blender_export_all import SHARED_FAMILIES
import struct

PART_RULES = (
    ("trunk_audio", ("TRUNK_AUDIO",)),
    ("hood_under", ("HOOD_UNDER",)),
    ("trunk_under", ("TRUNK_UNDER",)),
    ("door_panel", ("DOOR_PANEL", "DOOR_SILL")),
    ("front_bumper", ("FRONT_BUMPER",)),
    ("rear_bumper", ("REAR_BUMPER",)),
    ("headlight", ("HEADLIGHT",)),
    ("taillight", ("BRAKELIGHT", "TAILLIGHT")),
    ("mirror", ("WING_MIRROR", "SIDE_MIRROR")),
    ("roof_scoop", ("ROOFSCOOP", "ROOF_SCOOP")),
    ("side_skirt", ("SKIRT",)),
    ("spoiler", ("SPOILER",)),
    ("exhaust", ("EXHAUST",)),
    ("brake", ("BRAKE",)),
    ("wheel", ("WHEEL", "RIM")),
    ("engine", ("ENGINE",)),
    ("suspension", ("SUSPENSION",)),
    ("hood", ("HOOD",)),
    ("trunk", ("TRUNK",)),
    ("door", ("DOOR",)),
    ("fender", ("FENDER",)),
    ("quarter_panel", ("QUARTER",)),
    ("roof", ("ROOF", "TOP")),
    ("body", ("BODY",)),
    ("interior", ("BASE", "INTERIOR", "DASH")),
    ("neon", ("NEON",)),
    ("damage", ("DAMAGE",)),
)
AUDIO_EXT = {".gin", ".abk", ".csi", ".ast", ".asf", ".sns", ".sng", ".mus", ".str", ".wav", ".ogg"}
STAGES = ("Stock", "Street", "Pro", "Extreme")
UPGRADES = ("Engine", "ECU", "Transmission", "Chassis", "Nitrous", "Tires", "Brakes",
            "WeightReduction", "Induction", "Aerodynamics", "TestDyno")

def dir_ci(parent, name):
    if parent is None or not parent.is_dir():
        return None
    return next((p for p in parent.iterdir() if p.is_dir() and p.name.casefold() == name.casefold()), None)

def file_ci(parent, name):
    if parent is None or not parent.is_dir():
        return None
    return next((p for p in parent.iterdir() if p.is_file() and p.name.casefold() == name.casefold()), None)

def safe_name(name):
    return re.sub(r"[^a-zA-Z0-9_.-]+", "_", name).strip("._")[:100] or "unknown"

def part_category(family, kit=None):
    upper = str(family).upper()
    if str(kit or "").upper().startswith("KITW"):
        return "widebody"
    for label, words in PART_RULES:
        if any(word in upper for word in words):
            return label
    return "other"

def read_ini(path):
    if path is None:
        return {}
    conf = configparser.ConfigParser(interpolation=None, strict=False)
    raw = path.read_text(encoding="utf-8-sig", errors="replace")
    raw = re.sub(r"(?m)\s*//.*$", "", raw)
    try:
        conf.read_string(raw)
        return {section: dict(conf.items(section)) for section in conf.sections()}
    except configparser.Error:
        return {"_parse_error": str(path)}

def numbered_ini(base, folder, value):
    if value is None:
        return {}
    place = dir_ci(base, folder)
    try:
        n = int(value)
    except (TypeError, ValueError):
        return {}
    for filename in (f"{n}.ini", f"{n:02}.ini", f"{n:03}.ini"):
        result = file_ci(place, filename)
        if result:
            return read_ini(result)
    return {}

def sound_mapping(base, car):
    own = read_ini(file_ci(dir_ci(base, "CarTypeMapping"), car + ".ini"))
    mapping = next((v for k, v in own.items() if k.casefold() == "cartypemapping"), {})
    number = mapping.get("cardatamapping")
    if number is None:
        return {"status": "not_mapped", "stages": {}}
    package = numbered_ini(base, "CarDataMapping", number)
    stages = {}
    for stage in STAGES:
        rec = next((v for k, v in package.items() if k.casefold() == stage.casefold()), {})
        engine = numbered_ini(base, "EngineData", rec.get("enginedata"))
        shift = numbered_ini(base, "ShiftPatterns", rec.get("shiftpattern"))
        turbo = numbered_ini(base, "TurboDataSet", rec.get("turbodataset"))
        eng = next((v for k, v in engine.items() if k.casefold() == "enginedata"), {})
        stages[stage.lower()] = {
            "source_ids": {x: rec.get(x) for x in ("enginedata", "shiftpattern", "turbodataset")},
            "engine": engine, "shifting": shift, "turbo": turbo,
            "sweetener": numbered_ini(base, "SweetnerDataSet", eng.get("carid")),
            "deceleration": numbered_ini(base, "DualGinsu", eng.get("ginsudecelid")),
            "acceleration_from_idle": numbered_ini(base, "AccelFromIdle", eng.get("accelfromidleid")),
        }
    return {"status": "mapped_from_car_sound_tuner", "index": number, "stages": stages}

def unlimiter_config(game, car):
    folder = dir_ci(dir_ci(game, "scripts"), "UnlimiterData")
    main = read_ini(file_ci(folder, "_General.ini"))
    specific = read_ini(file_ci(folder, car + ".ini"))
    for section, values in specific.items():
        key = next((k for k in main if k.casefold() == section.casefold()), section)
        main.setdefault(key, {}).update(values)
    return main

def load_parsers(converter):
    if not (converter / "nfsu2_world_editor" / "core" / "cars.py").is_file():
        raise FileNotFoundError("Missing NFSU2-World-Editor checkout at " + str(converter))
    sys.path.insert(0, str(converter.resolve()))
    from nfsu2_world_editor.core import cars, tpk
    return cars, tpk

def collect_geometry(cars, geometry, global_dir):
    model = cars.CarGeometry.open(geometry)
    stock_hashes = {p.hash for p in model.stock_parts("KIT00", "A")}
    parts = []
    slots = Counter()
    for p in model.parts:
        label = part_category(p.family, p.kit)
        slots[label] += 1
        parts.append({
            "name": p.name, "hash": f"{p.hash:08X}", "kit": p.kit, "family": p.family,
            "lod": p.lod, "slot": label, "stock": p.hash in stock_hashes,
            "vertices": p.nverts, "triangles": p.nfaces,
            "materials": [cars.CLASS_NAMES.get(c, f"{c:08X}") for c in p.classes],
        })
    wheels = cars.wheel_layout(global_dir, model.name) if global_dir else None
    return {"model_name": model.name, "parts": parts, "part_count": len(parts),
            "slots": dict(sorted(slots.items())), "wheel_layout": wheels,
            "wheel_layout_source": "GLOBALB" if wheels else "unavailable"}

def collect_vinyls(tpk, source, dest=None):
    packs, _ = tpk.load_packs(str(source))
    if dest:
        from nfsu2_world_editor.core.image import write_image
        dest.mkdir(parents=True, exist_ok=True)
    result = []
    for pack in packs:
        for texture in pack.textures:
            rec = {"name": texture.name, "hash": f"{texture.hash:08X}",
                   "width": texture.width, "height": texture.height, "format": texture.format_name}
            if dest:
                try:
                    pixels, w, h = texture.decode()
                    target = dest / (f"{texture.hash:08X}_" + safe_name(texture.name) + ".png")
                    write_image(str(target), pixels, w, h)
                    rec["private_png"] = str(target)
                except (ValueError, IndexError, TypeError, OSError) as err:
                    rec["decode_error"] = str(err)
            result.append(rec)
    return {"count": len(result), "vinyls": result}

def sound_category(path):
    name = str(path).upper()
    if "ENGINE" in name or path.suffix.lower() == ".gin":
        return "engine"
    for token, group in (("TURBO", "turbo"), ("SHIFT", "transmission"),
                         ("NOS", "nitrous"), ("NITRO", "nitrous"),
                         ("SKID", "tyres"), ("TIRE", "tyres"), ("CRASH", "collision")):
        if token in name:
            return group
    return "vehicle_fx_other"

def sound_files(game):
    root = dir_ci(game, "SOUND")
    if root is None:
        return []
    return [{"path": p.relative_to(game).as_posix(), "bytes": p.stat().st_size,
             "extension": p.suffix.lower(), "category": sound_category(p.relative_to(root))}
            for p in sorted(root.rglob("*")) if p.is_file() and p.suffix.lower() in AUDIO_EXT]

def _valid_decoded_wave(path):
    """Require an actual RIFF/WAVE header, not stale or incomplete outputs."""
    try:
        if path.stat().st_size <= 44:
            return False
        with path.open("rb") as handle:
            header = handle.read(12)
        return header[:4] in (b"RIFF", b"RF64") and header[8:12] == b"WAVE"
    except OSError:
        return False


def decode_sound_banks(game, rows, output, decoder):
    """Extract ALL vgmstream subsongs into collision-free private WAV files.

    vgmstream -S 0 exports every available subsong; ?04s ensures unique output.
    A temporary bank directory prevents older successful output from falsely
    marking a failed decoder as successful.
    Official CLI: https://github.com/vgmstream/vgmstream/blob/master/doc/USAGE.md
    """
    exe = shutil.which(decoder)
    if not exe:
        return {"status": "not_run", "reason": f"Decoder missing: {decoder}"}
    import hashlib
    import tempfile
    output.mkdir(parents=True, exist_ok=True)
    success = failure = skipped = 0
    for entry in rows:
        if entry["extension"] not in (".gin", ".abk", ".asf", ".sns", ".sng"):
            continue
        # Preserve any existing user data but never treat it as verification
        # of this decoder attempt.
        unique = hashlib.sha256(entry["path"].encode("utf-8")).hexdigest()[:10]
        prefix = safe_name(entry["path"]) + "_" + unique
        if shutil.disk_usage(output).free < 512 * 1024 * 1024:
            entry["decode_status"] = "skipped_disk_space"
            skipped += 1
            continue
        with tempfile.TemporaryDirectory(prefix="cityzero_bank_", dir=output) as temporary:
            temp = Path(temporary)
            target = temp / (prefix + "_?04s.wav")
            try:
                proc = subprocess.run(
                    [exe, "-i", "-s", "1", "-S", "0", "-o", str(target),
                     str(game / entry["path"])],
                    capture_output=True, text=True, timeout=300, check=False)
            except subprocess.TimeoutExpired:
                entry["decoder_error"] = "Timeout; this bank was not confirmed"
                failure += 1
                continue
            fresh = sorted(p for p in temp.glob(prefix + "_*.wav")
                           if _valid_decoded_wave(p))
            if not fresh:
                entry["decode_status"] = "failed"
                entry["decoder_error"] = (proc.stderr or proc.stdout)[-400:]
                failure += 1
                continue
            imported = []
            for src in fresh:
                dest = output / src.name
                src.replace(dest)
                imported.append(str(dest))
            entry["private_wavs"] = imported
            entry["decode_status"] = (
                "complete_by_decoder" if proc.returncode == 0 else "partial"
            )
            success += len(imported)
            if proc.returncode:
                failure += 1
    return {"status": "attempted", "decoded_streams": success,
            "failed_files": failure, "skipped_low_disk": skipped,
            "note": "Decodes all source subsongs. WAVs do not yet recreate original RPM-layered Ginsu playback."}


def export_models(game, converter, output, selected, blender, all_lods):
    executable = shutil.which(blender)
    if not executable:
        return {"status": "not_run", "reason": "Blender executable not available"}
    script = Path(__file__).with_name("nfsu2_blender_export_all.py")
    if not script.is_file():
        return {"status": "not_run", "reason": "Missing Blender helper"}
    results = []
    for folder in sorted(dir_ci(game, "CARS").iterdir()):
        if not folder.is_dir() or not file_ci(folder, "GEOMETRY.BIN"):
            continue
        if selected and folder.name.upper() not in selected:
            continue
        dest = output / "local_assets" / "models" / folder.name
        cmd = [executable, "--background", "--factory-startup", "--python", str(script),
               "--", "--car", str(folder), "--converter-dir", str(converter),
               "--out", str(dest)]
        if all_lods:
            cmd.append("--every-lod")
        try:
            run = subprocess.run(cmd, capture_output=True, text=True, timeout=3600, check=False)
            shared = folder.name.upper() in SHARED_FAMILIES
            manifest = dest / "models.json"
            exported = {}
            if manifest.is_file():
                try:
                    exported = json.loads(manifest.read_text(encoding="utf-8"))
                except (ValueError, OSError):
                    pass
            verified = (run.returncode == 0 and manifest.is_file()
                        and (shared or (dest / "stock.glb").is_file())
                        and (not shared or len(exported.get("parts", [])) > 0))
            results.append({"car": folder.name, "status": "exported" if verified else "failed",
                            "exit_code": run.returncode, "log_tail": (run.stderr + run.stdout)[-1000:]})
        except subprocess.TimeoutExpired:
            results.append({"car": folder.name, "status": "timeout"})
    return {"status": "attempted", "exported": sum(x["status"] == "exported" for x in results),
            "failed": sum(x["status"] != "exported" for x in results), "results": results}

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--game-root", type=Path, required=True)
    ap.add_argument("--converter-dir", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--cars", default="", help="Optional comma-separated XNAMEs. Default is ALL.")
    ap.add_argument("--export-models", action="store_true")
    ap.add_argument("--export-vinyls", action="store_true")
    ap.add_argument("--decode-audio", action="store_true")
    ap.add_argument("--export-all", action="store_true")
    ap.add_argument("--every-lod", action="store_true")
    ap.add_argument("--blender", default="blender")
    ap.add_argument("--decoder", default="vgmstream-cli")
    a = ap.parse_args(argv)
    game, out = a.game_root.resolve(), a.out.resolve()
    game_cars = dir_ci(game, "CARS")
    if game_cars is None:
        ap.error("No original game CARS directory provided; proprietary models are NOT in this repository.")
    cars, tpk = load_parsers(a.converter_dir)
    chosen = {x.strip().upper() for x in a.cars.split(",") if x.strip()}
    global_dir = dir_ci(game, "GLOBAL")
    sound_data = dir_ci(dir_ci(game, "scripts"), "CarSoundData")
    report = {"schema": "cityzero.nfsu2.local-import.v1",
              "game_root": str(game), "asset_source": "user-supplied source files",
              "redistribution_permission": False,
              "source_files": {"globalb": str(file_ci(global_dir, "GLOBALB.BUN") or
                                                file_ci(global_dir, "GlobalB.lzc") or "")},
              "performance": {"status": "source_identified_numeric_upgrade_effects_not_yet_ported",
                              "categories": list(UPGRADES)},
              "cars": {}, "audio_files": sound_files(game)}
    original_physics = {}
    original_globalb = file_ci(global_dir, "GLOBALB.BUN")
    if original_globalb is not None:
        try:
            parsed_physics = read_original_physics(original_globalb.read_bytes())
            original_physics = parsed_physics["cars"]
            report["performance"]["status"] = "original_factory_and_upgrade_targets_extracted"
            report["performance"]["cars_decoded"] = parsed_physics["parsed"]
            report["performance"]["car_records_rejected"] = parsed_physics["rejected"]
        except (OSError, ValueError, struct.error) as err:
            report["performance"]["source_error"] = str(err)
    else:
        report["performance"]["source_error"] = "Original uncompressed GLOBALB.BUN not available"
    for folder in sorted(game_cars.iterdir()):
        if not folder.is_dir() or (chosen and folder.name.upper() not in chosen):
            continue
        geo = file_ci(folder, "GEOMETRY.BIN")
        if not geo:
            continue
        files = {name: file_ci(folder, name) for name in
                 ("GEOMETRY.BIN", "TEXTURES.BIN", "VINYLS.BIN", "PARTS_ANIMATIONS.BIN")}
        item = {"sources": {name: bool(path) for name, path in files.items()},
                "animation_file": str(files["PARTS_ANIMATIONS.BIN"] or ""),
                "animation": inspect_animation(files["PARTS_ANIMATIONS.BIN"]),
                "sound": sound_mapping(sound_data, folder.name),
                "unlimiter": unlimiter_config(game, folder.name),
                "physics": original_physics.get(folder.name.upper(),
                    {"status": "original_car_physics_not_available_for_this_vehicle"})}
        try:
            item["geometry"] = collect_geometry(cars, geo, global_dir)
        except (ValueError, OSError, IndexError) as err:
            item["geometry_error"] = str(err)
        vinyl_path = files["VINYLS.BIN"]
        if vinyl_path:
            try:
                private = out / "local_assets" / folder.name / "vinyls" if a.export_vinyls or a.export_all else None
                item["vinyls"] = collect_vinyls(tpk, vinyl_path, private)
            except (ValueError, OSError, IndexError) as err:
                item["vinyl_error"] = str(err)
        report["cars"][folder.name] = item
    if a.decode_audio or a.export_all:
        report["audio_decode"] = decode_sound_banks(game, report["audio_files"],
                                                  out / "local_assets" / "audio", a.decoder)
    if a.export_models or a.export_all:
        report["model_export"] = export_models(game, a.converter_dir, out, chosen,
                                               a.blender, a.every_lod)
    out.mkdir(parents=True, exist_ok=True)
    path = out / "nfsu2_all_manifest.json"
    path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    # Complete handoff in the SAME command: original GLBs + exact per-car
    # car sound stages + unmodified physics source metadata for Godot.
    registry = build_godot_private_library(report, out)
    registry_path = out / "cityzero_godot_library.json"
    registry_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n",
                             encoding="utf-8")
    count = Counter()
    for car in report["cars"].values():
        count.update(car.get("geometry", {}).get("slots", {}))
    print(json.dumps({"cars": len(report["cars"]), "parts": sum(count.values()),
                      "vinyls": sum(car.get("vinyls", {}).get("count", 0) for car in report["cars"].values()),
                      "source_sound_files": len(report["audio_files"]), "manifest": str(path),
                      "godot_private_library": str(registry_path),
                      "verified_stock_models": registry["summary"]["cars_with_valid_stock_glb"],
                      "private_assets_only": True}, indent=2))

if __name__ == "__main__":
    main()
