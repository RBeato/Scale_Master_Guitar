import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scalemasterguitar/models/progression_model.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/services/progression_supabase_service.dart';

/// Storage type for progressions based on user entitlement
enum ProgressionStorageType {
  none,   // Free users - cannot save
  local,  // Lifetime Premium - local only
  cloud,  // Subscription users - Supabase cloud
}

/// Service for managing chord progression persistence
/// Routes to appropriate storage based on user entitlement:
/// - Free users: Cannot save
/// - Lifetime Premium: Local storage (SharedPreferences)
/// - Subscription users: Cloud storage (Supabase)
class ProgressionStorageService {
  static const String _progressionIdListKey = 'progression_ids';

  /// Determine storage type based on entitlement
  static ProgressionStorageType getStorageType(Entitlement entitlement) {
    if (entitlement.hasFingeringsLibraryAccess) {
      // Subscription users (premiumSub, fingeringsLibrary, premiumOneTimeWithLibrary)
      return ProgressionStorageType.cloud;
    } else if (entitlement.isPremium) {
      // Lifetime Premium only (premiumOneTime)
      return ProgressionStorageType.local;
    } else {
      // Free users
      return ProgressionStorageType.none;
    }
  }

  /// Check if user can save progressions
  static bool canSave(Entitlement entitlement) {
    return getStorageType(entitlement) != ProgressionStorageType.none;
  }

  /// Get storage description for UI
  static String getStorageDescription(Entitlement entitlement) {
    switch (getStorageType(entitlement)) {
      case ProgressionStorageType.cloud:
        return 'Cloud sync enabled';
      case ProgressionStorageType.local:
        return 'Stored locally on this device';
      case ProgressionStorageType.none:
        return 'Upgrade to save progressions';
    }
  }

  // ============================================
  // ENTITLEMENT-AWARE METHODS (PUBLIC API)
  // ============================================

