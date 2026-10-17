# Drag Mini first Android APK (prototype)

This CI workflow exports a **debug-signed ARM64 APK** with Godot 4.6 using the native **Gradle** template. The Android Live Wallpaper plugin is downloaded from TheOathMan's v1.5.1 MIT release with a pinned SHA-256 before export. Wheels spin independently in racing and wallpaper presentation mode.

- GitHub Actions `Drag Mini Android ARM64 APK (Debug)` publishes an `DragMini-v0.2-Android-ARM64-debug` artifact on success.
- Requires no developer keystore; debug signing certificate is generated only on the GitHub runner. This is **not** a production/Play Store signed build.
- Select a car, choose MANUAL/AUTO, start a local race, check wheel rotations at varied speed.
- Use **WALLPAPER** to open the Android live wallpaper picker. Test launch, home-screen visibility pause, lock screen and switch between apps on a physical phone.
- Overlay over YouTube or Facebook, multiplayer, Android dynamic physics, real tuning and persistence beyond car selection are **not implemented**.
- TheOathMan v1.5.1 binaries target an older Godot version than 4.6; physical compatibility and Android runtime behavior need validation even after APK export.

The app identifier `com.dragmini.pixelstreet` is a provisional debug package; decide the final legal and publishing identifier before releasing.
