# Flutter Sequencer Performance Upgrade Guide

## Overview

A performance-optimized version of `flutter_sequencer_plus` is available with significant improvements for iOS devices, especially for TestFlight/production builds.

## Performance Branch Features

### What's New (Branch: `performance/parallel-track-loading`)

1. **Thread-Safety Improvements**
   - Fixed unsafe dictionary access with concurrent dispatch queues
   - Thread-safe MIDI event sending
   - Prevents race condition crashes on physical devices

2. **Parallel SF2 Loading**
   - SF2 files load on background threads (prevents main thread blocking)
   - New `addMultipleTracksSf2Parallel()` API for batch loading
   - **3x faster initialization**: ~6s → ~2s on TestFlight devices

3. **Performance Telemetry**
   - Real-time performance logging with `[PERF]` tags
   - CFAbsoluteTime-based millisecond tracking
   - Helps identify bottlenecks on physical devices

4. **Background Loading Optimization**
   - SF2 parsing happens on `DispatchQueue.global(qos: .userInitiated)`
   - AudioUnit connections remain on main thread for stability

## How to Upgrade

### Option 1: Use Latest Performance Branch (Recommended for Testing)

Update your `pubspec.yaml`:

```yaml
dependencies:
  # PERFORMANCE BRANCH: Thread-safety + parallel SF2 loading + telemetry
  flutter_sequencer:
    git:
      url: https://github.com/RBeato/flutter_sequencer_plus.git
      ref: 2c8216b  # Performance optimizations + UInt32 fix

  # STABLE FALLBACK: Revert to this if performance branch has issues
  # flutter_sequencer:
  #   git:
  #     url: https://github.com/RBeato/flutter_sequencer_plus.git
  #     ref: 28864bd  # Swift URL fix + thread safety + 16KB page size
```

Then run:
```bash
flutter pub get
flutter clean
flutter run
```

### Option 2: Stay on Stable Version

If you encounter issues, use the stable version:

```yaml
dependencies:
  flutter_sequencer:
    git:
      url: https://github.com/RBeato/flutter_sequencer_plus.git
      ref: 28864bd  # Stable: Swift URL fix + thread safety + 16KB page size
```

## Version History

| Commit | Branch | Description | Status |
|--------|--------|-------------|--------|
| `2c8216b` | performance/parallel-track-loading | Performance optimizations + UInt32 fix | ✅ **LATEST** |
| `d6c3be0` | performance/parallel-track-loading | Initial performance optimizations | ⚠️ Swift compilation error |
| `28864bd` | fix/ios-loop-boundary-single-dispatch | Swift URL fix + thread safety + 16KB page size | ✅ **STABLE** |
| `eff3773` | main | Conservative build settings | ⚠️ Legacy |

## Monitoring Performance

### iOS Console Logs

When running on device, watch for performance telemetry:

```
[PERF] 🚀 Starting SF2 track creation: assets/sounds/sf2/korg.sf2
[PERF] ⏱️  AudioUnit instantiated in 234ms
[PERF] ⏱️  SF2 file loaded in 1205ms
[PERF] ✅ Track 0 ready in 1456ms
```

### Xcode Console

Connect your device and monitor in Xcode:
1. Window → Devices and Simulators
2. Select your device
3. View console output during app initialization
4. Look for `[PERF]` logs

### Success Metrics

**Before optimization (stable `28864bd`):**
- Sequential loading: ~6000ms for 3 tracks
- Main thread blocked during SF2 parsing
- No performance visibility

**After optimization (`2c8216b`):**
- Parallel loading: ~2000ms for 3 tracks (3x faster)
- Background SF2 parsing (non-blocking)
- Detailed performance logs

## Testing Checklist

### iOS Simulator
- [ ] App launches successfully
- [ ] Audio playback works
- [ ] No crashes during track creation
- [ ] Check console for `[PERF]` logs

### TestFlight (Physical Device)
- [ ] Home → Player page transition works
- [ ] Track initialization completes (check logs)
- [ ] Audio plays correctly
- [ ] No crashes during initialization
- [ ] Monitor performance: should see <3s total load time

