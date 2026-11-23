import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/ai/ai_sixteen_call_strategy.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('AI 16-call strategy', () {
    const strategy = AiSixteenCallStrategy();

    test('calls with enough high-card control to cover every remaining trick', () {
      final hand = [
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.diamonds, rank: 14),
        Card.normal(suit: Suit.hearts, rank: 14),
        Card.normal(suit: Suit.spades, rank: 14),
      ];

      expect(
        strategy.shouldCall(
          hand: hand,
          completedTricks: 4,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        isTrue,
      );
    });

    test('values LORIS plus high honours in either trump mode', () {
      final hand = [
        Card.loris(replacesRank: 7),
        Card.normal(suit: Suit.clubs, rank: 14),
        Card.normal(suit: Suit.hearts, rank: 14),
        Card.normal(suit: Suit.spades, rank: 14),
      ];

      expect(
        strategy.shouldCall(
          hand: hand,
          completedTricks: 4,
          trumpSuit: Suit.diamonds,
          lorisTrump: true,
        ),
        isTrue,
      );
    });

    test('calls with a concentrated top-end trump run', () {
      final hand = [
        Card.normal(suit: Suit.spades, rank: 14),
        Card.normal(suit: Suit.spades, rank: 13),
        Card.normal(suit: Suit.spades, rank: 12),
        Card.normal(suit: Suit.spades, rank: 11),
      ];

      expect(
        strategy.shouldCall(
          hand: hand,
          completedTricks: 4,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        isTrue,
      );
    });

    test('decision is independent of hand card order', () {
      final hand = [
        Card.normal(suit: Suit.spades, rank: 14),
        Card.normal(suit: Suit.spades, rank: 13),
        Card.normal(suit: Suit.spades, rank: 12),
        Card.normal(suit: Suit.spades, rank: 11),
      ];

      final forward = strategy.shouldCall(
        hand: hand,
        completedTricks: 4,
        trumpSuit: Suit.spades,
        lorisTrump: false,
      );
      final reversed = strategy.shouldCall(
        hand: hand.reversed.toList(),
        completedTricks: 4,
        trumpSuit: Suit.spades,
        lorisTrump: false,
      );

      expect(forward, isTrue);
      expect(reversed, forward);
    });

    test('passes on a weak hand even when it holds LORIS', () {
      final hand = [
        Card.loris(replacesRank: 7),
        Card.normal(suit: Suit.clubs, rank: 7),
        Card.normal(suit: Suit.hearts, rank: 8),
        Card.normal(suit: Suit.diamonds, rank: 9),
      ];

      expect(
        strategy.shouldCall(
          hand: hand,
          completedTricks: 4,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        isFalse,
      );
    });

    test('passes on unsupported low cards', () {
      final hand = [
        Card.normal(suit: Suit.clubs, rank: 7),
        Card.normal(suit: Suit.diamonds, rank: 8),
        Card.normal(suit: Suit.hearts, rank: 9),
        Card.normal(suit: Suit.spades, rank: 10),
      ];

      expect(
        strategy.shouldCall(
          hand: hand,
          completedTricks: 4,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        isFalse,
      );
    });

    test('uses only the AI hand and public round context', () {
      final oneCardHand = [Card.normal(suit: Suit.hearts, rank: 14)];

      expect(
        strategy.shouldCall(
          hand: oneCardHand,
          completedTricks: 7,
          trumpSuit: Suit.spades,
          lorisTrump: true,
        ),
        isTrue,
      );
    });

    test('rejects a hand size inconsistent with remaining tricks', () {
      expect(
        () => strategy.shouldCall(
          hand: [Card.normal(suit: Suit.clubs, rank: 14)],
          completedTricks: 4,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid round progress', () {
      expect(
        () => strategy.shouldCall(
          hand: const [],
          completedTricks: 0,
          trumpSuit: Suit.spades,
          lorisTrump: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
