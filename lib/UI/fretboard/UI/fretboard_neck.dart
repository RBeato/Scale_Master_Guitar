import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard/UI/fretboard_painter.dart';
import '../provider/fingerings_provider.dart';

class Fretboard extends ConsumerWidget {
  Fretboard({super.key});

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int stringCount = 6;
    int fretCount = 24;
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);

    return SizedBox(
      height: 200,
      child: fingerings.when(
        data: (data) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 50.0,
              ),
              child: CustomPaint(
                painter: FretboardPainter(
                  stringCount: stringCount,
                  fretCount: fretCount,
                  fingeringsModel: data!,
                ),
                child: SizedBox(
                  width: fretCount.toDouble() * 36,
                  height: stringCount.toDouble() * 24,
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
