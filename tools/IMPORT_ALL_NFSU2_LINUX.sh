#!/usr/bin/env bash
# City Zero: privately import all original NFS Underground 2 vehicle assets.
# Usage: bash tools/IMPORT_ALL_NFSU2_LINUX.sh "/path/to/Need for Speed Underground 2"
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="$REPO/tools/_nfsu2_world_editor"
OUT="$HOME/CityZeroNFSU2Imported"

for cmd in git python3 blender; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is needed to export genuine NFSU2 meshes." >&2
        exit 1
    fi
done
if [[ ! -f "$UPSTREAM/nfsu2_world_editor/core/cars.py" ]]; then
    git clone --depth 1 https://github.com/mininxd/NFSU2-World-Editor.git "$UPSTREAM"
fi
GAME="$1"
if [[ -z "$GAME" ]]; then read -r -p 'Full path to installed NFSU2 directory: ' GAME; fi
if [[ ! -d "$GAME/CARS" ]]; then
    echo "ERROR: No original CARS directory at '$GAME' — no assets were invented." >&2
    exit 1
fi
if ! command -v vgmstream-cli >/dev/null 2>&1; then
    echo 'NOTE: vgmstream-cli is needed to decode ABK/GIN into WAV; inventory still works.'
fi
python3 "$REPO/tools/nfsu2_import_all.py" \
    --game-root "$GAME" \
    --converter-dir "$UPSTREAM" \
    --out "$OUT" \
    --export-all
printf '\nPRIVATE ORIGINAL CONTENT: %s\n' "$OUT"
printf 'SHOWROOM LIBRARY: %s/cityzero_godot_library.json\n' "$OUT"
printf 'Open Godot scene city_zero/nfsu2_private/CityZeroNFSU2Showroom.tscn and select that JSON.\n'
