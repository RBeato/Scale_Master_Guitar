import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/custom_drawer.dart';
import 'package:scalemasterguitar/widgets/screen_with_banner_ad.dart';

import '../chromatic_wheel/provider/top_note_provider.dart';
import '../fretboard/provider/fingerings_provider.dart';
import '../player_page/player_page.dart';
import '../scale_selection_dropdowns/scale_selection.dart';
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

    return ScreenWithBannerAd(
      appBar: AppBar(
        title: const Text("Scale Master Guitar",
            style: TextStyle(color: Colors.orange)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // Ensure fingerings provider is warmed up before navigation
              final fingerings = ref.read(chordModelFretboardFingeringProvider);
              
              // Navigate immediately - PlayerPage will handle loading states properly
              Navigator.pushReplacement(context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const PlayerPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ));
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(flex: 1, child: ScaleSelector()),
            const Expanded(
              flex: 8,
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
