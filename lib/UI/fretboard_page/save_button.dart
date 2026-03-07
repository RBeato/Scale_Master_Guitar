import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:scalemasterguitar/UI/fretboard_page/widget_to_png.dart';
import 'package:scalemasterguitar/UI/paywall/unified_paywall.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/services/feature_restriction_service.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';


class SaveImageButton extends ConsumerWidget {
  const SaveImageButton({super.key});

  Future<void> _saveImage(BuildContext context) async {
    final widgetToPngExporterState = WidgetToPngExporter.of(context);
    if (widgetToPngExporterState == null) {
      debugPrint('WidgetToPngExporterState not found.');
      return;
    }

    Uint8List? pngBytes = await widgetToPngExporterState.capturePng();
    if (pngBytes == null) {
      debugPrint('Error capturing PNG image.');
      return;
    }

    try {
      // Save to temp file first, then use Gal to save to device gallery/photos
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${tempDir.path}/SMG_fretboard_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path, album: 'SMGuitar');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to Photos')),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving image')),
        );
      }
    }
  }

  void _showPaywall(BuildContext context) {
    // Capture navigator before showing SnackBar — the widget context may be
    // unmounted by the time the user taps "Upgrade" (e.g. page transition).
    final navigator = Navigator.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Upgrade to download fretboard images'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Upgrade',
          textColor: Colors.white,
          onPressed: () {
            navigator.push(
              SlideRoute(page: const UnifiedPaywall(initialTab: 0), direction: SlideDirection.fromBottom),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final canDownload = FeatureRestrictionService.canDownloadFretboard(entitlement);

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!canDownload) {
            _showPaywall(context);
            return;
          }
          _saveImage(context);
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
                Icons.download,
                size: 30,
                color: canDownload ? Colors.orangeAccent : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
