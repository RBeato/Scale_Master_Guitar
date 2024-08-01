import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fretboard_options.dart';

class WidgetToPngExporter extends ConsumerStatefulWidget {
  final Widget child;
  final bool isDegreeSelected;

  const WidgetToPngExporter(
      {super.key, required this.isDegreeSelected, required this.child});

  @override
  _WidgetToPngExporterState createState() => _WidgetToPngExporterState();

  static _WidgetToPngExporterState? of(BuildContext context) {
    final _WidgetToPngExporterState? state =
        context.findAncestorStateOfType<_WidgetToPngExporterState>();
    return state;
  }
}

class _WidgetToPngExporterState extends ConsumerState<WidgetToPngExporter> {
  final GlobalKey _globalKey = GlobalKey();

  Future<Uint8List?> capturePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing PNG: $e');
      return null;
    }
  }

  Future<String?> savePng(Uint8List imageBytes) async {
    try {
      // Request storage permissions
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        print('Storage permission not granted');
        return null;
      }

      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final path = '${downloadsDir.path}/captured_image.png';
      final file = File(path);
      await file.writeAsBytes(imageBytes);
      print('Image saved to $path');
      return path;
    } catch (e) {
      print('Error saving PNG: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FretboardOptionButtons(widget.isDegreeSelected),
        ),
        Expanded(
          flex: 9,
          child: RepaintBoundary(key: _globalKey, child: widget.child),
        ),
      ],
    );
  }
}
