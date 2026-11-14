
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/redeal_validation_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Redeal Validation Engine', () {
    late RedealValidationEngine engine;

    setUp(() {
      engine = RedealValidationEngine();
    });

    List<Card> normalHand() {
      return List.generate(
        8,
        (i) => Card.normal(Suit.clubs, 10 + (i % 5)),
      );
    }

    List<Card> lowHand() {
      return List.generate(
        8,
        (i) => Card.normal(Suit.clubs, 7 + (i % 3)),
      );
    }

    List<List<Card>> validHands(int count) {
      return List.generate(count, (_) => normalHand());
    }

    test('Redeals when everyone passes', () {
      final result = engine.evaluate(
        hands: validHands(4),
        dealerIndex: 2,
        everyonePassed: true,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, true);
      expect(
        result.reasons,
        contains(RedealReason.everyonePassed),
      );
      expect(result.sameDealerIndex, 2);
    });

    test('Redeals when a player has all cards below ten', () {
      final hands = validHands(4);
      hands[1] = lowHand();

      final result = engine.evaluate(
        hands: hands,
        dealerIndex: 0,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, true);
      expect(
        result.reasons,
        contains(RedealReason.allCardsBelowTen),
      );
    });

    test('Does not count LORIS as a card below ten', () {
      final hand = lowHand();
      hand[0] = Card.loris(replacesRank: 7);

      final hands = validHands(4);
      hands[0] = hand;

      final result = engine.evaluate(
        hands: hands,
        dealerIndex: 0,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, true);
      expect(
        result.reasons,
        contains(RedealReason.allCardsBelowTen),
      );
    });

    test('Redeals when bidder has no selected trump suit', () {
      final result = engine.evaluate(
        hands: validHands(4),
        dealerIndex: 1,
        everyonePassed: false,
        bidderHasTrumpSuit: false,
      );

      expect(result.shouldRedeal, true);
      expect(
        result.reasons,
        contains(RedealReason.bidderHasNoTrump),
      );
    });

    test('Does not redeal when all conditions are valid', () {
      final result = engine.evaluate(
        hands: validHands(4),
        dealerIndex: 3,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, false);
      expect(result.reasons, isEmpty);
    });

    test('Keeps the same dealer after redeal', () {
      final result = engine.evaluate(
        hands: validHands(4),
        dealerIndex: 2,
        everyonePassed: true,
        bidderHasTrumpSuit: true,
      );

      expect(result.sameDealerIndex, 2);
    });

    test('Supports six players', () {
      final result = engine.evaluate(
        hands: validHands(6),
        dealerIndex: 4,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, false);
      expect(result.sameDealerIndex, 4);
    });

    test('Can return multiple redeal reasons', () {
      final hands = validHands(4);
      hands[0] = lowHand();

      final result = engine.evaluate(
        hands: hands,
        dealerIndex: 1,
        everyonePassed: false,
        bidderHasTrumpSuit: false,
      );

      expect(result.shouldRedeal, true);
      expect(result.reasons.length, 2);
    });

    test('Rejects invalid player count', () {
      expect(
        () => engine.evaluate(
          hands: validHands(3),
          dealerIndex: 0,
          everyonePassed: false,
          bidderHasTrumpSuit: true,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid dealer index', () {
      expect(
        () => engine.evaluate(
          hands: validHands(4),
          dealerIndex: 4,
          everyonePassed: false,
          bidderHasTrumpSuit: true,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects hands that do not contain eight cards', () {
      final hands = validHands(4);
      hands[0] = normalHand().sublist(0, 7);

      expect(
        () => engine.evaluate(
          hands: hands,
          dealerIndex: 0,
          everyonePassed: false,
          bidderHasTrumpSuit: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