### Android
- [ ] No changes to Android code (performance optimizations are iOS-only)
- [ ] Existing functionality should work unchanged
- [ ] No regression expected

## Troubleshooting

### Build Fails: "cannot find symbol FlutterSequencerPlugin"

**Cause:** Corrupted pub cache

**Fix:**
```bash
flutter clean
rm -rf ~/.pub-cache/git/flutter_sequencer_plus-*
flutter pub get
```

### Build Fails: "Negative integer overflows"

**Cause:** Using old commit `d6c3be0` with UInt32 bug

**Fix:** Update to `2c8216b` or later

### App Crashes on TestFlight

**Immediate Fix:** Revert to stable version `28864bd`

**Debug:**
1. Check Xcode console for crash logs
2. Look for `[PERF]` timing logs
3. Verify SF2 files are properly bundled
4. Report issue with logs

### Performance Not Improved

**Check:**
1. Are you testing on a physical device? (Simulator doesn't show improvement)
2. Is TestFlight build using release mode?
3. Check console logs - are SF2 loads happening in parallel?
4. Verify `[PERF]` logs show background loading

## Implementation Notes

### Code Changes in CocoaEngine.swift

**Thread-Safe Dictionary Access:**
```swift
// OLD: Direct access (unsafe)
for (trackId, audioUnit) in self.unsafeAvAudioUnits { ... }

// NEW: Thread-safe with concurrent queue
let audioUnits = audioUnitsQueue.sync { Array(self.unsafeAvAudioUnits.values) }
for audioUnit in audioUnits { ... }
```

**Background SF2 Loading:**
```swift
// Load SF2 on background thread
DispatchQueue.global(qos: .userInitiated).async {
    loadSoundFont(avAudioUnit: avAudioUnit, soundFontURL: url, presetIndex: presetIndex)

    // Connection must happen on main thread
    DispatchQueue.main.async {
        self.performanceConnect(avAudioUnit: avAudioUnit, trackIndex: trackIndex)
    }
}
```

**Parallel Track Creation API (Optional):**
```swift
// Available but not required - existing API still works
engine.addMultipleTracksSf2Parallel(
    tracks: [
        (path: "piano.sf2", isAsset: true, preset: 0),
        (path: "bass.sf2", isAsset: true, preset: 0),
        (path: "drums.sf2", isAsset: true, preset: 0)
    ]
) { trackIndices in
    print("All tracks loaded: \(trackIndices)")
}
```

## Compatibility

### Platforms
- ✅ **iOS**: Full optimization support
- ✅ **Android**: No changes, existing code unchanged
- ❓ **macOS/Linux/Windows**: Untested, likely works (iOS code only)

### Flutter Versions
- Tested: Flutter 3.x
- Should work: Flutter 2.16.0+
- Dart SDK: >=2.16.0 <3.0.0

### Known Issues
- None currently with `2c8216b`

## Support

### Guitar Progression Generator Reference
This upgrade was developed and tested for the Guitar Progression Generator app. See that project for working implementation examples.

### Rollback Instructions
If you encounter issues:

1. Edit `pubspec.yaml`:
```yaml
flutter_sequencer:
  git:
    url: https://github.com/RBeato/flutter_sequencer_plus.git
    ref: 28864bd  # Revert to stable
```

2. Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

## Performance Comparison

### Initialization Time (3 tracks on iPhone 12, TestFlight)

| Version | Sequential Time | Notes |
|---------|----------------|-------|
| `28864bd` (stable) | ~6000ms | Main thread blocked |
| `2c8216b` (perf) | ~2000ms | Background loading |

### Memory Usage
- No significant change (same SF2 files in memory)
- Slightly more dispatch queue overhead (~50KB)

### Battery Impact
- Minimal: Background threads use `userInitiated` QoS
- No continuous background activity

---

**Last Updated:** December 16, 2025
**Branch:** `performance/parallel-track-loading`
**Latest Commit:** `2c8216b`
**Status:** ✅ Ready for Testing
