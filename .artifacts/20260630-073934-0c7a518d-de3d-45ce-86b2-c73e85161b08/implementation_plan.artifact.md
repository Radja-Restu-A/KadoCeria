# Fix Audio Playback Acceleration and Distortion

The audio playback issue (playing faster and breaking up after ~5s) is likely caused by overlapping playback or resource contention between the narration player and the backsound player. Specifically, `playAudio` does not properly await the completion of `stop()` on the player, and multiple state changes might be triggering redundant playback.

## Proposed Changes

### [Audio Service](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/audio_service.dart)

Improve synchronization and state management in `AudioService`.

#### [audio_service.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/audio_service.dart)

- Ensure `playAudio` and `playAudioLoop` properly `await` the `stop()` or `pause()` of existing playback before starting new ones.
- Add a check to prevent re-starting the same audio file if it's already playing (idempotency).
- Use `ProcessingState` more effectively to prevent concurrent load operations on the same player.
- Add better cleanup in `dispose`.

### [Flipbook View Model](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/flipbook_viewmodel.dart)

Reduce redundant calls and improve navigation synchronization.

#### [flipbook_viewmodel.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/flipbook_viewmodel.dart)

- Ensure `playBacksoundAudio` is only called when the page actually changes or when explicitly needed.
- Improve `stopAudio` to be more comprehensive and ensure all players are reset.

---

## Verification Plan

### Automated Tests
- I will run `analyze_file` to ensure no syntax errors.

### Manual Verification
- I will review the logic for any potential race conditions where `play()` could be called before the previous `load()` or `stop()` has completed.
- I will verify that the backsound transition logic (stopping previous and starting new) is robust.
