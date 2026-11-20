import 'package:test/test.dart';
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
        (player) => List.generate(
          8,
          (_) => Card.normal(
            suit: Suit.clubs,
            // Team A wins each fixture trick, allowing the 16-call
            // test to reach the required bid number of tricks.
            rank: switch (player) {
              0 => 14,
              1 => 10,
              2 => 13,
              _ => 9,
            },
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

    void playOneTrick({bool resolve16Decision = true}) {
      for (var i = 0; i < 4; i++) {
        final player = controller.trickEngine.currentPlayerIndex;
        final card = controller.trickEngine.hands[player].first;

        controller.playCard(player, card);
      }

      final winner = controller.completeTrick();
      if (resolve16Decision && controller.sixteenCallEngine?.canCall == true) {
        controller.pass16(callerPlayerIndex: winner);
      }
    }

    test('Starts with the dealer right player', () {
      expect(controller.nextPlayerIndex, 0);
    });

    test('Blocks 16 Call when bidding team already has 16 points', () {
      matchScore.teamAScore = 16;
      controller = GameRoundController(
        hands: createHands(),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
      );

      for (var i = 0; i < 4; i++) {
        playOneTrick(resolve16Decision: false);
      }

      expect(controller.sixteenCallEngine!.canCall, isFalse);
      expect(
        () => controller.call16(callerPlayerIndex: 0),
        throwsStateError,
      );
    });

    test('Allows skipping after the bid target is reached and 16 is passed', () {
      for (var i = 0; i < 4; i++) {
        playOneTrick();
      }

      expect(controller.sixteenCallEngine!.status, SixteenCallStatus.passed);
      expect(controller.canSkipRemainingTricks, isTrue);

      controller.skipRemainingTricks();

      expect(controller.isRoundEnded, isTrue);
      expect(controller.isRoundScored, isTrue);
      expect(matchScore.teamAScore, 4);
      expect(matchScore.teamBScore, -4);
    });

    test('Does not allow skipping while 16 call is still available', () {
      for (var i = 0; i < 3; i++) {
        playOneTrick();
      }
      playOneTrick(resolve16Decision: false);

      expect(controller.sixteenCallEngine!.canCall, isTrue);
      expect(controller.canSkipRemainingTricks, isFalse);
      expect(
        controller.skipRemainingTricks,
        throwsStateError,
      );
    });

    test('Allows skipping an 8 bid after the first lost trick', () {
      final hands = List.generate(4, (player) {
        return List.generate(8, (i) => Card.normal(
          suit: Suit.clubs,
          rank: (player == 1 || player == 3) ? 14 - i : 7 + i,
        ));
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

      playOneTrick();

      expect(controller.canSkipRemainingTricks, isTrue);
      controller.skipRemainingTricks();
      expect(controller.isRoundEnded, isTrue);
      expect(matchScore.teamAScore, -16);
      expect(matchScore.teamBScore, 16);
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

    test('Pauses the next trick until the human passes the 16 decision', () {
      for (var trick = 0; trick < 4; trick++) {
        for (var i = 0; i < 4; i++) {
          final player = controller.trickEngine.currentPlayerIndex;
          final card = controller.trickEngine.hands[player].first;
          controller.playCard(player, card);
        }
        if (trick < 3) {
          controller.completeTrick();
        }
      }
      // The fourth trick is complete on the table; complete it to open the
      // CALL 16 decision window before the next trick begins.
      controller.completeTrick();

      expect(controller.sixteenCallEngine!.canCall, isTrue);
      final nextPlayer = controller.nextPlayerIndex!;
      final nextCard = controller.trickEngine.hands[nextPlayer].first;
      expect(
        () => controller.playCard(nextPlayer, nextCard),
        throwsStateError,
      );

      controller.pass16(callerPlayerIndex: 0);
      expect(controller.sixteenCallEngine!.status, SixteenCallStatus.passed);
      expect(
        () => controller.playCard(nextPlayer, nextCard),
        returnsNormally,
      );
    });

    test('Applies 16 Call success points only once', () {
      // Bid is 4: call 16 immediately after the bidding team reaches four tricks.
      for (var i = 0; i < 3; i++) {
        playOneTrick();
      }
      playOneTrick(resolve16Decision: false);

      controller.call16(callerPlayerIndex: 0);

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

    test('Successful 8 bid scores +16 when bidding team wins all 8 tricks', () {
      controller = GameRoundController(
        hands: createHands(),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 8,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(controller.isRoundEnded, isTrue);
      expect(controller.isRoundScored, isTrue);
      expect(matchScore.teamAScore, 16);
      expect(matchScore.teamBScore, -16);
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
