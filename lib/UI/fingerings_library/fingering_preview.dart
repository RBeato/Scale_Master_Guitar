import 'package:flutter/material.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';

/// A simplified fretboard preview widget for displaying saved fingerings
/// in library cards and lists
class FingeringPreview extends StatelessWidget {
  final SavedFingering fingering;
  final double width;
  final double height;
  final bool showFretNumbers;

  const FingeringPreview({
    super.key,
    required this.fingering,
    this.width = 200,
    this.height = 80,
    this.showFretNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fingering.getFretboardColorAsColor() ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          size: Size(width, height),
          painter: _FingeringPreviewPainter(
            dotPositions: fingering.dotPositions,
            dotColors: fingering.getDotColorsAsColors(),
            showFretNumbers: showFretNumbers,
          ),
        ),
      ),
    );
  }
}

/// Preview painter that renders a compact view of the fingering
class _FingeringPreviewPainter extends CustomPainter {
  final List<List<bool>> dotPositions;
  final List<List<Color?>> dotColors;
  final bool showFretNumbers;

  // Find the range of frets with dots for optimal display
  late final int minFret;
  late final int maxFret;
  late final int displayFretCount;

  _FingeringPreviewPainter({
    required this.dotPositions,
    required this.dotColors,
    this.showFretNumbers = false,
  }) {
    // Calculate the range of frets that have dots
    int min = 24;
    int max = 0;

    for (int string = 0; string < dotPositions.length; string++) {
      for (int fret = 0; fret < dotPositions[string].length; fret++) {
        if (dotPositions[string][fret]) {
          if (fret < min) min = fret;
          if (fret > max) max = fret;
        }
      }
    }

    // Handle case with no dots
    if (min > max) {
      minFret = 0;
      maxFret = 12;
    } else {
      // Add some padding and ensure at least 5 frets are shown
      minFret = (min - 1).clamp(0, 20);
      maxFret = (max + 1).clamp(minFret + 4, 24);
    }

    displayFretCount = maxFret - minFret + 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const int stringCount = 6;
    final double fretWidth = size.width / displayFretCount;
    final double stringHeight = size.height / (stringCount + 1);
    final double dotRadius = (fretWidth.clamp(8, 20) / 2.5).clamp(3.0, 8.0);

    final neckPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.0;

    // Draw fret lines
    for (int i = 0; i <= displayFretCount; i++) {
      final x = i * fretWidth;
      final isNut = (minFret + i) == 0;

      neckPaint.strokeWidth = isNut ? 3.0 : 1.0;
      neckPaint.color = isNut ? Colors.grey[400]! : Colors.grey[600]!;

      canvas.drawLine(
        Offset(x, stringHeight * 0.5),
        Offset(x, size.height - stringHeight * 0.5),
        neckPaint,
      );
    }

    // Draw string lines
    neckPaint.strokeWidth = 1.0;
    neckPaint.color = Colors.grey[500]!;
    for (int i = 0; i < stringCount; i++) {
      final y = stringHeight * (i + 1);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        neckPaint,
      );
    }

    // Draw dots
    for (int string = 0; string < stringCount; string++) {
      for (int displayFret = 0; displayFret < displayFretCount; displayFret++) {
        final actualFret = minFret + displayFret;
        if (actualFret >= dotPositions[string].length) continue;

        if (dotPositions[string][actualFret]) {
          final Color dotColor =
              dotColors[string][actualFret] ?? Colors.blueGrey;

          final dotPaint = Paint()
            ..color = dotColor
            ..style = PaintingStyle.fill;

          final x = displayFret * fretWidth + fretWidth / 2;
          final y = stringHeight * (string + 1);

          canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
        }
      }
    }

    // Draw fret numbers if enabled
    if (showFretNumbers && minFret > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${minFret + 1}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_FingeringPreviewPainter oldDelegate) {
    return oldDelegate.dotPositions != dotPositions ||
        oldDelegate.dotColors != dotColors;
  }
}
