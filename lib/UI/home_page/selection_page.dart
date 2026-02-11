import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/custom_drawer.dart';
import 'package:scalemasterguitar/utils/slide_route.dart';
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
            onPressed: () {
              // Ensure fingerings provider is warmed up before navigation
              ref.read(chordModelFretboardFingeringProvider);

              // Navigate immediately - PlayerPage will handle loading states properly
              Navigator.pushReplacement(context,
                  SlideRoute(
                    page: const PlayerPage(),
                    direction: SlideDirection.fromRight,
                  ));
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 80,
              child: ScaleSelector(),
            ),
            const Expanded(
              child: WheelAndPianoColumn(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            )
          ],
        ),
      ),
      drawer: const CustomDrawer(),
    );
  }
}