  /// Save a progression (routes to appropriate storage)
  static Future<bool> saveProgression(
    ProgressionModel progression,
    Entitlement entitlement,
  ) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        final result = await ProgressionSupabaseService.instance.saveProgression(progression);
        return result != null;
      case ProgressionStorageType.local:
        return await saveProgressionLocal(progression);
      case ProgressionStorageType.none:
        debugPrint('[ProgressionStorageService] Cannot save: user not entitled');
        return false;
    }
  }

  /// Load all saved progressions (routes to appropriate storage)
  static Future<List<ProgressionModel>> loadAllProgressions(Entitlement entitlement) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        return await ProgressionSupabaseService.instance.getUserProgressions();
      case ProgressionStorageType.local:
        return await loadAllProgressionsLocal();
      case ProgressionStorageType.none:
        return [];
    }
  }

  /// Load a specific progression by ID
  static Future<ProgressionModel?> loadProgression(
    String id,
    Entitlement entitlement,
  ) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        return await ProgressionSupabaseService.instance.loadProgression(id);
      case ProgressionStorageType.local:
        return await loadProgressionLocal(id);
      case ProgressionStorageType.none:
        return null;
    }
  }

  /// Update an existing progression
  static Future<bool> updateProgression(
    ProgressionModel progression,
    Entitlement entitlement,
  ) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        final result = await ProgressionSupabaseService.instance.updateProgression(progression);
        return result != null;
      case ProgressionStorageType.local:
        return await updateProgressionLocal(progression);
      case ProgressionStorageType.none:
        return false;
    }
  }

  /// Delete a progression
  static Future<bool> deleteProgression(
    String id,
    Entitlement entitlement,
  ) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        return await ProgressionSupabaseService.instance.deleteProgression(id);
      case ProgressionStorageType.local:
        return await deleteProgressionLocal(id);
      case ProgressionStorageType.none:
        return false;
    }
  }

  /// Check if a progression with given name already exists
  static Future<bool> progressionNameExists(
    String name,
    Entitlement entitlement, {
    String? excludeId,
  }) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        return await ProgressionSupabaseService.instance
            .progressionNameExists(name, excludeId: excludeId);
      case ProgressionStorageType.local:
        return await progressionNameExistsLocal(name, excludeId: excludeId);
      case ProgressionStorageType.none:
        return false;
    }
  }

  /// Get progression count
  static Future<int> getProgressionCount(Entitlement entitlement) async {
    final storageType = getStorageType(entitlement);

    switch (storageType) {
      case ProgressionStorageType.cloud:
        return await ProgressionSupabaseService.instance.getProgressionCount();
      case ProgressionStorageType.local:
        return await getProgressionCountLocal();
      case ProgressionStorageType.none:
        return 0;
    }
  }

  // ============================================
  // LOCAL STORAGE METHODS
  // ============================================

  /// Save a progression to local storage
  static Future<bool> saveProgressionLocal(ProgressionModel progression) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save the progression data
      final progressionJson = progression.toJsonString();
      await prefs.setString('progression_${progression.id}', progressionJson);

      // Update the list of progression IDs
      final existingIds = await getProgressionIdsLocal();
      if (!existingIds.contains(progression.id)) {
        existingIds.add(progression.id);
        await prefs.setStringList(_progressionIdListKey, existingIds);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving progression locally: $e');
      return false;
    }
  }

  /// Load all saved progressions from local storage
  static Future<List<ProgressionModel>> loadAllProgressionsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressionIds = await getProgressionIdsLocal();
      final progressions = <ProgressionModel>[];

      for (final id in progressionIds) {
        final progressionJson = prefs.getString('progression_$id');
        if (progressionJson != null) {
          try {
            final progression = ProgressionModel.fromJsonString(progressionJson);
            progressions.add(progression);
          } catch (e) {
            debugPrint('Error loading progression $id: $e');
            // Remove corrupted progression ID
            await _removeProgressionIdLocal(id);
          }
        }
      }

      // Sort by last modified date (most recent first)
      progressions.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return progressions;
    } catch (e) {
      debugPrint('Error loading progressions locally: $e');
      return [];
    }
  }

  /// Load a specific progression by ID from local storage
  static Future<ProgressionModel?> loadProgressionLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressionJson = prefs.getString('progression_$id');

      if (progressionJson != null) {
        return ProgressionModel.fromJsonString(progressionJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading progression $id locally: $e');
      return null;
    }
  }

  /// Update an existing progression in local storage
  static Future<bool> updateProgressionLocal(ProgressionModel progression) async {
    try {
      // Update the last modified time
      final updatedProgression = progression.copyWith(
        lastModified: DateTime.now(),
      );

      return await saveProgressionLocal(updatedProgression);
    } catch (e) {
      debugPrint('Error updating progression locally: $e');
      return false;
    }
  }

  /// Delete a progression from local storage
  static Future<bool> deleteProgressionLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove the progression data
      await prefs.remove('progression_$id');

      // Remove from ID list
      await _removeProgressionIdLocal(id);

      return true;
    } catch (e) {
      debugPrint('Error deleting progression locally: $e');
      return false;
    }
  }

  /// Get list of all local progression IDs
  static Future<List<String>> getProgressionIdsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_progressionIdListKey) ?? [];
    } catch (e) {
      debugPrint('Error getting progression IDs: $e');
      return [];
    }
  }

  /// Check if a progression with given name already exists locally
  static Future<bool> progressionNameExistsLocal(String name, {String? excludeId}) async {
    try {
      final progressions = await loadAllProgressionsLocal();
      return progressions.any((p) =>
        p.name.toLowerCase() == name.toLowerCase() &&
        (excludeId == null || p.id != excludeId)
      );
    } catch (e) {
      debugPrint('Error checking progression name: $e');
      return false;
    }
  }

  /// Get local progression count
  static Future<int> getProgressionCountLocal() async {
    try {
      final ids = await getProgressionIdsLocal();
      return ids.length;
    } catch (e) {
      debugPrint('Error getting progression count: $e');
      return 0;
    }
  }

  /// Clear all local progressions (for testing/reset purposes)
  static Future<bool> clearAllProgressionsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await getProgressionIdsLocal();

      // Remove all progression data
      for (final id in ids) {
        await prefs.remove('progression_$id');
      }

      // Clear the ID list
      await prefs.remove(_progressionIdListKey);

      return true;
    } catch (e) {
      debugPrint('Error clearing progressions: $e');
      return false;
    }
  }

  /// Export all local progressions as JSON string
  static Future<String?> exportProgressionsLocal() async {
    try {
      final progressions = await loadAllProgressionsLocal();
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'progressions': progressions.map((p) => p.toJson()).toList(),
      };
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('Error exporting progressions: $e');
      return null;
    }
  }

  /// Import progressions from JSON string to local storage
  static Future<bool> importProgressionsLocal(String jsonString, {bool overwrite = false}) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      final progressionsList = importData['progressions'] as List<dynamic>;

      int successCount = 0;
      for (final progressionJson in progressionsList) {
        try {
          final progression = ProgressionModel.fromJson(progressionJson as Map<String, dynamic>);

          // Check if progression name already exists
          if (!overwrite && await progressionNameExistsLocal(progression.name)) {
            // Generate a unique name
            int counter = 1;
            String newName;
            do {
              newName = '${progression.name} ($counter)';
              counter++;
            } while (await progressionNameExistsLocal(newName));

            final renamedProgression = progression.copyWith(
              id: ProgressionModel.generateId(),
              name: newName,
            );
            await saveProgressionLocal(renamedProgression);
          } else {
            await saveProgressionLocal(progression);
          }
          successCount++;
        } catch (e) {
          debugPrint('Error importing individual progression: $e');
        }
      }

      return successCount > 0;
    } catch (e) {
      debugPrint('Error importing progressions: $e');
      return false;
    }
  }

  /// Private helper to remove a progression ID from the local list
  static Future<void> _removeProgressionIdLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await getProgressionIdsLocal();
      ids.remove(id);
      await prefs.setStringList(_progressionIdListKey, ids);
    } catch (e) {
      debugPrint('Error removing progression ID: $e');
    }
  }

  // ============================================
  // MIGRATION HELPERS
  // ============================================

  /// Migrate local progressions to cloud (for users upgrading to subscription)
  static Future<int> migrateLocalToCloud() async {
    try {
      final localProgressions = await loadAllProgressionsLocal();
      int migratedCount = 0;

      for (final progression in localProgressions) {
        final result = await ProgressionSupabaseService.instance.saveProgression(progression);
        if (result != null) {
          migratedCount++;
        }
      }

      debugPrint('[ProgressionStorageService] Migrated $migratedCount progressions to cloud');
      return migratedCount;
    } catch (e) {
      debugPrint('[ProgressionStorageService] Migration error: $e');
      return 0;
    }
  }
}
