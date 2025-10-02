import 'package:flutter/foundation.dart';

/// Manages global audio state to prevent crashes during navigation
class AudioStateManager {
  static final AudioStateManager _instance = AudioStateManager._internal();
  factory AudioStateManager() => _instance;
  AudioStateManager._internal();

  bool _isNavigatingFromPaywall = false;
  bool _isDisposingAudio = false;

  /// Indicates if we're currently navigating away from paywall
  bool get isNavigatingFromPaywall => _isNavigatingFromPaywall;

  /// Indicates if audio is currently being disposed
  bool get isDisposingAudio => _isDisposingAudio;

  /// Call this when starting navigation from paywall
  void setPaywallNavigation(bool value) {
    debugPrint('[AudioStateManager] Setting paywall navigation: $value');
    _isNavigatingFromPaywall = value;
  }

  /// Call this when starting audio disposal
  void setDisposingAudio(bool value) {
    debugPrint('[AudioStateManager] Setting audio disposal: $value');
    _isDisposingAudio = value;
  }

  /// Check if it's safe to dispose audio resources
  bool get canSafelyDisposeAudio {
    final canDispose = !_isNavigatingFromPaywall;
    debugPrint('[AudioStateManager] Can safely dispose audio: $canDispose');
    return canDispose;
  }

  /// Reset all flags
  void reset() {
    debugPrint('[AudioStateManager] Resetting all flags');
    _isNavigatingFromPaywall = false;
    _isDisposingAudio = false;
  }
}