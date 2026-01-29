import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';
import 'package:scalemasterguitar/UI/fingerings_library/fingerings_library_page.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/services/feature_restriction_service.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/loaded_fingering_provider.dart';

class LibraryAccessButton extends ConsumerWidget {
  const LibraryAccessButton({super.key});

  Future<void> _openLibrary(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<SavedFingering>(
      context,
      SlideRoute(page: const FingeringsLibraryPage(), direction: SlideDirection.fromRight),
    );

    // If a fingering was returned, set the provider so the fretboard can load it
    if (result != null) {
      ref.read(loadedFingeringProvider.notifier).state = result;
    }
  }

  void _showPaywall(BuildContext context, {bool isLifetime = false}) {
    final message = isLifetime
        ? 'Fingerings Library is not included in your lifetime purchase'
        : 'Subscribe to access your fingerings library';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isLifetime ? Colors.orange : Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Subscribe',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              SlideRoute(page: const UnifiedPaywall(initialTab: 1), direction: SlideDirection.fromBottom),
            );
          },
        ),
      ),
    );
  }

  void _showNotConnected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cloud service not available. Check your connection.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final canAccessLibrary =
        FeatureRestrictionService.canAccessFingeringsLibrary(entitlement);
    final isLifetime = FeatureRestrictionService.isLifetimeUser(entitlement);
    final supabase = SupabaseService.instance;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!supabase.isInitialized) {
            _showNotConnected(context);
            return;
          }

          if (!canAccessLibrary) {
            _showPaywall(context, isLifetime: isLifetime);
            return;
          }

          _openLibrary(context, ref);
        },
        child: RotatedBox(
          quarterTurns: 1,
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black38,
            ),
            child: Center(
              child: Icon(
                Icons.library_music,
                size: 30,
                color: canAccessLibrary ? Colors.greenAccent : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
