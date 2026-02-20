import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of an account migration attempt.
///
/// Contains detailed information about what succeeded and what failed
/// during the anonymous-to-authenticated user migration.
class MigrationResult {
  final bool success;
  final String? errorMessage;
  final String? previousUserId;
  final String? newUserId;
  final Entitlement entitlementAfterMigration;
  final int fingeringsMigrated;
  final int progressionsMigrated;
  final int fingeringLikesMigrated;

  const MigrationResult({
    required this.success,
    this.errorMessage,
    this.previousUserId,
    this.newUserId,
    this.entitlementAfterMigration = Entitlement.free,
    this.fingeringsMigrated = 0,
    this.progressionsMigrated = 0,
    this.fingeringLikesMigrated = 0,
  });

  bool get userIdChanged =>
      previousUserId != null &&
      newUserId != null &&
      previousUserId != newUserId;

  @override
  String toString() {
    return 'MigrationResult('
        'success: $success, '
        'previousUserId: $previousUserId, '
        'newUserId: $newUserId, '
        'entitlement: $entitlementAfterMigration, '
        'fingeringsMigrated: $fingeringsMigrated, '
        'progressionsMigrated: $progressionsMigrated, '
        'fingeringLikesMigrated: $fingeringLikesMigrated'
        '${errorMessage != null ? ', error: $errorMessage' : ''}'
        ')';
  }
}

/// Handles migration from anonymous Supabase + RevenueCat identity
/// to an authenticated (Google/Apple Sign-In) identity.
///
/// SMG-specific considerations:
/// - Entitlements are checked directly from RevenueCat (no Supabase tier table)
/// - Supabase stores fingerings (smg_saved_fingerings), fingering likes
///   (smg_fingering_likes), and progressions (smg_saved_progressions)
/// - After identity switch, all user-owned data must be transferred
///   to the new user ID
class AccountMigrationService {
  static const String _tag = '[AccountMigration]';

