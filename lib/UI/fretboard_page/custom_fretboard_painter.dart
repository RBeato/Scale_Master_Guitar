import 'package:flutter/material.dart';
import 'package:test/UI/fretboard_page/provider/sharp_flat_selection_provider.dart';

import '../../../constants/fretboard_notes.dart';
import '../../../models/chord_scale_model.dart';
import '../../constants/roman_numeral_converter.dart';

class CustomFretboardPainter extends CustomPainter {
  final int stringCount;
  final int fretCount;
  final ChordScaleFingeringsModel fingeringsModel;

  final List<List<bool>> dotPositions;
  final List<List<Color?>> dotColors;
  final FretboardSharpFlat? flatSharpSelection;
  final Size size;
  final bool hideNotes;
  final Color fretboardColor;

  CustomFretboardPainter({
    required this.stringCount,
    required this.fretCount,
    required this.fingeringsModel,
    required this.dotPositions,
    required this.dotColors,
    required this.flatSharpSelection,
    required this.size,
    required this.hideNotes,
    required this.fretboardColor,
  });

  static TextStyle textStyle =
      const TextStyle(fontSize: 10.0, color: Colors.white);

  @override
  void paint(Canvas canvas, Size size) {
    var neckPaint = Paint()
      ..color = fretboardColor
      ..strokeWidth = 2.0;

    debugPrint(
        "inside customPainter width ${this.size.width} height ${this.size.height}");

    double fretWidth = this.size.width * 4 / (fretCount);
    double stringHeight = this.size.width / (stringCount);
    double dotRadius = fretWidth / 2.7;

    for (int i = 1; i <= fretCount + 1; i++) {
      double x1 = i * fretWidth;
      double x2 = (i + 1) * fretWidth;
      int p = i + 1;

      double centerX = (x1 + x2) / 2;

      neckPaint.strokeWidth = (i == 1) ? 8.0 : 2.0; //draw nut at 1st

      //Draw Fret lines
      canvas.drawLine(
        Offset(x1, 0),
        Offset(x1, this.size.width * 0.83),
        neckPaint,
      );

      //Draw roman numerals
      if ([3, 5, 7, 9, 12, 15, 17, 19, 21, 24].contains(p)) {
        final romanNumeral = RomanNumeralConverter.convertToFretRomanNumeral(p);
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: romanNumeral,
            style: const TextStyle(color: Colors.orange, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2) + fretWidth,
              this.size.width * 0.92),
        );
      }
    }

    //Draw string lines
    for (int i = 0; i < stringCount; i++) {
      double y = i * stringHeight;
      canvas.drawLine(
          Offset(fretWidth, y), Offset(this.size.width * 4.17, y), neckPaint);
    }

    //Draw Dots
    for (int string = 0; string < stringCount; string++) {
      for (int fret = 0; fret <= fretCount; fret++) {
        if (dotPositions[string][fret]) {
          Color dotColor = dotColors[string][fret] ?? Colors.blueGrey;
          var dotPaint = Paint()
            ..color = fret == 0 ? dotColor.withRed(160) : dotColor
            ..style = PaintingStyle.fill;

          canvas.drawCircle(
            Offset(fretWidth * fret + fretWidth / 2, stringHeight * string),
            dotRadius,
            dotPaint,
          );
        }
      }
    }

    //Draw notes names
    if (!hideNotes) {
      for (int string = 0; string < stringCount; string++) {
        for (int fret = 0; fret <= fretCount; fret++) {
          TextPainter textPainter = TextPainter(
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            textScaleFactor: 1.5,
          );

          double x = fret * fretWidth;
          double y = string * stringHeight;

          double textX = x + fretWidth / 2;
          double textY = y;

          var noteName = fingeringsModel.scaleModel!.scaleNotesNames
                  .contains(fretboardNotesNamesSharps[string][fret])
              ? fretboardNotesNamesSharps[string][fret]
              : fretboardNotesNamesFlats[string][fret];

          final showDegrees =
              fingeringsModel.scaleModel!.settings!.showScaleDegrees == true;

          String? degree;
          if (showDegrees) {
            degree = fingeringsModel
                    .scaleDegreesPositionsMap!["${string + 1},$fret"] ??
                '';
          }

          //Create text label for dots
          String labelText = showDegrees
              ? degree!
              : flatSharpSelection == null
                  ? noteName
                  : flatSharpSelection == FretboardSharpFlat.sharps
                      ? fretboardNotesNamesSharps[string][fret]
                      : fretboardNotesNamesFlats[string][fret];

          // Calculate the max font size that fits within the dot
          double maxFontSize = dotRadius; // Adjust as needed
          TextStyle dynamicTextStyle =
              textStyle.copyWith(fontSize: maxFontSize - 3);

          textPainter.text = TextSpan(text: labelText, style: dynamicTextStyle);
          textPainter.layout();

          textPainter.paint(
            canvas,
            Offset(
                textX - textPainter.width / 2, textY - textPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomFretboardPainter oldDelegate) {
    for (int i = 0; i < stringCount; i++) {
      for (int j = 0; j < fretCount + 1; j++) {
        if (oldDelegate.dotPositions[i][j] != dotPositions[i][j]) {
          return true;
        }
      }
    }
    if (oldDelegate.flatSharpSelection != flatSharpSelection) {
      return true;
    }
    if (oldDelegate.hideNotes != hideNotes) {
      return true;
    }
    if (oldDelegate.fretboardColor != fretboardColor) {
      return true;
    }
    return false;
  }
}
