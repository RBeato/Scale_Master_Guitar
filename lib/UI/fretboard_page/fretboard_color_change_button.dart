import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/fretboard_page/provider/fretboard_color_provider.dart';
import 'color_picker_dialog.dart'; // Ensure this import is correct

class FretboardColorChangeButton extends ConsumerWidget {
  const FretboardColorChangeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(fretboardColorProvider);

    return IconButton(
      icon: Icon(Icons.color_lens, color: currentColor),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return const ColorPickerDialog();
          },
        );
      },
    );
  }
}
