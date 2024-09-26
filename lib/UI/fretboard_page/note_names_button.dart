import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider/note_names_visibility_provider.dart';

class NoteNamesButton extends ConsumerWidget {
  const NoteNamesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteNamesVisible = ref.watch(noteNamesVisibilityProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        ref.read(noteNamesVisibilityProvider.notifier).state =
            !noteNamesVisible;
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
              child: Text(
                (!noteNamesVisible ? 'Hide\nText' : 'Show\nText'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: noteNamesVisible ? Colors.orangeAccent : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
