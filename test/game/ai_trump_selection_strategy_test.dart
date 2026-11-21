import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/ai/ai_trump_selection_strategy.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  const strategy = AiTrumpSelectionStrategy();

  group('AI trump selection strategy', () {
    test('selects the longest suit using only the bidder hand', () {
      const hand = [
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 9),
        Card.normal(suit: Suit.hearts, rank: 10),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.diamonds, rank: 12),
        Card.loris(replacesRank: 7),
      ];

      final selected = strategy.chooseCard(bidderHand: hand);

      expect(selected.suit, Suit.hearts);
      expect(selected.rank, 7);
    });

    test('uses honours to break equal-length suit ties', () {
      const hand = [
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 9),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.diamonds, rank: 10),
        Card.loris(replacesRank: 7),
      ];

      final selected = strategy.chooseCard(bidderHand: hand);

      expect(selected.suit, Suit.clubs);
      expect(selected.rank, 12);
    });

    test('rejects an incomplete bidder hand', () {
      expect(
        () => strategy.chooseCard(
          bidderHand: const [
            Card.normal(suit: Suit.hearts, rank: 14),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('never chooses LORIS as the trump selector', () {
      const hand = [
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 9),
        Card.normal(suit: Suit.clubs, rank: 10),
        Card.normal(suit: Suit.clubs, rank: 11),
        Card.normal(suit: Suit.diamonds, rank: 12),
        Card.normal(suit: Suit.spades, rank: 13),
        Card.loris(replacesRank: 7),
      ];

      expect(
        strategy.chooseCard(bidderHand: hand).isLoris,
        isFalse,
      );
    });
  });
}
