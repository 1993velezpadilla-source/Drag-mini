#!/usr/bin/env python3
"""Collect real Kindria Android diagnostics over ADB; no emulator FPS claims."""
import argparse
import json
import math
from pathlib import Path
import subprocess
import time

TAG = "KINDRIA_DEVICE_PERF "
PACKAGE = "org.myforeverpet.godot"
BUDGET = 16667

def parse_windows(log):
    windows = []
    rejected = 0
    for line in log.splitlines():
        if TAG not in line:
            continue
        try:
            row, _ = json.JSONDecoder().raw_decode(line.split(TAG, 1)[1].lstrip())
            if row.get("os") != "Android":
                raise ValueError("not Android")
            interval = row["frame_interval"]
            count = interval["samples"]
            if type(count) is not int or count < 300:
                raise ValueError("incomplete window")
            for key in ("p50_usec", "p95_usec", "p99_usec", "max_usec"):
                value = interval[key]
                if not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0:
                    raise ValueError("invalid timing")
            if not interval["p50_usec"] <= interval["p95_usec"] <= interval["p99_usec"] <= interval["max_usec"]:
                raise ValueError("unordered percentiles")
            over = interval["over_60hz_budget"]
            if type(over) is not int or not 0 <= over <= count:
                raise ValueError("invalid budget count")
            tier = row["peak_quality_tier"]
            if type(tier) is not int or not 0 <= tier <= 2:
                raise ValueError("invalid tier")
            windows.append(row)
        except (ValueError, TypeError, KeyError, AttributeError):
            rejected += 1
    return windows, rejected

def summarize(windows, rejected, physical_device, duration_seconds):
    total = sum(w["frame_interval"]["samples"] for w in windows)
    over = sum(w["frame_interval"]["over_60hz_budget"] for w in windows)
    tier = max((w["peak_quality_tier"] for w in windows), default=None)
    return {
        "windows": len(windows), "rejected_windows": rejected,
        "samples": total, "over_budget": over,
        "worst_window_p95_usec": max((w["frame_interval"]["p95_usec"] for w in windows), default=None),
        "max_interval_usec": max((w["frame_interval"]["max_usec"] for w in windows), default=None),
        "peak_quality_tier": tier,
        "physical_device_indicated": physical_device,
        "capture_seconds": duration_seconds,
        "observed_strict_budget_pass": bool(total and over == 0 and tier == 0 and rejected == 0),
        "certification_ready": bool(physical_device and duration_seconds >= 600 and total >= 18000 and over == 0 and tier == 0 and rejected == 0),
        "scope": "Observed combat intervals only; not whole-session FPS, thermal certification or visual parity.",
    }

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--serial")
    p.add_argument("--package", default=PACKAGE)
    p.add_argument("--duration", type=int, default=600)
    p.add_argument("--output", type=Path, default=Path("kindria-android-evidence"))
    args = p.parse_args()
    if args.duration < 1:
        p.error("--duration must be positive")
    adb = ["adb"] + (["-s", args.serial] if args.serial else [])
    args.output.mkdir(parents=True, exist_ok=True)
    def command(*words):
        return subprocess.check_output(adb + list(words), text=True, stderr=subprocess.STDOUT, timeout=30).strip()
    def snapshot(when):
        commands = {
            "thermal": ("shell", "dumpsys", "thermalservice"),
            "memory": ("shell", "dumpsys", "meminfo", args.package),
            "display": ("shell", "wm", "size"),
        }
        for name, cmd in commands.items():
            try:
                value = command(*cmd)
            except (subprocess.SubprocessError, OSError) as exc:
                value = "UNAVAILABLE: " + str(exc)
            (args.output / (when + "-" + name + ".txt")).write_text(value, encoding="utf-8")
    pid = command("shell", "pidof", args.package).split()
    if len(pid) != 1:
        p.error("launch the game with diagnostics enabled; expected exactly one game PID")
    properties = {}
    for key in ("ro.product.model", "ro.product.manufacturer", "ro.build.version.release",
                "ro.product.cpu.abi", "ro.kernel.qemu", "ro.boot.qemu"):
        properties[key] = command("shell", "getprop", key)
    physical = all(properties[k] != "1" for k in ("ro.kernel.qemu", "ro.boot.qemu")) and bool(properties["ro.product.model"])
    snapshot("before")
    log_path = args.output / "logcat.txt"
    print("Capture active. Play combat continuously; include simultaneous attacks and different biomes.", flush=True)
    started = time.monotonic()
    with log_path.open("w", encoding="utf-8") as out:
        proc = subprocess.Popen(adb + ["logcat", "--pid=" + pid[0], "-T", "1", "-v", "threadtime"], stdout=out, stderr=subprocess.STDOUT)
        try:
            proc.wait(timeout=args.duration)
        except subprocess.TimeoutExpired:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
            proc.wait(timeout=5)
    duration = time.monotonic() - started
    snapshot("after")
    windows, rejected = parse_windows(log_path.read_text(encoding="utf-8", errors="replace"))
    report = {"device": properties, "package": args.package, "pid": pid[0],
              "summary": summarize(windows, rejected, physical, duration), "windows": windows}
    (args.output / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report["summary"], indent=2))
    return 0 if windows else 2

if __name__ == "__main__":
    raise SystemExit(main())
