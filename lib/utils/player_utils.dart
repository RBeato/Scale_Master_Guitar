import 'package:flutter_sequencer/models/instrument.dart';
import 'package:scalemasterguitar/models/settings_model.dart';
import '../constants/gm_programs.dart';
import '../UI/drawer/UI/drawer/settings_enum.dart';
import 'package:flutter/material.dart' as material;
class SoundPlayerUtils {
  static List<Instrument> getInstruments(Settings settings, {bool onlyKeys = false}) {
    if (onlyKeys) {
      // For home page piano, still create the expected 3-track structure
      // but use piano instrument for all tracks to maintain compatibility with SequencerManager
      final pianoInstrument = _getSound(SettingsSelection.keyboardSound, settings.keyboardSound);
      return [
        pianoInstrument, // Track 0: Piano (instead of drums)
        pianoInstrument, // Track 1: Piano (expected piano track)
        pianoInstrument, // Track 2: Piano (instead of bass)
      ];
    }
    
    // Match the working reference app's track order: [Drums, Piano, Bass]
    List<Instrument> instruments = [
      _getSound(SettingsSelection.drumsSound, settings.drumsSound),
      _getSound(SettingsSelection.keyboardSound, settings.keyboardSound),
      _getSound(SettingsSelection.bassSound, settings.bassSound),
    ];
    return instruments;
  }

  static Sf2Instrument _getSound(SettingsSelection instrument, String instSound) {
    String gmName = '';
    String soundFontPath = '';
    
    switch (instrument) {
      case SettingsSelection.keyboardSound:
        gmName = instSound;
        // Use dedicated SF2 files based on instrument type
        soundFontPath = _getKeyboardSoundfontPath(instSound);
        break;
      case SettingsSelection.bassSound:
        gmName = instSound;
        // Use dedicated SF2 files based on bass type
        soundFontPath = _getBassSoundfontPath(instSound);
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
      material.debugPrint('[SoundPlayerUtils] PIANO: Using GM Piano preset $presetIndex');
      material.debugPrint('[SoundPlayerUtils] PIANO: SoundFont path is $soundFontPath (optimized for iOS compatibility)');
    }
    
    return Sf2Instrument(
      path: soundFontPath,
      isAsset: true,
      presetIndex: presetIndex,
    );
  }
  
  /// Get keyboard soundfont path based on instrument type
  static String _getKeyboardSoundfontPath(String instrumentSound) {
    switch (instrumentSound.toLowerCase()) {
      case 'piano':
        return 'assets/sounds/sf2/j_piano.sf2';       // Proven to work on iOS TestFlight
      case 'rhodes':
        return 'assets/sounds/sf2/rhodes.sf2';        // Dedicated Rhodes SF2
      case 'organ':
        return 'assets/sounds/sf2/korg.sf2';          // Dedicated Korg SF2
      case 'pad':
        return 'assets/sounds/sf2/j_piano.sf2';       // Use piano for pad sounds
      default:
        return 'assets/sounds/sf2/j_piano.sf2';       // Default fallback
    }
  }
  
  /// Get bass soundfont path based on bass type
  static String _getBassSoundfontPath(String bassSound) {
    switch (bassSound.toLowerCase()) {
      case 'double bass':
      case 'acoustic':
        return 'assets/sounds/sf2/acoustic_bass.sf2';     // Dedicated acoustic bass
      case 'electric':
      case 'bass guitar':
        return 'assets/sounds/sf2/BassGuitars.sf2';       // Proven electric bass SF2
      case 'synth':
      case 'synthesizer':
        return 'assets/sounds/sf2/BassGuitars.sf2';       // Use electric bass for synth
      default:
        return 'assets/sounds/sf2/BassGuitars.sf2';       // Default fallback
    }
  }
}
