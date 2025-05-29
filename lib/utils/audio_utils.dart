import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _lock = Lock();
  final _volumeSubject = BehaviorSubject.seeded(1.0);
  bool _isInitialized = false;
  
  Stream<double> get volumeStream => _volumeSubject.stream;
  double get currentVolume => _volumeSubject.value;
  bool get isInitialized => _isInitialized;
  
  factory AudioPlayerManager() {
    return _instance;
  }
  
  AudioPlayerManager._internal() {
    _init();
  }
  
  Future<void> _init() async {
    try {
      // Configure audio session
      final session = await AudioSession.instance;
      final configuration = AudioSessionConfiguration.music();
      await session.configure(configuration);
      await session.setActive(true);
      
      // For iOS specifically, ensure audio session is properly configured
      if (Platform.isIOS) {
        try {
          // iOS-specific configuration to ensure audio works properly in TestFlight
          await session.configure(const AudioSessionConfiguration.music()
            .copyWith(
              androidAudioAttributes: const AndroidAudioAttributes(
                contentType: AndroidAudioContentType.music,
                usage: AndroidAudioUsage.media,
              ),
              androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
              androidWillPauseWhenDucked: true,
            )
          );
          
          // Double-check that the session is active
          await session.setActive(true);
        } catch (e) {
          debugPrint('iOS specific audio session setup error: $e');
        }
      }
      
      // Handle audio becoming noisy (e.g., headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _audioPlayer.pause();
      });
      
      // Handle audio interruptions
      session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            await _audioPlayer.setVolume(0.1);
          } else {
            await _audioPlayer.pause();
          }
        } else {
          if (event.type == AudioInterruptionType.duck) {
            await _audioPlayer.setVolume(_volumeSubject.value);
          } else {
            // Try to resume playback if possible
            try {
              await session.setActive(true);
              if (_audioPlayer.playing) {
                await _audioPlayer.play();
              }
            } catch (e) {
              debugPrint('Failed to resume after interruption: $e');
            }
          }
        }
      });
      
      // Handle audio device changes
      session.devicesChangedEventStream.listen((_) {
        // Reinitialize audio player if needed
        _reinitializePlayer();
      });
      
      // Handle player errors
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('Audioplayer error: $e');
          _reinitializePlayer();
        },
      );
      
      _isInitialized = true;
      debugPrint('AudioPlayerManager initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }
  
  Future<void> _reinitializePlayer() async {
    await _lock.synchronized(() async {
      try {
        final wasPlaying = _audioPlayer.playing;
        final position = _audioPlayer.position;
        final currentIndex = _audioPlayer.currentIndex;
        
        await _audioPlayer.stop();
        await _audioPlayer.dispose();
        
        // Wait a bit to allow resources to be released
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Create a new instance
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse('https://example.com/empty.mp3')));
        
        // Try to restore state if possible
        if (wasPlaying && currentIndex != null) {
          try {
            // We can't restore the exact source, but we'll log it
            debugPrint('Audio state was playing at position: $position');
          } catch (e) {
            debugPrint('Failed to log audio state: $e');
          }
        }
      } catch (e) {
        debugPrint('Error reinitializing audio player: $e');
      }
    });
  }
  
  Future<void> playSound(String assetPath) async {
    try {
      // Make sure audio session is active
      final session = await AudioSession.instance;
      await session.setActive(true);
      
      await _lock.synchronized(() async {
        await _audioPlayer.stop();
        debugPrint('Playing asset: $assetPath');
        await _audioPlayer.setAsset(assetPath);
        
        // Set the volume before playing
        await _audioPlayer.setVolume(_volumeSubject.value);
        
        // Play the audio
        await _audioPlayer.play();
        debugPrint('Started playing asset');
      });
    } catch (e) {
      debugPrint('Error playing sound: $e');
      // Try to recover but avoid infinite recursion by not calling playSound again
      await _reinitializePlayer();
    }
  }
  
  Future<void> playUrl(String url) async {
    try {
      // Make sure audio session is active
      final session = await AudioSession.instance;
      await session.setActive(true);
      
      await _lock.synchronized(() async {
        await _audioPlayer.stop();
        debugPrint('Playing URL: $url');
        await _audioPlayer.setUrl(url);
        
        // Set the volume before playing
        await _audioPlayer.setVolume(_volumeSubject.value);
        
        // Play the audio
        await _audioPlayer.play();
        debugPrint('Started playing URL');
      });
    } catch (e) {
      debugPrint('Error playing URL: $e');
      await _reinitializePlayer();
    }
  }
  
  Future<void> stop() async {
    try {
      await _lock.synchronized(() async {
        debugPrint('Stopping audio player');
        await _audioPlayer.stop();
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      await _reinitializePlayer();
    }
  }
  
  Future<void> setVolume(double volume) async {
    try {
      await _lock.synchronized(() async {
        debugPrint('Setting volume to: $volume');
        await _audioPlayer.setVolume(volume);
        _volumeSubject.add(volume);
      });
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }
  
  Future<void> dispose() async {
    await _lock.synchronized(() async {
      debugPrint('Disposing audio player manager');
      await _audioPlayer.dispose();
      await _volumeSubject.close();
      _isInitialized = false;
    });
  }
}

// Global instance for easy access
final audioPlayerManager = AudioPlayerManager();
