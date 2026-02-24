import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard/UI/fretboard_painter.dart';
import '../../../providers/fretboard_notes_provider.dart';
import '../../../providers/tuning_provider.dart';
import '../provider/fingerings_provider.dart';
import '../../fretboard_page/provider/sharp_flat_selection_provider.dart';

class Fretboard extends ConsumerWidget {
  Fretboard({super.key});

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuning = ref.watch(tuningProvider);
    int stringCount = tuning.stringCount;
    int fretCount = tuning.fretCount;
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);
    final sharpFlatPreference = ref.watch(sharpFlatSelectionProvider);
    final notesSharps = ref.watch(fretboardNotesSharpsProvider);
    final notesFlats = ref.watch(fretboardNotesFlatsProvider);

    final isTablet = MediaQuery.of(context).size.width > 600;

    // Dynamic spacing: give 7-8 string instruments more vertical room
    final double perStringHeight = stringCount <= 6 ? 24.0 : 28.0;
    final double verticalPadding = stringCount <= 6 ? 20.0 : 12.0;
    final double containerHeight =
        (stringCount * perStringHeight + verticalPadding * 2).clamp(200.0, 260.0);

    return SizedBox(
      height: containerHeight,
      child: fingerings.when(
        data: (data) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: isTablet ? 160.0 : 50.0,
              ),
              child: CustomPaint(
                painter: FretboardPainter(
                  stringCount: stringCount,
                  fretCount: fretCount,
                  fingeringsModel: data!,
                  sharpFlatPreference: sharpFlatPreference,
                  notesSharps: notesSharps,
                  notesFlats: notesFlats,
                ),
                child: SizedBox(
                  width: fretCount.toDouble() * 36,
                  height: stringCount * perStringHeight,
                ),
              ),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(color: Colors.orange),
        error: (error, stackTrace) => Text('Error: $error'),
      ),
    );
  }
}
