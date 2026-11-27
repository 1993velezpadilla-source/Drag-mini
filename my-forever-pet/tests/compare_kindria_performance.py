#!/usr/bin/env python3
"""Compare Kindria V22.8+ reports from the same machine and benchmark mode.

Run repeated measurements under the same conditions. A single comparison is
a regression signal, not proof of a device-level performance change.
"""
import argparse
import json
import math
from pathlib import Path

TIMINGS = {
    "headless_cpu_submission": (
        "cold_spawn", "cold_update", "warm_spawn", "warm_update",
        "crowd_spawn", "crowd_update", "sustained_stress.spawn",
        "sustained_stress.update", "sustained_stress.combined_cpu_submission",
    ),
    "desktop_rendered": ("rendered_frame_intervals", "cpu_update"),
}


def get(data, path):
    for key in path.split("."):
        data = data[key]
    return data


def number(data, path):
    value = get(data, path)
    if type(value) not in (float, int) or not math.isfinite(value) or value < 0:
        raise ValueError("invalid numeric field: " + path)
    return value


def compare(base, candidate, relative=0.15, absolute_usec=250):
    errors, warnings, metrics = [], [], []
    try:
        mode = base["mode"]
        if mode not in TIMINGS or candidate["mode"] != mode:
            raise ValueError("incompatible benchmark modes")
        for path in ("catalog_moves", "simulation_hz", "frame_budget_usec",
                     "audio_playback"):
            if get(base, path) != get(candidate, path):
                raise ValueError("incompatible " + path)
        if base["catalog_moves"] != 589:
            raise ValueError("incomplete catalog")
        for report in (base, candidate):
            if report["failures"] != []:
                raise ValueError("benchmark reported failures")
        if mode == "headless_cpu_submission":
            for path in ("crowd_batches", "concurrent_casts",
                         "sustained_stress.casts", "sustained_stress.expected_waves",
                         "sustained_stress.simulation_frames",
                         "sustained_stress.slow_simulation_frames"):
                if number(base, path) != number(candidate, path):
                    raise ValueError("incompatible workload: " + path)
            for report in (base, candidate):
                stress = report["sustained_stress"]
                casts = number(stress, "casts")
                expected = {"dispatched_waves": casts * 3,
                            "dispatched_damage_waves": casts * 2,
                            "dispatched_miss_waves": casts,
                            "retired_dropped": 0}
                for key, value in expected.items():
                    if number(stress, "counters." + key) != value:
                        raise ValueError("invalid stress accounting: " + key)
        elif base["experimental_particle_batching"] != candidate["experimental_particle_batching"]:
            raise ValueError("incompatible batching configuration")
        for group in TIMINGS[mode]:
            baseline_samples = number(base, group + ".samples")
            current_samples = number(candidate, group + ".samples")
            if baseline_samples <= 0 or current_samples != baseline_samples:
                raise ValueError("incompatible sample count: " + group)
            for percentile in ("p50_usec", "p95_usec", "p99_usec", "max_usec"):
                path = group + "." + percentile
                old, new = number(base, path), number(candidate, path)
                if old <= 0:
                    raise ValueError("zero baseline timing: " + path)
                change = new - old
                ratio = change / old
                exceeded = change > absolute_usec and ratio > relative
                metrics.append({"metric": path, "baseline_usec": old,
                                "candidate_usec": new, "change_pct": ratio * 100,
                                "threshold_exceeded": exceeded})
                if exceeded:
                    (warnings if percentile == "max_usec" else errors).append(path)
        for key in ("static_bytes", "renderer_video_bytes"):
            old, new = number(base, "peaks." + key), number(candidate, "peaks." + key)
            if old == 0 or new == 0:
                warnings.append(key + ": unavailable monitor")
            elif new - old > max(8 * 1024 * 1024, old * relative):
                warnings.append(key + ": peak memory increased")
    except (KeyError, TypeError, ValueError) as exc:
        return {"status": "incompatible", "errors": [str(exc)], "warnings": [], "metrics": []}
    return {"status": "regression" if errors else "pass",
            "errors": errors, "warnings": warnings, "metrics": metrics}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--relative", type=float, default=0.15)
    parser.add_argument("--absolute-usec", type=float, default=250)
    args = parser.parse_args()
    if not math.isfinite(args.relative) or not math.isfinite(args.absolute_usec) or min(args.relative, args.absolute_usec) < 0:
        parser.error("thresholds must be finite and nonnegative")
    try:
        result = compare(json.loads(args.baseline.read_text()),
                         json.loads(args.candidate.read_text()),
                         args.relative, args.absolute_usec)
    except (OSError, ValueError) as exc:
        result = {"status": "incompatible", "errors": [str(exc)]}
    print(json.dumps(result, indent=2))
    return {"pass": 0, "regression": 1, "incompatible": 2}[result["status"]]


if __name__ == "__main__":
    raise SystemExit(main())
