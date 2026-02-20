import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart in-app review service that requests reviews at optimal moments.
///
/// Triggers the native review dialog only when the user is likely engaged:
/// - Minimum app opens reached
/// - Minimum key actions completed
/// - Minimum days since install
/// - Cooldown between requests respected
class InAppReviewService {
  static final InAppReviewService _instance = InAppReviewService._internal();
  factory InAppReviewService() => _instance;
  InAppReviewService._internal();

  static const String _keyAppOpens = 'review_app_opens';
  static const String _keyKeyActions = 'review_key_actions';
  static const String _keyFirstOpen = 'review_first_open';
  static const String _keyLastRequest = 'review_last_request';
  static const String _keyRequestCount = 'review_request_count';

  // Thresholds - more aggressive for Scale Master since rating is 1.0
  static const int _minAppOpens = 3;
  static const int _minKeyActions = 5;
  static const int _minDaysSinceInstall = 2;
  static const int _cooldownDays = 45; // Ask again sooner
  static const int _maxRequestsPerYear = 4;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Call this in main() during app initialization.
  Future<void> trackAppOpen() async {
    final prefs = await SharedPreferences.getInstance();

    // Set first open date if not set
    if (!prefs.containsKey(_keyFirstOpen)) {
      await prefs.setString(_keyFirstOpen, DateTime.now().toIso8601String());
    }

    // Increment app opens
    final opens = (prefs.getInt(_keyAppOpens) ?? 0) + 1;
    await prefs.setInt(_keyAppOpens, opens);
    debugPrint('📊 [ReviewService] App open #$opens tracked');
  }

  /// Call this after positive user moments (exploring scales, saving fingerings, etc.)
  Future<void> trackKeyAction() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = (prefs.getInt(_keyKeyActions) ?? 0) + 1;
    await prefs.setInt(_keyKeyActions, actions);
    debugPrint('📊 [ReviewService] Key action #$actions tracked');
  }

  /// Request a review if all conditions are met.
  /// Call after positive moments like saving fingerings or exploring multiple scales.
  Future<bool> requestReviewIfReady() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final opens = prefs.getInt(_keyAppOpens) ?? 0;
      final actions = prefs.getInt(_keyKeyActions) ?? 0;
      final requestCount = prefs.getInt(_keyRequestCount) ?? 0;

      // Check first open date
      final firstOpenStr = prefs.getString(_keyFirstOpen);
      if (firstOpenStr == null) return false;
      final firstOpen = DateTime.parse(firstOpenStr);
      final daysSinceInstall = DateTime.now().difference(firstOpen).inDays;

      // Check cooldown
      final lastRequestStr = prefs.getString(_keyLastRequest);
      if (lastRequestStr != null) {
        final lastRequest = DateTime.parse(lastRequestStr);
        final daysSinceLastRequest =
            DateTime.now().difference(lastRequest).inDays;
        if (daysSinceLastRequest < _cooldownDays) {
          debugPrint(
              '📊 [ReviewService] Cooldown active ($daysSinceLastRequest/$_cooldownDays days)');
          return false;
        }
      }

      // Check all thresholds
      if (opens < _minAppOpens) {
        debugPrint('📊 [ReviewService] Not enough opens ($opens/$_minAppOpens)');
        return false;
      }
      if (actions < _minKeyActions) {
        debugPrint(
            '📊 [ReviewService] Not enough actions ($actions/$_minKeyActions)');
        return false;
      }
      if (daysSinceInstall < _minDaysSinceInstall) {
        debugPrint(
            '📊 [ReviewService] Too early ($daysSinceInstall/$_minDaysSinceInstall days)');
        return false;
      }
      if (requestCount >= _maxRequestsPerYear) {
        debugPrint(
            '📊 [ReviewService] Max requests reached ($requestCount/$_maxRequestsPerYear)');
        return false;
      }

      // All conditions met - request review
      if (await _inAppReview.isAvailable()) {
        debugPrint('⭐ [ReviewService] Requesting in-app review!');
        await _inAppReview.requestReview();

        // Update tracking
        await prefs.setString(
            _keyLastRequest, DateTime.now().toIso8601String());
        await prefs.setInt(_keyRequestCount, requestCount + 1);
        return true;
      } else {
        debugPrint('📊 [ReviewService] In-app review not available');
        return false;
      }
    } catch (e) {
      debugPrint('📊 [ReviewService] Error requesting review: $e');
      return false;
    }
  }

  /// Opens the app store listing directly. Use for a "Rate Us" button in settings.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6746448058',
      );
    } catch (e) {
      debugPrint('📊 [ReviewService] Error opening store listing: $e');
    }
  }
}
