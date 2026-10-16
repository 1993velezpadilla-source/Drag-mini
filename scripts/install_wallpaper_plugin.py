#!/usr/bin/env python3
"""Install pinned official TheOathMan Android Live Wallpaper plugin (MIT)."""
import hashlib
import io
import pathlib
import shutil
import sys
import tempfile
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
VERSION = "v1.5.1"
URL = f"https://github.com/TheOathMan/Godot-Android-Live-Wallpaper/releases/download/{VERSION}/GodotLiveWallpaperPlugin.zip"
EXPECTED_SHA256 = "0bfc928515cf1ba8f7127754a2d28e995f508145aadd35d7a5ebdf8f2153a6b2"
TARGET = ROOT / "addons" / "Android" / "LiveWallpaper"
REQUIRED = ("plugin.cfg", "LiveWallpaper.gd", "bin/LiveWallpaper-debug.aar", "bin/LiveWallpaper-release.aar")

def main() -> int:
    if all((TARGET / name).is_file() for name in REQUIRED):
        print("Live Wallpaper v1.5.1 present (not re-downloaded).")
        return 0
    print(f"Downloading {URL}")
    try:
        request = urllib.request.Request(URL, headers={"User-Agent": "DragMini-TheOathMan-PinnedInstaller/1.0"})
        with urllib.request.urlopen(request, timeout=90) as response:
            raw = response.read(1_000_000)
    except Exception as exc:
        print(f"Failed downloading plugin: {exc}", file=sys.stderr)
        return 1
    digest = hashlib.sha256(raw).hexdigest()
    if digest != EXPECTED_SHA256:
        print("Plugin SHA-256 MISMATCH. Aborting.", file=sys.stderr)
        return 1

    prefix = "addons/Android/LiveWallpaper/"
    with tempfile.TemporaryDirectory(prefix="dragmini_plugin_") as folder:
        staged = pathlib.Path(folder) / "LiveWallpaper"
        staged.mkdir(parents=True)
        with zipfile.ZipFile(io.BytesIO(raw)) as archive:
            found = 0
            for entry in archive.infolist():
                normalized = entry.filename.replace("\\", "/")
                if not normalized.startswith(prefix) or entry.is_dir():
                    continue
                relative = pathlib.PurePosixPath(normalized[len(prefix):])
                if relative.is_absolute() or ".." in relative.parts:
                    raise ValueError("Unsafe plugin archive filename")
                dest = staged.joinpath(*relative.parts)
                dest.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(entry, "r") as inp, dest.open("wb") as out:
                    shutil.copyfileobj(inp, out)
                found += 1
        missing = [name for name in REQUIRED if not (staged / name).is_file()]
        if missing:
            print(f"Plugin archive incompatible or incomplete: {missing}", file=sys.stderr)
            return 1
        if TARGET.exists():
            shutil.rmtree(TARGET)
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(staged, TARGET)
        print(f"Installed {found} files to {TARGET.relative_to(ROOT)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
