#!/usr/bin/env bash
# SDK-only packaging for the dependency-free Java Android app.
set -euo pipefail
cd "$(dirname "$0")"
SDK="${ANDROID_HOME:?ANDROID_HOME must be set}"
BT="$SDK/build-tools/35.0.0"
ANDROID_JAR="$SDK/platforms/android-35/android.jar"
OUT="$PWD/app/build/outputs/apk/debug"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT" "$WORK/classes" "$WORK/dex"
python3 - "$WORK/AndroidManifest.xml" <<'PY'
import pathlib,re,sys
gradle=pathlib.Path('app/build.gradle').read_text()
manifest=pathlib.Path('app/src/main/AndroidManifest.xml').read_text()
pkg=re.search(r"applicationId\s+'([^']+)'",gradle).group(1)
code=re.search(r"versionCode\s+(\d+)",gradle).group(1)
name=re.search(r"versionName\s+'([^']+)'",gradle).group(1)
manifest=manifest.replace('<manifest ',f'<manifest package="{pkg}" android:versionCode="{code}" android:versionName="{name}" ',1)
pathlib.Path(sys.argv[1]).write_text(manifest)
PY
"$BT/aapt2" compile --dir app/src/main/res -o "$WORK/res.zip"
"$BT/aapt2" link -I "$ANDROID_JAR" --manifest "$WORK/AndroidManifest.xml" --min-sdk-version 26 --target-sdk-version 34 --debug-mode -o "$WORK/unsigned.apk" "$WORK/res.zip"
find app/src/main/java -name '*.java' -print > "$WORK/sources"
javac --release 8 -classpath "$ANDROID_JAR" -d "$WORK/classes" @"$WORK/sources"
jar cf "$WORK/classes.jar" -C "$WORK/classes" .
"$BT/d8" --release --min-api 26 --lib "$ANDROID_JAR" --output "$WORK/dex" "$WORK/classes.jar"
(cd "$WORK/dex" && zip -q -j "$WORK/unsigned.apk" classes*.dex)
"$BT/zipalign" -f 4 "$WORK/unsigned.apk" "$WORK/aligned.apk"
KEY="${HOME}/.android/debug.keystore"
mkdir -p "$(dirname "$KEY")"
if [ ! -f "$KEY" ]; then
  keytool -genkeypair -keystore "$KEY" -storepass android -keypass android -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
fi
"$BT/apksigner" sign --ks "$KEY" --ks-pass pass:android --key-pass pass:android --ks-key-alias androiddebugkey --out "$OUT/app-debug.apk" "$WORK/aligned.apk"
"$BT/apksigner" verify --verbose "$OUT/app-debug.apk"
"$BT/aapt" dump badging "$OUT/app-debug.apk"
