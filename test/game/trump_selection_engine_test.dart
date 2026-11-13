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

  test('teammate card is revealed to everyone', () {
    final result = TrumpSelectionEngine.select(
      hands: hands,
      bidderIndex: 0,
      highestBidderIndex: 0,
      cardOwnerIndex: 2,
      selectedCard: teammateCard,
    );

    expect(result.trumpSuit, Suit.spades);
    expect(result.revealedToEveryone, true);
    expect(result.cardOwnerIndex, 2);
    expect(result.bidderHasTrumpSuit, false);
  });

  test('selected card remains in owner hand', () {
    TrumpSelectionEngine.select(
      hands: hands,
      bidderIndex: 0,
      highestBidderIndex: 0,
      cardOwnerIndex: 2,
      selectedCard: teammateCard,
    );

    expect(hands[2].contains(teammateCard), true);
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

  test('LORIS cannot select trump', () {
    hands[0].add(loris);

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
