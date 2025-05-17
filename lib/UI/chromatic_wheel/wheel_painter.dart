import 'package:flutter/material.dart';
import 'package:test/constants/music_constants.dart';
import 'dart:math' as math;
import '../../constants/color_constants.dart';

class WheelPainter extends CustomPainter {
  final double rotation;
  final List chromaticNotes;
  final List scaleIntervals;
  final String topNote;

  WheelPainter(
      this.rotation, this.chromaticNotes, this.scaleIntervals, this.topNote);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double innerRadius = size.width / 2.8; // Radius for the knob
    double outerRadius = size.width / 2.2; // Adjusted for visibility

    Paint outerWheelPaint = Paint()..color = Colors.transparent;
    canvas.drawCircle(center, outerRadius, outerWheelPaint);

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    Color getDegreeColor(String degree, i) {
      return scaleIntervals[i] != null
          ? ConstantColors.scaleColorMap[degree]
          : Colors.grey.withOpacity(0.3);
    }

    for (int i = 0; i < chromaticNotes.length; i++) {
      // debugPrint(
      //     "i=$i, ${getDegreeColor(chromaticNotes[i], i)}, null:${scaleIntervals[i] == null}");

      double angle = 2 * math.pi * i / chromaticNotes.length - math.pi / 2;
      textPainter.text = TextSpan(
        text: chromaticNotes[i],
        style: TextStyle(
          fontWeight:
              scaleIntervals[i] != null ? FontWeight.bold : FontWeight.normal,
          color: getDegreeColor(chromaticNotes[i], i), // Colors.grey,
          fontSize: 20,
        ),
      );
      textPainter.layout();
      Size textSize = textPainter.size;
      Offset valuePosition = Offset(
        center.dx + outerRadius * math.cos(angle) - textSize.width / 2,
        center.dy + outerRadius * math.sin(angle) - textSize.height / 2,
      );
      textPainter.paint(canvas, valuePosition);
    }

    // // Knob design (inner wheel)
    Paint knobPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [Colors.grey[700]!, Colors.black],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawCircle(center, innerRadius, knobPaint);

    for (int i = 0; i < MusicConstants.notesWithFlatsAndSharps.length; i++) {
      // debugPrint(
      //     "i=$i, MusicConstants.notesWithFlatsAndSharps[i]: ${MusicConstants.notesWithFlatsAndSharps[i]}, ");
      double angle =
          2 * math.pi * i / MusicConstants.notesWithFlatsAndSharps.length +
              rotation;

      // Position for the note container
      Offset containerPosition = Offset(
        center.dx + innerRadius * 0.8 * math.cos(angle),
        center.dy + innerRadius * 0.8 * math.sin(angle),
      );

      //   // Draw 3D-looking circular container
      Paint containerPaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [Colors.grey[400]!, Colors.grey[600]!],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromCircle(center: containerPosition, radius: 10));
      canvas.drawCircle(
          containerPosition, 20, containerPaint); // Adjust radius as needed

      // Draw shadow for 3D effect
      Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(containerPosition, 20, shadowPaint);

      //   // Text
      //   // Offset notePosition = Offset(
      //   //   containerPosition.dx - 10, // Centering the text inside the container
      //   //   containerPosition.dy - 10,
      //   // );
      textPainter.text = TextSpan(
        text: MusicConstants.notesWithFlatsAndSharps[i],

        style: TextStyle(
            color: MusicConstants.notesWithFlatsAndSharps[i] == topNote
                ? Colors.orangeAccent
                : Colors.white,
            fontSize: 18), //Color of inside notes
      );
      textPainter.layout();
      Size textSize = textPainter.size;
      Offset textCenter = Offset(
        containerPosition.dx - textSize.width / 2,
        containerPosition.dy - textSize.height / 2,
      );
      textPainter.paint(canvas, textCenter);
    }
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) => true;
}
