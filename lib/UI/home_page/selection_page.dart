import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/drawer/UI/drawer/custom_drawer.dart';

import '../chromatic_wheel/provider/top_note_provider.dart';
import '../player_page/player_page.dart';
import '../scale_selection_dropdowns/scale_selection.dart';
import 'wheel_piano_widget.dart';

class SelectionPage extends ConsumerStatefulWidget {
  const SelectionPage({Key? key}) : super(key: key);

  @override
  SelectionPageState createState() => SelectionPageState();
}

class SelectionPageState extends ConsumerState<SelectionPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(topNoteProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text("Scale Master Guitar"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PlayerPage()));
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(flex: 1, child: ScaleSelector()),
            const Expanded(
              flex: 8,
              child: WheelAndPianoColumn(),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
      drawer: CustomDrawer(),
    );
  }
}
