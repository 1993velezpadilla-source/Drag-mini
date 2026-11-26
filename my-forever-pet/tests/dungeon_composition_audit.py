"""Offline adversarial composition review for actual Godot on/off captures.
Requires Pillow and NumPy. No rendering, no AI images, no aesthetic approval.
Usage: python dungeon_composition_audit.py candidate.zip [--baseline previous.zip]
"""
import argparse
import io
import json
import zipfile
from pathlib import PurePosixPath
import numpy as np
from PIL import Image

REGIONS = ("Whisperwood", "Coral Depths", "Starfall Isles")

def measure(on, off, threshold=12):
    a = np.asarray(on.convert("RGB"), dtype=np.int16)
    b = np.asarray(off.convert("RGB"), dtype=np.int16)
    if a.shape != b.shape or a.shape[0] < 3 or a.shape[1] < 4:
        raise ValueError("unmatched or invalid viewport dimensions")
    mask = np.max(np.abs(a - b), axis=2) > threshold
    h, w = mask.shape
    bands = {
        "whole": mask, "far": mask[:h//3], "middle": mask[h//3:2*h//3],
        "near": mask[2*h//3:], "left_edge": mask[:, :w//4],
        "right_edge": mask[:, 3*w//4:]
    }
    return {key: round(float(value.mean()) * 100, 3) for key, value in bands.items()}

def review(path):
    result = {}
    with zipfile.ZipFile(path) as archive:
        names = {PurePosixPath(n).name: n for n in archive.namelist()}
        for region, name in enumerate(REGIONS):
            for floor in (1, 2):
                prefix = f"dungeon-real-{region}-floor{floor}-exterior-"
                key = f"{name} B{floor}"
                pair = [names.get(prefix + suffix + ".png") for suffix in ("on", "off")]
                if not all(pair):
                    result[key] = {"status": "missing_capture"}
                    continue
                images = [Image.open(io.BytesIO(archive.read(p))) for p in pair]
                bands = measure(*images)
                # Diagnostic only: a full room may legitimately have no visible
                # exterior on one side. Reject this camera composition for art
                # review, not the procedural map or its gameplay.
                empty = [b for b in ("far", "near", "left_edge", "right_edge") if bands[b] < 0.5]
                result[key] = {"status": "review_required", "percent": bands,
                               "weak_bands": empty, "invisible": bands["whole"] < 0.5}
    return result

def report(candidate, baseline=None):
    current = review(candidate)
    if baseline:
        old = review(baseline)
        for key, entry in current.items():
            if "percent" in entry and "percent" in old[key]:
                entry["delta_pp"] = {b: round(v-old[key]["percent"][b], 3)
                                     for b, v in entry["percent"].items()}
    return {"candidate": str(candidate), "captures": current,
            "complete": all("percent" in e for e in current.values()),
            "art_approved": False,
            "limitations": "Measures changed pixels, not beauty or total scenery. Animated shaders can contaminate pairs; compare fixed-time captures when available."}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate")
    parser.add_argument("--baseline")
    args = parser.parse_args()
    print(json.dumps(report(args.candidate, args.baseline), indent=2))
