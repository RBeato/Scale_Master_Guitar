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
        // For drums, we use a drum SoundFont based on user settings
        // The MIDI channel is set to 9 (drum channel) in sequencer_manager._syncTrack
        // MIDI note 44 = Hi-hat closed
        soundFontPath = _getDrumSoundfontPath(instSound);
        return Sf2Instrument(
          path: soundFontPath,
          isAsset: true,
          presetIndex: 0, // Use preset 0 - drum kits are typically at index 0
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
        return 'assets/sounds/sf2/yamaha_piano.sf2';          // Yamaha Piano - better dynamics
      case 'rhodes':
        return 'assets/sounds/sf2/rhodes.sf2';                // Dedicated Rhodes SF2
      case 'organ':
        return 'assets/sounds/sf2/dance_organ.sf2';           // Dance Organ (542KB)
      case 'pad':
        return 'assets/sounds/sf2/korg.sf2';                  // Korg Triton for pad sounds (6.9MB)
      default:
        return 'assets/sounds/sf2/korg.sf2';                  // Default fallback - Korg Triton
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

  /// Get drum soundfont path based on drum type
  static String _getDrumSoundfontPath(String drumSound) {
    switch (drumSound.toLowerCase()) {
      case 'acoustic':
        return 'assets/sounds/sf2/DrumsSlavo.sf2';        // Acoustic drums
      case 'electronic':
        return 'assets/sounds/sf2/808-Drums.sf2';         // Electronic 808 drums
      default:
        return 'assets/sounds/sf2/DrumsSlavo.sf2';        // Default fallback - acoustic
    }
  }
  
  /// Get correct preset index for flutter_sequencer_plus eff3773 compatibility
  static int? _getCorrectPresetIndex(SettingsSelection instrument, String instSound, String soundFontPath) {
    // For the specific eff3773 commit, we need to match the exact preset structure

    if (kDebugMode) {
      material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex] 🔍 CALLED');
      material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   Instrument: $instrument');
      material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   InstSound: $instSound');
      material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   SoundFontPath: $soundFontPath');
    }

    int? presetIndex;

    switch (instrument) {
      case SettingsSelection.drumsSound:
        // Drums use channel 9, preset index doesn't matter for percussion channel
        presetIndex = 0;
        if (kDebugMode) {
          material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Drums: returning preset 0');
        }
        return presetIndex;

      case SettingsSelection.keyboardSound:
        // For keyboards, SF2 files have presets starting at index 0
        // The logs show: "SF2 Loaded successfully: 1 presets available" means preset 0 is the only valid preset
        switch (instSound.toLowerCase()) {
          case 'piano':
            presetIndex = 0; // Use preset 0 (SF2 files are 0-indexed)
            if (kDebugMode) {
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Piano: returning preset 0 from j_piano.sf2');
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   ✅ Using J Piano SF2 (5.9MB)');
            }
            return presetIndex;
          case 'pad':
            presetIndex = 0; // Use preset 0
            if (kDebugMode) {
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Pad: returning preset 0 from korg.sf2');
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   ✅ Using Korg Triton for pad sounds');
            }
            return presetIndex;
          case 'rhodes':
            presetIndex = 0; // Use preset 0
            if (kDebugMode) {
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Rhodes: returning preset 0 from rhodes.sf2');
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   ✅ Using dedicated Rhodes SF2');
            }
            return presetIndex;
          case 'organ':
            presetIndex = 0; // Use preset 0
            if (kDebugMode) {
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Organ: returning preset 0 from dance_organ.sf2');
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   ✅ Using dedicated Dance Organ SF2');
            }
            return presetIndex;
          default:
            presetIndex = 0; // Use preset 0
            if (kDebugMode) {
              material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Unknown keyboard: defaulting to preset 0');
            }
            return presetIndex;
        }

      case SettingsSelection.bassSound:
        // For bass, SF2 files have presets starting at index 0
        presetIndex = 0; // Fixed: Use preset 0 (SF2 files are 0-indexed)
        if (kDebugMode) {
          material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Bass: returning preset 0');
        }
        return presetIndex;

      default:
        presetIndex = 0; // Fixed: Use preset 0 as default
        if (kDebugMode) {
          material.debugPrint('[SoundPlayerUtils._getCorrectPresetIndex]   → Unknown instrument: defaulting to preset 0');
        }
        return presetIndex;
    }
  }
}
