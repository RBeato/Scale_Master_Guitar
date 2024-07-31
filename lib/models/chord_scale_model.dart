import 'package:flutter/material.dart';

import 'scale_model.dart';

class ChordScaleFingeringsModel {
  List? scaleNotesPositions;
  List? chordVoicingNotesPositions;
  Map<String, Color>? scaleColorfulMap;
  Map<String, String>? scaleDegreesPositionsMap;
  ScaleModel? scaleModel;

  ChordScaleFingeringsModel(
      {this.chordVoicingNotesPositions,
      this.scaleNotesPositions,
      this.scaleColorfulMap,
      this.scaleDegreesPositionsMap,
      this.scaleModel});

  ChordScaleFingeringsModel copy() {
    return ChordScaleFingeringsModel(
      scaleModel: scaleModel, // Assuming scaleModel is immutable
      // Copy other fields as needed
    );
  }

  ChordScaleFingeringsModel copyWith({
    List? chordVoicingNotesPositions,
    List? scaleNotesPositions,
    Map<String, Color>? scaleColorfulMap,
    Map<String, String>? scaleDegreesPositionsMap,
    ScaleModel? scaleModel,
  }) {
    return ChordScaleFingeringsModel(
      chordVoicingNotesPositions:
          chordVoicingNotesPositions ?? this.chordVoicingNotesPositions,
      scaleNotesPositions: scaleNotesPositions ?? this.scaleNotesPositions,
      scaleColorfulMap: scaleColorfulMap ?? this.scaleColorfulMap,
      scaleDegreesPositionsMap:
          scaleDegreesPositionsMap ?? this.scaleDegreesPositionsMap,
      scaleModel: scaleModel ?? this.scaleModel,
    );
  }

  @override
  String toString() {
    return 'ChordScaleFingeringsModel info:'
        '\n$chordVoicingNotesPositions'
        '\n$scaleNotesPositions'
        '\n$scaleColorfulMap'
        '\n$scaleDegreesPositionsMap'
        '\n$scaleModel';
  }
}