  /// Perform full account migration from anonymous to authenticated user.
  ///
  /// Steps:
  /// 1. Capture current anonymous Supabase user ID
  /// 2. Verify Supabase identity linking (caller handles the actual OAuth)
  /// 3. Log in to RevenueCat with the user's email
  /// 4. Re-check entitlements to ensure they survived the identity switch
  /// 5. Transfer fingerings/progressions data if Supabase user ID changed
  ///
  /// Returns a [MigrationResult] with details of what happened.
  /// On failure, existing anonymous functionality is preserved.
  static Future<MigrationResult> migrateToAuthenticatedUser({
    required String email,
    required AuthResponse authResponse,
  }) async {
    final supabase = SupabaseService.instance;
    final previousUserId = supabase.currentUserId;

    debugPrint('$_tag Starting migration for $email');
    debugPrint('$_tag Previous anonymous user ID: $previousUserId');

    // -------------------------------------------------------
    // Step 1: Validate prerequisites
    // -------------------------------------------------------
    if (!supabase.isInitialized) {
      debugPrint('$_tag Supabase not initialized, skipping Supabase migration');
      return _migrateRevenueCatOnly(
        email: email,
        previousUserId: previousUserId,
      );
    }

    // -------------------------------------------------------
    // Step 2: Supabase identity is already linked via the authResponse.
    // The caller (sign-in screen) performs the actual OAuth/link call.
    // We just verify the new session is active.
    // -------------------------------------------------------
    final newUser = supabase.client.auth.currentUser;
    final newUserId = newUser?.id;

    if (newUserId == null) {
      debugPrint('$_tag No authenticated user after sign-in, aborting');
      return MigrationResult(
        success: false,
        errorMessage: 'No authenticated user found after sign-in',
        previousUserId: previousUserId,
        entitlementAfterMigration: Entitlement.free,
      );
    }

    debugPrint('$_tag New authenticated user ID: $newUserId');

    // -------------------------------------------------------
    // Step 3: RevenueCat identity switch
    // -------------------------------------------------------
    Entitlement entitlementAfterLogin = Entitlement.free;
    try {
      entitlementAfterLogin = await _migrateRevenueCatIdentity(email);
    } catch (e) {
      debugPrint('$_tag RevenueCat migration failed (non-fatal): $e');
      // Non-fatal: user can still use the app, just might not see
      // their web subscription entitlements until next app launch.
    }

    // -------------------------------------------------------
    // Step 4: Transfer Supabase data if user ID changed
    // -------------------------------------------------------
    int fingeringsMigrated = 0;
    int progressionsMigrated = 0;
    int fingeringLikesMigrated = 0;

    if (previousUserId != null && previousUserId != newUserId) {
      debugPrint('$_tag User ID changed, transferring data...');
      try {
        final dataResult = await _transferUserData(
          client: supabase.client,
          fromUserId: previousUserId,
          toUserId: newUserId,
        );
        fingeringsMigrated = dataResult['fingerings'] ?? 0;
        progressionsMigrated = dataResult['progressions'] ?? 0;
        fingeringLikesMigrated = dataResult['fingering_likes'] ?? 0;

        debugPrint(
          '$_tag Data transfer complete: '
          '$fingeringsMigrated fingerings, '
          '$progressionsMigrated progressions, '
          '$fingeringLikesMigrated fingering likes',
        );
      } catch (e) {
        debugPrint('$_tag Data transfer failed (non-fatal): $e');
        // Non-fatal: data stays under old anonymous ID.
        // User loses access to old saves but app still works.
      }
    } else {
      debugPrint('$_tag User ID unchanged, no data transfer needed');
    }

    final result = MigrationResult(
      success: true,
      previousUserId: previousUserId,
      newUserId: newUserId,
      entitlementAfterMigration: entitlementAfterLogin,
      fingeringsMigrated: fingeringsMigrated,
      progressionsMigrated: progressionsMigrated,
      fingeringLikesMigrated: fingeringLikesMigrated,
    );

    debugPrint('$_tag Migration complete: $result');
    return result;
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  /// Migrate only RevenueCat identity when Supabase is unavailable.
  static Future<MigrationResult> _migrateRevenueCatOnly({
    required String email,
    required String? previousUserId,
  }) async {
    Entitlement entitlement = Entitlement.free;
    try {
      entitlement = await _migrateRevenueCatIdentity(email);
    } catch (e) {
      debugPrint('$_tag RevenueCat-only migration failed: $e');
      return MigrationResult(
        success: false,
        errorMessage: 'RevenueCat login failed: $e',
        previousUserId: previousUserId,
        entitlementAfterMigration: Entitlement.free,
      );
    }

    return MigrationResult(
      success: true,
      previousUserId: previousUserId,
      entitlementAfterMigration: entitlement,
    );
  }

  /// Switch RevenueCat identity from anonymous to email-based.
  ///
  /// Calls Purchases.logIn(email) which:
  /// - Creates or retrieves a RevenueCat customer with that email as app user ID
  /// - Transfers any anonymous purchases to the identified customer
  /// - Returns updated customer info with merged entitlements
  ///
  /// Then re-checks entitlements through PurchaseApi.getUserEntitlement().
  static Future<Entitlement> _migrateRevenueCatIdentity(String email) async {
    debugPrint('$_tag Logging in to RevenueCat with email: $email');

    // Purchases.logIn merges anonymous purchases into the identified user.
    // If the identified user already has purchases (e.g., from web subscription),
    // both sets of entitlements are preserved.
    final loginResult = await Purchases.logIn(email);

    debugPrint(
      '$_tag RevenueCat logIn result - '
      'created: ${loginResult.created}, '
      'active entitlements: '
      '${loginResult.customerInfo.entitlements.active.keys.toList()}',
    );

    // Re-check entitlement through the standard PurchaseApi path
    // so the result matches what the rest of the app expects.
    final entitlement = await PurchaseApi.getUserEntitlement();
    debugPrint('$_tag Entitlement after RevenueCat login: $entitlement');

    return entitlement;
  }

  /// Transfer all user-owned Supabase data from the old anonymous ID
  /// to the new authenticated ID.
  ///
  /// Tables affected:
  /// - smg_saved_fingerings (user_id column)
  /// - smg_fingering_likes (user_id column)
  /// - smg_saved_progressions (user_id column)
  ///
  /// Best-effort: if one table fails, the others still proceed.
  static Future<Map<String, int>> _transferUserData({
    required SupabaseClient client,
    required String fromUserId,
    required String toUserId,
  }) async {
    int fingeringsMigrated = 0;
    int progressionsMigrated = 0;
    int fingeringLikesMigrated = 0;

    // --- Transfer saved fingerings ---
    try {
      fingeringsMigrated = await _transferTable(
        client: client,
        table: 'smg_saved_fingerings',
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
      debugPrint('$_tag Transferred $fingeringsMigrated fingerings');
    } catch (e) {
      debugPrint('$_tag Failed to transfer fingerings: $e');
    }

    // --- Transfer fingering likes (has unique constraint) ---
    try {
      fingeringLikesMigrated = await _transferLikesTable(
        client: client,
        table: 'smg_fingering_likes',
        foreignKeyColumn: 'fingering_id',
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
      debugPrint('$_tag Transferred $fingeringLikesMigrated fingering likes');
    } catch (e) {
      debugPrint('$_tag Failed to transfer fingering likes: $e');
    }

    // --- Transfer saved progressions ---
    try {
      progressionsMigrated = await _transferTable(
        client: client,
        table: 'smg_saved_progressions',
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
      debugPrint('$_tag Transferred $progressionsMigrated progressions');
    } catch (e) {
      debugPrint('$_tag Failed to transfer progressions: $e');
    }

    return {
      'fingerings': fingeringsMigrated,
      'fingering_likes': fingeringLikesMigrated,
      'progressions': progressionsMigrated,
    };
  }

  /// Transfer rows in a single table from one user ID to another.
  ///
  /// Used for data tables (fingerings, progressions) that have no
  /// unique constraints beyond the primary key.
  static Future<int> _transferTable({
    required SupabaseClient client,
    required String table,
    required String fromUserId,
    required String toUserId,
  }) async {
    final existing = await client
        .from(table)
        .select('id')
        .eq('user_id', fromUserId);

    final count = (existing as List).length;
    if (count == 0) {
      debugPrint('$_tag No rows to transfer in $table');
      return 0;
    }

    debugPrint('$_tag Transferring $count rows in $table');

    await client
        .from(table)
        .update({'user_id': toUserId})
        .eq('user_id', fromUserId);

    return count;
  }

  /// Transfer likes table rows, handling unique constraint violations.
  ///
  /// Likes tables have a UNIQUE(user_id, fingering_id) constraint.
  /// If the authenticated user already liked the same item as the
  /// anonymous user, we must delete the anonymous duplicate first.
  static Future<int> _transferLikesTable({
    required SupabaseClient client,
    required String table,
    required String foreignKeyColumn,
    required String fromUserId,
    required String toUserId,
  }) async {
    final existing = await client
        .from(table)
        .select('id, $foreignKeyColumn')
        .eq('user_id', fromUserId);

    final count = (existing as List).length;
    if (count == 0) {
      debugPrint('$_tag No rows to transfer in $table');
      return 0;
    }

    debugPrint('$_tag Transferring $count rows in $table');

    // Deduplicate: remove anonymous likes that conflict with
    // authenticated user likes before transferring
    await _deduplicateLikes(
      client: client,
      table: table,
      foreignKeyColumn: foreignKeyColumn,
      fromUserId: fromUserId,
      toUserId: toUserId,
    );

    // Update remaining rows to new user ID
    await client
        .from(table)
        .update({'user_id': toUserId})
        .eq('user_id', fromUserId);

    return count;
  }

  /// Remove duplicate likes from the anonymous user before transferring.
  ///
  /// If both the anonymous user and the authenticated user have liked
  /// the same item, we delete the anonymous user's like to avoid
  /// unique constraint violations on (user_id, fingering_id).
  static Future<void> _deduplicateLikes({
    required SupabaseClient client,
    required String table,
    required String foreignKeyColumn,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final newUserLikes = await client
          .from(table)
          .select(foreignKeyColumn)
          .eq('user_id', toUserId);

      if ((newUserLikes as List).isEmpty) return;

      final newUserLikedIds = newUserLikes
          .map((row) => row[foreignKeyColumn] as String)
          .toList();

      // Delete anonymous user's likes that would conflict
      for (final itemId in newUserLikedIds) {
        await client
            .from(table)
            .delete()
            .eq('user_id', fromUserId)
            .eq(foreignKeyColumn, itemId);
      }

      debugPrint(
        '$_tag Deduplicated ${newUserLikedIds.length} potential '
        'conflicts in $table',
      );
    } catch (e) {
      debugPrint('$_tag Deduplication warning for $table: $e');
    }
  }

  // ============================================================
  // PUBLIC UTILITY METHODS
  // ============================================================

  /// Check if the current Supabase user is anonymous.
  static bool isCurrentUserAnonymous() {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || !supabase.isAuthenticated) {
      return true;
    }

    final user = supabase.client.auth.currentUser;
    if (user == null) return true;

    final isAnon = user.isAnonymous;
    debugPrint('$_tag isCurrentUserAnonymous: $isAnon (email: ${user.email})');
    return isAnon;
  }

  /// Sign out and revert to anonymous auth.
  ///
  /// Used when user explicitly signs out from their account.
  /// Creates a new anonymous session so the app continues to function.
  static Future<void> signOutAndRevertToAnonymous() async {
    final supabase = SupabaseService.instance;

    try {
      debugPrint('$_tag Logging out from RevenueCat');
      await Purchases.logOut();
    } catch (e) {
      debugPrint('$_tag RevenueCat logout failed (non-fatal): $e');
    }

    try {
      debugPrint('$_tag Signing out from Supabase');
      await supabase.client.auth.signOut();

      debugPrint('$_tag Creating new anonymous session');
      await supabase.client.auth.signInAnonymously();
      debugPrint('$_tag New anonymous user: ${supabase.currentUserId}');
    } catch (e) {
      debugPrint('$_tag Supabase sign-out/anonymous recovery failed: $e');
    }
  }

  /// Get the email of the currently authenticated (non-anonymous) user.
  /// Returns null if user is anonymous or not authenticated.
  static String? getAuthenticatedEmail() {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || !supabase.isAuthenticated) {
      return null;
    }

    final user = supabase.client.auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    return user.email;
  }
}
