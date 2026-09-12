# Street Football Pakistan — Unreal Engine 5.8

## Rebuild target
A new mobile-first 3D football game built from scratch in Unreal Engine 5.8. The old Godot prototype is not part of the gameplay architecture.

## First playable milestone
- 3D football pitch with Pakistan street-football visual identity
- Third-person/broadcast football camera
- One controllable player
- Virtual movement and action controls
- Ball possession, dribbling, pass and shot
- Opposing players and teammates with basic positioning AI
- Goalkeeper and goals
- Match timer and score HUD
- Restart/full-time flow
- Android ARM64 Shipping target

## Gameplay architecture
- `AStreetFootballGameMode`: match lifecycle and rules
- `AStreetFootballPlayerController`: mobile input and player selection
- `AStreetFootballCharacter`: locomotion, possession and football actions
- `AStreetFootballBall`: physical ball state and kick/pass impulses
- `AStreetFootballTeamAI`: team shape, support runs and defensive positioning
- `UStreetFootballMatchSubsystem`: score, clock, possession and match state
- `UStreetFootballMobileInput`: touch joystick/action abstraction
- UMG HUD/menu layer for score, clock, player indicator and controls

## Presentation target
Realistic but Android-conscious visuals inspired by modern football games: broadcast camera, readable player silhouettes, responsive animation, stadium/street atmosphere, crowd/audio ambience, strong pitch lighting and polished HUD.

## Build policy
The project must not be considered complete until an Unreal Engine Android Shipping APK is actually produced and its APK signature is verified. No Godot APK is an acceptable substitute.
