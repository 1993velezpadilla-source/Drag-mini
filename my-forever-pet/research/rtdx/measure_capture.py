"""Measure manually labeled attack stages using real decoded frame timestamps.

Input: lawful local video and a JSON annotation file. Outputs metadata only.
No download, OCR, guessed FPS, or automatic identification of attacks.
"""
import argparse
import json
import math
import subprocess
from pathlib import Path

STAGES = ("cast_start", "anticipation", "launch", "first_contact",
          "damage_text", "last_contact", "recovery", "effect_end")

def probe_frames(video):
    cmd = ["ffprobe", "-v", "error", "-select_streams", "v:0",
           "-show_frames", "-show_entries", "frame=best_effort_timestamp_time",
           "-of", "json", str(video)]
    raw = json.loads(subprocess.check_output(cmd, text=True))
    frames = []
    for row in raw.get("frames", []):
        val = row.get("best_effort_timestamp_time")
        if val is None:
            raise ValueError("Missing decoded frame timestamp; cannot infer timing")
        frames.append(float(val))
    return frames

def measure(frames, annotation):
    if len(frames) < 2 or any(not math.isfinite(t) for t in frames):
        raise ValueError("Need at least two finite decoded timestamps")
    if any(b <= a for a,b in zip(frames, frames[1:])):
        raise ValueError("Timestamps must be strictly increasing")
    if not annotation.get("source") or not annotation.get("move_id"):
        raise ValueError("Source and move ID required")
    labels = annotation.get("frames", {})
    if not {"cast_start", "effect_end"} <= labels.keys():
        raise ValueError("Cast start and effect end must be explicitly labeled")
    if set(labels) - set(STAGES):
        raise ValueError("Unknown stage label")
    if any(type(n) is not int or not 0 <= n < len(frames) for n in labels.values()):
        raise ValueError("Stage frame out of range")
    ordered = [labels[k] for k in STAGES if k in labels]
    # Damage may be shown before a later hit, but cannot precede first contact.
    if ordered != sorted(ordered) or labels["effect_end"] <= labels["cast_start"]:
        raise ValueError("Invalid stage order")
    start = frames[labels["cast_start"]]
    stop = frames[labels["effect_end"]]
    return {"source": annotation["source"], "move_id": annotation["move_id"],
            "verification": "manual_frame_labels_with_decoded_pts",
            "duration_ms": round((stop-start)*1000, 3),
            "stages": {k: {"frame": labels[k],
                           "video_pts_s": frames[labels[k]],
                           "offset_ms": round((frames[labels[k]]-start)*1000,3)}
                       for k in STAGES if k in labels},
            "unobserved_stages": [k for k in STAGES if k not in labels],
            "notes": annotation.get("notes", "")}

def self_test():
    pts = [0.0, .033, .083, .100, .149, .200]
    a = {"source":"synthetic only", "move_id":"test",
         "frames":{"cast_start":1,"launch":2,"first_contact":3,"effect_end":5}}
    out = measure(pts,a)
    assert out["duration_ms"] == 167.0
    assert out["stages"]["first_contact"]["offset_ms"] == 67.0
    assert "damage_text" in out["unobserved_stages"]
    for bad in ([0,0,1,2,3,4], [0,.1,float("nan"),.3,.4,.5]):
        try:
            measure(bad,a)
        except ValueError:
            pass
        else:
            raise AssertionError("Invalid timestamps accepted")
    print("RTDX_CAPTURE_MEASUREMENT_SYNTHETIC_PASS")

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--video", type=Path)
    p.add_argument("--annotations", type=Path)
    p.add_argument("--output", type=Path)
    args = p.parse_args()
    if args.self_test:
        self_test()
        return
    if not (args.video and args.annotations and args.output):
        p.error("--video, --annotations and --output required")
    annotation = json.loads(args.annotations.read_text(encoding="utf-8"))
    result = measure(probe_frames(args.video), annotation)
    with args.output.open("x", encoding="utf-8") as f:
        json.dump(result,f,indent=2)

if __name__ == "__main__":
    main()
