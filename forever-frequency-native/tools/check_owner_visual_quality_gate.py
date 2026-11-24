#!/usr/bin/env python3
"""City Zero fail-closed owner visual quality gate.

Technical source/import/render/triangle tests DO NOT prove art quality.
The November 24 2026 owner decision explicitly REJECTED all non-orange
vehicle candidates. This file is intentionally non-generative.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "data" / "owner_rejected_vehicle_art_2026_11_24.json"
GOLD = ROOT / "data" / "approved_lamborghini_gold_standard.json"
GOLD_GLTF = ROOT / "assets" / "curated_rigged" / "curated_midengine_supercar.glb"
EXPECTED_SHA256 = "45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"
PROTOTYPE_DIRS = (
    ROOT / "assets" / "premium_fleet",
    ROOT / "assets" / "mobility_fleet",
    ROOT / "assets" / "tevy_cc0_blender_vehicles",
)
CATALOGS = (
    ("procedural_car", ROOT / "data" / "vehicle_fleet_catalog.json", "models"),
    ("procedural_mobility", ROOT / "data" / "mobility_fleet_catalog.json", "models"),
    ("third_party_author_source", ROOT / "data" / "pinned_artist_licensed_premium_car_sources.json", "records"),
    ("third_party_author_source", ROOT / "data" / "pinned_artist_premium_round2.json", "records"),
)

def main() -> None:
    args = argparse.ArgumentParser()
    args.add_argument("--shipping", action="store_true", help="Reject any non-owner-approved vehicle in the Godot distribution")
    opt = args.parse_args()
    gold = json.loads(GOLD.read_text())
    review = json.loads(REVIEW.read_text())
    assert GOLD_GLTF.is_file(), "Owner-approved orange Lamborghini is MISSING"
    original = GOLD_GLTF.read_bytes()
    assert len(original) == gold["bytes"] == 3689788, "Owner's car was substituted or corrupted"
    assert hashlib.sha256(original).hexdigest() == gold["expected_sha256"] == EXPECTED_SHA256, (
        "STOP: user-approved orange Lamborghini changed without consent"
    )
    assert review["visual_gold_standard"]["sha256"] == EXPECTED_SHA256
    assert review["visual_gold_standard"]["owner_approved"] is True
    assert review["current_owner_approved_vehicle_count"] == 1

    actual: dict[str, str] = {}
    for group, path, key in CATALOGS:
        source = json.loads(path.read_text())
        for row in source[key]:
            model_id = row["id"]
            assert model_id not in actual, "Duplicate models masquerading as fleet diversity: "+model_id
            actual[model_id] = group
            assert not row.get("user_approved", False), "Candidate falsely approved: "+model_id
            assert not row.get("production_approved", False), "Candidate falsely approved for production: "+model_id
            assert not row.get("game_ready", False), "Candidate falsely marked game ready: "+model_id

    reviews = review["vehicle_reviews"]
    assert set(reviews) == set(actual), "New/unreviewed vehicle entries cannot bypass owner rejection gate"
    assert len(reviews) == 103, "Expected 103 visually rejected cars and mobility models"
    for model_id, entry in reviews.items():
        assert entry["source"] == actual[model_id], "Catalog group mismatch "+model_id
        assert entry["art_status"] == "REJECTED_VISUAL_QUALITY_2026_11_24", model_id
        assert entry["approved_for_gameplay"] is False, model_id
        assert entry["meets_orange_lamborghini_quality"] is False, model_id
        assert entry["needs_rebuild_or_replacement"] is True, model_id
    assert all(x not in actual for x in ["curated_midengine_supercar","exotic_supercar__revulse"]), (
        "Do not replace the exact orange GLB with a rejected lookalike"
    )
    print("CITY_ZERO_VISUAL_QUALITY_GATE: 1 OWNER APPROVED ORANGE MODEL, 103 REJECTED")
    print("Blender/Godot technical PASS != owner visual APPROVAL")

    if opt.shipping:
        shipped = []
        for folder in PROTOTYPE_DIRS:
            if folder.exists():
                shipped += [str(p.relative_to(ROOT)) for p in folder.glob("*.glb")]
        if shipped:
            raise SystemExit("BLOCK RELEASE: user-rejected vehicle GLBs are in Godot assets: " +
                             ", ".join(shipped[:16]))
        print("CITY_ZERO_SHIPPING_ASSET_GATE_GREEN: no rejected prototype fleet included in Godot runtime")

if __name__ == "__main__":
    main()
