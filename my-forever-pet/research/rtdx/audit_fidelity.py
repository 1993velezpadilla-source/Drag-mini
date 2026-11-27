"""Validate evidence coverage against the actual Kindria catalog.
A reference key is not proof of Rescue Team DX availability or timing.
"""
import argparse
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1] / "godot-arcade"

def read_constant(source, name):
    match = re.search(r"^const " + name + r"\s*(?::[^=]+)?\s*=\s*(\{.*\})$", source, re.M)
    if not match:
        raise ValueError("Missing JSON constant: " + name)
    return json.loads(match.group(1))

def build():
    rules = (GAME / "dungeon_rules.gd").read_text(encoding="utf-8")
    view = (GAME / "dungeon_view.gd").read_text(encoding="utf-8")
    evidence = json.loads((HERE / "v15-reference-evidence.json").read_text(encoding="utf-8"))
    catalog = read_constant(rules, "MOVE_LIBRARY") | read_constant(rules, "DEV_NATIVE_MOVES")
    observed = set(json.loads(re.search(r"^const RTDX_OBSERVED_MOVES=(\[.*\])$", view, re.M).group(1)))
    images = {x["kindria_id"]: x for x in evidence["images"] if x.get("kindria_id")}
    implementations = {x["id"]: x for x in evidence["implementation"]}
    for id in observed:
        assert id in catalog and id in implementations
        assert images[id]["status"] == "still_inspected", id
        assert images[id].get("page") and images[id].get("observation"), id
    assert set(images) <= set(catalog), "Stale mapped reference"
    rows = []
    for id, v in sorted(catalog.items()):
        image = images.get(id, {})
        renderer = "still_grounded" if id in observed else "existing_route_regression" if id in implementations else "authored_unverified"
        rows.append(dict(id=id, name=v["name"], type=v["type"], reference_key=v.get("reference_key"),
                         evidence=image.get("status", "not_located"), source=image.get("page"),
                         renderer=renderer, timing_verified=False))
    counts = dict(total=len(rows), reference_key=sum(bool(x["reference_key"]) for x in rows),
                  still_grounded=sum(x["renderer"] == "still_grounded" for x in rows),
                  existing_route_regression=sum(x["renderer"] == "existing_route_regression" for x in rows),
                  authored_unverified=sum(x["renderer"] == "authored_unverified" for x in rows),
                  timing_verified=0, inspected_stills=sum(x["status"] == "still_inspected" for x in evidence["images"]))
    return dict(schema=1, counts=counts, rows=rows)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    actual = build()
    path = HERE / "v15-fidelity-ledger.json"
    if args.write:
        path.write_text(json.dumps(actual, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    else:
        assert json.loads(path.read_text(encoding="utf-8")) == actual, "Fidelity ledger stale"
    print("KINDRIA_FIDELITY_LEDGER_PASS", json.dumps(actual["counts"]))

if __name__ == "__main__":
    main()
