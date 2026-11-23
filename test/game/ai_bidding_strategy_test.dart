import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/ai/ai_bidding_strategy.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  const strategy = AiBiddingStrategy();

  group('AiBiddingStrategy', () {
    test('rejects hands that do not contain exactly eight cards', () {
      expect(
        () => strategy.chooseBid(
          hand: const [Card.normal(suit: Suit.clubs, rank: 14)],
          playerIndex: 1,
          highestBid: null,
          highestBidder: null,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a duplicate card in the AI hand', () {
      const duplicateHand = [
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.diamonds, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.spades, rank: 9),
      ];

      expect(() => strategy.evaluateHand(duplicateHand), throwsArgumentError);
    });

    test('rejects a LORIS card without a valid replacement rank', () {
      const malformedHand = [
        Card.loris(replacesRank: null),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.diamonds, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.spades, rank: 9),
      ];

      expect(() => strategy.evaluateHand(malformedHand), throwsArgumentError);
    });

    test('passes with a weak hand instead of inventing a bid', () {
      const hand = [
        Card.normal(suit: Suit.clubs, rank: 7),
        Card.normal(suit: Suit.clubs, rank: 8),
        Card.normal(suit: Suit.diamonds, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.spades, rank: 8),
        Card.normal(suit: Suit.spades, rank: 9),
      ];

      final decision = strategy.chooseBid(
        hand: hand,
        playerIndex: 1,
        highestBid: null,
        highestBidder: null,
      );

      expect(decision.shouldPass, isTrue);
      expect(decision.estimatedStrength, lessThan(3.4));
    });

    test('recognises LORIS as a major source of trick strength', () {
      const ordinaryHand = [
        Card.normal(suit: Suit.clubs, rank: 7),
        Card.normal(suit: Suit.clubs, rank: 8),
        Card.normal(suit: Suit.diamonds, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.spades, rank: 8),
        Card.normal(suit: Suit.spades, rank: 9),
      ];
      const lorisHand = [
        Card.loris(replacesRank: 7),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.diamonds, rank: 14),
        Card.normal(suit: Suit.hearts, rank: 7),
        Card.normal(suit: Suit.spades, rank: 8),
        Card.normal(suit: Suit.spades, rank: 9),
      ];

      expect(
        strategy.evaluateHand(lorisHand),
        greaterThan(strategy.evaluateHand(ordinaryHand)),
      );
    });

    test('does not outbid a teammate', () {
      const hand = [
        Card.loris(replacesRank: 7),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.diamonds, rank: 14),
        Card.normal(suit: Suit.diamonds, rank: 13),
        Card.normal(suit: Suit.hearts, rank: 14),
        Card.normal(suit: Suit.spades, rank: 14),
      ];

      final decision = strategy.chooseBid(
        hand: hand,
        playerIndex: 2,
        highestBid: 5,
        highestBidder: 0,
      );

      expect(decision.shouldPass, isTrue);
      expect(decision.estimatedStrength, greaterThan(6));
    });

    test('never repeats or undercuts the current high bid', () {
      const hand = [
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.diamonds, rank: 14),
        Card.normal(suit: Suit.diamonds, rank: 13),
        Card.normal(suit: Suit.hearts, rank: 14),
        Card.normal(suit: Suit.hearts, rank: 13),
        Card.normal(suit: Suit.spades, rank: 14),
      ];

      final decision = strategy.chooseBid(
        hand: hand,
        playerIndex: 1,
        highestBid: 8,
        highestBidder: 0,
      );

      expect(decision.shouldPass, isTrue);
    });

    test('can bid when the hand supports a contract above the current bid', () {
      const hand = [
        Card.loris(replacesRank: 7),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.clubs, rank: 13),
        Card.normal(suit: Suit.clubs, rank: 12),
        Card.normal(suit: Suit.diamonds, rank: 14),
        Card.normal(suit: Suit.diamonds, rank: 13),
        Card.normal(suit: Suit.hearts, rank: 14),
        Card.normal(suit: Suit.spades, rank: 14),
      ];

      final decision = strategy.chooseBid(
        hand: hand,
        playerIndex: 1,
        highestBid: 5,
        highestBidder: 0,
      );

      expect(decision.bidAmount, greaterThan(5));
      expect(decision.bidAmount, lessThanOrEqualTo(8));
    });
  });
}
