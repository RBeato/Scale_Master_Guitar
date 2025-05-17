// import 'dart:math';
// import 'package:tonic/tonic.dart' as tonic;

// import '../../../constants/flats_only_nomenclature_converter.dart';
// import '../../../constants/music_constants.dart';
// import '../../../models/chord_model.dart';

// class SoundCreationService {
//   late List<ChordModel> _selectedChords;
//   final Map<int, String> _chordRootPositionsAndNotes = {};
//   int _octave = 3;
//   bool isFirstChord = true;

//   Map<int, String> get bassLine => _chordRootPositionsAndNotes;
//   List<ChordModel> get chordModelAndPositions => _selectedChords;

//   clearChords() {
//     _selectedChords = [];
//   }

//   createSoundLists(List<ChordModel> selectedItems, bool addedPedalMainNote) {
//     if (selectedItems.isEmpty) return;

//     if (addedPedalMainNote) {
//       //do Something
//     }

//     for (var item in _selectedChords) {
//       var chord =
//           tonic.Chord.parse('${item.chordNameForAudio} ${item.typeOfChord}');
//       var chordsList = removeOctaveIndexes(chord.pitches);
//       item.selectedChordPitches = chordsList;
//       _chordRootPositionsAndNotes[item.position] = chord.root.toString();
//     }

//     if (isFirstChord) {
//       chooseFirstChordInversionRandomly();
//     }
//     if (!isFirstChord) {
//       createVoiceLeading();
//     }
//     addOctaveIndexes();
//     return _selectedChords;
//   }

//   removeOctaveIndexes(List chordsPitches) {
//     int counter = 0;
//     List<String> chordsPitchesList = [];
//     for (var note in chordsPitches) {
//       note = note.toString().substring(0, note.toString().length - 1);
//       chordsPitchesList.add(note.toString());
//     }
//     counter++;
//     //debugPrint('Original chordsPitchesList: $chordsPitchesList');
//     return chordsPitchesList;
//   }

//   chooseFirstChordInversionRandomly() {
//     _selectedChords.first.selectedChordPitches =
//         _reOrderNotes(_selectedChords.first.selectedChordPitches);
//     isFirstChord = false;
//   }

//   _reOrderNotes(notesList) {
//     int randomNumber = Random().nextInt(notesList.length);
//     for (int i = 0; i < randomNumber; i++) {
//       notesList.add(notesList[0]);
//       notesList.removeAt(0);
//     }
//     // debugPrint('Reordered first chord notes list: $notesList');
//     return notesList;
//   }

//   createVoiceLeading() {
//     String highestNote = _selectedChords.first.selectedChordPitches!.last;
//     int indexOfHighestNote = MusicConstants.notesWithFlats.indexOf(highestNote);

//     for (var item in _selectedChords) {
//       int noteCounter = 0;
//       for (var note in item.selectedChordPitches!) {
//         item.selectedChordPitches![noteCounter] =
//             flatsOnlyNoteNomenclature(note);
//         noteCounter++;
//       }

//       List indexesList = [];
//       for (var note in item.selectedChordPitches!) {
//         indexesList.add(MusicConstants.notesWithFlats.indexOf(note));
//       }
//       var reorderedChordIndexes = indexesList
//           .where((e) => e >= indexOfHighestNote || e <= indexOfHighestNote)
//           .toList()
//         ..sort();
//       // debugPrint('Reordered Chord Indexes: $reorderedChordIndexes');

//       List<String> reorderedChordNotes = [];
//       for (var index in reorderedChordIndexes) {
//         reorderedChordNotes.add(MusicConstants.notesWithFlats[index]);
//       }
//       item.selectedChordPitches = reorderedChordNotes;
//       indexOfHighestNote = reorderedChordIndexes.last.toInt();
//     }
//   }

//   List auxHashCodes = [];
//   addOctaveIndexes() {
//     for (var item in _selectedChords) {
//       int auxIndexValue = 0;
//       _octave = 3;
//       List audioNamesNotes = item.selectedChordPitches as List<String>;

//       if (!auxHashCodes.contains(item.hashCode)) {
//         //avoid adding indexes if chords are repeated
//         if (isFundamentalStateChord(item)) {
//           _octave++;
//         } // if fundamental state increment octave
//         for (int i = 0; i < audioNamesNotes.length; i++) {
//           if (auxIndexValue >
//               MusicConstants.notesWithFlats.indexOf(audioNamesNotes[i])) {
//             _octave++;
//           }
//           auxIndexValue =
//               MusicConstants.notesWithFlats.indexOf(audioNamesNotes[i]);
//           item.selectedChordPitches![i] =
//               audioNamesNotes[i] + _octave.toString();
//         }
//         auxHashCodes.add(item.hashCode);
//       }
//       // debugPrint('SelectedChordsNotes   ${item.chordModel.organizedPitches} ');
//     }
//     auxHashCodes.clear();
//   }

//   isFundamentalStateChord(ChordModel item) {
//     int aux = 0;
//     bool result = true;
//     for (var index in item.selectedChordPitches!) {
//       if (MusicConstants.notesWithFlats.indexOf(index) < aux) result = false;
//       aux = MusicConstants.notesWithFlats.indexOf(index);
//     }
//     return result;
//   }
// }
