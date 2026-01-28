import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/models/progression_model.dart';
import 'package:scalemasterguitar/services/progression_storage_service.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

/// State for the progression library
class ProgressionLibraryState {
  final List<ProgressionModel> progressions;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final ProgressionStorageType storageType;

  const ProgressionLibraryState({
    this.progressions = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.storageType = ProgressionStorageType.none,
  });

  ProgressionLibraryState copyWith({
    List<ProgressionModel>? progressions,
    bool? isLoading,
    String? error,
    String? successMessage,
    ProgressionStorageType? storageType,
  }) {
    return ProgressionLibraryState(
      progressions: progressions ?? this.progressions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      storageType: storageType ?? this.storageType,
    );
  }

  /// Whether the user can save progressions
  bool get canSave => storageType != ProgressionStorageType.none;

  /// Human-readable storage description
  String get storageDescription {
    switch (storageType) {
      case ProgressionStorageType.cloud:
        return 'Cloud sync enabled';
      case ProgressionStorageType.local:
        return 'Stored locally';
      case ProgressionStorageType.none:
        return 'Upgrade to save';
    }
  }
}

/// Notifier for managing progression library state
class ProgressionLibraryNotifier extends StateNotifier<ProgressionLibraryState> {
  final Ref _ref;
  Entitlement _currentEntitlement = Entitlement.free;

  ProgressionLibraryNotifier(this._ref) : super(const ProgressionLibraryState()) {
    // Listen to entitlement changes
    _ref.listen<Entitlement>(revenueCatProvider, (previous, next) {
      if (previous != next) {
        _currentEntitlement = next;
        _updateStorageType(next);
        loadProgressions();
      }
    }, fireImmediately: true);
  }

  void _updateStorageType(Entitlement entitlement) {
    final storageType = ProgressionStorageService.getStorageType(entitlement);
    state = state.copyWith(storageType: storageType);
    debugPrint('[ProgressionLibraryNotifier] Storage type: $storageType');
  }

  /// Load all progressions from storage
  Future<void> loadProgressions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final progressions = await ProgressionStorageService.loadAllProgressions(_currentEntitlement);
      state = state.copyWith(
        progressions: progressions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load progressions: $e',
      );
    }
  }

  /// Save a new progression
  Future<bool> saveProgression(ProgressionModel progression) async {
    if (!ProgressionStorageService.canSave(_currentEntitlement)) {
      state = state.copyWith(
        error: 'Upgrade to Premium to save progressions',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if name already exists
      final nameExists = await ProgressionStorageService.progressionNameExists(
        progression.name,
        _currentEntitlement,
      );
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A progression with that name already exists',
        );
        return false;
      }

      final success = await ProgressionStorageService.saveProgression(
        progression,
        _currentEntitlement,
      );
      if (success) {
        // Reload progressions to update the list
        await loadProgressions();
        state = state.copyWith(
          successMessage: 'Progression "${progression.name}" saved successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save progression',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error saving progression: $e',
      );
      return false;
    }
  }

  /// Update an existing progression
  Future<bool> updateProgression(ProgressionModel progression) async {
    if (!ProgressionStorageService.canSave(_currentEntitlement)) {
      state = state.copyWith(
        error: 'Upgrade to Premium to update progressions',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if name already exists (excluding current progression)
      final nameExists = await ProgressionStorageService.progressionNameExists(
        progression.name,
        _currentEntitlement,
        excludeId: progression.id,
      );
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A progression with that name already exists',
        );
        return false;
      }

      final success = await ProgressionStorageService.updateProgression(
        progression,
        _currentEntitlement,
      );
      if (success) {
        // Reload progressions to update the list
        await loadProgressions();
        state = state.copyWith(
          successMessage: 'Progression "${progression.name}" updated successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update progression',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating progression: $e',
      );
      return false;
    }
  }

  /// Delete a progression
  Future<bool> deleteProgression(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final progression = state.progressions.firstWhere((p) => p.id == id);
      final success = await ProgressionStorageService.deleteProgression(
        id,
        _currentEntitlement,
      );

      if (success) {
        // Remove from current state
        final updatedProgressions = state.progressions.where((p) => p.id != id).toList();
        state = state.copyWith(
          progressions: updatedProgressions,
          isLoading: false,
          successMessage: 'Progression "${progression.name}" deleted successfully',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete progression',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error deleting progression: $e',
      );
      return false;
    }
  }

  /// Get a specific progression by ID
  ProgressionModel? getProgression(String id) {
    try {
      return state.progressions.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error or success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Get progressions filtered by name
  List<ProgressionModel> searchProgressions(String query) {
    if (query.isEmpty) return state.progressions;

    final lowerQuery = query.toLowerCase();
    return state.progressions.where((progression) =>
      progression.name.toLowerCase().contains(lowerQuery) ||
      (progression.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      (progression.tags?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Get progressions sorted by different criteria
  List<ProgressionModel> getSortedProgressions(ProgressionSortType sortType) {
    final progressions = List<ProgressionModel>.from(state.progressions);

    switch (sortType) {
      case ProgressionSortType.nameAsc:
        progressions.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProgressionSortType.nameDesc:
        progressions.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProgressionSortType.dateCreatedAsc:
        progressions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ProgressionSortType.dateCreatedDesc:
        progressions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProgressionSortType.lastModifiedAsc:
        progressions.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        break;
      case ProgressionSortType.lastModifiedDesc:
        progressions.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
      case ProgressionSortType.durationAsc:
        progressions.sort((a, b) => a.totalBeats.compareTo(b.totalBeats));
        break;
      case ProgressionSortType.durationDesc:
        progressions.sort((a, b) => b.totalBeats.compareTo(a.totalBeats));
        break;
    }

    return progressions;
  }

  /// Migrate local progressions to cloud (for users upgrading to subscription)
  Future<int> migrateToCloud() async {
    if (state.storageType != ProgressionStorageType.cloud) {
      return 0;
    }

    try {
      final migratedCount = await ProgressionStorageService.migrateLocalToCloud();
      if (migratedCount > 0) {
        await loadProgressions();
        state = state.copyWith(
          successMessage: 'Migrated $migratedCount progressions to cloud',
        );
      }
      return migratedCount;
    } catch (e) {
      debugPrint('[ProgressionLibraryNotifier] Migration error: $e');
      return 0;
    }
  }
}

/// Sort types for progressions
enum ProgressionSortType {
  nameAsc,
  nameDesc,
  dateCreatedAsc,
  dateCreatedDesc,
  lastModifiedAsc,
  lastModifiedDesc,
  durationAsc,
  durationDesc,
}

/// Provider for progression library
final progressionLibraryProvider = StateNotifierProvider<ProgressionLibraryNotifier, ProgressionLibraryState>((ref) {
  return ProgressionLibraryNotifier(ref);
});

/// Provider for progression count
final progressionCountProvider = Provider<int>((ref) {
  final state = ref.watch(progressionLibraryProvider);
  return state.progressions.length;
});

/// Provider for checking if user can save progressions
final canSaveProgressionsProvider = Provider<bool>((ref) {
  final state = ref.watch(progressionLibraryProvider);
  return state.canSave;
});

/// Provider for storage description
final progressionStorageDescriptionProvider = Provider<String>((ref) {
  final state = ref.watch(progressionLibraryProvider);
  return state.storageDescription;
});
