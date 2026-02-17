import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

/// Banner widget — shows RiffRoutine cross-marketing for free-tier users.
/// Premium users (subscription or lifetime) see nothing.
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  static const String _riffroutineUrl = 'https://www.riffroutine.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);

    // Hide banner for premium users
    if (entitlement.isPremium) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _launchUrl(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D1B69), Color(0xFF4A2D8A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/riff_routine_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text
            const Expanded(
              child: Text(
                'Level up your guitar skills at RiffRoutine.com',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'Visit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse(_riffroutineUrl);

    for (final mode in [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
      LaunchMode.inAppWebView,
    ]) {
      try {
        final launched = await launchUrl(uri, mode: mode);
        if (launched) return;
      } catch (_) {
        // Try next mode
      }
    }
  }
}
