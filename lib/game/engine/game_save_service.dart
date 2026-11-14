
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_state_snapshot.dart';

/// Stores and retrieves a LORIS match on the device.
class GameSaveService {
  static const String _saveKey = 'loris_saved_match_v1';

  Future<void> save(GameStateSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(snapshot.toJson());

    final saved = await preferences.setString(
      _saveKey,
      encodedData,
    );

    if (!saved) {
      throw StateError('Failed to save LORIS match.');
    }
  }

  Future<GameStateSnapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();

    final savedData = preferences.getString(_saveKey);

    if (savedData == null || savedData.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(savedData);

    if (decoded is! Map) {
      throw const FormatException('Invalid saved game data.');
    }

    return GameStateSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<bool> hasSavedGame() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.containsKey(_saveKey);
  }

  Future<void> deleteSavedGame() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_saveKey);
  }
}
