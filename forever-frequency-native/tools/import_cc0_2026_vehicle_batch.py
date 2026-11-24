"""Authentic source-only vehicle intake from Tevy 2026 CC0 catalog.

The user's approved orange Lamborghini is a hash-locked original source model,
NOT the procedural REVULSE. This importer uses that original CC0 sourcing
workflow for cars, motorcycles, boats and aircraft. It NEVER generates a car
body or invents a vehicle. All output stays NOT GAME READY pending visual QA.
"""
import hashlib
import json
import os
import re
import urllib.request
from pathlib import Path
from urllib.parse import urljoin, urlparse

ROOT = Path(__file__).resolve().parents[1]
URL = "https://tevy.dev/models.json"
SOURCE_DIR = ROOT / "assets" / "tevy_cc0_original_sources"
AUDIT_DIR = ROOT / "real_cc0_source_vehicle_audit"
SOURCE_DIR.mkdir(parents=True, exist_ok=True)
AUDIT_DIR.mkdir(parents=True, exist_ok=True)
BATCH_SIZE = int(os.getenv("CITYZERO_CC0_BATCH_SIZE", "6"))
BATCH_INDEX = int(os.getenv("CITYZERO_CC0_BATCH_INDEX", "0"))
MIN_TRIANGLES = 6000
REFERENCE_SHA = "45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"
assert 0 <= BATCH_INDEX <= 1000 and 1 <= BATCH_SIZE <= 12

def get_bytes(url, max_bytes=250_000_000):
    request = urllib.request.Request(url, headers={
        "User-Agent": "CityZero-Real-CC0-Model-Audit/1.0 (original source integrity)",
        "Accept": "application/json,model/gltf-binary,application/octet-stream,*/*",
    })
    with urllib.request.urlopen(request, timeout=90) as handle:
        content = handle.read(max_bytes + 1)
    if len(content) > max_bytes:
        raise RuntimeError("Excessively large source: " + url)
    return content

catalog_bytes = get_bytes(URL, 50_000_000)
catalog = json.loads(catalog_bytes)
models = catalog.get("models", [])
if len(models) < 1000 or catalog.get("count", 0) < 1000:
    raise RuntimeError("Official CC0 catalog was truncated")
ids = set()
vehicles = []
for entry in models:
    if entry.get("category") != "vehicles" or entry.get("deprecated"):
        continue
    if entry.get("license") != "CC0-1.0":
        continue
    slug = entry.get("slug", "")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{2,99}", slug):
        continue
    if slug in ids:
        raise RuntimeError("Source site has duplicate vehicles " + slug)
    ids.add(slug)
    files = entry.get("files", [])
    lod0 = next((f for f in files if f.get("lod") == 0), None)
    if not lod0 or int(lod0.get("triangles", 0)) < MIN_TRIANGLES:
        continue
    if not re.fullmatch(r"[a-f0-9]{64}", lod0.get("sha256", "")):
        continue
    source_path = lod0.get("path", "")
    if not source_path.startswith("/models/") or not source_path.endswith("/lod0.glb"):
        continue
    if int(lod0.get("bytes", 0)) < 75000:
        continue
    body = {
        "id": slug,
        "name": entry.get("name", slug),
        "category": "vehicles",
        "tags": entry.get("tags", []),
        "description": entry.get("description", ""),
        "license": "CC0-1.0 (declared by tevy.dev)",
        "source_page": urljoin("https://tevy.dev", f"/models/{slug}"),
        "source_glb": urljoin("https://tevy.dev", source_path),
        "sha256": lod0["sha256"],
        "bytes": int(lod0["bytes"]),
        "author_declared_triangles_lod0": int(lod0["triangles"]),
        "dimensions": entry.get("dimensions"),
        "parts": entry.get("parts", []),
        "original_model_version": entry.get("version"),
        "asset_status": "ORIGINAL_SOURCE_VERIFIED_PENDING_BLENDER_AND_GODOT_VISUAL_REVIEW",
        "approved_gold_reference": REFERENCE_SHA,
        "user_approved": False,
        "game_ready": False,
    }
    vehicles.append(body)
# Stable deterministic audit order. Every unique vehicle is counted ONCE,
# regardless of extra LODs or paint variants; never claim 100 by recoloring.
vehicles.sort(key=lambda x: x["id"])
if not vehicles:
    raise RuntimeError("No authentic CC0 source vehicles found")
all_manifest = {
    "source": URL,
    "source_site_generated": catalog.get("generated", ""),
    "catalog_sha256": hashlib.sha256(catalog_bytes).hexdigest(),
    "vehicle_count": len(vehicles),
    "quality_policy": "Source license, exact byte SHA, native Blender geometry and genuine Godot visual proof. REJECT every model without full QA.",
    "reference_lamborghini_original_sha256": REFERENCE_SHA,
    "models": vehicles,
}
(AUDIT_DIR / "tevy_original_vehicle_inventory.json").write_text(json.dumps(all_manifest, indent=2) + "\n")
start = BATCH_INDEX * BATCH_SIZE
selected = vehicles[start:start+BATCH_SIZE]
if not selected:
    raise RuntimeError("No CC0 vehicles for batch index %s: catalog has %s" % (BATCH_INDEX, len(vehicles)))
if os.getenv("CITYZERO_CC0_INVENTORY_ONLY") == "1":
    print("TEVY_REAL_CC0_VEHICLE_SOURCE_INVENTORY_GREEN count", len(vehicles),
          "batch", BATCH_INDEX, "chosen", [m["id"] for m in selected])
    raise SystemExit(0)

for model in selected:
    src_url = model["source_glb"]
    parsed = urlparse(src_url)
    if parsed.hostname != "tevy.dev" or parsed.scheme != "https":
        raise RuntimeError("Untrusted source host " + src_url)
    raw = get_bytes(src_url, 35_000_000)
    if len(raw) != model["bytes"]:
        raise RuntimeError("Official original GLB byte mismatch " + model["id"])
    if raw[:4] != b"glTF":
        raise RuntimeError("Not a real GLB original " + model["id"])
    if hashlib.sha256(raw).hexdigest() != model["sha256"]:
        raise RuntimeError("Original source SHA mismatch " + model["id"])
    (SOURCE_DIR / (model["id"] + ".glb")).write_bytes(raw)
    print("VERIFIED_ORIGINAL_CC0_GLB", model["id"], len(raw),
          model["author_declared_triangles_lod0"], flush=True)
batch = {
    "batch_index": BATCH_INDEX,
    "batch_size": BATCH_SIZE,
    "source_catalog_count": len(vehicles),
    "models": selected,
    "status": "SOURCE_SHA_VERIFIED_NOT_GAME_READY",
}
(AUDIT_DIR / "downloaded_original_cc0_vehicle_batch.json").write_text(json.dumps(batch, indent=2) + "\n")
print("REAL_CC0_SOURCE_BATCH_HASH_VERIFIED_GREEN", [m["id"] for m in selected], flush=True)
