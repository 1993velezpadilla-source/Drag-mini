import json, struct, subprocess, tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for path in sorted((root / "assets/tevy_cc0_decoded_sources").glob("*.glb")):
    raw = path.read_bytes()
    magic, version, total, n, kind = struct.unpack_from("<5I", raw)
    assert magic == 0x46546c67 and version == 2 and total == len(raw)
    doc = json.loads(raw[20:20+n])
    if "KHR_texture_basisu" not in doc.get("extensionsUsed", []):
        continue
    size, kind = struct.unpack_from("<2I", raw, 20+n)
    assert kind == 0x004e4942
    buf = bytearray(raw[28+n:28+n+size])
    converted = {}
    with tempfile.TemporaryDirectory() as tmp:
        for tex in doc["textures"]:
            ext = tex.get("extensions", {}).pop("KHR_texture_basisu", None)
            if ext is None:
                continue
            idx = ext["source"]
            if idx not in converted:
                img = doc["images"][idx]
                view = doc["bufferViews"][img["bufferView"]]
                assert view.get("buffer", 0) == 0
                start = view.get("byteOffset", 0)
                src = Path(tmp) / "input.ktx2"
                dst = Path(tmp) / "output.png"
                src.write_bytes(buf[start:start+view["byteLength"]])
                dst.unlink(missing_ok=True)
                subprocess.run(["ktx", "extract", "--transcode", "rgba8", str(src), str(dst)], check=True)
                png = dst.read_bytes()
                assert png.startswith(b"\x89PNG\r\n\x1a\n")
                buf.extend(b"\0" * (-len(buf) % 4))
                doc["bufferViews"].append(dict(buffer=0, byteOffset=len(buf), byteLength=len(png)))
                buf.extend(png)
                img["bufferView"] = len(doc["bufferViews"])-1
                img["mimeType"] = "image/png"
                converted[idx] = True
            tex["source"] = idx
            if not tex.get("extensions"):
                tex.pop("extensions", None)
    for key in ("extensionsUsed", "extensionsRequired"):
        if key in doc:
            doc[key] = [x for x in doc[key] if x != "KHR_texture_basisu"]
    buf.extend(b"\0" * (-len(buf) % 4))
    doc["buffers"][0]["byteLength"] = len(buf)
    j = json.dumps(doc, separators=(",", ":")).encode()
    j += b" " * (-len(j) % 4)
    result = struct.pack("<5I", magic, version, 28+len(j)+len(buf), len(j), 0x4e4f534a) + j + struct.pack("<2I", len(buf), 0x004e4942) + buf
    path.write_bytes(result)
    print("BASIS_TEXTURES_DECODED", path.name, len(converted))
