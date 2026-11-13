import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/trick_scoring_engine.dart';

void main() {
  group('LORIS Trick Scoring - 4 Players', () {
    late TrickScoringEngine scoring;

    setUp(() {
      scoring = TrickScoringEngine(playerCount: 4);
    });

    test('one trick gives one point to winner team', () {
      scoring.recordTrickWinner(0);

      expect(scoring.teamAScore, 1);
      expect(scoring.teamBScore, 0);
    });

    test('team members share their trick points', () {
      scoring.recordTrickWinner(0);
      scoring.recordTrickWinner(2);
      scoring.recordTrickWinner(1);

      expect(scoring.teamATricks, 2);
      expect(scoring.teamBTricks, 1);
    });

    test('individual player tricks are counted', () {
      scoring.recordTrickWinner(2);
      scoring.recordTrickWinner(2);
      scoring.recordTrickWinner(0);

      expect(scoring.playerTricks[2], 2);
      expect(scoring.playerTricks[0], 1);
    });

    test('round completes after eight tricks', () {
      for (var i = 0; i < 8; i++) {
        scoring.recordTrickWinner(i % 4);
      }

      expect(scoring.totalTricks, 8);
      expect(scoring.isRoundComplete, true);
    });

    test('cannot record more than eight tricks', () {
      for (var i = 0; i < 8; i++) {
        scoring.recordTrickWinner(i % 4);
      }

      expect(
        () => scoring.recordTrickWinner(0),
        throwsStateError,
      );
    });

    test('invalid player index is rejected', () {
      expect(
        () => scoring.recordTrickWinner(4),
        throwsArgumentError,
      );
    });

    test('round scores can be reset', () {
      scoring.recordTrickWinner(0);
      scoring.recordTrickWinner(1);

      scoring.resetRound();

      expect(scoring.totalTricks, 0);
      expect(scoring.teamAScore, 0);
      expect(scoring.teamBScore, 0);
    });
  });

  group('LORIS Trick Scoring - 6 Players', () {
    late TrickScoringEngine scoring;

    setUp(() {
      scoring = TrickScoringEngine(playerCount: 6);
    });

    test('three players belong to each team', () {
      scoring.recordTrickWinner(0);
      scoring.recordTrickWinner(2);
      scoring.recordTrickWinner(4);

      scoring.recordTrickWinner(1);
      scoring.recordTrickWinner(3);
      scoring.recordTrickWinner(5);

      expect(scoring.teamATricks, 3);
      expect(scoring.teamBTricks, 3);
    });

    test('eight tricks are distributed correctly', () {
      final winners = [0, 2, 4, 1, 3, 5, 0, 2];

      for (final winner in winners) {
        scoring.recordTrickWinner(winner);
      }

      expect(scoring.totalTricks, 8);
      expect(scoring.teamATricks, 5);
      expect(scoring.teamBTricks, 3);
      expect(scoring.isRoundComplete, true);
    });

    test('invalid player count is rejected', () {
      expect(
        () => TrickScoringEngine(playerCount: 5),
        throwsArgumentError,
      );
    });
  });
}
