import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/models/settings_model.dart';
import 'package:tonic/tonic.dart';
import '../../../constants/scales/scales_data_v2.dart';
import '../../../models/scale_model.dart';
import '../../../models/chord_scale_model.dart';
import '../../../utils/music_utils.dart';
import '../../drawer/provider/settings_state_notifier.dart';
import '../../chromatic_wheel/provider/top_note_provider.dart';
import '../../scale_selection_dropdowns/provider/mode_dropdown_value_provider.dart';
import '../../scale_selection_dropdowns/provider/scale_dropdown_value_provider.dart';
import '../service/fingerings_positions_and_color.dart';

final chordModelFretboardFingeringProvider =
    FutureProvider.autoDispose<ChordScaleFingeringsModel?>((ref) async {
  ref.maintainState = true;

  final topNote = ref.watch(topNoteProvider);
  final scale = ref.watch(scaleDropdownValueProvider);
  final mode = ref.watch(modeDropdownValueProvider);
  ref.watch(settingsStateNotifierProvider);

  final Settings settings =
      await ref.read(settingsStateNotifierProvider.notifier).settings;

  final List<String> scaleNotesNames = MusicUtils.createChords(
      settings, MusicUtils.flatsAndSharpsToFlats(topNote), scale, mode);

  final scaleIntervals = Scales.data[scale.toString()][mode]['scaleStepsRoman'];

  List<List<Interval>> modesScalarTonicIntervals = [];

  ScaleModel item = ScaleModel(
    parentScaleKey: topNote,
    scale: scale.toString(),
    scaleNotesNames: scaleNotesNames,
    chordTypes: [],
    degreeFunction: scaleIntervals,
    mode: mode,
    modesScalarTonicIntervals: [],
    settings: settings,
    originModeType: '',
    notesIntervalsRelativeToTonicForBuildingChordsList: [],
    completeChordNames: [],
  );

  if (scale == 'Diatonic Major' ||
      scale == 'Melodic Minor' ||
      scale == 'Harmonic Minor' ||
      scale == 'Harmonic Major') {
    modesScalarTonicIntervals =
        MusicUtils.getSevenNoteScalesModesIntervalsLists(item);
  } else {
    modesScalarTonicIntervals =
        MusicUtils.getOtherScaleModesIntervalsLists(item);
  }

  item.modesScalarTonicIntervals = modesScalarTonicIntervals;

  MusicUtils.getTriadsNames(item, modesScalarTonicIntervals);

  ChordScaleFingeringsModel fingering =
      FingeringsCreator().createChordsScales(item, settings);

  return fingering;
});

class ChordModelFretboardFingeringsProvider
    extends StateNotifier<Map<int, ChordScaleFingeringsModel>> {
  ChordModelFretboardFingeringsProvider({
    fingerings,
  }) : super(fingerings ?? Map<int, ChordScaleFingeringsModel>.from({}));

  deleteFingering(int index) {
    state.removeWhere((key, value) => key == index);
  }

  clearFingerings() {
    state.clear();
  }
}
