import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/fretboard_page/provider/palette_color_provider.dart';
import 'package:test/UI/fretboard_page/widget_to_png.dart';

import '../../models/chord_scale_model.dart';
import 'custom_fretboard_painter.dart';
import 'provider/fretboard_color_provider.dart';
import 'provider/note_names_visibility_provider.dart';
import 'provider/sharp_flat_selection_provider.dart';

class FretboardFull extends ConsumerStatefulWidget {
  final ChordScaleFingeringsModel fingeringsModel;

  const FretboardFull({Key? key, required this.fingeringsModel})
      : super(key: key);

  @override
  ConsumerState<FretboardFull> createState() => _FretboardFullState();
}

class _FretboardFullState extends ConsumerState<FretboardFull> {
  late List<List<bool>> dotPositions;
  late List<List<Color?>> dotColors;
  late Color selectedColor;
  int stringCount = 6;
  int fretCount = 24;

  @override
  void initState() {
    super.initState();
    dotPositions = createDotPositions(widget.fingeringsModel);
    dotColors = List.generate(
      stringCount,
      (_) => List.filled(fretCount + 1, null),
    );
    selectedColor = ref.read(paletteColorProvider);
  }

  List<List<bool>> createDotPositions(
      ChordScaleFingeringsModel fingeringsModel) {
    List<List<bool>> dotPositions = List.generate(
        stringCount, (index) => List.generate(fretCount + 1, (j) => false));

    if (fingeringsModel.scaleNotesPositions != null) {
      for (final position in fingeringsModel.scaleNotesPositions!) {
        int string = position[0] - 1;
        int fret = position[1];

        if (string >= 0 &&
            string < stringCount &&
            fret >= 0 &&
            fret <= fretCount) {
          dotPositions[string][fret] = true;
        }
      }
    }

    return dotPositions;
  }

  @override
  Widget build(BuildContext context) {
    selectedColor = ref.watch(paletteColorProvider);
    final flatSharpSelection = ref.watch(sharpFlatSelectionProvider);
    final fretboardColor = ref.watch(fretboardColorProvider);
    final hideNotes = ref.watch(noteNamesVisibilityProvider);
    const widthFactor = 3.37;
    const heightTolerance = 0.75;
    const fretTolerance = 3.2;

    return WidgetToPngExporter(
      isDegreeSelected:
          widget.fingeringsModel.scaleModel!.settings!.showScaleDegrees,
      child: LayoutBuilder(builder: (context, constraints) {
        Size size = constraints.biggest;
        print("Layout builder width ${size.width} height ${size.height}");
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: GestureDetector(
            onTapDown: (details) {
              final tapPosition = details.localPosition;

              // Rotate the touch position manually for a 90-degree clockwise rotation
              final rotatedPosition = Offset(
                tapPosition.dy,
                size.width - tapPosition.dx,
              );

              final stringHeight = size.width * heightTolerance / stringCount;
              final fretWidth = size.width * fretTolerance / fretCount;

              int string = (rotatedPosition.dy / stringHeight).floor();
              int fret = (rotatedPosition.dx / fretWidth).floor();
              print("Fret $fret String $string");

              if (string < 0 ||
                  string > stringCount ||
                  fret < 0 ||
                  fret > fretCount) {
                return;
              }

              string = string - 1; //TODO: Fix this. 6th string not working

              final updatedDotPositions = List.generate(
                dotPositions.length,
                (i) => List.generate(
                    dotPositions[i].length, (j) => dotPositions[i][j]),
              );
              updatedDotPositions[string][fret] =
                  !updatedDotPositions[string][fret];

              if (!updatedDotPositions[string][fret]) {
                dotColors[string][fret] = null;
              } else {
                dotColors[string][fret] = selectedColor;
              }

              setState(() {
                dotPositions = updatedDotPositions;
              });
            },
            child: RotatedBox(
              quarterTurns: 1,
              child: SizedBox(
                width: size.width * widthFactor, // Adjust to rotation
                height: size.width,
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  // color: Colors.pink,
                  child: CustomPaint(
                    painter: CustomFretboardPainter(
                      size: Size(size.width * 0.8, size.height),
                      stringCount: stringCount,
                      fretCount: fretCount,
                      fingeringsModel: widget.fingeringsModel,
                      dotPositions: dotPositions,
                      dotColors: dotColors,
                      flatSharpSelection: flatSharpSelection,
                      hideNotes: hideNotes,
                      fretboardColor: fretboardColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
