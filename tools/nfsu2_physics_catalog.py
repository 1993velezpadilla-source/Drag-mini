#!/usr/bin/env python3
"""Read exact factory physics and upgrade targets from a user-owned NFSU2 GLOBALB.BUN.

Fields use the verified original PC v1.2 CarTypeInfo format (0x890 bytes).
Reference: chrystianfarias/NFSU2Unity/docs/re/physics-data.md.
These target arrays are not a complete simulation of performance packages!
No EA assets or full source records are embedded in the output or repo.
"""
from __future__ import annotations
import argparse
import json
import math
import struct
from pathlib import Path

CAR_CHUNK = 0x00034600
CAR_SIZE = 0x890
CAR_MIN = 0x840
MAX_CARS = 512


def chunks(data: bytes, start=0, end=None, depth=0):
    if end is None:
        end = len(data)
    if depth > 12:
        raise ValueError("Excessive chunk nesting")
    p = start
    while p + 8 <= end:
        kind, size = struct.unpack_from("<II", data, p)
        begin = p + 8
        limit = begin + size
        if limit > end or limit < begin:
            raise ValueError("GLOBALB has out-of-bounds chunk")
        if kind == CAR_CHUNK:
            yield begin, limit
        if kind and (kind >> 28) == 8 and size:
            yield from chunks(data, begin, limit, depth + 1)
        p = limit


def floats(data: bytes, offset: int, n: int) -> list[float]:
    values = struct.unpack_from("<" + "f" * n, data, offset)
    if not all(math.isfinite(x) for x in values):
        raise ValueError("Nonfinite original physics data")
    return list(values)


def _reasonable_rpm(values: list[float]) -> bool:
    idle, redline, maximum = values
    return 100 <= idle <= 3000 and 1000 <= redline <= 16000 and redline <= maximum <= 20000


def record(data: bytes) -> dict:
    if len(data) != CAR_SIZE:
        raise ValueError("Incomplete CarTypeInfo")
    name = data[:32].split(b"\0", 1)[0].decode("ascii", "replace").strip()
    if not name or not all(ch.isascii() and (ch.isalnum() or ch in "_-") for ch in name):
        raise ValueError("Malformed car identity")
    rpm = floats(data, 0x300, 3)
    if not _reasonable_rpm(rpm):
        raise ValueError("Invalid factory RPM fields for " + name)
    base_mass = floats(data, 0x220, 1)[0]
    if not 0.1 <= base_mass <= 20:
        raise ValueError("Invalid base mass in original car: " + name)
    gears = struct.unpack_from("<I", data, 0x2D8)[0]
    if gears > 8:
        raise ValueError("Impossible gear count for " + name)
    return {
        "xname": name,
        "source_record_bytes": CAR_SIZE,
        "factory_physics": {
            "mass_tonnes": base_mass,
            "engine_idle_redline_max_rpm": rpm,
            "torque_curve_kNm": floats(data, 0x310, 9),
            "turbo_torque_curve_kNm": floats(data, 0x334, 9),
            "engine_braking_kNm": floats(data, 0x358, 3),
            "gear_count": gears,
            "gear_ratios_reverse_neutral_1to6": floats(data, 0x2E0, 8),
            "final_drive_front_rear": floats(data, 0x2C8, 2),
            "drive_torque_split_rear": floats(data, 0x2D0, 1)[0],
            "front_tyre_slip_load_grip": floats(data, 0x1E0, 5),
            "rear_tyre_slip_load_grip": floats(data, 0x200, 5),
            "brake_torque_handbrake_bias": floats(data, 0x384, 3),
            "aero_drag_and_downforce": floats(data, 0x370, 4),
            "nitrous_capacity_shots_torque": {
                "capacity": floats(data, 0x3B0, 1)[0],
                "shots": struct.unpack_from("<i", data, 0x3B4)[0],
                "torque_multiplier": floats(data, 0x3BC, 1)[0],
            },
        },
        "upgrade_source_targets": {
            "weight": {
                "mass_max_level_multiplier": floats(data, 0x450, 1)[0],
                "center_of_mass_shift_delta": floats(data, 0x454, 1)[0],
                "yaw_inertia_factor": floats(data, 0x458, 1)[0],
            },
            "engine": {
                "torque_delta_at_max_level_kNm": floats(data, 0x530, 9),
                "engine_braking_delta_at_max_level_kNm": floats(data, 0x554, 3),
            },
            "ecu": {
                "rpm_level_1_add": floats(data, 0x560, 3),
                "rpm_level_2_add": floats(data, 0x5A0, 3),
                "rpm_level_3_add": floats(data, 0x5E0, 3),
                "torque_delta_at_max_level_kNm": floats(data, 0x5F0, 9),
            },
            "turbo": {"torque_target_at_max_level_kNm": floats(data, 0x620, 9)},
            "tires": {
                "front_target": floats(data, 0x650, 5),
                "rear_target": floats(data, 0x670, 5),
            },
            "nitrous": {
                "capacity_target": floats(data, 0x690, 1)[0],
                "torque_multiplier_target": floats(data, 0x69C, 1)[0],
            },
            "aerodynamics": {
                "target_a": floats(data, 0x6A0, 4),
                "target_b": floats(data, 0x6B0, 4),
            },
            "brakes": {"torque_ebrake_bias_targets": floats(data, 0x6C0, 3)},
            "suspension": {
                "front_targets": floats(data, 0x6D0, 8),
                "rear_targets": floats(data, 0x6F0, 8),
                "center_of_mass_drop": floats(data, 0x710, 1)[0],
                "front_rear_ride_height_add": floats(data, 0x714, 2),
            },
        },
        "upgrade_status": "original_targets_extracted_packages_not_applied",
        "note": "NFSU2 applies these arrays with separate per-part fractions and its simulation. "
                "Do not interpret target values as an installed performance upgrade.",
    }


def catalog(globalb: bytes) -> dict:
    candidates = list(chunks(globalb))
    if len(candidates) != 1:
        raise ValueError("Expected one validated GLOBALB CarTypeInfo chunk")
    start, end = candidates[0]
    while start < end and globalb[start] == 0x11:
        start += 1
    available = (end - start) // CAR_SIZE
    if available == 0 or available > MAX_CARS:
        raise ValueError("Invalid original vehicle record count")
    out = {}
    rejected = []
    for index in range(available):
        chunk = globalb[start + index * CAR_SIZE:start + (index + 1) * CAR_SIZE]
        try:
            row = record(chunk)
        except ValueError as e:
            rejected.append({"index": index, "reason": str(e)})
            continue
        if row["xname"] in out:
            rejected.append({"index": index, "reason": "Duplicate car ID"})
        else:
            out[row["xname"]] = row
    if not out:
        raise ValueError("No valid original car physics records")
    return {
        "schema": "cityzero.nfsu2.private-physics.v1",
        "cars": out,
        "parsed": len(out),
        "rejected": rejected,
        "unread_bytes_trailing": (end - start) % CAR_SIZE,
        "redistribution_authorized": False,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--globalb", type=Path, required=True,
                        help="User-owned original uncompressed GLOBAL/GLOBALB.BUN")
    parser.add_argument("--out", type=Path, required=True,
                        help="Output private JSON path (never publish original data)")
    args = parser.parse_args(argv)
    try:
        source = args.globalb.read_bytes()
        results = catalog(source)
    except (OSError, ValueError, struct.error) as e:
        parser.error(str(e))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n",
                        encoding="utf-8")
    print(json.dumps({"cars": results["parsed"], "rejected": len(results["rejected"]),
                      "private_output": str(args.out)}))


if __name__ == "__main__":
    main()
