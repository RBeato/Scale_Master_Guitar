import 'package:flutter/foundation.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'dart:async';
import 'dart:io';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  Sequence? _sequence;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDisposing = false;
  final List<Function> _onInitializedCallbacks = [];
  
  // Lifecycle management
  static AudioService? _previousInstance;
  DateTime? _lastDisposalTime;
  
  // Configuration - conservative values based on working iOS apps
  static const int maxRetries = 3; // Back to 3 - too many retries can cause issues
  static const Duration retryDelay = Duration(seconds: 2); // Conservative retry delay
  static const Duration initTimeout = Duration(seconds: 45); // Reasonable timeout
  static const Duration trackCreationTimeout = Duration(seconds: 30); // Conservative track timeout
  
  bool get isInitialized => _isInitialized;
  Sequence? get sequence => _sequence;
  
  /// Initialize the audio engine with proper lifecycle management
  Future<void> initialize({
    required double tempo,
    required double endBeat,
    bool forceReinitialize = false,
  }) async {
    debugPrint('[AudioService] Initialize called - tempo: $tempo, endBeat: $endBeat, forceReinitialize: $forceReinitialize');
    
    // For iOS TestFlight, add a pre-initialization delay to ensure system readiness
    if (Platform.isIOS && !kDebugMode) {
      debugPrint('[AudioService] iOS release mode detected - adding pre-initialization delay');
      await Future.delayed(const Duration(seconds: 3));
    }
    
    if (_isInitialized && !forceReinitialize) {
      debugPrint('[AudioService] Already initialized');
      return;
    }
    
    if (_isInitializing) {
      debugPrint('[AudioService] Initialization already in progress');
      // Wait for existing initialization
      final completer = Completer<void>();
      _onInitializedCallbacks.add(() => completer.complete());
      return completer.future;
    }
    
    // Check if a previous instance needs cleanup
    if (_previousInstance != null) {
      debugPrint('[AudioService] Disposing previous instance before initialization');
      await _previousInstance!._forceDispose();
      await Future.delayed(const Duration(milliseconds: 300)); // Allow audio cleanup
      _previousInstance = null;
    }
    
    // Ensure sufficient time has passed since last disposal
    if (_lastDisposalTime != null) {
      final timeSinceDisposal = DateTime.now().difference(_lastDisposalTime!);
      if (timeSinceDisposal < const Duration(milliseconds: 500)) {
        final remainingDelay = const Duration(milliseconds: 500) - timeSinceDisposal;
        debugPrint('[AudioService] Waiting ${remainingDelay.inMilliseconds}ms for audio resource cleanup');
        await Future.delayed(remainingDelay);
      }
    }
    
    _isInitializing = true;
    debugPrint('[AudioService] Starting initialization with tempo: $tempo, endBeat: $endBeat');
    
    try {
      // Set up audio engine
      await _setupAudioEngine();
      
      // Create sequence with retry logic
      _sequence = await _createSequenceWithRetry(tempo, endBeat);
      
      _isInitialized = true;
      debugPrint('[AudioService] Initialization successful');
      
      // Notify all waiting callbacks
      for (final callback in _onInitializedCallbacks) {
        callback();
      }
      _onInitializedCallbacks.clear();
      
    } catch (e, stackTrace) {
      debugPrint('[AudioService] Initialization failed: $e');
      debugPrint('[AudioService] Stack trace: $stackTrace');
      _isInitialized = false;
      _sequence = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Set up the audio engine with platform-specific configurations
  Future<void> _setupAudioEngine() async {
    try {
      debugPrint('[AudioService] Setting up audio engine');
      
      // Platform-specific setup
      if (Platform.isIOS) {
        debugPrint('[AudioService] iOS platform detected - using conservative approach');
        
        // Conservative iOS setup - similar to working Scale Master app
        final isPhysicalDevice = !kDebugMode;
        
        // Step 1: Basic engine setup
        GlobalState().setKeepEngineRunning(true);
        debugPrint('[AudioService] Audio engine configured for iOS');
        
        // Step 2: Conservative delay for iOS physical devices
        if (isPhysicalDevice) {
          debugPrint('[AudioService] iOS physical device - using 3s delay');
          await Future.delayed(const Duration(seconds: 3));
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Step 3: Skip warmup for iOS - it often causes issues
        // Many working iOS apps skip the warmup sequence
        debugPrint('[AudioService] Skipping warmup sequence for iOS stability');
        
      } else {
        // Non-iOS platform - standard setup
        GlobalState().setKeepEngineRunning(true);
        debugPrint('[AudioService] Non-iOS platform - standard initialization');
      }
      
      debugPrint('[AudioService] Audio engine setup completed');
      
    } catch (e) {
      debugPrint('[AudioService] Error setting up audio engine: $e');
      throw Exception('Failed to setup audio engine: $e');
    }
  }
  
  /// Create sequence with retry logic
  Future<Sequence> _createSequenceWithRetry(double tempo, double endBeat) async {
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('[AudioService] Creating sequence (attempt $attempt/$maxRetries)');
        
        final sequence = Sequence(tempo: tempo, endBeat: endBeat);
        
        // Test the sequence is working by trying to get its tempo
        final testTempo = sequence.getTempo();
        debugPrint('[AudioService] Sequence created successfully, test tempo: $testTempo');
        
        return sequence;
      } catch (e, stackTrace) {
        lastError = Exception('Attempt $attempt failed: $e');
        debugPrint('[AudioService] Sequence creation failed (attempt $attempt): $e');
        
        if (attempt < maxRetries) {
          debugPrint('[AudioService] Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        }
      }
    }
    
    throw lastError ?? Exception('Failed to create sequence after $maxRetries attempts');
  }
  
  /// Create tracks with instruments
  Future<List<Track>> createTracks(List<Instrument> instruments) async {
    if (!_isInitialized || _sequence == null) {
      throw Exception('AudioService not initialized');
    }
    
    debugPrint('[AudioService] Creating ${instruments.length} tracks');
    
    // For iOS physical devices, add extra delay before track creation
    if (Platform.isIOS && !kDebugMode) {
      debugPrint('[AudioService] iOS physical device detected - adding pre-creation delay');
      await Future.delayed(const Duration(seconds: 2));
    }
    
    try {
      // Create tracks with timeout and retry logic
      final tracks = await _createTracksWithRetry(instruments);
      
      // Initialize track volumes
      for (var track in tracks) {
        track.changeVolumeNow(volume: 0.75);
      }
      
      debugPrint('[AudioService] Successfully created ${tracks.length} tracks');
      return tracks;
      
    } catch (e, stackTrace) {
      debugPrint('[AudioService] Error creating tracks: $e');
      debugPrint('[AudioService] Stack trace: $stackTrace');
      throw Exception('Failed to create tracks: $e');
    }
  }
  
  /// Create tracks with retry logic - simplified for iOS reliability
  Future<List<Track>> _createTracksWithRetry(List<Instrument> instruments) async {
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('[AudioService] Creating tracks (attempt $attempt/$maxRetries)');
        
        // Conservative approach - always create all tracks at once
        final tracks = await _sequence!.createTracks(instruments).timeout(
          trackCreationTimeout,
          onTimeout: () {
            throw TimeoutException('Track creation timed out after ${trackCreationTimeout.inSeconds} seconds');
          },
        );
        
        // Verify tracks were created successfully
        if (tracks.isEmpty) {
          // Add specific TestFlight error context
          final isTestFlight = Platform.isIOS && kReleaseMode;
          if (isTestFlight) {
            debugPrint('[AudioService] 🚨 TESTFLIGHT ERROR: No tracks created - SF2 loading failed');
            debugPrint('[AudioService] 🚨 This should have been prevented by SFZ fallback');
            throw Exception('No tracks were created - SF2 loading failed in TestFlight environment');
          } else {
            throw Exception('No tracks were created - instrument loading failed');
          }
        }
        
        if (tracks.length != instruments.length) {
          throw Exception('Expected ${instruments.length} tracks, got ${tracks.length}');
        }
        
        // Skip volume testing - it can sometimes fail even when tracks work
        debugPrint('[AudioService] Created ${tracks.length} tracks successfully');
        
        return tracks;
        
      } on TimeoutException catch (e) {
        lastError = Exception('Attempt $attempt timed out: $e');
        debugPrint('[AudioService] Track creation timeout (attempt $attempt): $e');
        
        // For timeout errors, recreate the sequence with proper cleanup
        if (attempt < maxRetries) {
          debugPrint('[AudioService] Recreating sequence before retry...');
          try {
            // Properly dispose of corrupted sequence
            if (_sequence != null) {
              try {
                _sequence!.stop();
                await Future.delayed(const Duration(milliseconds: 100));
              } catch (e) {
                debugPrint('[AudioService] Error stopping corrupted sequence: $e');
              }
            }
            
            // Brief engine reset
            GlobalState().setKeepEngineRunning(false);
            await Future.delayed(const Duration(milliseconds: 200));
            GlobalState().setKeepEngineRunning(true);
            await Future.delayed(const Duration(milliseconds: 300));
            
            const tempo = 120.0; // Use safe default
            const endBeat = 16.0; // Default endBeat, adjust as needed
            
            // iOS-specific audio session reset
            if (Platform.isIOS) {
              debugPrint('[AudioService] Performing iOS-specific audio session reset');
              try {
                // Force a brief audio session interruption to reset the audio engine
                // TestFlight needs longer delays
                await Future.delayed(const Duration(milliseconds: 500));
                GlobalState().setKeepEngineRunning(false);
                await Future.delayed(const Duration(milliseconds: 1000));
                GlobalState().setKeepEngineRunning(true);
                await Future.delayed(const Duration(milliseconds: 1500));
              } catch (e) {
                debugPrint('[AudioService] iOS audio session reset failed: $e');
              }
            }
            
            _sequence = Sequence(tempo: tempo, endBeat: endBeat);
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            debugPrint('[AudioService] Error recreating sequence: $e');
          }
        }
      } catch (e) {
        lastError = Exception('Attempt $attempt failed: $e');
        debugPrint('[AudioService] Track creation failed (attempt $attempt): $e');
      }
      
      if (attempt < maxRetries) {
        debugPrint('[AudioService] Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    
    throw lastError ?? Exception('Failed to create tracks after $maxRetries attempts');
  }
  
  /// Clean up resources with proper order and delays
  Future<void> dispose() async {
    if (_isDisposing) {
      debugPrint('[AudioService] Already disposing');
      return;
    }
    
    _isDisposing = true;
    debugPrint('[AudioService] Starting disposal process');
    
    await _forceDispose();
    
    _lastDisposalTime = DateTime.now();
    _isDisposing = false;
  }
  
  /// Force disposal for cleanup (internal use)
  Future<void> _forceDispose() async {
    try {
      // Step 1: Stop sequence
      if (_sequence != null) {
        debugPrint('[AudioService] Stopping sequence');
        _sequence!.stop();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow sequence stop
      }
    } catch (e) {
      debugPrint('[AudioService] Error stopping sequence: $e');
    }
    
    try {
      // Step 2: Release audio engine
      debugPrint('[AudioService] Releasing audio engine');
      GlobalState().setKeepEngineRunning(false);
      await Future.delayed(const Duration(milliseconds: 100)); // Allow engine release
    } catch (e) {
      debugPrint('[AudioService] Error releasing audio engine: $e');
    }
    
    // Step 3: Clear state
    _sequence = null;
    _isInitialized = false;
    _isInitializing = false;
    _onInitializedCallbacks.clear();
    
    debugPrint('[AudioService] Disposal completed');
  }
  
  /// Reset the audio service (useful for error recovery)
  Future<void> reset() async {
    debugPrint('[AudioService] Resetting audio service');
    
    // Store current instance as previous for proper cleanup
    _previousInstance = AudioService._instance;
    
    await dispose();
    await Future.delayed(const Duration(milliseconds: 500)); // Extended delay for reset
  }
  
  /// Create a new instance with proper cleanup of previous one
  static Future<AudioService> createNewInstance() async {
    final currentInstance = AudioService._instance;
    
    if (currentInstance._isInitialized || currentInstance._isInitializing) {
      debugPrint('[AudioService] Creating new instance, disposing current one');
      _previousInstance = currentInstance;
      await currentInstance.dispose();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    return AudioService();
  }
}