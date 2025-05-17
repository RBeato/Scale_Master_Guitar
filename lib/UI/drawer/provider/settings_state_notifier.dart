import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/drawer/models/settings_state.dart';
import 'package:test/models/settings_model.dart';

import '../UI/drawer/settings_enum.dart';
import '../storage/localstorage_service.dart';

final settingsStateNotifierProvider =
    StateNotifierProvider<SettingsStateNotifier, SettingsState>((ref) {
  return SettingsStateNotifier();
});

class SettingsStateNotifier extends StateNotifier<SettingsState> {
  SettingsStateNotifier() : super(const SettingsInitial()) {
    getSettings();
  }

  final LocalStorageService localStorageProvider = LocalStorageService();

  Future<Settings> get settings async {
    return await localStorageProvider.fetchSettings();
  }

  Future<void> getSettings() async {
    state = const SettingsLoading();
    try {
      final settings = await localStorageProvider.fetchSettings();
      state = SettingsLoaded(settings);
    } catch (e) {
      state = const SettingsError("Couldn't FETCH settings!");
    }
  }

  Future<void> changeValue(SettingsSelection settingSelection, value) async {
    try {
      debugPrint(
          "Attempting to change settings for: $settingSelection with value: $value");
      final settings =
          await localStorageProvider.changeSettings(settingSelection, value);
      debugPrint("Settings updated successfully.");
      state = SettingsLoaded(settings);
    } catch (e) {
      debugPrint("Error changing settings: $e");
      state = const SettingsError("Couldn't CHANGE the settings!");
    }
  }

  Future getFilteredValue(SettingsSelection settingSelection) async {
    try {
      final settings = await localStorageProvider.getFiltered(settingSelection);
      return settings;
    } catch (e) {
      // debugPrint("Didn't get filtered Value");
    }
  }

  Future<void> resetValues() async {
    try {
      final settings = await localStorageProvider.clearPreferences();
      state = SettingsLoaded(settings);
    } catch (e) {
      state = const SettingsError("Couldn't RESET the settings!");
    }
  }
}
