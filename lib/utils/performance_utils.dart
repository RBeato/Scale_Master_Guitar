import 'dart:async';
import 'package:flutter/foundation.dart';

class PerformanceUtils {
  static void trackOperation(String name, Function operation) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      operation();
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 16) {
        debugPrint('Performance warning: $name took ${stopwatch.elapsedMilliseconds}ms');
      }
    } else {
      operation();
    }
  }

  static Future<T> trackAsyncOperation<T>(String name, Future<T> Function() operation) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = await operation();
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 16) {
        debugPrint('Performance warning: $name took ${stopwatch.elapsedMilliseconds}ms');
      }
      return result;
    } else {
      return await operation();
    }
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class NoteTracker {
  final Map<int, DateTime> _noteTimestamps = {};
  final Set<int> _activeNotes = {};
  static const int _staleNoteTimeoutMs = 5000; // 5 seconds

  void addNote(int note) {
    _activeNotes.add(note);
    _noteTimestamps[note] = DateTime.now();
  }

  void removeNote(int note) {
    _activeNotes.remove(note);
    _noteTimestamps.remove(note);
  }

  Set<int> getStaleNotes() {
    final now = DateTime.now();
    final staleNotes = <int>{};
    
    for (final entry in _noteTimestamps.entries) {
      if (now.difference(entry.value).inMilliseconds > _staleNoteTimeoutMs) {
        staleNotes.add(entry.key);
      }
    }
    
    return staleNotes;
  }

  void cleanupStaleNotes() {
    final staleNotes = getStaleNotes();
    for (final note in staleNotes) {
      removeNote(note);
    }
  }

  Set<int> get activeNotes => Set.from(_activeNotes);
  
  void clear() {
    _activeNotes.clear();
    _noteTimestamps.clear();
  }
}