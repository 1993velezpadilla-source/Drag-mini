#!/usr/bin/env bash
set -euo pipefail
PKG=org.myforeverpet.paradise
mkdir -p /tmp/pet-screens
trap 'rc=$?; if [ "$rc" != 0 ]; then adb exec-out screencap -p > /tmp/pet-screens/failure.png || true; adb logcat -d -s AndroidRuntime:E > /tmp/pet-screens/failure-log.txt || true; cp /tmp/pet.xml /tmp/pet-screens/failure.xml 2>/dev/null || true; fi' EXIT
adb install -r "$1"
adb shell pm clear "$PKG"
adb shell am start -W -n "$PKG/.MainActivity"
sleep 2
dump() { adb shell uiautomator dump /sdcard/pet.xml >/dev/null; adb pull /sdcard/pet.xml /tmp/pet.xml >/dev/null; }
tap_text() {
 echo "Tap UI: $1"
 dump
 local coords
 coords=$(python3 - "$1" <<'PY'
import sys,re,xml.etree.ElementTree as ET
for n in ET.parse('/tmp/pet.xml').iter('node'):
    label=n.get('text') or ''
    if label.casefold()==sys.argv[1].casefold() or (n.get('content-desc') or '').casefold()==sys.argv[1].casefold() or (sys.argv[1]=='@clock' and n.get('content-desc')=='Game clock'):
        v=list(map(int,re.findall(r'\d+',n.get('bounds'))))
        print((v[0]+v[2])//2,(v[1]+v[3])//2)
        break
else: raise SystemExit('Missing button: '+sys.argv[1])
PY
)
 adb shell input tap $coords
 sleep 1
}
assert_text(){ echo "Assert UI: $1"; for i in 1 2 3; do dump; if grep -Fiq "$1" /tmp/pet.xml; then return 0; fi; sleep 2; done; cat /tmp/pet.xml; return 1; }
shot(){ adb exec-out screencap -p > "/tmp/pet-screens/$1.png"; }
shot egg
assert_text "Hatch egg"
tap_text "Hatch egg"
assert_text "Baby"
assert_text "Next: Kid"
shot baby
tap_text "Expand scene"
shot expanded
tap_text "Expand scene"
tap_text "@clock"
assert_text "Real-time routine"
shot routine
tap_text "Disable auto sleep"
tap_text "Rooms"
tap_text "Kitchen"
shot kitchen
tap_text "Rooms"
tap_text "Bathroom"
assert_text "Hygiene"
shot bathroom
tap_text "Rooms"
tap_text "Bedroom"
shot bedroom
tap_text "Rooms"
tap_text "Playroom"
shot playroom
tap_text "Rooms"
tap_text "Garden"
shot garden
tap_text "Rooms"
tap_text "Potion lab"
shot potion-lab
tap_text "Back"
tap_text "Arcade"
tap_text "Flappy Pet"
shot flappy
adb shell input tap 300 500
sleep 2
tap_text "Exit & collect"
tap_text "Arcade"
tap_text "Cloud Jump"
shot cloud-jump
tap_text "Exit & collect"
tap_text "Arcade"
tap_text "Find My Pet"
shot find-my-pet
tap_text "Zoom / overview"
shot find-zoom
tap_text "Exit & collect"
tap_text "Arcade"
tap_text "Pet Dash"
shot pet-dash
tap_text "Exit & collect"
tap_text "World"
tap_text "Cell"
assert_text "Inspect cells"
shot cell
tap_text "World"
tap_text "Field"
tap_text "Clean field"
shot field
tap_text "World"
tap_text "Space"
shot space
tap_text "Lab"
tap_text "Shop"
shot shop
adb shell input keyevent 4
sleep 1
adb shell am force-stop "$PKG"
adb shell am start -W -n "$PKG/.MainActivity"
sleep 2
assert_text "Baby"
shot restored
tap_text "World"
tap_text "Wallpaper"
shot wallpaper-picker
adb shell dumpsys package "$PKG" | grep -F 'PetWallpaper'
adb logcat -d -s AndroidRuntime:E > /tmp/pet-screens/android-runtime.txt
if grep -Fq "Process: $PKG" /tmp/pet-screens/android-runtime.txt; then exit 1; fi
