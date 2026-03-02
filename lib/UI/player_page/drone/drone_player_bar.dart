import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_theme.dart';
import '../../drawer/models/settings_state.dart';
import '../../drawer/provider/settings_state_notifier.dart';
import '../provider/drone_providers.dart';
import 'drone_chord_selector.dart';
import 'drone_service.dart';

class DronePlayerBar extends ConsumerStatefulWidget {
  const DronePlayerBar({super.key});

  @override
  ConsumerState<DronePlayerBar> createState() => _DronePlayerBarState();
}

class _DronePlayerBarState extends ConsumerState<DronePlayerBar> {
  bool _isInitializing = false;

  String _getDroneSound() {
    final state = ref.read(settingsStateNotifierProvider);
    if (state is SettingsLoaded) {
      return state.settings.droneSound;
    }
    return 'Organ';
  }

  Future<void> _togglePlayStop() async {
    final isPlaying = ref.read(isDronePlayingProvider);
    final chord = ref.read(droneChordProvider);

    if (isPlaying) {
      DroneService().stop();
      ref.read(isDronePlayingProvider.notifier).state = false;
    } else {
      if (chord == null) return;

      setState(() => _isInitializing = true);
      try {
        await DroneService().play(chord, soundName: _getDroneSound());
        ref.read(isDronePlayingProvider.notifier).state = true;
      } catch (e) {
        debugPrint('[DronePlayerBar] Error starting drone: $e');
      } finally {
        if (mounted) setState(() => _isInitializing = false);
      }
    }
  }

  void _openChordSelector() {
    final wasPlaying = ref.read(isDronePlayingProvider);
    if (wasPlaying) {
      DroneService().stop();
      ref.read(isDronePlayingProvider.notifier).state = false;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DroneChordSelector(
        currentChord: ref.read(droneChordProvider),
        onChordSelected: (chord) {
          ref.read(droneChordProvider.notifier).state = chord;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chord = ref.watch(droneChordProvider);
    final isPlaying = ref.watch(isDronePlayingProvider);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double edgeInset = isTablet ? 20.0 : 0.0;

    if (chord == null) {
      return Container(
        color: AppColors.backgroundDark,
        child: const Center(
          child: Text(
            'Tap a chord above to set the drone',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final chordColor = chord.color ?? Colors.orangeAccent;

    return Container(
      color: chordColor.withValues(alpha: 0.6),
      child: Stack(
        children: [
          // Center: Chord name + playing indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chord.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (isPlaying)
                  _PulsingIndicator(color: Colors.white)
                else
                  Text(
                    'DRONE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom-left: Play/Stop button
          Positioned(
            left: edgeInset,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: _isInitializing ? null : _togglePlayStop,
                child: _isInitializing
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white70,
                        size: 40,
                      ),
              ),
            ),
          ),

          // Bottom-right: Edit chord button
          Positioned(
            bottom: 0,
            right: edgeInset,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: _openChordSelector,
                child: const Icon(
                  Icons.tune,
                  size: 28,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot indicator to show the drone is active
class _PulsingIndicator extends StatefulWidget {
  final Color color;
  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = ((_controller.value + delay) % 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: 0.3 + 0.7 * t,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
