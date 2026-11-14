
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
        () => controller.playCard(0, Card.normal(
          suit: Suit.clubs,
          rank: 7,
        )),
        throwsStateError,
      );
    });

    test('Applies 16 Call success points only once', () {
      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      controller.call16(callerPlayerIndex: 0);

      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isTrue);
      expect(matchScore.teamAScore, 16);
      expect(matchScore.teamBScore, -16);

      // 16 Call points must not be added to Bid Scoring again.
      expect(bidScore.teamAScore, 0);
      expect(bidScore.teamBScore, 0);
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
  });
}
