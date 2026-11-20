
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/game_round_controller.dart';
import 'package:loris_card_game/game/engine/sixteen_call_engine.dart';
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

    test('Passing 16 closes the option and keeps normal play active', () {
      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      expect(controller.sixteenCallEngine!.canCall, isTrue);

      controller.pass16(passerPlayerIndex: 0);

      expect(
        controller.sixteenCallEngine!.status,
        SixteenCallStatus.passed,
      );
      expect(controller.sixteenCallEngine!.canCall, isFalse);
      expect(controller.isRoundEnded, isFalse);

      playOneTrick();

      expect(controller.sixteenCallEngine!.canCall, isFalse);
      expect(controller.isRoundEnded, isFalse);
    });

    test('Does not offer 16 after opponents win any trick before the bid is reached', () {
      final hands = List.generate(4, (_) => <Card>[]);

      void addTrickColumn(Suit suit, List<int> ranks) {
        for (var player = 0; player < 4; player++) {
          hands[player].add(Card.normal(suit: suit, rank: ranks[player]));
        }
      }

      // Trick winners in order: opponent 1, then bidding-team players
      // 2, 0, 2, 0. The team reaches its four-trick bid after trick five,
      // but its earlier loss permanently disables the 16-call option.
      addTrickColumn(Suit.clubs, [7, 14, 8, 9]);
      addTrickColumn(Suit.hearts, [10, 11, 14, 12]);
      addTrickColumn(Suit.diamonds, [14, 7, 8, 9]);
      addTrickColumn(Suit.spades, [10, 11, 14, 12]);
      addTrickColumn(Suit.clubs, [13, 10, 11, 12]);

      hands[0].addAll([
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 10),
        Card.normal(suit: Suit.spades, rank: 8),
      ]);
      hands[1].addAll([
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.diamonds, rank: 11),
        Card.normal(suit: Suit.spades, rank: 9),
      ]);
      hands[2].addAll([
        Card.normal(suit: Suit.hearts, rank: 9),
        Card.normal(suit: Suit.diamonds, rank: 12),
        Card.normal(suit: Suit.spades, rank: 13),
      ]);
      hands[3].addAll([
        Card.normal(suit: Suit.hearts, rank: 13),
        Card.normal(suit: Suit.diamonds, rank: 13),
        Card.loris(replacesRank: 7),
      ]);

      controller = GameRoundController(
        hands: hands,
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
      );

      for (var i = 0; i < 5; i++) {
        playOneTrick();
      }

      expect(controller.completedTricks, 5);
      expect(controller.biddingTeamTricks, 4);
      expect(controller.sixteenCallEngine!.canCall, isFalse);
      expect(
        () => controller.call16(callerPlayerIndex: 0),
        throwsStateError,
      );
      expect(controller.isRoundEnded, isFalse);
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
