import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/trick_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

List<Card> _hand(Suit firstSuit, int firstRank, Suit secondSuit, int secondRank) => [
  Card.normal(suit: firstSuit, rank: firstRank),
  Card.normal(suit: secondSuit, rank: secondRank),
  Card.normal(suit: Suit.clubs, rank: 7),
  Card.normal(suit: Suit.diamonds, rank: 8),
  Card.normal(suit: Suit.hearts, rank: 9),
  Card.normal(suit: Suit.spades, rank: 10),
  Card.normal(suit: Suit.clubs, rank: 11),
  Card.normal(suit: Suit.diamonds, rank: 12),
];

void main() {
  group('LORIS selected as trump', () {
    test('follows the led suit and ignores off-suit high cards', () {
      final hands = [
        _hand(Suit.clubs, 7, Suit.hearts, 8),
        _hand(Suit.clubs, 9, Suit.diamonds, 14),
        _hand(Suit.clubs, 12, Suit.hearts, 10),
        _hand(Suit.clubs, 10, Suit.spades, 9),
      ];
      final engine = TrickEngine(
        hands: hands,
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        lorisTrump: true,
      );

      engine.playCard(0, hands[0][0]);
      expect(engine.legalCardsFor(1), contains(hands[1][0]));
      expect(engine.legalCardsFor(1), isNot(contains(hands[1][1])));
      engine.playCard(1, hands[1][0]);
      engine.playCard(2, hands[2][0]);
      engine.playCard(3, hands[3][0]);

      // The highest club wins. The off-suit Ace of Diamonds is not a trump.
      expect(engine.winnerIndex, 2);
    });

    test('allows any discard when void in the led suit', () {
      final hands = [
        _hand(Suit.clubs, 7, Suit.hearts, 8),
        [
          Card.normal(suit: Suit.diamonds, rank: 14),
          Card.normal(suit: Suit.spades, rank: 8),
          Card.normal(suit: Suit.diamonds, rank: 7),
          Card.normal(suit: Suit.hearts, rank: 8),
          Card.normal(suit: Suit.diamonds, rank: 9),
          Card.normal(suit: Suit.spades, rank: 10),
          Card.normal(suit: Suit.hearts, rank: 11),
          Card.normal(suit: Suit.diamonds, rank: 12),
        ],
        _hand(Suit.clubs, 12, Suit.hearts, 10),
        _hand(Suit.clubs, 10, Suit.spades, 9),
      ];
      final engine = TrickEngine(
        hands: hands,
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        lorisTrump: true,
      );

      engine.playCard(0, hands[0][0]);
      expect(engine.legalCardsFor(1), contains(hands[1][0]));
      engine.playCard(1, hands[1][0]);
      engine.playCard(2, hands[2][0]);
      engine.playCard(3, hands[3][0]);

      // The void player's off-suit Ace cannot beat the led-suit Queen.
      expect(engine.winnerIndex, 2);
    });

    test('LORIS remains the highest card in this mode', () {
      final hands = [
        [
          Card.normal(suit: Suit.clubs, rank: 7),
          ..._hand(Suit.hearts, 8, Suit.spades, 9).skip(1),
        ],
        [
          Card.loris(replacesRank: 7),
          ..._hand(Suit.diamonds, 8, Suit.hearts, 9).skip(1),
        ],
        _hand(Suit.clubs, 14, Suit.hearts, 10),
        _hand(Suit.spades, 13, Suit.diamonds, 11),
      ];
      final engine = TrickEngine(
        hands: hands,
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        lorisTrump: true,
      );

      engine.playCard(0, hands[0][0]);
      engine.playCard(1, hands[1][0]);
      engine.playCard(2, hands[2][0]);
      engine.playCard(3, hands[3][0]);

      expect(engine.winnerIndex, 1);
    });
  });
}
