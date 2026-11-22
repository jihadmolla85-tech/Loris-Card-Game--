
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loris_card_game/game/engine/game_save_service.dart';
import 'package:loris_card_game/game/engine/game_match_controller.dart';
import 'package:loris_card_game/game/engine/match_score_engine.dart';
import 'package:loris_card_game/game/engine/bid_scoring_engine.dart';
import 'package:loris_card_game/game/engine/deal_controller.dart';
import 'package:loris_card_game/game/engine/deck_shuffle_engine.dart';
import 'package:loris_card_game/game/engine/deck_validation_engine.dart';
import 'package:loris_card_game/game/engine/redeal_controller.dart';
import 'package:loris_card_game/game/engine/redeal_validation_engine.dart';
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

    List<Card> createSixPlayerDeck() {
      final ranks = List.generate(12, (i) => i + 3);

      return [
        for (final suit in Suit.values)
          for (final rank in ranks)
            if (!(suit == Suit.spades && rank == 3))
              Card.normal(suit: suit, rank: rank),
        Card.loris(replacesRank: 3),
      ];
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
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

      final winner = match.completeTrick();
      if (match.currentRound.sixteenCallEngine?.canCall == true) {
        match.pass16(callerPlayerIndex: winner);
      }
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
      expect(match.nextPlayerIndex, 2);
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

    test('Rotates dealer when cumulative score stays +1 or more after this round loses points', () {
      // Team B owns dealer seat 3 and already has a positive match total.
      // Rotation depends on the cumulative total, not this round's delta.
      matchScore.teamBScore = 6;
      matchScore.teamAScore = -6;
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      expect(matchScore.teamBScore, 2);
      expect(match.dealerIndex, 2);
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
      expect(match.dealerIndex, 2);
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

      expect(match.dealerIndex, 2);
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
      expect(match.nextPlayerIndex, 2);
    });

    test('Starts a six-player round by dealing cards automatically', () {
      final sixPlayerMatch = GameMatchController(
        initialDealerIndex: 5,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
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

      final hands = sixPlayerMatch.startRoundWithDeal(
        deck: createSixPlayerDeck(),
        playerCount: 6,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      expect(hands.length, 6);
      expect(hands.every((hand) => hand.length == 8), isTrue);
      expect(sixPlayerMatch.hasStarted, isTrue);
      expect(sixPlayerMatch.currentRound.dealerIndex, 5);
      expect(sixPlayerMatch.nextPlayerIndex, 4);
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
      expect(sixPlayerMatch.nextPlayerIndex, 4);
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

    test('Redeals when everyone passes', () {
      final firstHands = match.startRoundWithDeal(
        deck: createDeck(),
        playerCount: 4,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      final newHands = match.validateAndRedeal(
        everyonePassed: true,
        bidderHasTrumpSuit: true,
      );

      expect(newHands.length, 4);
      expect(newHands.every((hand) => hand.length == 8), isTrue);
      expect(match.dealerIndex, 3);
      expect(matchScore.teamAScore, 0);
      expect(matchScore.teamBScore, 0);
      expect(identical(firstHands, newHands), isFalse);
    });

    test('Keeps the same deal when redeal is not required', () {
      final hands = match.startRoundWithDeal(
        deck: createDeck(),
        playerCount: 4,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      final result = match.validateAndRedeal(
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(identical(result, hands), isTrue);
      expect(match.dealerIndex, 3);
    });

    test('Redeals when bidder has no trump suit', () {
      match.startRoundWithDeal(
        deck: createDeck(),
        playerCount: 4,
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      final newHands = match.validateAndRedeal(
        everyonePassed: false,
        bidderHasTrumpSuit: false,
      );

      expect(newHands.length, 4);
      expect(newHands.every((hand) => hand.length == 8), isTrue);
      expect(match.dealerIndex, 3);
    });

    test('Restores a saved match in the middle of a trick', () {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      final round = match.currentRound;
      final player = round.trickEngine.currentPlayerIndex;
      final playedCard = round.trickEngine.hands[player].first;
      match.playCard(player, playedCard);

      final snapshot = match.createSnapshot();
      final restored = GameMatchController(
        initialDealerIndex: snapshot.dealerIndex,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
      );
      restored.restoreSnapshot(snapshot);

      expect(restored.currentRound.trickEngine.plays, hasLength(1));
      expect(
        restored.currentRound.trickEngine.currentPlayerIndex,
        (player - 1 + 4) % 4,
      );
      expect(
        restored.currentRound.trickEngine.hands[player].contains(playedCard),
        isFalse,
      );
    });

    test('Restores a saved match after the final trick of a round', () {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      for (var i = 0; i < 8; i++) {
        playOneTrick();
      }

      final snapshot = match.createSnapshot();
      expect(snapshot.completedTricks, 8);
      expect(snapshot.trickPlays, isEmpty);

      final restored = GameMatchController(
        initialDealerIndex: snapshot.dealerIndex,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
      );

      restored.restoreSnapshot(snapshot);

      expect(restored.hasStarted, isTrue);
      expect(restored.currentRound.isRoundEnded, isTrue);
      expect(restored.currentRound.completedTricks, 8);
      expect(restored.matchScoreEngine.teamAScore, 4);
      expect(restored.matchScoreEngine.teamBScore, -4);
    });

    test('resumeGame returns false when no save exists', () async {
      final service = GameSaveService();
      final restored = GameMatchController(
        initialDealerIndex: 3,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
      );

      expect(await restored.resumeGame(service), isFalse);
      expect(restored.hasStarted, isFalse);
    });

    test('resumeGame restores a saved match with a mid-trick play', () async {
      match.startRound(
        hands: createHands(),
        trumpSuit: Suit.spades,
        biddingTeam: 0,
        bidAmount: 4,
      );

      final round = match.currentRound;
      final player = round.trickEngine.currentPlayerIndex;
      final playedCard = round.trickEngine.hands[player].first;
      match.playCard(player, playedCard);

      final service = GameSaveService();
      await match.saveGame(service);

      final restored = GameMatchController(
        initialDealerIndex: 3,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
      );

      expect(await restored.resumeGame(service), isTrue);
      expect(restored.hasStarted, isTrue);
      expect(restored.currentRound.trickEngine.plays, hasLength(1));
      expect(restored.currentRound.trickEngine.hands[player].contains(playedCard), isFalse);
      expect(restored.currentRound.trickEngine.currentPlayerIndex, (player - 1 + 4) % 4);
    });

  });
}
