import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Provider for the SequencerStateManager singleton
final sequencerStateManagerProvider = Provider((ref) => SequencerStateManager());

/// Enum to represent the current state of the sequencer
enum SequencerState {
  uninitialized,
  initializing,
  ready,
  playing,
  paused,
  stopping,
  disposing,
  error,
}

/// A centralized state manager for flutter_sequencer operations
/// This ensures proper lifecycle management and prevents race conditions
class SequencerStateManager extends ChangeNotifier {
  static final SequencerStateManager _instance = SequencerStateManager._internal();
  
  factory SequencerStateManager() => _instance;
  
  SequencerStateManager._internal();
  
  // State tracking
  SequencerState _state = SequencerState.uninitialized;
  SequencerState get state => _state;
  
  // Error tracking
  String? _lastError;
  String? get lastError => _lastError;
  
  // Operation locks to prevent concurrent operations
  final _operationCompleter = <String, Completer<void>>{};
  
  // State transition history for debugging
  final List<_StateTransition> _stateHistory = [];
  static const int _maxHistorySize = 20;
  
  /// Update the sequencer state with validation
  Future<void> updateState(SequencerState newState, {String? error}) async {
    if (_state == newState) {
      debugPrint('[SequencerStateManager] State already $newState, skipping update');
      return;
    }
    
    // Validate state transition
    if (!_isValidTransition(_state, newState)) {
      debugPrint('[SequencerStateManager] Invalid transition from $_state to $newState');
      return;
    }
    
    final previousState = _state;
    _state = newState;
    _lastError = error;
    
    // Record state transition
    _recordTransition(previousState, newState, error);
    
    debugPrint('[SequencerStateManager] State changed: $previousState → $newState${error != null ? ' (error: $error)' : ''}');
    
    notifyListeners();
  }
  
  /// Check if a state transition is valid
  bool _isValidTransition(SequencerState from, SequencerState to) {
    // Define valid state transitions
    final validTransitions = <SequencerState, Set<SequencerState>>{
      SequencerState.uninitialized: {
        SequencerState.initializing,
        SequencerState.disposing,
      },
      SequencerState.initializing: {
        SequencerState.ready,
        SequencerState.error,
        SequencerState.disposing,
      },
      SequencerState.ready: {
        SequencerState.playing,
        SequencerState.disposing,
        SequencerState.initializing, // Allow reinit
      },
      SequencerState.playing: {
        SequencerState.paused,
        SequencerState.stopping,
        SequencerState.ready,
        SequencerState.error,
      },
      SequencerState.paused: {
        SequencerState.playing,
        SequencerState.stopping,
        SequencerState.ready,
      },
      SequencerState.stopping: {
        SequencerState.ready,
        SequencerState.error,
      },
      SequencerState.disposing: {
        SequencerState.uninitialized,
        SequencerState.error,
      },
      SequencerState.error: {
        SequencerState.initializing,
        SequencerState.disposing,
        SequencerState.uninitialized,
      },
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }
  
  /// Record state transition for debugging
  void _recordTransition(SequencerState from, SequencerState to, String? error) {
    _stateHistory.add(_StateTransition(
      from: from,
      to: to,
      timestamp: DateTime.now(),
      error: error,
    ));
    
    // Keep history size limited
    if (_stateHistory.length > _maxHistorySize) {
      _stateHistory.removeAt(0);
    }
  }
  
  /// Execute an operation with proper locking
  Future<T> executeOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Check if operation is already in progress
    if (_operationCompleter.containsKey(operationName)) {
      debugPrint('[SequencerStateManager] Operation "$operationName" already in progress, waiting...');
      await _operationCompleter[operationName]!.future;
      debugPrint('[SequencerStateManager] Operation "$operationName" completed, proceeding');
    }
    
    // Create completer for this operation
    final completer = Completer<void>();
    _operationCompleter[operationName] = completer;
    
    try {
      debugPrint('[SequencerStateManager] Starting operation: $operationName');
      
      // Execute with timeout
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Operation "$operationName" timed out after ${timeout.inSeconds}s');
        },
      );
      
      debugPrint('[SequencerStateManager] Operation completed: $operationName');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('[SequencerStateManager] Operation failed: $operationName - $e');
      debugPrint('[SequencerStateManager] Stack trace: $stackTrace');
      
      // Update state to error if appropriate
      if (_state != SequencerState.disposing) {
        await updateState(SequencerState.error, error: e.toString());
      }
      
      rethrow;
    } finally {
      // Complete and remove the completer
      completer.complete();
      _operationCompleter.remove(operationName);
    }
  }
  
  /// Check if it's safe to perform an operation
  bool canPerformOperation(String operationName) {
    // Check state
    if (_state == SequencerState.disposing || _state == SequencerState.uninitialized) {
      debugPrint('[SequencerStateManager] Cannot perform "$operationName" in state $_state');
      return false;
    }
    
    // Check if another operation is in progress
    if (_operationCompleter.isNotEmpty) {
      final inProgress = _operationCompleter.keys.join(', ');
      debugPrint('[SequencerStateManager] Cannot perform "$operationName", operations in progress: $inProgress');
      return false;
    }
    
    return true;
  }
  
  /// Wait for a specific state
  Future<void> waitForState(
    SequencerState targetState, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_state == targetState) {
      return;
    }
    
    final completer = Completer<void>();
    
    void listener() {
      if (_state == targetState) {
        completer.complete();
      }
    }
    
    addListener(listener);
    
    try {
      await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Timeout waiting for state $targetState (current: $_state)');
        },
      );
    } finally {
      removeListener(listener);
    }
  }
  
  /// Reset the state manager
  void reset() {
    debugPrint('[SequencerStateManager] Resetting state manager');
    _state = SequencerState.uninitialized;
    _lastError = null;
    _operationCompleter.clear();
    _stateHistory.clear();
    notifyListeners();
  }
  
  /// Get state history for debugging
  List<String> getStateHistory() {
    return _stateHistory.map((t) => 
      '${t.timestamp.toIso8601String()}: ${t.from} → ${t.to}${t.error != null ? ' (error)' : ''}'
    ).toList();
  }
  
  /// Check if sequencer is in a playable state
  bool get isPlayable => _state == SequencerState.ready || _state == SequencerState.paused;
  
  /// Check if sequencer is currently playing
  bool get isPlaying => _state == SequencerState.playing;
  
  /// Check if sequencer is initialized
  bool get isInitialized => _state != SequencerState.uninitialized && 
                            _state != SequencerState.initializing &&
                            _state != SequencerState.error;
}

/// Internal class to track state transitions
class _StateTransition {
  final SequencerState from;
  final SequencerState to;
  final DateTime timestamp;
  final String? error;
  
  _StateTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    this.error,
  });
}