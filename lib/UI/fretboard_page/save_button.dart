import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:scalemasterguitar/UI/fretboard_page/widget_to_png.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/services/feature_restriction_service.dart';


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
      // Save to temp directory, then share via native share sheet
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${tempDir.path}/SMG_fretboard_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Scale Master Guitar - Fretboard',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);
    final canDownload = FeatureRestrictionService.canDownloadFretboard(entitlement);

    // Only show download button to premium users who can actually use it
    if (!canDownload) {
      return const SizedBox.shrink(); // Hide button for free users
    }

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _saveImage(context),
        child: RotatedBox(
          quarterTurns: 1,
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20), // Adjust border radius as needed
              color: Colors.black38,
            ),
            child: const Center(
              child: Icon(
                Icons.download,
                size: 30,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
