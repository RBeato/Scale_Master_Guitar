import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/debouncing.dart';
import '../provider/is_metronome_selected.dart';
import '../provider/is_playing_provider.dart';
import 'metrome_custom_painter.dart';

class MetronomeButton extends ConsumerStatefulWidget {
  const MetronomeButton({super.key});

  @override
  ConsumerState<MetronomeButton> createState() => _MetronomeButtonState();
}

class _MetronomeButtonState extends ConsumerState<MetronomeButton> {
  DateTime? _lastPressTime;
  static const _throttleDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final isOn = ref.watch(isMetronomeSelectedProvider);

    return IconButton(
        icon: MetronomeIcon(
          isOn: isOn,
          size: 32.0,
        ),
        color: isOn ? Colors.greenAccent : Colors.white70,
        onPressed: () {
          final now = DateTime.now();

          // Throttle button presses
          if (_lastPressTime != null &&
              now.difference(_lastPressTime!) < _throttleDuration) {
            return;
          }

          _lastPressTime = now;

          // Toggle metronome without stopping playback
          ref
              .read(isMetronomeSelectedProvider.notifier)
              .update((state) => !state);
        });
  }
}

class MetronomeIcon extends StatelessWidget {
  final double size;
  final bool isOn;

  const MetronomeIcon({super.key, required this.size, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: MetronomePainter(isOn: isOn),
    );
  }
}
