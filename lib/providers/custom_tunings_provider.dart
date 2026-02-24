import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/instrument_tuning.dart';

const String _customTuningsPrefsKey = 'custom_tunings';

class CustomTuningsNotifier extends StateNotifier<List<InstrumentTuning>> {
  CustomTuningsNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tuningsJson = prefs.getString(_customTuningsPrefsKey);
    if (tuningsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tuningsJson);
        state = decoded
            .map((e) => InstrumentTuning.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((t) => t.toJson()).toList());
    await prefs.setString(_customTuningsPrefsKey, json);
  }

  Future<void> addTuning(InstrumentTuning tuning) async {
    state = [...state, tuning];
    await _saveToPrefs();
  }

  Future<void> removeTuning(String tuningId) async {
    state = state.where((t) => t.id != tuningId).toList();
    await _saveToPrefs();
  }

  Future<void> updateTuning(InstrumentTuning tuning) async {
    state = state.map((t) => t.id == tuning.id ? tuning : t).toList();
    await _saveToPrefs();
  }
}

final customTuningsProvider =
    StateNotifierProvider<CustomTuningsNotifier, List<InstrumentTuning>>((ref) {
  return CustomTuningsNotifier();
});
