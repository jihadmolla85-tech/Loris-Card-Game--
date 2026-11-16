import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/game_save_service.dart';
import 'package:loris_card_game/game/engine/game_state_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GameSaveService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = GameSaveService();
  });

  const snapshot = GameStateSnapshot(
    dealerIndex: 2,
    dealerAdvanced: true,
    teamAScore: 12,
    teamBScore: -12,
    playerCount: 4,
    completedTricks: 3,
    biddingTeam: 0,
    bidAmount: 5,
  );

  group('GameSaveService', () {
    test('returns null when no match has been saved', () async {
      expect(await service.load(), isNull);
      expect(await service.hasSavedGame(), isFalse);
    });

    test('saves and restores a match snapshot', () async {
      await service.save(snapshot);
      final restored = await service.load();

      expect(restored, isNotNull);
      expect(restored!.version, snapshot.version);
      expect(restored.dealerIndex, snapshot.dealerIndex);
      expect(restored.dealerAdvanced, isTrue);
      expect(restored.teamAScore, 12);
      expect(restored.teamBScore, -12);
      expect(restored.playerCount, 4);
      expect(restored.completedTricks, 3);
      expect(restored.biddingTeam, 0);
      expect(restored.bidAmount, 5);
      expect(await service.hasSavedGame(), isTrue);
    });

    test('deletes the saved match', () async {
      await service.save(snapshot);
      await service.deleteSavedGame();

      expect(await service.load(), isNull);
      expect(await service.hasSavedGame(), isFalse);
    });

    test('reports malformed saved JSON instead of silently restoring it', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('loris_saved_match_v1', '{broken');

      expect(service.load(), throwsFormatException);
    });

    test('rejects a saved value that is not a JSON object', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('loris_saved_match_v1', '[]');

      expect(service.load(), throwsA(isA<FormatException>()));
    });
  });
}
