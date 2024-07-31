import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/fretboard_page/provider/palette_color_provider.dart';

class ColorPalette extends ConsumerWidget {
  final List<Color> colors;
  final Function(Color) onColorSelected;

  const ColorPalette({
    Key? key,
    required this.colors,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(paletteColorProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20), // Adjust border radius as needed
        color: Colors.black38,
      ),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: colors.map((color) {
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(width: 0.5, color: Colors.black),
                  ),
                  child: selectedColor == color
                      ? const RotatedBox(
                          quarterTurns: 1,
                          child: FittedBox(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : Container()),
            );
          }).toList(),
        ),
      ),
    );
  }
}
