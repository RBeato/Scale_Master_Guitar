import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/fretboard_state_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/fretboard_color_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/note_names_visibility_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/sharp_flat_selection_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/save_fingering_dialog.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/services/feature_restriction_service.dart';
import 'package:scalemasterguitar/services/supabase_service.dart';

class SaveToLibraryButton extends ConsumerWidget {
  const SaveToLibraryButton({super.key});

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final fretboardState = ref.read(fretboardEditStateProvider);
    final sharpFlat = ref.read(sharpFlatSelectionProvider);
    final showNoteNames = ref.read(noteNamesVisibilityProvider);
    final fretboardColor = ref.read(fretboardColorProvider);

    // Check if there are any dots to save
    if (!fretboardState.hasDots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some notes to the fretboard before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SaveFingeringDialog(
        dotPositions: fretboardState.dotPositions,
        dotColors: fretboardState.dotColors,
        sharpFlatPreference: sharpFlat?.name,
        showNoteNames: !showNoteNames, // Provider stores "hide" state, invert for "show"
        fretboardColor: fretboardColor,
      ),
    );
  }

  void _showPaywall(BuildContext context, {bool isLifetime = false}) {
    final message = isLifetime
        ? 'Fingerings Library is not included in your lifetime purchase'
        : 'Subscribe to save fingerings to your library';

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

          _showSaveDialog(context, ref);
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
                Icons.cloud_upload_outlined,
                size: 30,
                color: canAccessLibrary ? Colors.lightBlueAccent : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
