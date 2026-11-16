import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loris_card_game/game/engine/game_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses enabled defaults when no settings have been saved', () async {
      final settings = await GameSettingsService().load();

      expect(settings.musicEnabled, isTrue);
      expect(settings.soundEnabled, isTrue);
    });

    test('persists and restores both audio preferences', () async {
      final service = GameSettingsService();
      const settings = GameSettings(
        musicEnabled: false,
        soundEnabled: true,
      );

      await service.save(settings);
      final restored = await service.load();

      expect(restored.musicEnabled, isFalse);
      expect(restored.soundEnabled, isTrue);
    });

    test('persists both preferences when both are disabled', () async {
      final service = GameSettingsService();
      const settings = GameSettings(
        musicEnabled: false,
        soundEnabled: false,
      );

      await service.save(settings);
      final restored = await service.load();

      expect(restored.musicEnabled, isFalse);
      expect(restored.soundEnabled, isFalse);
    });
  });
}
