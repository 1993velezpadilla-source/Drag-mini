#!/usr/bin/env bash
set -euo pipefail
# Build audited MIT-licensed upstream code against SAME Godot Android API as the app.
UPSTREAM_COMMIT="e2b7628e3782800f182b5b6b24922903139b00aa"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
git clone --quiet https://github.com/TheOathMan/Godot-Android-Live-Wallpaper.git "$WORK/source"
git -C "$WORK/source" checkout --quiet "$UPSTREAM_COMMIT"
ORIGINAL="$WORK/source/plugin/build.gradle.kts"
grep -Fq 'api(project(":GD4_5"))' "$ORIGINAL"
sed -i 's/api(project(":GD4_5"))/implementation("org.godotengine:godot:4.6.0.stable")/' "$ORIGINAL"
# Godot 4.6 added two GodotRenderView members and renamed lifecycle hooks.
VIEW="$WORK/source/plugin/src/main/java/org/godotengine/plugin/android/LiveWallpaper/GodotGLRenderViewWP.kt"
python3 - "$VIEW" <<'PY_COMPAT'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
old = "    override fun onActivityDestroyed() {"
if old not in source:
    raise SystemExit("Unexpected upstream GodotRenderView lifecycle source")
source = source.replace(old, "    fun onActivityDestroyed() {", 1)
marker = "    override fun onActivityResumed() {"
if marker not in source:
    raise SystemExit("Unexpected render view source")
methods = """    override fun blockingExitRenderer(timeout: Long): Boolean {
        requestRenderThreadExitAndWait()
        return true
    }

    override fun canCapturePointer(): Boolean {
        return android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O
    }

"""
source = source.replace(marker, methods + marker, 1)
path.write_text(source)
PY_COMPAT
# Godot 4.6 only exposes publicly annotated Android methods.
# Screenshot V0.4: singleton exists, but startWallpaperService is not visible.
LW="$WORK/source/plugin/src/main/java/org/godotengine/plugin/android/LiveWallpaper/LiveWallpaper.kt"
python3 - "$LW" <<'PY_WALLPAPER_API'
from pathlib import Path
import sys
p=Path(sys.argv[1])
text=p.read_text()
old="    private fun startWallpaperService(): Int {"
if text.count(old) != 1:
    raise SystemExit("Upstream @UsedByGodot startWallpaperService signature changed")
text=text.replace(old,"    fun startWallpaperService(): Int {")
text=text.replace("    private fun IsPreview():Boolean{","    fun IsPreview():Boolean{")
p.write_text(text)
PY_WALLPAPER_API
chmod +x "$WORK/source/gradlew"
(
  cd "$WORK/source"
  ./gradlew :plugin:assembleDebug :plugin:assembleRelease --no-daemon --stacktrace
)
BIN="$PROJECT_ROOT/addons/Android/LiveWallpaper/bin"
test -d "$BIN"
for TYPE in debug release; do
  SOURCE_AAR="$WORK/source/plugin/build/outputs/aar/LiveWallpaper-$TYPE.aar"
  test -s "$SOURCE_AAR"
  cp "$SOURCE_AAR" "$BIN/LiveWallpaper-$TYPE.aar"
  echo "REBUILT WALLPAPER GODOT 4.6: $TYPE"
  sha256sum "$BIN/LiveWallpaper-$TYPE.aar"
done
