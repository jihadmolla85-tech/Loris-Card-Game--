
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/match_score_engine.dart';

void main() {
  group('LORIS Match Score Engine', () {
    late MatchScoreEngine engine;

    setUp(() {
      engine = MatchScoreEngine();
    });

    test('Starts with zero scores', () {
      expect(engine.teamAScore, 0);
      expect(engine.teamBScore, 0);
    });

    test('Adds round scores correctly', () {
      final winner = engine.applyRoundScore(
        teamAPoints: 6,
        teamBPoints: -6,
      );

      expect(engine.teamAScore, 6);
      expect(engine.teamBScore, -6);
      expect(winner, MatchWinner.none);
    });

    test('Team A wins after reaching 32', () {
      final winner = engine.applyRoundScore(
        teamAPoints: 32,
        teamBPoints: -32,
      );

      expect(winner, MatchWinner.teamA);
    });

    test('Team B wins after reaching 32', () {
      final winner = engine.applyRoundScore(
        teamAPoints: -32,
        teamBPoints: 32,
      );

      expect(winner, MatchWinner.teamB);
    });

    test('Checks winner only after round score is applied', () {
      engine.applyRoundScore(
        teamAPoints: 20,
        teamBPoints: -20,
      );

      expect(engine.checkWinner(), MatchWinner.none);

      final winner = engine.applyRoundScore(
        teamAPoints: 12,
        teamBPoints: -12,
      );

      expect(winner, MatchWinner.teamA);
    });

    test('Supports negative accumulated scores', () {
      engine.applyRoundScore(
        teamAPoints: -8,
        teamBPoints: 8,
      );

      expect(engine.teamAScore, -8);
      expect(engine.teamBScore, 8);
      expect(engine.checkWinner(), MatchWinner.none);
    });

    test('Rejects non-zero-sum round scores', () {
      expect(
        () => engine.applyRoundScore(
          teamAPoints: 5,
          teamBPoints: 2,
        ),
        throwsArgumentError,
      );
    });

    test('Resets match scores', () {
      engine.applyRoundScore(
        teamAPoints: 10,
        teamBPoints: -10,
      );

      engine.resetMatch();

      expect(engine.teamAScore, 0);
      expect(engine.teamBScore, 0);
      expect(engine.checkWinner(), MatchWinner.none);
    });
  });
}
