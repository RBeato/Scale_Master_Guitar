import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';

/// Service for interacting with Supabase for the fingerings library
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize Supabase with credentials from .env
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null ||
          supabaseUrl.isEmpty ||
          supabaseUrl.contains('your-project')) {
        debugPrint('[SupabaseService] Supabase URL not configured');
        return false;
      }

      if (supabaseAnonKey == null ||
          supabaseAnonKey.isEmpty ||
          supabaseAnonKey.contains('your-anon-key')) {
        debugPrint('[SupabaseService] Supabase anon key not configured');
        return false;
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      // Sign in anonymously if not already signed in
      if (_client!.auth.currentUser == null) {
        await _signInAnonymously();
      }

      debugPrint('[SupabaseService] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Initialization failed: $e');
      return false;
    }
  }

  /// Sign in anonymously to get a user ID
  Future<void> _signInAnonymously() async {
    try {
      await client.auth.signInAnonymously();
      debugPrint('[SupabaseService] Signed in anonymously: $currentUserId');
    } catch (e) {
      debugPrint('[SupabaseService] Anonymous sign-in failed: $e');
    }
  }

  /// Get current user ID
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  // ============================================
  // FINGERINGS CRUD OPERATIONS
  // ============================================

  /// Save a new fingering to the database
  Future<SavedFingering?> saveFingering(SavedFingering fingering) async {
    if (!_isInitialized || currentUserId == null) {
      debugPrint('[SupabaseService] Cannot save: not initialized or no user');
      return null;
    }

    try {
      final data = fingering.toJson();
      data['user_id'] = currentUserId;

      final response = await client
          .from('smg_saved_fingerings')
          .insert(data)
          .select()
          .single();

      debugPrint('[SupabaseService] Saved fingering: ${response['id']}');
      return SavedFingering.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error saving fingering: $e');
      return null;
    }
  }

  /// Update an existing fingering
  Future<SavedFingering?> updateFingering(SavedFingering fingering) async {
    if (!_isInitialized || currentUserId == null) {
      return null;
    }

    try {
      final data = fingering.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('smg_saved_fingerings')
          .update(data)
          .eq('id', fingering.id)
          .eq('user_id', currentUserId!)
          .select()
          .single();

      return SavedFingering.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error updating fingering: $e');
      return null;
    }
  }

  /// Delete a fingering by ID
  Future<bool> deleteFingering(String fingeringId) async {
    if (!_isInitialized || currentUserId == null) {
      return false;
    }

    try {
      await client
          .from('smg_saved_fingerings')
          .delete()
          .eq('id', fingeringId)
          .eq('user_id', currentUserId!);

      debugPrint('[SupabaseService] Deleted fingering: $fingeringId');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error deleting fingering: $e');
      return false;
    }
  }

  /// Get all fingerings for the current user
  Future<List<SavedFingering>> getUserFingerings({
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    if (!_isInitialized || currentUserId == null) {
      return [];
    }

    try {
      final response = await client
          .from('smg_saved_fingerings')
          .select()
          .eq('user_id', currentUserId!)
          .order(sortBy, ascending: ascending);

      return (response as List)
          .map((json) => SavedFingering.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error getting user fingerings: $e');
      return [];
    }
  }

  /// Get public fingerings with optional search and pagination
  Future<List<SavedFingering>> getPublicFingerings({
    String? searchQuery,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_isInitialized) {
      return [];
    }

    try {
      var query = client
          .from('smg_saved_fingerings')
          .select()
          .eq('is_public', true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      final fingerings = (response as List)
          .map((json) => SavedFingering.fromJson(json))
          .toList();

      // Check which fingerings the user has liked
      if (currentUserId != null && fingerings.isNotEmpty) {
        final fingeringIds = fingerings.map((f) => f.id).toList();
        final likes = await client
            .from('smg_fingering_likes')
            .select('fingering_id')
            .eq('user_id', currentUserId!)
            .inFilter('fingering_id', fingeringIds);

        final likedIds = (likes as List)
            .map((l) => l['fingering_id'] as String)
            .toSet();

        for (final fingering in fingerings) {
          fingering.isLikedByUser = likedIds.contains(fingering.id);
        }
      }

      return fingerings;
    } catch (e) {
      debugPrint('[SupabaseService] Error getting public fingerings: $e');
      return [];
    }
  }

  /// Toggle the public visibility of a fingering
  Future<bool> togglePublic(String fingeringId) async {
    if (!_isInitialized || currentUserId == null) {
      return false;
    }

    try {
      // Get current state
      final current = await client
          .from('smg_saved_fingerings')
          .select('is_public')
          .eq('id', fingeringId)
          .eq('user_id', currentUserId!)
          .single();

      final newValue = !(current['is_public'] as bool);

      await client
          .from('smg_saved_fingerings')
          .update({'is_public': newValue, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', fingeringId)
          .eq('user_id', currentUserId!);

      return newValue;
    } catch (e) {
      debugPrint('[SupabaseService] Error toggling public: $e');
      return false;
    }
  }

  /// Toggle like on a fingering
  Future<bool> toggleLike(String fingeringId) async {
    if (!_isInitialized || currentUserId == null) {
      return false;
    }

    try {
      // Check if already liked
      final existing = await client
          .from('smg_fingering_likes')
          .select()
          .eq('user_id', currentUserId!)
          .eq('fingering_id', fingeringId)
          .maybeSingle();

      if (existing != null) {
        // Unlike - remove the like
        await client
            .from('smg_fingering_likes')
            .delete()
            .eq('user_id', currentUserId!)
            .eq('fingering_id', fingeringId);

        // Decrement likes count
        await client.rpc('smg_decrement_fingering_likes', params: {
          'fingering_id_param': fingeringId,
        });

        return false; // Now unliked
      } else {
        // Like - add the like
        await client.from('smg_fingering_likes').insert({
          'user_id': currentUserId,
          'fingering_id': fingeringId,
        });

        // Increment likes count
        await client.rpc('smg_increment_fingering_likes', params: {
          'fingering_id_param': fingeringId,
        });

        return true; // Now liked
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error toggling like: $e');
      return false;
    }
  }

  /// Increment the load count when a fingering is loaded
  Future<void> incrementLoadCount(String fingeringId) async {
    if (!_isInitialized) return;

    try {
      await client.rpc('smg_increment_fingering_loads', params: {
        'fingering_id_param': fingeringId,
      });
    } catch (e) {
      debugPrint('[SupabaseService] Error incrementing load count: $e');
    }
  }

  /// Get a single fingering by ID
  Future<SavedFingering?> getFingering(String fingeringId) async {
    if (!_isInitialized) return null;

    try {
      final response = await client
          .from('smg_saved_fingerings')
          .select()
          .eq('id', fingeringId)
          .single();

      final fingering = SavedFingering.fromJson(response);

      // Check if liked by current user
      if (currentUserId != null) {
        final like = await client
            .from('smg_fingering_likes')
            .select()
            .eq('user_id', currentUserId!)
            .eq('fingering_id', fingeringId)
            .maybeSingle();

        fingering.isLikedByUser = like != null;
      }

      return fingering;
    } catch (e) {
      debugPrint('[SupabaseService] Error getting fingering: $e');
      return null;
    }
  }
}
