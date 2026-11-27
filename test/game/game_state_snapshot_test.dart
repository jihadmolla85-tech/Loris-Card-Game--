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
      expect(snapshot.hasSixteenCallState, isFalse);
    });

    test('round-trips the one-time 16-call decision through JSON', () {
      const snapshot = GameStateSnapshot(
        dealerIndex: 1,
        dealerAdvanced: false,
        teamAScore: 0,
        teamBScore: 0,
        playerCount: 6,
        completedTricks: 4,
        biddingTeamTricks: 4,
        sixteenCallStatus: 'passed',
        sixteenCompletedTricks: 4,
        sixteenBiddingTeamTricks: 4,
        sixteenLastTrickWinnerIndex: 3,
      );

      final restored = GameStateSnapshot.fromJson(snapshot.toJson());

      expect(restored.sixteenCallStatus, 'passed');
      expect(restored.sixteenCompletedTricks, 4);
      expect(restored.sixteenBiddingTeamTricks, 4);
      expect(restored.sixteenLastTrickWinnerIndex, 3);
      expect(restored.sixteenCallerIndex, isNull);
      expect(restored.hasSixteenCallState, isTrue);
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
