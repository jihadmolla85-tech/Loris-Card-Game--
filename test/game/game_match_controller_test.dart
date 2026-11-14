import 'dart:math';
import 'package:loris_card_game/game/engine/deal_controller.dart';
import 'package:loris_card_game/game/engine/deck_shuffle_engine.dart';
import 'package:loris_card_game/game/engine/deck_validation_engine.dart';
import 'package:loris_card_game/game/engine/redeal_controller.dart';
import 'package:loris_card_game/game/engine/redeal_validation_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/game_match_controller.dart';
import 'package:loris_card_game/game/engine/match_score_engine.dart';
import 'package:loris_card_game/game/engine/bid_scoring_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Game Match Controller', () {
    late MatchScoreEngine matchScore;
    late BidScoringEngine bidScore;
    late GameMatchController match;

    List<List<Card>> createHands({
      bool teamBWins = false,
    }) {
      return List.generate(4, (player) {
        return List.generate(8, (i) {
          final rank = teamBWins
              ? (player == 3 ? 14 - i : 7 + i)
              : (player == 0 ? 14 - i : 7 + i);

          return Card.normal(
            suit: Suit.clubs,
            rank: rank,
          );
        });
      });
    }

    setUp(() {
      matchScore = MatchScoreEngine();
      bidScore = BidScoringEngine();

            match = GameMatchController(
        initialDealerIndex: 3,
        matchScoreEngine: matchScore,
        bidScoringEngine: bidScore,
        dealController: DealController(
          shuffleEngine: DeckShuffleEngine(
            random: Random(42),
          ),
          redealController: RedealController(
            validationEngine: RedealValidationEngine(),
          ),
          deckValidationEngine: DeckValidationEngine(),
        ),
      );
    });

    void playOneTrick() {
      final round = match.currentRound;

      for (var i = 0; i < 4; i++) {
        final player = round.trickEngine.currentPlayerIndex;
        final card = round.trickEngine.hands[player].first;

        match.playCard(player, card);
      }

      match.completeTrick();
    }

    test('Starts with the initial dealer', () {
      expect(match.dealerIndex, 3);
      expect(match.hasStarted, isFalse);
      expect(match.nextPlayerIndex, isNull);
    });

    test('Starts a new round using the current dealer', () {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      expect(match.hasStarted, isTrue);
      expect(match.currentRound.dealerIndex, 3);
      expect(match.nextPlayerIndex, 0);
    });

    test('Prevents starting another round before current round ends', () {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      expect(
        () => match.startRound(
          hands: createHands(),
              List<Card> createDeck() {
      final ranks = List.generate(8, (i) => i + 7);

      return [
        for (final suit in Suit.values)
          for (final rank in ranks)
            if (!(suit == Suit.spades && rank == 7))
              Card.normal(suit: suit, rank: rank),
        Card.loris(replacesRank: 7),
      ];
    }
          trumpSuit: Suit.spades,
          biddingTeam: 0,
          bidAmount: 4,
        ),
        throwsStateError,
      );
    });

    test('Keeps the dealer when the dealer team score is below 1', () {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(match.dealerIndex, 3);
    });

    test('Rotates dealer when dealer team reaches at least 1 point', () {
      match.startRound(
        hands: createHands(teamBWins: true),
        trumpSuit: Suit.spades,
        biddingTeam: 1,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(matchScore.teamBScore, 4);
      expect(match.dealerIndex, 0);
    });

    test('Detects match winner and prevents another round', () {
      matchScore.teamAScore = 28;
      matchScore.teamBScore = -28;

      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(match.isMatchOver, isTrue);
      expect(match.matchWinner, MatchWinner.teamA);

      expect(
        () => match.startRound(
          hands: createHands(),
          trumpSuit: Suit.spades,
          biddingTeam: 0,
          bidAmount: 4,
        ),
        throwsStateError,
      );
    });

    test('Does not advance dealer more than once', () {
      match.startRound(
        hands: createHands(teamBWins: true),
        trumpSuit: Suit.spades,
        biddingTeam: 1,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(match.dealerIndex, 0);
    });
    test('Starts a round by dealing cards automatically', () {
      final hands = match.startRoundWithDeal(
        deck: createDeck(),
        playerCount: 4,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      expect(hands.length, 4);
      expect(hands.every((hand) => hand.length == 8), isTrue);
      expect(match.hasStarted, isTrue);
      expect(match.currentRound.dealerIndex, 3);
      expect(match.nextPlayerIndex, 0);
    });
    test('Supports a six-player match', () {
      final sixPlayerMatch = GameMatchController(
        initialDealerIndex: 5,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
      );

      final hands = List.generate(
        6,
        (_) => List.generate(
          8,
          (i) => Card.normal(
            suit: Suit.clubs,
            rank: 7 + i,
          ),
        ),
      );

      sixPlayerMatch.startRound(
        hands: hands,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      expect(sixPlayerMatch.currentRound.dealerIndex, 5);
      expect(sixPlayerMatch.nextPlayerIndex, 0);
    });

    test('Rejects an invalid player count', () {
      final invalidHands = List.generate(
        5,
        (_) => List.generate(
          8,
          (i) => Card.normal(
            suit: Suit.clubs,
            rank: 7 + i,
          ),
        ),
      );

      expect(
        () => match.startRound(
          hands: invalidHands,
          trumpSuit: Suit.spades,
          biddingTeam: 0,
          bidAmount: 4,
        ),
        throwsArgumentError,
      );
    });
  });
}
