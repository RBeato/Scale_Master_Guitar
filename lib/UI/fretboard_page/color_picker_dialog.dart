import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/fretboard_color_provider.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';

class ColorPickerDialog extends ConsumerStatefulWidget {
  const ColorPickerDialog({super.key});

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends ConsumerState<ColorPickerDialog> {
  Color selectedColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final currentColor = ref.watch(fretboardColorProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Choose Color of Fretboard',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: MaterialPicker(
          pickerColor: currentColor,
          onColorChanged: (color) {
            setState(() {
              selectedColor = color;
            });
          },
          enableLabel: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            ref.read(fretboardColorProvider.notifier).state = selectedColor;
            Navigator.of(context).pop();
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
