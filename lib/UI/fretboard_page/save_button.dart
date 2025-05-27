import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:scalemasterguitar/UI/fretboard_page/widget_to_png.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:path/path.dart'
    as path; // Import path package for file handling

import '../../revenue_cat_purchase_flutter/entitlement.dart';

class SaveImageButton extends ConsumerWidget {
  const SaveImageButton({super.key});

  Future<void> _requestStoragePermission(BuildContext context) async {
    // Request permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      _saveImage(context);
    } else {
      debugPrint('Storage permission denied.');
    }
  }

  // Helper function to check if Scoped Storage is required
  Future<bool> _isScopedStorageRequired() async {
    // For Android 11+ (API level 30 and above)
    return (Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt! >= 30);
  }

  Future<void> _saveImage(BuildContext context) async {
    debugPrint('Starting the saveImage process...');
    // Request storage permissions
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      debugPrint('Storage permission denied.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage permission is required to save images')),
      );
      return;
    } else {
      debugPrint('Storage permission granted.');
    }

    // Find the WidgetToPngExporterState
    final widgetToPngExporterState = WidgetToPngExporter.of(context);
    if (widgetToPngExporterState == null) {
      debugPrint('WidgetToPngExporterState not found.');
      return;
    }

    // Capture PNG bytes
    Uint8List? pngBytes = await widgetToPngExporterState.capturePng();
    if (pngBytes == null) {
      debugPrint('Error capturing PNG image.');
      return;
    } else {
      debugPrint('PNG image captured successfully. Byte size: ${pngBytes.length}');
    }

    try {
      // Use the Downloads directory
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        // For Android, get the Downloads directory
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else {
        // For iOS or other platforms
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (!await downloadsDirectory.exists()) {
        debugPrint('Could not retrieve a valid Downloads directory.');
        return;
      }

      // Generate a unique filename with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath =
          path.join(downloadsDirectory.path, 'SMG_image_$timestamp.png');
      debugPrint('File path set: $filePath');

      // Write the PNG bytes to the file
      debugPrint('Attempting to write PNG bytes to file...');
      File file = File(filePath);
      await file.writeAsBytes(pngBytes);
      debugPrint('PNG image saved successfully: $filePath');

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to $filePath')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving PNG image: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving image')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final entitlement = ref.watch(revenueCatProvider);
    //TODO: Revert this
    const entitlement = Entitlement.premium;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: entitlement == Entitlement.free
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Upgrade required to use this feature.')),
                );
              }
            : () => _requestStoragePermission(context),
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
