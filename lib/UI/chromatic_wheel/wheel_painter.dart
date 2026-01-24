import 'package:flutter/material.dart';
import 'package:scalemasterguitar/constants/music_constants.dart';
import 'dart:math' as math;
import '../../constants/color_constants.dart';
import '../../constants/app_theme.dart';

class WheelPainter extends CustomPainter {
  final double rotation;
  final List chromaticNotes;
  final List scaleIntervals;
  final String topNote;

  WheelPainter(
      this.rotation, this.chromaticNotes, this.scaleIntervals, this.topNote);

  /// Checks if a raw note name (like "A♯/B♭") matches the topNote (like "A♯" or "B♭")
  bool _noteMatchesTopNote(String rawNoteName, String topNote) {
    // Direct match (for natural notes like "C", "D", etc.)
    if (rawNoteName == topNote) return true;
    
    // Check compound notes (like "A♯/B♭")
    if (rawNoteName.contains('/')) {
      final parts = rawNoteName.split('/');
      return parts[0] == topNote || parts[1] == topNote;
    }
    
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double outerRadius = size.width * 0.46; // 90% diameter, so radius is 45%
    double innerRadius = size.width * 0.37; // knob radius as a proportion

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
          fontSize: size.width * 0.06,
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

    // Knob design (inner wheel) - matches background color
    Paint knobPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, knobPaint);

    // Draw the inner note containers and notes
    double containerRadius = size.width * 0.07;
    double containerDistance = innerRadius * 0.8;
    double containerFontSize = size.width * 0.045;
    for (int i = 0; i < MusicConstants.notesWithFlatsAndSharps.length; i++) {
      // debugPrint(
      //     "i=$i, MusicConstants.notesWithFlatsAndSharps[i]: ${MusicConstants.notesWithFlatsAndSharps[i]}, ");
      double angle =
          2 * math.pi * i / MusicConstants.notesWithFlatsAndSharps.length +
              rotation;

      // Position for the note container
      Offset containerPosition = Offset(
        center.dx + containerDistance * math.cos(angle),
        center.dy + containerDistance * math.sin(angle),
      );

      // Draw circular container - slightly lighter than background for contrast
      Paint containerPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill;
      canvas.drawCircle(containerPosition, containerRadius, containerPaint);

      // Draw subtle border
      Paint borderPaint = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(containerPosition, containerRadius, borderPaint);

      //   // Text
      //   // Offset notePosition = Offset(
      //   //   containerPosition.dx - 10, // Centering the text inside the container
      //   //   containerPosition.dy - 10,
      //   // );
      // Get the raw note name and check if it matches topNote
      String rawNoteName = MusicConstants.notesWithFlatsAndSharps[i];
      bool isSelectedNote = _noteMatchesTopNote(rawNoteName, topNote);
      
      textPainter.text = TextSpan(
        text: rawNoteName,
        style: TextStyle(
            color: isSelectedNote ? Colors.orangeAccent : Colors.white,
            fontSize: containerFontSize),
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
