"""Verify that the actual Android export contains the exact baked combat packs.
Godot Gradle export can store assets loose or inside a PCK. Validate both layouts,
including the PCK directory and each entry's MD5, without relying on filenames
alone. No claim about Android runtime performance is made by this test.
"""
import argparse
import hashlib
import json
import pathlib
import struct
import zipfile

FILES = (
    "generated_combat_audio/index.json",
    "generated_combat_audio/audio.pcm",
    "generated_combat_frames/index.json",
    "generated_combat_frames/frames.bin",
    "generated_combat_frames/particles.json",
    "generated_combat_frames/particles.bin",
)


def read_pck(data):
    # Godot 4.4 PCK format v2: offsets are relative to file_base when packed.
    if data[:4] != b"GDPC":
        raise ValueError("PCK signature missing")
    version, major, minor, patch, flags = struct.unpack_from("<5I", data, 4)
    if version != 2 or major != 4 or flags & 1:
        raise ValueError(f"unsupported/encrypted PCK {version=} {major=} {flags=}")
    file_base = struct.unpack_from("<Q", data, 24)[0]
    count = struct.unpack_from("<I", data, 96)[0]
    cursor = 100
    entries = {}
    for _ in range(count):
        length = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        name = data[cursor:cursor + length].rstrip(b"\x00").decode("utf-8")
        cursor += length
        offset, size = struct.unpack_from("<QQ", data, cursor)
        digest = data[cursor + 16:cursor + 32]
        entry_flags = struct.unpack_from("<I", data, cursor + 32)[0]
        cursor += 36
        name = name.removeprefix("res://")
        if name not in FILES:
            continue
        if entry_flags:
            raise ValueError(f"unsupported entry flags for {name}")
        start = file_base + offset
        payload = data[start:start + size]
        if len(payload) != size or hashlib.md5(payload).digest() != digest:
            raise ValueError(f"invalid PCK payload {name}")
        entries[name] = payload
    return entries


def verify(apk, root):
    expected = {name: (root / name).read_bytes() for name in FILES}
    found = {}
    with zipfile.ZipFile(apk) as archive:
        for entry in archive.namelist():
            if not entry.startswith("assets/"):
                continue
            name = entry.removeprefix("assets/")
            if name in expected:
                found[name] = archive.read(entry)
            elif entry.endswith(".pck"):
                found.update(read_pck(archive.read(entry)))
    report = {}
    for name, payload in expected.items():
        if not payload or found.get(name) != payload:
            raise SystemExit(f"missing or mismatched APK combat resource: {name}")
        report[name] = {"bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest()}
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=pathlib.Path)
    parser.add_argument("root", type=pathlib.Path)
    parser.add_argument("report", type=pathlib.Path)
    args = parser.parse_args()
    report = verify(args.apk, args.root)
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(f"KINDRIA_APK_PACK_VERIFIED files={len(report)}")
