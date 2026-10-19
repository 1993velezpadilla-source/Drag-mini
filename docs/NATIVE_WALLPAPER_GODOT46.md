# Live Wallpaper compatibility build — Godot 4.6

After a physical Android 16 screenshot showed `Android LiveWallpaper singleton missing` even though APK bytecode included LiveWallpaper, we added this experimental native rebuild. It downloads the upstream MIT-licensed source at **pinned commit** `e2b7628e3782800f182b5b6b24922903139b00aa`, changes ONLY the compilation dependency from `org.godotengine:godot:4.5.0.stable` to `org.godotengine:godot:4.6.0.stable`, and rebuilds the Android AAR. The original source stays external; third-party license remains in `third_party/theoathman/LICENSE`.

The first Android v0.2 screenshot confirms the Java `LiveWallpaper` singleton was not accessible to GDScript. Previous CI tests on Linux cannot validate that. The rebuilt Android APK **must be installed and tested on-device**; this branch tests API alignment and manifest registration, NOT successful wallpaper rendering. Run `bash scripts/build_live_wallpaper_46.sh` on a workstation with Java 17 and Android SDK to reproduce the native library build. The GitHub Actions `Drag Mini Android ARM64 APK (Debug)` pipeline performs this automatically.

Acceptance criteria: tapping WALLPAPER launches the native Android wallpaper preview; after accepting it, home-screen renders selected car, wheels animate, and Android app remains launchable. Reconfirm on Pixel Fold with Android 16.
