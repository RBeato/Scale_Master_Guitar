import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/chromatic_wheel/wheel_painter.dart';
import 'package:scalemasterguitar/UI/chromatic_wheel/provider/wheel_rotation_provider.dart';
import 'package:scalemasterguitar/models/scale_model.dart';
import 'package:scalemasterguitar/constants/music_constants.dart';
import '../../constants/scales/scales_data_v2.dart';
import 'provider/top_note_provider.dart';
import '../fretboard_page/provider/sharp_flat_selection_provider.dart';

class ChromaticWheel extends ConsumerStatefulWidget {
  const ChromaticWheel(this.scaleModel, {super.key});
  final ScaleModel scaleModel;

  @override
  _ChromaticWheelState createState() => _ChromaticWheelState();
}

class _ChromaticWheelState extends ConsumerState<ChromaticWheel> with SingleTickerProviderStateMixin {

  double _currentRotation = 0.0;
  static const int numStops = 12;
  final double _rotationPerStop = 2 * math.pi / numStops;
  double _initialAngle = 0.0;
  late List scaleIntervals;
  late List chromaticNotes;

  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  void _onSnapControllerTick() {
    if (!mounted) return;
    setState(() {
      _currentRotation = _snapAnimation?.value ?? _currentRotation;
      ref.read(wheelRotationProvider.notifier).update((state) => _currentRotation);
    });
  }

