import 'package:flutter_sequencer/models/instrument.dart';
import 'package:test/models/settings_model.dart';

import '../UI/drawer/UI/drawer/settings_enum.dart';
import '../constants.dart';

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
    String key = '';
    switch (instrument) {
      case SettingsSelection.keyboardSound:
        key = 'keys';
        break;
      case SettingsSelection.bassSound:
        key = 'bass';
        break;
      case SettingsSelection.drumsSound:
        key = 'drums';
        break;
    }

    String sound = '';

    if (key == 'keys' && instSound == 'Piano') {
      sound = 'Piano';
    }
    if (key == 'keys' && instSound == 'Rhodes') {
      sound = 'Rhodes';
    }
    if (key == 'bass' && instSound == 'Double Bass') {
      sound = 'Double Bass';
    }
    if (key == 'bass' && instSound == 'Electric') {
      sound = 'Electric';
    }
    if (key == 'drums' && instSound == 'Electronic') {
      sound = 'Electronic';
    }
    if (key == 'drums' && instSound == 'Acoustic') {
      sound = 'Acoustic';
    }

    return Sf2Instrument(
        path: Constants.soundPath[key]![sound] as String, isAsset: true);
  }
}
