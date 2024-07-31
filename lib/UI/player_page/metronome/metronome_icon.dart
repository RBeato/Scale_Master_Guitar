import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/debouncing.dart';
import '../provider/is_metronome_selected.dart';
import '../provider/is_playing_provider.dart';
import 'metrome_custom_painter.dart';

class MetronomeButton extends ConsumerWidget {
  bool _isOn = false;

  MetronomeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _isOn = ref.watch(isMetronomeSelectedProvider);
    return IconButton(
        icon: MetronomeIcon(
          isOn: _isOn,
          size: 32.0,
        ),
        color: _isOn ? Colors.greenAccent : Colors.white70,
        onPressed: () {
          Debouncer.handleButtonPress(() {
            ref
                .read(isSequencerPlayingProvider.notifier)
                .update((state) => false);
            ref
                .read(isMetronomeSelectedProvider.notifier)
                .update((state) => !_isOn);
          });
        });
  }
}

class MetronomeIcon extends StatelessWidget {
  final double size;
  final bool isOn;

  const MetronomeIcon({Key? key, required this.size, required this.isOn})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MetronomePainter(isOn: isOn),
    );
  }
}
