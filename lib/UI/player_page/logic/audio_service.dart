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
    if (_isInitialized && !forceReinitialize) return;

    try {
      // iOS audio session setup
      if (Platform.isIOS) {
        try {
          await const MethodChannel('flutter_sequencer').invokeMethod('initializeAudioSession');
        } catch (e) {
          debugPrint('[AudioService] iOS audio session init failed: $e');
        }
      }

      GlobalState().setKeepEngineRunning(true);

      // Platform-specific scheduling
      if (Platform.isIOS) {
        GlobalState().setIosNativeSchedulingEnabled(false);
      }

      _sequence = Sequence(tempo: tempo, endBeat: endBeat);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AudioService] Initialization failed: $e');
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

    final isTestFlight = Platform.isIOS && kReleaseMode;

    if (!isTestFlight) {
      final tracks = await _sequence!.createTracks(instruments);
      if (tracks.isEmpty) {
        throw Exception('No tracks created - instrument loading failed');
      }
      return tracks;
    }

    return await _createTracksWithTestFlightFallback(instruments);
  }

  /// TestFlight-specific track creation with progressive fallback strategy
  Future<List<Track>> _createTracksWithTestFlightFallback(List<Instrument> instruments) async {
    // Strategy 1: Try original instruments
    try {
      final tracks = await _sequence!.createTracks(instruments);
      if (tracks.isNotEmpty) return tracks;
    } catch (e) {
      debugPrint('[AudioService] Strategy 1 failed: $e');
    }

    // Strategy 2: Try minimal SF2 fallback
    try {
      final minimalInstruments = [
        Sf2Instrument(
          path: 'assets/sounds/sf2/korg.sf2',
          isAsset: true,
          presetIndex: 0,
        ),
      ];
      final tracks = await _sequence!.createTracks(minimalInstruments);
      if (tracks.isNotEmpty) return tracks;
    } catch (e) {
      debugPrint('[AudioService] Strategy 2 failed: $e');
    }

    // Strategy 3: iOS AudioUnit fallback
    if (Platform.isIOS) {
      try {
        final audioUnitInstruments = [
          AudioUnitInstrument(
            manufacturerName: 'Apple',
            componentName: 'DLSMusicDevice',
          ),
        ];
        final tracks = await _sequence!.createTracks(audioUnitInstruments);
        if (tracks.isNotEmpty) return tracks;
      } catch (e) {
        debugPrint('[AudioService] Strategy 3 failed: $e');
      }
    }

    throw Exception('All fallback strategies failed - audio engine not available');
  }

  /// Safe disposal with iOS-specific handling and navigation safety checks
  Future<void> dispose() async {
    final audioStateManager = AudioStateManager();
    if (!audioStateManager.canSafelyDisposeAudio && Platform.isIOS) {
      audioStateManager.setDisposingAudio(true);
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
    try {
      if (_sequence != null) {
        _sequence!.stop();
        if (Platform.isIOS) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      debugPrint('[AudioService] Error stopping sequence: $e');
    }

    try {
      if (Platform.isIOS) {
        final audioStateManager = AudioStateManager();
        if (audioStateManager.canSafelyDisposeAudio) {
          GlobalState().setKeepEngineRunning(false);
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
  }
}
