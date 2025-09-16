import 'package:flutter/foundation.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

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

  /// Create tracks (simplified from working examples)
  Future<List<Track>> createTracks(List<Instrument> instruments) async {
    if (!_isInitialized || _sequence == null) {
      throw Exception('AudioService not initialized');
    }

    debugPrint('[AudioService] Creating ${instruments.length} tracks');

    try {
      // Simple track creation like working examples
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

  /// Simple disposal
  Future<void> dispose() async {
    debugPrint('[AudioService] Disposing...');

    try {
      if (_sequence != null) {
        _sequence!.stop();
      }
    } catch (e) {
      debugPrint('[AudioService] Error stopping sequence: $e');
    }

    try {
      GlobalState().setKeepEngineRunning(false);
    } catch (e) {
      debugPrint('[AudioService] Error releasing engine: $e');
    }

    _sequence = null;
    _isInitialized = false;

    debugPrint('[AudioService] Disposal completed');
  }
}