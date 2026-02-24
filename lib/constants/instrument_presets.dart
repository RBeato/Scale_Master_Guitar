import '../models/instrument_tuning.dart';

class InstrumentPresets {
  static const InstrumentTuning standardGuitar = InstrumentTuning(
    id: 'guitar_standard',
    name: 'Standard Guitar',
    type: InstrumentType.guitar,
    openNotes: ['E', 'B', 'G', 'D', 'A', 'E'], // high to low
    fretCount: 24,
  );

  static const InstrumentTuning dropD = InstrumentTuning(
    id: 'guitar_drop_d',
    name: 'Drop D',
    type: InstrumentType.guitar,
    openNotes: ['E', 'B', 'G', 'D', 'A', 'D'], // low E dropped to D
    fretCount: 24,
  );

  static const InstrumentTuning openG = InstrumentTuning(
    id: 'guitar_open_g',
    name: 'Open G',
    type: InstrumentType.guitar,
    openNotes: ['D', 'B', 'G', 'D', 'G', 'D'],
    fretCount: 24,
  );

  static const InstrumentTuning dadgad = InstrumentTuning(
    id: 'guitar_dadgad',
    name: 'DADGAD',
    type: InstrumentType.guitar,
    openNotes: ['D', 'A', 'G', 'D', 'A', 'D'],
    fretCount: 24,
  );

  static const InstrumentTuning sevenStringGuitar = InstrumentTuning(
    id: 'guitar_7string',
    name: '7-String Guitar',
    type: InstrumentType.sevenString,
    openNotes: ['E', 'B', 'G', 'D', 'A', 'E', 'B'], // low B added
    fretCount: 24,
  );

  static const InstrumentTuning eightStringGuitar = InstrumentTuning(
    id: 'guitar_8string',
    name: '8-String Guitar',
    type: InstrumentType.sevenString,
    openNotes: ['E', 'B', 'G', 'D', 'A', 'E', 'B', 'F#'], // low F# added
    fretCount: 24,
  );

  static const InstrumentTuning standardBass = InstrumentTuning(
    id: 'bass_standard',
    name: 'Standard Bass',
    type: InstrumentType.bass,
    openNotes: ['G', 'D', 'A', 'E'], // high to low
    fretCount: 24,
  );

  static const InstrumentTuning fiveStringBass = InstrumentTuning(
    id: 'bass_5string',
    name: '5-String Bass',
    type: InstrumentType.bass,
    openNotes: ['G', 'D', 'A', 'E', 'B'], // low B added
    fretCount: 24,
  );

  static const InstrumentTuning ukulele = InstrumentTuning(
    id: 'ukulele_standard',
    name: 'Standard Ukulele',
    type: InstrumentType.ukulele,
    openNotes: ['A', 'E', 'C', 'G'], // high to low
    fretCount: 17,
  );

  static const List<InstrumentTuning> allPresets = [
    standardGuitar,
    dropD,
    openG,
    dadgad,
    sevenStringGuitar,
    eightStringGuitar,
    standardBass,
    fiveStringBass,
    ukulele,
  ];

  static const InstrumentTuning defaultTuning = standardGuitar;

  /// Chromatic note names for the custom tuning selector UI
  static const List<String> chromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];
}
