import 'package:flutter_sequencer/models/instrument.dart';
import 'package:scalemasterguitar/models/settings_model.dart';
import '../constants/gm_programs.dart';
import '../UI/drawer/UI/drawer/settings_enum.dart';
import 'package:flutter/material.dart' as material;
class SoundPlayerUtils {
  static getInstruments(Settings settings, {bool onlyKeys = false}) {
    List<Instrument> instruments = [
      _getSound(SettingsSelection.drumsSound, settings.drumsSound),
      _getSound(SettingsSelection.keyboardSound, settings.keyboardSound),
      _getSound(SettingsSelection.bassSound, settings.bassSound),
    ];
    return instruments;
  }

  static _getSound(instrument, instSound) {
    // All instruments use FluidR3_GM.sf2 and select the correct presetIndex (program number)
    String gmName = '';
    switch (instrument) {
      case SettingsSelection.keyboardSound:
        gmName = instSound;
        break;
      case SettingsSelection.bassSound:
        gmName = instSound;
        break;
      case SettingsSelection.drumsSound:
        gmName = 'Synth Drum'; // or 'Drums' if you want to use a melodic drum preset
        break;
      default:
        throw Exception('Unknown instrument type: $instrument');
    }

    final presetIndex = gmProgramNumbers[gmName];
    if (presetIndex == null) {
      material.debugPrint('[SoundPlayerUtils] ERROR: No GM program for instrument: $instrument, instSound: $instSound');
      throw Exception('No GM program for instrument: $instrument, instSound: $instSound');
    }
    material.debugPrint('[SoundPlayerUtils] Using instrument: $instrument, instSound: $instSound, presetIndex: $presetIndex');
    return Sf2Instrument(
      path: "assets/sounds/sf2/FluidR3_GM.sf2",
      isAsset: true,
      presetIndex: presetIndex,
    );
  }
}
