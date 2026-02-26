import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/custom_drawer.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';
import 'package:scalemasterguitar/widgets/banner_ad_widget.dart';
import '../chromatic_wheel/provider/top_note_provider.dart';
import '../fretboard/provider/fingerings_provider.dart';
import '../player_page/player_page.dart';
import '../scale_selection_dropdowns/scale_selection.dart';
import 'provider/piano_visibility_provider.dart';
import 'wheel_piano_widget.dart';

class SelectionPage extends ConsumerStatefulWidget {
  const SelectionPage({super.key});

  @override
  SelectionPageState createState() => SelectionPageState();
}

class SelectionPageState extends ConsumerState<SelectionPage> {
  bool _isNavigating = false;

  Future<void> _navigateToPlayer() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });

    try {
      // Pre-compute fingerings before navigating so the transition is smooth
      await ref.read(chordModelFretboardFingeringProvider.future);
    } catch (e) {
      debugPrint('[SelectionPage] Fingerings pre-computation failed: $e');
      // Navigate anyway — PlayerPage handles errors
    }

    if (!mounted) return;

    // Let the UI settle after computation before transitioning
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      SlideRoute(
        page: const PlayerPage(),
        direction: SlideDirection.fromRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(topNoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Scale Master Guitar",
              style: TextStyle(color: Colors.orange)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(pianoVisibilityProvider.notifier).state =
                  !ref.read(pianoVisibilityProvider);
            },
            icon: Icon(
              ref.watch(pianoVisibilityProvider)
                  ? Icons.piano
                  : Icons.piano_off,
              color: Colors.orange,
            ),
            tooltip: 'Toggle Piano',
          ),
          IconButton(
            onPressed: _isNavigating ? null : _navigateToPlayer,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const ScaleSelector(),
                      const Expanded(
                        child: WheelAndPianoColumn(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
          // Loading overlay while pre-computing fingerings
          if (_isNavigating)
            Container(
              color: AppColors.background.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.orangeAccent),
                    const SizedBox(height: 20),
                    Text(
                      'Preparing your sequence...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      drawer: const CustomDrawer(),
    );
  }
}
