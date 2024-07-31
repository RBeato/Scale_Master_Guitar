import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/chromatic_wheel/provider/wheel_rotation_provider.dart';
import 'package:test/UI/chromatic_wheel/wheel_painter.dart';
import 'package:test/models/scale_model.dart';

import '../../constants/music_constants.dart';
import '../../constants/scales/scales_data_v2.dart';
import 'provider/top_note_provider.dart';

class ChromaticWheel extends ConsumerStatefulWidget {
  const ChromaticWheel(this.scaleModel, {Key? key}) : super(key: key);
  final ScaleModel scaleModel;

  @override
  _ChromaticWheelState createState() => _ChromaticWheelState();
}

class _ChromaticWheelState extends ConsumerState<ChromaticWheel> {
  double _currentRotation = 0.0;
  static const int numStops = 12;
  final double _rotationPerStop = 2 * math.pi / numStops;
  double _initialAngle = 0.0;
  late List scaleIntervals;
  late List chromaticNotes;

  @override
  void initState() {
    super.initState();
    _currentRotation = ref.read(wheelRotationProvider);

    scaleIntervals = Scales.data[widget.scaleModel.scale]
        [widget.scaleModel.mode]['scaleDegrees']!;
    chromaticNotes = getChromaticNotes();
  }

  List getChromaticNotes() {
    var chromaticIntervals = MusicConstants.tonicNotesDegrees;
    if (scaleIntervals.length != chromaticIntervals.length) {
      debugPrint(
          "Scale Intervals length is not correct for ${widget.scaleModel.mode} from ${widget.scaleModel.scale}!",
          wrapWidth: 1024);
    }

    List temp = [];

    var scaleDegrees = List<String>.from(widget.scaleModel.degreeFunction);
    print("Degrees : $scaleDegrees");

    for (int i = 0; i < scaleIntervals.length; i++) {
      if (scaleIntervals[i] != null) {
        temp.add(scaleDegrees.first.toString());
        scaleDegrees.removeAt(0);
      } else {
        temp.add(MusicConstants.notesDegrees[i].toString());
      }
    }

    return temp;
  }

  void _updateRotation(double delta) {
    setState(() {
      _currentRotation += delta;
      ref
          .read(wheelRotationProvider.notifier)
          .update((state) => _currentRotation);
    });
  }

  String getTopNote() {
    // Adjust the angle calculation to accurately reflect the top of the wheel
    double topPositionAngle = (_currentRotation + math.pi / 2) % (2 * math.pi);
    if (topPositionAngle < 0) topPositionAngle += 2 * math.pi;

    // Determine the index of the note at this angle
    int noteIndex = (numStops -
            ((topPositionAngle / _rotationPerStop) % numStops).floor()) %
        numStops;

    return MusicConstants.notesWithFlatsAndSharps[noteIndex];
  }

  @override
  Widget build(BuildContext context) {
    String topNote = getTopNote();
    return GestureDetector(
      onPanStart: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset wheelCenter =
            renderBox.localToGlobal(renderBox.size.center(Offset.zero));
        _initialAngle = _angleFromCenter(details.globalPosition, wheelCenter);
      },
      onPanUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset wheelCenter =
            renderBox.localToGlobal(renderBox.size.center(Offset.zero));
        final double currentAngle =
            _angleFromCenter(details.globalPosition, wheelCenter);
        _updateRotation(currentAngle - _initialAngle);
        _initialAngle =
            currentAngle; // Update the initial angle for continuous tracking
      },
      onPanEnd: (details) {
        var closestStop =
            ((_currentRotation + _rotationPerStop / 2) / _rotationPerStop)
                .floor();
        setState(() {
          _currentRotation = closestStop * _rotationPerStop;
        });

        ref.read(topNoteProvider.notifier).update((state) => topNote);
      },
      child: CustomPaint(
        painter: WheelPainter(
            _currentRotation, chromaticNotes, scaleIntervals, topNote),
        child: const SizedBox(width: 300, height: 300),
      ),
    );
  }

  double _angleFromCenter(Offset touchPosition, Offset wheelCenter) {
    return math.atan2(
        touchPosition.dy - wheelCenter.dy, touchPosition.dx - wheelCenter.dx);
  }
}
