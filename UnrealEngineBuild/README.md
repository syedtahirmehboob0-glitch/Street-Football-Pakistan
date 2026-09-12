# Street Football Pakistan — Unreal Engine 5 Build

This folder is the new Unreal Engine 5 rebuild. The existing Godot project remains at the repository root as the old prototype/reference.

## Target
- Unreal Engine 5.8
- Android ARM64
- Target SDK 35
- Mobile/Scalable rendering
- 3D football presentation
- eFootball-style broadcast camera
- Touch joystick and action controls
- 3v3 match, player switching, passing, shooting, sprint, tackle
- Teammate, opponent and goalkeeper AI
- Pakistan street-football presentation

## Build requirement
A real Unreal Android build requires a machine/runner with Unreal Engine and the Android SDK/NDK/JDK toolchain installed. GitHub's normal hosted runners do not provide a licensed Unreal Engine installation. The CI workflow therefore targets a self-hosted runner labelled `unreal-engine` rather than pretending that a standard GitHub runner can produce an Unreal APK.

## Release validation
The final release gate must verify:
1. Unreal project generation succeeds.
2. Android Shipping build succeeds.
3. APK is ARM64 and targets Android API 35.
4. APK is cryptographically signed.
5. APK passes `apksigner verify`.
6. APK installs with `adb install` on a clean Android device/emulator.
7. Game launches into the match and the core controls work.

No APK is considered final until all seven checks pass.
