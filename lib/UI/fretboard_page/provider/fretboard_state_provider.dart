import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class to hold the current fretboard editing state
class FretboardEditState {
  final List<List<bool>> dotPositions;
  final List<List<Color?>> dotColors;
  final int stringCount;
  final int fretCount;

  const FretboardEditState({
    required this.dotPositions,
    required this.dotColors,
    this.stringCount = 6,
    this.fretCount = 24,
  });

  factory FretboardEditState.empty({int stringCount = 6, int fretCount = 24}) {
    return FretboardEditState(
      dotPositions: List.generate(
        stringCount,
        (_) => List.filled(fretCount + 1, false),
      ),
      dotColors: List.generate(
        stringCount,
        (_) => List.filled(fretCount + 1, null),
      ),
      stringCount: stringCount,
      fretCount: fretCount,
    );
  }

  FretboardEditState copyWith({
    List<List<bool>>? dotPositions,
    List<List<Color?>>? dotColors,
  }) {
    return FretboardEditState(
      dotPositions: dotPositions ?? this.dotPositions,
      dotColors: dotColors ?? this.dotColors,
      stringCount: stringCount,
      fretCount: fretCount,
    );
  }

  /// Check if there are any dots on the fretboard
  bool get hasDots {
    for (final row in dotPositions) {
      for (final dot in row) {
        if (dot) return true;
      }
    }
    return false;
  }

  /// Get the count of dots
  int get dotCount {
    int count = 0;
    for (final row in dotPositions) {
      for (final dot in row) {
        if (dot) count++;
      }
    }
    return count;
  }
}

/// Notifier for managing fretboard edit state
class FretboardEditStateNotifier extends StateNotifier<FretboardEditState> {
  FretboardEditStateNotifier() : super(FretboardEditState.empty());

  /// Update the entire state
  void updateState(FretboardEditState newState) {
    state = newState;
  }

  /// Update dot positions
  void updateDotPositions(List<List<bool>> positions) {
    state = state.copyWith(dotPositions: positions);
  }

  /// Update dot colors
  void updateDotColors(List<List<Color?>> colors) {
    state = state.copyWith(dotColors: colors);
  }

  /// Update both positions and colors
  void updateDotsAndColors(
      List<List<bool>> positions, List<List<Color?>> colors) {
    state = state.copyWith(dotPositions: positions, dotColors: colors);
  }

  /// Reset to empty state
  void reset() {
    state = FretboardEditState.empty(
      stringCount: state.stringCount,
      fretCount: state.fretCount,
    );
  }
}

/// Provider for the current fretboard edit state
final fretboardEditStateProvider =
    StateNotifierProvider<FretboardEditStateNotifier, FretboardEditState>(
  (ref) => FretboardEditStateNotifier(),
);
