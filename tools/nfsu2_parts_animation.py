"""Read-only NFSU2 animation inventory; format evidence: TVasya/PartAnimatorulator
PackingUnpacking.py, FrameTools.py, AnimStruct.py, PivotNames.py (MIT).
Independent parser; source coordinates preserved, no guessed playback timing.
"""
import math
import re
import struct
from pathlib import Path

PIVOTS = tuple("_ZAM_"+s for s in (
    "HOOD_REG HOOD_FRONT LEFT_HOOD_SPLIT RIGHT_HOOD_SPLIT FRONT_HOOD_SPLIT BACK_HOOD_SPLIT "
    "LEFT_DOOR_REG LEFT_DOOR_SCISSOR LEFT_DOOR_SUICIDE RIGHT_DOOR_REG RIGHT_DOOR_SCISSOR "
    "RIGHT_DOOR_SUICIDE TRUNK_REG LEFT_DOOR_WIDE1 LEFT_DOOR_WIDE2 LEFT_DOOR_WIDE3 "
    "LEFT_DOOR_WIDE4 RIGHT_DOOR_WIDE1 RIGHT_DOOR_WIDE2 RIGHT_DOOR_WIDE3 RIGHT_DOOR_WIDE4").split())
CAR = re.compile(rb"\x0c\x00\x00\x00.{4}\x00{8}", re.S)
SLOT = b"\x10\x40\xe3\x00"
START = re.compile(rb"\x00\x00\x00[\x00\x01]\x00{7}\x01\x00{7}")
END = re.compile(rb"\x0f\x00.\x14..\x00\x00\x01", re.S)
NAME = re.compile(rb"([A-Za-z0-9_]+)_q\x00\1_t\x00")

def parse(data):
    matches = list(CAR.finditer(data))
    candidates = [m for m in matches if len(data)-m.end() == 21*64]
    if len(candidates) != 1:
        raise ValueError("Unsupported or ambiguous pivot block; expected 21 x 64 bytes")
    marker = candidates[0]
    pivots = {}
    for i, name in enumerate(PIVOTS):
        v = struct.unpack_from("<16f", data, marker.end()+64*i)
        if not all(math.isfinite(x) for x in v):
            raise ValueError("Nonfinite pivot: "+name)
        pivots[name] = {"matrix_rows": [list(v[j:j+4]) for j in (0,4,8)],
                        "position_xyzw": list(v[12:16])}
    tracks = []
    for slot in data[:marker.start()].split(SLOT)[1:]:
        name = NAME.search(slot)
        start = START.search(slot)
        end = END.search(slot, start.end()) if start else None
        row = {"name": name.group(1).decode("ascii") if name else None}
        if not start or not end or (end.start()-start.end()) % 16 or end.start()==start.end():
            row["status"] = "unsupported_frame_layout"
        else:
            frames = list(struct.iter_unpack("<4f", slot[start.end():end.start()]))
            if not all(all(math.isfinite(x) for x in q) and abs(sum(x*x for x in q)-1)<0.02 for q in frames):
                row["status"] = "invalid_quaternion"
            else:
                row.update(status="rotation_frames_parsed", quaternion_xyzw=frames)
        tracks.append(row)
    if not tracks:
        raise ValueError("No animation slots")
    return {"status": "source_layout_parsed_not_playback_verified",
            "car_hash_bytes": data[marker.start()+4:marker.start()+8].hex(),
            "pivots": pivots, "tracks": tracks, "frame_rate": None,
            "translation_tracks_decoded": False, "coordinate_conversion_verified": False}

def inspect(path):
    if path is None:
        return {"status": "missing_original_source"}
    try:
        return parse(Path(path).read_bytes())
    except (OSError, ValueError, struct.error) as exc:
        return {"status": "unsupported_or_invalid", "reason": str(exc)}
