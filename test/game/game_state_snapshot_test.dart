import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/game_state_snapshot.dart';

void main() {
  group('GameStateSnapshot versioning', () {
    test('loads version 1 snapshots', () {
      final snapshot = GameStateSnapshot.fromJson({
        'version': 1,
        'dealerIndex': 0,
        'dealerAdvanced': false,
        'teamAScore': 0,
        'teamBScore': 0,
      });

      expect(snapshot.version, 1);
      expect(snapshot.dealerIndex, 0);
    });

    test('rejects snapshots from unsupported future versions', () {
      expect(
        () => GameStateSnapshot.fromJson({
          'version': 2,
          'dealerIndex': 0,
          'dealerAdvanced': false,
          'teamAScore': 0,
          'teamBScore': 0,
        }),
        throwsFormatException,
      );
    });
  });
}
