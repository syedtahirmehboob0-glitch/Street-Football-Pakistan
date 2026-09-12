# Unreal Engine Environment Readiness

Target: Unreal Engine 5.8 Android Shipping build.

## Required build environment
- Unreal Engine 5.8 installed and licensed on the build machine
- Windows runner with `UnrealEditor-Cmd.exe` and `RunUAT.bat`
- Android SDK / platform API 35
- Android Build Tools 35.0.1
- Android NDK r27c
- OpenJDK 21.0.3
- ADB on PATH
- apksigner on PATH
- `UE_ROOT`, `JAVA_HOME`, and `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) configured
- `NDKROOT` should point to the configured UE Android NDK where applicable

## Build output requirements
- Android ARM64
- Shipping configuration
- Cook + stage + pak + package
- APK signature verification before artifact upload
- SHA-256 hash recorded in CI logs

## Important
GitHub-hosted runners do not include Unreal Engine 5.8. The repository workflow therefore uses a self-hosted runner tagged `unreal-engine` and `android`. The final APK cannot be truthfully produced until a machine matching the requirements above is registered to this repository as that runner.
