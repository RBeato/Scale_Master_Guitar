// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

// class WidgetToPngExporter extends StatefulWidget {
//   final Widget child;

//   const WidgetToPngExporter({Key? key, required this.child}) : super(key: key);

//   @override
//   _WidgetToPngExporterState createState() => _WidgetToPngExporterState();
// }

// class _WidgetToPngExporterState extends State<WidgetToPngExporter> {
//   final GlobalKey _globalKey = GlobalKey();

//   Future<Uint8List?> capturePng() async {
//     try {
//       // Render the widget to a raster layer.
//       RenderRepaintBoundary boundary = _globalKey.currentContext!
//           .findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(
//           pixelRatio: 3.0); // Adjust pixelRatio as needed for image quality.

//       // Convert the image to PNG format.
//       ByteData? byteData =
//           await image.toByteData(format: ui.ImageByteFormat.png);
//       return byteData?.buffer.asUint8List();
//     } catch (e) {
//       print('Error capturing PNG: $e');
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RepaintBoundary(
//       key: _globalKey,
//       child: widget.child,
//     );
//   }
// }
