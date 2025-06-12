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
    String gmName = '';
    String soundFontPath = '';
    
    switch (instrument) {
      case SettingsSelection.keyboardSound:
        gmName = instSound;
        soundFontPath = "assets/sounds/sf2/GeneralUser-GS.sf2";
        break;
      case SettingsSelection.bassSound:
        gmName = instSound;
        soundFontPath = "assets/sounds/sf2/GeneralUser-GS.sf2";
        break;
      case SettingsSelection.drumsSound:
        // For drums, we use the dedicated drum SoundFont
        // and channel 9 (drums channel in MIDI)
        soundFontPath = "assets/sounds/sf2/DrumsSlavo.sf2";
        // For drum channel, preset doesn't matter as much since it's percussion
        return Sf2Instrument(
          path: soundFontPath,
          isAsset: true,
          presetIndex: 0, // Standard drum kit
        );
      default:
        throw Exception('Unknown instrument type: $instrument');
    }

    final presetIndex = gmProgramNumbers[gmName];
    if (presetIndex == null) {
      material.debugPrint('[SoundPlayerUtils] ERROR: No GM program for instrument: $instrument, instSound: $instSound');
      throw Exception('No GM program for instrument: $instrument, instSound: $instSound');
    }
    
    // Enhanced debugging for piano sound quality issues
    material.debugPrint('[SoundPlayerUtils] Creating instrument:');
    material.debugPrint('[SoundPlayerUtils]   Type: $instrument');
    material.debugPrint('[SoundPlayerUtils]   Sound: $instSound');
    material.debugPrint('[SoundPlayerUtils]   PresetIndex: $presetIndex');
    material.debugPrint('[SoundPlayerUtils]   SoundFont: $soundFontPath');
    
    // For piano specifically, add extra debugging
    if (instrument == SettingsSelection.keyboardSound && gmName == 'Piano') {
      material.debugPrint('[SoundPlayerUtils] PIANO: Using GM Piano preset $presetIndex (Electric Piano 1 for iOS compatibility)');
      material.debugPrint('[SoundPlayerUtils] PIANO: SoundFont path is assets/sounds/sf2/GeneralUser-GS.sf2');
    }
    
    return Sf2Instrument(
      path: soundFontPath,
      isAsset: true,
      presetIndex: presetIndex,
    );
  }
}
