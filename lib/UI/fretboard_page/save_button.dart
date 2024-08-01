import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:test/UI/fretboard_page/widget_to_png.dart';

class SaveImageButton extends StatelessWidget {
  const SaveImageButton({super.key});

  Future<void> _requestStoragePermission(BuildContext context) async {
    // Request permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      _saveImage(context);
    } else {
      print('Storage permission denied.');
    }
  }

  Future<void> _saveImage(BuildContext context) async {
    // Find the WidgetToPngExporterState
    final widgetToPngExporterState = WidgetToPngExporter.of(context);
    if (widgetToPngExporterState != null) {
      // Call the capturePng method
      Uint8List? pngBytes = await widgetToPngExporterState.capturePng();
      if (pngBytes != null) {
        try {
          // Get the directory for saving files
          Directory? downloadsDirectory = await getExternalStorageDirectory();
          String? directoryPath;

          if (downloadsDirectory != null) {
            directoryPath = '/storage/emulated/0/Download';
          } else {
            // Fallback to application directory if Downloads directory is not accessible
            downloadsDirectory = await getApplicationDocumentsDirectory();
            directoryPath = downloadsDirectory.path;
          }

          String filePath = '$directoryPath/SMG_image.png';

          // Write the PNG bytes to the file
          await File(filePath).writeAsBytes(pngBytes);

          print('PNG image saved: $filePath');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to $filePath')),
          );
        } catch (e) {
          print('Error saving PNG image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving image')),
          );
        }
      } else {
        print('Error capturing PNG image.');
      }
    } else {
      print('WidgetToPngExporterState not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {}, //=>_requestStoragePermission(context),
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
