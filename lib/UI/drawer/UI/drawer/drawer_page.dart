import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:test/UI/drawer/UI/drawer/sounds_dropdown_column.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/constants/styles.dart';
import 'chord_options_cards.dart';

class DrawerPage extends ConsumerStatefulWidget {
  const DrawerPage({super.key});

  @override
  ConsumerState<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends ConsumerState<DrawerPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Column(
            children: <Widget>[
              GeneralOptions(),
              SoundsDropdownColumn(),
            ],
          ),
          InkWell(
            highlightColor: cardColor,
            child: GestureDetector(
              onTap: () {
                ref.read(settingsStateNotifierProvider.notifier).resetValues();
              },
              child: Card(
                  color: clearPreferencesButtonColor,
                  child: const ListTile(
                    title: Text(
                      'Clear Preferences',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
