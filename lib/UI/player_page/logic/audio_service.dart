import 'package:flutter/foundation.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import '../../../utils/audio_state_manager.dart';

/// Simplified AudioService based on working flutter_sequencer_plus example
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  Sequence? _sequence;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Sequence? get sequence => _sequence;

  /// Simple initialization based on working examples
  Future<void> initialize({
    required double tempo,
    required double endBeat,
    bool forceReinitialize = false,
  }) async {
    debugPrint('[AudioService] Initialize: tempo=$tempo, endBeat=$endBeat');

    if (_isInitialized && !forceReinitialize) {
      debugPrint('[AudioService] Already initialized');
      return;
    }

    try {
      // STEP 1: Initialize audio session for iOS (from working example)
      if (Platform.isIOS) {
        try {
          debugPrint('[AudioService] Initializing iOS audio session');
          await const MethodChannel('flutter_sequencer').invokeMethod('initializeAudioSession');
          debugPrint('[AudioService] iOS audio session initialized');
        } catch (e) {
          debugPrint('[AudioService] iOS audio session init failed: $e');
        }
      }

      // STEP 2: Keep engine running (from working examples)
      GlobalState().setKeepEngineRunning(true);

      // STEP 3: Platform-specific scheduling setup (from flutter_sequencer_plus example)
      if (Platform.isIOS) {
        // iOS: Use Dart scheduling (like working example)
        GlobalState().setIosNativeSchedulingEnabled(false);
        debugPrint('[AudioService] iOS: Dart scheduling enabled');
      } else {
        // Android: Use native scheduling (default)
        debugPrint('[AudioService] Android: Native scheduling enabled');
      }

      // STEP 4: Create sequence (simple like working examples)
      _sequence = Sequence(tempo: tempo, endBeat: endBeat);
      debugPrint('[AudioService] Sequence created successfully');

      _isInitialized = true;
      debugPrint('[AudioService] Initialization completed successfully');

    } catch (e, stackTrace) {
      debugPrint('[AudioService] Initialization failed: $e');
      debugPrint('[AudioService] Stack trace: $stackTrace');
      _isInitialized = false;
      _sequence = null;
      rethrow;
    }
  }

  /// Create tracks with TestFlight-compatible fallback strategy
  Future<List<Track>> createTracks(List<Instrument> instruments) async {
    if (!_isInitialized || _sequence == null) {
      throw Exception('AudioService not initialized');
    }

    debugPrint('[AudioService] Creating ${instruments.length} tracks');

    // Check if we're in TestFlight/Release mode for enhanced error handling
    final isTestFlight = Platform.isIOS && kReleaseMode;

    if (!isTestFlight) {
      // Development/Debug mode - use simple approach
      try {
        final tracks = await _sequence!.createTracks(instruments);
        if (tracks.isEmpty) {
          throw Exception('No tracks created - instrument loading failed');
        }
        debugPrint('[AudioService] Created ${tracks.length} tracks successfully');
        return tracks;
      } catch (e, stackTrace) {
        debugPrint('[AudioService] Track creation failed: $e');
        debugPrint('[AudioService] Stack trace: $stackTrace');
        rethrow;
      }
    }

    // TestFlight/Release mode - use progressive fallback strategy
    return await _createTracksWithTestFlightFallback(instruments);
  }

  /// TestFlight-specific track creation with progressive fallback strategy
  Future<List<Track>> _createTracksWithTestFlightFallback(List<Instrument> instruments) async {
    debugPrint('[AudioService] 🚀 TESTFLIGHT MODE: Using progressive fallback strategy');

    // Strategy 1: Try original instruments
    try {
      final tracks = await _sequence!.createTracks(instruments);
      if (tracks.isNotEmpty) {
        debugPrint('[AudioService] ✅ Strategy 1 SUCCESS: Original instruments loaded');
        return tracks;
      }
    } catch (e) {
      debugPrint('[AudioService] ❌ Strategy 1 FAILED: $e');
    }

    // Strategy 2: Try minimal SF2 fallback
    debugPrint('[AudioService] Strategy 2: Minimal SF2 fallback');
    try {
      final minimalInstruments = [
        Sf2Instrument(
          path: 'assets/sounds/sf2/korg.sf2',
          isAsset: true,
          presetIndex: 0,
        ),
      ];
      final tracks = await _sequence!.createTracks(minimalInstruments);
      if (tracks.isNotEmpty) {
        debugPrint('[AudioService] ✅ Strategy 2 SUCCESS: Minimal SF2 loaded');
        return tracks;
      }
    } catch (e) {
      debugPrint('[AudioService] ❌ Strategy 2 FAILED: $e');
    }

    // Strategy 3: iOS AudioUnit fallback
    if (Platform.isIOS) {
      debugPrint('[AudioService] Strategy 3: iOS AudioUnit fallback');
      try {
        final audioUnitInstruments = [
          AudioUnitInstrument(
            manufacturerName: 'Apple',
            componentName: 'DLSMusicDevice',
          ),
        ];
        final tracks = await _sequence!.createTracks(audioUnitInstruments);
        if (tracks.isNotEmpty) {
          debugPrint('[AudioService] ✅ Strategy 3 SUCCESS: iOS AudioUnit loaded');
          return tracks;
        }
      } catch (e) {
        debugPrint('[AudioService] ❌ Strategy 3 FAILED: $e');
      }
    }

    debugPrint('[AudioService] 💥 ALL STRATEGIES FAILED - No audio tracks created');
    throw Exception('All fallback strategies failed - audio engine not available');
  }

  /// Safe disposal with iOS-specific handling and navigation safety checks
  Future<void> dispose() async {
    debugPrint('[AudioService] Disposing...');

    // Check if we're in a navigation state that could cause crashes
    final audioStateManager = AudioStateManager();
    if (!audioStateManager.canSafelyDisposeAudio && Platform.isIOS) {
      debugPrint('[AudioService] iOS: Unsafe to dispose audio during paywall navigation - deferring');
      audioStateManager.setDisposingAudio(true);

      // Defer disposal until navigation is complete
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!audioStateManager.isNavigatingFromPaywall) {
          _performActualDisposal();
        }
      });
      return;
    }

    await _performActualDisposal();
  }

  Future<void> _performActualDisposal() async {
    debugPrint('[AudioService] Performing actual disposal...');

    try {
      if (_sequence != null) {
        debugPrint('[AudioService] Stopping sequence...');
        _sequence!.stop();

        // iOS-specific: Give audio engine time to cleanup SoundFont resources
        if (Platform.isIOS) {
          debugPrint('[AudioService] iOS: Waiting for audio cleanup...');
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      debugPrint('[AudioService] Error stopping sequence: $e');
    }

    try {
      debugPrint('[AudioService] Releasing engine...');

      // iOS-specific: More graceful engine release
      if (Platform.isIOS) {
        // Only release engine if we're not in a critical navigation state
        final audioStateManager = AudioStateManager();
        if (audioStateManager.canSafelyDisposeAudio) {
          GlobalState().setKeepEngineRunning(false);
          debugPrint('[AudioService] iOS: Engine released safely');
        } else {
          debugPrint('[AudioService] iOS: Keeping engine running during navigation');
        }
      } else {
        GlobalState().setKeepEngineRunning(false);
      }
    } catch (e) {
      debugPrint('[AudioService] Error releasing engine: $e');
    }

    _sequence = null;
    _isInitialized = false;
    AudioStateManager().setDisposingAudio(false);

    debugPrint('[AudioService] Disposal completed');
  }
}