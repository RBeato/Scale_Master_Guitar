import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/fretboard_page/provider/sharp_flat_selection_provider.dart';

class FretboardSharpFlatToggleButton extends ConsumerWidget {
  const FretboardSharpFlatToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharpFlat = ref.watch(sharpFlatSelectionProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        var currentValue = ref.read(sharpFlatSelectionProvider);
        var newValue = currentValue == FretboardSharpFlat.sharps
            ? FretboardSharpFlat.flats
            : FretboardSharpFlat.sharps;
        ref
            .read(sharpFlatSelectionProvider.notifier)
            .update((state) => newValue);
      },
      child: RotatedBox(
        quarterTurns: 1,
        child: Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20), // Adjust border radius as needed
            color: Colors.black38,
          ),
          child: Center(
            child: FittedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '♯',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: sharpFlat == FretboardSharpFlat.sharps
                            ? null
                            : FontWeight.bold,
                        color: sharpFlat == FretboardSharpFlat.sharps
                            ? Colors.orangeAccent
                            : Colors.grey),
                  ),
                  const Text(
                    '/',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '♭',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: sharpFlat == FretboardSharpFlat.flats
                            ? null
                            : FontWeight.bold,
                        color: sharpFlat == FretboardSharpFlat.flats
                            ? Colors.orangeAccent
                            : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
