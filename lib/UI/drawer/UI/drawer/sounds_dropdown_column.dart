import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:test/UI/drawer/UI/build_loading.dart';
import 'package:test/UI/drawer/UI/drawer/settings_enum.dart';
import 'package:test/UI/drawer/models/settings_state.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/models/settings_model.dart';
import 'drawer_card.dart';

class SoundsDropdownColumn extends ConsumerWidget {
  const SoundsDropdownColumn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsStateNotifierProvider);

    if (state is SettingsInitial) {
      return const Text("Didn't load drop column!");
      // buildInitialSettingsInput(context);
    } else if (state is SettingsLoading) {
      return buildLoadingSettings();
    } else if (state is SettingsLoaded) {
      return buildColumnWithData(context, state.settings);
    } else if (state is SettingsError) {
      return const Text("Error loading drop column!");
      // buildInitialSettingsInput(context);
    }
    return const Text("Didn't load drop column!");
  }
}

Widget buildColumnWithData(BuildContext context, Settings settings) {
  return Column(children: [
    DrawerCard(
      title: 'Keyboard Sound',
      subtitle: 'Choose the type of keyboard sound you prefer',
      dropdownList: const ['Piano', 'Rhodes'],
      savedValue: settings.keyboardSound,
      settingsSelection: SettingsSelection.keyboardSound,
    ),
    DrawerCard(
      title: 'Bass Sound',
      subtitle: 'Choose the type of bass sound you prefer',
      dropdownList: const ['Double Bass', 'Electric'],
      savedValue: settings.bassSound,
      settingsSelection: SettingsSelection.bassSound,
    ),
    DrawerCard(
      title: 'Drum Kit Sound',
      subtitle: 'Choose the type of drum sound you prefer',
      dropdownList: const ['Acoustic', 'Electronic'],
      savedValue: settings.drumsSound,
      settingsSelection: SettingsSelection.drumsSound,
    ),
  ]);
}
