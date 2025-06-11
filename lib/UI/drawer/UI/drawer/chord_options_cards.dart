import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:scalemasterguitar/UI/drawer/UI/build_loading.dart';
import 'package:scalemasterguitar/UI/drawer/UI/drawer/settings_enum.dart';
import 'package:scalemasterguitar/UI/drawer/models/settings_state.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/models/settings_model.dart';
import 'drawer_switch_general.dart';

class GeneralOptions extends ConsumerWidget {
  const GeneralOptions({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, watch, _) {
        final state = ref.watch(settingsStateNotifierProvider);

        if (state is SettingsInitial) {
          return const Text("Didn't load options!");
          // buildInitialSettingsInput(context);
        } else if (state is SettingsLoading) {
          return buildLoadingSettings();
        } else if (state is SettingsLoaded) {
          return GeneralOptionsCards(state.settings);
        } else if (state is SettingsError) {
          return const Text("Error loading options!");
          // buildInitialSettingsInput(context);
        }
        return const Text("Didn't load options!");
      },
    );
  }
}

class GeneralOptionsCards extends StatelessWidget {
  GeneralOptionsCards(this.settings, {super.key});
  Settings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DrawerGeneralSwitch(
          title: 'Show scale degrees on fretboard',
          subtitle: 'If unselected will show notes names on fretboard',
          settingSelection: SettingsSelection.scaleDegrees,
          switchValue: settings.showScaleDegrees,
        ),
        DrawerGeneralSwitch(
          title: 'Single Color',
          subtitle: 'If unselected will show scale tones with different colors',
          settingSelection: SettingsSelection.singleColor,
          switchValue: settings.isSingleColor,
        ),
        DrawerGeneralSwitch(
          title: 'Tonic as Universal Bass Note',
          subtitle:
              'if selected all chords will have the scale tonic as the bass note',
          settingSelection: SettingsSelection.tonicUniversalBassNote,
          switchValue: settings.isTonicUniversalBassNote,
          isPremiumFeature: true,
        ),
      ],
    );
  }
}
