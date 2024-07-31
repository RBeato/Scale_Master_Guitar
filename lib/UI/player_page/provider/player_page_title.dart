import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fretboard/provider/fingerings_provider.dart';

class PlayerPageTitle extends ConsumerWidget {
  const PlayerPageTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fingerings = ref.watch(chordModelFretboardFingeringProvider);

    return fingerings.when(
        data: (data) {
          return RichText(
            text: TextSpan(
              // Default text style that parent TextSpans will inherit
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text:
                        "${data!.scaleModel!.parentScaleKey} ${data.scaleModel!.mode}  ",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                TextSpan(
                  text: "${data.scaleModel!.scale}",
                  style: const TextStyle(
                      fontSize: 12), // Smaller font size for this part
                ),
              ],
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'));
  }
}
