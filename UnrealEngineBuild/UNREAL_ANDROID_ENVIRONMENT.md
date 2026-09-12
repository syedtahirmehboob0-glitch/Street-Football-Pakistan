# Unreal Engine 5.8 Android Build Environment

This branch is Unreal Engine only. Godot CI is intentionally removed.

## Required host

A self-hosted Windows runner is required for the current build pipeline. It must have:

- Unreal Engine 5.8 installed
- `UE_ROOT` set to the UE 5.8 installation directory
- Visual Studio 2022 with C++ desktop/game development components
- Android Studio Koala 2024.1.2 Patch 1
- Android SDK 35 (SDK 34 minimum for compilation)
- Android Build Tools 35.0.1
- Android NDK r27c
- OpenJDK 21.0.3
- `adb` and `apksigner` available on PATH

Epic's UE 5.8 Android documentation lists these toolchain versions and recommends Turnkey for installing the Android SDK/NDK/JDK. See the project documentation links in the repository README.

## Runner labels

The runner must expose these labels:

- `self-hosted`
- `unreal-engine`
- `android`

## Environment variables

Required:

```text
UE_ROOT=C:\Program Files\Epic Games\UE_5.8
```

The exact `UE_ROOT` path may differ by installation.

## Verification

Before an APK build, the CI workflow verifies:

1. UnrealEditor-Cmd.exe exists and reports UE 5.8.
2. RunUAT.bat exists.
3. Android SDK/NDK/JDK environment is available.
4. `adb` is available.
5. `apksigner` is available.
6. The Unreal project targets Android ARM64.
7. The final APK exists and passes `apksigner verify`.

## Build stages

- Unreal project generation
- C++ compilation
- Asset cooking
- Android staging
- Shipping APK packaging
- APK signature verification
- GitHub Actions artifact upload

No Godot build is part of the Unreal pipeline.
