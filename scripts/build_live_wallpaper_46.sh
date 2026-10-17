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
grep -q 'org.godotengine:godot:4.5.0.stable' "$ORIGINAL"
sed -i 's/org.godotengine:godot:4.5.0.stable/org.godotengine:godot:4.6.0.stable/g' "$ORIGINAL"
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
