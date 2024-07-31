import 'package:test/models/scale_model.dart';

class TrashChordModel {
  bool isBassNote;
  int positionIndex;
  ScaleModel chordModel;

  TrashChordModel(
      {required this.isBassNote,
      required this.positionIndex,
      required this.chordModel});

  @override
  String toString() {
    return "isBass: $isBassNote, Position:$positionIndex, chordModel: $chordModel";
  }
}
