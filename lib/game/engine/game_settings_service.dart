import 'package:shared_preferences/shared_preferences.dart';

/// User-controlled audio preferences stored on the device.
class GameSettings {
  const GameSettings({
    this.musicEnabled = true,
    this.soundEnabled = true,
  });

  final bool musicEnabled;
  final bool soundEnabled;
}

/// Persists settings locally. These preferences do not imply that audio
/// playback assets are present or currently connected to the game.
class GameSettingsService {
  static const String _musicKey = 'loris_setting_music_enabled_v1';
  static const String _soundKey = 'loris_setting_sound_enabled_v1';

  Future<GameSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return GameSettings(
      musicEnabled: preferences.getBool(_musicKey) ?? true,
      soundEnabled: preferences.getBool(_soundKey) ?? true,
    );
  }

  Future<void> save(GameSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final musicSaved = await preferences.setBool(
      _musicKey,
      settings.musicEnabled,
    );
    final soundSaved = await preferences.setBool(
      _soundKey,
      settings.soundEnabled,
    );
    if (!musicSaved || !soundSaved) {
      throw StateError('Failed to save LORIS audio settings.');
    }
  }
}
