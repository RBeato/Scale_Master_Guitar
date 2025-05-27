import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/settings_enum.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';

class DrawerGeneralSwitch extends ConsumerWidget {
  const DrawerGeneralSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.settingSelection,
    required this.switchValue,
  });

  final String title;
  final String subtitle;
  final SettingsSelection settingSelection;
  final bool switchValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.black12,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: Switch(
          value: switchValue,
          onChanged: (value) async {
            await ref
                .read(settingsStateNotifierProvider.notifier)
                .changeValue(settingSelection, value);
          },
          activeTrackColor: Colors.lightGreenAccent,
          activeColor: Colors.green,
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Text(
                subtitle,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 11.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
