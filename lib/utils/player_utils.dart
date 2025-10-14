import 'package:flutter/foundation.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:scalemasterguitar/models/settings_model.dart';
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

    // Use correct preset indices based on what's actually available in the SF2 files
    final presetIndex = _getCorrectPresetIndex(instrument, instSound, soundFontPath);
    if (presetIndex == null) {
      if (kDebugMode) {
        material.debugPrint('[SoundPlayerUtils] ERROR: No preset available for instrument: $instrument, instSound: $instSound');
      }
      throw Exception('No preset available for instrument: $instrument, instSound: $instSound');
    }
    
    if (kDebugMode) {
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
    }
    
    // For flutter_sequencer_plus eff3773, ensure proper SF2 instrument creation
    final sf2Instrument = Sf2Instrument(
      path: soundFontPath,
      isAsset: true,
      presetIndex: presetIndex,
    );
    
    if (kDebugMode) {
      material.debugPrint('[SoundPlayerUtils] Created SF2 Instrument:');
      material.debugPrint('[SoundPlayerUtils]   Path: ${sf2Instrument.idOrPath}');
      material.debugPrint('[SoundPlayerUtils]   IsAsset: ${sf2Instrument.isAsset}');
      material.debugPrint('[SoundPlayerUtils]   PresetIndex: ${sf2Instrument.presetIndex}');
      material.debugPrint('[SoundPlayerUtils]   DisplayName: ${sf2Instrument.displayName}');
    }
    
    return sf2Instrument;
  }
  
  /// Get keyboard soundfont path based on instrument type
  static String _getKeyboardSoundfontPath(String instrumentSound) {
    switch (instrumentSound.toLowerCase()) {
      case 'piano':
        return 'assets/sounds/sf2/korg.sf2';          // Korg Triton - better quality (6.9MB)
      case 'rhodes':
        return 'assets/sounds/sf2/rhodes.sf2';        // Dedicated Rhodes SF2
      case 'organ':
        return 'assets/sounds/sf2/korg.sf2';          // Dedicated Korg SF2
      case 'pad':
        return 'assets/sounds/sf2/korg.sf2';          // Use Korg for pad sounds
      default:
        return 'assets/sounds/sf2/korg.sf2';          // Default fallback - Korg Triton
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
  
  /// Get correct preset index for flutter_sequencer_plus eff3773 compatibility
  static int? _getCorrectPresetIndex(SettingsSelection instrument, String instSound, String soundFontPath) {
    // For the specific eff3773 commit, we need to match the exact preset structure
    switch (instrument) {
      case SettingsSelection.drumsSound:
        // Drums use channel 9, preset index doesn't matter for percussion channel
        return 0;
        
      case SettingsSelection.keyboardSound:
        // For keyboards, use GM program numbers that map to valid presets
        switch (instSound.toLowerCase()) {
          case 'piano':
            return 1; // Try preset 1 for piano (eff3773 may have different mapping)
          case 'pad':
            return 1; // Use same preset for pad sounds
          case 'rhodes':
            return 1; 
          case 'organ':
            return 1;
          default:
            return 1;
        }
        
      case SettingsSelection.bassSound:
        // For bass, use preset that should exist in BassGuitars.sf2
        return 1; // Try preset 1 instead of 0
        
      default:
        return 1;
    }
  }
}
