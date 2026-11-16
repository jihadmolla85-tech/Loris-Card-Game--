
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/game_round_controller.dart';
import 'package:loris_card_game/game/engine/bid_scoring_engine.dart';
import 'package:loris_card_game/game/engine/match_score_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Game Round Controller', () {
    late MatchScoreEngine matchScore;
    late BidScoringEngine bidScore;

    List<List<Card>> createHands() {
      return List.generate(
        4,
        (_) => List.generate(
          8,
          (i) => Card.normal(
            suit: Suit.clubs,
            rank: 7 + i,
          ),
        ),
      );
    }

    late GameRoundController controller;

    setUp(() {
      matchScore = MatchScoreEngine();
      bidScore = BidScoringEngine();

      controller = GameRoundController(
        hands: createHands(),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
      );
    });

    void playOneTrick() {
      for (var i = 0; i < 4; i++) {
        final player = controller.trickEngine.currentPlayerIndex;
        final card = controller.trickEngine.hands[player].first;

        controller.playCard(player, card);
      }

      controller.completeTrick();
    }

    test('Starts with the dealer right player', () {
      expect(controller.nextPlayerIndex, 0);
    });

    test('Scores the round after eight tricks', () {
      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isTrue);
      expect(controller.isRoundScored, isTrue);
      expect(matchScore.teamAScore, 4);
      expect(matchScore.teamBScore, -4);
    });

    test('Does not score the round before it ends', () {
      for (var i = 0; i < 7; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isFalse);
      expect(controller.isRoundScored, isFalse);
      expect(matchScore.teamAScore, 0);
      expect(matchScore.teamBScore, 0);
    });

    test('Prevents playing cards after the round ends', () {
      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(
        () => controller.playCard(
          0,
          Card.normal(suit: Suit.clubs, rank: 7),
        ),
        throwsStateError,
      );
    });

    test('Applies 16 Call success points only once', () {
      // The team can call immediately after reaching its four-trick bid,
      // provided the opponents have not won a trick.
      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      controller.call16(callerPlayerIndex: 0);

      // Four tricks remain in the eight-trick round.
      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isTrue);
      expect(matchScore.teamAScore, 16);
      expect(matchScore.teamBScore, -16);
    });

    test('Detects match winner after round scoring', () {
      matchScore.teamAScore = 28;
      matchScore.teamBScore = -28;

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(controller.matchWinner, MatchWinner.teamA);
    });

    test('Keeps the same dealer during redeal', () {
      expect(
        controller.getNextDealerIndex(isRedeal: true),
        3,
      );
    });

    test('Handles an 8 bid without enabling 16 Call', () {
      final hands = List.generate(4, (player) {
        return List.generate(8, (i) {
          final rank = (player == 1 || player == 3)
              ? 14 - i
              : 7 + i;

          return Card.normal(
            suit: Suit.clubs,
            rank: rank,
          );
        });
      });

      controller = GameRoundController(
        hands: hands,
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 8,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
      );

      expect(
        () => controller.call16(callerPlayerIndex: 0),
        throwsStateError,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isTrue);
      expect(controller.isRoundScored, isTrue);
      expect(matchScore.teamAScore, -16);
      expect(matchScore.teamBScore, 16);
    });
  });
}
