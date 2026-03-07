import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/palette_color_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/fretboard_state_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/loaded_fingering_provider.dart';
import 'package:scalemasterguitar/UI/fretboard_page/widget_to_png.dart';
import 'package:scalemasterguitar/models/saved_fingering.dart';

import '../../models/chord_scale_model.dart';
import '../../providers/fretboard_notes_provider.dart';
import '../../providers/tuning_provider.dart';
import 'custom_fretboard_painter.dart';
import 'provider/fretboard_color_provider.dart';
import 'provider/note_names_visibility_provider.dart';
import 'provider/sharp_flat_selection_provider.dart';

class FretboardFull extends ConsumerStatefulWidget {
  final ChordScaleFingeringsModel fingeringsModel;

  const FretboardFull({super.key, required this.fingeringsModel});

  @override
  ConsumerState<FretboardFull> createState() => _FretboardFullState();
}

class _FretboardFullState extends ConsumerState<FretboardFull> {
  late List<List<bool>> dotPositions;
  late List<List<Color?>> dotColors;
  late Color selectedColor;
  late int stringCount;
  late int fretCount;

  @override
  void initState() {
    super.initState();
    final tuning = ref.read(tuningProvider);
    stringCount = tuning.stringCount;
    fretCount = tuning.fretCount;
    dotPositions = createDotPositions(widget.fingeringsModel);
    dotColors = List.generate(
      stringCount,
      (_) => List.filled(fretCount + 1, null),
    );
    selectedColor = ref.read(paletteColorProvider);

    // Sync initial state to provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncStateToProvider();
    });
  }

  /// Sync current fretboard state to provider for save functionality
  void _syncStateToProvider() {
    ref.read(fretboardEditStateProvider.notifier).updateDotsAndColors(
          dotPositions,
          dotColors,
        );
  }

  /// Render a polished horizontal fretboard image with branding.
  Future<Uint8List?> _renderFullFretboard({
    required FretboardSharpFlat? flatSharpSelection,
    required Color fretboardColor,
    required bool hideNotes,
    required List<List<String>> notesSharps,
    required List<List<String>> notesFlats,
  }) async {
    try {
      const double pixelRatio = 3.0;
      const double baseWidth = 400.0;
      const double pad = 30.0;

      final painterSize = Size(baseWidth * 0.8, baseWidth);
      final double pw = painterSize.width; // 320

      // Painter geometry
      final double fretWidth = pw * 4 / fretCount;
      final double dotRadius = fretWidth / 2.7;

      // Fretboard content bounds (horizontal, no rotation)
      final double contentW = math.max(
        (fretCount + 1) * fretWidth,
        pw * 4.17,
      );
      final double yOvershoot = dotRadius + 5;
      final double contentH = yOvershoot + pw * 0.92 + 20;

      // Layout sections
      const double headerH = 60.0;
      const double gap = 16.0;
      const double footerH = 30.0;

      final double totalW = contentW + pad * 2;
      final double totalH =
          pad + headerH + gap + contentH + gap + footerH + pad;

      // --- Load logo ---
      ui.Image? logoImage;
      try {
        final logoData =
            await rootBundle.load('assets/images/smg_icon.png');
        final logoBytes = logoData.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(
          logoBytes,
          targetWidth: 150,
          targetHeight: 150,
        );
        final frame = await codec.getNextFrame();
        logoImage = frame.image;
      } catch (e) {
        debugPrint('Could not load logo: $e');
      }

      // --- Scale name ---
      final scaleModel = widget.fingeringsModel.scaleModel;
      String scaleName = '';
      if (scaleModel != null) {
        final key = scaleModel.parentScaleKey;
        final name = scaleModel.scale ?? '';
        scaleName = '$key $name'.trim();
      }

      final painter = CustomFretboardPainter(
        size: painterSize,
        stringCount: stringCount,
        fretCount: fretCount,
        fingeringsModel: widget.fingeringsModel,
        dotPositions: dotPositions,
        dotColors: dotColors,
        flatSharpSelection: flatSharpSelection,
        hideNotes: hideNotes,
        fretboardColor: fretboardColor,
        notesSharps: notesSharps,
        notesFlats: notesFlats,
      );

      final recorder = ui.PictureRecorder();
      final canvas =
          Canvas(recorder, Rect.fromLTWH(0, 0, totalW * pixelRatio, totalH * pixelRatio));
      // Scale canvas so logical coordinates map to high-res pixels
      canvas.scale(pixelRatio, pixelRatio);

      // No background — transparent PNG

      // ── Header ──
      double curY = pad;
      const double logoSize = 42.0;
      final double textX = pad + (logoImage != null ? logoSize + 14 : 0);

      if (logoImage != null) {
        canvas.drawImageRect(
          logoImage,
          Rect.fromLTWH(0, 0, logoImage.width.toDouble(),
              logoImage.height.toDouble()),
          Rect.fromLTWH(pad, curY + (headerH - logoSize) / 2, logoSize,
              logoSize),
          Paint()..filterQuality = FilterQuality.high,
        );
      }

      if (scaleName.isNotEmpty) {
        // Scale name (primary)
        final namePainter = TextPainter(
          text: TextSpan(
            text: scaleName,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        namePainter.layout();
        namePainter.paint(canvas, Offset(textX, curY + 8));

        // App name (subtitle)
        final subPainter = TextPainter(
          text: TextSpan(
            text: 'Scale Master Guitar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        subPainter.layout();
        subPainter.paint(
            canvas, Offset(textX, curY + 10 + namePainter.height + 2));
      } else {
        final titlePainter = TextPainter(
          text: const TextSpan(
            text: 'Scale Master Guitar',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        titlePainter.layout();
        titlePainter.paint(canvas,
            Offset(textX, curY + (headerH - titlePainter.height) / 2));
      }

      curY += headerH;

      // Thin accent divider
      final dividerPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.25)
        ..strokeWidth = 1.0;
      canvas.drawLine(
          Offset(pad, curY), Offset(totalW - pad, curY), dividerPaint);

      curY += gap;

      // ── Fretboard ──
      canvas.save();
      canvas.translate(pad, curY + yOvershoot);
      painter.paint(canvas, painterSize);
      canvas.restore();

      curY += contentH + gap;

      // Thin accent divider
      canvas.drawLine(
          Offset(pad, curY), Offset(totalW - pad, curY), dividerPaint);

      // ── Footer ──
      final brandPainter = TextPainter(
        text: TextSpan(
          text: 'riffroutine.com',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      brandPainter.layout();
      brandPainter.paint(
        canvas,
        Offset(totalW - pad - brandPainter.width,
            curY + (footerH - brandPainter.height) / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (totalW * pixelRatio).ceil(),
        (totalH * pixelRatio).ceil(),
      );

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error rendering full fretboard: $e');
      return null;
    }
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

  /// Apply a loaded fingering from the library
  void _applyLoadedFingering(SavedFingering fingering) {
    setState(() {
      // Apply dot positions
      dotPositions = fingering.dotPositions.map((row) => List<bool>.from(row)).toList();

      // Apply dot colors (convert from hex strings to Colors)
      dotColors = fingering.getDotColorsAsColors();
    });

    // Apply other settings via providers
    if (fingering.sharpFlatPreference != null) {
      final sharpFlat = fingering.sharpFlatPreference == 'sharps'
          ? FretboardSharpFlat.sharps
          : FretboardSharpFlat.flats;
      ref.read(sharpFlatSelectionProvider.notifier).state = sharpFlat;
    }
    ref.read(noteNamesVisibilityProvider.notifier).state = !fingering.showNoteNames;

    final loadedFretboardColor = fingering.getFretboardColorAsColor();
    if (loadedFretboardColor != null) {
      ref.read(fretboardColorProvider.notifier).state = loadedFretboardColor;
    }

    // Sync to provider for subsequent saves
    _syncStateToProvider();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for loaded fingerings from the library
    ref.listen<SavedFingering?>(loadedFingeringProvider, (previous, next) {
      if (next != null) {
        _applyLoadedFingering(next);
        // Clear the provider after applying
        ref.read(loadedFingeringProvider.notifier).state = null;
      }
    });

    selectedColor = ref.watch(paletteColorProvider);
    final flatSharpSelection = ref.watch(sharpFlatSelectionProvider);
    final fretboardColor = ref.watch(fretboardColorProvider);
    final hideNotes = ref.watch(noteNamesVisibilityProvider);
    final notesSharps = ref.watch(fretboardNotesSharpsProvider);
    final notesFlats = ref.watch(fretboardNotesFlatsProvider);
    const widthFactor = 3.37;
    const heightTolerance = 0.75;
    const fretTolerance = 3.2;

    return WidgetToPngExporter(
      isDegreeSelected:
          widget.fingeringsModel.scaleModel!.settings!.showScaleDegrees,
      fullCaptureCallback: () => _renderFullFretboard(
        flatSharpSelection: flatSharpSelection,
        fretboardColor: fretboardColor,
        hideNotes: hideNotes,
        notesSharps: notesSharps,
        notesFlats: notesFlats,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        Size size = constraints.biggest;
        debugPrint("Layout builder width ${size.width} height ${size.height}");
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
              debugPrint("Fret $fret String $string");

              if (string < 0 ||
                  string > stringCount ||
                  fret < 0 ||
                  fret > fretCount) {
                return;
              }

              string = string - 1;

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

              // Sync updated state to provider
              _syncStateToProvider();
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
                      notesSharps: notesSharps,
                      notesFlats: notesFlats,
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
