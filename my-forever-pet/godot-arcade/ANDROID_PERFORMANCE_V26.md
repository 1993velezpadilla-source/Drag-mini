# Kindria V26.1 — physical Android evidence procedure

The desktop Godot probe is not Android certification. The latest V25.9 cinematic gauntlet passed 318,363 checks with zero failures (run 46083243001). Android APK export and the desktop release benchmark are separate gates.

## Capture a debug APK on physical hardware

1. Install the verified ARM64 debug APK from the matching GitHub Actions build. Record its commit and APK SHA256 from its provenance artifact.
2. Enable USB debugging, connect the device, and confirm it appears in `adb devices`. Do not use an emulator for the physical-device gate.
3. With the game closed, enable the existing Godot diagnostic marker:

   ```sh
   adb shell am force-stop org.myforeverpet.godot
   adb shell run-as org.myforeverpet.godot mkdir -p files
   adb shell run-as org.myforeverpet.godot touch files/kindria-diagnostics.enabled
   ```

   The marker requires a debuggable APK and assumes the Android Godot user-data directory is files/. If no diagnostics appear, verify the actual user-data directory and relaunch before recording.
4. Launch Kindria manually, enter a dungeon, then run the collector from the repository:

   ```sh
   python3 my-forever-pet/godot-arcade/collect_kindria_android.py --duration 600 --output kindria-android-evidence
   ```

   Play for the entire ten-minute capture. Include simultaneous casts, movement, status effects and each biome. Repeat on a cold launch and after prolonged play. Add APK provenance and note device refresh rate, resolution, power mode and thermal conditions.
5. Review report.json, raw logcat and before/after memory, display and thermal snapshots. The summary requires at least 18,000 measured combat intervals, 600 seconds of capture, zero intervals over 16,667 microseconds, zero reduced-quality windows and zero rejected windows for its preliminary gate. This is an intentionally strict observed-combat gate, not a claim of whole-session FPS or independent visual/thermal certification.
6. Disable diagnostics after collection and relaunch:

   ```sh
   adb shell am force-stop org.myforeverpet.godot
   adb shell run-as org.myforeverpet.godot rm -f files/kindria-diagnostics.enabled
   ```

The collector does not change game visuals or gameplay. Emulator detection is heuristic. A physical-device run and human review of thermal, memory and visual evidence remain mandatory. No device has been measured by this commit.
