#!/usr/bin/env bash
set -euo pipefail
PKG=org.myforeverpet.paradise
mkdir -p /tmp/pet-screens
adb install -r "$1"
adb shell pm clear "$PKG"
adb shell am start -W -n "$PKG/.MainActivity"
sleep 2
dump() { adb shell uiautomator dump /sdcard/pet.xml >/dev/null; adb pull /sdcard/pet.xml /tmp/pet.xml >/dev/null; }
tap_text() {
 dump
 local coords
 coords=$(python3 - "$1" <<'PY'
import sys,re,xml.etree.ElementTree as ET
for n in ET.parse('/tmp/pet.xml').iter('node'):
    if n.get('text')==sys.argv[1]:
        v=list(map(int,re.findall(r'\d+',n.get('bounds'))))
        print((v[0]+v[2])//2,(v[1]+v[3])//2)
        break
else: raise SystemExit('Missing button: '+sys.argv[1])
PY
)
 adb shell input tap $coords
 sleep 1
}
assert_text(){ dump; grep -Fq "$1" /tmp/pet.xml; }
shot(){ adb exec-out screencap -p > "/tmp/pet-screens/$1.png"; }
assert_text "Egg"
shot egg
tap_text "Hatch egg"
assert_text "Baby"
shot baby
tap_text "Mini game"
tap_text "Flappy Pet"
shot flappy
adb shell input tap 300 500
sleep 2
tap_text "Finish"
tap_text "Mini game"
tap_text "Cloud Jump"
shot cloud-jump
adb shell input tap 300 500
sleep 2
tap_text "Finish"
tap_text "Feed"
tap_text "Fish"
tap_text "Cell"
assert_text "Inspect cells"
shot cell
tap_text "Field"
tap_text "Clean field"
shot field
tap_text "Space"
shot space
tap_text "Lab"
shot lab
tap_text "Shop"
shot shop
adb shell input keyevent 4
sleep 1
adb shell am force-stop "$PKG"
adb shell am start -W -n "$PKG/.MainActivity"
sleep 2
assert_text "Baby"
shot restored
tap_text "Live wallpaper"
shot wallpaper-picker
adb shell dumpsys package "$PKG" | grep -F 'PetWallpaper'
adb logcat -d -s AndroidRuntime:E > /tmp/pet-screens/android-runtime.txt
if grep -Fq "Process: $PKG" /tmp/pet-screens/android-runtime.txt; then exit 1; fi
