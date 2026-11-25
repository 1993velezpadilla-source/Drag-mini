# My Forever Pet — Paradise interoperability prototype
Android native port of the GPL-3.0 Capybara emulator, not an independently implemented pet simulator. The original game is proprietary and is not supplied. Import a legally obtained 16 MiB dump and its device key; neither is committed. This is a development prototype, not an official Bandai product or a commercially cleared clone.
 
Pinned upstream: https://github.com/infinition/capybara/tree/e80354eccba2124fdbfcf37d323a39a2104f3832
The build fetches the complete upstream repository and copies the unmodified emulator module and touches module, with license. Native Android bridge is GPL-3.0-only. Firmware mechanics, sprites, clock and flash saves come from the original firmware, not synthetic substitutes. The desktop UI, sound output, serial bridge, recovery-point UI and key search are not yet ported. The Android wallpaper shows the full original LCD frame (not isolated pet sprites), and a tap sends B if the launcher delivers it. Hidden wallpaper stops rendering and saves the clock; upstream save restoration advances elapsed wall time. Timing fidelity and lifecycle behavior require physical-phone validation.
 
Reference tools only (not linked into the APK): GMMan/tama-para-research, mameise/Paramix-Studio (GPL-3.0), x43x61x69/ParaLab (license not verified). No code from repositories with unverified licenses is redistributed.
 
## Build
Run bash prepare-upstream.sh, then install cargo-ndk, Android SDK 35 and NDK 27.2.12479018. In native run cargo ndk -t arm64-v8a -o ../app/src/main/jniLibs build --release. From this directory run gradle :app:assembleDebug with Gradle 8.9 and Java 17. CI does the same. No ROM is needed to compile; gameplay validation requires a user-owned dump. APK is debug-signed, not a release.
