import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard_page/save_button.dart';
import 'package:scalemasterguitar/UI/fretboard_page/save_to_library_button.dart';
import 'package:scalemasterguitar/UI/fretboard_page/library_access_button.dart';

import 'color_palette.dart';
import 'fretboard_color_change_button.dart';
import 'note_names_button.dart';
import 'provider/palette_color_provider.dart';
import 'sharp_flats_selection_button.dart';

class FretboardOptionButtons extends ConsumerWidget {
  const FretboardOptionButtons(this.isDegreeSelected, {super.key});

  final bool isDegreeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0, bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SaveImageButton(),
            const SaveToLibraryButton(),
            const LibraryAccessButton(),
            const NoteNamesButton(),
            const FretboardColorChangeButton(),
            isDegreeSelected
                ? Container()
                : const FretboardSharpFlatToggleButton(),
            ColorPalette(
              colors: const [
                Colors.blueGrey,
                Colors.red,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
              onColorSelected: (Color color) {
                ref
                    .read(paletteColorProvider.notifier)
                    .update((state) => color);
              },
            ),
          ],
        ),
      ),
    );
  }
}
