import 'package:flutter/foundation.dart';
import 'package:scalemasterguitar/models/progression_model.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';

/// Service for managing chord progressions in Supabase cloud storage
/// Only for users with Fingerings Library subscription access
class ProgressionSupabaseService {
  static ProgressionSupabaseService? _instance;

  ProgressionSupabaseService._();

  static ProgressionSupabaseService get instance {
    _instance ??= ProgressionSupabaseService._();
    return _instance!;
  }

  /// Check if Supabase is ready for use
  bool get isReady =>
      SupabaseService.instance.isInitialized &&
      SupabaseService.instance.isAuthenticated;

  String? get currentUserId => SupabaseService.instance.currentUserId;

  // ============================================
  // PROGRESSIONS CRUD OPERATIONS
  // ============================================

  /// Save a new progression to Supabase
  Future<ProgressionModel?> saveProgression(ProgressionModel progression) async {
    if (!isReady) {
      debugPrint('[ProgressionSupabaseService] Cannot save: not ready');
      return null;
    }

    try {
      final data = _progressionToSupabaseJson(progression);
      data['user_id'] = currentUserId;

      final response = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .insert(data)
          .select()
          .single();

      debugPrint('[ProgressionSupabaseService] Saved progression: ${response['id']}');
      return _progressionFromSupabaseJson(response);
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error saving progression: $e');
      return null;
    }
  }

  /// Update an existing progression
  Future<ProgressionModel?> updateProgression(ProgressionModel progression) async {
    if (!isReady) {
      return null;
    }

    try {
      final data = _progressionToSupabaseJson(progression);
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .update(data)
          .eq('id', progression.id)
          .eq('user_id', currentUserId!)
          .select()
          .single();

      return _progressionFromSupabaseJson(response);
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error updating progression: $e');
      return null;
    }
  }

  /// Delete a progression by ID
  Future<bool> deleteProgression(String progressionId) async {
    if (!isReady) {
      return false;
    }

    try {
      await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .delete()
          .eq('id', progressionId)
          .eq('user_id', currentUserId!);

      debugPrint('[ProgressionSupabaseService] Deleted progression: $progressionId');
      return true;
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error deleting progression: $e');
      return false;
    }
  }

  /// Get all progressions for the current user
  Future<List<ProgressionModel>> getUserProgressions({
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    if (!isReady) {
      return [];
    }

    try {
      final response = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select()
          .eq('user_id', currentUserId!)
          .order(sortBy, ascending: ascending);

      return (response as List)
          .map((json) => _progressionFromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error getting user progressions: $e');
      return [];
    }
  }

  /// Load a specific progression by ID
  Future<ProgressionModel?> loadProgression(String progressionId) async {
    if (!isReady) {
      return null;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select()
          .eq('id', progressionId)
          .single();

      return _progressionFromSupabaseJson(response);
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error loading progression: $e');
      return null;
    }
  }

  /// Get public progressions with optional search and pagination
  Future<List<ProgressionModel>> getPublicProgressions({
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!SupabaseService.instance.isInitialized) {
      return [];
    }

    try {
      var query = SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select()
          .eq('is_public', true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => _progressionFromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error getting public progressions: $e');
      return [];
    }
  }

  /// Toggle the public visibility of a progression
  Future<bool> togglePublic(String progressionId) async {
    if (!isReady) {
      return false;
    }

    try {
      // Get current state
      final current = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select('is_public')
          .eq('id', progressionId)
          .eq('user_id', currentUserId!)
          .single();

      final newValue = !(current['is_public'] as bool);

      await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .update({
            'is_public': newValue,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', progressionId)
          .eq('user_id', currentUserId!);

      return newValue;
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error toggling public: $e');
      return false;
    }
  }

  /// Check if a progression with given name already exists for this user
  Future<bool> progressionNameExists(String name, {String? excludeId}) async {
    if (!isReady) {
      return false;
    }

    try {
      var query = SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select('id')
          .eq('user_id', currentUserId!)
          .ilike('name', name);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error checking name: $e');
      return false;
    }
  }

  /// Get progression count for current user
  Future<int> getProgressionCount() async {
    if (!isReady) {
      return 0;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('smg_saved_progressions')
          .select('id')
          .eq('user_id', currentUserId!);

      return (response as List).length;
    } catch (e) {
      debugPrint('[ProgressionSupabaseService] Error getting count: $e');
      return 0;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Convert ProgressionModel to Supabase JSON format
  Map<String, dynamic> _progressionToSupabaseJson(ProgressionModel progression) {
    return {
      'name': progression.name,
      'description': progression.description,
      'tags': progression.tags,
      'chords': progression.chords.map((c) => c.toJson()).toList(),
      'total_beats': progression.totalBeats,
      'created_at': progression.createdAt.toIso8601String(),
      'updated_at': progression.lastModified.toIso8601String(),
    };
  }

  /// Convert Supabase JSON to ProgressionModel
  ProgressionModel _progressionFromSupabaseJson(Map<String, dynamic> json) {
    return ProgressionModel.fromJson({
      'id': json['id'],
      'name': json['name'],
      'description': json['description'],
      'tags': json['tags'],
      'chords': json['chords'],
      'totalBeats': json['total_beats'],
      'createdAt': json['created_at'],
      'lastModified': json['updated_at'],
    });
  }
}
