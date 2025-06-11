import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scalemasterguitar/models/progression_model.dart';

/// Service for managing chord progression persistence
class ProgressionStorageService {
  static const String _progressionIdListKey = 'progression_ids';

  /// Save a progression to local storage
  static Future<bool> saveProgression(ProgressionModel progression) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the progression data
      final progressionJson = progression.toJsonString();
      await prefs.setString('progression_${progression.id}', progressionJson);
      
      // Update the list of progression IDs
      final existingIds = await getProgressionIds();
      if (!existingIds.contains(progression.id)) {
        existingIds.add(progression.id);
        await prefs.setStringList(_progressionIdListKey, existingIds);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving progression: $e');
      return false;
    }
  }

  /// Load all saved progressions
  static Future<List<ProgressionModel>> loadAllProgressions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressionIds = await getProgressionIds();
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
            await _removeProgressionId(id);
          }
        }
      }

      // Sort by last modified date (most recent first)
      progressions.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return progressions;
    } catch (e) {
      debugPrint('Error loading progressions: $e');
      return [];
    }
  }

  /// Load a specific progression by ID
  static Future<ProgressionModel?> loadProgression(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressionJson = prefs.getString('progression_$id');
      
      if (progressionJson != null) {
        return ProgressionModel.fromJsonString(progressionJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading progression $id: $e');
      return null;
    }
  }

  /// Update an existing progression
  static Future<bool> updateProgression(ProgressionModel progression) async {
    try {
      // Update the last modified time
      final updatedProgression = progression.copyWith(
        lastModified: DateTime.now(),
      );
      
      return await saveProgression(updatedProgression);
    } catch (e) {
      debugPrint('Error updating progression: $e');
      return false;
    }
  }

  /// Delete a progression
  static Future<bool> deleteProgression(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the progression data
      await prefs.remove('progression_$id');
      
      // Remove from ID list
      await _removeProgressionId(id);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting progression: $e');
      return false;
    }
  }

  /// Get list of all progression IDs
  static Future<List<String>> getProgressionIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_progressionIdListKey) ?? [];
    } catch (e) {
      debugPrint('Error getting progression IDs: $e');
      return [];
    }
  }

  /// Check if a progression with given name already exists
  static Future<bool> progressionNameExists(String name, {String? excludeId}) async {
    try {
      final progressions = await loadAllProgressions();
      return progressions.any((p) => 
        p.name.toLowerCase() == name.toLowerCase() && 
        (excludeId == null || p.id != excludeId)
      );
    } catch (e) {
      debugPrint('Error checking progression name: $e');
      return false;
    }
  }

  /// Get progression count
  static Future<int> getProgressionCount() async {
    try {
      final ids = await getProgressionIds();
      return ids.length;
    } catch (e) {
      debugPrint('Error getting progression count: $e');
      return 0;
    }
  }

  /// Clear all progressions (for testing/reset purposes)
  static Future<bool> clearAllProgressions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await getProgressionIds();
      
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

  /// Export all progressions as JSON string
  static Future<String?> exportProgressions() async {
    try {
      final progressions = await loadAllProgressions();
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

  /// Import progressions from JSON string
  static Future<bool> importProgressions(String jsonString, {bool overwrite = false}) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      final progressionsList = importData['progressions'] as List<dynamic>;
      
      int successCount = 0;
      for (final progressionJson in progressionsList) {
        try {
          final progression = ProgressionModel.fromJson(progressionJson as Map<String, dynamic>);
          
          // Check if progression name already exists
          if (!overwrite && await progressionNameExists(progression.name)) {
            // Generate a unique name
            int counter = 1;
            String newName;
            do {
              newName = '${progression.name} ($counter)';
              counter++;
            } while (await progressionNameExists(newName));
            
            final renamedProgression = progression.copyWith(
              id: ProgressionModel.generateId(),
              name: newName,
            );
            await saveProgression(renamedProgression);
          } else {
            await saveProgression(progression);
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

  /// Private helper to remove a progression ID from the list
  static Future<void> _removeProgressionId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await getProgressionIds();
      ids.remove(id);
      await prefs.setStringList(_progressionIdListKey, ids);
    } catch (e) {
      debugPrint('Error removing progression ID: $e');
    }
  }
}