import 'package:flutter/material.dart';
import 'package:test/models/settings_model.dart';
import '../constants/color_constants.dart';
import '../constants/flats_to_sharps_nomenclature.dart';
import '../utils/music_utils.dart';

class ChordModel {
  String noteName;
  String? chordNameForUI;
  int id;
  int position;
  int duration;
  String scale = 'Diatonic Major';
  String mode = 'Ionian';
  String originalScaleType;
  String parentScaleKey;
  List<String> chordNotesWithIndexesRaw;
  String? chordNameForAudio;
  String? function;
  String? typeOfChord;
  Color? color;
  List<String>? chordNotesInversionWithIndexes;
  List<String>? selectedChordPitches;
  String? originModeType;
  Settings? settings;
  String? chordFunction;
  String? chordDegree;
  String? completeChordName;

  ChordModel({
    required this.noteName,
    required this.id,
    required this.position,
    required this.duration,
    required this.scale,
    required this.mode,
    required this.chordFunction,
    required this.chordDegree,
    required this.originalScaleType,
    required this.parentScaleKey,
    required this.chordNotesWithIndexesRaw,
    required this.completeChordName,
    this.chordNameForAudio,
    this.chordNameForUI,
    this.function,
    // this.chordProgression,
    this.typeOfChord,
    this.color,
    this.chordNotesInversionWithIndexes,
    this.selectedChordPitches,
    this.originModeType,
    this.settings,
  }) {
    // Set other properties based on provided information
    // function = _info('function');
    // typeOfChord = _info('chordType');
    chordNameForUI = _getChordNameForUI();
    chordNameForAudio = MusicUtils.flatsAndSharpsToFlats(parentScaleKey);
    color = _getColorFromFunction();
    // chordNotesInversionWithIndexes = _getOrganizedPitches();
  }

  List<String> _getOrganizedPitches() {
    List<String> pitches = MusicUtils.cleanNotesNames(chordNotesWithIndexesRaw);
    // for (var i = 0; i < notes.length; i++) {
    //   pitches.add(flatsAndSharpsToFlats(note));
    // }
    return pitches;
  }

  String _getChordNameForUI() {
    return ['C', 'D', 'E', 'F', 'G', 'A', 'B']
            .contains(MusicUtils.flatsAndSharpsToFlats(parentScaleKey))
        ? flatsToSharpsNomenclature(parentScaleKey)
        : parentScaleKey;
  }

  Color? _getColorFromFunction() {
    final functionKey = chordDegree.toString().toUpperCase();
    return ConstantColors.scaleColorMap[functionKey];
  }

  ChordModel copyWith({
    String? noteName,
    String? chordNameForUI,
    int? id,
    int? position,
    int? duration,
    String? scale,
    String? mode,
    String? bassNote,
    String? originalScaleType,
    String? parentScaleKey,
    List<String>? chordNotesWithIndexesUnclean,
    String? chordNameForAudio,
    String? function,
    String? typeOfChord,
    String? completeChordName,
    Color? color,
    List<String>? allChordExtensions,
    List<String>? pitches,
    String? originModeType,
    Settings? settings,
    String? chordFunction,
    String? chordDegree,
  }) {
    return ChordModel(
      noteName: noteName ?? this.noteName,
      chordNameForUI: chordNameForUI ?? this.chordNameForUI,
      id: id ?? this.id,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      scale: scale ?? this.scale,
      mode: mode ?? this.mode,
      originalScaleType: originalScaleType ?? this.originalScaleType,
      parentScaleKey: parentScaleKey ?? this.parentScaleKey,
      chordNotesWithIndexesRaw:
          chordNotesWithIndexesUnclean ?? chordNotesWithIndexesRaw,
      chordNameForAudio: chordNameForAudio ?? this.chordNameForAudio,
      function: function ?? this.function,
      typeOfChord: typeOfChord ?? this.typeOfChord,
      color: color ?? this.color,
      chordNotesInversionWithIndexes:
          allChordExtensions ?? pitches, // Update organizedPitches
      selectedChordPitches: pitches ?? selectedChordPitches,
      originModeType: originModeType ?? this.originModeType,
      settings: settings ?? this.settings,
      chordFunction: chordFunction ?? this.chordFunction,
      chordDegree: chordDegree ?? this.chordDegree,
      completeChordName: completeChordName ?? this.completeChordName,
    );
  }

  @override
  String toString() {
    return 'ScaleModel(scale: $scale, mode: $mode, chordNameForAudio: $chordNameForAudio, chordNameForUI: $chordNameForUI, function: $function,typeOfChord: $typeOfChord color: $color, selectedChordPitches: $selectedChordPitches,allChordExtension $chordNotesInversionWithIndexes, originModeType: $originModeType), completeChordName: $completeChordName, chordFunction: $chordFunction, chordDegree: $chordDegree, settings: $settings)';
  }
}
