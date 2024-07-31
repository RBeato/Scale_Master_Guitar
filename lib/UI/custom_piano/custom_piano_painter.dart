import 'package:flutter/material.dart';

class CustomPianoPainter extends CustomPainter {
  final int numberOfOctaves;
  final List<String> whiteKeyNotes;
  final List<String> blackKeyNotes;
  final List<String> scaleNotes;
  final double whiteKeyWidth;
  final double blackKeyWidth;
  final List<String> pressedKeys;
  final Color? containerColor;

  CustomPianoPainter({
    required this.numberOfOctaves,
    required this.whiteKeyNotes,
    required this.blackKeyNotes,
    required this.scaleNotes,
    required this.whiteKeyWidth,
    required this.blackKeyWidth,
    required this.pressedKeys,
    required this.containerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint whiteKeyPaint = Paint()..color = Colors.white;
    Paint blackKeyPaint = Paint()..color = Colors.black;
    Paint shadowPaint = Paint()..color = Colors.grey.withOpacity(0.5);

    // Draw white keys
    for (int octave = 0; octave < numberOfOctaves; octave++) {
      for (int i = 0; i < 7; i++) {
        String noteName = '${whiteKeyNotes[i]}${octave + 1}';
        bool isPressed = pressedKeys.contains(noteName);
        Color color =
            scaleNotes.contains(noteName) ? containerColor! : Colors.white;
        whiteKeyPaint.color = color;
        double left = octave * 7 * whiteKeyWidth + i * whiteKeyWidth;

        // Draw shadow if pressed
        if (isPressed) {
          canvas.drawRect(
            Rect.fromLTWH(left + 2, 2, whiteKeyWidth - 4, size.height - 4),
            shadowPaint,
          );
        }

        // Draw key
        canvas.drawRect(
            Rect.fromLTWH(left, 0, whiteKeyWidth, size.height), whiteKeyPaint);

        // Draw key border
        canvas.drawLine(
          Offset(left, 0),
          Offset(left, size.height),
          Paint()..color = Colors.black,
        );

        // Draw note label
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: noteName,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: whiteKeyWidth);
        textPainter.paint(
            canvas,
            Offset(left + whiteKeyWidth / 2 - textPainter.width / 2,
                size.height - 20));
      }
    }

    // Draw black keys
    List<double> blackKeyOffsets = [
      whiteKeyWidth - blackKeyWidth / 2,
      whiteKeyWidth * 2 - blackKeyWidth / 2,
      whiteKeyWidth * 4 - blackKeyWidth / 2,
      whiteKeyWidth * 5 - blackKeyWidth / 2,
      whiteKeyWidth * 6 - blackKeyWidth / 2,
    ];

    for (int octave = 0; octave < numberOfOctaves; octave++) {
      for (int i = 0; i < blackKeyNotes.length; i++) {
        String noteName = blackKeyNotes[i] + (octave + 1).toString();
        bool isPressed = pressedKeys.contains(noteName);
        Color color =
            scaleNotes.contains(noteName) ? containerColor! : Colors.black;
        blackKeyPaint.color = color;
        double left = octave * 7 * whiteKeyWidth + blackKeyOffsets[i];

        // Draw shadow if pressed
        if (isPressed) {
          canvas.drawRect(
            Rect.fromLTWH(
                left + 2, 2, blackKeyWidth - 4, size.height * 0.6 - 4),
            shadowPaint,
          );
        }

        // Draw key
        canvas.drawRect(
            Rect.fromLTWH(left, 0, blackKeyWidth, size.height * 0.6),
            blackKeyPaint);

        // Draw note label
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: noteName,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: blackKeyWidth);
        textPainter.paint(
            canvas,
            Offset(left + blackKeyWidth / 2 - textPainter.width / 2,
                size.height * 0.6 - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
