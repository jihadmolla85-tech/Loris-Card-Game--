import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/engine/trump_selection_engine.dart';

void main() {
  final ownCard = Card.normal(suit: Suit.hearts, rank: 10);
  final teammateCard = Card.normal(suit: Suit.spades, rank: 12);
  final opponentCard = Card.normal(suit: Suit.clubs, rank: 11);
  final loris = Card.loris(replacesRank: 7);

  late List<List<Card>> hands;

  setUp(() {
    hands = [
      [ownCard, Card.normal(suit: Suit.hearts, rank: 9)],
      [opponentCard],
      [teammateCard, Card.normal(suit: Suit.spades, rank: 9)],
      [Card.normal(suit: Suit.diamonds, rank: 10)],
    ];
  });

  test('random teammate draw can select from either partner in six-player game', () {
    final sixPlayerHands = [
      [ownCard],
      [opponentCard],
      [teammateCard],
      [Card.normal(suit: Suit.diamonds, rank: 10)],
      [Card.normal(suit: Suit.clubs, rank: 8)],
      [Card.normal(suit: Suit.hearts, rank: 11)],
    ];
    final selection = TrumpSelectionEngine.selectRandomTeammateCard(
      hands: sixPlayerHands,
      bidderIndex: 0,
      random: Random(7),
    );

    expect([2, 4], contains(selection.key));
    expect(sixPlayerHands[selection.key].contains(selection.value), true);
    expect(selection.value.isLoris, false);
  });

  test('random teammate draw never selects bidder or opponent cards', () {
    final selection = TrumpSelectionEngine.selectRandomTeammateCard(
      hands: hands,
      bidderIndex: 0,
      random: Random(3),
    );

    expect(selection.key, 2);
    expect(selection.value, teammateCard);
  });

  test('own card selects trump without revealing it', () {
    final result = TrumpSelectionEngine.select(
      hands: hands,
      bidderIndex: 0,
      highestBidderIndex: 0,
      cardOwnerIndex: 0,
      selectedCard: ownCard,
    );

    expect(result.trumpSuit, Suit.hearts);
    expect(result.revealedToEveryone, false);
    expect(result.cardOwnerIndex, 0);
    expect(result.bidderHasTrumpSuit, true);
  });

  test('teammate card privately determines trump suit', () {
    final result = TrumpSelectionEngine.select(hands: hands, bidderIndex: 0, highestBidderIndex: 0, cardOwnerIndex: 2, selectedCard: teammateCard);
    expect(result.trumpSuit, Suit.spades);
    expect(result.revealedToEveryone, false);
    expect(result.cardOwnerIndex, 2);
    expect(result.bidderHasTrumpSuit, true);
  });

  test('selected bidder card remains in the private hand', () {
    final result = TrumpSelectionEngine.select(
      hands: hands,
      bidderIndex: 0,
      highestBidderIndex: 0,
      cardOwnerIndex: 0,
      selectedCard: ownCard,
    );

    expect(hands[0].contains(ownCard), true);
    expect(result.revealedToEveryone, false);
  });

  test('opponent card cannot be selected', () {
    expect(
      () => TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: 0,
        highestBidderIndex: 0,
        cardOwnerIndex: 1,
        selectedCard: opponentCard,
      ),
      throwsArgumentError,
    );
  });

  test('only highest bidder can select trump', () {
    expect(
      () => TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: 0,
        highestBidderIndex: 2,
        cardOwnerIndex: 0,
        selectedCard: ownCard,
      ),
      throwsStateError,
    );
  });

  test('bidder can select Joker mode when holding LORIS', () {
    hands[0].add(loris);

    final result = TrumpSelectionEngine.select(
      hands: hands,
      bidderIndex: 0,
      highestBidderIndex: 0,
      cardOwnerIndex: 0,
      selectedCard: loris,
    );

    expect(result.trumpSuit, isNull);
    expect(result.selectedCard.isLoris, true);
    expect(result.bidderHasTrumpSuit, true);
  });

  test('teammate holding LORIS cannot let bidder select Joker mode', () {
    hands[2].add(loris);

    expect(
      () => TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: 0,
        highestBidderIndex: 0,
        cardOwnerIndex: 2,
        selectedCard: loris,
      ),
      throwsArgumentError,
    );
  });

  test('bidder without LORIS cannot select Joker mode', () {
    expect(
      () => TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: 0,
        highestBidderIndex: 0,
        cardOwnerIndex: 0,
        selectedCard: loris,
      ),
      throwsArgumentError,
    );
  });

  test('card not in selected owner hand is rejected', () {
    expect(
      () => TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: 0,
        highestBidderIndex: 0,
        cardOwnerIndex: 0,
        selectedCard: teammateCard,
      ),
      throwsArgumentError,
    );
  });
}
