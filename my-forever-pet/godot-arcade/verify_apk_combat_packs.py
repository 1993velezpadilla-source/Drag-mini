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
    if len(data) < 100 or data[:4] != b"GDPC":
        raise ValueError("PCK signature missing")
    version, major, minor, patch, flags = struct.unpack_from("<5I", data, 4)
    if version != 2 or major != 4 or flags & 1:
        raise ValueError(f"unsupported/encrypted PCK {version=} {major=} {flags=}")
    file_base = struct.unpack_from("<Q", data, 24)[0]
    count = struct.unpack_from("<I", data, 96)[0]
    if not 100 <= file_base <= len(data) or count > (file_base - 100) // 40:
        raise ValueError("invalid PCK directory bounds")
    cursor = 100
    entries = {}
    for _ in range(count):
        if cursor + 4 > file_base:
            raise ValueError("truncated PCK directory")
        length = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        if length == 0 or cursor + length + 36 > file_base:
            raise ValueError("invalid PCK entry name or directory size")
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
        if name in entries:
            raise ValueError(f"duplicate PCK combat resource {name}")
        entries[name] = payload
    return entries


def verify(apk, root):
    expected = {name: (root / name).read_bytes() for name in FILES}
    found = {}
    def record(name, payload):
        if name in found and found[name] != payload:
            raise ValueError(f"conflicting APK combat resource copies: {name}")
        found[name] = payload

    with zipfile.ZipFile(apk) as archive:
        for info in archive.infolist():
            entry = info.filename
            if not entry.startswith("assets/"):
                continue
            name = entry.removeprefix("assets/")
            if name in expected:
                record(name, archive.read(info))
            elif entry.endswith(".pck"):
                for resource, payload in read_pck(archive.read(info)).items():
                    record(resource, payload)
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
