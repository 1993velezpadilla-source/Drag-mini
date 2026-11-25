#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PIN=e80354eccba2124fdbfcf37d323a39a2104f3832
if [ ! -d upstream/.git ]; then
  git clone https://github.com/infinition/capybara.git upstream
fi
git -C upstream checkout --detach "$PIN"
test "$(git -C upstream rev-parse HEAD)" = "$PIN"
mkdir -p native/src app/src/main/assets
rm -rf native/src/emulator native/assets
cp -R upstream/src/emulator native/src/
cp upstream/src/touches.rs native/src/
cp -R upstream/assets native/assets
cp upstream/LICENSE app/src/main/assets/CAPYBARA-LICENSE.txt
diff -qr upstream/src/emulator native/src/emulator
cmp upstream/src/touches.rs native/src/touches.rs
