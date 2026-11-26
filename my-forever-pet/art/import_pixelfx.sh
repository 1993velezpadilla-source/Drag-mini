#!/usr/bin/env bash
set -euo pipefail
out="$(realpath -m "$1")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
rev=babe913bc8ee95536320668d2c69996dbe260926
curl -fL --retry 3 "https://codeload.github.com/yan513/pixelfx-godot/tar.gz/$rev" -o "$tmp/source.tar.gz"
tar -xzf "$tmp/source.tar.gz" -C "$tmp" --strip-components=1
cd "$tmp"
node tools/sheets.mjs fire/spirit-flame fire/fire-breath pickups/heart-pickup water/bubbles holy/heal
mkdir -p "$out"
for id in fire/spirit-flame fire/fire-breath pickups/heart-pickup water/bubbles holy/heal; do
  name="${id##*/}"
  test -s "sheets/$id.png";test -s "sheets/$id.json"
  cp "sheets/$id.png" "$out/$name.png";cp "sheets/$id.json" "$out/$name.json"
done
cp LICENSE "$out/LICENSE-pixelfx.txt"
python3 - "$out" <<'PY'
import json,sys,pathlib,struct
for j in pathlib.Path(sys.argv[1]).glob("*.json"):
    data=json.loads(j.read_text()); png=j.with_suffix(".png").read_bytes()
    w,h=struct.unpack(">II",png[16:24]); frames=data["frames"]
    assert len(frames)>1 and data["meta"]["pixelfx"]["frames"]==len(frames)
    assert all(x["frame"]["x"]+x["frame"]["w"]<=w and x["frame"]["y"]+x["frame"]["h"]<=h for x in frames)
    print("PIXELFX_BAKED",j.stem,len(frames),w,h)
PY
