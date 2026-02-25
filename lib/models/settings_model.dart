import 'package:equatable/equatable.dart';

import '../UI/drawer/UI/drawer/settings_enum.dart';

abstract class JsonTo {
  Map<String, dynamic> toJson();
}

class Settings extends Equatable {
  bool showScaleDegrees;
  bool isSingleColor;
  bool isTonicUniversalBassNote;
  String keyboardSound;
  String bassSound;
  String drumsSound;

  Settings({
    this.showScaleDegrees = false,
    this.isSingleColor = false,
    this.isTonicUniversalBassNote = true,
    this.keyboardSound = 'Rhodes',
    this.bassSound = 'Double Bass',
    this.drumsSound = 'Acoustic',
  });

  dynamic get(SettingsSelection settingsSelection) {
    if (settingsSelection == SettingsSelection.bassSound) {
      return bassSound;
    }
    if (settingsSelection == SettingsSelection.drumsSound) {
      return drumsSound;
    }
    if (settingsSelection == SettingsSelection.keyboardSound) {
      return keyboardSound;
    }
    if (settingsSelection == SettingsSelection.tonicUniversalBassNote) {
      return isTonicUniversalBassNote;
    }
    if (settingsSelection == SettingsSelection.scaleDegrees) {
      return showScaleDegrees;
    }
    if (settingsSelection == SettingsSelection.singleColor) {
      return isSingleColor;
    }
  }

  @override
  List<Object> get props => [
        showScaleDegrees,
        isSingleColor,
        isTonicUniversalBassNote,
        keyboardSound,
        drumsSound,
        bassSound,
      ];

  @override
  String toString() {
    return 'Settings: '
        '\n $showScaleDegrees'
        '\n $isSingleColor'
        '\n $isTonicUniversalBassNote'
        '\n $keyboardSound'
        '\n $drumsSound'
        '\n $bassSound';
  }
}