  @override
  void initState() {
    super.initState();
    _currentRotation = ref.read(wheelRotationProvider);

    _updateScaleData();

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Slightly longer for smoother animation
    );
    // Use vsync to ensure smooth animations
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Ensure final position is exact to avoid drift
        _currentRotation = _snapAnimation?.value ?? _currentRotation;
        _currentRotation = (_currentRotation % (2 * math.pi));
        if (_currentRotation < 0) _currentRotation += 2 * math.pi;
      }
    });
    _snapController.addListener(_onSnapControllerTick);
  }

  /// Updates scale data when the scale model changes
  void _updateScaleData() {
    scaleIntervals = Scales.data[widget.scaleModel.scale]
        [widget.scaleModel.mode]['scaleDegrees']!;
    chromaticNotes = getChromaticNotes();
  }

  @override
  void didUpdateWidget(ChromaticWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the scale model has changed
    if (oldWidget.scaleModel.scale != widget.scaleModel.scale ||
        oldWidget.scaleModel.mode != widget.scaleModel.mode) {
        _updateScaleData();
      // Trigger a rebuild to update the visual representation
      setState(() {});
    }
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
      // Update the top note provider in real-time during rotation
      final String currentTopNote = _calculateTopNoteForRotation(_currentRotation);
      ref.read(topNoteProvider.notifier).update((state) => currentTopNote);
    });
  }

  void _animateSnap(double targetRotation) {
    if (!mounted) return;

    // Calculate the minimal difference considering circular nature
    double diff = (targetRotation - _currentRotation) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;

    // For very small adjustments, just snap immediately without animation
    if (diff.abs() < 0.01) {
      if (mounted) {
        setState(() {
          _currentRotation = targetRotation;
          ref.read(wheelRotationProvider.notifier).update((state) => _currentRotation);
          final String finalTopNote = _calculateTopNoteForRotation(targetRotation);
          ref.read(topNoteProvider.notifier).update((state) => finalTopNote);
        });
      }
      return;
    }

    // Calculate dynamic duration based on distance (max 150ms, min 50ms)
    final double distance = diff.abs();
    final double normalizedDistance = distance / (math.pi / 6);
    final int durationMs = (50 + (100 * normalizedDistance.clamp(0.0, 1.0))).round();

    _snapController.duration = Duration(milliseconds: durationMs);
    _snapController
      ..reset()
      ..removeListener(_onSnapControllerTick);

    _snapAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + diff,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutQuad,
    ));

    _snapController.addListener(_onSnapControllerTick);

    _snapController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentRotation = targetRotation;
          ref.read(wheelRotationProvider.notifier).update((state) => _currentRotation);
          final String finalTopNote = _calculateTopNoteForRotation(targetRotation);
          ref.read(topNoteProvider.notifier).update((state) => finalTopNote);
        });
      }
    });
  }

  /// Converts a note to the preferred sharp or flat notation
  String _convertNoteToPreferredNotation(String rawNote) {
    final sharpFlatPreference = ref.read(sharpFlatSelectionProvider);
    
    // If no preference is set, default to sharps
    if (sharpFlatPreference == null) {
      if (rawNote.contains('/')) {
        return rawNote.split('/')[0]; // Return sharp version
      }
      return rawNote;
    }
    
    // Handle compound notes like 'C♯/D♭'
    if (rawNote.contains('/')) {
      final parts = rawNote.split('/');
      return sharpFlatPreference == FretboardSharpFlat.sharps 
          ? parts[0]  // Return sharp version (first part)
          : parts[1]; // Return flat version (second part)
    }
    
    return rawNote;
  }

  /// Shared note index calculation — uses .round() to avoid floating point
  /// errors where values like 8.9999999 would be floored to 8 instead of 9,
  /// causing the wrong note (one semitone off) to be selected.
  int _noteIndexForAngle(double topPositionAngle) {
    final double notePosition = (topPositionAngle / _rotationPerStop) % numStops;
    return (numStops - notePosition.round()) % numStops;
  }

  String getTopNote() {
    final currentRotation = _snapController.isAnimating
        ? _snapAnimation?.value ?? _currentRotation
        : _currentRotation;

    double topPositionAngle = (currentRotation + math.pi / 2) % (2 * math.pi);
    if (topPositionAngle < 0) topPositionAngle += 2 * math.pi;

    String rawNote = MusicConstants.notesWithFlatsAndSharps[_noteIndexForAngle(topPositionAngle)];
    return _convertNoteToPreferredNotation(rawNote);
  }

  String _calculateTopNoteForRotation(double rotation) {
    double topPositionAngle = (rotation + math.pi / 2) % (2 * math.pi);
    if (topPositionAngle < 0) topPositionAngle += 2 * math.pi;

    int noteIndex = _noteIndexForAngle(topPositionAngle);
    String rawNote = MusicConstants.notesWithFlatsAndSharps[noteIndex];
    return _convertNoteToPreferredNotation(rawNote);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the sharp/flat preference to rebuild when it changes
    ref.watch(sharpFlatSelectionProvider);
    
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
        if (!mounted) return;

        // Calculate the closest stop with high precision
        final double normalizedRotation = (_currentRotation % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
        final double stopPosition = (normalizedRotation / _rotationPerStop).roundToDouble();
        double snappedRotation = (stopPosition * _rotationPerStop) % (2 * math.pi);
        
        // Ensure snappedRotation is in [0, 2π)
        snappedRotation = (snappedRotation + 2 * math.pi) % (2 * math.pi);
        
        // For very small movements, ensure we don't snap to the next position
        final double snapThreshold = _rotationPerStop * 0.1; // 10% of the way to next stop
        final double diffToCurrent = (normalizedRotation / _rotationPerStop) - stopPosition;
        if (diffToCurrent.abs() < snapThreshold) {
          snappedRotation = normalizedRotation;
        }

        if (mounted) {
          _animateSnap(snappedRotation);
        }
      },
      child: CustomPaint(
        painter: WheelPainter(
            _currentRotation, chromaticNotes, scaleIntervals, topNote),
        child: LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double size = screenWidth > 600
        ? screenWidth * 0.58  // Tablet/iPad: scaled wheel
        : screenWidth * 0.9;  // Phone: unchanged
    return SizedBox(
      width: size,
      height: size,
    );
  },
),
      ),
    );
  }

  double _angleFromCenter(Offset touchPosition, Offset wheelCenter) {
    return math.atan2(
        touchPosition.dy - wheelCenter.dy, touchPosition.dx - wheelCenter.dx);
  }

  @override
  void dispose() {
    // It's crucial to stop the animation controller if it's active.
    // This helps release the Ticker. Using canceled: true ensures it stops immediately.
    _snapController.stop(canceled: true);
    _snapController.removeListener(_onSnapControllerTick);
    _snapController.dispose();
    super.dispose();
  }
}
